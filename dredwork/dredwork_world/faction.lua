local Math = require("dredwork_core.math")
-- Dark Legacy — Faction System
-- Rival houses that evolve alongside the player's lineage.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")
local starting_factions = require("dredwork_world.config.starting_factions")
local era_definitions = require("dredwork_world.config.era_definitions")

-- Faction genetics (pcall-wrapped — works without it)
local ok_fg, FactionGenetics = pcall(require, "dredwork_world.faction_genetics")
if not ok_fg then FactionGenetics = nil end

local Faction = {}
Faction.__index = Faction

--- Create a faction from a data definition.
---@param data table faction definition (from starting_factions or emergent)
---@return table Faction instance
function Faction.new(data)
    local self = setmetatable({}, Faction)

    self.id = data.id
    self.name = data.name
    self.motto = data.motto or ""
    self.category_scores = {}
    for k, v in pairs(data.category_scores or {}) do
        self.category_scores[k] = v
    end
    self.personality = {}
    for k, v in pairs(data.personality or {}) do
        self.personality[k] = v
    end
    self.reputation = {
        primary = data.reputation and data.reputation.primary or "unknown",
        secondary = data.reputation and data.reputation.secondary or "unknown",
    }
    self.power = data.power or 50
    self.status = data.status or "active"
    self.disposition = data.disposition or 0
    self._gens_neutral = data._gens_neutral or 0
    self.trait_averages = data.trait_averages

    -- Ambition system: factions pursue goals autonomously
    self.ambition = data.ambition or nil
    -- Grudge system: factions remember wrongs
    self.grudges = data.grudges or {}

    -- Initialize faction genetics if not already present
    if not self.trait_averages and FactionGenetics then
        pcall(FactionGenetics.init, self)
    end

    return self
end

--- Get the faction's dominant category (highest score).
---@return string category key
function Faction:get_dominant_category()
    local best_cat, best_val = "physical", 0
    for cat, score in pairs(self.category_scores) do
        if score > best_val then
            best_cat = cat
            best_val = score
        end
    end
    return best_cat
end

--- Evolve the faction for one generation based on world conditions.
---@param world_state table WorldState instance
---@param all_factions table|nil array of all Faction instances (for cross-faction ambition effects)
function Faction:evolve(world_state, all_factions)
    if self.status == "fallen" then return end

    local era = world_state:get_era()

    -- 1. Power drifts based on world conditions
    self:_drift_power(world_state)

    -- 2. Category scores drift toward era-valued categories
    if era then
        self:_drift_categories(era)
    end

    -- 3. Disposition drifts toward neutral per generation
    -- Positive disposition decays at 5%, hostile disposition decays faster at 8%
    if self.disposition > 0 then
        self.disposition = self.disposition * 0.95
        if self.disposition < 1 then self.disposition = 0 end
    elseif self.disposition < 0 then
        self.disposition = self.disposition * 0.92
        if self.disposition > -1 then self.disposition = 0 end
    end

    -- Grudge cap: disposition can't recover past -(intensity/2) for grudge targets
    local player_grudge = self:has_grudge("player")
    if player_grudge and self.disposition > -(player_grudge.intensity / 2) then
        self.disposition = math.floor(-(player_grudge.intensity / 2))
    end

    -- 3b. Hostility drift: factions that stay neutral (|disposition| < 15)
    -- for too long slowly drift hostile. Prevents comfortable stagnation.
    -- Track generations_neutral internally.
    self._gens_neutral = self._gens_neutral or 0
    if math.abs(self.disposition) < 15 then
        self._gens_neutral = self._gens_neutral + 1
    else
        self._gens_neutral = 0
    end

    if self._gens_neutral >= 10 then
        -- Drift hostile by -1 per gen past the threshold
        self.disposition = math.max(-100, self.disposition - 1)
    end

    -- 4. Update status
    self:_update_status()

    -- 5. Update reputation based on category scores
    self:_update_reputation()

    -- 6. Evolve faction genetics
    if FactionGenetics and self.trait_averages then
        local era_key = era and era.id or "ancient"
        pcall(FactionGenetics.evolve, self, era_key, world_state.generation or 1)
    end

    -- 7. Tick ambition
    self:_tick_ambition(world_state, all_factions)

    -- 8. Decay grudges
    self:_decay_grudges()
