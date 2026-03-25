local Math = require("dredwork_core.math")
-- Dark Legacy — Cultural Memory ("The Weight")
-- The accumulated identity of the lineage. It is the ancestor. It is you.
-- Tracks trait priorities, reputation, taboos, blind spots, and faction relationships.

local cultural_thresholds = require("dredwork_genetics.config.cultural_thresholds")

local CulturalMemory = {}
CulturalMemory.__index = CulturalMemory

-- Doctrine modifiers (set externally before decay/update)
CulturalMemory._doctrine_taboo_decay_mult = 1.0
CulturalMemory._doctrine_relationship_decay_mult = 1.0
CulturalMemory._doctrine_cultural_shift_speed = 1.0  -- multiplier on heir_weight
CulturalMemory._doctrine_blind_spot_pierce = false    -- if true, suppresses blind spots

-- Custom effect modifiers (set externally by WorldController)
CulturalMemory._custom_decay_mult = 1.0
CulturalMemory._custom_relationship_bonus = 0
CulturalMemory._cultural_memory_shift_mult = 1.0

--- Create a new cultural memory (start of a lineage).
---@return table CulturalMemory instance
function CulturalMemory.new()
    local self = setmetatable({}, CulturalMemory)

    -- Running weighted average of what the family values (per trait)
    self.trait_priorities = {}

    -- Reputation archetype
    self.reputation = {
        primary = "unknown",
        secondary = "unknown",
        era_modifier = "ancient",
    }

    -- Events that created permanent restrictions
    self.taboos = {}

    -- Categories the family can't see weaknesses in
    self.blind_spots = {}

    -- Inherited faction relationships
    self.relationships = {}

    return self
end

