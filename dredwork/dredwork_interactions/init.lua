-- dredwork Interactions — Module Entry
-- Defines what the player can DO. Every entity type combination has a defined set
-- of actions. Availability is contextual — you can only blackmail if you hold a secret.
-- This is the game mechanic layer between the player and the simulation.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Interactions = {}
Interactions.__index = Interactions

function Interactions.init(engine)
    local self = setmetatable({}, Interactions)
    self.engine = engine

    -- Respond to interaction queries
    engine:on("GET_INTERACTIONS", function(req)
        if req.actor_id and req.target_id then
            req.interactions = self:get_available(req.actor_id, req.target_id)
        elseif req.actor_id and req.target_type then
            req.interactions = self:get_self_actions(req.actor_id)
        end
    end)

    return self
end

--------------------------------------------------------------------------------
-- Interaction Definitions
-- Each interaction: { id, label, description, category,
--   requires(actor, target, engine) → bool,
--   execute(actor, target, engine) → result }
--------------------------------------------------------------------------------

local INTERACTIONS = {}

--------------------------------------------------------------------------------
-- PERSON → PERSON
--------------------------------------------------------------------------------

INTERACTIONS.person_person = {
    {
        id = "talk",
        label = "Talk",
        description = "Have a conversation.",
        category = "social",
        requires = function(actor, target, engine) return true end,
        execute = function(actor, target, engine)
            local dialogue = engine:get_module("dialogue")
            if dialogue then
                local Dialogue = require("dredwork_dialogue.logic")
                -- Build memory/context for richer dialogue
                local ctx = {}
                ctx.memory_line = Dialogue.get_memory_line(target, actor.id, engine.game_state)
                ctx.context_line = Dialogue.get_context_line(target, actor, engine.game_state)
                local exchange = Dialogue.generate_exchange(target, engine.game_state, ctx)
                return { success = true, text = exchange.greeting or "...", exchange = exchange }
            end
            return { success = true, text = target.name .. " acknowledges you." }
        end,
    },
    {
        id = "gift_item",
        label = "Give Gift",
        description = "Offer one of your possessions.",
        category = "social",
        requires = function(actor, target, engine)
            local inv = actor.components.inventory
            return inv and inv.items and #inv.items > 0
        end,
        execute = function(actor, target, engine)
            local inventory = engine:get_module("inventory")
            if not inventory then return { success = false } end
            local items = inventory:get_items(actor.id)
            if #items == 0 then return { success = false, text = "Nothing to give." } end
            -- Give first non-weapon item
            for _, item in ipairs(items) do
                if item.type ~= "weapon" then
                    inventory:transfer(actor.id, target.id, item.id)
                    return { success = true, text = "You give " .. item.name .. " to " .. target.name .. ".", item = item }
                end
            end
            return { success = false, text = "Nothing suitable to give." }
        end,
    },
    {
        id = "threaten",
        label = "Threaten",
        description = "Make your displeasure known.",
        category = "hostile",
        requires = function(actor, target, engine)
            local p = actor.components.personality or {}
            local bld = p.PER_BLD or 50
            if type(bld) == "table" then bld = bld.value or 50 end
            return bld >= 35
        end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then
                entities:shift_relationship(actor.id, target.id, "fear", 10)
                -- Target's loyalty drops
                if target.components.needs then
                    target.components.needs.safety = Math.clamp((target.components.needs.safety or 50) - 5, 0, 100)
                end
            end
            return { success = true, text = "You make your intentions clear. " .. target.name .. " flinches." }
        end,
    },
    {
        id = "propose_alliance",
        label = "Propose Alliance",
        description = "Suggest mutual benefit.",
        category = "diplomatic",
        requires = function(actor, target, engine) return true end,
        execute = function(actor, target, engine)
            local NegotiationLib = require("dredwork_agency.negotiation")
            local proposal = NegotiationLib.create_proposal(actor.id, target.id, "alliance", {}, engine.game_state.clock and engine.game_state.clock.total_days or 0)
            local accepted, score, reason = NegotiationLib.evaluate(target, actor, proposal)
            local entities = engine:get_module("entities")
            if accepted and entities then
                entities:shift_relationship(actor.id, target.id, "alliance", 15)
                engine:emit("NEGOTIATION_ACCEPTED", { proposer = actor.name, target = target.name, type = "alliance", text = target.name .. " accepts your alliance." })
            end
            return { success = accepted, text = accepted and (target.name .. " agrees. \"Together, then.\"") or (target.name .. " declines. \"" .. reason .. ".\""), score = score }
        end,
    },
    {
        id = "propose_marriage",
        label = "Propose Marriage",
        description = "Offer a union of houses.",
        category = "diplomatic",
        requires = function(actor, target, engine)
            -- Check neither is already married (simplified)
            return true
        end,
        execute = function(actor, target, engine)
            local marriage = engine:get_module("marriage")
            if not marriage then return { success = false } end
            local result = marriage:resolve_type({
                heir_personality = actor.components.personality or {},
                mate_personality = target.components.personality or {},
            })
            return { success = true, text = result.text or "A marriage is proposed.", marriage_result = result }
        end,
    },
    {
        id = "challenge_duel",
        label = "Challenge to Duel",
        description = "Settle this with steel.",
        category = "hostile",
        requires = function(actor, target, engine)
            local p = actor.components.personality or {}
            local bld = p.PER_BLD or 50
            if type(bld) == "table" then bld = bld.value or 50 end
            return bld >= 40
        end,
        execute = function(actor, target, engine)
            local duel = engine:get_module("duel")
            if not duel then return { success = false } end
            duel:start_duel(
                { name = actor.name, hp = 20, person = actor },
                { name = target.name, hp = 18, person = target },
                { cause = "challenge" }
            )
            local result = duel:auto_fight()
            return { success = true, text = result and (result.winner == "a" and "You are victorious." or "You are defeated.") or "The duel is fought.", duel_result = result }
        end,
    },
    {
        id = "blackmail",
        label = "Blackmail",
        description = "Use what you know against them.",
        category = "hostile",
        requires = function(actor, target, engine)
            local secrets = actor.components.secrets
            if not secrets then return false end
            local SecretsLib = require("dredwork_agency.secrets")
            local has, _ = SecretsLib.knows_about(secrets, target.id)
            return has
        end,
        execute = function(actor, target, engine)
            local SecretsLib = require("dredwork_agency.secrets")
            local _, secret_list = SecretsLib.knows_about(actor.components.secrets, target.id)
            local secret = secret_list[1]
            local entities = engine:get_module("entities")
            if entities then
                entities:shift_relationship(actor.id, target.id, "fear", 20)
                entities:shift_relationship(target.id, actor.id, "loyalty", -10)
            end
            -- Target's memory: grudge against you
            if target.components.memory then
                local MemLib = require("dredwork_agency.memory")
                MemLib.add_grudge(target.components.memory, actor.id, "blackmailed me", 40)
            end
            return { success = true, text = "You reveal what you know. " .. target.name .. "'s face drains of color. They will comply — for now." }
        end,
    },
    {
        id = "assign_role",
        label = "Assign Role",
        description = "Appoint to a position of authority.",
        category = "governance",
        requires = function(actor, target, engine)
            -- Only the ruler can assign roles
            local gs = engine.game_state
            return gs.roles and gs.roles.assignments and gs.roles.assignments.ruler == actor.id
        end,
        execute = function(actor, target, engine)
            -- Returns available roles — actual assignment happens in UI
            return { success = true, text = "Which role?", needs_followup = "role_select", target_id = target.id }
        end,
    },
    {
        id = "investigate",
        label = "Investigate",
        description = "Look into their affairs.",
        category = "espionage",
        requires = function(actor, target, engine)
            local p = actor.components.personality or {}
            local obs = p.PER_OBS or 50
            if type(obs) == "table" then obs = obs.value or 50 end
            return obs >= 40
        end,
        execute = function(actor, target, engine)
            local SecretsLib = require("dredwork_agency.secrets")
            local day = engine.game_state.clock and engine.game_state.clock.total_days or 0
            if RNG.chance(0.4) then
                local types = {"embezzlement", "affair", "ambition", "weakness", "conspiracy"}
                local secret = SecretsLib.generate(target, RNG.pick(types), day)
                if not actor.components.secrets then actor.components.secrets = SecretsLib.create() end
                SecretsLib.learn(actor.components.secrets, secret)
                return { success = true, text = "You uncover something: " .. secret.text, secret = secret }
            end
            return { success = false, text = "Your investigation turns up nothing. Perhaps they're clean — or careful." }
        end,
    },
    {
        id = "give_gold",
        label = "Give Gold",
        description = "Offer coin from your purse.",
        category = "social",
        requires = function(actor, target, engine)
            local pw = actor.components.personal_wealth
            return pw and pw.gold >= 10
        end,
        execute = function(actor, target, engine)
            local WealthLib = require("dredwork_agency.wealth")
            WealthLib.change(actor.components.personal_wealth, -10, "gift to " .. target.name)
            if not target.components.personal_wealth then target.components.personal_wealth = WealthLib.create(0) end
            WealthLib.change(target.components.personal_wealth, 10, "gift from " .. actor.name)
            local entities = engine:get_module("entities")
            if entities then entities:shift_relationship(actor.id, target.id, "gratitude", 8) end
            if target.components.memory then
                local MemLib = require("dredwork_agency.memory")
                MemLib.add_debt(target.components.memory, actor.id, "gave me gold", 10)
            end
            return { success = true, text = "You press coins into " .. target.name .. "'s palm. They remember the gesture." }
        end,
    },
    {
        id = "confide",
        label = "Confide In",
        description = "Share something personal. Risk vulnerability.",
        category = "social",
        requires = function(a, t, e)
            local entities = e:get_module("entities")
            if not entities then return false end
            local rels = entities:get_relationships(a.id)
            for _, r in ipairs(rels) do
                if (r.a == t.id or r.b == t.id) and r.strength > 50 then return true end
            end
            return false
        end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then entities:shift_relationship(actor.id, target.id, "trust", 10) end
            if actor.components.needs then actor.components.needs.belonging = Math.clamp((actor.components.needs.belonging or 50) + 5, 0, 100) end
            return { success = true, text = "You let your guard down. The words come slowly, then all at once. " .. target.name .. " listens without judgment." }
        end,
    },
    {
        id = "seduce",
        label = "Seduce",
        description = "Test the boundaries of attraction.",
        category = "social",
        requires = function(a, t, e)
            local p = a.components.personality or {}
            local bld = p.PER_BLD or 50; if type(bld) == "table" then bld = bld.value or 50 end
            return bld >= 40
        end,
        execute = function(actor, target, engine)
            local Marriage = require("dredwork_marriage")
            local compat = Marriage.calculate_compatibility(actor.components.personality or {}, target.components.personality or {})
            local success = compat > 50 and RNG.chance(compat / 100)
            local entities = engine:get_module("entities")
            if success then
                if entities then entities:shift_relationship(actor.id, target.id, "romance", 15) end
                if actor.components.needs then actor.components.needs.belonging = Math.clamp((actor.components.needs.belonging or 50) + 5, 0, 100) end
                return { success = true, text = "Something sparks between you. " .. target.name .. "'s eyes linger a moment too long." }
            else
                if entities then entities:shift_relationship(actor.id, target.id, "awkward", 5) end
                return { success = false, text = target.name .. " turns away. The moment passes, unanswered." }
            end
        end,
    },
    {
        id = "recruit",
        label = "Recruit to Court",
        description = "Bring them into your service.",
        category = "governance",
        requires = function(a, t, e)
            local gs = e.game_state
            return gs.roles and gs.roles.assignments and gs.roles.assignments.ruler == a.id
        end,
        execute = function(actor, target, engine)
            local court = engine:get_module("court")
            if court then
                court:add_member({ name = target.name, role = "advisor", loyalty = 50, competence = RNG.range(30, 70), personality = target.components.personality })
            end
            return { success = true, text = target.name .. " kneels. \"I accept your service.\" A new voice in the court." }
        end,
    },
    {
        id = "exile",
        label = "Exile",
        description = "Cast them out.",
        category = "governance",
        requires = function(a, t, e)
            local gs = e.game_state
            return gs.roles and gs.roles.assignments and gs.roles.assignments.ruler == a.id
        end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then
                entities:destroy(target.id)
            end
            local rumor = engine:get_module("rumor")
            if rumor then
                rumor:inject(engine.game_state, {
                    origin_type = "exile", subject = target.name,
                    text = target.name .. " has been exiled from the realm.",
                    heat = 55, tags = { shame = true },
                })
            end
            return { success = true, text = "\"Leave. And do not return.\" " .. target.name .. " walks into the cold without looking back." }
        end,
    },
    {
        id = "forgive",
        label = "Forgive",
        description = "Let go of a grudge.",
        category = "social",
        requires = function(a, t, e)
            if not a.components.memory then return false end
            local MemLib = require("dredwork_agency.memory")
            return MemLib.has_grudge(a.components.memory, t.id)
        end,
        execute = function(actor, target, engine)
            if actor.components.memory then
                -- Remove grudge
                for i, g in ipairs(actor.components.memory.grudges) do
                    if g.target_id == target.id then table.remove(actor.components.memory.grudges, i); break end
                end
            end
            local entities = engine:get_module("entities")
            if entities then entities:shift_relationship(actor.id, target.id, "trust", 5) end
            if actor.components.needs then actor.components.needs.comfort = Math.clamp((actor.components.needs.comfort or 50) + 3, 0, 100) end
            return { success = true, text = "You let it go. Not because they deserve it, but because carrying it was killing you." }
        end,
    },
    {
        id = "betray",
        label = "Betray",
        description = "Break trust for personal gain.",
        category = "hostile",
        requires = function(a, t, e)
            local p = a.components.personality or {}
            local loy = p.PER_LOY or 50; if type(loy) == "table" then loy = loy.value or 50 end
            return loy < 55 -- disloyal characters can betray
        end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then
                entities:shift_relationship(actor.id, target.id, "loyalty", -30)
                entities:shift_relationship(target.id, actor.id, "trust", -30)
            end
            if target.components.memory then
                local MemLib = require("dredwork_agency.memory")
                MemLib.add_grudge(target.components.memory, actor.id, "betrayed me", 60)
            end
            -- Gain from betrayal
            if actor.components.personal_wealth then
                local WealthLib = require("dredwork_agency.wealth")
                WealthLib.change(actor.components.personal_wealth, RNG.range(20, 50), "betrayal gains")
            end
            local rumor = engine:get_module("rumor")
            if rumor then
                rumor:inject(engine.game_state, { origin_type = "betrayal", subject = actor.name,
                    text = actor.name .. " has betrayed " .. target.name .. "'s trust.",
                    heat = 75, tags = { scandal = true, shame = true } })
            end
            return { success = true, text = "You cross a line you can never uncross. The gold feels heavy. So does the silence." }
        end,
    },
    {
        id = "mentor",
        label = "Mentor",
        description = "Teach what you know.",
        category = "social",
        requires = function(a, t, e)
            local a_age = a.components.mortality and a.components.mortality.age or 30
            local t_age = t.components.mortality and t.components.mortality.age or 30
            return a_age > t_age + 5
        end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then
                entities:shift_relationship(actor.id, target.id, "mentor", 10)
                entities:add_relationship(target.id, actor.id, "student", 10)
            end
            if actor.components.needs then actor.components.needs.purpose = Math.clamp((actor.components.needs.purpose or 50) + 5, 0, 100) end
            if target.components.needs then target.components.needs.purpose = Math.clamp((target.components.needs.purpose or 50) + 5, 0, 100) end
            return { success = true, text = "You share what the years have taught you. " .. target.name .. " absorbs every word." }
        end,
    },
    {
        id = "spy_on",
        label = "Spy On",
        description = "Watch them without their knowledge.",
        category = "espionage",
        requires = function(a, t, e)
            local p = a.components.personality or {}
            local obs = p.PER_OBS or 50; if type(obs) == "table" then obs = obs.value or 50 end
            return obs >= 35
        end,
        execute = function(actor, target, engine)
            -- Higher chance than investigate, but only observes behavior, not secrets
            if target.components.agenda and target.components.agenda.current_action then
                return { success = true, text = "You watch from the shadows. " .. target.name .. " is " .. target.components.agenda.current_action .. ". Interesting." }
            elseif target.components.agenda and target.components.agenda.active_plan then
                local plan = target.components.agenda.active_plan
                return { success = true, text = "You observe " .. target.name .. " carefully. They seem to be pursuing something: " .. (plan.label or "unknown") .. "." }
            end
            return { success = true, text = "You watch " .. target.name .. " for a while. Nothing unusual — but nothing is ever what it seems." }
        end,
    },
    -- OWNERSHIP OF PEOPLE (dark fantasy)
    {
        id = "enslave",
        label = "Enslave",
        description = "Claim dominion over this person.",
        category = "hostile",
        requires = function(a, t, e)
            -- Must have power over them: they're defeated, captured, or you're the ruler with high cruelty
            local p = a.components.personality or {}
            local crm = p.PER_CRM or 50; if type(crm) == "table" then crm = crm.value or 50 end
            local gs = e.game_state
            local is_ruler = gs.roles and gs.roles.assignments and gs.roles.assignments.ruler == a.id
            -- Check they're not already owned
            local entities = e:get_module("entities")
            if entities then
                local rels = entities:get_relationships(t.id, "owned_by")
                if #rels > 0 then return false end
            end
            return is_ruler and crm >= 50
        end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then
                entities:add_relationship(target.id, actor.id, "owned_by", 100)
                entities:add_relationship(actor.id, target.id, "owns", 100)
            end
            -- Target's needs collapse
            if target.components.needs then
                target.components.needs.safety = Math.clamp((target.components.needs.safety or 50) - 30, 0, 100)
                target.components.needs.status = Math.clamp((target.components.needs.status or 50) - 40, 0, 100)
                target.components.needs.belonging = Math.clamp((target.components.needs.belonging or 50) - 20, 0, 100)
            end
            -- Target remembers
            if target.components.memory then
                local MemLib = require("dredwork_agency.memory")
                MemLib.add_grudge(target.components.memory, actor.id, "enslaved me", 90)
            end
            -- Culture reacts
            local culture = engine:get_module("culture")
            if culture then culture:shift("CUL_HIE", 3) end
            -- Rumor
            local rumor = engine:get_module("rumor")
            if rumor then
                rumor:inject(engine.game_state, { origin_type = "slavery", subject = target.name,
                    text = target.name .. " has been claimed as property. The world watches.",
                    heat = 70, tags = { shame = true, danger = true } })
            end
            engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = -5 })
            return { success = true, text = target.name .. " kneels. Not by choice. Their eyes say everything their mouth cannot." }
        end,
    },
    {
        id = "free_person",
        label = "Free",
        description = "Release from bondage.",
        category = "social",
        requires = function(a, t, e)
            local entities = e:get_module("entities")
            if not entities then return false end
            local rels = entities:get_relationships(t.id, "owned_by")
            for _, r in ipairs(rels) do
                if r.b == a.id or r.a == a.id then return true end
            end
            return false
        end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then
                -- Remove ownership relationships
                local rels = entities:get_relationships(target.id)
                for _, r in ipairs(rels) do
                    if r.type == "owned_by" or r.type == "owns" then
                        r.strength = 0 -- will be cleaned up
                    end
                end
            end
            -- Target remembers the freedom
            if target.components.memory then
                local MemLib = require("dredwork_agency.memory")
                MemLib.add_debt(target.components.memory, actor.id, "freed me", 50)
                -- Grudge remains but weakened
                for _, g in ipairs(target.components.memory.grudges) do
                    if g.target_id == actor.id then g.intensity = Math.clamp(g.intensity - 30, 0, 100) end
                end
            end
            if target.components.needs then
                target.components.needs.safety = Math.clamp((target.components.needs.safety or 50) + 20, 0, 100)
                target.components.needs.status = Math.clamp((target.components.needs.status or 50) + 15, 0, 100)
            end
            engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = 5 })
            local rumor = engine:get_module("rumor")
            if rumor then
                rumor:inject(engine.game_state, { origin_type = "freedom", subject = target.name,
                    text = target.name .. " has been freed. A rare act of mercy.",
                    heat = 50, tags = { praise = true, prestige = true } })
            end
            return { success = true, text = "You break the chain. " .. target.name .. " stands. They look at you — not with love, but with something complicated. Something you'll have to live with." }
        end,
    },
    {
        id = "command_servant",
        label = "Command",
        description = "Order them to serve.",
        category = "governance",
        requires = function(a, t, e)
            local entities = e:get_module("entities")
            if not entities then return false end
            local rels = entities:get_relationships(t.id, "owned_by")
            for _, r in ipairs(rels) do
                if r.b == a.id or r.a == a.id then return true end
            end
            return false
        end,
        execute = function(actor, target, engine)
            -- Set their action to serve the owner
            target.components.agenda = target.components.agenda or {}
            target.components.agenda.current_action = "serving"
            -- Service provides benefits to owner
            if actor.components.needs then
                actor.components.needs.comfort = Math.clamp((actor.components.needs.comfort or 50) + 2, 0, 100)
                actor.components.needs.status = Math.clamp((actor.components.needs.status or 50) + 1, 0, 100)
            end
            return { success = true, text = target.name .. " obeys. What else can they do?" }
        end,
    },
}

