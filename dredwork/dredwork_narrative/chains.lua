-- dredwork Narrative — Story Arc Chains
-- Multi-step narrative arcs driven by simulation state thresholds.
-- Chains advance through stages when conditions are met.

local Templates = require("dredwork_narrative.templates")

local Chains = {}

local _definitions = {}

--------------------------------------------------------------------------------
-- Chain Definitions
--------------------------------------------------------------------------------

local function register(def)
    _definitions[def.id] = def
end

--- Get all registered chain definitions.
function Chains.get_definitions()
    return _definitions
end

--- Create an active chain state from a definition.
function Chains.start(chain_id, clock)
    local def = _definitions[chain_id]
    if not def then return nil end
    return {
        chain_id = chain_id,
        current_stage = 1,
        started_day = clock.total_days,
        stage_entered_day = clock.total_days,
        data = {},
    }
end

--- Tick all active chains daily. Returns array of beats to emit.
---@param active_chains table array of active chain states
---@param gs table game_state
---@param clock table
---@param vars table standard template variables
---@return table beats array of {template_id, text, display_hint, priority, chain_id, stage_id}
function Chains.tick_daily(active_chains, gs, clock, vars)
    local beats = {}

    for i = #active_chains, 1, -1 do
        local ac = active_chains[i]
        local def = _definitions[ac.chain_id]
        if not def then
            table.remove(active_chains, i)
        else
            -- Check max lifespan
            if def.max_days and (clock.total_days - ac.started_day) > def.max_days then
                table.remove(active_chains, i)
            else
                local stage = def.stages[ac.current_stage]
                if stage then
                    local min_elapsed = clock.total_days - ac.stage_entered_day
                    local min_met = min_elapsed >= (stage.min_duration_days or 0)

                    -- Check if next stage condition is met
                    local next_stage = def.stages[ac.current_stage + 1]
                    if next_stage and min_met and next_stage.condition(gs) then
                        ac.current_stage = ac.current_stage + 1
                        ac.stage_entered_day = clock.total_days

                        local text = Templates.render(next_stage.template_id, vars)
                        if text then
                            table.insert(beats, {
                                template_id = next_stage.template_id,
                                text = text,
                                display_hint = next_stage.display_hint or "panel",
                                priority = next_stage.priority or 70,
                                chain_id = ac.chain_id,
                                stage_id = next_stage.id,
                            })
                        end

                        -- Terminal stage: mark for removal
                        if next_stage.terminal then
                            table.remove(active_chains, i)
                        end
                    end
                end
            end
        end
    end

    return beats
end

--- Check if any new chains should start. Called monthly.
---@param active_chains table
---@param gs table game_state
---@param clock table
---@param vars table
---@return table new_beats, table new_chains
function Chains.check_triggers(active_chains, gs, clock, vars)
    local new_beats = {}
    local new_chains = {}

    -- Build set of active chain IDs for singleton checks
    local active_ids = {}
    for _, ac in ipairs(active_chains) do
        active_ids[ac.chain_id] = true
    end

    for id, def in pairs(_definitions) do
        -- Singleton check
        if def.singleton and active_ids[id] then
            goto continue
        end

        -- Cooldown check (stored in chain data? use memory externally)
        -- First stage condition check
        local first_stage = def.stages[1]
        if first_stage and first_stage.condition(gs) then
            local ac = Chains.start(id, clock)
            if ac then
                table.insert(new_chains, ac)
                active_ids[id] = true

                local text = Templates.render(first_stage.template_id, vars)
                if text then
                    table.insert(new_beats, {
                        template_id = first_stage.template_id,
                        text = text,
                        display_hint = first_stage.display_hint or "toast",
                        priority = first_stage.priority or 60,
                        chain_id = id,
                        stage_id = first_stage.id,
                    })
                end
            end
        end

        ::continue::
    end

    return new_beats, new_chains
end

