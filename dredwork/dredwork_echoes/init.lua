-- dredwork Echoes — Consequence Echo System
-- Your past choices return as narrative scenes. Months later. When you've forgotten.
-- The game remembers what you did and shows you what it became.
--
-- Not stat changes. Not tooltips. SCENES with characters who were affected.
-- "My family survived because of you."
-- "I've been looking for you. You know why."

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Echoes = {}
Echoes.__index = Echoes

function Echoes.init(engine)
    local self = setmetatable({}, Echoes)
    self.engine = engine

    engine.game_state.echoes = {
        planted = {},    -- seeds: choices that WILL echo back
        triggered = {},  -- echoes that have fired (history)
    }

    -- Plant echo seeds when significant events happen
    engine:on("DECISION_RESOLVED", function(ctx)
        if ctx and ctx.option then
            self:plant_from_decision(ctx, engine.game_state)
        end
    end)

    engine:on("INTERACTION_PERFORMED", function(ctx)
        if ctx then
            self:plant_from_interaction(ctx, engine.game_state)
        end
    end)

    engine:on("CLAIM_REVEALED", function(ctx)
        if ctx then
            self:plant_from_claim(ctx, engine.game_state)
        end
    end)

    engine:on("HAPPENING_RESOLVED", function(ctx)
        if ctx then
            self:plant_from_happening(ctx, engine.game_state)
        end
    end)

    -- Check for ripe echoes monthly
    engine:on("NEW_MONTH", function(clock)
        self:check_echoes(engine.game_state, clock)
    end)

    return self
end

--------------------------------------------------------------------------------
-- PLANTING: Record choices that will echo back
--------------------------------------------------------------------------------

--- Plant an echo seed from a decision.
function Echoes:plant_from_decision(ctx, gs)
    local day = gs.clock and gs.clock.total_days or 0
    local option = ctx.option

    if not option or not option.tags then return end

    local seed = {
        source = "decision",
        decision_id = ctx.decision and ctx.decision.id,
        option_id = option.id,
        option_label = option.label,
        tags = option.tags,
        day_planted = day,
        min_delay = 60,   -- at least 2 months before echoing
        max_delay = 300,  -- at most 10 months
        echo_day = day + RNG.range(60, 300),
        fired = false,
    }

    -- Determine echo type from tags
    for _, tag in ipairs(option.tags) do
        if tag == "merciful_act" then
            seed.echo_type = "gratitude"
            seed.echo_texts = {
                stranger = {
                    "A stranger stops you in the street. You don't recognize them. They recognize you.",
                    "\"You probably don't remember,\" they say. \"But I do. What you did — it mattered.\"",
                },
                named = {
                    "Someone you helped once appears at your door. They're different now. Stronger.",
                    "\"I came back because of what you did for me. I owe you a life.\"",
                },
            }
            seed.consequences = {
                { type = "need", need = "purpose", delta = 8 },
                { type = "need", need = "belonging", delta = 5 },
                { type = "relationship_new", rel_type = "gratitude", strength = 40 },
            }
        elseif tag == "cruel_act" then
            seed.echo_type = "revenge"
            seed.echo_texts = {
                stranger = {
                    "You feel eyes on your back. You turn. A face you don't know, wearing an expression you do: hatred.",
                    "A figure blocks your path. \"Remember what you did? I do. Every day.\"",
                },
                named = {
                    "They found you. You always knew they would. The look on their face says everything.",
                    "\"I've been waiting for this moment. Planning it. Do you know how long?\"",
                },
            }
            seed.consequences = {
                { type = "need", need = "safety", delta = -10 },
                { type = "grudge_against_you", intensity = 50 },
            }
        elseif tag == "warfare" then
            seed.echo_type = "aftermath"
            seed.echo_texts = {
                stranger = {
                    "A soldier — missing an arm. They don't salute. They stare. \"Was it worth it?\"",
                    "A widow at the temple. She's lighting candles. One for each name. Your order put those names there.",
                },
            }
            seed.consequences = {
                { type = "need", need = "purpose", delta = -3 },
            }
        elseif tag == "diplomacy" then
            seed.echo_type = "alliance_fruit"
            seed.echo_texts = {
                stranger = {
                    "A merchant approaches with an offer. \"Your reputation precedes you. I was told you're someone who can be trusted.\"",
                    "An envoy arrives with gifts. \"The peace you brokered — it held. My people remember.\"",
                },
            }
            seed.consequences = {
                { type = "need", need = "status", delta = 5 },
                { type = "gold", delta = 15 },
            }
        elseif tag == "espionage" then
            seed.echo_type = "exposure"
            seed.echo_texts = {
                stranger = {
                    "A sealed letter. No name. Inside: a list of your recent movements. Someone has been watching the watcher.",
                    "\"You're clever,\" says a voice from behind you. \"But so am I. And I've been at this longer.\"",
                },
            }
            seed.consequences = {
                { type = "need", need = "safety", delta = -8 },
                { type = "suspicion", delta = 10 },
            }
        end
    end

    if seed.echo_type then
        table.insert(gs.echoes.planted, seed)
    end