--------------------------------------------------------------------------------
-- PERSON → FACTION (rival houses)
--------------------------------------------------------------------------------

INTERACTIONS.person_faction = {
    {
        id = "send_envoy",
        label = "Send Envoy",
        description = "Open diplomatic channels.",
        category = "diplomatic",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            local rivals = engine:get_module("rivals")
            if rivals then rivals:change_disposition(target.id, 5) end
            if actor.components.personal_wealth then
                local WealthLib = require("dredwork_agency.wealth")
                WealthLib.change(actor.components.personal_wealth, -15, "diplomatic envoy")
            end
            return { success = true, text = "An envoy rides out bearing your words and a white flag. Diplomacy is expensive but war is more so." }
        end,
    },
    {
        id = "denounce",
        label = "Denounce Publicly",
        description = "Declare them enemies before the world.",
        category = "hostile",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            local rivals = engine:get_module("rivals")
            if rivals then rivals:change_disposition(target.id, -20) end
            local rumor = engine:get_module("rumor")
            if rumor then
                rumor:inject(engine.game_state, { origin_type = "denouncement", subject = target.name,
                    text = actor.name .. " has publicly denounced " .. target.name .. ".",
                    heat = 70, tags = { danger = true } })
            end
            engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = 3 })
            return { success = true, text = "Your words ring through the hall. " .. target.name .. " is now your declared enemy. There is no taking this back." }
        end,
    },
    {
        id = "offer_tribute",
        label = "Offer Tribute",
        description = "Pay for peace.",
        category = "diplomatic",
        requires = function(a, t, e)
            local pw = a.components.personal_wealth
            return pw and pw.gold >= 30
        end,
        execute = function(actor, target, engine)
            local WealthLib = require("dredwork_agency.wealth")
            WealthLib.change(actor.components.personal_wealth, -30, "tribute to " .. target.name)
            local rivals = engine:get_module("rivals")
            if rivals then rivals:change_disposition(target.id, 10) end
            return { success = true, text = "Gold buys time. " .. target.name .. " accepts the tribute with a smile that doesn't reach their eyes." }
        end,
    },
    {
        id = "demand_tribute",
        label = "Demand Tribute",
        description = "They will pay, or face consequences.",
        category = "hostile",
        requires = function(a, t, e)
            local p = a.components.personality or {}
            local bld = p.PER_BLD or 50; if type(bld) == "table" then bld = bld.value or 50 end
            return bld >= 50
        end,
        execute = function(actor, target, engine)
            -- Check if they comply based on their disposition
            local house = nil
            if engine.game_state.rivals then
                for _, h in ipairs(engine.game_state.rivals.houses) do
                    if h.id == target.id or h.entity_id == target.id then house = h; break end
                end
            end
            if house and house.disposition > -20 then
                if actor.components.personal_wealth then
                    local WealthLib = require("dredwork_agency.wealth")
                    WealthLib.change(actor.components.personal_wealth, 25, "tribute from " .. target.name)
                end
                return { success = true, text = target.name .. " complies, but their jaw is set. They won't forget this." }
            else
                return { success = false, text = target.name .. " refuses. \"Take it yourself, if you dare.\"" }
            end
        end,
    },
    {
        id = "spy_on_faction",
        label = "Plant Spy",
        description = "Insert an agent into their ranks.",
        category = "espionage",
        requires = function(a, t, e)
            local p = a.components.personality or {}
            local obs = p.PER_OBS or 50; if type(obs) == "table" then obs = obs.value or 50 end
            return obs >= 45
        end,
        execute = function(actor, target, engine)
            if actor.components.personal_wealth then
                local WealthLib = require("dredwork_agency.wealth")
                WealthLib.change(actor.components.personal_wealth, -20, "spy network")
            end
            if RNG.chance(0.5) then
                local SecretsLib = require("dredwork_agency.secrets")
                if not actor.components.secrets then actor.components.secrets = SecretsLib.create() end
                local secret = SecretsLib.generate(target, "conspiracy", engine.game_state.clock and engine.game_state.clock.total_days or 0)
                SecretsLib.learn(actor.components.secrets, secret)
                return { success = true, text = "Your spy returns with intelligence. " .. target.name .. " has been busy." }
            end
            return { success = false, text = "Your spy was detected and barely escaped. The investment yields nothing — this time." }
        end,
    },
}

