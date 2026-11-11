-- Herds are server-owned networked peds: every nearby player sees the same animals in the same place.
-- The server decides when a herd exists and deletes it. Clients only propose a road position and report the horn.

local RES = GetCurrentResourceName()
local L, F, H = Config.Limits, Config.Fixed, Config.Horn

local herds = {}      -- id -> { c = vec3, peds = {}, expires = os time, spot = index or nil }
local public = {}     -- id -> { id, c = vec3, n = { netIds }, f = vec3 or nil }  replicated to clients
local lastSpawn = {}  -- player source -> os time of their last random herd
local spots = {}      -- fixed spot index -> { herd, readyAt, needEmpty }
local nextId = 0

for i = 1, #Config.Spots do spots[i] = { readyAt = 0, needEmpty = false } end

local function debug(msg, ...)
    if Config.Debug then print(('[%s] ' .. msg):format(RES, ...)) end
end

local function publish()
    GlobalState.ntcHerds = public
end

local function remove(id)
    local h = herds[id]
    if not h then return end
    for _, ped in ipairs(h.peds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    if h.spot then
        local s = spots[h.spot]
        -- a fixed herd stays gone until the area has been empty and the respawn time has passed
        s.herd, s.readyAt, s.needEmpty = nil, os.time() + F.RespawnSec, true
    end
    herds[id], public[id] = nil, nil
    publish()
    debug('herd %d removed', id)
end

local function spawn(pos, heading, lifetime, spot)
    nextId = nextId + 1
    local id = nextId
    local peds = {}
    -- reserved before any wait so the limit checks of other requests see it
    herds[id] = { c = pos, peds = peds, expires = os.time() + lifetime, spot = spot }

    local model = Config.Models[math.random(#Config.Models)]
    local rad = math.rad(heading)
    local fx, fy = -math.sin(rad), math.cos(rad) -- road direction
    for _ = 1, math.random(Config.FlockSize[1], Config.FlockSize[2]) do
        local along = (math.random() * 2 - 1) * Config.SpreadAlong
        local side = (math.random() * 2 - 1) * Config.SpreadSide
        -- +1.0: dropped onto the road, never spawned inside it
        local ped = CreatePed(28, model, pos.x + fx * along - fy * side, pos.y + fy * along + fx * side, pos.z + 1.0,
            math.random(0, 359) + 0.0, true, true)
        if ped and ped ~= 0 then peds[#peds + 1] = ped end
    end

    -- entities exist a tick or two after creation
    local nets, deadline = {}, GetGameTimer() + 2000
    for i = #peds, 1, -1 do
        while not DoesEntityExist(peds[i]) and GetGameTimer() < deadline do Wait(0) end
        if DoesEntityExist(peds[i]) then
            nets[#nets + 1] = NetworkGetNetworkIdFromEntity(peds[i])
        else
            table.remove(peds, i)
        end
    end

    if not herds[id] then -- resource stopping, or removed while we waited
        for _, ped in ipairs(peds) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        return
    end
    if #peds == 0 then
        debug('herd %d: no animals could be created', id)
        remove(id)
        return
    end

    public[id] = { id = id, c = pos, n = nets }
    publish()
    debug('herd %d: %d animals at %s', id, #peds, pos)
    return id
end

local function roomFor(pos)
    local count = 0
    for _, h in pairs(herds) do
        count = count + 1
        if #(h.c - pos) < L.MinGap then return false end
    end
    return count < L.MaxHerds
end

-- A driver's client found a backroad point ahead of them (road data only exists on clients).
RegisterNetEvent(RES .. ':request', function(pos, heading)
    local src = source
    local R = Config.Random
    if not R.Enabled or type(pos) ~= 'vector3' or type(heading) ~= 'number' then return end
    local now = os.time()
    if (lastSpawn[src] or 0) + R.CooldownSec > now then return end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or GetVehiclePedIsIn(ped, false) == 0 then return end
    if #(GetEntityCoords(ped) - pos) > R.Ahead * 1.5 then return end
    if not roomFor(pos) then return end
    lastSpawn[src] = now
    spawn(pos, heading, L.LifetimeSec)
end)

RegisterNetEvent(RES .. ':honk', function(id)
    local src = source
    local h, p = herds[id], public[id]
    if not H.Enabled or not h or not p or p.f then return end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or GetVehiclePedIsIn(ped, false) == 0 then return end
    local at = GetEntityCoords(ped)
    if #(at - h.c) > H.Range * 2 then return end -- x2: allowance for latency
    p.f = at
    h.expires = math.min(h.expires, os.time() + H.DespawnSec)
    publish()
    debug('herd %d scattered by %s', id, src)
end)

AddEventHandler('playerDropped', function()
    lastSpawn[source] = nil
end)

local function anyNear(coords, pos, range)
    for i = 1, #coords do
        if #(coords[i] - pos) < range then return true end
    end
    return false
end

-- One sweep: expire herds, drop herds nobody is near, raise fixed herds when someone approaches.
CreateThread(function()
    while true do
        Wait(L.TickMs)
        if next(herds) or #spots > 0 then
            local coords = {}
            for _, src in ipairs(GetPlayers()) do
                local ped = GetPlayerPed(src)
                if ped and ped ~= 0 then coords[#coords + 1] = GetEntityCoords(ped) end
            end

            local now = os.time()
            for id, h in pairs(herds) do
                if now >= h.expires or not anyNear(coords, h.c, L.DespawnDistance) then remove(id) end
            end

            for i, s in ipairs(spots) do
                if not s.herd then
                    local at = Config.Spots[i]
                    if not anyNear(coords, at.xyz, F.Range) then
                        s.needEmpty = false
                    elseif not s.needEmpty and now >= s.readyAt then
                        s.herd = spawn(at.xyz, at.w, F.LifetimeSec, i)
                    end
                end
            end
        end
    end
end)

if Config.TestCommand then
    -- ACE restricted: add_ace group.admin command.<name> allow
    RegisterCommand(Config.TestCommand, function(src)
        if src == 0 then return end
        local ped = GetPlayerPed(src)
        local c, rad = GetEntityCoords(ped), math.rad(GetEntityHeading(ped))
        spawn(vec3(c.x - math.sin(rad) * 25.0, c.y + math.cos(rad) * 25.0, c.z - 1.0), GetEntityHeading(ped), L.LifetimeSec)
    end, true)
end

AddEventHandler('onResourceStart', function(r)
    if r ~= RES then return end
    GlobalState.ntcHerds = {} -- clear anything left from a previous run
    if GetConvar('onesync', 'off') == 'off' then
        print(('[%s] OneSync is off. Herds need OneSync to be created and synced.'):format(RES))
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= RES then return end
    for id, h in pairs(herds) do
        for _, ped in ipairs(h.peds) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        herds[id] = nil
    end
    GlobalState.ntcHerds = {}
end)
