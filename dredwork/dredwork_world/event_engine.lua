local Math = require("dredwork_core.math")
-- Dark Legacy — Event Engine
-- Generates 1-3 events per generation from 4 pools: world, faction, personal, legacy.
-- Personality gating determines which options appear for each event.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local EventEngine = {}
EventEngine.__index = EventEngine

-- Event template pools loaded lazily
local _templates = {}

local function get_templates()
    if not _templates.loaded then
        local ok_w, world_t = pcall(require, "dredwork_world.config.event_templates_world")
        _templates.world = ok_w and world_t or {}
        local ok_f, faction_t = pcall(require, "dredwork_world.config.event_templates_faction")
        _templates.faction = ok_f and faction_t or {}
        local ok_p, personal_t = pcall(require, "dredwork_world.config.event_templates_personal")
        _templates.personal = ok_p and personal_t or {}
        local ok_l, legacy_t = pcall(require, "dredwork_world.config.event_templates_legacy")
        _templates.legacy = ok_l and legacy_t or {}
        if not ok_w then print("Warning: failed to load world event templates: " .. tostring(world_t)) end
        if not ok_f then print("Warning: failed to load faction event templates: " .. tostring(faction_t)) end
        if not ok_p then print("Warning: failed to load personal event templates: " .. tostring(personal_t)) end
        if not ok_l then print("Warning: failed to load legacy event templates: " .. tostring(legacy_t)) end
        _templates.loaded = true
    end
    return _templates
end

--- Create a new event engine instance.
---@return table EventEngine
function EventEngine.new()
    local self = setmetatable({}, EventEngine)
    return self
end