--------------------------------------------------------------------------------
-- PERSON → UNIT (military)
--------------------------------------------------------------------------------

INTERACTIONS.person_unit = {
    {
        id = "inspect_unit",
        label = "Inspect",
        description = "Review the troops.",
        category = "military",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            local mil = target.components.military or {}
            return { success = true, text = string.format("You inspect the %s. Strength: %d. Morale: %.0f. %s",
                target.name, mil.strength or 0, mil.readiness or 0,
                (mil.readiness or 0) > 70 and "They are ready." or "They need work.") }
        end,
    },
    {
        id = "rally_troops",
        label = "Rally",
        description = "Inspire them with your presence.",
        category = "military",
        requires = function(a, t, e)
            local p = a.components.personality or {}
            local bld = p.PER_BLD or 50; if type(bld) == "table" then bld = bld.value or 50 end
            return bld >= 40
        end,
        execute = function(actor, target, engine)
            -- Boost morale of all units at same location
            if engine.game_state.military then
                for _, unit in ipairs(engine.game_state.military.units) do
                    unit.morale = Math.clamp((unit.morale or 50) + 8, 0, 100)
                end
            end
            return { success = true, text = "You stand before them. Your words carry weight. Eyes sharpen. Spines straighten. They remember why they fight." }
        end,
    },
    {
        id = "deploy_unit",
        label = "Deploy",
        description = "Send to a region.",
        category = "military",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            return { success = true, text = "Where?", needs_followup = "region_select", target_id = target.id, action = "deploy" }
        end,
    },
    {
        id = "disband_unit",
        label = "Disband",
        description = "Release the soldiers.",
        category = "military",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then entities:destroy(target.id) end
            -- Remove from military units list
            if engine.game_state.military then
                for i, u in ipairs(engine.game_state.military.units) do
                    if u.entity_id == target.id then table.remove(engine.game_state.military.units, i); break end
                end
            end
            return { success = true, text = "The soldiers scatter. Some relieved, some lost. The unit is no more." }
        end,
    },
}

