-- dredwork Agency — Module Entry
-- Gives every entity with a personality component autonomous behavior.
-- Entities evaluate their world, set goals, and take actions.
-- The player's entity has agency overridden by player input.
-- Non-player entities act on their own — the world is alive.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local MemoryLib = require("dredwork_agency.memory")
local NeedsLib = require("dredwork_agency.needs")
local SecretsLib = require("dredwork_agency.secrets")
local PlansLib = require("dredwork_agency.plans")
local NegotiationLib = require("dredwork_agency.negotiation")

local Agency = {}
Agency.__index = Agency

--- Goal templates: what entities can want.
local GOAL_TEMPLATES = {
    -- Universal
    survive        = { id = "survive",        priority = 90, description = "Stay alive" },
    gain_power     = { id = "gain_power",     priority = 60, description = "Increase influence and resources" },
    protect_family = { id = "protect_family",  priority = 70, description = "Keep family members safe" },
    seek_comfort   = { id = "seek_comfort",    priority = 40, description = "Improve living conditions" },
    -- Social
    build_loyalty  = { id = "build_loyalty",   priority = 50, description = "Strengthen bonds with allies" },
    avenge_grudge  = { id = "avenge_grudge",   priority = 65, description = "Punish those who wronged us" },
    find_mate      = { id = "find_mate",       priority = 55, description = "Seek a partner" },
    -- Ambitious
    conquer        = { id = "conquer",         priority = 45, description = "Expand territory" },
    build_legacy   = { id = "build_legacy",    priority = 50, description = "Create something lasting" },
    seek_knowledge = { id = "seek_knowledge",  priority = 35, description = "Pursue learning and discovery" },
    -- Spiritual
    serve_faith    = { id = "serve_faith",     priority = 40, description = "Advance religious goals" },
    -- Criminal
    accumulate     = { id = "accumulate",      priority = 55, description = "Hoard wealth" },
    undermine      = { id = "undermine",       priority = 45, description = "Weaken rivals from the shadows" },
    -- Animal
    follow_owner   = { id = "follow_owner",    priority = 80, description = "Stay near owner" },
    hunt           = { id = "hunt",            priority = 60, description = "Find prey" },
    guard          = { id = "guard",           priority = 70, description = "Protect territory or owner" },
}

--- Action templates: what entities can do.
local ACTION_TEMPLATES = {
    -- Economic
    earn_gold       = { id = "earn_gold",       goals = {"gain_power", "seek_comfort", "accumulate"}, tags = {} },
    spend_gold      = { id = "spend_gold",      goals = {"seek_comfort", "build_legacy"}, tags = {} },
    trade           = { id = "trade",           goals = {"gain_power", "accumulate"}, tags = {} },
    -- Social
    visit_ally      = { id = "visit_ally",      goals = {"build_loyalty", "protect_family"}, tags = {"diplomacy"} },
    gift            = { id = "gift",            goals = {"build_loyalty"}, tags = {"diplomacy"} },
    scheme          = { id = "scheme",          goals = {"gain_power", "undermine", "avenge_grudge"}, tags = {"espionage"} },
    propose_marriage= { id = "propose_marriage",goals = {"find_mate", "build_loyalty"}, tags = {"diplomacy"} },
    -- Military
    train_troops    = { id = "train_troops",    goals = {"gain_power", "survive"}, tags = {"warfare"} },
    raid            = { id = "raid",            goals = {"gain_power", "avenge_grudge", "conquer"}, tags = {"warfare", "cruel_act"} },
    fortify         = { id = "fortify",         goals = {"survive", "protect_family"}, tags = {"cautious_act"} },
    -- Cultural
    build_monument  = { id = "build_monument",  goals = {"build_legacy"}, tags = {"traditional_act"} },
    research        = { id = "research",        goals = {"seek_knowledge"}, tags = {} },
    pray            = { id = "pray",            goals = {"serve_faith"}, tags = {"traditional_act"} },
    -- Criminal
    extort          = { id = "extort",          goals = {"accumulate", "gain_power"}, tags = {"cruel_act", "espionage"} },
    bribe           = { id = "bribe",           goals = {"undermine", "gain_power"}, tags = {"espionage"} },
    -- Animal
    patrol          = { id = "patrol",          goals = {"guard", "follow_owner"}, tags = {} },
    hunt_prey       = { id = "hunt_prey",       goals = {"hunt", "survive"}, tags = {} },
    rest            = { id = "rest",            goals = {"survive", "seek_comfort"}, tags = {} },
    -- Passive
    idle            = { id = "idle",            goals = {"survive"}, tags = {} },
}

