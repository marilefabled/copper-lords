-- Dark Legacy — Geography & Landmarks
-- Tracks the physical world of Caldemyr, including regions and dangerous 'Passes'.
-- Pure Lua, zero Solar2D dependencies.

local Geography = {}
Geography.__index = Geography

Geography.REGIONS = {
    gray_wastes = {
        id = "gray_wastes",
        name = "The Gray Wastes",
        description = "A desolation of ash and silence. No one rules here for long.",
        danger = 0.8,
        fertility = 0.1,
    },
    iron_hills = {
        id = "iron_hills",
        name = "The Iron Hills",
        description = "Rich in ore, but the terrain is a jagged maze of sharp stone.",
        danger = 0.5,
        fertility = 0.3,
    },
    low_veldt = {
        id = "low_veldt",
        name = "The Low Veldt",
        description = "Fertile plains that have seen a thousand years of blood.",
        danger = 0.2,
        fertility = 0.9,
    }
}

Geography.PASSES = {
    iron_pass = {
        id = "iron_pass",
        name = "The Iron Pass",
        region_a = "iron_hills",
        region_b = "gray_wastes",
        difficulty = 0.7,
        description = "A narrow, wind-swept gap between the jagged peaks."
    },
    shadow_pass = {
        id = "shadow_pass",
        name = "The Pass of Shadows",
        region_a = "low_veldt",
        region_b = "gray_wastes",
        difficulty = 0.8,
        description = "Where the sunlight never reaches the valley floor."
    }
}

function Geography.new()
    local self = setmetatable({}, Geography)
    self.active_events = {}
    return self
end

--- Get a pass by ID.
function Geography.get_pass(pass_id)
    return Geography.PASSES[pass_id]
end

--- Get a region by ID.
function Geography.get_region(region_id)
    return Geography.REGIONS[region_id]
end

return Geography
