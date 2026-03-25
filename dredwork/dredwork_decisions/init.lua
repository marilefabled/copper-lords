-- dredwork Decisions — Module Entry
-- Personality-gated choices with heir resistance and consequence resolution.
-- Ported from Bloodweight's event_engine.lua, adapted for event bus.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Decisions = {}
Decisions.__index = Decisions

--- Personality contradiction map: consequence type → conflicting axis + direction.
local RESISTANCE_MAP = {
    cruel_act       = { axis = "PER_CRM", direction = "low",  threshold = 35 },
    merciful_act    = { axis = "PER_CRM", direction = "high", threshold = 70 },
    warfare         = { axis = "PER_BLD", direction = "low",  threshold = 35 },
    retreat         = { axis = "PER_BLD", direction = "high", threshold = 70 },
    diplomacy       = { axis = "PER_PRI", direction = "high", threshold = 70 },
    submission      = { axis = "PER_PRI", direction = "high", threshold = 65 },
    betrayal        = { axis = "PER_LOY", direction = "high", threshold = 65 },
    espionage       = { axis = "PER_LOY", direction = "high", threshold = 60 },
    reckless_act    = { axis = "PER_OBS", direction = "high", threshold = 70 },
    cautious_act    = { axis = "PER_VOL", direction = "high", threshold = 65 },
    traditional_act = { axis = "PER_ADA", direction = "high", threshold = 65 },
    radical_act     = { axis = "PER_ADA", direction = "low",  threshold = 35 },
}

