Config = {}

-- Animals a flock can be made of. One model is picked per flock.
-- GTA has no sheep model: add a streamed addon model here if you have one.
Config.Models = { `a_c_cow` }

Config.FlockSize = { 5, 9 }     -- min, max animals per flock

-- Random flocks (only the driver of a car, on a backroad, in a rural zone)
Config.Chance = 0.12            -- chance per check
Config.CheckMs = 6000           -- time between checks
Config.CooldownMs = 4 * 60000   -- minimum time between two random flocks
Config.Ahead = 170.0            -- metres down the road the flock appears, out of sight
Config.MinSpeed = 8.0           -- m/s, no flocks while crawling or parked

-- Traffic density of a road node, 0-15. Highways and main roads sit above this.
Config.MaxDensity = 4

-- Control held to scatter the flock. 86 = INPUT_VEH_HORN
Config.HornControl = 86
Config.HornRange = 35.0         -- metres

-- Zones where random flocks can appear (GetNameOfZone names).
Config.RuralZones = {
    'GRAPES', 'SANDY', 'ALAMO', 'HARMO', 'MTCHIL', 'PALFOR', 'PALCOV', 'PALETO', 'BRADP', 'BRADT',
    'CCREAK', 'CMSW', 'NCHU', 'CHU', 'ZANCUDO', 'RTRAK', 'DESRT', 'SLAB', 'TONGVAH', 'TONGVAV', 'GALFISH', 'CANNY',
    'MTGORDO', 'LAGO', 'PALHIGH', 'CHIL', 'MTJOSE', 'SANCHIA', 'GREATC',
}

-- Fixed flocks: always on the road when someone comes near. vec4(x, y, z, road heading).
-- A spot that is not on a backroad is skipped (turn Debug on to see why).
Config.Spots = {
    vec4(1498.88, 1550.54, 109.76, 356.3),
}

Config.Debug = false            -- print skipped spots to the F8 console
