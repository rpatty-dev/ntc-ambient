-- Client side of the herds. The animals are server-owned networked peds (see server.lua).
-- This file does three things: proposes a backroad position while driving, gives the animals their
-- behaviour when this client owns them, and reports the horn.

local RES = GetCurrentResourceName()
local R, H = Config.Random, Config.Horn

local herds = GlobalState.ntcHerds or {} -- cached: reading a state bag decodes it every time
local applied = {}                       -- netId -> 'w' (wander) or 'f' (flee): behaviour we last gave it
local honked                             -- herd id we already reported

AddStateBagChangeHandler('ntcHerds', 'global', function(_, _, value)
    herds = value or {}
    -- net ids are reused: forget every animal that is no longer in a herd
    local keep = {}
    for _, h in pairs(herds) do
        for i = 1, #h.n do keep[h.n[i]] = applied[h.n[i]] end
    end
    applied = keep
end)

local Rural = {}
for _, z in ipairs(R.Zones) do Rural[z] = true end

-- Backroad = quiet road, not highway/tunnel/junction/water (eVehicleNodeProperties bits).
local BAD = (1 << 4) | (1 << 6) | (1 << 7) | (1 << 10)
local function isBackroad(p)
    local ok, density, flags = GetVehicleNodeProperties(p.x, p.y, p.z)
    return ok and density <= R.MaxDensity and flags & BAD == 0
end

local function randomSpot(veh, c)
    if not isBackroad(c) then return end -- no herds seen from the highway
    local a = GetOffsetFromEntityInWorldCoords(veh, 0.0, R.Ahead, 0.0)
    local ok, pos, heading = GetClosestVehicleNodeWithHeading(a.x, a.y, a.z, 1, 3.0, 0)
    -- the road may bend back towards the car: keep the herd out of sight
    if ok and #(pos - c) >= R.Ahead * 0.65 and isBackroad(pos) then return pos, heading end
end

local function hourOk()
    if not R.Hours then return true end
    local h, from, to = GetClockHours(), R.Hours[1], R.Hours[2]
    if from <= to then return h >= from and h < to end
    return h >= from or h < to -- window passes midnight
end

if R.Enabled then
    CreateThread(function()
        local nextAt = 0
        while true do
            Wait(R.CheckMs)
            local now = GetGameTimer()
            -- the roll comes first: most checks end here without calling the game
            if now >= nextAt and math.random() < R.Chance then
                local ped = PlayerPedId()
                local veh = GetVehiclePedIsIn(ped, false)
                if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and GetEntitySpeed(veh) > R.MinSpeed
                    and (not R.CarsOnly or IsThisModelACar(GetEntityModel(veh))) and hourOk() then
                    local c = GetEntityCoords(veh)
                    if Rural[GetNameOfZone(c.x, c.y, c.z)] then
                        local pos, heading = randomSpot(veh, c)
                        if pos then
                            nextAt = now + R.CooldownSec * 1000
                            TriggerServerEvent(RES .. ':request', pos, heading)
                        end
                    end
                end
            end
        end
    end)
end

-- Behaviour runs on whichever client owns the animal. Ownership moves between players, so every
-- client near a herd checks for animals it owns that have not been told what to do yet.
local function upkeep(h)
    local want = h.f and 'f' or 'w'
    for i = 1, #h.n do
        local net = h.n[i]
        if applied[net] ~= want and NetworkDoesNetworkIdExist(net) then
            local p = NetworkGetEntityFromNetworkId(net)
            if p ~= 0 and NetworkHasControlOfEntity(p) and not IsEntityDead(p) then
                if h.f then
                    SetBlockingOfNonTemporaryEvents(p, false)
                    TaskSmartFleeCoord(p, h.f.x, h.f.y, h.f.z, H.FleeDistance, -1, false, false)
                else
                    SetEntityInvincible(p, Config.Invincible)
                    SetBlockingOfNonTemporaryEvents(p, true) -- don't bolt at engine noise, only at the horn
                    TaskWanderInArea(p, h.c.x, h.c.y, h.c.z, Config.WanderRadius, 2.0, 6.0)
                end
                applied[net] = want
            end
        end
    end
end

local UPKEEP_RANGE, UPKEEP_MS = 150.0, 400

CreateThread(function()
    local lastUpkeep = 0
    while true do
        local sleep = 2000
        if next(herds) then
            local ped = PlayerPedId()
            local c = GetEntityCoords(ped)
            local now = GetGameTimer()
            local due = now - lastUpkeep >= UPKEEP_MS
            for _, h in pairs(herds) do
                local d = #(c - h.c)
                if d < UPKEEP_RANGE then
                    if sleep > UPKEEP_MS then sleep = UPKEEP_MS end
                    if due then
                        lastUpkeep = now
                        upkeep(h)
                    end
                    if H.Enabled and not h.f and honked ~= h.id and d < H.Range then
                        local veh = GetVehiclePedIsIn(ped, false)
                        if veh ~= 0 and (not H.DriverOnly or GetPedInVehicleSeat(veh, -1) == ped) then
                            sleep = 0 -- frame-accurate horn only when close
                            if IsControlPressed(0, H.Control) then
                                honked = h.id
                                TriggerServerEvent(RES .. ':honk', h.id)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
