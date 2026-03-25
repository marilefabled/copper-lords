-- The Ripple — Consequence Narrator
-- Watches state-pair combinations across modules.
-- When interesting collisions happen, generates observations that juxtapose
-- the player's choices with their consequences — without explaining the link.
--
-- "The streets are darker than they used to be. You're not sure when that started."
--
-- This is NOT pattern detection (that's dredwork_patterns).
-- This is STATE COLLISION detection: "you are X AND the world is Y."
-- The player connects the dots. Or doesn't.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    --------------------------------------------------------------------------
    -- MONTHLY: Scan for state collisions and narrate
    --------------------------------------------------------------------------

    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        local entities = engine:get_module("entities")
        local focal = entities and entities:get_focus()
        if not focal then return end

        local day = clock and clock.total_days or 0
        local patterns = gs.patterns or {}
        local tag_counts = patterns.tag_counts or {}
        local corruption = gs.underworld and gs.underworld.global_corruption or 0
        local unrest = gs.politics and gs.politics.unrest or 0
        local terror = gs.justice and gs.justice.terror_score or 0
        local zeal = gs.religion and gs.religion.active_faith and
                     gs.religion.active_faith.attributes and
                     gs.religion.active_faith.attributes.zeal or 0
        local suspicion = gs.claim and gs.claim.suspicion or 0
        local gold = focal.components.personal_wealth and focal.components.personal_wealth.gold or 0

        -- Track what we've already fired to avoid repeats
        gs._consequence_narrator = gs._consequence_narrator or { fired = {} }
        local fired = gs._consequence_narrator.fired

        -- Only fire one observation per month (restraint makes it powerful)
        local observation = nil

        ----------------------------------------------------------------
        -- MERCY + HIGH CRIME: Your kindness enabled the underworld
        ----------------------------------------------------------------
        if not fired.mercy_crime and (tag_counts.mercy or 0) >= 5 and corruption > 35 then
            observation = RNG.pick({
                "The streets are darker than they used to be. You're not sure when that started.",
                "Another break-in. The third this month. People used to leave their doors unlocked.",
                "You pass a group of men in the alley. They nod at you. Friendly. Too friendly. Like they know something about you — about your softness — and they're grateful for it.",
                "An old woman grabs your sleeve. 'You're the kind one. The one who lets people go.' She doesn't sound grateful. She sounds afraid.",
            })
            fired.mercy_crime = true
        end

        ----------------------------------------------------------------
        -- CRUELTY + LOW CRIME: Your fear works. At a cost.
        ----------------------------------------------------------------
        if not fired.cruelty_order and (tag_counts.cruelty or 0) >= 5 and corruption < 15 then
            observation = observation or RNG.pick({
                "The streets are quiet. Clean. Nobody lingers. Nobody talks. You wonder if this is order or just silence.",
                "Children cross the street when they see you. Their mothers taught them that. The streets are safe. The fear is not.",
                "A merchant thanks you for the peace. His hands shake when he says it. Peace and terror look the same from a distance.",
            })
            fired.cruelty_order = true
        end

        ----------------------------------------------------------------
        -- HIGH ZEAL + TECH STAGNATION: Faith ate progress
        ----------------------------------------------------------------
        if not fired.zeal_tech and zeal > 65 then
            local tech = gs.technology and gs.technology.fields
            if tech then
                local stagnant = 0
                for _, field in pairs(tech) do
                    if (field.progress or 0) < 5 then stagnant = stagnant + 1 end
                end
                if stagnant >= 3 then
                    observation = observation or RNG.pick({
                        "The scholars are gone. Not dead — just quiet. Their books gather dust. The temples, though. The temples are full.",
                        "A tinker offers you a mechanism. Clever. Useful. He whispers when he shows it to you. 'Don't tell the priests.'",
                    })
                    fired.zeal_tech = true
                end
            end
        end

        ----------------------------------------------------------------
        -- HIGH SUSPICION + HIGH MERCY: You're kind AND hunted
        ----------------------------------------------------------------
        if not fired.hunted_kind and suspicion > 40 and (tag_counts.mercy or 0) >= 3 then
            observation = observation or RNG.pick({
                "People know two things about you: that you're kind, and that you're hiding something. They haven't decided which matters more.",
                "A child brings you a flower. You wonder if someone sent them. You wonder if you'll ever stop wondering.",
                "Trust and suspicion. You carry both. The weight is uneven.",
            })
            fired.hunted_kind = true
        end

        ----------------------------------------------------------------
        -- HIGH UNREST + WEALTH: You have gold while the world burns
        ----------------------------------------------------------------
        if not fired.wealthy_unrest and gold > 40 and unrest > 50 then
            observation = observation or RNG.pick({
                "Your purse is heavy. The streets are angry. These two facts are not unrelated.",
                "A beggar spits at your shadow. Not at you — they're not brave enough for that. But the message lands.",
                "You eat well tonight. Through the window, you see smoke. Someone's burning something that isn't theirs.",
            })
            fired.wealthy_unrest = true
        end

        ----------------------------------------------------------------
        -- DESTITUTE + HIGH REPUTATION: Famous and starving
        ----------------------------------------------------------------
        if not fired.famous_starving and gold <= 0 and patterns.reputation_label then
            observation = observation or RNG.pick({
                "They call you " .. (patterns.reputation_label or "someone") .. ". You can't eat a name.",
                "Your reputation precedes you. Your hunger follows.",
                "A stranger recognizes you. Asks for advice. You smile. Your stomach answers for you, quietly.",
            })
            fired.famous_starving = true
        end

        ----------------------------------------------------------------
        -- HIGH TERROR + HIGH CORRUPTION: Fear breeds shadows
        ----------------------------------------------------------------
        if not fired.terror_corruption and terror > 40 and corruption > 40 then
            observation = observation or RNG.pick({
                "The punishments are harsh. The crime continues. Somehow, both are true at once.",
                "The dungeons are full. So are the alleys. Fear drives crime underground — it doesn't kill it.",
                "The magistrate hangs a thief at dawn. By noon, his successor is already working the same corner.",
            })
            fired.terror_corruption = true
        end

        ----------------------------------------------------------------
        -- SCHEMING REPUTATION + ALLY SUSPICION: Your shadow precedes you
        ----------------------------------------------------------------
        if not fired.scheming_lonely and (tag_counts.scheming or 0) >= 5 then
            local entities_mod = engine:get_module("entities")
            local lonely = true
            if entities_mod then
                local rels = entities_mod:get_relationships(focal.id)
                for _, r in ipairs(rels) do
                    if r.strength > 60 then lonely = false; break end
                end
            end
            if lonely then
                observation = observation or RNG.pick({
                    "You know everyone's secrets. No one knows yours. The isolation is complete — and it was your design.",
                    "The shadows are comfortable now. But comfort and companionship are different things.",
                    "You've become very good at knowing what people want. When was the last time someone knew what you wanted?",
                })
                fired.scheming_lonely = true
            end
        end

        ----------------------------------------------------------------
        -- COURAGE + INJURIES: Brave but breaking
        ----------------------------------------------------------------
        if not fired.brave_breaking and (tag_counts.courage or 0) >= 5 then
            local needs = focal.components.needs
            if needs and (needs.safety or 50) < 25 then
                observation = observation or RNG.pick({
                    "Brave. Always brave. Your body keeps the score your mouth won't speak.",
                    "They tell stories about your courage. You tell yourself the shaking will stop eventually.",
                    "Every scar is a decision you didn't flinch from. Your skin is running out of room.",
                })
                fired.brave_breaking = true
            end
        end

        ----------------------------------------------------------------
        -- EMIT
        ----------------------------------------------------------------
        if observation then
            engine:emit("NARRATIVE_BEAT", {
                channel = "whispers",
                text = observation,
                priority = 68,
                display_hint = "pattern",
                tags = { "consequence", "juxtaposition" },
                timestamp = day,
            })
            engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = observation,
                priority = 68,
                display_hint = "pattern",
            })
        end
    end)

    --------------------------------------------------------------------------
    -- ECHO TRIGGERS: When a happening fires that connects to a past choice,
    -- emit a memory echo (ghost text from the original moment).
    --------------------------------------------------------------------------

    engine:on("HAPPENING_PRESENTED", function(happening)
        if not happening then return end
        local gs = engine.game_state
        local history = gs.happenings and gs.happenings.history or {}

        -- Find past choices that connect to this happening
        local echo_text = nil

        -- Crime happening + past mercy
        if happening.category == "crime" then
            local patterns = gs.patterns or {}
            if (patterns.tag_counts or {}).mercy and patterns.tag_counts.mercy >= 3 then
                -- Find the most recent merciful choice
                for i = #history, 1, -1 do
                    local h = history[i]
                    if h.option_chosen == "feed_them" or h.option_chosen == "help"
                       or h.option_chosen == "hide_them" or h.option_chosen == "release_ally" then
                        echo_text = h.result or "You chose mercy."
                        break
                    end
                end
                if not echo_text then
                    echo_text = "You let them go."
                end
            end
        end

        -- Claim recognition happening + past reveal
        if happening.category == "claim" then
            for i = #history, 1, -1 do
                local h = history[i]
                if h.happening_id == "recognized" then
                    echo_text = "A face from before. They saw you then, too."
                    break
                end
            end
        end

        -- Wealth/economy happening + past theft
        if happening.id == "theft_consequence" or happening.id == "favor_returned" then
            for i = #history, 1, -1 do
                local h = history[i]
                if h.option_chosen == "steal" then
                    echo_text = "Your hand moved. The purse vanished."
                    break
                elseif h.option_chosen == "hide_them" or h.option_chosen == "feed_them" then
                    echo_text = "You gave what you had."
                    break
                end
            end
        end

        if echo_text then
            engine:push_ui_event("MEMORY_ECHO", {
                text = echo_text,
            })
        end
    end)

    --------------------------------------------------------------------------
    -- NPC WORLD-VOICE: NPCs reference the state of the world YOU created
    -- without knowing you created it. Added as context lines in dialogue.
    --------------------------------------------------------------------------

    engine:on("GET_INTERACTIONS", function(req)
        if not req or not req.interactions then return end
        local gs = engine.game_state
        local corruption = gs.underworld and gs.underworld.global_corruption or 0
        local unrest = gs.politics and gs.politics.unrest or 0
        local terror = gs.justice and gs.justice.terror_score or 0

        -- Inject world-state awareness as NPC ambient lines
        -- These are NOT interaction options — they're flavor attached to existing talk
        req._world_voice = req._world_voice or {}

        if corruption > 40 then
            table.insert(req._world_voice, RNG.pick({
                "It used to be safer here.",
                "Lock your door at night. Didn't have to say that a year ago.",
                "The thieves don't even bother hiding anymore.",
            }))
        end

        if unrest > 50 then
            table.insert(req._world_voice, RNG.pick({
                "People are angry. Not the shouting kind. The quiet kind. That's worse.",
                "Something's going to break. You can feel it.",
                "Everyone I know is keeping their head down. That's never a good sign.",
            }))
        end

        if terror > 50 then
            table.insert(req._world_voice, RNG.pick({
                "The punishments have gotten... creative. I try not to watch.",
                "They hung two people this morning. Neither one was guilty. Everyone knows. Nobody speaks.",
                "Fear keeps the peace. But it's not peace, is it?",
            }))
        end
    end)
end

return Bridge
