Config = {}

--------------------------------------------------------------------------------
-- The herd
--------------------------------------------------------------------------------

-- Animals a herd can be made of. One model is picked per herd.
-- GTA has no sheep model: add a streamed addon model here if you have one.
-- Other stock models: `a_c_pig`, `a_c_deer`, `a_c_boar`, `a_c_hen`
Config.Models = { `a_c_cow` }

Config.FlockSize = { 5, 9 }     -- min, max animals per herd
Config.SpreadAlong = 10.0       -- metres the herd spreads each way along the road
Config.SpreadSide = 3.5         -- metres each way across the road
Config.WanderRadius = 7.0       -- metres the animals wander from the herd centre
Config.Invincible = false       -- true: animals cannot be killed or run over

--------------------------------------------------------------------------------
-- Random herds: appear ahead of a driver on a quiet road in a rural zone
--------------------------------------------------------------------------------

Config.Random = {
    Enabled = true,
    Chance = 0.12,              -- chance per check, 0.0 - 1.0
    CheckMs = 6000,             -- milliseconds between checks
    CooldownSec = 240,          -- seconds before the same player can trigger another herd
    Ahead = 170.0,              -- metres down the road the herd appears, out of sight
    MinSpeed = 8.0,             -- m/s, no herds while crawling or parked
    MaxDensity = 4,             -- road traffic density 0-15; highways and main roads sit above this
    CarsOnly = true,            -- false: bikes, quads and trucks trigger herds too
    Hours = false,              -- false = any time, or { from, to } in game hours, e.g. { 6, 21 }

    -- Zones where random herds can appear (GetNameOfZone names).
    Zones = {
        'GRAPES', 'SANDY', 'ALAMO', 'HARMO', 'MTCHIL', 'PALFOR', 'PALCOV', 'PALETO', 'BRADP', 'BRADT',
        'CCREAK', 'CMSW', 'NCHU', 'CHU', 'ZANCUDO', 'RTRAK', 'DESRT', 'SLAB', 'TONGVAH', 'TONGVAV', 'GALFISH',
        'CANNY', 'MTGORDO', 'LAGO', 'PALHIGH', 'CHIL', 'MTJOSE', 'SANCHIA', 'GREATC',
    },
}

--------------------------------------------------------------------------------
-- Fixed herds: always on the road when someone comes near
--------------------------------------------------------------------------------

-- vec4(x, y, z, heading along the road). Leave empty for none.
Config.Spots = {
    vec4(1498.88, 1550.54, 109.76, 356.3),
}

Config.Fixed = {
    Range = 200.0,              -- metres: a player this close raises the herd
    LifetimeSec = 600,          -- seconds a fixed herd stays if nobody shifts it
    RespawnSec = 300,           -- seconds before it can return, and only after the area has been empty
}

--------------------------------------------------------------------------------
-- The horn
--------------------------------------------------------------------------------

Config.Horn = {
    Enabled = true,             -- false: the herd never moves, drive round it
    Control = 86,               -- 86 = INPUT_VEH_HORN
    Range = 35.0,               -- metres from the herd centre
    DriverOnly = true,          -- only the driver can sound the horn
    FleeDistance = 80.0,        -- metres the animals run
    DespawnSec = 25,            -- seconds after scattering before the herd is removed
}

--------------------------------------------------------------------------------
-- Server limits
--------------------------------------------------------------------------------

Config.Limits = {
    MaxHerds = 6,               -- random herds alive at once, server wide
    MinGap = 300.0,             -- metres between two herds
    LifetimeSec = 180,          -- seconds a random herd lives
    DespawnDistance = 260.0,    -- metres: a herd with no player this close is removed
    TickMs = 5000,              -- milliseconds between server sweeps
}

--------------------------------------------------------------------------------
-- Tools
--------------------------------------------------------------------------------

-- Admin command that puts a herd 25 m in front of you. false = no command.
-- Needs permission: add_ace group.admin command.livestock allow
Config.TestCommand = 'livestock'

Config.Debug = false            -- print spawns, removals and scatters to the server console