function Decisions.init(engine)
    local self = setmetatable({}, Decisions)
    self.engine = engine

    engine.game_state.decisions = {
        pending = nil,          -- current decision awaiting player input
        history = {},           -- past decisions
        resistance_count = 0,   -- how many times heir resisted this generation
    }

    -- Respond to decision requests
    engine:on("REQUEST_DECISION", function(req)
        if req.decision then
            self:present(req.decision)
        end
    end)

    -- Monthly: auto-resolve stale decisions, then generate new ones
    engine:on("NEW_MONTH", function(clock)
        self:_auto_resolve_if_stale(self.engine.game_state, clock)
        self:tick_monthly(self.engine.game_state, clock)
    end)

    -- Generational: reset resistance count
    engine:on("ADVANCE_GENERATION", function(context)
        self.engine.game_state.decisions.resistance_count = 0
    end)

    --------------------------------------------------------------------------
    -- Event-Triggered Decisions (from specific module events)
    --------------------------------------------------------------------------

    -- Rival raid → respond?
    engine:on("RIVAL_ACTION", function(ctx)
        if not ctx or ctx.type ~= "rival_raid" then return end
        if self.engine.game_state.decisions.pending then return end
        if not RNG.chance(0.6) then return end

        self:present({
            id = "rival_raid_response_" .. (self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0),
            title = "Raiders at the Gates",
            narrative = string.format("%s has raided our lands. How do we respond?", ctx.house or "A rival"),
            source = "rivals",
            options = {
                { id = "retaliate", label = "Strike Back", description = "Launch a counter-raid.",
                  tags = { "warfare" }, requires = { axis = "PER_BLD", min = 40 },
                  consequences = {
                      { type = "wealth_change", delta = -100 },
                      { type = "military_change", delta = -20 },
                      { type = "narrative_inject", text = "The counter-raid is launched. Fire for fire." },
                  }},
                { id = "fortify", label = "Strengthen Defenses", description = "Build walls, not wars.",
                  tags = { "cautious_act" },
                  consequences = {
                      { type = "wealth_change", delta = -80 },
                      { type = "narrative_inject", text = "Fortifications rise. The next raid will find us ready." },
                  }},
                { id = "negotiate", label = "Send an Envoy", description = "Words before swords.",
                  tags = { "diplomacy" },
                  consequences = {
                      { type = "wealth_change", delta = -30 },
                      { type = "legitimacy_change", delta = -3 },
                      { type = "narrative_inject", text = "An envoy rides out under a white banner. Some call it wisdom. Others, cowardice." },
                  }},
            },
        })
    end)

    -- Rival demand for tribute → pay or refuse?
    engine:on("RIVAL_ACTION", function(ctx)
        if not ctx or ctx.type ~= "rival_demand" then return end
        if self.engine.game_state.decisions.pending then return end

        self:present({
            id = "tribute_demand_" .. (self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0),
            title = "Tribute Demanded",
            narrative = string.format("%s demands tribute to maintain the peace.", ctx.house or "A rival house"),
            source = "rivals",
            options = {
                { id = "pay", label = "Pay the Tribute", description = "Humiliating, but safe.",
                  tags = { "submission" },
                  consequences = {
                      { type = "wealth_change", delta = -(ctx.cost or 50) },
                      { type = "legitimacy_change", delta = -5 },
                      { type = "narrative_inject", text = "Gold changes hands. Peace is preserved — at a price." },
                  }},
                { id = "refuse", label = "Refuse", description = "Let them try.",
                  tags = { "warfare" }, requires = { axis = "PER_PRI", min = 40 },
                  consequences = {
                      { type = "legitimacy_change", delta = 5 },
                      { type = "narrative_inject", text = "The envoy is sent back empty-handed. War may follow." },
                  }},
            },
        })
    end)

    -- Court betrayal → how to respond?
    engine:on("COURT_BETRAYAL", function(ctx)
        if self.engine.game_state.decisions.pending then return end
        if not RNG.chance(0.5) then return end

        self:present({
            id = "betrayal_response_" .. (self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0),
            title = "The Traitor's Wake",
            narrative = string.format("%s has betrayed the house. The court is shaken.", ctx and ctx.member and ctx.member.name or "Someone"),
            source = "court",
            options = {
                { id = "purge_court", label = "Purge Suspected Sympathizers", description = "Root out anyone who might follow.",
                  tags = { "cruel_act" },
                  consequences = {
                      { type = "court_loyalty_shift", delta = -8 },
                      { type = "corruption_change", delta = -5 },
                      { type = "narrative_inject", text = "The purge is swift. Not all who are taken are guilty." },
                  }},
                { id = "rally", label = "Rally the Faithful", description = "Reward loyalty. Punish none.",
                  tags = { "merciful_act", "diplomacy" },
                  consequences = {
                      { type = "wealth_change", delta = -60 },
                      { type = "court_loyalty_shift", delta = 10 },
                      { type = "narrative_inject", text = "Gold and honors are bestowed on the loyal. Trust is rebuilt, coin by coin." },
                  }},
                { id = "hunt", label = "Hunt the Traitor", description = "Send agents after the defector.",
                  tags = { "espionage" }, requires = { axis = "PER_OBS", min = 45 },
                  consequences = {
                      { type = "wealth_change", delta = -40 },
                      { type = "legitimacy_change", delta = 3 },
                      { type = "narrative_inject", text = "Agents slip into the night. The traitor will be found." },
                  }},
            },
        })
    end)

    -- Peril strike → how to respond?
    engine:on("PERIL_STRIKE", function(ctx)
        if self.engine.game_state.decisions.pending then return end

        local is_disease = ctx and ctx.category == "disease"
        self:present({
            id = "peril_response_" .. (self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0),
            title = is_disease and "Plague at the Gates" or "Disaster Strikes",
            narrative = string.format("%s threatens the realm. What is your response?", ctx and ctx.label or "A disaster"),
            source = "peril",
            options = {
                { id = "quarantine", label = is_disease and "Enforce Quarantine" or "Evacuate the Area",
                  description = "Protect lives at economic cost.",
                  tags = { "cautious_act" },
                  consequences = {
                      { type = "wealth_change", delta = -120 },
                      { type = "legitimacy_change", delta = 5 },
                      { type = "narrative_inject", text = is_disease and "The quarantine is enforced. Commerce halts, but lives are saved." or "The evacuation begins. It is orderly, if costly." },
                  }},
                { id = "pray", label = "Call for Prayer and Fasting",
                  description = "Turn to faith for salvation.",
                  tags = { "traditional_act" },
                  consequences = {
                      { type = "culture_shift", axis = "CUL_FAI", delta = 5 },
                      { type = "narrative_inject", text = "The temples fill. Whether the gods listen, none can say." },
                  }},
                { id = "nothing", label = "Maintain Order, Do Nothing Special",
                  description = "The strong survive. Nature runs its course.",
                  tags = { "cruel_act" },
                  consequences = {
                      { type = "unrest_change", delta = 10 },
                      { type = "narrative_inject", text = "Life continues. For those who survive." },
                  }},
            },
        })
    end)

    -- Sacred animals dying → religious crisis
    engine:on("NEW_YEAR", function(clock)
        if self.engine.game_state.decisions.pending then return end
        local gs = self.engine.game_state
        local req_rel = { sacred_species = nil, zeal = 50 }
        engine:emit("GET_RELIGION_DATA", req_rel)
        if not req_rel.sacred_species then return end
        if not gs.animals or not gs.animals.regional_populations then return end

        local total = 0
        for _, pops in pairs(gs.animals.regional_populations) do
            if pops[req_rel.sacred_species] then
                total = total + (pops[req_rel.sacred_species].density or 0)
            end
        end

        if total < 10 and req_rel.zeal > 40 and RNG.chance(0.3) then
            self:present({
                id = "sacred_crisis_" .. clock.total_days,
                title = "The Sacred Vanish",
                narrative = string.format("The sacred %s are nearly gone. The faithful demand action.", req_rel.sacred_species),
                source = "religion",
                options = {
                    { id = "protect", label = "Ban Hunting, Protect Habitat",
                      description = "Save the sacred creatures at any cost.",
                      tags = { "traditional_act" },
                      consequences = {
                          { type = "wealth_change", delta = -80 },
                          { type = "culture_shift", axis = "CUL_FAI", delta = 5 },
                          { type = "narrative_inject", text = "Hunting is forbidden. The sacred species are placed under protection." },
                      }},
                    { id = "pragmatic", label = "The Species Will Recover on Its Own",
                      description = "Nature finds a way.",
                      tags = { "radical_act" },
                      consequences = {
                          { type = "culture_shift", axis = "CUL_FAI", delta = -5 },
                          { type = "unrest_change", delta = 8 },
                          { type = "narrative_inject", text = "The pragmatic approach angers the faithful, but saves gold." },
                      }},
                },
            })
        end
    end)

    -- Succession contested → which heir?
    engine:on("SUCCESSION_CONTESTED", function(ctx)
        if not ctx or not ctx.candidates or #ctx.candidates < 2 then return end
        local c1 = ctx.candidates[1].person
        local c2 = ctx.candidates[2].person

        self:present({
            id = "succession_choice_" .. (self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0),
            title = "The Succession",
            narrative = string.format("Two claim the seat: %s and %s. The realm waits.", c1.name or "the eldest", c2.name or "the challenger"),
            source = "mortality",
            options = {
                { id = "eldest", label = c1.name or "The Eldest",
                  description = "Tradition favors the firstborn.",
                  tags = { "traditional_act" },
                  consequences = {
                      { type = "culture_shift", axis = "CUL_HIE", delta = 3 },
                      { type = "narrative_inject", text = (c1.name or "The eldest") .. " takes the seat. Tradition holds." },
                  }},
                { id = "challenger", label = c2.name or "The Challenger",
                  description = "Merit over birthright.",
                  tags = { "radical_act" },
                  consequences = {
                      { type = "culture_shift", axis = "CUL_HIE", delta = -3 },
                      { type = "unrest_change", delta = 5 },
                      { type = "narrative_inject", text = (c2.name or "The challenger") .. " rises. The old order is shaken." },
                  }},
            },
        })
    end)

    return self