function Agency.init(engine)
    local self = setmetatable({}, Agency)
    self.engine = engine

    -- Monthly: all non-focal entities evaluate and act
    engine:on("NEW_MONTH", function(clock)
        self:tick_all(self.engine.game_state, clock)
    end)

    --------------------------------------------------------------------------
    -- Event-Reactive Agency: entities respond to events in real-time
    --------------------------------------------------------------------------

    -- Entities witness betrayals and adjust memory
    engine:on("COURT_BETRAYAL", function(ctx)
        self:_witness_event("betrayal", ctx and ctx.member and ctx.member.name, ctx)
    end)

    -- Entities witness deaths
    engine:on("COURT_DEATH", function(ctx)
        self:_witness_event("death", ctx and ctx.member and ctx.member.name, ctx)
    end)

    -- Entities witness rival actions
    engine:on("RIVAL_ACTION", function(ctx)
        self:_witness_event("rival_action", ctx and ctx.house, ctx)
    end)

    -- Entities witness heir death
    engine:on("HEIR_DIED", function(ctx)
        self:_witness_event("heir_death", ctx and ctx.heir_name, ctx)
    end)

    -- Entities react to peril
    engine:on("PERIL_STRIKE", function(ctx)
        self:_react_to_danger(ctx)
    end)

    return self
end

--- Broadcast an event to all entities at the same location as the focal entity.
function Agency:_witness_event(event_type, subject_name, ctx)
    local entities = self.engine:get_module("entities")
    if not entities then return end
    local gs = self.engine.game_state
    local day = gs.clock and gs.clock.total_days or 0

    for _, entity in pairs(gs.entities.registry) do
        if not entity.alive or not entity.components.memory then goto continue end

        -- Initialize memory if needed
        if not entity.components.memory.events then
            entity.components.memory = MemoryLib.create()
        end

        MemoryLib.witness(entity.components.memory, day, event_type, {
            subject = subject_name,
            text = ctx and ctx.text,
        })

        -- Betrayal: entities who are loyal develop grudges against betrayers
        if event_type == "betrayal" and ctx and ctx.member then
            local p = entity.components.personality or {}
            local loy = p.PER_LOY or 50
            if type(loy) == "table" then loy = loy.value or 50 end
            if loy > 60 then
                MemoryLib.add_grudge(entity.components.memory, ctx.member.entity_id or ctx.member.id, "betrayed the house", 20)
            end
        end

        ::continue::
    end
end

--- Entities react to danger by shifting needs.
function Agency:_react_to_danger(ctx)
    local entities = self.engine:get_module("entities")
    if not entities then return end

    for _, entity in pairs(self.engine.game_state.entities.registry) do
        if not entity.alive or not entity.components.needs then goto continue end
        entity.components.needs.safety = Math.clamp(entity.components.needs.safety - 10, 0, 100)
        ::continue::
    end
end

--------------------------------------------------------------------------------
-- Goal Assignment (based on personality + context)
--------------------------------------------------------------------------------

--- Assign goals to an entity based on its personality and type.
function Agency:assign_goals(entity)
    local goals = {}
    local p = entity.components.personality or {}

    -- Universal goals
    table.insert(goals, { id = "survive", priority = 90 })

    if entity.type == "person" then
        table.insert(goals, { id = "protect_family", priority = 70 })

        -- Personality-driven goals
        local bld = p.PER_BLD or 50
        local crm = p.PER_CRM or 50
        local obs = p.PER_OBS or 50
        local loy = p.PER_LOY or 50
        local cur = p.PER_CUR or 50
        local pri = p.PER_PRI or 50

        if bld > 65 then table.insert(goals, { id = "conquer", priority = 55 + (bld - 65) }) end
        if bld < 35 then table.insert(goals, { id = "seek_comfort", priority = 60 }) end
        if crm > 65 then table.insert(goals, { id = "accumulate", priority = 55 }); table.insert(goals, { id = "undermine", priority = 45 }) end
        if obs > 65 then table.insert(goals, { id = "seek_knowledge", priority = 50 }) end
        if loy > 65 then table.insert(goals, { id = "build_loyalty", priority = 60 }) end
        if cur > 65 then table.insert(goals, { id = "seek_knowledge", priority = 55 }) end
        if pri > 65 then table.insert(goals, { id = "build_legacy", priority = 55 }); table.insert(goals, { id = "gain_power", priority = 60 }) end

        -- Context-driven goals
        local entities = self.engine:get_module("entities")
        if entities then
            local rels = entities:get_relationships(entity.id)
            local has_mate = false
            for _, rel in ipairs(rels) do
                if rel.type == "spouse" then has_mate = true end
                if rel.type == "grudge" then
                    table.insert(goals, { id = "avenge_grudge", priority = 65, target = rel.a == entity.id and rel.b or rel.a })
                end
            end
            if not has_mate and (entity.components.mortality and (entity.components.mortality.age or 0) >= 18) then
                table.insert(goals, { id = "find_mate", priority = 50 })
            end
        end

    elseif entity.type == "animal" then
        table.insert(goals, { id = "follow_owner", priority = 80 })
        table.insert(goals, { id = "guard", priority = 70 })
        if (p.PER_BLD or 50) > 50 then
            table.insert(goals, { id = "hunt", priority = 60 })
        end
    end

    -- Sort by priority (highest first)
    table.sort(goals, function(a, b) return a.priority > b.priority end)

    entity.components.agenda = entity.components.agenda or {}
    entity.components.agenda.goals = goals
    return goals