end

--- Plant an echo from an interaction.
function Echoes:plant_from_interaction(ctx, gs)
    local day = gs.clock and gs.clock.total_days or 0

    -- Only plant for significant interactions
    local significant = {
        enslave = true, free_person = true, betray = true, forgive = true,
        blackmail = true, gift_item = true, challenge_duel = true, exile = true,
    }
    if not significant[ctx.interaction] then return end

    local seed = {
        source = "interaction",
        interaction_id = ctx.interaction,
        target_name = ctx.target_name,
        target_id = ctx.target_id,
        day_planted = day,
        echo_day = day + RNG.range(90, 360),
        fired = false,
    }

    if ctx.interaction == "enslave" then
        seed.echo_type = "slave_echo"
        seed.echo_texts = {
            "Years later, a face from the past. Older. Harder. The chains are gone but the marks remain.",
            "A child approaches you. \"You owned my parent. I wanted to see what kind of person does that.\"",
        }
        seed.consequences = {
            { type = "need", need = "safety", delta = -15 },
            { type = "need", need = "belonging", delta = -5 },
        }
    elseif ctx.interaction == "free_person" then
        seed.echo_type = "freedom_echo"
        seed.echo_texts = {
            (ctx.target_name or "Someone") .. " returns. Free. Changed. They built a life from the ashes of what you gave back.",
            "A gift arrives. No note. But you recognize the style. " .. (ctx.target_name or "They") .. " remembered.",
        }
        seed.consequences = {
            { type = "need", need = "purpose", delta = 10 },
            { type = "gold", delta = 20 },
        }
    elseif ctx.interaction == "betray" then
        seed.echo_type = "betrayal_echo"
        seed.echo_texts = {
            "The person you betrayed hasn't forgotten. They've been building something. You can feel it closing in.",
            "A warning scratched into your door overnight. One word: \"Soon.\"",
        }
        seed.consequences = {
            { type = "need", need = "safety", delta = -15 },
            { type = "suspicion", delta = 5 },
        }
    elseif ctx.interaction == "forgive" then
        seed.echo_type = "forgiveness_echo"
        seed.echo_texts = {
            "The person you forgave is different now. They carry themselves like someone who was given a second chance and chose not to waste it.",
            (ctx.target_name or "They") .. " sought you out. \"I never thanked you properly. For choosing mercy when you didn't have to.\"",
        }
        seed.consequences = {
            { type = "need", need = "belonging", delta = 8 },
            { type = "need", need = "purpose", delta = 5 },
        }
    elseif ctx.interaction == "blackmail" then
        seed.echo_type = "blackmail_echo"
        seed.echo_texts = {
            "Someone leaves evidence on your pillow. Not of their secret — of YOUR secret. The tables have turned.",
            (ctx.target_name or "They") .. " smiles at you now. The wrong kind of smile. They found leverage of their own.",
        }
        seed.consequences = {
            { type = "need", need = "safety", delta = -10 },
            { type = "suspicion", delta = 8 },
        }
    end

    if seed.echo_type then
        table.insert(gs.echoes.planted, seed)
    end
end

--- Plant an echo from a claim reveal.
function Echoes:plant_from_claim(ctx, gs)
    local day = gs.clock and gs.clock.total_days or 0

    if ctx.reaction == "supporter" then
        table.insert(gs.echoes.planted, {
            source = "claim", echo_type = "supporter_returns",
            target_name = ctx.target_name, target_id = ctx.target_id,
            day_planted = day, echo_day = day + RNG.range(45, 180), fired = false,
            echo_texts = {
                (ctx.target_name or "Your supporter") .. " has been working. Quietly. When they speak now, others listen. Your name carries further than it did.",
                "A message: \"I've found two others who believe. When you're ready, so are we.\"",
            },
            consequences = {
                { type = "need", need = "status", delta = 8 },
                { type = "need", need = "purpose", delta = 5 },
            },
        })
    elseif ctx.reaction == "hostile" then
        table.insert(gs.echoes.planted, {
            source = "claim", echo_type = "betrayer_moves",
            target_name = ctx.target_name, target_id = ctx.target_id,
            day_planted = day, echo_day = day + RNG.range(30, 120), fired = false,
            echo_texts = {
                "The person you trusted with your secret — they talked. You can feel the net tightening.",
                "Guards have been asking about a stranger matching your description. " .. (ctx.target_name or "Someone") .. " gave them that description.",
            },
            consequences = {
                { type = "suspicion", delta = 20 },
                { type = "need", need = "safety", delta = -15 },
            },
        })
    end
end