end

--- Shift disposition toward the player.
---@param delta number positive = friendlier, negative = more hostile
function Faction:shift_disposition(delta)
    self.disposition = Math.clamp(self.disposition + delta, -100, 100)
    -- Grudge cap: can't rise above -(intensity/2) toward grudge target
    local player_grudge = self:has_grudge("player")
    if player_grudge and self.disposition > -(player_grudge.intensity / 2) then
        self.disposition = math.floor(-(player_grudge.intensity / 2))
    end
end

--- Shift power.
---@param delta number
function Faction:shift_power(delta)
    self.power = Math.clamp(self.power + delta, 0, 100)
    self:_update_status()
end

--- Check if faction is hostile (disposition <= -50).
---@return boolean
function Faction:is_hostile()
    return self.disposition <= -50
end

--- Check if faction is friendly (disposition >= 30).
---@return boolean
function Faction:is_friendly()
    return self.disposition >= 30
end

--- Add a grudge against a target.
---@param target string "player" or faction ID
---@param reason string
---@param generation number
---@param intensity number 0-100
function Faction:add_grudge(target, reason, generation, intensity)
    -- Max 3 grudges per faction
    if #self.grudges >= 3 then
        -- Replace weakest grudge
        local weakest_idx, weakest_val = 1, 999
        for i, g in ipairs(self.grudges) do
            if g.intensity < weakest_val then
                weakest_idx = i
                weakest_val = g.intensity
            end
        end
        if intensity > weakest_val then
            self.grudges[weakest_idx] = { target = target, reason = reason, generation = generation, intensity = intensity }
        end
        return
    end
    self.grudges[#self.grudges + 1] = { target = target, reason = reason, generation = generation, intensity = intensity }
end

--- Check if faction has a grudge against a target.
---@param target string "player" or faction ID
---@return table|nil grudge or nil
function Faction:has_grudge(target)
    for _, g in ipairs(self.grudges) do
        if g.target == target then return g end
    end
    return nil
end

--- Get the active ambition type, if any.
---@return string|nil ambition type
function Faction:get_ambition_type()
    return self.ambition and self.ambition.type or nil
end

--- Serialize to plain table.
---@return table
function Faction:to_table()
    return {
        id = self.id,
        name = self.name,
        motto = self.motto,
        category_scores = self.category_scores,
        personality = self.personality,
        reputation = self.reputation,
        power = self.power,
        status = self.status,
        disposition = self.disposition,
        _gens_neutral = self._gens_neutral or 0,
        trait_averages = self.trait_averages,
        ambition = self.ambition,
        grudges = self.grudges,
    }
end

--- Restore from saved table.
---@param data table
---@return table Faction
function Faction.from_table(data)
    return Faction.new(data)
end

-- Internal: drift power based on world conditions
function Faction:_drift_power(world_state)
    local dominant = self:get_dominant_category()
    local drift = rng.range(-3, 3) -- base random drift

    -- Warriors gain power during war
    if world_state:has_condition("war") and dominant == "physical" then
        drift = drift + rng.range(2, 5)
    end
    -- Scholars suffer during war but gain during peace
    if world_state:has_condition("war") and dominant == "mental" then
        drift = drift - rng.range(1, 3)
    end
    -- Physical houses suffer during plague
    if world_state:has_condition("plague") and dominant == "physical" then
        drift = drift - rng.range(2, 4)
    end
    -- Social houses benefit during peace (no conditions)
    if #world_state.conditions == 0 and dominant == "social" then
        drift = drift + rng.range(1, 3)
    end
    -- Creative houses suffer during famine
    if world_state:has_condition("famine") and dominant == "creative" then
        drift = drift - rng.range(1, 3)
    end

    self.power = Math.clamp(self.power + drift, 0, 100)
end

-- Internal: drift category scores toward era-valued categories
function Faction:_drift_categories(era)
    local valued_set = {}
    for _, cat in ipairs(era.valued_categories) do
        valued_set[cat] = true
    end

    for cat, score in pairs(self.category_scores) do
        if valued_set[cat] then
            -- Drift up toward era values
            self.category_scores[cat] = math.min(100, score + rng.range(0, 2))
        else
            -- Slight drift down
            self.category_scores[cat] = math.max(10, score - rng.range(0, 1))
        end
    end
end

-- Internal: update status based on power
function Faction:_update_status()
    if self.power <= 10 then
        self.status = "fallen"
    elseif self.power <= 30 then
        self.status = "declining"
    elseif self.power >= 75 then
        self.status = "rising"
    else
        self.status = "active"
    end
end

-- Internal: update reputation from category scores
function Faction:_update_reputation()
    local sorted = {}
    for cat, score in pairs(self.category_scores) do
        sorted[#sorted + 1] = { cat = cat, score = score }
    end
    table.sort(sorted, function(a, b) return a.score > b.score end)

    local archetypes = {
        physical = "warriors",
        mental = "scholars",
        social = "diplomats",
        creative = "artisans",
    }

    if sorted[1] then
        self.reputation.primary = archetypes[sorted[1].cat] or "unknown"
    end
    if sorted[2] then
        self.reputation.secondary = archetypes[sorted[2].cat] or "unknown"
    end
end

-- Internal: tick ambition progress and assignment
function Faction:_tick_ambition(world_state, all_factions)
    if self.status == "fallen" then self.ambition = nil; return end

    -- If no ambition, try to assign one
    if not self.ambition then
        self:_assign_ambition(world_state)
        return
    end

    -- Progress existing ambition
    local base_progress = rng.range(5, 15)

    -- Personality fit bonus
    local fit = self:_ambition_personality_fit()
    base_progress = base_progress + fit

    self.ambition.progress = math.min(100, (self.ambition.progress or 0) + base_progress)

    -- Complete at 100% progress
    if self.ambition.progress >= 100 then
        self:_complete_ambition(all_factions)
        return
    end

    -- Expire after 15 gens
    local gen = world_state and world_state.generation or 0
    if gen - (self.ambition.started_gen or 0) > 15 then
        self.ambition = nil
        return
    end

    -- Check if gate conditions still met
    if not self:_ambition_gate_met(self.ambition.type) then
        self.ambition = nil
    end
end

-- Internal: apply ambition completion effects
function Faction:_complete_ambition(all_factions)
    local amb = self.ambition
    if not amb then return end

    local amb_type = amb.type
    local target_id = amb.target

    if amb_type == "expansion" then
        self:shift_power(10)
    elseif amb_type == "dominance" then
        self:shift_power(10)
        if target_id and all_factions then
            for _, f in ipairs(all_factions) do
                if f.id == target_id then
                    f:shift_power(-10)
                    break
                end
            end
        end
    elseif amb_type == "revenge" then
        if target_id then
            local grudge = self:has_grudge(target_id)
            if grudge then
                grudge.intensity = math.min(100, (grudge.intensity or 50) + 20)
            end
        end
    elseif amb_type == "hegemony" then
        self:shift_power(5)
        if all_factions then
            for _, f in ipairs(all_factions) do
                if f ~= self and f.status ~= "fallen" and f.disposition > 40 then
                    f:shift_power(5)
                end
            end
        end
    elseif amb_type == "survival" then
        if self.power < 40 then
            self.power = 40
            self:_update_status()
        end
    elseif amb_type == "cultural_supremacy" then
        self:shift_power(5)
    end

    self.ambition = nil
end

-- Internal: assign an ambition based on current state
function Faction:_assign_ambition(world_state)
    local gen = world_state and world_state.generation or 0
    local candidates = {}

    -- expansion: power > 60
    if self.power > 60 then
        candidates[#candidates + 1] = { type = "expansion", weight = 2 }
    end
    -- dominance: power > 70
    if self.power > 70 then
        candidates[#candidates + 1] = { type = "dominance", weight = 1 }
    end
    -- revenge: has grudge
    if #self.grudges > 0 then
        local w = 3 -- revenge is high priority
        candidates[#candidates + 1] = { type = "revenge", weight = w }
    end
    -- survival: power < 30
    if self.power < 30 then
        candidates[#candidates + 1] = { type = "survival", weight = 4 }
    end
    -- cultural_supremacy: dominant category score > 65
    local dom_cat = self:get_dominant_category()
    local dom_score = self.category_scores[dom_cat] or 50
    if dom_score > 65 then
        candidates[#candidates + 1] = { type = "cultural_supremacy", weight = 1 }
    end

    if #candidates == 0 then return end

    -- Weighted random selection
    local total = 0
    for _, c in ipairs(candidates) do total = total + c.weight end
    local roll = rng.range(1, total)
    local acc = 0
    for _, c in ipairs(candidates) do
        acc = acc + c.weight
        if roll <= acc then
            self.ambition = {
                type = c.type,
                target = nil,
                progress = 0,
                started_gen = gen,
            }
            -- Set target for directed ambitions
            if c.type == "revenge" and #self.grudges > 0 then
                self.ambition.target = self.grudges[1].target
            elseif c.type == "dominance" then
                self.ambition.target = "player"
            end
            return
        end
    end
end

-- Internal: check if ambition gate conditions are still met
function Faction:_ambition_gate_met(amb_type)
    if amb_type == "expansion" then return self.power > 50
    elseif amb_type == "dominance" then return self.power > 60
    elseif amb_type == "revenge" then return #self.grudges > 0
    elseif amb_type == "survival" then return self.power < 40
    elseif amb_type == "cultural_supremacy" then
        local dom_cat = self:get_dominant_category()
        return (self.category_scores[dom_cat] or 50) > 55
    end
    return true
end

-- Internal: personality fit bonus for ambition progress
function Faction:_ambition_personality_fit()
    local amb = self.ambition
    if not amb then return 0 end
    local p = self.personality or {}
    if amb.type == "expansion" and (p.PER_BLD or 50) > 60 then return 3 end
    if amb.type == "dominance" and (p.PER_PRI or 50) > 60 then return 3 end
    if amb.type == "revenge" and (p.PER_OBS or 50) > 60 then return 4 end
    if amb.type == "survival" and (p.PER_ADA or 50) > 60 then return 3 end
    if amb.type == "cultural_supremacy" and (p.PER_PRI or 50) > 60 then return 2 end
    return 0
end

-- Internal: decay grudges over time
function Faction:_decay_grudges()
    local live = {}
    for _, g in ipairs(self.grudges) do
        g.intensity = (g.intensity or 50) - 2
        if g.intensity > 0 then
            live[#live + 1] = g
        end
    end
    self.grudges = live
end

-- =========================================================================
-- Faction Manager: manages the collection of all factions
-- =========================================================================

local FactionManager = {}
FactionManager.__index = FactionManager

-- Doctrine modifiers (set externally by WorldController before evolve_all)
FactionManager._doctrine_disposition_drift = 0         -- per-gen positive disposition shift
FactionManager._doctrine_alliance_disp_floor = nil     -- floor for strongest ally
FactionManager._doctrine_enmity_disp_ceiling = nil     -- ceiling for strongest enemy
FactionManager._doctrine_permanent_alliance = false    -- lock strongest ally
FactionManager._doctrine_permanent_enmity = false      -- lock strongest enemy

--- Create a new faction manager with starting factions.
---@param custom_config table|nil optional overrides
---@return table FactionManager instance
function FactionManager.new(custom_config)
    local self = setmetatable({}, FactionManager)
    self.factions = {}

    local houses = starting_factions.houses
    if custom_config and custom_config.factions then
        houses = custom_config.factions
    end

    for _, def in ipairs(houses) do
        self.factions[#self.factions + 1] = Faction.new(def)
    end

    return self
end

--- Get a faction by ID.
---@param id string
---@return table|nil Faction or nil
function FactionManager:get(id)
    for _, f in ipairs(self.factions) do
        if f.id == id then return f end
    end
    return nil
end

--- Get all active (non-fallen) factions.
---@return table array of Faction
function FactionManager:get_active()
    local result = {}
    for _, f in ipairs(self.factions) do
        if f.status ~= "fallen" then
            result[#result + 1] = f
        end
    end
    return result
end

--- Get all factions (including fallen).
---@return table array of Faction
function FactionManager:get_all()
    return self.factions
end

--- Evolve all factions for one generation.
---@param world_state table WorldState instance
function FactionManager:evolve_all(world_state)
    for _, f in ipairs(self.factions) do
        f:evolve(world_state, self.factions)
    end

    -- Doctrine: per-gen disposition drift (applies to all active factions)
    if FactionManager._doctrine_disposition_drift ~= 0 then
        for _, f in ipairs(self.factions) do
            if f.status ~= "fallen" then
                f:shift_disposition(FactionManager._doctrine_disposition_drift)
            end
        end
    end

    -- Doctrine: permanent alliance — lock strongest ally's disposition floor
    if FactionManager._doctrine_permanent_alliance and FactionManager._doctrine_alliance_disp_floor then
        local best_ally, best_disp = nil, -999
        for _, f in ipairs(self.factions) do
            if f.status ~= "fallen" and f.disposition > best_disp then
                best_ally = f
                best_disp = f.disposition
            end
        end
        if best_ally and best_ally.disposition < FactionManager._doctrine_alliance_disp_floor then
            best_ally.disposition = FactionManager._doctrine_alliance_disp_floor
        end
    end

    -- Doctrine: permanent enmity — lock strongest enemy's disposition ceiling
    if FactionManager._doctrine_permanent_enmity and FactionManager._doctrine_enmity_disp_ceiling then
        local worst_enemy, worst_disp = nil, 999
        for _, f in ipairs(self.factions) do
            if f.status ~= "fallen" and f.disposition < worst_disp then
                worst_enemy = f
                worst_disp = f.disposition
            end
        end
        if worst_enemy and worst_enemy.disposition > FactionManager._doctrine_enmity_disp_ceiling then
            worst_enemy.disposition = FactionManager._doctrine_enmity_disp_ceiling
        end
    end

    -- Replace fallen factions if active count drops below 3
    local active = self:get_active()
    if #active < 3 then
        self:_spawn_emergent(world_state)
    end
end

--- Shift disposition for all factions.
---@param delta number
function FactionManager:shift_all_disposition(delta)
    for _, f in ipairs(self.factions) do
        if f.status ~= "fallen" then
            f:shift_disposition(delta)
        end
    end
end

--- Get factions sorted by disposition (most friendly first).
---@return table array of Faction
function FactionManager:get_by_disposition()
    local active = self:get_active()
    table.sort(active, function(a, b) return a.disposition > b.disposition end)
    return active
end

--- Serialize all factions to a table.
---@return table
function FactionManager:to_table()
    local result = {}
    for _, f in ipairs(self.factions) do
        result[#result + 1] = f:to_table()
    end
    return result
end

--- Restore from saved table.
---@param data table
---@return table FactionManager
function FactionManager.from_table(data)
    local self = setmetatable({}, FactionManager)
    self.factions = {}
    for _, fd in ipairs(data) do
        self.factions[#self.factions + 1] = Faction.from_table(fd)
    end
    return self
end

-- Internal: spawn a new emergent faction
function FactionManager:_spawn_emergent(world_state)
    local templates = starting_factions.emergent_templates
    local template = templates[rng.range(1, #templates)]

    -- Generate unique ID
    local id = "house_emergent_" .. tostring(world_state.generation)

    -- Generate name
    local suffixes = {
        "Ashford", "Blackthorn", "Crestfall", "Dawnmere", "Embervale",
        "Frosthollow", "Grimward", "Ironbark", "Nightshade", "Stormveil",
        "Ravencroft", "Whitepeak", "Shadowfen", "Goldmane", "Darkwater",
    }
    local name = template.name_prefix .. " " .. suffixes[rng.range(1, #suffixes)]

    local mottos = {
        "We rise from ashes.", "The new dawn breaks.", "Fortune favors the bold.",
        "From nothing, everything.", "Our time has come.", "The old ways end here.",
    }

    local category_scores = { physical = 45, mental = 45, social = 45, creative = 45 }
    category_scores[template.category_bias] = rng.range(60, 75)

    local personality = {
        PER_BLD = 50, PER_CRM = 50, PER_PRI = 50, PER_OBS = 50,
        PER_LOY = 50, PER_CUR = 50, PER_VOL = 50, PER_ADA = 50,
    }
    for k, v in pairs(template.personality_bias) do
        personality[k] = v
    end

    local faction = Faction.new({
        id = id,
        name = name,
        motto = mottos[rng.range(1, #mottos)],
        category_scores = category_scores,
        personality = personality,
        reputation = { primary = template.reputation_primary, secondary = "unknown" },
        power = rng.range(30, 50),
        status = "active",
        disposition = rng.range(-10, 10),
    })

    self.factions[#self.factions + 1] = faction
end

-- Export both
return {
    Faction = Faction,
    FactionManager = FactionManager,
}
