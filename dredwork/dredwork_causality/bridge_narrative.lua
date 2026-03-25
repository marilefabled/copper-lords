-- The Ripple — Narrative Bridge
-- Echoes, Approaches, Patterns, Arcs → everything.
-- The systems that watch the player's behavior and reflect it back.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    --------------------------------------------------------------------------
    -- PATTERNS → REPUTATION → NPC BEHAVIOR
    -- Your behavioral patterns change how NPCs treat you.
    --------------------------------------------------------------------------

    engine:on("PATTERN_DETECTED", function(ctx)
        if not ctx then return end
        local entities = engine:get_module("entities")
        if not entities then return end

        -- Reputation affects NPC needs/disposition toward focal
        local focal = entities:get_focus()
        if not focal then return end

        local axis = ctx.axis
        local threshold = ctx.threshold or 0

        -- Major thresholds shift the world
        if threshold >= 5 then
            if axis == "mercy" then
                -- Merciful reputation: people feel safer around you
                for _, entity in pairs(engine.game_state.entities.registry) do
                    if entity.alive and entity.id ~= focal.id and entity.components.needs then
                        entity.components.needs.safety = Math.clamp(
                            (entity.components.needs.safety or 50) + 2, 0, 100)
                    end
                end
            elseif axis == "cruelty" then
                -- Cruel reputation: people fear you (safety drops, loyalty through fear)
                for _, entity in pairs(engine.game_state.entities.registry) do
                    if entity.alive and entity.id ~= focal.id and entity.components.needs then
                        entity.components.needs.safety = Math.clamp(
                            (entity.components.needs.safety or 50) - 3, 0, 100)
                    end
                end
                -- Suppresses unrest through fear
                if engine.game_state.politics then
                    engine.game_state.politics.unrest = Math.clamp(
                        (engine.game_state.politics.unrest or 0) - 5, 0, 100)
                end
            elseif axis == "diplomacy" then
                -- Diplomatic reputation: trade and alliance benefits
                if engine.game_state.politics then
                    engine.game_state.politics.legitimacy = Math.clamp(
                        (engine.game_state.politics.legitimacy or 50) + 3, 0, 100)
                end
            elseif axis == "violence" then
                -- Violent reputation: military morale up, civilian trust down
                if engine.game_state.military then
                    engine.game_state.military.total_morale = Math.clamp(
                        (engine.game_state.military.total_morale or 50) + 5, 0, 100)
                end
            elseif axis == "scheming" then
                -- Scheming reputation: suspicion rises
                if engine.game_state.claim then
                    engine.game_state.claim.suspicion = Math.clamp(
                        (engine.game_state.claim.suspicion or 0) + 5, 0, 100)
                end
            end
        end

        -- Emit for other systems to react
        engine:emit("REPUTATION_SHIFTED", {
            axis = ctx.axis,
            count = ctx.count,
            threshold = ctx.threshold,
        })
    end)

    --------------------------------------------------------------------------
    -- ECHOES → RUMORS + NARRATIVE
    -- When an echo fires, it becomes a rumor and a story.
    --------------------------------------------------------------------------

    engine:on("ECHO_FIRED", function(ctx)
        if not ctx then return end

        -- Echoes generate rumors (your past becomes public knowledge)
        local rumor_mod = engine:get_module("rumor")
        if rumor_mod and ctx.text then
            rumor_mod:inject({
                text = ctx.text,
                heat = 30 + (ctx.delay_days or 0) / 10,  -- older echoes hit harder
                source = "echo",
                tags = { "echo", ctx.echo_type or "unknown" },
            })
        end

        -- Certain echo types affect claim suspicion
        if ctx.echo_type == "revenge" or ctx.echo_type == "betrayer_moves" then
            if engine.game_state.claim then
                engine.game_state.claim.suspicion = Math.clamp(
                    (engine.game_state.claim.suspicion or 0) + 8, 0, 100)
            end
        elseif ctx.echo_type == "gratitude" or ctx.echo_type == "supporter_returns" then
            -- Positive echoes bolster legitimacy
            if engine.game_state.politics then
                engine.game_state.politics.legitimacy = Math.clamp(
                    (engine.game_state.politics.legitimacy or 50) + 2, 0, 100)
            end
        end
    end)

    --------------------------------------------------------------------------
    -- APPROACHES → MEMORY + RELATIONSHIPS
    -- When an NPC approaches you, it becomes part of both your memories.
    --------------------------------------------------------------------------

    engine:on("APPROACH_RESOLVED", function(ctx)
        if not ctx then return end
        local entities = engine:get_module("entities")
        if not entities then return end

        local focal = entities:get_focus()
        local other = ctx.entity_id and entities:get(ctx.entity_id)
        if not focal or not other then return end

        local day = engine.game_state.clock and engine.game_state.clock.total_days or 0

        -- Both parties remember the encounter
        local MemLib = require("dredwork_agency.memory")

        if focal.components.memory then
            MemLib.remember(focal.components.memory, day,
                "approached_by", other.id,
                (other.name or "Someone") .. " sought you out (" .. (ctx.type or "?") .. ")", 5)
        end

        if other.components.memory then
            MemLib.remember(other.components.memory, day,
                "approached", focal.id,
                "Sought out " .. (focal.name or "someone") .. " (" .. (ctx.type or "?") .. ")", 5)
        end

        -- Confrontations that go badly can escalate
        if ctx.type == "confrontation" then
            if ctx.response == "intimidate" then
                -- Grudge deepens or enemy is cowed
                if other.components.memory then
                    MemLib.add_grudge(other.components.memory, focal.id, "humiliated me", 20)
                end
            elseif ctx.response == "face_them" then
                -- Respect earned, grudge slightly reduced
                local has, intensity = MemLib.has_grudge(other.components.memory, focal.id)
                if has and intensity then
                    -- Can't directly reduce grudge, but shift relationship
                    entities:shift_relationship(other.id, focal.id, "respect", 5)
                end
            end
        elseif ctx.type == "gratitude" then
            if ctx.response == "accept" then
                entities:shift_relationship(other.id, focal.id, "trust", 8)
                if other.components.memory then
                    MemLib.add_debt(other.components.memory, focal.id, "accepted my gratitude", -10)
                end
            elseif ctx.response == "call_favor" then
                -- Debt reduced, you used it
                if other.components.memory then
                    MemLib.add_debt(other.components.memory, focal.id, "called in the favor", -20)
                end
            end
        elseif ctx.type == "warning" then
            -- Warning approaches strengthen the bond
            entities:shift_relationship(focal.id, other.id, "trust", 5)
        end
    end)

    --------------------------------------------------------------------------
    -- REPUTATION → INTERACTION AVAILABILITY
    -- Your pattern reputation gates certain interactions.
    --------------------------------------------------------------------------

    engine:on("GET_INTERACTIONS", function(req)
        if not req or not req.interactions then return end

        local patterns = engine:get_module("patterns")
        if not patterns then return end

        local gs = engine.game_state
        local rep = patterns:get_reputation_label(gs)
        local dominant, count = patterns:get_dominant_axis(gs)

        if not dominant or count < 3 then return end

        -- Add reputation-unlocked interactions
        local bonus = {}

        if dominant == "mercy" and count >= 5 then
            table.insert(bonus, {
                id = "appeal_to_mercy",
                label = "Appeal to their better nature",
                description = "Your reputation gives weight to your words.",
                category = "diplomatic",
            })
        end

        if dominant == "cruelty" and count >= 5 then
            table.insert(bonus, {
                id = "reputation_intimidate",
                label = "Let your reputation speak",
                description = "They know what you've done. You don't need to say a word.",
                category = "hostile",
            })
        end

        if dominant == "diplomacy" and count >= 5 then
            table.insert(bonus, {
                id = "broker_peace",
                label = "Broker a peace",
                description = "Your word carries weight between opposing sides.",
                category = "diplomatic",
            })
        end

        if dominant == "scheming" and count >= 5 then
            table.insert(bonus, {
                id = "plant_suspicion",
                label = "Plant suspicion",
                description = "Turn their paranoia against them. You've learned from experience.",
                category = "espionage",
            })
        end

        for _, b in ipairs(bonus) do
            table.insert(req.interactions, b)
        end
    end)

    --------------------------------------------------------------------------
    -- ARCS → BIOGRAPHY
    -- Relationship arcs feed into the biography system.
    --------------------------------------------------------------------------

    engine:on("NEW_YEAR", function(clock)
        local arcs = engine:get_module("arcs")
        local biography = engine:get_module("biography")
        if not arcs or not biography then return end

        local entities = engine:get_module("entities")
        local focal = entities and entities:get_focus()
        if not focal then return end

        local all_arcs = arcs:get_all_arcs()
        for _, entry in ipairs(all_arcs) do
            if entry.arc and entry.arc.interaction_count >= 5 then
                -- Significant relationships become biography entries
                local other = entities:get(entry.entity_id)
                local name = other and other.name or "someone"
                biography:add_entry(focal.id, {
                    type = "relationship",
                    text = entry.arc.summary,
                    subject = name,
                    arc_shape = entry.arc.arc_shape,
                    year = clock.year,
                })
            end
        end
    end)
end

return Bridge