end

--------------------------------------------------------------------------------
-- Action Selection (personality-driven)
--------------------------------------------------------------------------------

--- Pick an action for an entity based on its goals and personality.
function Agency:select_action(entity)
    local agenda = entity.components.agenda
    if not agenda or not agenda.goals or #agenda.goals == 0 then
        return ACTION_TEMPLATES.idle
    end

    local p = entity.components.personality or {}

    -- Find actions that serve the highest-priority unsatisfied goal
    local candidates = {}
    for _, goal in ipairs(agenda.goals) do
        for action_id, action_def in pairs(ACTION_TEMPLATES) do
            for _, serves_goal in ipairs(action_def.goals) do
                if serves_goal == goal.id then
                    local score = goal.priority

                    -- Personality alignment bonus
                    for _, tag in ipairs(action_def.tags) do
                        if tag == "warfare" then score = score + ((p.PER_BLD or 50) - 50) * 0.3 end
                        if tag == "diplomacy" then score = score + ((p.PER_LOY or 50) - 40) * 0.3 end
                        if tag == "espionage" then score = score + ((p.PER_OBS or 50) - 40) * 0.3 end
                        if tag == "cruel_act" then score = score + ((p.PER_CRM or 50) - 50) * 0.3 end
                        if tag == "traditional_act" then score = score + (50 - (p.PER_ADA or 50)) * 0.2 end
                        if tag == "cautious_act" then score = score + (50 - (p.PER_VOL or 50)) * 0.3 end
                    end

                    score = score + RNG.range(-5, 5) -- variance
                    table.insert(candidates, { action = action_def, score = score, goal = goal })
                    break
                end
            end
        end
        -- Only consider top 2 goals to keep it focused
        if #candidates >= 6 then break end
    end

    if #candidates == 0 then return ACTION_TEMPLATES.idle end

    -- Pick the highest-scored action
    table.sort(candidates, function(a, b) return a.score > b.score end)
    return candidates[1].action
end

--------------------------------------------------------------------------------
-- Execution
--------------------------------------------------------------------------------