--- Plant from a happening response.
function Echoes:plant_from_happening(ctx, gs)
    local day = gs.clock and gs.clock.total_days or 0

    -- Only specific happening responses echo
    if ctx.option_id == "feed_them" or ctx.option_id == "adopt" then
        table.insert(gs.echoes.planted, {
            source = "happening", echo_type = "kindness_remembered",
            day_planted = day, echo_day = day + RNG.range(60, 240), fired = false,
            echo_texts = {
                "A face you almost forgot. They're healthier now. They brought something — bread, wrapped carefully. \"You shared with me once.\"",
                "Someone left flowers at your door. You don't know who. But you remember a cold morning and a hungry stranger.",
            },
            consequences = {
                { type = "need", need = "belonging", delta = 8 },
                { type = "need", need = "comfort", delta = 3 },
            },
        })
    elseif ctx.option_id == "loot" then
        table.insert(gs.echoes.planted, {
            source = "happening", echo_type = "theft_witnessed",
            day_planted = day, echo_day = day + RNG.range(30, 150), fired = false,
            echo_texts = {
                "Someone saw you that night. During the fire. They've been telling people. The story is growing.",
                "A vendor refuses to serve you. \"I know what you did when the market burned. Everyone does.\"",
            },
            consequences = {
                { type = "need", need = "belonging", delta = -10 },
                { type = "need", need = "status", delta = -5 },
            },
        })
    end
end

--------------------------------------------------------------------------------
-- CHECKING: Fire ripe echoes
--------------------------------------------------------------------------------

function Echoes:check_echoes(gs, clock)
    local day = clock and clock.total_days or 0
    local entities = self.engine:get_module("entities")
    local focal = entities and entities:get_focus()

    for i = #gs.echoes.planted, 1, -1 do
        local seed = gs.echoes.planted[i]
        if not seed.fired and day >= seed.echo_day then
            -- Fire the echo
            seed.fired = true
            table.remove(gs.echoes.planted, i)

            local text_pool = seed.echo_texts
            local text
            if type(text_pool) == "table" then
                if text_pool.named and seed.target_id and entities and entities:get(seed.target_id) then
                    text = RNG.pick(text_pool.named)
                elseif text_pool.stranger then
                    text = RNG.pick(text_pool.stranger)
                else
                    text = RNG.pick(text_pool)
                end
            end
            text = text or "Something from your past catches up to you."

            table.insert(gs.echoes.triggered, {
                echo_type = seed.echo_type,
                source = seed.source,
                text = text,
                day_planted = seed.day_planted,
                day_triggered = day,
                delay = day - seed.day_planted,
            })

            if focal and seed.consequences then
                for _, c in ipairs(seed.consequences) do
                    if c.type == "need" and focal.components.needs then
                        focal.components.needs[c.need] = Math.clamp(
                            (focal.components.needs[c.need] or 50) + (c.delta or 0), 0, 100)
                    elseif c.type == "suspicion" and gs.claim then
                        gs.claim.suspicion = Math.clamp((gs.claim.suspicion or 0) + (c.delta or 0), 0, 100)
                    elseif c.type == "gold" and focal.components.personal_wealth then
                        local WealthLib = require("dredwork_agency.wealth")
                        WealthLib.change(focal.components.personal_wealth, c.delta or 0, "echo from the past")
                    elseif c.type == "grudge_against_you" and focal then
                        local names = require("dredwork_core.names")
                        local new_entity = entities:create({
                            type = "person", name = names.character(),
                            components = {
                                personality = { PER_BLD = RNG.range(40, 70), PER_CRM = RNG.range(40, 70), PER_LOY = RNG.range(20, 50) },
                                location = focal.components.location,
                                memory = require("dredwork_agency.memory").create(),
                            },
                            tags = { "echo_character" },
                        })
                        if new_entity then
                            local MemLib = require("dredwork_agency.memory")
                            MemLib.add_grudge(new_entity.components.memory, focal.id, "what you did to my family", c.intensity or 50)
                            entities:add_relationship(new_entity.id, focal.id, "grudge", c.intensity or 50)
                        end
                    end
                end
            end

            self.engine:emit("ECHO_FIRED", {
                echo_type = seed.echo_type,
                text = text,
                delay_days = day - seed.day_planted,
            })
            self.engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = text,
                priority = 70,
                display_hint = "echo",
                tags = { "echo", seed.echo_type },
                timestamp = day,
            })

            self.engine.log:info("Echo: %s (planted %d days ago)", seed.echo_type, day - seed.day_planted)

            -- Only fire one echo per month (don't overwhelm)
            return
        end
    end
end

function Echoes:get_planted_count()
    return #self.engine.game_state.echoes.planted
end

function Echoes:get_triggered()
    return self.engine.game_state.echoes.triggered
end

function Echoes:serialize() return self.engine.game_state.echoes end
function Echoes:deserialize(data) self.engine.game_state.echoes = data end

return Echoes