end

--------------------------------------------------------------------------------
-- Decision Structure
--------------------------------------------------------------------------------

--[[
A decision looks like:
{
    id = "famine_response",
    title = "The Hungry Masses",
    narrative = "The famine worsens. The people look to you for answers.",
    source = "economy",  -- which module triggered it
    options = {
        {
            id = "open_granaries",
            label = "Open the Granaries",
            description = "Feed the people at great cost.",
            requires = { axis = "PER_BLD", min = 30 },  -- personality gate (optional)
            tags = { "merciful_act" },  -- for heir resistance check
            consequences = {
                { type = "wealth_change", delta = -200 },
                { type = "legitimacy_change", delta = 15 },
                { type = "unrest_change", delta = -20 },
            },
        },
        {
            id = "ration_strictly",
            label = "Tighten Rationing",
            description = "Preserve resources. The weak will suffer.",
            tags = { "cruel_act" },
            consequences = {
                { type = "unrest_change", delta = 20 },
                { type = "legitimacy_change", delta = -5 },
            },
        },
    },
}
]]

--------------------------------------------------------------------------------
-- Option Availability (Personality Gating)
--------------------------------------------------------------------------------

--- Check if an option is available to the current heir.
---@param option table
---@param personality table { PER_BLD = n, ... }
---@return boolean available
---@return string|nil reason
function Decisions:check_option_available(option, personality)
    if not option.requires then return true, nil end

    local req = option.requires
    local axis = req.axis
    local value = personality and personality[axis] or 50

    if req.min and value < req.min then
        return false, string.format("Requires higher %s (need %d, have %d)", axis, req.min, value)
    end
    if req.max and value > req.max then
        return false, string.format("Requires lower %s (need below %d, have %d)", axis, req.max, value)
    end

    return true, nil
