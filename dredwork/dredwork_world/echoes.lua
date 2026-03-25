-- Dark Legacy — The Ghost Council (Ancestral Echoes)
-- Tracks the souls of legendary ancestors that can be invoked for aid.
-- Each Echo provides specific trait bonuses or unique situational bypasses.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Echoes = {}
Echoes.__index = Echoes

--- Create a new Echo Manager.
---@return table Echoes instance
function Echoes.new()
    local self = setmetatable({}, Echoes)
    self.spirits = {} -- array of { heir_id, name, generation, traits, masteries, affinity, impact_tier }
    self.aura = 50    -- Resource for invoking echoes (0-100)
    self.max_aura = 100
    self.history = {}
    return self
end

--- Enshrine an heir as an Echo. Call when an heir dies if impact_tier is Legendary or Ruinous.
---@param heir table heir data (genome + personality + ledger)
function Echoes:enshrine(heir)
    if not heir then return end
    
    -- Filter: Only Legendary or Ruinous heirs leave strong enough imprints
    local tier = heir.impact_tier or "Common"
    if tier ~= "Legendary" and tier ~= "Ruinous" then return end

    -- Avoid duplicates
    for _, s in ipairs(self.spirits) do
        if s.name == heir.name and s.generation == heir.generation then return end
    end

    local spirit = {
        name = heir.name,
        generation = heir.generation,
        impact_tier = tier,
        traits = {},
        masteries = {},
        -- Personality affinity: descendants with similar personality invoke this ghost more effectively
        personality_axis = heir.top_personality_axis or "PER_PRI",
        personality_dir = heir.top_personality_dir or "high",
    }

    -- Snapshot top traits (above 70)
    if heir.traits then
        for id, val in pairs(heir.traits) do
            if val >= 70 then spirit.traits[id] = math.floor(val / 5) end -- Bonus granted when invoked
        end
    end

    -- Snapshot Masteries
    if heir.mastery_tags then
        for tag, _ in pairs(heir.mastery_tags) do
            spirit.masteries[#spirit.masteries + 1] = tag
        end
    end

    self.spirits[#self.spirits + 1] = spirit
end

--- Get available echoes for the current heir.
---@param current_personality table
---@return table array of spirits with a "synergy" score
function Echoes:get_invocations(current_personality)
    local available = {}
    for _, s in ipairs(self.spirits) do
        local synergy = 1.0
        if current_personality then
            local axis_val = current_personality:get_axis(s.personality_axis) or 50
            if s.personality_dir == "high" and axis_val >= 60 then
                synergy = 1.5
            elseif s.personality_dir == "low" and axis_val <= 40 then
                synergy = 1.5
            end
        end
        
        available[#available + 1] = {
            spirit = s,
            synergy = synergy,
            cost = math.floor(25 / synergy) -- Stronger synergy = lower aura cost
        }
    end
    return available
end

--- Invoke an echo. Consumes aura.
---@param spirit_name string
---@param cost number
---@return table|nil bonuses { trait_id = bonus_val }
function Echoes:invoke(spirit_name, cost)
    if self.aura < cost then return nil end
    
    local target = nil
    for _, s in ipairs(self.spirits) do
        if s.name == spirit_name then target = s; break end
    end
    
    if target then
        self.aura = self.aura - cost
        self.history[#self.history + 1] = {
            text = "Invoked the ghost of " .. target.name .. " (Gen " .. target.generation .. ")",
            aura_remaining = self.aura
        }
        while #self.history > 20 do table.remove(self.history, 1) end
        return target.traits
    end
    return nil
end

--- Replenish aura over generations.
---@param amount number
function Echoes:recharge(amount)
    self.aura = math.min(self.max_aura, self.aura + (amount or 10))
end

-- =========================================================================
-- Static Legacy Methods (Resonance System)
-- Restored for compatibility with scene_generation_advance.lua and tests
-- =========================================================================

--- Create a compact snapshot of an outgoing heir for resonance detection.
---@param genome table heir genome
---@param name string heir name
---@param gen number generation
---@return table|nil snapshot data
function Echoes.snapshot(genome, name, gen)
    if not genome then return nil end
    local snap = {
        name = name or "Unknown",
        generation = gen or 1,
        traits = {}
    }
    
    -- Filter: Only store non-hidden traits for resonance
    for id, trait in pairs(genome.traits or {}) do
        if trait.visibility ~= "hidden" then
            snap.traits[#snap.traits + 1] = { id = id, value = trait:get_value() }
        end
    end
    
    return snap
end

--- Detect if the current heir "resonates" with an ancestor snapshot.
---@param current_genome table
---@param snapshots table array of snapshots
---@param min_overlap number minimum traits to match (default 5)
---@return table|nil result { ancestor_name, overlap_count, narrative }
function Echoes.detect(current_genome, snapshots, min_overlap)
    if not current_genome or not snapshots or #snapshots == 0 then return nil end
    min_overlap = min_overlap or 5
    
    local best_match = nil
    local max_overlap = 0
    
    for _, snap in ipairs(snapshots) do
        local overlap = 0
        for _, t in ipairs(snap.traits) do
            local current_val = current_genome:get_value(t.id) or 50
            -- Match if both are high (60+) and within 10 points
            if t.value >= 60 and current_val >= 60 and math.abs(t.value - current_val) <= 10 then
                overlap = overlap + 1
            end
        end
        
        if overlap >= min_overlap and overlap > max_overlap then
            max_overlap = overlap
            best_match = snap
        end
    end
    
    if best_match then
        return {
            ancestor_name = best_match.name,
            ancestor_generation = best_match.generation,
            overlap_count = max_overlap,
            narrative = Echoes.get_narrative({
                ancestor_name = best_match.name,
                overlap_count = max_overlap
            })
        }
    end
    return nil
end

--- Filter ancestors to ensure a minimum generational gap (prevent resonance with parent).
function Echoes.filter_eligible(snapshots, current_gen, min_gap)
    min_gap = min_gap or 3
    local eligible = {}
    for _, snap in ipairs(snapshots or {}) do
        if current_gen - snap.generation >= min_gap then
            eligible[#eligible + 1] = snap
        end
    end
    return eligible
end

--- Keep snapshots to a manageable count.
function Echoes.trim(snapshots, max_count)
    max_count = max_count or 20
    while #snapshots > max_count do
        table.remove(snapshots, 1)
    end
end

--- Generate a flavor narrative for an echo detection.
function Echoes.get_narrative(echo)
    if not echo then return "" end
    local templates = {
        "The blood of {name} stirs in the heir's veins.",
        "A ghost of the past, {name}, reflected in the present.",
        "In {heir_name}, the world sees the echo of {name}.",
        "The patterns of {name} have returned to the bloodline.",
    }
    local t = templates[rng.range(1, #templates)]
    t = t:gsub("{name}", echo.ancestor_name or "an ancestor")
    t = t:gsub("{heir_name}", echo.heir_name or "the heir")
    return t
end

--- Serialize to table.
function Echoes:to_table()
    return {
        spirits = self.spirits,
        aura = self.aura,
        history = self.history
    }
end

--- Restore from table.
function Echoes.from_table(data)
    local self = Echoes.new()
    if data then
        self.spirits = data.spirits or {}
        self.aura = data.aura or 50
        self.history = data.history or {}
    end
    return self
end

return Echoes