--------------------------------------------------------------------------------
-- PERSON → PLACE (region)
--------------------------------------------------------------------------------

INTERACTIONS.person_place = {
    {
        id = "travel_to",
        label = "Travel",
        description = "Journey to this region.",
        category = "movement",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then
                entities:move_to(actor.id, target.id)
                -- Update world_map current region
                if engine.game_state.world_map then
                    engine.game_state.world_map.current_region_id = target.id
                end
            end
            return { success = true, text = "You pack light and ride hard. The road to " .. (target.name or target.id) .. " stretches ahead." }
        end,
    },
    {
        id = "invest_in_region",
        label = "Invest",
        description = "Pour resources into development.",
        category = "governance",
        requires = function(a, t, e)
            local pw = a.components.personal_wealth
            return pw and pw.gold >= 50
        end,
        execute = function(actor, target, engine)
            local WealthLib = require("dredwork_agency.wealth")
            WealthLib.change(actor.components.personal_wealth, -50, "investment in " .. (target.name or target.id))
            -- Boost market in that region
            local econ = engine:get_module("economy")
            if econ then
                local market = econ:get_market(target.id)
                if market then market.wealth_level = Math.clamp((market.wealth_level or 50) + 10, 0, 100) end
            end
            return { success = true, text = "Gold flows into " .. (target.name or "the region") .. ". Growth takes time, but the seed is planted." }
        end,
    },
    {
        id = "fortify_region",
        label = "Fortify",
        description = "Build defenses.",
        category = "military",
        requires = function(a, t, e)
            local pw = a.components.personal_wealth
            return pw and pw.gold >= 40
        end,
        execute = function(actor, target, engine)
            local WealthLib = require("dredwork_agency.wealth")
            WealthLib.change(actor.components.personal_wealth, -40, "fortifications")
            -- Boost regional security
            if engine.game_state.home and engine.game_state.home.attributes then
                engine.game_state.home.attributes.condition = Math.clamp((engine.game_state.home.attributes.condition or 50) + 10, 0, 100)
            end
            return { success = true, text = "Walls rise. Gates strengthen. Whatever comes, you will be ready." }
        end,
    },
    {
        id = "commission_work",
        label = "Commission Great Work",
        description = "Build something that will outlast you.",
        category = "legacy",
        requires = function(a, t, e)
            local pw = a.components.personal_wealth
            return pw and pw.gold >= 100
        end,
        execute = function(actor, target, engine)
            return { success = true, text = "What will you build?", needs_followup = "work_type_select", region_id = target.id }
        end,
    },
    {
        id = "explore",
        label = "Explore",
        description = "See what's out there.",
        category = "discovery",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            if RNG.chance(0.3) then
                -- Discovery!
                local discoveries = {
                    { text = "You find an old trail leading to a hidden spring. The water is cold and sweet.", effect = "comfort" },
                    { text = "In a ruined tower, you discover a cache of old coins.", effect = "gold" },
                    { text = "You stumble upon tracks — something large has passed through recently.", effect = "knowledge" },
                    { text = "A hermit lives at the edge of the territory. They speak of things the court does not know.", effect = "secret" },
                }
                local d = RNG.pick(discoveries)
                if d.effect == "gold" and actor.components.personal_wealth then
                    local WealthLib = require("dredwork_agency.wealth")
                    WealthLib.change(actor.components.personal_wealth, RNG.range(10, 30), "exploration find")
                end
                if d.effect == "secret" then
                    local SecretsLib = require("dredwork_agency.secrets")
                    if not actor.components.secrets then actor.components.secrets = SecretsLib.create() end
                    local s = { id = "explore_" .. (engine.game_state.clock and engine.game_state.clock.total_days or 0),
                        type = "weakness", subject_id = nil, text = "The land holds secrets older than any house.",
                        severity = 20, known_day = engine.game_state.clock and engine.game_state.clock.total_days or 0 }
                    SecretsLib.learn(actor.components.secrets, s)
                end
                return { success = true, text = d.text }
            end
            return { success = true, text = "You walk the borders of " .. (target.name or "the region") .. ". Nothing new — but the land remembers your footsteps." }
        end,
    },
}