end

--------------------------------------------------------------------------------
-- Heir Resistance
--------------------------------------------------------------------------------

--- Check if the heir's personality resists a chosen option.
---@param option table decision option with tags
---@param personality table { PER_BLD = n, ... }
---@return boolean resists
---@return string|nil resistance_text
function Decisions:check_heir_resistance(option, personality)
    if not option.tags or not personality then return false, nil end

    local max_strength = 0
    local resist_axis = nil

    for _, tag in ipairs(option.tags) do
        local mapping = RESISTANCE_MAP[tag]
        if mapping then
            local val = personality[mapping.axis] or 50
            local strength = 0

            if mapping.direction == "low" then
                -- Resist if axis is LOW (e.g., kind heir resists cruel act)
                strength = (mapping.threshold - val) / mapping.threshold
            else
                -- Resist if axis is HIGH (e.g., loyal heir resists betrayal)
                strength = (val - mapping.threshold) / (100 - mapping.threshold)
            end

            if strength > max_strength then
                max_strength = strength
                resist_axis = mapping.axis
            end
        end
    end

    if max_strength > 0.3 then
        local axis_names = {
            PER_BLD = "boldness", PER_CRM = "mercy", PER_OBS = "caution",
            PER_LOY = "loyalty", PER_CUR = "curiosity", PER_VOL = "composure",
            PER_PRI = "pride", PER_ADA = "tradition",
        }
        local name = axis_names[resist_axis] or resist_axis
        return true, string.format("Your heir's %s rebels against this course of action.", name)
    end

    return false, nil
end

--------------------------------------------------------------------------------
-- Present a Decision
--------------------------------------------------------------------------------

--- Queue a decision for the player.
function Decisions:present(decision)
    local gs = self.engine.game_state
    decision.presented_day = gs.clock and gs.clock.total_days or 0
    gs.decisions.pending = decision

    self.engine:emit("DECISION_PRESENTED", decision)
    self.engine:push_ui_event("DECISION_PRESENTED", decision)
    self.engine.log:info("Decision: %s — %s", decision.id, decision.title)
end

