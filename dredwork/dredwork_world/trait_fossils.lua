-- Dark Legacy — Trait Fossils ("Echoes of Greatness")
-- Tracks peak trait values across the lineage history.
-- When a trait that once peaked at 75+ has since dropped 25+ points,
-- it becomes a "fossil" — a record of lost greatness.
-- Creates a restoration loop: breed back what was lost.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")
local TraitFossils = {}

local trait_definitions = require("dredwork_genetics.config.trait_definitions")

-- Build name lookup from trait definitions
local trait_names = {}
for _, def in ipairs(trait_definitions) do
    trait_names[def.id] = def.name
end

local narratives = {
    "Your bloodline once possessed legendary %s. That fire has dimmed.",
    "The blood remembers when %s was the family's crown. Those days are gone.",
    "%s once defined this lineage. Now it is only a memory.",
    "Generations ago, %s burned bright in the bloodline. Only embers remain.",
}

--- Update peak tracking after each generation.
--- Mutates peaks table in-place.
---@param peaks table { [trait_id] = { value, generation, heir_name } }
---@param heir_genome table Genome instance
---@param generation number current generation
---@param heir_name string
function TraitFossils.update_peaks(peaks, heir_genome, generation, heir_name)
    if not peaks or not heir_genome then return end

    local all_traits = heir_genome.traits or {}
    for id, trait in pairs(all_traits) do
        local val = trait:get_value()
        local existing = peaks[id]
        if not existing or val > existing.value then
            peaks[id] = {
                value = val,
                generation = generation,
                heir_name = heir_name or "Unknown",
            }
        end
    end
end

--- Detect active fossils (traits that peaked high and have since declined).
---@param peaks table peak tracking data
---@param current_heir_genome table Genome instance
---@return table array of fossil records
function TraitFossils.detect(peaks, current_heir_genome)
    if not peaks or not current_heir_genome then return {} end

    local fossils = {}
    for id, peak in pairs(peaks) do
        if peak.value >= 75 then
            local current_val = current_heir_genome:get_value(id) or 50
            local gap = peak.value - current_val
            if gap >= 25 then
                fossils[#fossils + 1] = {
                    trait_id = id,
                    trait_name = trait_names[id] or id,
                    peak_value = peak.value,
                    peak_generation = peak.generation,
                    peak_heir = peak.heir_name,
                    current_value = current_val,
                    gap = gap,
                }
            end
        end
    end

    -- Sort by gap descending (most dramatic loss first)
    table.sort(fossils, function(a, b) return a.gap > b.gap end)

    return fossils
end

--- Check if any fossil was "restored" this generation.
--- Restored = current value within 10 of the peak.
---@param peaks table peak tracking data
---@param current_heir_genome table Genome instance
---@param previous_fossils table array of fossils from last generation
---@return table array of restoration records
function TraitFossils.check_restorations(peaks, current_heir_genome, previous_fossils)
    if not peaks or not current_heir_genome or not previous_fossils then return {} end

    local restorations = {}
    for _, fossil in ipairs(previous_fossils) do
        local current_val = current_heir_genome:get_value(fossil.trait_id) or 50
        if current_val >= fossil.peak_value - 10 then
            restorations[#restorations + 1] = {
                trait_id = fossil.trait_id,
                trait_name = fossil.trait_name,
                peak_heir = fossil.peak_heir,
                peak_value = fossil.peak_value,
                current_value = current_val,
            }
        end
    end

    return restorations
end

--- Get narrative text for a fossil.
---@param fossil table a single fossil record
---@return string
function TraitFossils.get_narrative(fossil)
    if not fossil then return "" end
    local template = narratives[rng.range(1, #narratives)]
    return string.format(template, fossil.trait_name)
end

--- Serialize peaks for save/load.
---@param peaks table
---@return table
function TraitFossils.to_table(peaks)
    return peaks
end

--- Deserialize peaks from save.
---@param data table
---@return table
function TraitFossils.from_table(data)
    return data or {}
end

return TraitFossils
