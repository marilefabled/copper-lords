-- Dark Legacy — Reliquary (Inheritable Artifacts)
-- Tracks items of power forged or found by the lineage.
-- Artifacts persist across generations, providing tangible bonuses and narrative weight.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Reliquary = {}
Reliquary.__index = Reliquary

--- Create a new Reliquary.
---@return table Reliquary instance
function Reliquary.new()
    local self = setmetatable({}, Reliquary)
    self.artifacts = {} -- array of artifact objects
    return self
end

--- Add a new artifact to the reliquary.
---@param artifact table { id, name, type, effect, forged_by, forged_gen, description }
function Reliquary:add_artifact(artifact)
    self.artifacts[#self.artifacts + 1] = {
        id = artifact.id or ("art_" .. tostring(os.time()) .. tostring(rng.range(1, 1000))),
        name = artifact.name or "Unknown Relic",
        type = artifact.type or "heirloom", -- weapon, tome, relic, crown
        effect = artifact.effect or {}, -- { trait_bonus = { PHY_STR = 5 }, lineage_power_floor = 10 }
        forged_by = artifact.forged_by or "unknown",
        forged_gen = artifact.forged_gen or 1,
        description = artifact.description or "An artifact of the bloodline.",
        history = {}, -- chronicle of who wielded it and what they did
    }
end

--- Lose an artifact (stolen, destroyed, given away).
---@param artifact_name string
---@return boolean success
function Reliquary:lose_artifact(artifact_name)
    for i, art in ipairs(self.artifacts) do
        if art.name == artifact_name or art.id == artifact_name then
            table.remove(self.artifacts, i)
            return true
        end
    end
    return false
end

--- Record an event in an artifact's history.
---@param artifact_id string
---@param text string
---@param generation number
function Reliquary:record_history(artifact_id, text, generation)
    for _, art in ipairs(self.artifacts) do
        if art.id == artifact_id or art.name == artifact_id then
            art.history[#art.history + 1] = { text = text, generation = generation }
            while #art.history > 15 do table.remove(art.history, 1) end
            break
        end
    end
end

--- Get all active effects from artifacts.
---@return table aggregated effects
function Reliquary:get_effects()
    local aggregated = {
        trait_bonuses = {},
        lineage_power_bonus = 0,
        wealth_bonus = 0,
        mutation_pressure_reduction = 0,
    }
    
    for _, art in ipairs(self.artifacts) do
        if art.effect.trait_bonus then
            for trait_id, bonus in pairs(art.effect.trait_bonus) do
                aggregated.trait_bonuses[trait_id] = (aggregated.trait_bonuses[trait_id] or 0) + bonus
            end
        end
        if art.effect.lineage_power_bonus then
            aggregated.lineage_power_bonus = aggregated.lineage_power_bonus + art.effect.lineage_power_bonus
        end
        if art.effect.wealth_bonus then
            aggregated.wealth_bonus = aggregated.wealth_bonus + art.effect.wealth_bonus
        end
        if art.effect.mutation_pressure_reduction then
            aggregated.mutation_pressure_reduction = aggregated.mutation_pressure_reduction + art.effect.mutation_pressure_reduction
        end
    end
    
    return aggregated
end

--- Get a random artifact (for events like theft).
---@return table|nil
function Reliquary:get_random()
    if #self.artifacts == 0 then return nil end
    return self.artifacts[rng.range(1, #self.artifacts)]
end

--- Serialize to plain table.
---@return table
function Reliquary:to_table()
    return { artifacts = self.artifacts }
end

--- Restore from saved table.
---@param data table
---@return table Reliquary
function Reliquary.from_table(data)
    local self = setmetatable({}, Reliquary)
    self.artifacts = data and data.artifacts or {}
    return self
end

return Reliquary