--- Update cultural memory after a generation passes.
--- The heir's traits contribute to family priorities, then decay applies.
---@param heir table Genome of the heir that just lived
---@param momentum_bonuses table|nil map of { [category_key] = true } for decay resistance
function CulturalMemory:update(heir, momentum_bonuses)
    local heir_weight = cultural_thresholds.heir_weight * CulturalMemory._doctrine_cultural_shift_speed * (CulturalMemory._cultural_memory_shift_mult or 1.0)
    local base_decay = cultural_thresholds.trait_priority_decay

    for id, trait in pairs(heir.traits) do
        local prefix = id:sub(1, 3)
        local catKey = ({ PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" })[prefix]
        
        local decay_rate = base_decay
        if momentum_bonuses and catKey and momentum_bonuses[catKey] then
            -- Ascending categories decay 50% slower
            decay_rate = decay_rate * 0.5
        end
        decay_rate = decay_rate * (CulturalMemory._custom_decay_mult or 1.0)

        local current = self.trait_priorities[id] or 50
        -- Decay toward baseline (50)
        current = current * (1 - decay_rate) + 50 * decay_rate
        -- Add heir contribution
        local heir_val = trait:get_value()
        current = current + (heir_val - 50) * heir_weight
        self.trait_priorities[id] = Math.clamp(current, 0, 100)
    end

    -- Update taboos
    self:_decay_taboos()

    -- Update relationships
    self:_decay_relationships()

    -- Recalculate blind spots
    self:_calculate_blind_spots()

    -- Recalculate reputation
    self:_calculate_reputation()
end

--- Apply generational decay to all tracked values.
function CulturalMemory:decay()
    self:_decay_taboos()
    self:_decay_relationships()
end

--- Add a taboo from a traumatic event.
---@param trigger string what caused it
---@param generation number when it happened
---@param effect string what it locks out
---@param strength number initial strength (0-100)
function CulturalMemory:add_taboo(trigger, generation, effect, strength)
    self.taboos[#self.taboos + 1] = {
        trigger = trigger,
        generation = generation,
        effect = effect,
        strength = strength or 85,
    }
end

--- Add or update a faction relationship.
---@param faction string faction identifier
---@param rel_type string "ally" | "enemy"
---@param origin_gen number generation it originated
---@param strength number relationship strength
---@param reason string why this relationship exists
function CulturalMemory:add_relationship(faction, rel_type, origin_gen, strength, reason)
    -- Check for existing relationship with this faction
    local existing = nil
    for _, rel in ipairs(self.relationships) do
        if rel.faction == faction then
            existing = rel
            break
        end
    end

    if existing then
        local old_type = existing.type
        existing.type = rel_type
        existing.strength = strength or existing.strength
        existing.reason = reason or existing.reason
        -- Only update origin_gen if the type changed
        if old_type ~= rel_type then
            existing.origin_gen = origin_gen
        end
    else
        local bonus = CulturalMemory._custom_relationship_bonus or 0
        self.relationships[#self.relationships + 1] = {
            faction = faction,
            type = rel_type,
            origin_gen = origin_gen,
            strength = (strength or 50) + bonus,
            reason = reason or "unknown",
        }
    end
end

--- Check if a taboo blocks a given effect.
---@param effect string
---@return boolean
function CulturalMemory:is_taboo(effect)
    for _, taboo in ipairs(self.taboos) do
        if taboo.effect == effect and taboo.strength >= cultural_thresholds.taboo_active_threshold then
            return true
        end
    end
    return false
end

--- Get active blind spot categories.
---@return table array of category strings
function CulturalMemory:get_blind_spots()
    return self.blind_spots
end

-- Internal: decay taboo strength, remove dead taboos.
function CulturalMemory:_decay_taboos()
    local decay = cultural_thresholds.taboo_decay_rate * CulturalMemory._doctrine_taboo_decay_mult
    local threshold = cultural_thresholds.taboo_remove_threshold
    local live = {}
    for _, taboo in ipairs(self.taboos) do
        taboo.strength = taboo.strength * (1 - decay)
        if taboo.strength >= threshold then
            live[#live + 1] = taboo
        end
    end
    self.taboos = live
end

-- Internal: decay relationship strength, remove dead relationships.
function CulturalMemory:_decay_relationships()
    local decay = cultural_thresholds.relationship_decay_rate * CulturalMemory._doctrine_relationship_decay_mult
    local threshold = cultural_thresholds.relationship_remove_threshold
    local live = {}
    for _, rel in ipairs(self.relationships) do
        rel.strength = rel.strength * (1 - decay)
        if rel.strength >= threshold then
            live[#live + 1] = rel
        end
    end
    self.relationships = live
end

-- Internal: calculate blind spots from trait priorities.
function CulturalMemory:_calculate_blind_spots()
    -- Doctrine: blind spot pierce suppresses all blind spots
    if CulturalMemory._doctrine_blind_spot_pierce then
        self.blind_spots = {}
        return
    end

    -- If any category average priority > 70, the lowest category becomes a blind spot
    local category_avgs = { physical = {}, mental = {}, social = {}, creative = {} }
    for id, priority in pairs(self.trait_priorities) do
        local prefix = id:sub(1, 3)
        local cat = ({ PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" })[prefix]
        if cat then
            local t = category_avgs[cat]
            t[#t + 1] = priority
        end
    end

    local avgs = {}
    for cat, vals in pairs(category_avgs) do
        if #vals > 0 then
            local sum = 0
            for _, v in ipairs(vals) do sum = sum + v end
            avgs[cat] = sum / #vals
        else
            avgs[cat] = 50
        end
    end

    -- Find if any category > threshold
    local has_dominant = false
    local min_cat, min_val = nil, 999
    for cat, avg in pairs(avgs) do
        if avg > cultural_thresholds.blind_spot_dominant_threshold then
            has_dominant = true
        end
        if avg < min_val then
            min_cat = cat
            min_val = avg
        end
    end

    self.blind_spots = {}
    if has_dominant and min_cat then
        self.blind_spots[1] = min_cat
    end
end

-- Internal: calculate reputation archetype from trait priorities.
function CulturalMemory:_calculate_reputation()
    local category_avgs = { physical = 0, mental = 0, social = 0, creative = 0 }
    local counts = { physical = 0, mental = 0, social = 0, creative = 0 }

    for id, priority in pairs(self.trait_priorities) do
        local prefix = id:sub(1, 3)
        local cat = ({ PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" })[prefix]
        if cat then
            category_avgs[cat] = category_avgs[cat] + priority
            counts[cat] = counts[cat] + 1
        end
    end

    for cat, total in pairs(category_avgs) do
        if counts[cat] > 0 then
            category_avgs[cat] = total / counts[cat]
        end
    end

    -- Sort categories by average priority
    local sorted = {}
    for cat, avg in pairs(category_avgs) do
        sorted[#sorted + 1] = { cat = cat, avg = avg }
    end
    table.sort(sorted, function(a, b) return a.avg > b.avg end)

    local archetypes = {
        physical = "warriors",
        mental = "scholars",
        social = "diplomats",
        creative = "artisans",
    }

    self.reputation.primary = archetypes[sorted[1].cat] or "unknown"
    self.reputation.secondary = archetypes[sorted[2].cat] or "unknown"
end

--- Get the current average priority per category.
---@return table { physical = N, mental = N, social = N, creative = N }
function CulturalMemory:get_category_averages()
    local avgs = { physical = 0, mental = 0, social = 0, creative = 0 }
    local counts = { physical = 0, mental = 0, social = 0, creative = 0 }

    for id, priority in pairs(self.trait_priorities) do
        local prefix = id:sub(1, 3)
        local cat = ({ PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" })[prefix]
        if cat then
            avgs[cat] = avgs[cat] + priority
            counts[cat] = counts[cat] + 1
        end
    end

    for cat, total in pairs(avgs) do
        if counts[cat] > 0 then
            avgs[cat] = total / counts[cat]
        end
    end
    return avgs
end

--- Restore from a serialized table (from Serializer.memory_to_table).
---@param data table { trait_priorities, reputation, taboos, blind_spots, relationships }
---@return table CulturalMemory
function CulturalMemory.from_table(data)
    if not data then return CulturalMemory.new() end

    local self = setmetatable({}, CulturalMemory)
    self.trait_priorities = data.trait_priorities or {}
    self.reputation = data.reputation or { primary = "unknown", secondary = "unknown", era_modifier = "ancient" }
    self.taboos = data.taboos or {}
    self.blind_spots = data.blind_spots or {}
    self.relationships = data.relationships or {}
    return self
end

return CulturalMemory
