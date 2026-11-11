-- Livestock on country roads. Client-only peds: cheap, no network sync.
-- shortcut: only the driver sees the flock (local peds), network them if passengers need to see it.

local Rural = {}
for _, z in ipairs(Config.RuralZones) do Rural[z] = true end

local flock, nextAt = {}, 0

local function clear()
    for _, p in ipairs(flock) do
        if DoesEntityExist(p) then DeleteEntity(p) end
    end
    flock = {}
end

local function scatter(from)
    for _, p in ipairs(flock) do
        if DoesEntityExist(p) then
            SetBlockingOfNonTemporaryEvents(p, false)
            TaskSmartFleePed(p, from, 80.0, -1, false, false)
        end
    end
end

-- Backroad = quiet road, not highway/tunnel/junction/water (eVehicleNodeProperties bits).
local BAD = (1 << 4) | (1 << 6) | (1 << 7) | (1 << 10)
local function isBackroad(p)
    local ok, density, flags = GetVehicleNodeProperties(p.x, p.y, p.z)
    return ok and density <= Config.MaxDensity and flags & BAD == 0
end

local function randomSpot(veh)
    if not isBackroad(GetEntityCoords(veh)) then return end -- no flocks seen from the highway
    local a = GetOffsetFromEntityInWorldCoords(veh, 0.0, Config.Ahead, 0.0)
    local ok, pos, heading = GetClosestVehicleNodeWithHeading(a.x, a.y, a.z, 1, 3.0, 0)
    -- the road may bend back towards the car: keep the flock out of sight
    if ok and #(pos - GetEntityCoords(veh)) >= Config.Ahead * 0.65 and isBackroad(pos) then return pos, heading end
end

local function spawn(pos, heading)
    local model = Config.Models[math.random(#Config.Models)]
    if not IsModelInCdimage(model) then return end
    RequestModel(model)
    local t = GetGameTimer() + 3000
    while not HasModelLoaded(model) do
        if GetGameTimer() > t then return end
        Wait(50)
    end

    local rad = math.rad(heading)
    local fx, fy = -math.sin(rad), math.cos(rad) -- road direction
    for _ = 1, math.random(Config.FlockSize[1], Config.FlockSize[2]) do
        local along, side = math.random(-10, 10), math.random(-35, 35) / 10
        local x, y = pos.x + fx * along - fy * side, pos.y + fy * along + fx * side
        local p = CreatePed(28, model, x, y, pos.z, math.random(0, 359) + 0.0, false, false)
        if p ~= 0 then
            PlaceObjectOnGroundProperly(p)
            SetBlockingOfNonTemporaryEvents(p, true) -- don't bolt at engine noise, only at the horn
            TaskWanderInArea(p, pos.x, pos.y, pos.z, 7.0, 2.0, 6.0)
            flock[#flock + 1] = p
        end
    end
    SetModelAsNoLongerNeeded(model)
    return pos
end

local function nearSpot(c)
    for _, s in ipairs(Config.Spots) do
        if #(c - s.xyz) < 200.0 then return s end
    end
end

CreateThread(function()
    local lastRoll = 0
    while true do
        Wait(1500)
        local ped = PlayerPedId()
        local c = GetEntityCoords(ped)
        local pos, heading, fixed
        local s = nearSpot(c)
        if s and not isBackroad(s.xyz) then
            if Config.Debug then
                local _, density, flags = GetVehicleNodeProperties(s.x, s.y, s.z)
                print(('[%s] spot %s is not a backroad (density %s, flags %s), skipped')
                    :format(GetCurrentResourceName(), s, density, flags))
            end
            s = nil
            Wait(30000)
        end
        if s then
            pos, heading, fixed = s.xyz, s.w, true
        elseif GetGameTimer() - lastRoll > Config.CheckMs then
            lastRoll = GetGameTimer()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and GetGameTimer() > nextAt
                and GetEntitySpeed(veh) > Config.MinSpeed and Rural[GetNameOfZone(c.x, c.y, c.z)]
                and IsThisModelACar(GetEntityModel(veh)) and math.random() < Config.Chance then
                pos, heading = randomSpot(veh)
            end
        end
        local at = pos and spawn(pos, heading)
        if at then
            if not fixed then nextAt = GetGameTimer() + Config.CooldownMs end
            local scattered, ends = false, GetGameTimer() + (fixed and 600000 or 120000)
            while GetGameTimer() < ends do
                ped = PlayerPedId()
                local d = #(GetEntityCoords(ped) - at)
                if d > 260.0 then break end
                if not scattered and d < Config.HornRange and IsPedInAnyVehicle(ped, false)
                    and IsControlPressed(0, Config.HornControl) then
                    scattered, ends = true, math.min(ends, GetGameTimer() + 25000)
                    scatter(ped)
                end
                Wait(d < 60.0 and 0 or 500) -- frame-accurate horn only when close
            end
            clear()
            -- a shifted fixed flock stays gone until you leave the area
            while fixed and nearSpot(GetEntityCoords(PlayerPedId())) do Wait(2000) end
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then clear() end
end)