--- Execute an action for an entity (applies effects via event bus).
function Agency:execute_action(entity, action)
    local gs = self.engine.game_state
    local entities = self.engine:get_module("entities")
    if not entities then return end

    entity.components.agenda = entity.components.agenda or {}
    entity.components.agenda.current_action = action.id

    -- Action effects (simplified — each maps to existing module APIs)
    if action.id == "earn_gold" then
        -- Entity works: gain small gold
        local econ = self.engine:get_module("economy")
        if econ then econ:change_wealth(RNG.range(3, 10)) end

    elseif action.id == "scheme" then
        -- Intrigue: inject a rumor, shift relationships
        local rumor = self.engine:get_module("rumor")
        if rumor then
            rumor:inject(gs, {
                origin_type = "agency",
                subject = entity.name,
                text = entity.name .. " has been seen in private meetings. Something is afoot.",
                heat = RNG.range(30, 50),
                tags = { scandal = true },
            })
        end

    elseif action.id == "raid" then
        -- Aggressive action: triggers rival mechanics
        self.engine:emit("ENTITY_ACTION", {
            entity_id = entity.id, entity_name = entity.name,
            action = "raid", type = "aggressive",
            text = entity.name .. " launches a raid.",
        })

    elseif action.id == "fortify" then
        if gs.home and gs.home.attributes then
            gs.home.attributes.condition = Math.clamp((gs.home.attributes.condition or 50) + 2, 0, 100)
        end

    elseif action.id == "pray" then
        if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
            gs.religion.active_faith.attributes.zeal = Math.clamp(
                (gs.religion.active_faith.attributes.zeal or 50) + 0.5, 0, 100)
        end

    elseif action.id == "research" then
        local tech = self.engine:get_module("technology")
        if tech then
            local fields = {"industry","medicine","warfare","infrastructure","agriculture","navigation","metallurgy","theology","espionage","governance"}
            tech:boost_field(RNG.pick(fields), RNG.range(1, 3))
        end

    elseif action.id == "train_troops" then
        if gs.military then
            for _, unit in ipairs(gs.military.units or {}) do
                unit.readiness = Math.clamp((unit.readiness or 50) + 2, 0, 100)
            end
        end

    elseif action.id == "visit_ally" then
        -- Strengthen a relationship
        local rels = entities:get_relationships(entity.id, "loyalty")
        if #rels > 0 then
            local rel = RNG.pick(rels)
            entities:shift_relationship(rel.a, rel.b, "loyalty", RNG.range(1, 5))
        end

    elseif action.id == "gift" then
        local econ = self.engine:get_module("economy")
        if econ then econ:change_wealth(-RNG.range(5, 15)) end
        -- Boost a random relationship
        local rels = entities:get_relationships(entity.id)
        if #rels > 0 then
            local rel = RNG.pick(rels)
            entities:shift_relationship(rel.a, rel.b, rel.type, RNG.range(2, 8))
        end

    elseif action.id == "patrol" or action.id == "guard" then
        -- Animal guards: slight security boost
        if gs.home and gs.home.attributes then
            gs.home.attributes.comfort = Math.clamp((gs.home.attributes.comfort or 50) + 0.5, 0, 100)
        end

    elseif action.id == "hunt_prey" then
        -- Animal hunts: slight food bonus
        local econ = self.engine:get_module("economy")
        if econ then econ:change_wealth(RNG.range(1, 3)) end
    end

    -- Emit for narrative
    self.engine:emit("ENTITY_ACTION", {
        entity_id = entity.id,
        entity_name = entity.name,
        entity_type = entity.type,
        action = action.id,
        text = entity.name .. " " .. (GOAL_TEMPLATES[action.goals and action.goals[1]] and GOAL_TEMPLATES[action.goals[1]].description or "acts"),
    })
end

--------------------------------------------------------------------------------
-- Monthly Tick: All Entities Act
--------------------------------------------------------------------------------