--------------------------------------------------------------------------------
-- PERSON → HOME
--------------------------------------------------------------------------------

INTERACTIONS.person_home = {
    {
        id = "repair_home",
        label = "Repair",
        description = "Fix what's broken.",
        category = "domestic",
        requires = function(a, t, e)
            return e.game_state.home and e.game_state.home.attributes and e.game_state.home.attributes.condition < 80
        end,
        execute = function(actor, target, engine)
            if actor.components.personal_wealth then
                local WealthLib = require("dredwork_agency.wealth")
                WealthLib.change(actor.components.personal_wealth, -15, "home repairs")
            end
            engine.game_state.home.attributes.condition = Math.clamp(engine.game_state.home.attributes.condition + 15, 0, 100)
            return { success = true, text = "You roll up your sleeves. The work is honest and the walls are grateful." }
        end,
    },
    {
        id = "host_feast",
        label = "Host Feast",
        description = "Bring people together over food and drink.",
        category = "social",
        requires = function(a, t, e)
            local pw = a.components.personal_wealth
            return pw and pw.gold >= 25
        end,
        execute = function(actor, target, engine)
            local WealthLib = require("dredwork_agency.wealth")
            WealthLib.change(actor.components.personal_wealth, -25, "feast")
            -- Boost all court loyalty
            if engine.game_state.court then
                for _, m in ipairs(engine.game_state.court.members) do
                    if m.status == "active" then m.loyalty = Math.clamp(m.loyalty + 3, 0, 100) end
                end
            end
            -- Boost belonging and comfort
            if actor.components.needs then
                actor.components.needs.belonging = Math.clamp((actor.components.needs.belonging or 50) + 8, 0, 100)
                actor.components.needs.comfort = Math.clamp((actor.components.needs.comfort or 50) + 5, 0, 100)
            end
            engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = 2 })
            return { success = true, text = "The hall fills with warmth, laughter, and the smell of roasted meat. For one night, the troubles of the world feel distant." }
        end,
    },
    {
        id = "add_room",
        label = "Build Room",
        description = "Expand your dwelling.",
        category = "domestic",
        requires = function(a, t, e)
            local pw = a.components.personal_wealth
            return pw and pw.gold >= 40
        end,
        execute = function(actor, target, engine)
            return { success = true, text = "What kind of room?", needs_followup = "room_select" }
        end,
    },
    {
        id = "clean_home",
        label = "Clean & Organize",
        description = "Bring order to chaos.",
        category = "domestic",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            if engine.game_state.home and engine.game_state.home.attributes then
                engine.game_state.home.attributes.comfort = Math.clamp(engine.game_state.home.attributes.comfort + 3, 0, 100)
            end
            if actor.components.needs then
                actor.components.needs.comfort = Math.clamp((actor.components.needs.comfort or 50) + 2, 0, 100)
                actor.components.needs.purpose = Math.clamp((actor.components.needs.purpose or 50) + 1, 0, 100)
            end
            return { success = true, text = "You scrub, sweep, and sort. The space breathes easier. So do you." }
        end,
    },
}

