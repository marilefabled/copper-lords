-- Dark Legacy — Great Works System
-- Multi-generation projects that provide permanent bonuses when completed.
-- Council action "BEGIN GREAT WORK" starts one; sustained investment completes it.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local GreatWorks = {}
GreatWorks.__index = GreatWorks

--- Great work templates keyed by era / trait category.
GreatWorks.templates = {
    { id = "the_iron_wall", label = "The Iron Wall",
      era = "iron", category = "physical",
      requires_trait = "PHY_END", requires_value = 55,
      investment_gens = 3,
      effect = { trait_bonus = { PHY_END = 3, PHY_VIT = 2 } },
      flavor = "A fortification to outlast empires.",
      completion_flavor = "The wall stands — a monument to endurance." },

    { id = "the_great_library", label = "The Great Library",
      era = "ancient", category = "mental",
      requires_trait = "MEN_INT", requires_value = 55,
      investment_gens = 4,
      effect = { trait_bonus = { MEN_INT = 3, MEN_MEM = 2 } },
      flavor = "A warehouse for other people's conclusions.",
      completion_flavor = "The shelves are full. The scholars argue about the cataloguing system." },

    { id = "the_cathedral", label = "The Cathedral",
      era = "dark", category = "creative",
      requires_trait = "CRE_ARC", requires_value = 50,
      investment_gens = 5,
      effect = { trait_bonus = { CRE_ARC = 3, CRE_SYM = 2 }, zealotry_bonus = 15 },
      flavor = "An expensive argument with gravity.",
      completion_flavor = "It stands. The bloodline is surprised every morning." },

    { id = "the_academy", label = "The Academy",
      era = "arcane", category = "mental",
      requires_trait = "MEN_ABS", requires_value = 55,
      investment_gens = 4,
      effect = { trait_bonus = { MEN_ABS = 3, MEN_LRN = 3 } },
      flavor = "A place where confusion is given a curriculum.",
      completion_flavor = "Graduates emerge. Some of them are useful." },

    { id = "the_colosseum", label = "The Colosseum",
      era = "ancient", category = "physical",
      requires_trait = "PHY_STR", requires_value = 55,
      investment_gens = 3,
      effect = { trait_bonus = { PHY_STR = 2, SOC_INM = 3 } },
      flavor = "An arena. The admission price is blood.",
      completion_flavor = "The crowds come. They always come." },

    { id = "the_grand_bazaar", label = "The Grand Bazaar",
      era = "gilded", category = "social",
      requires_trait = "SOC_NEG", requires_value = 50,
      investment_gens = 3,
      effect = { trait_bonus = { SOC_NEG = 3, SOC_AWR = 2 } },
      flavor = "A controlled environment for mutual exploitation.",
      completion_flavor = "Everyone leaves convinced they got the better deal. No one did." },

    { id = "the_observatory", label = "The Observatory",
      era = "arcane", category = "creative",
      requires_trait = "CRE_VIS", requires_value = 55,
      investment_gens = 4,
      effect = { trait_bonus = { MEN_PAT = 3, CRE_VIS = 2 }, mutation_pressure_reduction = 3 },
      flavor = "A very expensive way to stare at the ceiling.",
      completion_flavor = "The stars have not moved. The astronomers have not noticed." },

    { id = "the_forge_eternal", label = "The Forge Eternal",
      era = "iron", category = "creative",
      requires_trait = "CRE_CRA", requires_value = 55,
      investment_gens = 4,
      effect = { trait_bonus = { CRE_CRA = 3, CRE_MEC = 2, PHY_STR = 2 } },
      flavor = "The heat bill alone bankrupted a lesser house.",
      completion_flavor = "It produces. The accountants weep at the fuel costs." },

    { id = "the_diplomatic_quarter", label = "The Diplomatic Quarter",
      era = "gilded", category = "social",
      requires_trait = "SOC_CHA", requires_value = 55,
      investment_gens = 3,
      effect = { trait_bonus = { SOC_CHA = 2, SOC_ELO = 3 }, disposition_bonus = 10 },
      flavor = "A building where enemies sit in comfortable chairs and lie to each other.",
      completion_flavor = "The treaties are signed. The ink is not yet dry before the first violation." },

    { id = "the_twilight_spire", label = "The Twilight Spire",
      era = "twilight", category = "mental",
      requires_trait = "MEN_WIL", requires_value = 60,
      investment_gens = 5,
      effect = { trait_bonus = { MEN_WIL = 4, MEN_STH = 3 }, mutation_pressure_reduction = 5 },
      flavor = "Built to the precise specifications of the bloodline's obsession.",
      completion_flavor = "It endures. Whether anyone remembers why it was built is another matter." },
}