--- Resolve a player's choice.
---@param option_id string which option was selected
---@return table { success, resisted, resistance_text, consequences_applied }
function Decisions:resolve(option_id)
    local gs = self.engine.game_state
    local decision = gs.decisions.pending
    if not decision then return { success = false } end

    -- Find the option
    local option = nil
    for _, opt in ipairs(decision.options) do
        if opt.id == option_id then option = opt; break end
    end
    if not option then return { success = false } end

    -- Check heir resistance
    local heir_personality = nil
    if gs.current_heir and gs.current_heir.traits then
        heir_personality = {}
        for id, t in pairs(gs.current_heir.traits) do
            heir_personality[id] = type(t) == "table" and t.value or t
        end
    end

    local resisted, resistance_text = self:check_heir_resistance(option, heir_personality)
    if resisted then
        gs.decisions.resistance_count = gs.decisions.resistance_count + 1
    end

    -- Apply consequences
    local applied = self:_apply_consequences(option.consequences or {}, gs)

    -- Record
    table.insert(gs.decisions.history, {
        day = gs.clock and gs.clock.total_days or 0,
        decision_id = decision.id,
        option_id = option_id,
        resisted = resisted,
    })

    -- Clear pending
    gs.decisions.pending = nil

    -- Emit resolution
    local result = {
        success = true,
        resisted = resisted,
        resistance_text = resistance_text,
        consequences_applied = applied,
        decision = decision,
        option = option,
    }
    self.engine:emit("DECISION_RESOLVED", result)
    self.engine:push_ui_event("DECISION_RESOLVED", result)

    return result
end

--------------------------------------------------------------------------------
-- Consequence Application (via event bus)
--------------------------------------------------------------------------------

function Decisions:_apply_consequences(consequences, gs)
    local applied = {}

    for _, c in ipairs(consequences) do
        local t = c.type

        if t == "wealth_change" then
            local econ = self.engine:get_module("economy")
            if econ then econ:change_wealth(c.delta or 0) end
            table.insert(applied, c)

        elseif t == "legitimacy_change" then
            self.engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = c.delta or 0 })
            table.insert(applied, c)

        elseif t == "unrest_change" then
            if gs.politics then
                gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) + (c.delta or 0), 0, 100)
            end
            table.insert(applied, c)

        elseif t == "disposition_change" then
            local rivals = self.engine:get_module("rivals")
            if rivals and c.house_id then
                rivals:change_disposition(c.house_id, c.delta or 0)
            end
            table.insert(applied, c)

        elseif t == "military_change" then
            if gs.military then
                gs.military.total_power = Math.clamp((gs.military.total_power or 0) + (c.delta or 0), 0, 9999)
            end
            table.insert(applied, c)

        elseif t == "corruption_change" then
            if gs.underworld then
                gs.underworld.global_corruption = Math.clamp((gs.underworld.global_corruption or 0) + (c.delta or 0), 0, 100)
            end
            table.insert(applied, c)

        elseif t == "culture_shift" then
            local culture = self.engine:get_module("culture")
            if culture and c.axis and c.delta then
                culture:shift(c.axis, c.delta)
            end
            table.insert(applied, c)

        elseif t == "trigger_peril" then
            local peril_mod = self.engine:get_module("peril")
            if peril_mod and c.peril_type then
                peril_mod:trigger(c.peril_type, c.region_id)
            end
            table.insert(applied, c)

        elseif t == "add_grudge" then
            local rivals = self.engine:get_module("rivals")
            if rivals and c.house_id then
                local house = rivals:get_house(c.house_id)
                if house then rivals:add_grudge(house, c.reason or "decision", c.intensity or 30) end
            end
            table.insert(applied, c)

        elseif t == "court_loyalty_shift" then
            if gs.court then
                for _, member in ipairs(gs.court.members) do
                    if member.status == "active" then
                        member.loyalty = Math.clamp(member.loyalty + (c.delta or 0), 0, 100)
                    end
                end
            end
            table.insert(applied, c)

        elseif t == "narrative_inject" then
            local narrative = self.engine:get_module("narrative")
            if narrative and c.text then
                narrative:inject(c.text, { display_hint = c.display_hint or "panel", priority = c.priority or 70 })
            end
            table.insert(applied, c)
        end
    end

    return applied
end

--------------------------------------------------------------------------------
-- Monthly Tick: Generate Contextual Decisions
--------------------------------------------------------------------------------