function Agency:tick_all(gs, clock)
    local entities = self.engine:get_module("entities")
    if not entities then return end
    local day = clock and clock.total_days or 0
    local focal_id = gs.entities and gs.entities.focal_entity_id

    for _, entity in pairs(gs.entities.registry) do
        if not entity.alive then goto continue end
        if entity.id == focal_id then goto continue end
        if not entity.components.personality then goto continue end

        -- Initialize components if missing
        if not entity.components.memory then entity.components.memory = MemoryLib.create() end
        if not entity.components.needs then entity.components.needs = NeedsLib.create() end
        if not entity.components.secrets then entity.components.secrets = SecretsLib.create() end

        -- 1. Update needs from context
        local rel_count = #entities:get_relationships(entity.id)
        NeedsLib.update(entity.components.needs, {
            relationship_count = rel_count,
            is_at_war = gs.empire and gs.empire.territories and #gs.empire.territories > 0,
            has_peril = gs.perils and gs.perils.active and #gs.perils.active > 0,
            has_purpose = entity.components.agenda and entity.components.agenda.current_action ~= nil,
            home_comfort = gs.home and gs.home.attributes and gs.home.attributes.comfort,
            wealth = gs.resources and gs.resources.gold,
            unrest = gs.politics and gs.politics.unrest,
            legitimacy = gs.politics and gs.politics.legitimacy,
        })

        -- 2. Decay memory (grudges and debts fade)
        MemoryLib.decay(entity.components.memory)

        -- 3. Assign goals (boosted by unmet needs and grudges)
        self:assign_goals(entity)
        local need_boosts = NeedsLib.get_goal_boosts(entity.components.needs)
        if entity.components.agenda and entity.components.agenda.goals then
            for _, goal in ipairs(entity.components.agenda.goals) do
                goal.priority = goal.priority + (need_boosts[goal.id] or 0)
            end
            -- Grudge-driven goals
            local enemy, enemy_intensity = MemoryLib.get_worst_enemy(entity.components.memory)
            if enemy and enemy_intensity > 20 then
                for _, goal in ipairs(entity.components.agenda.goals) do
                    if goal.id == "avenge_grudge" then goal.priority = goal.priority + enemy_intensity * 0.3 end
                end
            end
            table.sort(entity.components.agenda.goals, function(a, b) return a.priority > b.priority end)
        end

        -- Probability gate
        local act_chance = entity.type == "person" and 0.5 or 0.2
        if not RNG.chance(act_chance) then goto continue end

        -- 4. Plans: continue existing plan or start new one
        local agenda = entity.components.agenda or {}
        local plan = agenda.active_plan
        local action_id = nil

        if plan and PlansLib.is_active(plan) then
            -- Continue existing plan
            local template = PlansLib.get_templates()[plan.template_id]
            if template then
                action_id = PlansLib.advance(plan, template)
            end
            if not action_id then plan = nil end
        end

        if not plan and entity.type == "person" and RNG.chance(0.3) then
            -- Start a new plan
            local template = PlansLib.select_plan(entity)
            if template then
                plan = PlansLib.create(template)
                plan.started_day = day
                agenda.active_plan = plan
                action_id = PlansLib.advance(plan, template)

                self.engine:emit("ENTITY_PLAN_STARTED", {
                    entity_id = entity.id, entity_name = entity.name,
                    plan = template.label,
                    text = entity.name .. " begins a plan: " .. template.label,
                })
            end
        end

        entity.components.agenda = agenda

        -- 5. Execute action (from plan or single selection)
        if action_id then
            local action = ACTION_TEMPLATES[action_id]
            if action then self:execute_action(entity, action) end
        else
            local action = self:select_action(entity)
            if action and action.id ~= "idle" then
                self:execute_action(entity, action)
            end
        end

        -- 6. Secret generation (rare: observant entities discover secrets)
        local obs = entity.components.personality.PER_OBS or 50
        if type(obs) == "table" then obs = obs.value or 50 end
        if obs > 60 and RNG.chance(0.05) then
            -- Discover a secret about a random related entity
            local related = entities:get_related(entity.id)
            if #related > 0 then
                local target = RNG.pick(related)
                if target and target.entity then
                    local secret_types = {"embezzlement", "affair", "ambition", "weakness", "conspiracy"}
                    local secret = SecretsLib.generate(target.entity, RNG.pick(secret_types), day)
                    SecretsLib.learn(entity.components.secrets, secret)
                end
            end
        end

        -- 7. Negotiation (rare: entities propose deals)
        if entity.type == "person" and RNG.chance(0.05) then
            local related = entities:get_related(entity.id)
            if #related > 0 then
                local target_rel = RNG.pick(related)
                if target_rel and target_rel.entity and target_rel.entity.alive then
                    local proposal_types = {"alliance", "trade", "support"}
                    local proposal = NegotiationLib.create_proposal(
                        entity.id, target_rel.entity.id, RNG.pick(proposal_types), {}, day)

                    local accepted, score, reason = NegotiationLib.evaluate(
                        target_rel.entity, entity, proposal)

                    if accepted then
                        proposal.status = "accepted"
                        -- Strengthen relationship
                        entities:shift_relationship(entity.id, target_rel.entity.id, target_rel.relationship.type, 5)
                        self.engine:emit("NEGOTIATION_ACCEPTED", {
                            proposer = entity.name, target = target_rel.entity.name,
                            type = proposal.type, score = score,
                            text = entity.name .. "'s proposal to " .. target_rel.entity.name .. " is accepted: " .. proposal.label,
                        })
                    else
                        proposal.status = "rejected"
                        if score < 20 then
                            -- Deep rejection may create grudge
                            if entity.components.memory then
                                MemoryLib.add_grudge(entity.components.memory, target_rel.entity.id, "rejected my " .. proposal.type, 10)
                            end
                        end
                    end
                end
            end
        end

        ::continue::
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Manually assign goals to an entity.
function Agency:set_goals(entity_id, goals)
    local entities = self.engine:get_module("entities")
    if not entities then return end
    local entity = entities:get(entity_id)
    if not entity then return end
    entity.components.agenda = entity.components.agenda or {}
    entity.components.agenda.goals = goals
end

--- Get the current action of an entity.
function Agency:get_current_action(entity_id)
    local entities = self.engine:get_module("entities")
    if not entities then return nil end
    local entity = entities:get(entity_id)
    if not entity or not entity.components.agenda then return nil end
    return entity.components.agenda.current_action
end

--- Get goal templates (for UI display).
function Agency.get_goal_templates()
    return GOAL_TEMPLATES
end

--- Get action templates (for UI display).
function Agency.get_action_templates()
    return ACTION_TEMPLATES
end

function Agency:serialize() return {} end -- agency is stateless; entity state is in entities module
function Agency:deserialize(data) end

return Agency
