-- Dark Legacy — Procedural Event Assembler
-- Combines archetypes, fragments, consequence patterns, and scaling
-- to produce fully-formed event objects matching the static event format.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local EventAssembler = {}

-- Lazy-load data modules
local _data = {}
local function get_data()
    if not _data.loaded then
        _data.fragments = require("dredwork_world.proc_gen.narrative_fragments")
        _data.archetypes = require("dredwork_world.proc_gen.event_archetypes")
        _data.patterns = require("dredwork_world.proc_gen.consequence_patterns")
        _data.scaler = require("dredwork_world.proc_gen.consequence_scaler")
        _data.loaded = true
    end
    return _data
end

-- =========================================================================
-- Helpers
-- =========================================================================

--- Pick a random element from an array.
local function pick(arr)
    if not arr or #arr == 0 then return nil end
    return arr[rng.range(1, #arr)]
end

--- Get the current era key, with fallback.
local function get_era_key(context)
    if context.world_state then
        return context.world_state.current_era_key or "ancient"
    end
    return "ancient"
end

--- Get active condition types as a set.
local function get_condition_set(context)
    local set = {}
    if context.world_state and context.world_state.conditions then
        for _, cond in ipairs(context.world_state.conditions) do
            set[cond.type] = true
        end
    end
    return set
end

--- Check legacy eligibility (mirrors event_engine legacy checks).
local function check_legacy_requires(requires, context)
    local cm = context.cultural_memory
    if not cm then return false end

    if requires == "active_taboo" then
        return #cm.taboos > 0
    elseif requires == "blind_spot" then
        return #cm:get_blind_spots() > 0
    elseif requires == "strong_reputation" then
        return cm.reputation and cm.reputation.primary ~= "unknown"
    elseif requires == "old_relationship" then
        for _, rel in ipairs(cm.relationships) do
            if (context.generation - rel.origin_gen) >= 5 then
                return true
            end
        end
        return false
    end

    -- No requirement = always eligible
    return true
end

--- Build variable substitution table.
local function build_vars(context, faction)
    local vars = {
        heir_name = context.heir_name or "the heir",
        era_name = context.world_state and context.world_state:get_era_name() or "this age",
        generation = tostring(context.generation or 0),
        reputation_primary = context.cultural_memory and context.cultural_memory.reputation.primary or "unknown",
        reputation_secondary = context.cultural_memory and context.cultural_memory.reputation.secondary or "unknown",
        lineage_name = context.lineage_name or "the bloodline",
    }
    if faction then
        vars.faction_name = faction.name or "the rival house"
        vars.faction_id = faction.id or ""
        -- Inject rival heir vars when available
        if context.rival_heirs then
            local rival = context.rival_heirs:get(faction.id)
            if rival and rival.alive then
                vars.rival_name = rival.name
                vars.rival_attitude = rival.attitude
                vars.rival_faction = rival.faction_name
            end
        end
    end
    return vars
end

--- Substitute {var} placeholders in text.
local function substitute(text, vars)
    if not text then return "" end
    return text:gsub("{([%w_]+)}", function(key)
        return vars[key] or ("{" .. key .. "}")
    end)
end

--- Pick a title from fragments for the given archetype and era.
local function pick_title(fragments, archetype, era_key)
    local titles = fragments.titles[archetype]
    if not titles then return "An Event Unfolds" end

    -- Try era-specific first
    local era_pool = titles[era_key]
    if era_pool and #era_pool > 0 and rng.chance(0.6) then
        return pick(era_pool)
    end

    -- Fallback to generic
    local generic = titles.generic
    if generic and #generic > 0 then
        return pick(generic)
    end

    return "An Event Unfolds"
end

--- Pick a narrative from fragments for the given archetype and conditions.
local function pick_narrative(fragments, archetype, condition_set)
    local narratives = fragments.narratives[archetype]
    if not narratives then return "Something happens." end

    -- Try condition-specific first
    for cond_type, _ in pairs(condition_set) do
        local pool = narratives[cond_type]
        if pool and #pool > 0 and rng.chance(0.5) then
            return pick(pool)
        end
    end

    -- Fallback to generic
    local generic = narratives.generic
    if generic and #generic > 0 then
        return pick(generic)
    end

    return "Something happens."
end

--- Build options from archetype patterns.
local function build_options(archetype_def, context, vars, data)
    local fragments = data.fragments
    local patterns = data.patterns
    local scaler = data.scaler

    local multiplier = scaler.get_multiplier(context)
    local options = {}
    local has_available = false

    for _, opt_pattern in ipairs(archetype_def.option_patterns) do
        local rtype = opt_pattern.response_type
        local consequence_key = opt_pattern.consequence_pattern

        -- Pick label and description
        local label_pool = fragments.option_labels[rtype]
        local desc_pool = fragments.option_descriptions[rtype]
        local label = label_pool and pick(label_pool) or rtype:gsub("^%l", string.upper)
        local desc = desc_pool and pick(desc_pool) or ""
        desc = substitute(desc, vars)

        -- Build consequence from pattern
        local base_pattern = patterns[consequence_key]
        local consequences = {}
        if base_pattern then
            consequences = scaler.scale(base_pattern, multiplier)
            -- Pick a consequence narrative
            local cons_narratives = fragments.consequence_narratives[rtype]
            if cons_narratives then
                -- Weighted outcome: success 40%, mixed 35%, failure 25%
                local roll = rng.random()
                local outcome
                if roll < 0.40 then
                    outcome = "success"
                elseif roll < 0.75 then
                    outcome = "mixed"
                else
                    outcome = "failure"
                end
                local outcome_pool = cons_narratives[outcome]
                if outcome_pool and #outcome_pool > 0 then
                    consequences.narrative = substitute(pick(outcome_pool), vars)
                end
            end
            -- Substitute vars in base narrative too
            if consequences.narrative then
                consequences.narrative = substitute(consequences.narrative, vars)
            end
        end

        -- Check personality gating
        local avail = true
        local gated_reason = nil
        if opt_pattern.requires and context.heir_personality then
            local req = opt_pattern.requires
            local value = context.heir_personality:get_axis(req.axis)
            if req.min and value < req.min then avail = false end
            if req.max and value > req.max then avail = false end

            if not avail then
                -- Import gate reason logic
                local axis_reasons_min = {
                    PER_BLD = "Your heir lacks the boldness for this...",
                    PER_CRM = "Your heir is too merciful for this...",
                    PER_OBS = "Your heir lacks the fixation for this...",
                    PER_LOY = "Your heir's loyalty is not strong enough...",
                    PER_CUR = "Your heir lacks the curiosity for this...",
                    PER_VOL = "Your heir is too composed for this...",
                    PER_PRI = "Your heir is too humble for this...",
                    PER_ADA = "Your heir is too rigid for this...",
                }
                local axis_reasons_max = {
                    PER_BLD = "Your heir is too reckless to consider this...",
                    PER_CRM = "Your heir is too cruel for this...",
                    PER_OBS = "Your heir is too obsessed to let go...",
                    PER_LOY = "Your heir's loyalty prevents this...",
                    PER_CUR = "Your heir cannot resist investigating...",
                    PER_VOL = "Your heir is too volatile for restraint...",
                    PER_PRI = "Your heir's pride will not allow it...",
                    PER_ADA = "Your heir is too fluid to commit...",
                }
                if req.min then
                    gated_reason = axis_reasons_min[req.axis] or "Requires greater ability..."
                elseif req.max then
                    gated_reason = axis_reasons_max[req.axis] or "Requires less intensity..."
                end
            end
        end

        if avail then has_available = true end

        options[#options + 1] = {
            label = label,
            description = desc,
            consequences = consequences,
            requires = opt_pattern.requires,
            available = avail,
            gated_reason = gated_reason,
        }
    end

    -- Only return if at least one option is available
    if not has_available then return nil end
    return options
end

-- =========================================================================
-- Core: calculate weight for an archetype given context
-- =========================================================================
local function calculate_weight(archetype_def, context, condition_set)
    local weight = archetype_def.chance or 0.25
    local mods = archetype_def.weight_modifiers or {}

    -- Condition-based modifiers
    if condition_set.war and mods.has_condition_war then
        weight = weight * mods.has_condition_war
    end
    if condition_set.plague and mods.has_condition_plague then
        weight = weight * mods.has_condition_plague
    end
    if condition_set.famine and mods.has_condition_famine then
        weight = weight * mods.has_condition_famine
    end

    -- Era-based modifiers
    local era = get_era_key(context)
    if mods["era_" .. era] then
        weight = weight * mods["era_" .. era]
    end

    -- Generation-based
    if mods.high_generation and (context.generation or 0) >= 20 then
        weight = weight * mods.high_generation
    end

    -- Legacy-specific
    local cm = context.cultural_memory
    if mods.has_taboos and cm and #cm.taboos > 0 then
        weight = weight * mods.has_taboos
    end
    if mods.has_blind_spots and cm and #cm:get_blind_spots() > 0 then
        weight = weight * mods.has_blind_spots
    end

    return weight
end

-- =========================================================================
-- Public API
-- =========================================================================

--- Generate procedural events to fill remaining slots.
---@param pool string "world", "faction", or "legacy"
---@param context table event context (same as EventEngine:generate receives)
---@param count number how many events to generate
---@return table array of event objects matching static event format
function EventAssembler.generate(pool, context, count)
    local data = get_data()
    local pool_archetypes = data.archetypes[pool]
    if not pool_archetypes or #pool_archetypes == 0 then return {} end

    local condition_set = get_condition_set(context)
    local era_key = get_era_key(context)
    local events = {}

    -- Filter eligible archetypes
    local eligible = {}
    for _, arch in ipairs(pool_archetypes) do
        local ok = true

        -- Check condition requirements
        if arch.requires_condition then
            if not condition_set[arch.requires_condition] then
                ok = false
            end
        end

        -- Check legacy requirements
        if ok and arch.requires_legacy then
            ok = check_legacy_requires(arch.requires_legacy, context)
        end

        if ok then
            eligible[#eligible + 1] = {
                archetype = arch,
                weight = calculate_weight(arch, context, condition_set),
            }
        end
    end

    if #eligible == 0 then return {} end

    -- Weighted random selection
    local used_ids = {}
    for attempt = 1, count do
        -- Calculate total weight
        local total_weight = 0
        for _, e in ipairs(eligible) do
            if not used_ids[e.archetype.id] then
                total_weight = total_weight + e.weight
            end
        end
        if total_weight <= 0 then break end

        -- Pick
        local roll = rng.random() * total_weight
        local acc = 0
        local chosen = nil
        for _, e in ipairs(eligible) do
            if not used_ids[e.archetype.id] then
                acc = acc + e.weight
                if roll <= acc then
                    chosen = e.archetype
                    break
                end
            end
        end

        if not chosen then break end
        used_ids[chosen.id] = true

        -- Pick a faction for faction events
        local target_faction = nil
        if pool == "faction" and context.factions then
            local active = context.factions:get_active()
            if #active > 0 then
                target_faction = active[rng.range(1, #active)]
            end
        end

        -- Build the event
        local vars = build_vars(context, target_faction)
        local title = pick_title(data.fragments, chosen.archetype, era_key)
        local narrative = pick_narrative(data.fragments, chosen.archetype, condition_set)

        -- Add condition modifier flavor
        for cond_type, _ in pairs(condition_set) do
            local modifiers = data.fragments.condition_modifiers[cond_type]
            if modifiers and #modifiers > 0 and rng.chance(0.3) then
                narrative = narrative .. " " .. pick(modifiers)
            end
        end

        title = substitute(title, vars)
        narrative = substitute(narrative, vars)

        -- Build options
        local options = build_options(chosen, context, vars, data)
        if not options then
            -- No available options; skip this archetype
            used_ids[chosen.id] = nil  -- allow re-roll
        else
            -- Inject target faction into consequences
            if target_faction then
                for _, opt in ipairs(options) do
                    if opt.consequences then
                        opt.consequences.target_faction = target_faction.id
                    end
                end
            end

            local event = {
                type = pool,
                id = chosen.id .. "_g" .. (context.generation or 0),
                title = title,
                narrative = narrative,
                options = options,
                auto_resolve = false,
                target_faction = target_faction and target_faction.id or nil,
                proc_gen = true, -- flag for identification
            }

            events[#events + 1] = event
            if #events >= count then break end
        end
    end

    return events
end

return EventAssembler