function Decisions:tick_monthly(gs, clock)
    -- Don't generate if one is already pending
    if gs.decisions.pending then return end

    -- Check for crisis conditions that should produce decisions
    -- Famine decision
    if gs.markets then
        for region_id, market in pairs(gs.markets) do
            if market.prices and market.prices.food and market.prices.food > 18 and RNG.chance(0.15) then
                self:present({
                    id = "famine_response_" .. clock.total_days,
                    title = "The Hungry Masses",
                    narrative = "Food prices have soared beyond reason. The people look to you for answers.",
                    source = "economy",
                    options = {
                        {
                            id = "open_granaries",
                            label = "Open the Granaries",
                            description = "Feed the people at great cost to the treasury.",
                            tags = { "merciful_act" },
                            consequences = {
                                { type = "wealth_change", delta = -150 },
                                { type = "legitimacy_change", delta = 10 },
                                { type = "unrest_change", delta = -15 },
                                { type = "narrative_inject", text = "The granaries are opened. The people eat, and they remember." },
                            },
                        },
                        {
                            id = "ration",
                            label = "Enforce Strict Rationing",
                            description = "Preserve what remains. Some will go hungry.",
                            tags = { "cruel_act" },
                            consequences = {
                                { type = "unrest_change", delta = 15 },
                                { type = "legitimacy_change", delta = -5 },
                                { type = "narrative_inject", text = "Rationing is enforced. The weak suffer in silence — for now." },
                            },
                        },
                        {
                            id = "raid_neighbors",
                            label = "Seize Food from Neighbors",
                            description = "Take what you need by force.",
                            requires = { axis = "PER_BLD", min = 50 },
                            tags = { "warfare", "cruel_act" },
                            consequences = {
                                { type = "unrest_change", delta = -10 },
                                { type = "disposition_change", house_id = nil, delta = -20 },
                                { type = "narrative_inject", text = "Raiders ride out under your banner. The neighbors will not forget this." },
                            },
                        },
                    },
                })
                return
            end
        end
    end

    -- Unrest decision
    if gs.politics and gs.politics.unrest > 60 and RNG.chance(0.10) then
        self:present({
            id = "unrest_response_" .. clock.total_days,
            title = "Rising Tensions",
            narrative = "The discontent can no longer be ignored. How do you respond?",
            source = "politics",
            options = {
                {
                    id = "reforms",
                    label = "Announce Reforms",
                    description = "Promise change. It may or may not come.",
                    tags = { "diplomacy" },
                    consequences = {
                        { type = "unrest_change", delta = -20 },
                        { type = "legitimacy_change", delta = 5 },
                        { type = "wealth_change", delta = -80 },
                        { type = "narrative_inject", text = "Reforms are promised. The people cautiously hope." },
                    },
                },
                {
                    id = "crack_down",
                    label = "Crack Down Hard",
                    description = "Crush dissent with force.",
                    tags = { "cruel_act", "warfare" },
                    consequences = {
                        { type = "unrest_change", delta = -30 },
                        { type = "legitimacy_change", delta = -10 },
                        { type = "court_loyalty_shift", delta = -5 },
                        { type = "narrative_inject", text = "The crackdown is swift and brutal. Order is restored — but at what cost?" },
                    },
                },
                {
                    id = "blame_rival",
                    label = "Blame a Rival House",
                    description = "Redirect the anger outward.",
                    tags = { "espionage" },
                    requires = { axis = "PER_OBS", min = 40 },
                    consequences = {
                        { type = "unrest_change", delta = -15 },
                        { type = "narrative_inject", text = "Whispers are planted. The people's fury finds a new target." },
                    },
                },
            },
        })
        return
    end

    -- Corruption decision
    if gs.underworld and gs.underworld.global_corruption > 40 and RNG.chance(0.08) then
        self:present({
            id = "corruption_response_" .. clock.total_days,
            title = "The Rot Within",
            narrative = "Corruption festers in the institutions. The treasury bleeds.",
            source = "crime",
            options = {
                {
                    id = "purge",
                    label = "Purge the Corrupt",
                    description = "Root out the guilty. Some may be innocent.",
                    tags = { "cruel_act" },
                    consequences = {
                        { type = "corruption_change", delta = -25 },
                        { type = "court_loyalty_shift", delta = -10 },
                        { type = "narrative_inject", text = "The purge begins. Not all who are taken are guilty, but the message is clear." },
                    },
                },
                {
                    id = "buy_loyalty",
                    label = "Buy Their Loyalty",
                    description = "Pay them more than they can steal.",
                    tags = { "diplomacy" },
                    consequences = {
                        { type = "wealth_change", delta = -200 },
                        { type = "corruption_change", delta = -15 },
                        { type = "court_loyalty_shift", delta = 5 },
                        { type = "narrative_inject", text = "Gold changes hands. The corrupt are now... invested in the system." },
                    },
                },
                {
                    id = "ignore",
                    label = "Look the Other Way",
                    description = "There are bigger problems.",
                    consequences = {
                        { type = "corruption_change", delta = 5 },
                        { type = "narrative_inject", text = "Nothing changes. The rot deepens." },
                    },
                },
            },
        })
        return
    end