--------------------------------------------------------------------------------
-- PERSON → ANIMAL
--------------------------------------------------------------------------------

INTERACTIONS.person_animal = {
    {
        id = "pet",
        label = "Pet",
        description = "Show affection.",
        category = "bond",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then entities:shift_relationship(actor.id, target.id, "owner_pet", 3) end
            if actor.components.needs then actor.components.needs.comfort = Math.clamp((actor.components.needs.comfort or 50) + 2, 0, 100) end
            return { success = true, text = target.name .. " leans into your hand. For a moment, everything is simple." }
        end,
    },
    {
        id = "feed",
        label = "Feed",
        description = "Share food.",
        category = "bond",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then entities:shift_relationship(actor.id, target.id, "owner_pet", 5) end
            return { success = true, text = "You offer food. " .. target.name .. " eats gratefully." }
        end,
    },
    {
        id = "command_guard",
        label = "Command: Guard",
        description = "Set to guard your home.",
        category = "command",
        requires = function(a, t, e)
            local species = t.components.species
            return species and (species.key == "hound" or species.key == "warhorse")
        end,
        execute = function(actor, target, engine)
            target.components.agenda = target.components.agenda or {}
            target.components.agenda.current_action = "guard"
            if engine.game_state.home and engine.game_state.home.attributes then
                engine.game_state.home.attributes.comfort = Math.clamp((engine.game_state.home.attributes.comfort or 50) + 2, 0, 100)
            end
            return { success = true, text = target.name .. " takes up a watchful position. Nothing will pass unnoticed." }
        end,
    },
    {
        id = "command_hunt",
        label = "Command: Hunt",
        description = "Send to hunt.",
        category = "command",
        requires = function(a, t, e)
            local species = t.components.species
            return species and (species.key == "hound" or species.key == "exotic_falcon")
        end,
        execute = function(actor, target, engine)
            target.components.agenda = target.components.agenda or {}
            target.components.agenda.current_action = "hunt_prey"
            local econ = engine:get_module("economy")
            if econ then econ:change_wealth(RNG.range(2, 8)) end
            return { success = true, text = target.name .. " disappears into the brush. They return with a catch." }
        end,
    },
    {
        id = "release",
        label = "Release",
        description = "Set free.",
        category = "bond",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            local entities = engine:get_module("entities")
            if entities then entities:destroy(target.id) end
            if actor.components.needs then actor.components.needs.belonging = Math.clamp((actor.components.needs.belonging or 50) - 5, 0, 100) end
            return { success = true, text = "You open the gate. " .. target.name .. " hesitates, then goes. You watch until they vanish." }
        end,
    },
    {
        id = "name",
        label = "Rename",
        description = "Give a new name.",
        category = "bond",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            return { success = true, text = "What name?", needs_followup = "text_input", target_id = target.id, action = "rename" }
        end,
    },
}

