local Math = require("dredwork_core.math")
-- Dark Legacy — Genome Module
-- A Genome holds the complete set of traits + alleles for one individual.
-- It is the fundamental data object representing a character's genetics.

local Trait = require("dredwork_genetics.trait")
local trait_definitions = require("dredwork_genetics.config.trait_definitions")
local rng = require("dredwork_core.rng")

local Genome = {}
Genome.__index = Genome

--- Create a new genome. If no trait values are provided, generates from
--- population baseline (normal distribution, mean 50, stddev 12).
---@param overrides table|nil optional { [trait_id] = value } to override defaults
---@return table Genome instance
function Genome.new(overrides)
    local self = setmetatable({}, Genome)
    self.traits = {}  -- keyed by trait ID
    overrides = overrides or {}

    for _, def in ipairs(trait_definitions) do
        local value = overrides[def.id]
        if not value then
            -- Population baseline: normal distribution, mean 50, stddev 12
            value = math.floor(rng.normal(50, 12))
            value = Math.clamp(value, 0, 100)
        end
        self.traits[def.id] = Trait.new({
            id = def.id,
            name = def.name,
            value = value,
            category = def.category,
            scale = def.scale,
            visibility = def.visibility,
            inheritance_mode = def.inheritance_mode,
            description = def.description,
        })
    end

    return self
end

--- Get a trait by ID.
---@param id string e.g. "PHY_STR"
---@return table|nil Trait or nil if not found
function Genome:get_trait(id)
    return self.traits[id]
end

--- Get the expressed value of a trait by ID.
---@param id string
---@return number|nil
function Genome:get_value(id)
    local t = self.traits[id]
    if t then return t:get_value() end
    return nil
end

--- Set the value of a trait by ID.
---@param id string
---@param value number 0-100
function Genome:set_value(id, value)
    local t = self.traits[id]
    if t then t:set_value(value) end
end

--- Deep clone this genome.
---@return table Genome new independent copy
function Genome:clone()
    local copy = setmetatable({}, Genome)
    copy.traits = {}
    for id, trait in pairs(self.traits) do
        copy.traits[id] = trait:clone()
    end
    copy.mastery_tags = {}
    if self.mastery_tags then
        for k, v in pairs(self.mastery_tags) do
            copy.mastery_tags[k] = v
        end
    end
    return copy
end

--- Get all traits in a given category.
---@param category string "physical" | "mental" | "social" | "creative"
---@return table array of Trait objects
function Genome:get_category(category)
    local results = {}
    for _, trait in pairs(self.traits) do
        if trait.category == category then
            results[#results + 1] = trait
        end
    end
    return results
end

--- Get count of traits.
---@return number
function Genome:trait_count()
    local count = 0
    for _ in pairs(self.traits) do
        count = count + 1
    end
    return count
end

--- Restore a genome from a serialized table (from Serializer.genome_to_table).
---@param data table { traits = { [id] = { id, value, category, ... } } }
---@return table Genome
function Genome.from_table(data)
    if not data or not data.traits then
        return Genome.new()
    end

    local self = setmetatable({}, Genome)
    self.traits = {}
    self.mastery_tags = data.mastery_tags or {}

    for _, def in ipairs(trait_definitions) do
        local saved = data.traits[def.id]
        local value = saved and saved.value or 50
        local trait = Trait.new({
            id = def.id,
            name = def.name,
            value = value,
            category = def.category,
            scale = def.scale,
            visibility = def.visibility,
            inheritance_mode = def.inheritance_mode,
            description = def.description,
        })
        -- Restore alleles if present
        if saved and saved.alleles then
            trait.alleles = {
                { value = saved.alleles[1].value, dominant = saved.alleles[1].dominant },
                { value = saved.alleles[2].value, dominant = saved.alleles[2].dominant },
            }
        end
        self.traits[def.id] = trait
    end

    return self
end

return Genome