--- Get summaries of active chains for UI display.
function Chains.get_active_summaries(active_chains)
    local summaries = {}
    for _, ac in ipairs(active_chains) do
        local def = _definitions[ac.chain_id]
        if def then
            table.insert(summaries, {
                chain_id = ac.chain_id,
                title = def.title or ac.chain_id,
                current_stage = ac.current_stage,
                total_stages = #def.stages,
                days_active = 0, -- filled by caller with clock
            })
        end
    end
    return summaries
end

--------------------------------------------------------------------------------
-- Built-in Chain Definitions
--------------------------------------------------------------------------------

register({
    id = "famine_arc",
    title = "The Hungry Season",
    singleton = true,
    max_days = 360,
    stages = {
        {
            id = "buildup",
            condition = function(gs)
                if not gs.markets then return false end
                for _, market in pairs(gs.markets) do
                    if market.prices and market.prices.food and market.prices.food > 8 then
                        return true
                    end
                end
                return false
            end,
            template_id = "chain_famine_buildup",
            min_duration_days = 20,
            display_hint = "toast",
            priority = 60,
        },
        {
            id = "crisis",
            condition = function(gs)
                if not gs.markets then return false end
                for _, market in pairs(gs.markets) do
                    if market.prices and market.prices.food and market.prices.food > 13 then
                        return true
                    end
                end
                return false
            end,
            template_id = "chain_famine_crisis",
            min_duration_days = 15,
            display_hint = "panel",
            priority = 80,
        },
        {
            id = "climax",
            condition = function(gs)
                return gs.politics and gs.politics.unrest and gs.politics.unrest > 60
            end,
            template_id = "chain_famine_climax",
            min_duration_days = 0,
            display_hint = "fullscreen",
            priority = 95,
        },
        {
            id = "resolution",
            condition = function(gs)
                if not gs.markets then return true end
                for _, market in pairs(gs.markets) do
                    if market.prices and market.prices.food and market.prices.food < 10 then
                        return true
                    end
                end
                return false
            end,
            template_id = "chain_famine_resolution",
            min_duration_days = 0,
            display_hint = "panel",
            priority = 70,
            terminal = true,
        },
    },
})

register({
    id = "plague_arc",
    title = "The Pestilence",
    singleton = true,
    max_days = 300,
    stages = {
        {
            id = "onset",
            condition = function(gs)
                return gs.perils and gs.perils.active and #gs.perils.active > 0
            end,
            template_id = "chain_plague_onset",
            min_duration_days = 15,
            display_hint = "panel",
            priority = 75,
        },
        {
            id = "peak",
            condition = function(gs)
                if not gs.perils or not gs.perils.active then return false end
                for _, p in ipairs(gs.perils.active) do
                    if p.category == "disease" and (p.severity or 0) > 50 then return true end
                end
                return false
            end,
            template_id = "chain_plague_peak",
            min_duration_days = 30,
            display_hint = "fullscreen",
            priority = 90,
        },
        {
            id = "waning",
            condition = function(gs)
                if not gs.perils or not gs.perils.active then return true end
                for _, p in ipairs(gs.perils.active) do
                    if p.category == "disease" then return false end
                end
                return true
            end,
            template_id = "chain_plague_waning",
            min_duration_days = 0,
            display_hint = "panel",
            priority = 65,
            terminal = true,
        },
    },
})

register({
    id = "rebellion_arc",
    title = "The Reckoning",
    singleton = true,
    max_days = 180,
    stages = {
        {
            id = "simmering",
            condition = function(gs)
                return gs.politics and gs.politics.unrest and gs.politics.unrest > 25
            end,
            template_id = "chain_unrest_rising",
            min_duration_days = 30,
            display_hint = "toast",
            priority = 60,
        },
        {
            id = "boiling",
            condition = function(gs)
                return gs.politics and gs.politics.unrest and gs.politics.unrest > 70
            end,
            template_id = "chain_unrest_boiling",
            min_duration_days = 15,
            display_hint = "panel",
            priority = 80,
        },
        {
            id = "resolved",
            condition = function(gs)
                return gs.politics and gs.politics.unrest and gs.politics.unrest < 30
            end,
            template_id = "chain_unrest_resolved",
            min_duration_days = 0,
            display_hint = "panel",
            priority = 60,
            terminal = true,
        },
    },
})

return Chains