--------------------------------------------------------------------------------
-- PERSON → SELF
--------------------------------------------------------------------------------

INTERACTIONS.person_self = {
    {
        id = "rest",
        label = "Rest",
        description = "Take time to recover.",
        category = "personal",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            if actor.components.needs then
                actor.components.needs.comfort = Math.clamp((actor.components.needs.comfort or 50) + 5, 0, 100)
                actor.components.needs.safety = Math.clamp((actor.components.needs.safety or 50) + 2, 0, 100)
            end
            return { success = true, text = "You close your eyes. The world keeps turning, but for now, it turns without you." }
        end,
    },
    {
        id = "pray",
        label = "Pray",
        description = "Seek guidance from something greater.",
        category = "spiritual",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            if actor.components.needs then
                actor.components.needs.purpose = Math.clamp((actor.components.needs.purpose or 50) + 3, 0, 100)
            end
            if engine.game_state.religion and engine.game_state.religion.active_faith and engine.game_state.religion.active_faith.attributes then
                engine.game_state.religion.active_faith.attributes.zeal = Math.clamp((engine.game_state.religion.active_faith.attributes.zeal or 50) + 0.5, 0, 100)
            end
            return { success = true, text = "You kneel. Whether anyone listens, you cannot say. But the act itself steadies you." }
        end,
    },
    {
        id = "train",
        label = "Train",
        description = "Sharpen body and mind.",
        category = "personal",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            if actor.components.needs then
                actor.components.needs.purpose = Math.clamp((actor.components.needs.purpose or 50) + 3, 0, 100)
            end
            return { success = true, text = "You drill until your arms burn. Strength is earned, not given." }
        end,
    },
    {
        id = "scheme",
        label = "Scheme",
        description = "Plan in the shadows.",
        category = "espionage",
        requires = function(a, t, e)
            local p = a.components.personality or {}
            local obs = p.PER_OBS or 50
            if type(obs) == "table" then obs = obs.value or 50 end
            return obs >= 40
        end,
        execute = function(actor, target, engine)
            local rumor = engine:get_module("rumor")
            if rumor then
                rumor:inject(engine.game_state, {
                    origin_type = "scheme", subject = actor.name,
                    text = "Whispers of plots and plans circulate.",
                    heat = RNG.range(20, 40), tags = { scandal = true },
                })
            end
            if actor.components.needs then
                actor.components.needs.purpose = Math.clamp((actor.components.needs.purpose or 50) + 5, 0, 100)
            end
            return { success = true, text = "You sit in the dark, moving pieces only you can see. The game is long." }
        end,
    },
    {
        id = "review_secrets",
        label = "Review Secrets",
        description = "Consider what you know.",
        category = "espionage",
        requires = function(a, t, e)
            local secrets = a.components.secrets
            return secrets and secrets.known and #secrets.known > 0
        end,
        execute = function(actor, target, engine)
            local secrets = actor.components.secrets.known
            local lines = {}
            for _, s in ipairs(secrets) do
                table.insert(lines, string.format("[%s] %s (sev: %d)", s.type, s.text, s.severity))
            end
            return { success = true, text = "You review what you know:\n" .. table.concat(lines, "\n"), secrets = secrets }
        end,
    },
    {
        id = "examine_possessions",
        label = "Examine Items",
        description = "Look at what you carry.",
        category = "personal",
        requires = function(a, t, e)
            local inv = a.components.inventory
            return inv and inv.items and #inv.items > 0
        end,
        execute = function(actor, target, engine)
            local items = actor.components.inventory.items
            local lines = {}
            for _, item in ipairs(items) do
                table.insert(lines, item.name .. " — " .. item.description)
            end
            return { success = true, text = table.concat(lines, "\n"), items = items }
        end,
    },
}

--------------------------------------------------------------------------------
-- PERSON → ITEM
--------------------------------------------------------------------------------