--- Create a new great works tracker.
---@return table GreatWorks instance
function GreatWorks.new()
    local self = setmetatable({}, GreatWorks)
    self.completed = {}       -- array of { id, label, generation_started, generation_completed, builder, effect, flavor }
    self.in_progress = nil    -- { id, label, generation_started, investment_remaining, effect, flavor } or nil
    return self
end

--- Get available great works for this era/heir.
---@param genome table Genome of current heir
---@param era_key string current era
---@return table array of matching templates
function GreatWorks:get_available(genome, era_key)
    if self.in_progress then return {} end -- only one at a time

    local available = {}
    local completed_ids = {}
    for _, c in ipairs(self.completed) do
        completed_ids[c.id] = true
    end

    for _, tmpl in ipairs(GreatWorks.templates) do
        if not completed_ids[tmpl.id] and tmpl.era == era_key then
            -- Check trait requirement
            local val = genome and genome:get_value(tmpl.requires_trait) or 0
            if val >= tmpl.requires_value then
                available[#available + 1] = tmpl
            end
        end
    end

    return available
end

--- Start a great work.
---@param template_id string
---@param generation number
---@param heir_name string
---@param initial_progress number|nil
---@return boolean success
function GreatWorks:start(template_id, generation, heir_name, initial_progress)
    if self.in_progress then return false end

    for _, tmpl in ipairs(GreatWorks.templates) do
        if tmpl.id == template_id then
            self.in_progress = {
                id = tmpl.id,
                label = tmpl.label,
                generation_started = generation,
                investment_remaining = tmpl.investment_gens - (initial_progress or 0),
                effect = tmpl.effect,
                flavor = tmpl.flavor,
                completion_flavor = tmpl.completion_flavor,
                builder = heir_name,
            }
            return true
        end
    end
    return false
end

--- Invest one generation into the current great work.
---@param generation number
---@param heir_name string
---@return table|nil completion data if just completed
function GreatWorks:invest(generation, heir_name)
    if not self.in_progress then return nil end

    self.in_progress.investment_remaining = self.in_progress.investment_remaining - 1

    if self.in_progress.investment_remaining <= 0 then
        -- Completed!
        local completed = {
            id = self.in_progress.id,
            label = self.in_progress.label,
            generation_started = self.in_progress.generation_started,
            generation_completed = generation,
            builder = self.in_progress.builder,
            completer = heir_name,
            effect = self.in_progress.effect,
            flavor = self.in_progress.completion_flavor or self.in_progress.flavor,
        }
        self.completed[#self.completed + 1] = completed
        self.in_progress = nil
        return completed
    end

    return nil
end

--- Abandon the current great work.
---@return table|nil the abandoned work info
function GreatWorks:abandon()
    if not self.in_progress then return nil end
    local abandoned = self.in_progress
    self.in_progress = nil
    return abandoned
end

--- Get aggregated effects from all completed great works.
---@return table { trait_bonuses, mutation_pressure_reduction, zealotry_bonus, disposition_bonus }
function GreatWorks:get_effects()
    local effects = {
        trait_bonuses = {},
        mutation_pressure_reduction = 0,
        zealotry_bonus = 0,
        disposition_bonus = 0,
    }

    for _, work in ipairs(self.completed) do
        if work.effect then
            if work.effect.trait_bonus then
                for trait, bonus in pairs(work.effect.trait_bonus) do
                    effects.trait_bonuses[trait] = (effects.trait_bonuses[trait] or 0) + bonus
                end
            end
            if work.effect.mutation_pressure_reduction then
                effects.mutation_pressure_reduction = effects.mutation_pressure_reduction +
                    work.effect.mutation_pressure_reduction
            end
            if work.effect.zealotry_bonus then
                effects.zealotry_bonus = effects.zealotry_bonus + work.effect.zealotry_bonus
            end
            if work.effect.disposition_bonus then
                effects.disposition_bonus = effects.disposition_bonus + work.effect.disposition_bonus
            end
        end
    end

    return effects
end

--- Count completed great works.
---@return number
function GreatWorks:count()
    return #self.completed
end

--- Check if a great work is in progress.
---@return boolean
function GreatWorks:is_building()
    return self.in_progress ~= nil
end

--- Get display info.
---@return table
function GreatWorks:get_display()
    return {
        completed = self.completed,
        in_progress = self.in_progress,
    }
end

--- Serialize to plain table.
---@return table
function GreatWorks:to_table()
    return {
        completed = self.completed,
        in_progress = self.in_progress,
    }
end

--- Restore from saved table.
---@param data table
---@return table GreatWorks
function GreatWorks.from_table(data)
    local self = setmetatable({}, GreatWorks)
    self.completed = data and data.completed or {}
    self.in_progress = data and data.in_progress or nil
    return self
end

return GreatWorks