end

--------------------------------------------------------------------------------
-- Auto-Resolve: Heir picks based on personality after decision sits too long
--------------------------------------------------------------------------------

function Decisions:_auto_resolve_if_stale(gs, clock)
    local pending = gs.decisions.pending
    if not pending then return end

    -- If the current heir IS the focal entity, DON'T auto-resolve — wait for player input
    local focal_id = gs.entities and gs.entities.focal_entity_id
    local heir = gs.current_heir
    if heir and heir.entity_id and focal_id and heir.entity_id == focal_id then
        -- Player's decision — don't auto-resolve, pause sim instead
        return
    end

    -- Auto-resolve after 15 days for non-focal entities
    local age = (clock.total_days or 0) - (pending.presented_day or 0)
    if age < 15 then return end

    if not heir then
        -- No heir, pick first available option
        if pending.options and #pending.options > 0 then
            self:resolve(pending.options[1].id)
        end
        return
    end

    -- Build personality map
    local personality = {}
    if heir.traits then
        for id, t in pairs(heir.traits) do
            personality[id] = type(t) == "table" and t.value or t
        end
    end
    if heir.personality then
        for id, v in pairs(heir.personality) do
            personality[id] = v
        end
    end

    -- Score each option based on personality alignment
    local best_option = nil
    local best_score = -999

    for _, option in ipairs(pending.options or {}) do
        -- Check availability
        local available = self:check_option_available(option, personality)
        if not available then goto continue end

        local score = 0

        -- Score by tag alignment with personality
        for _, tag in ipairs(option.tags or {}) do
            if tag == "warfare" then score = score + ((personality.PER_BLD or 50) - 50) * 0.5 end
            if tag == "retreat" then score = score + (50 - (personality.PER_BLD or 50)) * 0.5 end
            if tag == "cruel_act" then score = score + ((personality.PER_CRM or 50) - 50) * 0.5 end
            if tag == "merciful_act" then score = score + (50 - (personality.PER_CRM or 50)) * 0.5 end
            if tag == "diplomacy" then score = score + ((personality.PER_LOY or 50) - 30) * 0.3 end
            if tag == "espionage" then score = score + ((personality.PER_OBS or 50) - 40) * 0.4 end
            if tag == "cautious_act" then score = score + (50 - (personality.PER_VOL or 50)) * 0.4 end
            if tag == "reckless_act" then score = score + ((personality.PER_VOL or 50) - 50) * 0.4 end
            if tag == "traditional_act" then score = score + (50 - (personality.PER_ADA or 50)) * 0.3 end
            if tag == "radical_act" then score = score + ((personality.PER_ADA or 50) - 50) * 0.3 end
            if tag == "submission" then score = score + (50 - (personality.PER_PRI or 50)) * 0.4 end
        end

        -- Small random variance so it's not perfectly deterministic
        score = score + RNG.range(-5, 5)

        if score > best_score then
            best_score = score
            best_option = option
        end

        ::continue::
    end

    if best_option then
        self.engine.log:info("Decisions: %s auto-resolves '%s' → '%s'",
            heir.name or "Heir", pending.title or "?", best_option.label or "?")
        self:resolve(best_option.id)
    elseif pending.options and #pending.options > 0 then
        -- Fallback: pick first available
        self:resolve(pending.options[1].id)
    end
end

function Decisions:serialize() return self.engine.game_state.decisions end
function Decisions:deserialize(data) self.engine.game_state.decisions = data end

return Decisions