INTERACTIONS.person_item = {
    {
        id = "examine",
        label = "Examine",
        description = "Look closely.",
        category = "personal",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            return { success = true, text = target.name .. " — " .. (target.description or "Nothing remarkable.") .. (target.origin and ("\n" .. target.origin.text) or "") }
        end,
    },
    {
        id = "use",
        label = "Use",
        description = "Put it to purpose.",
        category = "action",
        requires = function(a, t, e)
            return t.type == "medicine" or t.type == "tool" or t.properties.kill_target
        end,
        execute = function(actor, target, engine)
            if target.type == "medicine" then
                if actor.components.needs then
                    actor.components.needs.comfort = Math.clamp((actor.components.needs.comfort or 50) + (target.properties.health_restore or 3), 0, 100)
                end
                local inventory = engine:get_module("inventory")
                if inventory then inventory:remove(actor.id, target.id) end
                return { success = true, text = "The medicine tastes bitter. But the pain recedes." }
            end
            return { success = true, text = "You use " .. target.name .. "." }
        end,
    },
    {
        id = "destroy_item",
        label = "Destroy",
        description = "Break it. Burn it. Make it gone.",
        category = "action",
        requires = function(a, t, e) return true end,
        execute = function(actor, target, engine)
            local inventory = engine:get_module("inventory")
            if inventory then inventory:remove(actor.id, target.id) end
            local grief = (target.emotional_weight or 0) > 3
            if grief and actor.components.needs then
                actor.components.needs.comfort = Math.clamp((actor.components.needs.comfort or 50) - target.emotional_weight, 0, 100)
            end
            return { success = true, text = grief and ("You destroy " .. target.name .. ". It hurts more than you expected.") or ("You destroy " .. target.name .. ". It's done.") }
        end,
    },
}

--------------------------------------------------------------------------------
-- Query Engine
--------------------------------------------------------------------------------

--- Get all available interactions between actor and target.
---@param actor_id string
---@param target_id string
---@return table array of { id, label, description, category }
function Interactions:get_available(actor_id, target_id)
    local entities = self.engine:get_module("entities")
    if not entities then return {} end

    local actor = entities:get(actor_id)
    local target = entities:get(target_id)
    if not actor or not target then return {} end

    -- Self-interactions
    if actor_id == target_id then
        return self:_filter(INTERACTIONS.person_self, actor, actor)
    end

    -- Determine interaction set by type combination
    local key = actor.type .. "_" .. target.type
    local set = INTERACTIONS[key]
    if not set then return {} end

    return self:_filter(set, actor, target)
end

--- Get self-actions for an entity.
function Interactions:get_self_actions(actor_id)
    local entities = self.engine:get_module("entities")
    if not entities then return {} end
    local actor = entities:get(actor_id)
    if not actor then return {} end
    return self:_filter(INTERACTIONS.person_self, actor, actor)
end

--- Get home interactions.
function Interactions:get_home_actions(actor_id)
    local entities = self.engine:get_module("entities")
    if not entities then return {} end
    local actor = entities:get(actor_id)
    if not actor then return {} end
    local home = self.engine.game_state.home
    if not home then return {} end
    return self:_filter(INTERACTIONS.person_home, actor, home)
end

--- Get place/region interactions.
function Interactions:get_place_actions(actor_id, region_id)
    local entities = self.engine:get_module("entities")
    if not entities then return {} end
    local actor = entities:get(actor_id)
    if not actor then return {} end
    local target = { id = region_id, name = region_id, type = "place" }
    return self:_filter(INTERACTIONS.person_place, actor, target)
end

--- Get item interactions.
function Interactions:get_item_actions(actor_id, item)
    local entities = self.engine:get_module("entities")
    if not entities then return {} end
    local actor = entities:get(actor_id)
    if not actor then return {} end

    local result = {}
    for _, interaction in ipairs(INTERACTIONS.person_item) do
        if interaction.requires(actor, item, self.engine) then
            table.insert(result, {
                id = interaction.id,
                label = interaction.label,
                description = interaction.description,
                category = interaction.category,
            })
        end
    end
    return result
end

--- Execute an interaction.
---@param interaction_id string
---@param actor_id string
---@param target_id string (or item table for item interactions)
---@return table result { success, text, ... }
function Interactions:execute(interaction_id, actor_id, target_id)
    local entities = self.engine:get_module("entities")
    if not entities then return { success = false } end

    local actor = entities:get(actor_id)
    local target = entities:get(target_id)
    if not actor then return { success = false } end

    -- Find the interaction
    local sets_to_check = {}
    if actor_id == target_id then
        table.insert(sets_to_check, INTERACTIONS.person_self)
    else
        local key = actor.type .. "_" .. (target and target.type or "person")
        if INTERACTIONS[key] then table.insert(sets_to_check, INTERACTIONS[key]) end
    end

    for _, set in ipairs(sets_to_check) do
        for _, interaction in ipairs(set) do
            if interaction.id == interaction_id then
                if interaction.requires(actor, target or actor, self.engine) then
                    local result = interaction.execute(actor, target or actor, self.engine)

                    -- Emit for narrative
                    self.engine:emit("INTERACTION_PERFORMED", {
                        actor_id = actor_id,
                        actor_name = actor.name,
                        target_id = target_id,
                        target_name = target and target.name or actor.name,
                        interaction = interaction_id,
                        text = result.text,
                    })

                    return result
                else
                    return { success = false, text = "You can't do that right now." }
                end
            end
        end
    end

    return { success = false, text = "Unknown action." }
end

--- Execute an item interaction.
function Interactions:execute_item(interaction_id, actor_id, item)
    local entities = self.engine:get_module("entities")
    if not entities then return { success = false } end
    local actor = entities:get(actor_id)
    if not actor then return { success = false } end

    for _, interaction in ipairs(INTERACTIONS.person_item) do
        if interaction.id == interaction_id then
            if interaction.requires(actor, item, self.engine) then
                return interaction.execute(actor, item, self.engine)
            end
        end
    end
    return { success = false }
end

--- Filter interactions by requirements.
function Interactions:_filter(set, actor, target)
    local result = {}
    for _, interaction in ipairs(set) do
        if interaction.requires(actor, target, self.engine) then
            table.insert(result, {
                id = interaction.id,
                label = interaction.label,
                description = interaction.description,
                category = interaction.category,
            })
        end
    end
    return result
end

function Interactions:serialize() return {} end
function Interactions:deserialize(data) end

return Interactions