--- Generate events for this generation.
---@param context table { world_state, factions, heir_personality, cultural_memory, generation, heir_name }
---@return table array of event objects
function EventEngine:generate(context)
    local events = {}
    local templates = get_templates()
    local chain_event_added = false

    -- 0. Check for pending event chain stages (multi-gen story arcs)
    local ok_ec, EventChains = pcall(require, "dredwork_world.event_chains")
    if ok_ec and EventChains then
        pcall(function()
            local active_chains = context.active_chains or {}
            local generation = context.generation or 1

            -- Check pending chain stages
            local pending = EventChains.check_pending(active_chains, generation)
            if #pending > 0 then
                -- Fire the first ready chain event (takes one slot)
                local p = pending[1]
                local vars = self:_build_vars(context, {})
                local chain_evt = p.event
                if chain_evt then
                    -- Substitute variables in title/narrative
                    chain_evt.title = EventEngine.substitute(chain_evt.title, vars)
                    chain_evt.narrative = EventEngine.substitute(chain_evt.narrative, vars)
                    for _, opt in ipairs(chain_evt.options or {}) do
                        opt.label = EventEngine.substitute(opt.label, vars)
                        opt.description = EventEngine.substitute(opt.description or "", vars)
                    end
                    events[#events + 1] = chain_evt
                    chain_event_added = true
                end
            end

            -- Check for new chain triggers (if no chain event was added and under max)
            if not chain_event_added then
                local new_chain = EventChains.check_new_triggers(active_chains, context)
                if new_chain then
                    local vars = self:_build_vars(context, {})
                    local chain_evt = new_chain.event
                    if chain_evt then
                        chain_evt.title = EventEngine.substitute(chain_evt.title, vars)
                        chain_evt.narrative = EventEngine.substitute(chain_evt.narrative, vars)
                        for _, opt in ipairs(chain_evt.options or {}) do
                            opt.label = EventEngine.substitute(opt.label, vars)
                            opt.description = EventEngine.substitute(opt.description or "", vars)
                        end
                        chain_evt._new_chain_id = new_chain.chain_id
                        events[#events + 1] = chain_evt
                        chain_event_added = true
                    end
                end
            end
        end)
    end

    -- 1. Personal events (auto-resolve, personality-driven) — always check first
    local personal = self:_generate_personal(context, templates.personal)
    for _, e in ipairs(personal) do
        events[#events + 1] = e
    end

    -- 2. World events (condition/era driven)
    local world = self:_generate_world(context, templates.world)
    for _, e in ipairs(world) do
        events[#events + 1] = e
    end

    -- 2b. Religion schism event (fired when schism triggered previous gen)
    if context.world_state and context.world_state._pending_schism then
        local religion = context.religion
        local ReligionMod = require("dredwork_world.religion")
        local faith_name = religion and ReligionMod.display_name(religion.name) or "the faith"
        local schism_event = {
            type = "world",
            title = "Schism in " .. faith_name,
            narrative = faith_name .. " fractures. Followers divide. " ..
                "The heir must choose: preserve the old ways, or embrace the new creed.",
            options = {
                {
                    label = "Preserve the old faith",
                    description = "Stability. The tenets hold. But the dissidents leave.",
                    consequences = {
                        narrative = "The old faith endures. But the schismatics are gone — and they took something with them.",
                        cultural_memory_shift = { social = 2 },
                        religion_action = "preserve",
                    },
                },
                {
                    label = "Embrace the new creed",
                    description = "Change. New tenets form. But the zealots rage.",
                    consequences = {
                        narrative = "A new creed rises from the ashes of the old. Not everyone will follow.",
                        cultural_memory_shift = { mental = 2, social = -1 },
                        religion_action = "reform",
                    },
                },
                {
                    label = "Abandon religion entirely",
                    description = "The bloodline walks alone. No faith. No burden.",
                    requires = { axis = "PER_CUR", min = 60 },
                    consequences = {
                        narrative = "The temples emptied. The silence was deafening — and liberating.",
                        cultural_memory_shift = { mental = 3, social = -3 },
                        religion_action = "abandon",
                    },
                },
            },
        }
        local vars = self:_build_vars(context, {})
        schism_event.title = EventEngine.substitute(schism_event.title, vars)
        schism_event.narrative = EventEngine.substitute(schism_event.narrative, vars)
        -- Apply personality gating to options
        local gated_options = self:_prepare_options(schism_event.options, context, vars)
        schism_event.options = gated_options
        events[#events + 1] = schism_event
        -- Clear pending flag
        context.world_state._pending_schism = nil
    end

    -- 2c. Great work completion event (fired when great work finished previous gen)
    if context.world_state and context.world_state._pending_great_work then
        local gw = context.world_state._pending_great_work
        local gw_event = {
            type = "world",
            title = "A Monument Rises: " .. (gw.label or "the Great Work"),
            narrative = "The great work begun generations ago is complete. " ..
                (gw.completer or "The heir") .. " stands before it, a testament to the bloodline's endurance. " ..
                "The world takes notice. How will you wield this triumph?",
            options = {
                {
                    label = "Dedicate it to the people",
                    description = "The great work becomes a symbol of unity. All factions look upon you favorably.",
                    consequences = {
                        narrative = "The monument stands open. The people gather. For once, they are united in awe.",
                        disposition_changes = { { faction_id = "all", delta = 5 } },
                        cultural_memory_shift = { social = 2 },
                    },
                },
                {
                    label = "Claim it for the bloodline's glory",
                    description = "The great work is yours. It was always yours. Let them remember.",
                    requires = { axis = "PER_PRI", min = 45 },
                    consequences = {
                        narrative = "The monument bears only one name. The world remembers who built this — and who it serves.",
                        cultural_memory_shift = { creative = 3 },
                    },
                },
                {
                    label = "Use it as leverage",
                    description = "A great work is a bargaining chip. Trade its prestige for something tangible.",
                    requires = { axis = "PER_CRM", min = 40 },
                    consequences = {
                        narrative = "The monument's prestige is spent before the mortar dries. But what it purchased will last.",
                        disposition_changes = { { faction_id = "all", delta = -3 } },
                        mutation_triggers = { { type = "great_work_leverage", intensity = 0.3 } },
                    },
                },
            },
        }
        local gw_vars = self:_build_vars(context, {})
        gw_event.title = EventEngine.substitute(gw_event.title, gw_vars)
        gw_event.narrative = EventEngine.substitute(gw_event.narrative, gw_vars)
        gw_event.options = self:_prepare_options(gw_event.options, context, gw_vars)
        if #gw_event.options > 0 then
            events[#events + 1] = gw_event
        end
        context.world_state._pending_great_work = nil
    end

    -- 2d. Discovery breakthrough event (fired when discovery unlocked previous gen)
    if context.world_state and context.world_state._pending_discovery then
        local disc = context.world_state._pending_discovery
        local disc_event = {
            type = "world",
            title = "Breakthrough: " .. (disc.label or "a Discovery"),
            narrative = (disc.discoverer or "The heir") .. " has unlocked something profound: " ..
                (disc.label or "a new understanding") .. ". " ..
                (disc.flavor or "") .. " The question is what comes next.",
            options = {
                {
                    label = "Share the knowledge openly",
                    description = "Let the discovery spread. It will change the world — and your bloodline's reputation.",
                    consequences = {
                        narrative = "The discovery passes from hand to hand. The bloodline is remembered as scholars, not hoarders.",
                        disposition_changes = { { faction_id = "all", delta = 3 } },
                        cultural_memory_shift = { [disc.category or "mental"] = 2 },
                    },
                },
                {
                    label = "Guard it jealously",
                    description = "This is the bloodline's secret. Let no one else benefit.",
                    requires = { axis = "PER_OBS", min = 40 },
                    consequences = {
                        narrative = "The discovery is locked away. Only the blood may touch it. Power consolidates.",
                        cultural_memory_shift = { mental = 2 },
                        mutation_triggers = { { type = "discovery_hoarded", intensity = 0.3 } },
                    },
                },
                {
                    label = "Build upon it immediately",
                    description = "Push further. One breakthrough leads to another — if you dare.",
                    requires = { axis = "PER_CUR", min = 50 },
                    consequences = {
                        narrative = "The heir presses forward, fueled by the thrill of understanding. The next breakthrough is closer than anyone thinks.",
                        cultural_memory_shift = { creative = 1, mental = 1 },
                    },
                },
            },
        }
        local disc_vars = self:_build_vars(context, {})
        disc_event.title = EventEngine.substitute(disc_event.title, disc_vars)
        disc_event.narrative = EventEngine.substitute(disc_event.narrative, disc_vars)
        disc_event.options = self:_prepare_options(disc_event.options, context, disc_vars)
        if #disc_event.options > 0 then
            events[#events + 1] = disc_event
        end
        context.world_state._pending_discovery = nil
    end

    -- 2e. Undercurrent pattern event (fired when undercurrent reaches murmur/roar)
    if context.world_state and context.world_state._pending_undercurrent then
        local uc = context.world_state._pending_undercurrent
        local severity_desc = uc.severity == "roar"
            and "Something long-hidden erupts to the surface. The bloodline cannot ignore it."
            or "A pattern stirs beneath the generations. Those who pay attention can feel it."
        local uc_event = {
            type = "legacy",
            title = uc.title or "The Undercurrent",
            narrative = (uc.narrative or "") .. " " .. severity_desc,
            options = {
                {
                    label = "Confront the pattern",
                    description = "Face what the bloodline has been building toward. It won't be easy.",
                    requires = { axis = "PER_BLD", min = 45 },
                    consequences = {
                        narrative = "The undercurrent was met head-on. Whether it breaks or transforms the bloodline remains to be seen.",
                        cultural_memory_shift = { mental = 2 },
                        mutation_triggers = { { type = "undercurrent_confronted", intensity = 0.4 } },
                    },
                },
                {
                    label = "Adapt and flow with it",
                    description = "The pattern exists for a reason. Ride it rather than fight it.",
                    requires = { axis = "PER_ADA", min = 45 },
                    consequences = {
                        narrative = "The bloodline bent with the undercurrent rather than against it. A new equilibrium forms.",
                        cultural_memory_shift = { creative = 2 },
                    },
                },
                {
                    label = "Ignore it",
                    description = "What the bloodline cannot see cannot hurt it. Probably.",
                    consequences = {
                        narrative = "The pattern was left to fester. It will not stay quiet forever.",
                    },
                },
            },
        }
        local uc_vars = self:_build_vars(context, {})
        uc_event.title = EventEngine.substitute(uc_event.title, uc_vars)
        uc_event.narrative = EventEngine.substitute(uc_event.narrative, uc_vars)
        uc_event.options = self:_prepare_options(uc_event.options, context, uc_vars)
        if #uc_event.options > 0 then
            events[#events + 1] = uc_event
        end
        context.world_state._pending_undercurrent = nil
    end

    -- 3. Faction events (disposition threshold driven)
    local faction = self:_generate_faction(context, templates.faction)
    for _, e in ipairs(faction) do
        events[#events + 1] = e
    end

    -- 4. Legacy events (cultural memory driven)
    local legacy = self:_generate_legacy(context, templates.legacy)
    for _, e in ipairs(legacy) do
        events[#events + 1] = e
    end

    -- 5. Cross-run ghost events (past dynasty references, max once per 10 gens)
    local ok_cr, CrossRun = pcall(require, "dredwork_world.cross_run")
    if ok_cr and CrossRun then
        pcall(function()
            local ghost = CrossRun.get_ghost_event(context.generation, context.world_state and context.world_state.current_era_key)
            if ghost then
                events[#events + 1] = ghost
            end
        end)
    end

    -- 6. Dynamic events from living world systems (fossils, echoes, dreams)
    self:_inject_living_world_events(events, context)

    -- Dynamic event cap: more events in later generations
    local base_max = context.max_events or 3
    local gen_bonus = math.floor((context.generation or 1) / 15) -- +1 event every 15 gens
    local max_events = math.min(base_max + gen_bonus, 5) -- cap at 5
    if #events > max_events then
        -- Personal and chain events get priority
        local priority_events = {}
        local other_events = {}
        for _, e in ipairs(events) do
            if e.type == "personal" or e.type == "chain" then
                priority_events[#priority_events + 1] = e
            else
                other_events[#other_events + 1] = e
            end
        end

        events = {}
        -- Include priority events (personal + chain, up to 2)
        for _, e in ipairs(priority_events) do
            if #events >= max_events then break end
            events[#events + 1] = e
        end
        -- Fill remainder from other events
        for _, e in ipairs(other_events) do
            if #events >= max_events then break end
            events[#events + 1] = e
        end
    end

    -- Proc gen fallback: fill remaining slots with procedural events
    local slots_remaining = max_events - #events
    if slots_remaining > 0 then
        local ok_asm, EventAssembler = pcall(require, "dredwork_world.proc_gen.event_assembler")
        if ok_asm then
            -- Determine which pools need filling
            local has_world, has_faction, has_legacy = false, false, false
            for _, e in ipairs(events) do
                if e.type == "world" then has_world = true end
                if e.type == "faction" then has_faction = true end
                if e.type == "legacy" then has_legacy = true end
            end

            -- Try to fill one from each missing pool, then any pool
            local pool_order = {}
            if not has_world then pool_order[#pool_order + 1] = "world" end
            if not has_faction then pool_order[#pool_order + 1] = "faction" end
            if not has_legacy then pool_order[#pool_order + 1] = "legacy" end
            -- Fallback pools for extra slots
            pool_order[#pool_order + 1] = "world"
            pool_order[#pool_order + 1] = "faction"

            for _, pool in ipairs(pool_order) do
                if slots_remaining <= 0 then break end
                local proc_ok, proc_events = pcall(EventAssembler.generate, pool, context, 1)
                if proc_ok and proc_events then
                    for _, pe in ipairs(proc_events) do
                        events[#events + 1] = pe
                        slots_remaining = slots_remaining - 1
                        if slots_remaining <= 0 then break end
                    end
                end
            end
        end
    end

    -- Narrative variety: enhance static events with condition/reputation flavor
    local ok_nv, NarrativeVariety = pcall(require, "dredwork_world.proc_gen.narrative_variety")
    if ok_nv and NarrativeVariety then
        pcall(NarrativeVariety.apply, events, context)
    end

    return events
end

--- Check if an event option passes personality gating and resource/world state requirements.
---@param option table { requires = { axis, min, max }, requires_resources = { type, min }, requires_no_condition }
---@param context table { world_state, factions, heir_personality, resources, ... }
---@return boolean
function EventEngine.option_available(option, context)
    local personality = context.heir_personality
    
    -- 1. Personality gate
    if option.requires and personality then
        local req = option.requires
        local value = personality:get_axis(req.axis)
        if req.min and value < req.min then return false end
        if req.max and value > req.max then return false end
    end

    -- 2. Resource gate
    if option.requires_resources and context.resources then
        local req = option.requires_resources
        local current = context.resources[req.type] or 0
        if current < (req.min or 0) then return false end
    end

    -- 3. World Condition gate
    if option.requires_no_condition and context.world_state then
        if context.world_state:has_condition(option.requires_no_condition) then
            return false
        end
    end
    if option.requires_condition and context.world_state then
        if not context.world_state:has_condition(option.requires_condition) then
            return false
        end
    end

    return true
end

--- Filter event options through gating.
---@param options table array of option definitions
---@param context table
---@return table array of available options
function EventEngine.filter_options(options, context)
    local available = {}
    for _, opt in ipairs(options) do
        if EventEngine.option_available(opt, context) then
            available[#available + 1] = opt
        end
    end
    return available
end

--- Get a human-readable reason why an option is gated.
---@param requires table { axis, min, max, trait }
---@return string reason text
function EventEngine.get_gate_reason(requires)
    if not requires then return "" end

    local ok_s, Settings = pcall(require, "solar2d_bridge.settings")
    local display_mode = ok_s and Settings.get().stat_display_mode or "narrative"

    local axis_names = {
        PER_BLD = "boldness", PER_CRM = "cruelty", PER_OBS = "obsession",
        PER_LOY = "loyalty", PER_CUR = "curiosity", PER_VOL = "volatility",
        PER_PRI = "pride", PER_ADA = "adaptability",
    }
    local axis_name = axis_names[requires.axis] or requires.axis

    local function get_mythic_desc(v)
        if v <= 15 then return "Wretched"
        elseif v <= 30 then return "Meager"
        elseif v <= 45 then return "Mediocre"
        elseif v <= 60 then return "Capable"
        elseif v <= 75 then return "Potent"
        elseif v <= 89 then return "Exalted"
        else return "Legendary" end
    end

    if requires.min then
        if display_mode == "precise" then
            return "Requires " .. axis_name:upper() .. " " .. requires.min .. "+"
        else
            local desc = get_mythic_desc(requires.min)
            local reasons = {
                PER_BLD = "Your heir lacks the boldness for this...",
                PER_CRM = "Your heir is too merciful for this...",
                PER_OBS = "Your heir lacks the fixation for this...",
                PER_LOY = "Your heir's loyalty is not strong enough...",
                PER_CUR = "Your heir lacks the curiosity for this...",
                PER_VOL = "Your heir is too composed for this...",
                PER_PRI = "Your heir is too humble for this...",
                PER_ADA = "Your heir is too rigid for this...",
            }
            return (reasons[requires.axis] or "Requires " .. desc .. " " .. axis_name .. "...")
        end
    end

    if requires.max then
        if display_mode == "precise" then
            return "Requires " .. axis_name:upper() .. " under " .. requires.max
        else
            local reasons = {
                PER_BLD = "Your heir is too reckless to consider this...",
                PER_CRM = "Your heir is too cruel for this...",
                PER_OBS = "Your heir is too obsessed to let go...",
                PER_LOY = "Your heir's loyalty prevents this...",
                PER_CUR = "Your heir cannot resist investigating...",
                PER_VOL = "Your heir is too volatile for restraint...",
                PER_PRI = "Your heir's pride will not allow it...",
                PER_ADA = "Your heir is too fluid to commit...",
            }
            return reasons[requires.axis] or ("Requires lower " .. axis_name .. "...")
        end
    end

    return ""
end

--- Check if the heir's personality contradicts a chosen option.
--- Returns nil if no resistance, or a resistance table describing the conflict.
--- This is the core of "Choice vs. Autonomy" — heirs are not puppets.
---@param option table the chosen event option
---@param personality table Personality instance
---@return table|nil { axis, heir_value, resistance_strength (0-1), narrative, axis_name }
function EventEngine.check_heir_resistance(option, personality)
    if not personality or not option then return nil end

    local consequences = option.consequences or {}

    -- Resistance rules: map consequence types to personality contradictions
    -- Each rule: { axis, direction ("low"=heir resists if axis is low, "high"=if high), threshold }
    local contradictions = {}

    -- ── PER_CRM: Cruel acts resist merciful heirs ──────────────────────────
    if consequences.moral_act then
        local act_id = type(consequences.moral_act) == "table"
            and consequences.moral_act.act_id or consequences.moral_act
        if act_id == "cruelty" or act_id == "murder" or act_id == "harsh_justice" then
            contradictions[#contradictions + 1] = {
                axis = "PER_CRM", direction = "low", threshold = 30,
                narrative = "The heir balked at the cruelty demanded. The order was carried out, but half-heartedly.",
            }
        end
        if act_id == "exploitation" or act_id == "oppression" then
            contradictions[#contradictions + 1] = {
                axis = "PER_CRM", direction = "low", threshold = 35,
                narrative = "The heir's conscience stayed the hand. The oppression was enacted, but with visible reluctance.",
            }
        end
    end

    -- ── PER_BLD: War/aggression contradicts cautious heirs ─────────────────
    if consequences.add_condition then
        local cond = consequences.add_condition
        if cond.type == "war" and (cond.intensity or 0) >= 0.3 then
            contradictions[#contradictions + 1] = {
                axis = "PER_BLD", direction = "low", threshold = 30,
                narrative = "The heir's hand trembled on the war banner. The advance was ordered, but the voice cracked.",
            }
        end
    end

    -- ── PER_PRI: Diplomacy/submission contradicts proud heirs ──────────────
    if consequences.disposition_changes then
        local total_positive = 0
        for _, dc in ipairs(consequences.disposition_changes) do
            if dc.delta and dc.delta > 10 then total_positive = total_positive + dc.delta end
        end
        if total_positive >= 12 then
            contradictions[#contradictions + 1] = {
                axis = "PER_PRI", direction = "high", threshold = 60,
                narrative = "The heir choked on the words of submission. The alliance was offered, but the pride burned.",
            }
        end
    end

    -- ── PER_LOY: Treachery/betrayal contradicts loyal heirs ────────────────
    if consequences.add_relationship then
        local rel = consequences.add_relationship
        if rel.type == "enemy" then
            contradictions[#contradictions + 1] = {
                axis = "PER_LOY", direction = "high", threshold = 60,
                narrative = "The heir hesitated. Betrayal does not come easy to one who values oaths.",
            }
        end
    end
    -- Espionage also contradicts loyal heirs
    if consequences.reveal_faction_info then
        contradictions[#contradictions + 1] = {
            axis = "PER_LOY", direction = "high", threshold = 65,
            narrative = "The heir recoiled from the spy's report. There was no honor in stolen secrets.",
        }
    end

    -- ── PER_OBS: Reckless grand gestures contradict methodical heirs ───────
    if consequences.lineage_power_shift and consequences.lineage_power_shift >= 12 then
        contradictions[#contradictions + 1] = {
            axis = "PER_OBS", direction = "high", threshold = 60,
            narrative = "The heir insisted on planning, on caution. The grand gesture lost its edge in committee.",
        }
    end

    -- ── PER_CUR: Taboo formation contradicts curious heirs ─────────────────
    if consequences.taboo_chance and consequences.taboo_data then
        contradictions[#contradictions + 1] = {
            axis = "PER_CUR", direction = "high", threshold = 60,
            narrative = "The heir questioned the taboo. Why forbid what might be understood? The restriction was imposed, but loosely.",
        }
    end
    -- Knowledge suppression contradicts curious heirs
    if consequences.cultural_memory_shift and consequences.cultural_memory_shift.mental then
        if consequences.cultural_memory_shift.mental <= -3 then
            contradictions[#contradictions + 1] = {
                axis = "PER_CUR", direction = "high", threshold = 55,
                narrative = "The heir fought to preserve the old scrolls. Knowledge was lost, but not without protest.",
            }
        end
    end

    -- ── PER_VOL: Forced restraint contradicts volatile heirs ───────────────
    -- Diplomatic restraint (large positive disposition = submission)
    if consequences.disposition_changes then
        local has_restraint = false
        for _, dc in ipairs(consequences.disposition_changes) do
            if dc.delta and dc.delta >= 15 then has_restraint = true; break end
        end
        if has_restraint then
            contradictions[#contradictions + 1] = {
                axis = "PER_VOL", direction = "high", threshold = 65,
                narrative = "The heir's blood ran hot. Diplomacy tasted of ash in a mouth made for fire.",
            }
        end
    end
    -- Stoic response when negative consequences demand composure
    if consequences.remove_condition then
        contradictions[#contradictions + 1] = {
            axis = "PER_VOL", direction = "high", threshold = 70,
            narrative = "The heir wanted blood, not peace. The truce was signed with a shaking hand.",
        }
    end

    -- ── PER_ADA: Rigid traditions contradict adaptable heirs ───────────────
    -- Cultural memory shifts that reinforce existing patterns resist adaptive heirs
    if consequences.cultural_memory_shift then
        local cms = consequences.cultural_memory_shift
        local total_shift = 0
        for _, delta in pairs(cms) do total_shift = total_shift + math.abs(delta) end
        if total_shift >= 8 then
            -- Major cultural shift: rigid heirs resist change, adaptable heirs resist stagnation
            -- Check if this is reinforcing (same direction as dominant) or disrupting
            contradictions[#contradictions + 1] = {
                axis = "PER_ADA", direction = "low", threshold = 30,
                narrative = "The heir resisted the upheaval. The old ways were not easily abandoned.",
            }
        end
    end

    -- Find the strongest contradiction
    local strongest = nil
    local max_strength = 0

    local axis_names = {
        PER_BLD = "boldness", PER_CRM = "cruelty", PER_OBS = "obsession",
        PER_LOY = "loyalty", PER_CUR = "curiosity", PER_VOL = "volatility",
        PER_PRI = "pride", PER_ADA = "adaptability",
    }

    for _, c in ipairs(contradictions) do
        local value = personality:get_axis(c.axis)
        local strength = 0

        if c.direction == "low" and value < c.threshold then
            -- Heir is too merciful/cautious/rigid for this action
            strength = (c.threshold - value) / c.threshold
        elseif c.direction == "high" and value > c.threshold then
            -- Heir is too proud/loyal/curious to accept this
            strength = (value - c.threshold) / (100 - c.threshold)
        end

        if strength > max_strength then
            max_strength = strength
            strongest = {
                axis = c.axis,
                axis_name = axis_names[c.axis] or c.axis,
                heir_value = value,
                resistance_strength = strength,
                narrative = c.narrative,
            }
        end
    end

    -- Only trigger if resistance is significant (strength > 0.3 = ~30% contradiction)
    if strongest and strongest.resistance_strength > 0.3 then
        return strongest
    end
    return nil
end

--- Apply consequences from a chosen event option.
---@param context table { world_state, factions, cultural_memory, generation, mutation_pressure }
---@return table applied_effects { narrative, taboo_formed, consequence_lines, ... }
function EventEngine.apply_consequences(consequences, context)
    -- Substitute template variables in consequence narrative
    local narrative = consequences.narrative
    if narrative and narrative ~= "" then
        local vars = {
            heir_name = context.heir_name or "the heir",
            lineage_name = context.lineage_name or "the bloodline",
            generation = tostring(context.generation or 0),
            era_name = context.world_state and context.world_state.get_era_name
                and context.world_state:get_era_name() or "this age",
        }
        -- Court variables (sibling, spouse names)
        if context.court then
            for _, mem in ipairs(context.court.members) do
                if mem.role == "sibling" and not vars.sibling_name then
                    vars.sibling_name = mem.name
                elseif mem.role == "spouse" and not vars.spouse_name then
                    vars.spouse_name = mem.name
                end
            end
        end
        vars.sibling_name = vars.sibling_name or "your sibling"
        vars.spouse_name = vars.spouse_name or "your spouse"

        -- Resolve faction name from target_faction (on consequences or context)
        local tfaction = consequences.target_faction or context.target_faction
        if tfaction and context.factions then
            local f = context.factions:get(tfaction)
            if f then
                vars.faction_name = f.name
                vars.faction_id = f.id
                vars.faction_motto = f.motto or ""
            end
        end
        narrative = EventEngine.substitute(narrative, vars)
    end
    local effects = { narrative = narrative }
    local lines = {}  -- consequence visibility lines

    -- Mutation triggers
    if consequences.mutation_triggers then
        local Mutation = require("dredwork_genetics.mutation")
        for _, mt in ipairs(consequences.mutation_triggers) do
            Mutation.add_trigger(context.mutation_pressure, mt.type, mt.intensity or 1.0)
            lines[#lines + 1] = {
                text = "Mutation pressure stirs (" .. (mt.type or "unknown") .. ")",
                color_key = "special",
            }
        end
    end

    -- Disposition changes
    if consequences.disposition_changes and context.factions then
        for _, dc in ipairs(consequences.disposition_changes) do
            if dc.faction_id == "all" then
                context.factions:shift_all_disposition(dc.delta)
                local sign = dc.delta >= 0 and "+" or ""
                lines[#lines + 1] = {
                    text = "All factions: " .. sign .. tostring(dc.delta),
                    color_key = dc.delta >= 0 and "positive" or "negative",
                }
            else
                local fid = dc.faction_id
                -- Resolve _target to actual faction name
                if fid == "_target" and consequences.target_faction then
                    fid = consequences.target_faction
                end
                local f = context.factions:get(fid)
                if f then
                    f:shift_disposition(dc.delta)
                    local sign = dc.delta >= 0 and "+" or ""
                    lines[#lines + 1] = {
                        text = f.name .. ": " .. sign .. tostring(dc.delta),
                        color_key = dc.delta >= 0 and "positive" or "negative",
                    }
                end
            end
        end
    end

    -- Taboo chance
    if consequences.taboo_chance and consequences.taboo_data then
        if rng.chance(consequences.taboo_chance) then
            -- Resolve {faction_id} placeholder in effect string
            local taboo_effect = consequences.taboo_data.effect or ""
            local tfaction_id = consequences.target_faction or context.target_faction
            if tfaction_id then
                taboo_effect = taboo_effect:gsub("{faction_id}", tfaction_id)
            end

            context.cultural_memory:add_taboo(
                consequences.taboo_data.trigger,
                context.generation,
                taboo_effect,
                consequences.taboo_data.strength or 85
            )
            effects.taboo_formed = taboo_effect

            -- Build human-readable taboo label (resolve faction name)
            local taboo_label = taboo_effect:gsub("_", " ")
            if tfaction_id and context.factions then
                local f = context.factions:get(tfaction_id)
                if f and f.name then
                    taboo_label = taboo_label:gsub(tfaction_id:gsub("_", " "), f.name)
                end
            end
            lines[#lines + 1] = {
                text = "TABOO FORMED: " .. taboo_label,
                color_key = "negative",
            }
        end
    end

    -- Cultural memory shift
    if consequences.cultural_memory_shift then
        local cat_to_prefix = {
            physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE",
        }
        local cat_labels = {
            physical = "BODY", mental = "MIND", social = "WORD", creative = "ART",
        }
        for cat, delta in pairs(consequences.cultural_memory_shift) do
            local prefix = cat_to_prefix[cat]
            if prefix then
                -- Count traits in category to scale shift properly
                local trait_count = 0
                for id, _ in pairs(context.cultural_memory.trait_priorities) do
                    if id:sub(1, 3) == prefix then trait_count = trait_count + 1 end
                end
                -- Spread the shift across traits so +3 physical means +3 to the
                -- category average, not +3 to each of ~18 individual traits
                local per_trait = trait_count > 0 and (delta / trait_count) or 0
                for id, priority in pairs(context.cultural_memory.trait_priorities) do
                    if id:sub(1, 3) == prefix then
                        context.cultural_memory.trait_priorities[id] =
                            Math.clamp(priority + per_trait, 0, 100)
                    end
                end
                if delta ~= 0 then
                    local direction = delta > 0 and "rises" or "falls"
                    lines[#lines + 1] = {
                        text = "The bloodline shifts: " .. (cat_labels[cat] or cat:upper()) .. " " .. direction,
                        color_key = "neutral",
                    }
                end
            end
        end
    end

    -- Add condition
    if consequences.add_condition then
        local ac = consequences.add_condition
        context.world_state:add_condition(ac.type, ac.intensity or 0.5, ac.duration or 3)
        lines[#lines + 1] = {
            text = "A shadow descends: " .. (ac.type or ""):upper(),
            color_key = "negative",
        }
    end

    -- Remove condition
    if consequences.remove_condition then
        context.world_state:remove_condition(consequences.remove_condition)
        lines[#lines + 1] = {
            text = (consequences.remove_condition or ""):upper() .. " has been lifted",
            color_key = "positive",
        }
    end

    -- Add relationship to cultural memory
    if consequences.add_relationship and consequences.target_faction then
        context.cultural_memory:add_relationship(
            consequences.target_faction,
            consequences.add_relationship.type,
            context.generation,
            consequences.add_relationship.strength or 60,
            consequences.add_relationship.reason or "event"
        )
        local rel_type = consequences.add_relationship.type
        local f = context.factions and context.factions:get(consequences.target_faction)
        local fname = f and f.name or consequences.target_faction
        if rel_type == "ally" then
            lines[#lines + 1] = {
                text = "Bond forged: ally with " .. fname,
                color_key = "positive",
            }
        else
            lines[#lines + 1] = {
                text = "Enmity declared: enemy of " .. fname,
                color_key = "negative",
            }
        end
    end

    -- Arranged marriage lock: force next matchmaking to this faction
    if consequences.arranged_marriage_lock and consequences.target_faction and context.game_state then
        local previous_faction = context.game_state.arranged_marriage_faction
        -- Broken betrothal: betraying a prior marriage pact has severe consequences
        if previous_faction and previous_faction ~= consequences.target_faction and context.factions then
            local betrayed = context.factions:get(previous_faction)
            if betrayed then
                local betrayed_name = betrayed.name or previous_faction:gsub("_", " ")
                -- Massive disposition hit
                betrayed:shift_disposition(-30)
                -- Add grudge if faction supports it
                if betrayed.add_grudge then
                    betrayed:add_grudge("player", "broken_betrothal", context.generation or 1, 70)
                end
                -- Moral act: oath-breaking
                if context.game_state.morality then
                    local Morality = require("dredwork_world.morality")
                    Morality.record_act(context.game_state.morality, "betrayal", context.generation or 1, "Broke a betrothal oath")
                end
                -- Chronicle entry
                if context.world_state then
                    context.world_state:add_chronicle(
                        "A betrothal to " .. betrayed_name .. " was broken. The oath-breakers chose a new alliance. " .. betrayed_name .. " will not forget.",
                        { origin = { type = "betrayal", heir_name = context.game_state.heir_name, gen = context.generation or 1, detail = "Broken betrothal" } }
                    )
                end
                lines[#lines + 1] = {
                    text = "Betrothal to " .. betrayed_name .. " broken — they are furious",
                    color_key = "negative",
                }
                -- Reputation hit with all factions (oath-breakers are untrustworthy)
                if context.factions.get_active then
                    for _, fac in ipairs(context.factions:get_active()) do
                        if fac.id ~= consequences.target_faction and fac.id ~= previous_faction then
                            fac:shift_disposition(-8)
                        end
                    end
                end
            end
        end
        context.game_state.arranged_marriage_faction = consequences.target_faction
        local f = context.factions and context.factions:get(consequences.target_faction)
        local fname = f and f.name or consequences.target_faction
        lines[#lines + 1] = {
            text = "Betrothed to " .. fname,
            color_key = "neutral",
        }
    end

    -- Power shift on target faction
    if consequences.faction_power_shift and consequences.target_faction then
        local f = context.factions:get(consequences.target_faction)
        if f then
            f:shift_power(consequences.faction_power_shift)
            local direction = consequences.faction_power_shift > 0 and "grows stronger" or "grows weaker"
            lines[#lines + 1] = {
                text = f.name .. " " .. direction,
                color_key = "neutral",
            }
        end
    end

    -- Kill nemesis (blood rite consequence)
    if consequences.kill_nemesis and context.rival_heirs then
        pcall(function()
            local nemesis = context.rival_heirs:get_nemesis()
            if nemesis and nemesis.alive then
                nemesis.alive = false
                local nem_name = nemesis.name or "the Nemesis"
                lines[#lines + 1] = {
                    text = nem_name .. " has been erased",
                    color_key = "negative",
                }
                if context.world_state then
                    context.world_state:add_chronicle(nem_name .. " was struck from the record by ritual.", {
                        origin = {
                            type = "blood_rite",
                            heir_name = context.heir_name or "Unknown",
                            gen = context.generation or 0,
                            detail = "kill_nemesis"
                        }
                    })
                end
            end
        end)
    end

    -- Lineage Power shift
    if consequences.lineage_power_shift and context.lineage_power then
        pcall(function()
            local LP = require("dredwork_world.lineage_power")
            local delta = consequences.lineage_power_shift
            LP.shift(context.lineage_power, delta)
            local tier = LP.get_tier(context.lineage_power)
            local sign = delta >= 0 and "+" or ""
            lines[#lines + 1] = {
                text = "Power " .. sign .. tostring(delta) .. " (" .. tier.label .. ")",
                color_key = delta >= 0 and "positive" or "negative",
            }
        end)
    end

    -- Mutation pressure reduction
    if consequences.mutation_pressure_reduction and context.mutation_pressure then
        pcall(function()
            local reduction = consequences.mutation_pressure_reduction
            context.mutation_pressure.value = math.max(0, context.mutation_pressure.value - reduction)
            lines[#lines + 1] = {
                text = "Mutation pressure eases (-" .. reduction .. ")",
                color_key = "positive",
            }
        end)
    end

    -- Rival heir interaction
    if consequences.rival_interaction and context.rival_heirs then
        pcall(function()
            local ri = consequences.rival_interaction
            local rfid = ri.rival_faction
            if rfid == "_target" and consequences.target_faction then
                rfid = consequences.target_faction
            end
            local rival = context.rival_heirs:get(rfid)
            if rival and rival.alive then
                local ok_rmod, rival_mod = pcall(require, "dredwork_world.rival_heirs")
                if ok_rmod and rival_mod then
                    rival_mod.RivalHeirs.record_interaction(
                        rival,
                        context.generation or 0,
                        ri.event_type or "encounter",
                        ri.description or "",
                        ri.rivalry_delta or 0
                    )
                    if ri.rivalry_delta and ri.rivalry_delta ~= 0 then
                        local sign = ri.rivalry_delta > 0 and "+" or ""
                        lines[#lines + 1] = {
                            text = rival.name .. ": rivalry " .. sign .. tostring(ri.rivalry_delta),
                            color_key = ri.rivalry_delta > 0 and "positive" or "negative",
                        }
                    end
                end
            end
        end)
    end

    -- Religion effects (schism choices, zealotry changes)
    if consequences.religion_action and context.religion then
        pcall(function()
            local action = consequences.religion_action
            if action == "preserve" then
                -- Keep religion, reduce zealotry slightly
                context.religion.zealotry = math.max(20, context.religion.zealotry - 10)
                lines[#lines + 1] = {
                    text = "The faith endures, shaken but whole",
                    color_key = "neutral",
                }
            elseif action == "reform" then
                -- Regenerate tenets from current cultural memory
                if context.cultural_memory then
                    context.religion:generate(context.cultural_memory, context.generation or 1)
                end
                lines[#lines + 1] = {
                    text = "A new creed rises",
                    color_key = "special",
                }
            elseif action == "abandon" then
                -- Deactivate religion
                context.religion.active = false
                context.religion.zealotry = 0
                lines[#lines + 1] = {
                    text = "The faith is abandoned",
                    color_key = "negative",
                }
            elseif action == "boost_zealotry" then
                context.religion.zealotry = math.min(100, context.religion.zealotry + 20)
                lines[#lines + 1] = {
                    text = "Religious zealotry surges",
                    color_key = "positive",
                }
            end
        end)
    end

    -- Court Sacrifice (Pantheon Bargain)
    if consequences.trigger_court_sacrifice and context.court and #context.court.members > 0 then
        pcall(function()
            local best_idx = 1
            local best_comp = -1
            for i, mem in ipairs(context.court.members) do
                if mem.status == "active" and (mem.competence or 0) > best_comp then
                    best_comp = mem.competence or 0
                    best_idx = i
                end
            end
            local sacrificed = context.court.members[best_idx]
            if sacrificed then
                sacrificed.status = "dead"
                lines[#lines + 1] = {
                    text = sacrificed.name .. " (" .. sacrificed.role .. ") was sacrificed to the Pantheon.",
                    color_key = "negative",
                }
                -- Clear from campaign if they were the general
                if context.campaign and context.campaign.general_name == sacrificed.name then
                    context.campaign:assign_general(nil)
                end
            end
        end)
    end

    -- Genome Modification (Pantheon Bargain or permanent damage)
    if consequences.modify_genome and context.heir_genome then
        pcall(function()
            local trait_id = consequences.modify_genome.trait
            local delta = consequences.modify_genome.delta
            if trait_id and delta then
                local current = context.heir_genome:get_value(trait_id) or 50
                context.heir_genome:set_value(trait_id, Math.clamp(current + delta, 0, 100))
                local sign = delta >= 0 and "+" or ""
                lines[#lines + 1] = {
                    text = "Bloodline altered: " .. trait_id:gsub("_", " ") .. " " .. sign .. delta,
                    color_key = delta >= 0 and "positive" or "negative",
                }
            end
        end)
    end

    -- Wealth change
    if consequences.wealth_change and context.wealth then
        pcall(function()
            local Wealth = require("dredwork_world.wealth")
            local wc = consequences.wealth_change
            Wealth.change(context.wealth, wc.delta or 0, wc.source or "trade",
                context.generation or 0, wc.description)
            local tier = Wealth.get_tier(context.wealth)
            local sign = (wc.delta or 0) >= 0 and "+" or ""
            lines[#lines + 1] = {
                text = "Wealth " .. sign .. tostring(math.floor(wc.delta or 0)) .. " (" .. tier.label .. ")",
                color_key = (wc.delta or 0) >= 0 and "positive" or "negative",
            }
        end)
    end

    -- Gain Holding
    if consequences.gain_holding and context.holdings then
        pcall(function()
            local def = consequences.gain_holding
            -- Proc-gen name if marked "generate" or missing
            if not def.name or def.name == "generate" or def.name == "New Holding" or def.name == "New Settlement" then
                local Holdings = require("dredwork_world.holdings")
                local era_key = context.world_state and context.world_state.current_era_key or "ancient"
                def.name = Holdings.generate_name(def.type or "village", era_key)
            end
            context.holdings:add_domain(def)
            lines[#lines + 1] = {
                text = "Domain Acquired: " .. (def.name or "New Holding"),
                color_key = "positive",
            }
            -- Gaining a holding ends exodus — you have a home now
            if context.world_state and context.world_state:has_condition("exodus") then
                context.world_state:remove_condition("exodus")
                lines[#lines + 1] = {
                    text = "EXODUS ENDED — the bloodline has put down roots",
                    color_key = "positive",
                }
            end
        end)
    end

    -- Lose Holding (supports numeric count: lose_holding = 2 means lose 2 domains)
    if consequences.lose_holding and context.holdings then
        pcall(function()
            local count = type(consequences.lose_holding) == "number" and consequences.lose_holding or 1
            for _ = 1, count do
                local lost = context.holdings:lose_domain()
                if lost then
                    lines[#lines + 1] = {
                        text = "Domain Lost: " .. (lost.name or "A Holding"),
                        color_key = "negative",
                    }
                end
            end
        end)
    end

    -- Damage Holding (reduce size of a random domain)
    if consequences.damage_holding and context.holdings then
        pcall(function()
            local dmg = context.holdings:damage_random_domain()
            if dmg then
                lines[#lines + 1] = {
                    text = dmg,
                    color_key = "negative",
                }
            end
        end)
    end

    -- Gain Artifact
    if consequences.gain_artifact and context.reliquary then
        pcall(function()
            local def = consequences.gain_artifact
            def.forged_by = context.heir_name
            def.forged_gen = context.generation
            context.reliquary:add_artifact(def)
            lines[#lines + 1] = {
                text = "Artifact Claimed: " .. (def.name or "Relic"),
                color_key = "special",
            }
        end)
    end

    -- Lose Artifact
    if consequences.lose_artifact and context.reliquary then
        pcall(function()
            local to_lose = nil
            if type(consequences.lose_artifact) == "string" then
                to_lose = consequences.lose_artifact
            else
                local rnd = context.reliquary:get_random()
                if rnd then to_lose = rnd.id end
            end
            if to_lose and context.reliquary:lose_artifact(to_lose) then
                lines[#lines + 1] = {
                    text = "Artifact Lost: " .. to_lose,
                    color_key = "negative",
                }
            end
        end)
    end

    -- Clear Grudge (faction clears grudge against player)
    if consequences.clear_grudge and consequences.target_faction then
        pcall(function()
            local factions = context.factions
            if factions then
                local faction = factions:get(consequences.target_faction)
                if faction and faction.grudges then
                    local live = {}
                    for _, g in ipairs(faction.grudges) do
                        if g.target ~= "player" then
                            live[#live + 1] = g
                        end
                    end
                    faction.grudges = live
                    lines[#lines + 1] = {
                        text = "Grudge cleared with " .. (faction.name or "a rival house"),
                        color_key = "positive",
                    }
                end
            end
        end)
    end

    -- Intensify Grudge (faction grudge against player grows stronger)
    if consequences.intensify_grudge and consequences.target_faction then
        pcall(function()
            local factions = context.factions
            if factions then
                local faction = factions:get(consequences.target_faction)
                if faction and faction.has_grudge then
                    local grudge = faction:has_grudge("player")
                    if grudge then
                        grudge.intensity = math.min(100, grudge.intensity + consequences.intensify_grudge)
                    else
                        faction:add_grudge("player", "escalation", context.generation or 0, consequences.intensify_grudge)
                    end
                    lines[#lines + 1] = {
                        text = (faction.name or "A rival house") .. " remembers this wrong.",
                        color_key = "negative",
                    }
                end
            end
        end)
    end

    -- Resource Cost (deduct multiple resource types)
    if consequences.resource_cost and context.resources then
        pcall(function()
            for res_type, amount in pairs(consequences.resource_cost) do
                context.resources:change(res_type, -amount, "Event cost")
                lines[#lines + 1] = {
                    text = res_type:upper() .. " -" .. tostring(amount),
                    color_key = "negative",
                }
            end
        end)
    end

    -- Resource Gain (add multiple resource types)
    if consequences.resource_gain and context.resources then
        pcall(function()
            for res_type, amount in pairs(consequences.resource_gain) do
                context.resources:change(res_type, amount, "Event reward")
                lines[#lines + 1] = {
                    text = res_type:upper() .. " +" .. tostring(amount),
                    color_key = "positive",
                }
            end
        end)
    end

    -- Found Cadet Branch (Shadow Lineage)
    if consequences.found_cadet_branch and context.shadow_lineages and context.court then
        pcall(function()
            local sibling = nil
            local to_remove = nil
            for i, mem in ipairs(context.court.members) do
                if mem.role == "sibling" then
                    sibling = mem
                    to_remove = i
                    break
                end
            end
            if sibling then
                local branch = context.shadow_lineages:found_branch(sibling, context.generation)
                table.remove(context.court.members, to_remove)
                lines[#lines + 1] = {
                    text = "A cadet branch has departed to the wild.",
                    color_key = "special",
                }
            end
        end)
    end

    -- Add Court Member
    if consequences.add_court_member and context.court then
        pcall(function()
            local def = consequences.add_court_member
            context.court:add_member(def)
            lines[#lines + 1] = {
                text = "Courtier Added: " .. (def.name or "Unknown"),
                color_key = "neutral",
            }
        end)
    end

    -- Resource Change (Generic handler for grain, steel, lore, gold)
    -- Supports both single { type, delta, reason } and array { {type,delta,reason}, ... }
    local function handle_res(res_con, context, lines)
        if res_con and context.resources then
            pcall(function()
                local changes = res_con
                if changes.type then changes = { changes } end
                for _, rc in ipairs(changes) do
                    context.resources:change(rc.type, rc.delta, rc.reason)
                    local sign = rc.delta >= 0 and "+" or ""
                    lines[#lines + 1] = {
                        text = rc.type:upper() .. " " .. sign .. tostring(rc.delta),
                        color_key = rc.delta >= 0 and "positive" or "negative",
                    }
                end
            end)
        end
    end

    handle_res(consequences.resource_change, context, lines)
    handle_res(consequences.resource_change_2, context, lines)

    -- Moral act
    if consequences.moral_act and context.morality then
        pcall(function()
            local MoralityMod = require("dredwork_world.morality")
            local ma = consequences.moral_act
            MoralityMod.record_act(context.morality, ma.act_id, context.generation or 0, ma.description)
            lines[#lines + 1] = {
                text = "Moral act: " .. (ma.description or ma.act_id):gsub("_", " "),
                color_key = (context.morality.score >= 0) and "neutral" or "negative",
            }
        end)
    end

    -- Offspring boost (trait bonus for next generation)
    if consequences.offspring_boost then
        local boost = consequences.offspring_boost
        -- Normalize bare numbers to table format
        if type(boost) == "number" then
            boost = { bonus = boost }
        end
        effects.offspring_boost = boost
        local label = boost.trait and boost.trait:gsub("_", " ") or "offspring"
        local bonus = boost.bonus or boost.amount or 0
        lines[#lines + 1] = {
            text = "Next generation shaped: " .. label .. " +" .. tostring(bonus),
            color_key = "special",
        }
    end

    -- Add chronicle entry (use substituted narrative)
    if narrative and narrative ~= "" then
        context.world_state:add_chronicle(narrative)
    end

    effects.consequence_lines = lines
    return effects
end

--- Resolve a personal (auto-resolve) event. No player choice.
---@param event table the personal event
---@param context table
---@return table effects
function EventEngine.auto_resolve(event, context)
    if event.auto_consequence then
        return EventEngine.apply_consequences(event.auto_consequence, context)
    end
    return { narrative = event.narrative or "" }
end

--- Substitute template variables in text.
---@param text string template text with {var} placeholders
---@param vars table { heir_name, faction_name, era_name, ... }
---@return string
function EventEngine.substitute(text, vars)
    if not text then return "" end
    return text:gsub("{([%w_]+)}", function(key)
        return vars[key] or ""
    end)
end

-- =========================================================================
-- Internal: cooldown check helper
-- =========================================================================

--- Check if an event is on cooldown.
---@param tmpl table event template with optional cooldown field
---@param context table context with world_state.used_events
---@return boolean true if event is on cooldown and should be skipped
function EventEngine._is_on_cooldown(tmpl, context)
    if not tmpl.cooldown or not context.world_state then return false end
    local used = context.world_state.used_events
    if not used then return false end
    local last_gen = used[tmpl.id .. "_gen"]
    if not last_gen then return false end
    local current_gen = context.generation or 0
    return (current_gen - last_gen) < tmpl.cooldown
end

--- Mark an event as used with generation stamp for cooldown tracking.
---@param tmpl table event template
---@param context table context with world_state
function EventEngine._mark_used(tmpl, context)
    if not context.world_state then return end
    context.world_state.used_events = context.world_state.used_events or {}
    if tmpl.once_per_run then
        context.world_state.used_events[tmpl.id] = true
    end
    if tmpl.cooldown then
        context.world_state.used_events[tmpl.id .. "_gen"] = context.generation or 0
    end
end

-- =========================================================================
-- Internal: event generators by type
-- =========================================================================

function EventEngine:_generate_personal(context, templates)
    local events = {}
    local pers = context.heir_personality
    if not pers then return events end

    for _, tmpl in ipairs(templates) do
        local axis_val = pers:get_axis(tmpl.trigger_axis)
        local triggered = false
        if tmpl.trigger_min and axis_val >= tmpl.trigger_min then
            triggered = true
        end
        if tmpl.trigger_max and axis_val <= tmpl.trigger_max then
            triggered = true
        end
        if triggered then
            local skip = false

            -- once_per_run check
            if tmpl.once_per_run then
                local ws = context.world_state
                if ws then
                    local used = ws.used_events or {}
                    if used[tmpl.id] then skip = true end
                end
            end

            -- Cooldown check
            if not skip and EventEngine._is_on_cooldown(tmpl, context) then
                skip = true
            end

            -- Generation minimum check
            if not skip and tmpl.requires_generation_min then
                if (context.generation or 0) < tmpl.requires_generation_min then
                    skip = true
                end
            end

            if not skip and rng.chance(tmpl.chance or 0.4) then
                local vars = self:_build_vars(context, tmpl)

                -- Mark used with cooldown tracking
                EventEngine._mark_used(tmpl, context)

                events[#events + 1] = {
                    type = "personal",
                    id = tmpl.id,
                    title = EventEngine.substitute(tmpl.title, vars),
                    narrative = EventEngine.substitute(tmpl.narrative, vars),
                    auto_resolve = true,
                    auto_consequence = tmpl.consequence,
                    target_faction = tmpl.pick_faction and self:_pick_faction(context) or nil,
                    trigger_axis = tmpl.trigger_axis,
                }
                -- Only one personal event per generation
                return events
            end
        end
    end

    return events
end

function EventEngine:_generate_world(context, templates)
    local events = {}
    local ws = context.world_state
    if not ws then return events end

    -- Shuffle template evaluation order so no category always gets priority
    local shuffled = {}
    for i, t in ipairs(templates) do shuffled[i] = t end
    for i = #shuffled, 2, -1 do
        local j = rng.range(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    for _, tmpl in ipairs(shuffled) do
        local eligible = true

        -- Check condition triggers
        if tmpl.requires_condition then
            eligible = ws:has_condition(tmpl.requires_condition)
        end
        if tmpl.requires_no_condition then
            if type(tmpl.requires_no_condition) == "table" then
                for _, cond in ipairs(tmpl.requires_no_condition) do
                    if ws:has_condition(cond) then eligible = false; break end
                end
            else
                eligible = not ws:has_condition(tmpl.requires_no_condition)
            end
        end
        if tmpl.requires_era then
            eligible = eligible and (ws.current_era_key == tmpl.requires_era)
        end

        -- once_per_run check
        if eligible and tmpl.once_per_run then
            local used = ws.used_events or {}
            if used[tmpl.id] then eligible = false end
        end

        -- Cooldown check
        if eligible and EventEngine._is_on_cooldown(tmpl, context) then
            eligible = false
        end

        -- Generation minimum check
        if eligible and tmpl.requires_generation_min then
            eligible = (context.generation or 0) >= tmpl.requires_generation_min
        end

        -- NEW: Court Role trigger
        if eligible and tmpl.trigger and tmpl.trigger.requires_court_role and context.court then
            local found = false
            for _, mem in ipairs(context.court.members) do
                if mem.role == tmpl.trigger.requires_court_role then
                    found = true; break
                end
            end
            if not found then eligible = false end
        end

        -- NEW: Rival trigger
        if eligible and tmpl.trigger and tmpl.trigger.requires_rival and context.rival_heirs then
            local nemesis = context.rival_heirs:get_nemesis()
            if not nemesis or not nemesis.alive then eligible = false end
        end

        -- Check taboo blocks
        if eligible and tmpl.blocked_by_taboo and context.cultural_memory then
            if context.cultural_memory:is_taboo(tmpl.blocked_by_taboo) then
                eligible = false
            end
        end

        -- Morality gates (events that require specific moral standing)
        if eligible and tmpl.requires_morality_min and context.morality then
            local score = context.morality.score or 0
            if score < tmpl.requires_morality_min then eligible = false end
        end
        if eligible and tmpl.requires_morality_max and context.morality then
            local score = context.morality.score or 0
            if score > tmpl.requires_morality_max then eligible = false end
        end

        -- Zealotry gate (events that require minimum zealotry)
        if eligible and tmpl.requires_zealotry_min then
            local zealotry = context.religion and context.religion.zealotry or 0
            if zealotry < tmpl.requires_zealotry_min then eligible = false end
        end

        -- Resource threshold gate (fire when resource at or below max)
        if eligible and tmpl.requires_resource_max and context.resources then
            pcall(function()
                local res_val = context.resources[tmpl.requires_resource_max.type] or 99
                if res_val > (tmpl.requires_resource_max.value or 0) then
                    eligible = false
                end
            end)
        end

        -- Momentum boost: ascending blood in a related category increases chance
        local base_chance = tmpl.chance or 0.3
        local cat_hint = EventEngine._guess_category(tmpl.requires_condition)
        local momentum_boost = EventEngine._momentum_chance_boost(context, cat_hint)

        if eligible and rng.chance(base_chance + momentum_boost) then
            local vars = self:_build_vars(context, tmpl)
            local options = self:_prepare_options(tmpl.options, context, vars)

            if #options > 0 then
                -- Mark used with cooldown tracking
                EventEngine._mark_used(tmpl, context)

                events[#events + 1] = {
                    type = "world",
                    id = tmpl.id,
                    title = EventEngine.substitute(tmpl.title, vars),
                    opening = EventEngine.substitute(tmpl.opening, vars), -- Pass opening
                    narrative = EventEngine.substitute(tmpl.narrative, vars),
                    interlocutor = tmpl.interlocutor and {
                        name = EventEngine.substitute(tmpl.interlocutor.name or "", vars),
                        role = tmpl.interlocutor.role,
                    } or nil, -- Pass interlocutor for UI (substituted)
                    options = options,
                    auto_resolve = false,
                }
                -- Max 1 world event per generation
                return events
            end
        end
    end

    return events
end

function EventEngine:_generate_faction(context, templates)
    local events = {}
    if not context.factions then return events end

    local active_factions = context.factions:get_active()
    if #active_factions == 0 then return events end
    local ws = context.world_state

    for _, tmpl in ipairs(templates) do
        local skip = false

        -- once_per_run check
        if tmpl.once_per_run and ws then
            local used = ws.used_events or {}
            if used[tmpl.id] then skip = true end
        end

        -- Cooldown check
        if not skip and EventEngine._is_on_cooldown(tmpl, context) then
            skip = true
        end

        -- Generation minimum check
        if not skip and tmpl.requires_generation_min then
            if (context.generation or 0) < tmpl.requires_generation_min then
                skip = true
            end
        end

        if not skip then
            -- Find a faction matching disposition requirements
            for _, faction in ipairs(active_factions) do
                local eligible = true
                if tmpl.disposition_min and faction.disposition < tmpl.disposition_min then
                    eligible = false
                end
                if tmpl.disposition_max and faction.disposition > tmpl.disposition_max then
                    eligible = false
                end

                -- faction_type filter: match faction's dominant category or reputation
                if eligible and tmpl.faction_type then
                    local ft = tmpl.faction_type
                    local matches = false
                    -- Check reputation primary
                    if faction.reputation and faction.reputation.primary == ft then
                        matches = true
                    end
                    -- Check dominant category (more reliable)
                    if not matches and faction.get_dominant_category then
                        local dom = faction:get_dominant_category()
                        if dom == ft then matches = true end
                    end
                    -- Check category_scores directly (fallback)
                    if not matches and faction.category_scores then
                        local best_cat, best_val = nil, -1
                        for cat, val in pairs(faction.category_scores) do
                            if val > best_val then best_cat, best_val = cat, val end
                        end
                        if best_cat == ft then matches = true end
                    end
                    eligible = matches
                end

                -- Faction power gates
                if eligible and tmpl.faction_power_min then
                    eligible = (faction.power or 0) >= tmpl.faction_power_min
                end
                if eligible and tmpl.faction_power_max then
                    eligible = (faction.power or 0) <= tmpl.faction_power_max
                end

                if eligible and tmpl.blocked_by_taboo and context.cultural_memory then
                    local taboo_effect = tmpl.blocked_by_taboo:gsub("{faction_id}", faction.id)
                    if context.cultural_memory:is_taboo(taboo_effect) then
                        eligible = false
                    end
                end

                -- World Condition gates
                if eligible and tmpl.requires_condition and context.world_state then
                    if not context.world_state:has_condition(tmpl.requires_condition) then
                        eligible = false
                    end
                end
                if eligible and tmpl.requires_no_condition and context.world_state then
                    if type(tmpl.requires_no_condition) == "table" then
                        for _, cond in ipairs(tmpl.requires_no_condition) do
                            if context.world_state:has_condition(cond) then eligible = false; break end
                        end
                    elseif context.world_state:has_condition(tmpl.requires_no_condition) then
                        eligible = false
                    end
                end

                -- Rival heir requirement gate
                if eligible and tmpl.requires_rival then
                    local rival = context.rival_heirs and context.rival_heirs:get(faction.id)
                    if not rival or not rival.alive then
                        eligible = false
                    end
                    -- Optional attitude gate
                    if eligible and tmpl.rival_attitude then
                        eligible = (rival.attitude == tmpl.rival_attitude)
                    end
                    -- Optional rivalry score gates
                    if eligible and tmpl.rival_rivalry_min then
                        eligible = (rival.rivalry_score >= tmpl.rival_rivalry_min)
                    end
                    if eligible and tmpl.rival_rivalry_max then
                        eligible = (rival.rivalry_score <= tmpl.rival_rivalry_max)
                    end
                end

                -- Ambition gate: faction must have this ambition type
                if eligible and tmpl.requires_ambition then
                    eligible = faction.ambition and faction.ambition.type == tmpl.requires_ambition
                end

                -- Ambition progress gate
                if eligible and tmpl.requires_ambition_progress_min then
                    eligible = faction.ambition and (faction.ambition.progress or 0) >= tmpl.requires_ambition_progress_min
                end

                -- Grudge gate: faction must hold grudge against player
                if eligible and tmpl.requires_grudge_against_player then
                    eligible = faction.has_grudge and faction:has_grudge("player") ~= nil
                end

                -- Rumor boost: if active rumors mention this faction, increase chance
                local rumor_boost = 0
                if context.rumors and context.rumors.get_for_faction then
                    local faction_rumors = context.rumors:get_for_faction(faction.id)
                    if #faction_rumors > 0 then
                        rumor_boost = math.min(0.15, #faction_rumors * 0.05)
                    end
                end

                -- Momentum boost: faction's dominant category matching ascending blood
                local faction_cat = faction:get_dominant_category()
                local faction_momentum = EventEngine._momentum_chance_boost(context, faction_cat)

                if eligible and rng.chance((tmpl.chance or 0.25) + rumor_boost + faction_momentum) then
                    local vars = self:_build_vars(context, tmpl)
                    vars.faction_name = faction.name
                    vars.faction_id = faction.id
                    vars.faction_motto = faction.motto

                    -- Inject rival heir vars when available
                    local rival = context.rival_heirs and context.rival_heirs:get(faction.id)
                    if rival and rival.alive then
                        vars.rival_name = rival.name
                        vars.rival_attitude = rival.attitude
                        vars.rival_faction = rival.faction_name
                    end

                    local options = self:_prepare_options(tmpl.options, context, vars)

                    if #options > 0 then
                        -- Inject target faction into consequences
                        for _, opt in ipairs(options) do
                            if opt.consequences then
                                opt.consequences.target_faction = faction.id
                            end
                        end

                        -- Mark used with cooldown tracking
                        EventEngine._mark_used(tmpl, context)

                        events[#events + 1] = {
                            type = "faction",
                            id = tmpl.id,
                            title = EventEngine.substitute(tmpl.title, vars),
                            narrative = EventEngine.substitute(tmpl.narrative, vars),
                            options = options,
                            auto_resolve = false,
                            target_faction = faction.id,
                        }
                        -- Max faction events per generation: 2 when any faction has urgent ambition, else 1
                        local max_faction = 1
                        for _, af in ipairs(active_factions) do
                            if af.ambition and (af.ambition.progress or 0) > 60 then
                                max_faction = 2
                                break
                            end
                        end
                        if #events >= max_faction then
                            return events
                        end
                    end
                end
            end
        end
    end

    return events
end

function EventEngine:_generate_legacy(context, templates)
    local events = {}
    local cm = context.cultural_memory
    if not cm then return events end
    local ws = context.world_state

    for _, tmpl in ipairs(templates) do
        local eligible = false

        -- Check legacy condition
        if tmpl.requires == "active_taboo" then
            eligible = #cm.taboos > 0
        elseif tmpl.requires == "blind_spot" then
            eligible = #cm:get_blind_spots() > 0
        elseif tmpl.requires == "strong_reputation" then
            eligible = true -- always possible
        elseif tmpl.requires == "old_relationship" then
            for _, rel in ipairs(cm.relationships) do
                if (context.generation - rel.origin_gen) >= 5 then
                    eligible = true
                    break
                end
            end
        elseif tmpl.requires == "old_relationship_ally" then
            for _, rel in ipairs(cm.relationships) do
                if rel.type == "ally" and (context.generation - rel.origin_gen) >= 5 then
                    eligible = true
                    break
                end
            end
        elseif tmpl.requires == "old_relationship_enemy" then
            for _, rel in ipairs(cm.relationships) do
                if rel.type == "enemy" and (context.generation - rel.origin_gen) >= 3 then
                    eligible = true
                    break
                end
            end
        elseif tmpl.requires == "multiple_taboos" then
            eligible = #cm.taboos >= 2
        elseif not tmpl.requires then
            -- No specific cultural memory requirement — eligible by default
            eligible = true
        end

        -- once_per_run check
        if eligible and tmpl.once_per_run and ws then
            local used = ws.used_events or {}
            if used[tmpl.id] then eligible = false end
        end

        -- Cooldown check
        if eligible and EventEngine._is_on_cooldown(tmpl, context) then
            eligible = false
        end

        -- Generation minimum check
        if eligible and tmpl.requires_generation_min then
            eligible = (context.generation or 0) >= tmpl.requires_generation_min
        end

        -- Exact generation check (for milestone events)
        if eligible and tmpl.requires_generation_exact then
            eligible = (context.generation or 0) == tmpl.requires_generation_exact
        end

        -- Condition check on legacy events
        if eligible and tmpl.requires_condition then
            eligible = ws and ws:has_condition(tmpl.requires_condition)
        end

        if eligible and rng.chance(tmpl.chance or 0.2) then
            local vars = self:_build_vars(context, tmpl)

            -- Add context-specific vars
            if (tmpl.requires == "active_taboo" or tmpl.requires == "multiple_taboos") and #cm.taboos > 0 then
                local taboo = cm.taboos[rng.range(1, #cm.taboos)]
                vars.taboo_effect = (taboo.effect or ""):gsub("_", " ")
                vars.taboo_trigger = (taboo.trigger or ""):gsub("_", " ")
            end
            if tmpl.requires == "blind_spot" then
                local bs = cm:get_blind_spots()
                if #bs > 0 then
                    vars.blind_spot_category = bs[1]
                end
            end

            local options = self:_prepare_options(tmpl.options, context, vars)

            if #options > 0 then
                -- Mark used with cooldown tracking
                EventEngine._mark_used(tmpl, context)

                events[#events + 1] = {
                    type = "legacy",
                    id = tmpl.id,
                    title = EventEngine.substitute(tmpl.title, vars),
                    narrative = EventEngine.substitute(tmpl.narrative, vars),
                    options = options,
                    auto_resolve = false,
                }
                return events
            end
        end
    end

    return events
end

-- =========================================================================
-- Internal: momentum-aware chance modifier
-- =========================================================================

--- Get a chance boost based on ascending momentum in a relevant category.
--- Returns 0.0 (no boost) to 0.15 (strong ascending momentum).
---@param context table with momentum field
---@param category_hint string|nil "physical", "mental", "social", "creative"
---@return number bonus (0.0 to 0.15)
function EventEngine._momentum_chance_boost(context, category_hint)
    if not context.momentum or not category_hint then return 0 end
    local entry = context.momentum[category_hint]
    if not entry then return 0 end
    if entry.direction == "rising" and entry.streak >= 3 then
        return math.min(0.15, entry.streak * 0.03)
    end
    return 0
end

--- Map a trait prefix or event theme to a category.
---@param hint string|nil
---@return string|nil
function EventEngine._guess_category(hint)
    if not hint then return nil end
    local map = {
        PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative",
        physical = "physical", mental = "mental", social = "social", creative = "creative",
        war = "physical", plague = "physical", famine = "physical",
        diplomatic = "social", faith = "mental", trade = "social",
    }
    return map[hint] or nil
end

-- Internal helpers

function EventEngine:_build_vars(context, tmpl)
    local vars = {
        heir_name = context.heir_name or "the heir",
        era_name = context.world_state and context.world_state:get_era_name() or "this age",
        generation = context.generation or 0,
        reputation_primary = context.cultural_memory and context.cultural_memory.reputation.primary or "unknown",
        reputation_secondary = context.cultural_memory and context.cultural_memory.reputation.secondary or "unknown",
        lineage_name = context.lineage_name or "the bloodline",
        realm = context.world_state and context.world_state.get_world_name and context.world_state:get_world_name() or "Caldemyr",
    }

    -- Religion variables
    local religion = context.religion
    if religion and religion.active then
        local ok_rmod, ReligionMod2 = pcall(require, "dredwork_world.religion")
        vars.religion_name = ok_rmod and ReligionMod2.display_name(religion.name) or (religion.name or "the faith")
        vars.zealotry_label = religion.zealotry >= 75 and "fervent"
            or religion.zealotry >= 50 and "strong"
            or religion.zealotry >= 25 and "moderate"
            or "weak"
        if religion.tenets and #religion.tenets > 0 then
            vars.tenet_1 = religion.tenets[1].label or ""
            vars.tenet_1_category = religion.tenets[1].category or ""
            if religion.tenets[2] then
                vars.tenet_2 = religion.tenets[2].label or ""
            end
        end
    else
        vars.religion_name = "no faith"
        vars.zealotry_label = "absent"
    end

    -- Culture variables
    local culture = context.culture
    if culture then
        if culture.values and #culture.values > 0 then
            vars.culture_value_1 = culture.values[1] or ""
            vars.culture_value_2 = culture.values[2] or ""
            vars.culture_value_3 = culture.values[3] or ""
        end
        vars.culture_rigidity = culture.rigidity and (
            culture.rigidity >= 60 and "entrenched"
            or culture.rigidity >= 30 and "stable"
            or "malleable"
        ) or "unknown"
        if culture.customs and #culture.customs > 0 then
            vars.culture_custom = culture.customs[1].label or ""
        end
    end

    -- War target variables
    if context.world_state then
        local war_meta = context.world_state:get_condition_metadata("war")
        if war_meta then
            vars.war_target_name = war_meta.target_faction_name or "the enemy"
        else
            vars.war_target_name = "the enemy"
        end
    else
        vars.war_target_name = "the enemy"
    end

    -- Bloodline dream variables
    local dream = context.bloodline_dream
    if dream and dream.status == "active" then
        vars.dream_trait = dream.trait_name or ""
        vars.dream_category = dream.category or ""
        vars.dream_gens_remaining = dream.deadline_generation - (context.generation or 0)
    end

    -- Active doctrines
    if context.doctrines and #context.doctrines > 0 then
        vars.doctrine_name = context.doctrines[1].title or ""
        vars.doctrine_count = #context.doctrines
    end

    -- Active discoveries
    if context.discoveries and context.discoveries.unlocked then
        local disc_names = {}
        for disc_id, _ in pairs(context.discoveries.unlocked) do
            disc_names[#disc_names + 1] = disc_id:gsub("_", " ")
        end
        vars.discovery_count = #disc_names
        if #disc_names > 0 then
            vars.discovery_name = disc_names[1]
        end
    end

    -- Active rumors (sample up to 2 for narrative flavor)
    if context.rumors and context.rumors.get_active then
        pcall(function()
            local active = context.rumors:get_active(context.generation or 0)
            if active and #active > 0 then
                vars.rumor_1 = active[1].text or ""
                vars.rumor_count = #active
                if #active > 1 then
                    vars.rumor_2 = active[2].text or ""
                end
            end
        end)
    end

    -- Wealth vars
    pcall(function()
        if context.wealth then
            local Wealth = require("dredwork_world.wealth")
            local tier = Wealth.get_tier(context.wealth)
            vars.wealth_tier = tier.label or "Modest"
            vars.wealth_value = math.floor(context.wealth.value or 50)
        else
            vars.wealth_tier = "Modest"
            vars.wealth_value = 50
        end
    end)

    -- Morality vars
    pcall(function()
        if context.morality then
            local MoralityMod = require("dredwork_world.morality")
            local standing = MoralityMod.get_standing(context.morality)
            vars.moral_standing = standing.label or "Pragmatic"
            vars.moral_score = math.floor(context.morality.score or 0)
        else
            vars.moral_standing = "Pragmatic"
            vars.moral_score = 0
        end
    end)

    -- Lineage power vars
    pcall(function()
        if context.lineage_power then
            local LP = require("dredwork_world.lineage_power")
            local tier = LP.get_tier(context.lineage_power)
            vars.lineage_power_tier = tier.label or "Established"
            vars.lineage_power = math.floor(context.lineage_power.value or 45)
        else
            vars.lineage_power_tier = "Established"
            vars.lineage_power = 45
        end
    end)

    -- World identity
    pcall(function()
        local world_id = require("dredwork_world.config.world_identity")
        vars.world_name = world_id.world_name or "the world"
    end)

    -- Court variables (siblings, spouses)
    if context.court then
        for _, mem in ipairs(context.court.members) do
            if mem.role == "sibling" and not vars.sibling_name then
                vars.sibling_name = mem.name
            elseif mem.role == "spouse" and not vars.spouse_name then
                vars.spouse_name = mem.name
            end
        end
    end
    -- Fallbacks
    vars.sibling_name = vars.sibling_name or "your sibling"
    vars.spouse_name = vars.spouse_name or "your spouse"

    -- War target variables (from condition metadata)
    pcall(function()
        if context.world_state then
            local war_meta = context.world_state:get_condition_metadata("war")
            if war_meta and war_meta.target_faction_name then
                vars.war_target_name = war_meta.target_faction_name
            end
        end
    end)
    vars.war_target_name = vars.war_target_name or "the enemy"

    return vars
end

function EventEngine:_prepare_options(template_options, context, vars)
    if not template_options then return {} end

    local all_options = {}
    local has_available = false
    for _, opt_tmpl in ipairs(template_options) do
        local avail = true
        local gated_reason = nil

        -- Combined personality, resource, and world condition gate
        avail = EventEngine.option_available(opt_tmpl, context)
        if not avail then
            if opt_tmpl.requires then
                gated_reason = EventEngine.get_gate_reason(opt_tmpl.requires)
            elseif opt_tmpl.requires_resources then
                gated_reason = "The bloodline lacks the " .. opt_tmpl.requires_resources.type .. " for this..."
            elseif opt_tmpl.requires_no_condition then
                gated_reason = "The " .. opt_tmpl.requires_no_condition:upper() .. " makes this impossible..."
            elseif opt_tmpl.requires_condition then
                gated_reason = "This requires " .. opt_tmpl.requires_condition:upper() .. " to be active..."
            else
                gated_reason = "This path is currently barred."
            end
        end

        -- Discovery gate: option requires a specific discovery to be unlocked
        if avail and opt_tmpl.requires_discovery then
            local has_disc = false
            if context.discoveries and context.discoveries.unlocked then
                has_disc = context.discoveries.unlocked[opt_tmpl.requires_discovery] ~= nil
            end
            if not has_disc then
                avail = false
                gated_reason = "A discovery is needed to unlock this path..."
            end
        end

        -- Doctrine gate: option requires a specific doctrine to be adopted
        if avail and opt_tmpl.requires_doctrine then
            local has_doc = false
            if context.doctrines then
                for _, doc in ipairs(context.doctrines) do
                    if doc.id == opt_tmpl.requires_doctrine then
                        has_doc = true
                        break
                    end
                end
            end
            if not has_doc then
                avail = false
                gated_reason = "A doctrine of the bloodline is needed..."
            end
        end

        -- Wealth gate: option requires minimum or maximum wealth
        if avail and opt_tmpl.requires_wealth_min then
            if not context.wealth or (context.wealth.value or 50) < opt_tmpl.requires_wealth_min then
                avail = false
                gated_reason = "The bloodline lacks the wealth for this path."
            end
        end
        if avail and opt_tmpl.requires_wealth_max then
            if context.wealth and (context.wealth.value or 50) > opt_tmpl.requires_wealth_max then
                avail = false
                gated_reason = "The bloodline is too wealthy for this desperation."
            end
        end

        -- Lineage power gate: option requires minimum or maximum power
        if avail and opt_tmpl.requires_lineage_power_min then
            local power_val = context.lineage_power and context.lineage_power.value or 45
            if power_val < opt_tmpl.requires_lineage_power_min then
                avail = false
                gated_reason = "Your house lacks the authority to command this."
            end
        end
        if avail and opt_tmpl.requires_lineage_power_max then
            local power_val = context.lineage_power and context.lineage_power.value or 45
            if power_val > opt_tmpl.requires_lineage_power_max then
                avail = false
                gated_reason = "Your house is too powerful for such desperation."
            end
        end

        if avail then has_available = true end
        all_options[#all_options + 1] = {
            label = EventEngine.substitute(opt_tmpl.label, vars),
            description = EventEngine.substitute(opt_tmpl.description or "", vars),
            consequences = opt_tmpl.consequences,
            requires = opt_tmpl.requires,
            requires_discovery = opt_tmpl.requires_discovery,
            requires_doctrine = opt_tmpl.requires_doctrine,
            requires_wealth_min = opt_tmpl.requires_wealth_min,
            requires_wealth_max = opt_tmpl.requires_wealth_max,
            requires_lineage_power_min = opt_tmpl.requires_lineage_power_min,
            requires_lineage_power_max = opt_tmpl.requires_lineage_power_max,
            available = avail,
            gated_reason = gated_reason,
        }
    end
    -- If no option is available, add a fallback so the event still fires
    -- (player sees what they couldn't do + takes a minor penalty for powerlessness)
    if not has_available and #all_options > 0 then
        all_options[#all_options + 1] = {
            label = "Accept Your Fate",
            description = "The bloodline lacks the means to act. History moves without you.",
            consequences = {
                lineage_power = -3,
            },
            available = true,
        }
    end
    if not has_available and #all_options == 0 then return {} end
    return all_options
end

function EventEngine:_pick_faction(context)
    if not context.factions then return nil end
    local active = context.factions:get_active()
    if #active == 0 then return nil end
    return active[rng.range(1, #active)].id
end

-- =========================================================================
-- Living world dynamic events: fossils, echoes, bloodline dream
-- =========================================================================

--- Inject dynamic events from living world systems (trait fossils, ancestor echoes).
--- These are not template-based — they're generated from current game state.
---@param events table array to append to (mutated in-place)
---@param context table full context from build_context
function EventEngine:_inject_living_world_events(events, context)
    local vars = self:_build_vars(context, {})

    -- Trait fossil event: when a once-great trait has decayed, offer a restoration path
    pcall(function()
        local ok_tf, TraitFossils = pcall(require, "dredwork_world.trait_fossils")
        if ok_tf and TraitFossils and context.trait_peaks and context.heir_genome then
            local fossils = TraitFossils.detect(context.trait_peaks, context.heir_genome)
            if #fossils > 0 and rng.chance(0.25) then
                local fossil = fossils[1]  -- most dramatic gap
                local narrative_text = TraitFossils.get_narrative(fossil)
                local fossil_event = {
                    type = "legacy",
                    id = "_fossil_" .. fossil.trait_id,
                    title = "Echoes of Lost Greatness",
                    narrative = narrative_text ..
                        " " .. fossil.peak_heir .. " once held " .. fossil.trait_name ..
                        " at " .. fossil.peak_value .. ". Now it stands at " .. fossil.current_value .. ".",
                    options = {
                        {
                            label = "Breed to restore what was lost",
                            description = "Focus the bloodline's matchmaking on reclaiming " .. fossil.trait_name .. ".",
                            available = true,
                            consequences = {
                                narrative = "The blood reaches back, grasping for what the ancestors once held.",
                                cultural_memory_shift = { [EventEngine._guess_category(fossil.trait_id:sub(1, 3)) or "physical"] = 3 },
                                offspring_boost = { trait = fossil.trait_id, bonus = 8 },
                            },
                        },
                        {
                            label = "Let the past stay buried",
                            description = "The bloodline has moved beyond " .. fossil.trait_name .. ". Accept the loss.",
                            available = true,
                            consequences = {
                                narrative = "Some greatness is not meant to be reclaimed. The bloodline presses forward.",
                            },
                        },
                        {
                            label = "Channel the memory into something new",
                            description = "Use the echo of past greatness to fuel a different fire.",
                            requires = { axis = "PER_ADA", min = 55 },
                            available = true,
                            consequences = {
                                narrative = "The ancestor's gift transforms. What was " .. fossil.trait_name .. " becomes something else entirely.",
                                mutation_triggers = { { type = "fossil_redirect", intensity = 0.5 } },
                            },
                        },
                    },
                    auto_resolve = false,
                }
                -- Apply personality gating
                fossil_event.options = self:_prepare_options(fossil_event.options, context, vars)
                if #fossil_event.options > 0 then
                    events[#events + 1] = fossil_event
                end
            end
        end
    end)

    -- Ancestor echo event: when the current heir mirrors a past ancestor
    pcall(function()
        local ok_ech, Echoes = pcall(require, "dredwork_world.echoes")
        if ok_ech and Echoes and context.ancestor_snapshots and context.heir_genome then
            local eligible = Echoes.filter_eligible(context.ancestor_snapshots, context.generation or 0)
            if #eligible > 0 then
                local echo = Echoes.detect(context.heir_genome, eligible, 5)
                if echo and rng.chance(0.30) then
                    -- Resolve {heir_name} placeholder in echo narrative
                    local echo_narr = (echo.narrative or ""):gsub("{heir_name}", vars.heir_name or "the heir")
                    local echo_event = {
                        type = "personal",
                        id = "_echo_" .. echo.ancestor_generation,
                        title = "The Blood Remembers",
                        narrative = echo_narr ..
                            " " .. echo.overlap_count .. " traits burn with the same intensity.",
                        auto_resolve = true,
                        auto_consequence = {
                            narrative = vars.heir_name .. " walks in the footsteps of " ..
                                echo.ancestor_name .. ". The bloodline resonates.",
                            cultural_memory_shift = { physical = 1, mental = 1, social = 1, creative = 1 },
                        },
                    }
                    events[#events + 1] = echo_event
                end
            end
        end
    end)

    -- Active Pantheon (Devil's Bargains): Gods intervene during active conditions
    pcall(function()
        if context.world_state and context.world_state.conditions and #context.world_state.conditions > 0 then
            if context.religion and context.religion.active and context.religion.pantheon and #context.religion.pantheon > 0 then
                -- 20% chance per crisis to get a bargain
                if rng.chance(0.2) then
                    -- Check all active conditions for a matching god
                    local condition, god
                    for _, cond in ipairs(context.world_state.conditions) do
                        for _, g in ipairs(context.religion.pantheon) do
                            if (cond.type == "plague" and g.domain == "rot")
                                or (cond.type == "war" and (g.domain == "war" or g.domain == "iron")) then
                                condition = cond
                                god = g
                                break
                            end
                        end
                        if condition then break end
                    end
                    if not condition then
                        -- No matching god/condition pair; pick random for fallback
                        condition = context.world_state.conditions[rng.range(1, #context.world_state.conditions)]
                        god = context.religion.pantheon[rng.range(1, #context.religion.pantheon)]
                    end

                    if condition.type == "plague" and god.domain == "rot" then
                        local bargain_event = {
                            type = "world",
                            id = "_bargain_rot",
                            title = "The Whisper of Rot",
                            narrative = "The plague ravages the land. But in the fever-dreams of the sick, " .. god.heir_name .. ", the God of Rot, offers a terrible bargain: sacrifice a capable leader, and the sickness will pass over your bloodline.",
                            options = {
                                {
                                    label = "Offer a member of the Court to the rot",
                                    description = "A sacrifice of blood to save the whole.",
                                    requires = { axis = "PER_CRM", min = 60 },
                                    available = true,
                                    consequences = {
                                        narrative = "The sacrifice was made. The plague vanished overnight, leaving only ash where they stood.",
                                        remove_condition = "plague",
                                        trigger_court_sacrifice = true, -- we need to handle this in apply_consequences
                                        religion_action = "boost_zealotry",
                                    },
                                },
                                {
                                    label = "Reject the dark bargain",
                                    description = "We will survive the sickness on our own terms.",
                                    available = true,
                                    consequences = {
                                        narrative = "The God of Rot turns away, displeased. The plague thickens.",
                                        add_condition = { type = "plague", intensity = 0.8, duration = 3 },
                                    },
                                },
                            },
                        }
                        bargain_event.options = self:_prepare_options(bargain_event.options, context, vars)
                        if #bargain_event.options > 0 then events[#events + 1] = bargain_event end
                        
                    elseif condition.type == "war" and (god.domain == "war" or god.domain == "iron") then
                        local bargain_event = {
                            type = "world",
                            id = "_bargain_war",
                            title = "The Blade's Demand",
                            narrative = "The war grinds on. The God of Blades, " .. god.heir_name .. ", appears in the armory. 'Spill your own blood, and I will shatter their armies.'",
                            options = {
                                {
                                    label = "Accept the mutilation",
                                    description = "Permanently cripple the heir's vitality for immediate victory.",
                                    requires = { axis = "PER_VOL", min = 50 },
                                    available = true,
                                    consequences = {
                                        narrative = "The heir severed their own hand on the altar. The enemy forces routed in inexplicable terror the next morning.",
                                        remove_condition = "war",
                                        modify_genome = { trait = "PHY_VIT", delta = -30 },
                                        lineage_power_shift = 15,
                                    },
                                },
                                {
                                    label = "Refuse the god's demand",
                                    description = "We fight with the blood we have.",
                                    available = true,
                                    consequences = {
                                        narrative = "The God of Blades scoffs at your weakness. The war grows fiercer.",
                                        add_condition = { type = "war", intensity = 0.9, duration = 2 },
                                    },
                                },
                            },
                        }
                        bargain_event.options = self:_prepare_options(bargain_event.options, context, vars)
                        if #bargain_event.options > 0 then events[#events + 1] = bargain_event end
                    end
                end
            end
        end
    end)

    -- Bloodline dream urgency: when the dream deadline is near, inject a reminder event
    pcall(function()
        local dream = context.bloodline_dream
        if dream and dream.status == "active" then
            local remaining = dream.deadline_generation - (context.generation or 0)
            if remaining == 1 and rng.chance(0.6) then
                local ok_bd, BloodlineDream = pcall(require, "dredwork_world.bloodline_dream")
                if ok_bd and BloodlineDream then
                    local display_info = BloodlineDream.get_display(dream, context.heir_genome, context.generation)
                    local progress_pct = display_info and math.floor(display_info.progress_pct * 100) or 0
                    local dream_event = {
                        type = "legacy",
                        id = "_dream_urgency",
                        title = "The Dream Fades",
                        narrative = "The bloodline's dream of legendary " .. dream.trait_name ..
                            " is slipping away. Progress: " .. progress_pct ..
                            "%. One generation remains.",
                        options = {
                            {
                                label = "Dedicate everything to the dream",
                                description = "Focus all effort on achieving " .. dream.trait_name .. " before time runs out.",
                                available = true,
                                consequences = {
                                    narrative = "The bloodline strains toward its dream with desperate intensity.",
                                    offspring_boost = { trait = dream.trait_id, bonus = 12 },
                                    cultural_memory_shift = { [dream.category] = 2 },
                                },
                            },
                            {
                                label = "Accept that some dreams die",
                                description = "Release the dream. The bloodline will dream again.",
                                available = true,
                                consequences = {
                                    narrative = "The dream dissolves. But the blood stirs with something new.",
                                },
                            },
                        },
                        auto_resolve = false,
                    }
                    dream_event.options = self:_prepare_options(dream_event.options, context, vars)
                    if #dream_event.options > 0 then
                        events[#events + 1] = dream_event
                    end
                end
            end
        end
    end)
end

return EventEngine
