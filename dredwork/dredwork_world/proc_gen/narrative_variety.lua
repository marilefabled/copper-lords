-- Dark Legacy — Narrative Variety Enhancer
-- Adds variation to EXISTING static events.
-- Appends condition modifiers and reputation flavor to narratives.
-- Only touches text — never changes options or consequences.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local NarrativeVariety = {}

-- Lazy-load fragments
local _fragments = nil
local function get_fragments()
    if not _fragments then
        _fragments = require("dredwork_world.proc_gen.narrative_fragments")
    end
    return _fragments
end

--- Pick a random element from an array.
local function pick(arr)
    if not arr or #arr == 0 then return nil end
    return arr[rng.range(1, #arr)]
end

--- Substitute {var} placeholders in text.
local function substitute(text, vars)
    if not text then return "" end
    return text:gsub("{([%w_]+)}", function(key)
        return vars[key] or ("{" .. key .. "}")
    end)
end

--- Apply narrative variety to an array of events.
-- Modifies events in-place (narrative text only).
---@param events table array of event objects
---@param context table { world_state, cultural_memory, lineage_name, heir_name }
function NarrativeVariety.apply(events, context)
    local fragments = get_fragments()
    local vars = {
        lineage_name = context.lineage_name or "the bloodline",
        heir_name = context.heir_name or "the heir",
    }

    -- Get active conditions
    local conditions = {}
    if context.world_state and context.world_state.conditions then
        for _, cond in ipairs(context.world_state.conditions) do
            conditions[#conditions + 1] = cond.type
        end
    end

    -- Get reputation
    local reputation = "unknown"
    if context.cultural_memory and context.cultural_memory.reputation then
        reputation = context.cultural_memory.reputation.primary or "unknown"
    end

    for _, evt in ipairs(events) do
        -- Skip proc-gen events (they already have variety)
        if not evt.proc_gen then
            local additions = {}

            -- 30% chance to add a condition modifier
            for _, cond_type in ipairs(conditions) do
                local modifiers = fragments.condition_modifiers[cond_type]
                if modifiers and #modifiers > 0 and rng.chance(0.30) then
                    additions[#additions + 1] = substitute(pick(modifiers), vars)
                end
            end

            -- 20% chance to add reputation flavor
            local rep_pool = fragments.reputation_flavors[reputation]
            if rep_pool and #rep_pool > 0 and rng.chance(0.20) then
                additions[#additions + 1] = substitute(pick(rep_pool), vars)
            end

            -- Append to narrative
            if #additions > 0 and evt.narrative then
                evt.narrative = evt.narrative .. " " .. table.concat(additions, " ")
            end
        end
    end
end

return NarrativeVariety
