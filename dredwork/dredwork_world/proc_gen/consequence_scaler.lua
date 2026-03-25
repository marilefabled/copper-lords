-- Dark Legacy — Consequence Scaler
-- Scales consequence magnitudes based on generation, conditions, etc.
-- Pure Lua, zero Solar2D dependencies.

local ConsequenceScaler = {}

--- Calculate the scale multiplier for the current context.
---@param context table { generation, world_state }
---@return number multiplier (1.0 - 2.5)
function ConsequenceScaler.get_multiplier(context)
    local gen = context.generation or 1
    local multiplier = 1.0

    -- Generation-based scaling
    if gen <= 10 then
        multiplier = 1.0
    elseif gen <= 30 then
        -- Linear from 1.0 to 1.5
        multiplier = 1.0 + (gen - 10) / 20 * 0.5
    elseif gen <= 60 then
        -- Linear from 1.5 to 2.0
        multiplier = 1.5 + (gen - 30) / 30 * 0.5
    else
        -- Linear from 2.0 to 2.5, capped
        multiplier = 2.0 + math.min((gen - 60) / 40 * 0.5, 0.5)
    end

    -- Active condition bonuses
    local ws = context.world_state
    if ws then
        local conditions = ws.conditions or {}
        for _, cond in ipairs(conditions) do
            if cond.type == "plague" or cond.type == "war" or cond.type == "famine" then
                multiplier = multiplier + 0.1
            end
        end
    end

    -- Cap at 2.5
    if multiplier > 2.5 then multiplier = 2.5 end

    return multiplier
end

--- Deep copy a table (avoids mutating the pattern template).
---@param orig table
---@return table
function ConsequenceScaler.deep_copy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = ConsequenceScaler.deep_copy(v)
    end
    return copy
end

--- Scale a consequence pattern by the given multiplier.
-- Returns a new table (deep copied) with scaled values.
---@param pattern table consequence pattern from consequence_patterns.lua
---@param multiplier number scale factor
---@return table scaled consequence (without _scale_fields)
function ConsequenceScaler.scale(pattern, multiplier)
    local result = ConsequenceScaler.deep_copy(pattern)

    -- Remove internal metadata
    result._scale_fields = nil

    -- Scale cultural_memory_shift values
    if result.cultural_memory_shift then
        for cat, val in pairs(result.cultural_memory_shift) do
            result.cultural_memory_shift[cat] = math.floor(val * multiplier + 0.5)
        end
    end

    -- Scale mutation trigger intensities
    if result.mutation_triggers then
        for _, mt in ipairs(result.mutation_triggers) do
            if mt.intensity then
                mt.intensity = math.min(mt.intensity * multiplier, 2.0)
            end
        end
    end

    -- Scale disposition changes
    if result.disposition_changes then
        for _, dc in ipairs(result.disposition_changes) do
            if dc.delta then
                dc.delta = math.floor(dc.delta * multiplier + 0.5)
            end
        end
    end

    -- Scale taboo strength
    if result.taboo_data and result.taboo_data.strength then
        result.taboo_data.strength = math.min(
            math.floor(result.taboo_data.strength * multiplier + 0.5),
            100
        )
    end

    -- Scale relationship strength
    if result.add_relationship and result.add_relationship.strength then
        result.add_relationship.strength = math.min(
            math.floor(result.add_relationship.strength * multiplier + 0.5),
            100
        )
    end

    -- Scale faction power shift
    if result.faction_power_shift then
        result.faction_power_shift = math.floor(result.faction_power_shift * multiplier + 0.5)
    end

    return result
end

return ConsequenceScaler
