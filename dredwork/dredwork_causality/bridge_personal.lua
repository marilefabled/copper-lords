-- The Ripple — Personal Bridge
-- Encounters, items, mood, wealth → narrative, relationships, needs.
-- The intimate layer. Where the magnifying glass sits.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local MoodLib = require("dredwork_agency.mood")
local InnerVoice = require("dredwork_narrative.inner_voice")

local Bridge = {}

function Bridge.wire(engine)

    --------------------------------------------------------------------------
    -- ENCOUNTERS → NEEDS + NARRATIVE
    --------------------------------------------------------------------------

    engine:on("ENCOUNTER", function(ctx)
        if not ctx then return end
        local entities = engine:get_module("entities")
        if not entities then return end
        local focal = entities:get_focus()
        if not focal then return end

        -- Apply encounter effects to focal entity's needs
        if ctx.effect and focal.components.needs then
            for need, delta in pairs(ctx.effect) do
                if focal.components.needs[need] then
                    focal.components.needs[need] = Math.clamp(
                        focal.components.needs[need] + delta, 0, 100)
                end
            end
        end

        -- Encounters produce narrative beats
        if ctx.text then
            engine:emit("NARRATIVE_BEAT", {
                channel = "whispers",
                text = ctx.text,
                priority = ctx.type == "secret" and 60 or (ctx.type == "need" and 55 or 45),
                display_hint = "encounter",
                tags = { "encounter", ctx.type or "ambient" },
                timestamp = ctx.day or 0,
            })
            engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = ctx.text,
                priority = 45,
                display_hint = "encounter",
            })
        end
    end)

    --------------------------------------------------------------------------
    -- INNER VOICE: Generate thoughts for focal entity
    --------------------------------------------------------------------------

    engine:on("NEW_DAY", function(clock)
        local entities = engine:get_module("entities")
        if not entities then return end
        local focal = entities:get_focus()
        if not focal then return end

        local thought = InnerVoice.generate(focal, engine.game_state)
        if thought then
            -- Update mood component
            focal.components.mood = MoodLib.calculate(focal)

            engine:emit("NARRATIVE_BEAT", {
                channel = "whispers",
                text = thought.text,
                priority = thought.priority,
                display_hint = "thought",
                tags = thought.tags,
                timestamp = clock.total_days or 0,
            })
            engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = thought.text,
                priority = thought.priority,
                display_hint = "thought",
            })
        end
    end)

    --------------------------------------------------------------------------
    -- ITEMS → RELATIONSHIPS + MEMORY
    --------------------------------------------------------------------------

    -- Receiving a cherished item strengthens the bond
    engine:on("ITEM_RECEIVED", function(ctx)
        if not ctx or not ctx.item then return end
        local gs = engine.game_state

        if ctx.item.emotional_weight > 5 then
            -- Significant item → memory
            local entities = engine:get_module("entities")
            if entities then
                local entity = entities:get(ctx.entity_id)
                if entity and entity.components.memory then
                    local MemLib = require("dredwork_agency.memory")
                    MemLib.remember(entity.components.memory,
                        gs.clock and gs.clock.total_days or 0,
                        "received_item", ctx.item.origin.entity_id,
                        "Received " .. ctx.item.name, ctx.item.emotional_weight)
                end
            end
        end
    end)

    -- Losing a cherished item → grief
    engine:on("ITEM_LOST", function(ctx)
        if not ctx or not ctx.item then return end
        if ctx.item.emotional_weight > 3 then
            local entities = engine:get_module("entities")
            if entities then
                local entity = entities:get(ctx.entity_id)
                if entity and entity.components.needs then
                    entity.components.needs.comfort = Math.clamp(
                        (entity.components.needs.comfort or 50) - ctx.item.emotional_weight, 0, 100)
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    -- PERSONAL WEALTH: Tick monthly (survival-aware for focal)
    --------------------------------------------------------------------------

    engine:on("NEW_MONTH", function(clock)
        local entities = engine:get_module("entities")
        if not entities then return end
        local WealthLib = require("dredwork_agency.wealth")
        local focal = entities:get_focus()
        local focal_id = focal and focal.id

        for _, entity in pairs(engine.game_state.entities.registry) do
            if not entity.alive then goto skip end
            local pw = entity.components.personal_wealth
            if not pw then goto skip end

            if entity.id == focal_id then
                -- Focal entity: track unpaid expenses and emit events
                local unpaid, gold_before = WealthLib.tick_monthly_survival(pw, clock.total_days)
                local gold_after = pw.gold

                -- Narrative beats on large gold changes
                local delta = gold_after - gold_before
                if delta > 10 then
                    engine:emit("NARRATIVE_BEAT", {
                        channel = "whispers", priority = 50, display_hint = "signal",
                        text = "The pouch is heavier than yesterday. A rare feeling.",
                        tags = { "wealth" }, timestamp = clock.total_days,
                    })
                    engine:push_ui_event("NARRATIVE_BEAT", {
                        channel = "whispers", text = "The pouch is heavier than yesterday. A rare feeling.",
                        priority = 50, display_hint = "signal",
                    })
                elseif delta < -10 then
                    engine:emit("NARRATIVE_BEAT", {
                        channel = "whispers", priority = 55, display_hint = "signal",
                        text = "The coins slip away faster than they come. Every month, the pile shrinks.",
                        tags = { "wealth" }, timestamp = clock.total_days,
                    })
                    engine:push_ui_event("NARRATIVE_BEAT", {
                        channel = "whispers", text = "The coins slip away faster than they come.",
                        priority = 55, display_hint = "signal",
                    })
                end

                -- Low gold warning
                if gold_after < 10 and gold_after > 0 then
                    engine:emit("NARRATIVE_BEAT", {
                        channel = "whispers", priority = 60, display_hint = "signal",
                        text = "The pouch is light. You count what's left and stop counting.",
                        tags = { "wealth", "danger" }, timestamp = clock.total_days,
                    })
                    engine:push_ui_event("NARRATIVE_BEAT", {
                        channel = "whispers",
                        text = "The pouch is light. You count what's left and stop counting.",
                        priority = 60, display_hint = "signal",
                    })
                end

                -- Wealth crisis at zero
                if gold_after <= 0 then
                    engine:emit("WEALTH_CRISIS", { severity = 1, gold = gold_after })
                    engine:push_ui_event("WEALTH_CRISIS", {
                        text = "Nothing. The pouch is empty. The world doesn't stop for the poor.",
                    })
                    -- Slam needs directly
                    if focal.components.needs then
                        focal.components.needs.safety = Math.clamp(
                            (focal.components.needs.safety or 50) - 10, 0, 100)
                        focal.components.needs.comfort = Math.clamp(
                            (focal.components.needs.comfort or 50) - 15, 0, 100)
                    end
                end

                -- Unpaid expense narrative
                for _, bill in ipairs(unpaid) do
                    engine:emit("EXPENSE_UNPAID", { reason = bill.reason, amount = bill.amount })
                    local expense_texts = {
                        rent = "The landlord stood in the doorway. You had nothing to give him.",
                        food = "Your stomach speaks a language that needs no translation.",
                    }
                    local beat_text = expense_texts[bill.reason] or
                        ("You couldn't cover the " .. bill.reason .. ". The debt sits heavy.")
                    engine:emit("NARRATIVE_BEAT", {
                        channel = "whispers", priority = 62, display_hint = "encounter",
                        text = beat_text, tags = { "wealth", "unpaid" },
                        timestamp = clock.total_days,
                    })
                    engine:push_ui_event("NARRATIVE_BEAT", {
                        channel = "whispers", text = beat_text,
                        priority = 62, display_hint = "encounter",
                    })
                end
            else
                -- Non-focal: simple tick
                WealthLib.tick_monthly(pw, clock.total_days)
            end
            ::skip::
        end
    end)

    --------------------------------------------------------------------------
    -- LETTERS: Deliver letters, informant reports, scheme updates
    --------------------------------------------------------------------------

    engine:on("NEW_DAY", function(clock)
        local gs = engine.game_state
        local Letters = require("dredwork_agency.letters")
        local day = clock and clock.total_days or 0

        -- Informant reports (daily chance if you have informants)
        if gs._informants and #gs._informants > 0 and RNG.chance(0.08) then
            local entities_mod = engine:get_module("entities")
            local inf_id = RNG.pick(gs._informants)
            local inf = entities_mod and entities_mod:get(inf_id)
            if inf and inf.alive then
                -- Generate contextual report from world state
                local reports = {}
                if gs.underworld and (gs.underworld.global_corruption or 0) > 30 then
                    table.insert(reports, "The guild is planning something. I don't have details yet, but coin is moving in unusual directions.")
                end
                if gs.claim and gs.claim.suspicion > 30 then
                    table.insert(reports, "People are asking about you. Specifically about your parents. Be careful.")
                end
                if gs.politics and (gs.politics.unrest or 0) > 40 then
                    table.insert(reports, "The people are restless. I hear talk of protests. Maybe worse.")
                end
                if #reports == 0 then
                    table.insert(reports, "Quiet week. Nothing that concerns you directly. I'll keep watching.")
                end
                Letters.generate_informant_report(gs, inf.name or "Your informant", RNG.pick(reports), day)
            end
        end

        -- Unread letter notification
        local unread = Letters.get_unread_count(gs)
        if unread > 0 and day % 3 == 0 then  -- remind every 3 days
            engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = unread == 1 and "A letter waits for you at home." or (unread .. " letters wait for you."),
                priority = 45,
                display_hint = "signal",
            })
        end
    end)

    -- Monthly: tick scheme partners
    engine:on("NEW_MONTH", function(clock)
        local SchemesLib = require("dredwork_agency.schemes")
        SchemesLib.tick_partner(engine.game_state, engine)
    end)

    --------------------------------------------------------------------------
    -- SUSPICION NARRATIVE THRESHOLDS
    --------------------------------------------------------------------------

    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.claim or not gs.claim.type then return end

        local susp = gs.claim.suspicion or 0
        local prev = gs.claim._prev_suspicion_tier or 0
        local tier = 0
        if susp >= 75 then tier = 3
        elseif susp >= 50 then tier = 2
        elseif susp >= 25 then tier = 1 end

        if tier > prev then
            local texts = {
                [1] = "Questions. Nothing direct. But people are watching more carefully.",
                [2] = "The air has changed. People fall silent when you enter a room. They know something.",
                [3] = "You can feel it — the noose tightening. Whoever is looking for you is close.",
            }
            engine:emit("NARRATIVE_BEAT", {
                channel = "whispers", priority = 63, display_hint = "signal",
                text = texts[tier], tags = { "claim", "suspicion" },
                timestamp = clock.total_days,
            })
            engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers", text = texts[tier],
                priority = 63, display_hint = "signal",
            })
        end
        gs.claim._prev_suspicion_tier = tier
    end)

    --------------------------------------------------------------------------
    -- MOOD: Update focal entity's mood on display
    --------------------------------------------------------------------------

    engine:on("NEW_MONTH", function(clock)
        local entities = engine:get_module("entities")
        if not entities then return end
        local focal = entities:get_focus()
        if not focal then return end

        -- Calculate and store mood
        focal.components.mood = MoodLib.calculate(focal)
    end)

    --------------------------------------------------------------------------
    -- ROLES → PERSONAL WEALTH (salary)
    --------------------------------------------------------------------------

    engine:on("ROLE_ASSIGNED", function(ctx)
        if not ctx or not ctx.entity_id then return end
        local entities = engine:get_module("entities")
        if not entities then return end
        local entity = entities:get(ctx.entity_id)
        if not entity then return end

        -- Initialize personal wealth if missing
        if not entity.components.personal_wealth then
            local WealthLib = require("dredwork_agency.wealth")
            entity.components.personal_wealth = WealthLib.create(20)
        end

        -- Role salary as income source
        local role_salaries = {
            ruler = 0, heir = 0, general = 15, spymaster = 12, treasurer = 10,
            priest = 5, steward = 8, ambassador = 10, judge = 8, master_hunter = 5,
        }
        local salary = role_salaries[ctx.role_id] or 5
        if salary > 0 then
            local WealthLib = require("dredwork_agency.wealth")
            WealthLib.add_income(entity.components.personal_wealth, "role:" .. ctx.role_id, salary)
        end
    end)

    engine:on("ROLE_VACATED", function(ctx)
        if not ctx or not ctx.entity_id then return end
        local entities = engine:get_module("entities")
        if not entities then return end
        local entity = entities:get(ctx.entity_id)
        if not entity or not entity.components.personal_wealth then return end

        local WealthLib = require("dredwork_agency.wealth")
        WealthLib.remove_income(entity.components.personal_wealth, "role:" .. ctx.role_id)
    end)
end

return Bridge
