-- Dark Legacy — Birth Event Resolver
-- Determines special birth events: twins, difficult births, miraculous births.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Births = {}

--- Resolve birth events for a set of children.
-- Checks for twins, difficult births, and miraculous births.
---@param num_children number planned number of children
---@param heir_genome table Genome of the heir parent
---@param mate_genome table|nil Genome of the mate parent
---@param conditions table array of { type, intensity } from world_state
---@param generation number current generation
---@return table { children_metadata = array, birth_event = string|nil, adjusted_count = number }
function Births.resolve(num_children, heir_genome, mate_genome, conditions, generation)
    conditions = conditions or {}
    num_children = num_children or 2

    local metadata = {}
    local birth_event = nil
    local adjusted_count = num_children

    -- Check fertility for twin chance modifier
    local fertility = (heir_genome:get_value("PHY_FER") or 50) / 100
    local vitality = (heir_genome:get_value("PHY_VIT") or 50) / 100

    -- Count active conditions
    local condition_count = #conditions

    -- TWINS check (applied once, not per-child)
    local twin_chance = 0.04  -- 4% base (rare but meaningful)
    if fertility > 0.75 then
        twin_chance = twin_chance + 0.03
    end
    twin_chance = twin_chance + condition_count * 0.01

    local has_twins = false
    local twin_pair_id = nil
    if rng.chance(twin_chance) and adjusted_count >= 1 then
        has_twins = true
        twin_pair_id = "twin_" .. generation .. "_" .. rng.range(1000, 9999)
        -- If only 1 child, bump to 2 for twins (max 4)
        if adjusted_count < 2 then
            adjusted_count = 2
        end
        -- Cap at 4
        if adjusted_count > 4 then
            adjusted_count = 4
        end
    end

    -- MIRACULOUS birth check (rare, late game)
    local miraculous = false
    if not has_twins and generation > 20 and condition_count > 0 then
        if rng.chance(0.02) then
            miraculous = true
            adjusted_count = math.min(4, adjusted_count + 1)
            birth_event = "miraculous"
        end
    end

    -- DIFFICULT birth check
    local difficult = false
    if not miraculous then
        local difficult_chance = 0
        if vitality < 0.30 then
            difficult_chance = 0.10
        end
        for _, cond in ipairs(conditions) do
            if cond.type == "plague" then
                difficult_chance = difficult_chance + 0.10
            end
        end
        if difficult_chance > 0 and rng.chance(difficult_chance) then
            difficult = true
            birth_event = "difficult"
        end
    end

    -- Build per-child metadata
    for i = 1, adjusted_count do
        local entry = {
            index = i,
            birth_type = "normal",
        }

        -- Tag twins (first two children if twins triggered)
        if has_twins and i <= 2 then
            entry.birth_type = "twin"
            entry.twin_pair_id = twin_pair_id
            if i == 1 then
                birth_event = "twins"
            end
        end

        -- Tag miraculous child (the extra one)
        if miraculous and i == adjusted_count then
            entry.birth_type = "miraculous"
            entry.narrative = "Against all odds, another drew breath."
        end

        -- Tag difficult birth (narrative only, affects all children)
        if difficult and entry.birth_type == "normal" then
            entry.narrative = "A difficult birth — the heir's strength was tested."
        end

        metadata[#metadata + 1] = entry
    end

    return {
        children_metadata = metadata,
        birth_event = birth_event,
        adjusted_count = adjusted_count,
    }
end

--- Get a narrative description for a birth event.
---@param birth_event string|nil
---@return string|nil
function Births.get_narrative(birth_event)
    local narratives = {
        twins = "Twins — a rare blessing. The bloodline doubles its chances.",
        miraculous = "Against all odds, another drew breath. A miraculous birth.",
        difficult = "A difficult birth. The heir barely survived the ordeal.",
    }
    return narratives[birth_event]
end

return Births
