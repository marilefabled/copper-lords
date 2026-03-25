-- dredwork Living World — The Room Is Already Happening
-- You walk into a scene in progress. NPCs are DOING things.
-- You overhear conversations. Your dog reacts.
-- The world doesn't start when you arrive — you interrupt it.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Living = {}
Living.__index = Living

function Living.init(engine)
    local self = setmetatable({}, Living)
    self.engine = engine
    return self
end

--------------------------------------------------------------------------------
-- NPC ACTIVITY LINES
-- What is this person DOING when you walk in?
-- Generated from: action, mood, personality, plan, relationships, location
--------------------------------------------------------------------------------

--- Generate an activity description for an entity at a location.
---@param entity table Entity with components
---@param location_type string Where they are
---@return string|nil Prose description of what they're doing
function Living:describe_activity(entity, location_type)
    if not entity or not entity.components then return nil end

    local name = entity.name or "Someone"
    local agenda = entity.components.agenda or {}
    local action = agenda.current_action
    local mood = entity.components.mood
    if type(mood) ~= "string" then mood = "calm" end
    local pers = entity.components.personality or {}
    local bld = pers.PER_BLD or 50; if type(bld) == "table" then bld = bld.value or 50 end
    local loy = pers.PER_LOY or 50; if type(loy) == "table" then loy = loy.value or 50 end
    local crm = pers.PER_CRM or 50; if type(crm) == "table" then crm = crm.value or 50 end
    local obs = pers.PER_OBS or 50; if type(obs) == "table" then obs = obs.value or 50 end

    -- Action-specific descriptions (varied by mood and personality)
    local pool = {}

    if action == "earn_gold" then
        if location_type == "market" then
            pool = {
                name .. " is haggling with a vendor. Hands moving fast. The deal matters.",
                name .. " is counting coins at a corner stall. Their lips move with each one.",
            }
        else
            pool = {
                name .. " is busy with something. Money, by the look of it.",
                name .. " is working. Head down. Purpose in every movement.",
            }
        end
    elseif action == "scheme" then
        if crm > 55 then
            pool = {
                name .. " is speaking in low tones with someone you don't recognize. They stop when they see you.",
                name .. " is reading a letter. They fold it quickly when you approach.",
            }
        else
            pool = {
                name .. " is sitting alone, thinking. The kind of thinking that plans something.",
                name .. " glances around the room before settling into a corner. Waiting for someone.",
            }
        end
    elseif action == "raid" or action == "train_troops" then
        pool = {
            name .. " is drilling with a blade. Each swing deliberate. Practiced.",
            name .. " is inspecting weapons. Testing edges with a thumb.",
            name .. " is sparring. Losing, but learning.",
        }
    elseif action == "pray" then
        pool = {
            name .. " is kneeling. Lips moving silently. Whatever they're asking for, it matters.",
            name .. " stands before the altar. Still. The kind of still that comes from either peace or desperation.",
        }
    elseif action == "visit_ally" or action == "gift" then
        pool = {
            name .. " is deep in conversation. Leaning in. The kind of talk that builds something.",
            name .. " is laughing with someone. Genuine. The sound is rare enough to notice.",
        }
    elseif action == "research" then
        pool = {
            name .. " is bent over documents. Scratching notes. Lost in thought.",
            name .. " is examining something — turning it over in their hands, studying it from every angle.",
        }
    elseif action == "fortify" then
        pool = {
            name .. " is checking the walls. Running a hand along the stone. Looking for weakness.",
            name .. " is directing workers. Pointing at cracks. Making lists.",
        }
    elseif action == "trade" then
        pool = {
            name .. " is negotiating with a merchant. The merchant looks uncomfortable.",
            name .. " is loading goods onto a cart. Business, from the look of it.",
        }
    elseif action == "patrol" or action == "guard" then
        pool = {
            name .. " is standing watch. Eyes moving. Alert.",
            name .. " paces slowly. Scanning the room. A habit, not a choice.",
        }
    elseif action == "rest" or action == "idle" then
        -- Mood colors idle time
        if mood == "desperate" or mood == "anxious" then
            pool = {
                name .. " is sitting alone. Staring at nothing. The kind of quiet that worries you.",
                name .. " is fidgeting. Can't settle. Something is eating at them.",
            }
        elseif mood == "bitter" then
            pool = {
                name .. " is drinking. Not for pleasure. For forgetting.",
                name .. " sits with arms crossed. Watching everyone. Trusting no one.",
            }
        elseif mood == "content" or mood == "hopeful" then
            pool = {
                name .. " is relaxed. Actually relaxed. You don't see that often here.",
                name .. " is humming something. The sound is small but it fills the space.",
            }
        elseif mood == "determined" then
            pool = {
                name .. " is sharpening something. A blade, a quill — the action is the same. Preparation.",
                name .. " is writing. Fast. Whatever it is, it can't wait.",
            }
        else
            pool = {
                name .. " is here. Waiting, maybe. Or just existing between the things that matter.",
                name .. " is watching the room. Not looking for anything. Just watching.",
            }
        end
    end

    -- Fallback: mood + personality-driven idle description
    if #pool == 0 then
        if bld > 65 then
            pool = {
                name .. " stands tall. Takes up space. Doesn't apologize for it.",
                name .. " is here, and everyone knows it. The room adjusts around them.",
            }
        elseif loy > 65 then
            pool = {
                name .. " is talking to someone. Listening, mostly. They're good at that.",
                name .. " nods to you as you enter. A small thing. It means more than it should.",
            }
        elseif crm > 60 then
            pool = {
                name .. " is in the shadows. Not hiding — choosing. They see you before you see them.",
                name .. " watches from a corner. Calculating something.",
            }
        elseif obs > 60 then
            pool = {
                name .. " is studying the room. Every detail. You wonder what they see that you don't.",
                name .. " notices you immediately. They notice everything.",
            }
        else
            pool = {
                name .. " is here.",
                name .. " is occupied with something you can't quite make out.",
            }
        end
    end

    -- Plan modifier: if they have an active plan, add a subtle hint
    local plan = agenda.active_plan
    if plan and plan.template_id and RNG.chance(0.3) then
        local plan_hints = {
            coup = " There's an edge to them lately. Something behind the eyes.",
            alliance = " They've been making friends. More than usual.",
            revenge = " They haven't forgotten. You can tell by the way they hold themselves.",
            wealth = " Everything they do has a price tag. Every gesture is an investment.",
            subversion = " They're up to something. The smile doesn't reach their eyes.",
            piety = " They've been spending more time at the temple. Something weighs on them.",
            fortification = " They've been cautious lately. Checking exits. Counting guards.",
            knowledge = " They've been reading. Asking questions. Hungry for something.",
        }
        local hint = plan_hints[plan.template_id]
        if hint then
            local base = RNG.pick(pool)
            return base .. hint
        end
    end

    return RNG.pick(pool)
end

--------------------------------------------------------------------------------
-- OVERHEARD FRAGMENTS
-- NPCs at a location talking to each other about sim state.
-- Signal-gated: you only understand what your perception allows.
--------------------------------------------------------------------------------

--- Generate an overheard conversation fragment at a location.
---@param location_type string
---@param gs table game_state
---@param entity_names table Array of NPC names at this location
---@param focal table The focal entity (for signal gating)
---@return table|nil { text, domain, speakers }
function Living:overhear(location_type, gs, entity_names, focal)
    if #entity_names < 2 then return nil end
    -- 35% chance of overhearing something
    if not RNG.chance(0.35) then return nil end

    local a = RNG.pick(entity_names)
    local b = RNG.pick(entity_names)
    while b == a and #entity_names > 1 do b = RNG.pick(entity_names) end

    local fragments = {}

    -- ECONOMY fragments
    if gs.markets or (gs.economy and gs.economy.treasury) then
        local food_high = false
        if gs.markets then
            for _, m in pairs(gs.markets) do
                if m.prices and m.prices.food and m.prices.food > 12 then food_high = true end
            end
        end
        if food_high then
            table.insert(fragments, {
                text = a .. " to " .. b .. ": \"Have you seen the price of bread? My children ate once yesterday. Once.\"",
                domain = "economy",
            })
            table.insert(fragments, {
                text = "You catch " .. a .. " and " .. b .. " arguing about grain shipments. The numbers don't add up. Someone's skimming.",
                domain = "economy",
            })
        end
        if gs.economy and (gs.economy.treasury or 0) > 300 then
            table.insert(fragments, {
                text = a .. " mentions surplus gold to " .. b .. ". \"The coffers are full. Question is — who benefits?\"",
                domain = "economy",
            })
        end
    end

    -- POLITICS fragments
    if gs.politics then
        if (gs.politics.unrest or 0) > 40 then
            table.insert(fragments, {
                text = a .. " whispers to " .. b .. ": \"People are angry. Not the kind of angry that passes.\"",
                domain = "politics",
            })
            table.insert(fragments, {
                text = "\"The streets aren't safe,\" " .. a .. " tells " .. b .. ". \"Not because of criminals. Because of everyone else.\"",
                domain = "politics",
            })
        end
        if (gs.politics.legitimacy or 50) < 30 then
            table.insert(fragments, {
                text = a .. " and " .. b .. " are talking about the ruler. Not with respect.",
                domain = "politics",
            })
        end
        if (gs.politics.legitimacy or 50) > 75 then
            table.insert(fragments, {
                text = a .. " raises a cup to " .. b .. ". \"To the crown. Whatever else is wrong, the throne holds.\"",
                domain = "politics",
            })
        end
    end

    -- MILITARY fragments
    if gs.military then
        if (gs.military.total_power or 0) < 40 then
            table.insert(fragments, {
                text = a .. " to " .. b .. ": \"The barracks are half-empty. If they come now...\" The sentence finishes itself.",
                domain = "military",
            })
        end
        if (gs.military.at_war) then
            table.insert(fragments, {
                text = "\"My brother is at the front,\" " .. a .. " tells " .. b .. ". The silence after says everything.",
                domain = "military",
            })
        end
    end

    -- CRIME fragments (corruption-aware — reflects the world the player created)
    if gs.underworld and (gs.underworld.global_corruption or 0) > 30 then
        table.insert(fragments, {
            text = a .. " leans close to " .. b .. ". You catch a word: \"payment.\" Another: \"tonight.\" They notice you listening and stop.",
            domain = "crime",
        })
        if location_type == "tavern" then
            table.insert(fragments, {
                text = "\"Everyone has a price,\" " .. a .. " says to " .. b .. ". " .. b .. " doesn't argue.",
                domain = "crime",
            })
        end
        -- Higher corruption = more specific fragments
        if (gs.underworld.global_corruption or 0) > 50 then
            table.insert(fragments, {
                text = "\"Three break-ins this week,\" " .. b .. " says. " .. a .. " shrugs. \"It's getting worse.\" Neither says why.",
                domain = "crime",
            })
            table.insert(fragments, {
                text = a .. " to " .. b .. ": \"Remember when you could walk home at night?\" A pause. \"No. I don't either.\"",
                domain = "crime",
            })
            if location_type == "market" then
                table.insert(fragments, {
                    text = "A vendor checks under his stall. Twice. " .. a .. " watches. \"He used to trust the crowd,\" " .. a .. " murmurs to " .. b .. ".",
                    domain = "crime",
                })
            end
        end
    end

    -- TERROR fragments (if justice is harsh — reflects cruelty consequences)
    if gs.justice and (gs.justice.terror_score or 0) > 40 then
        table.insert(fragments, {
            text = a .. " and " .. b .. " talk in whispers. Not because it's secret. Because everything is whispers now.",
            domain = "politics",
        })
        if (gs.justice.terror_score or 0) > 60 then
            table.insert(fragments, {
                text = "\"Did you hear about—\" " .. a .. " starts. " .. b .. " grabs their arm. \"Don't.\" The conversation dies.",
                domain = "politics",
            })
        end
    end

    -- RELIGION fragments
    if gs.religion and gs.religion.active_faith then
        local attrs = gs.religion.active_faith.attributes or {}
        if (attrs.zeal or 0) > 60 then
            table.insert(fragments, {
                text = a .. " and " .. b .. " are debating scripture. It doesn't sound like a debate anymore. It sounds like a trial.",
                domain = "religion",
            })
        end
        if (gs.religion.diversity or 0) > 40 then
            table.insert(fragments, {
                text = "\"They pray differently in the eastern quarter,\" " .. a .. " mentions to " .. b .. ". The tone is careful. Too careful.",
                domain = "religion",
            })
        end
    end

    -- PERIL fragments
    if gs.peril and gs.peril.active_threats then
        for _, threat in ipairs(gs.peril.active_threats) do
            if threat.type == "disease" then
                table.insert(fragments, {
                    text = a .. " coughs. " .. b .. " steps back. Neither pretends it's nothing.",
                    domain = "peril",
                })
            elseif threat.type == "drought" or threat.type == "famine" then
                table.insert(fragments, {
                    text = "\"The well is lower than I've ever seen,\" " .. a .. " tells " .. b .. ". \"My grandfather says the same.\"",
                    domain = "nature",
                })
            end
        end
    end

    -- CLAIM fragments (if your claim is known)
    if gs.claim and gs.claim.status and gs.claim.status ~= "hidden" then
        table.insert(fragments, {
            text = a .. " and " .. b .. " fall silent when you pass. You catch your name — or what might be your name — as you walk away.",
            domain = "secrets",
        })
    end

    if #fragments == 0 then return nil end

    -- Signal gate: filter by focal entity's perception affinity
    local affinity = focal and focal.components and focal.components.signal_affinity
    if affinity then
        local gated = {}
        for _, f in ipairs(fragments) do
            local domain_score = affinity[f.domain] or 30
            if domain_score > 25 or RNG.chance(0.15) then
                table.insert(gated, f)
            end
        end
        if #gated > 0 then
            fragments = gated
        end
    end

    local picked = RNG.pick(fragments)
    return {
        text = picked.text,
        domain = picked.domain,
        speakers = { a, b },
    }
end

--------------------------------------------------------------------------------
-- PET MICRO-EVENTS
-- Shadow doesn't just sit there. Shadow LIVES.
--------------------------------------------------------------------------------

--- Generate a pet micro-event based on world state, location, and pet state.
---@param pet table Pet data from gs.animals.pets
---@param location_type string Where the player is
---@param gs table game_state
---@return table|nil { text, effect }
function Living:pet_moment(pet, location_type, gs)
    if not pet or pet.is_dead then return nil end
    -- 25% chance per location visit
    if not RNG.chance(0.25) then return nil end

    local name = pet.name or "Your companion"
    local species = pet.species_key or "pet"
    local moments = {}

    -- HOME: domestic moments
    if location_type == "home" then
        moments = {
            { text = name .. " is waiting at the door when you arrive. Tail wagging. They always know.",
              effect = { need = "belonging", delta = 2 } },
            { text = name .. " is curled by the fire. One eye opens when you enter. Satisfied you're home, they close it again.",
              effect = { need = "comfort", delta = 2 } },
            { text = name .. " brings you something — a scrap of leather, a bone. A gift. Their eyes watch to see if you're pleased.",
              effect = { need = "belonging", delta = 1 } },
        }
        -- Guarding behavior
        if species == "hound" then
            table.insert(moments, {
                text = name .. " growls at the window. Low. Serious. Something passed outside that " .. name .. " didn't like.",
                effect = { need = "safety", delta = 1 },
            })
        end
        -- Pest reaction
        if gs.animals and gs.animals.regional_populations then
            for _, pops in pairs(gs.animals.regional_populations) do
                if pops.rats and (pops.rats.density or 0) > 30 and (species == "cat" or species == "hound") then
                    table.insert(moments, {
                        text = name .. " drops a dead rat at your feet. Looks up at you. Proud. Disgusting and wonderful.",
                        effect = { need = "comfort", delta = 1 },
                    })
                    break
                end
            end
        end
    end

    -- WILDS: hunting and instinct
    if location_type == "wilds" then
        moments = {
            { text = name .. " freezes. Ears forward. Something in the undergrowth. Then they relax. False alarm.",
              effect = nil },
            { text = name .. " finds a trail and follows it. You lose sight of them for a moment. Your heart catches. Then they're back.",
              effect = { need = "safety", delta = -1 } },
        }
        if species == "hound" or species == "exotic_falcon" then
            table.insert(moments, {
                text = name .. " flushes something from the brush. A bird, a rabbit — gone before you can react. " .. name .. " looks disappointed.",
                effect = nil,
            })
        end
        -- Wildlife danger reaction
        if gs.animals and gs.animals.regional_populations then
            for _, pops in pairs(gs.animals.regional_populations) do
                if pops.wolves and (pops.wolves.density or 0) > 40 then
                    table.insert(moments, {
                        text = name .. " presses against your leg. Hackles up. The wolves are close — " .. name .. " can smell them even if you can't.",
                        effect = { need = "safety", delta = -2 },
                    })
                    break
                end
            end
        end
    end

    -- MARKET: social moments
    if location_type == "market" then
        moments = {
            { text = "A child reaches for " .. name .. ". " .. name .. " lets them. For a moment, the market is just a child and a dog.",
              effect = { need = "belonging", delta = 1 } },
            { text = name .. " sniffs a vendor's stall with deep interest. The vendor watches nervously.",
              effect = nil },
        }
    end

    -- COURT: out of place
    if location_type == "court" then
        moments = {
            { text = name .. " sits at your feet. Perfectly still. More dignified than half the courtiers.",
              effect = { need = "status", delta = 1 } },
            { text = "Someone looks at " .. name .. " with distaste. " .. name .. " looks back without blinking. You win that one.",
              effect = nil },
        }
    end

    -- TAVERN: uncomfortable
    if location_type == "tavern" then
        moments = {
            { text = name .. " growls at a man by the door. The man moves. " .. name .. " has better instincts than you do.",
              effect = { need = "safety", delta = 1 } },
            { text = name .. " steals food from under a table. You pretend you didn't see.",
              effect = nil },
        }
    end

    -- TEMPLE: quiet
    if location_type == "temple" then
        moments = {
            { text = name .. " lies down. Quiet. Even animals know when a place is sacred.",
              effect = { need = "comfort", delta = 1 } },
        }
    end

    -- Mood-reactive moments (any location)
    local focal = self.engine:get_module("entities")
    focal = focal and focal:get_focus()
    if focal then
        local player_mood = focal.components.mood
        if type(player_mood) ~= "string" then player_mood = "calm" end

        if player_mood == "desperate" or player_mood == "grieving" then
            table.insert(moments, {
                text = name .. " pushes their head under your hand. They don't understand what's wrong. They just know something is.",
                effect = { need = "belonging", delta = 3 },
            })
        elseif player_mood == "anxious" then
            table.insert(moments, {
                text = name .. " is restless too. Pacing. Mirrors your energy. You didn't realize how tense you were until you saw it in them.",
                effect = { need = "comfort", delta = 1 },
            })
        elseif player_mood == "triumphant" then
            table.insert(moments, {
                text = name .. " senses your mood. Jumps. Spins. The purest celebration you'll see today.",
                effect = { need = "belonging", delta = 2 },
            })
        end
    end

    -- Stranger reaction (someone with a grudge against you)
    if focal and focal.components and focal.components.memory then
        local mem = focal.components.memory
        if mem.grudges and #mem.grudges > 0 and species == "hound" then
            -- Check if any grudge-holder is at this location
            table.insert(moments, {
                text = name .. " growls at someone across the room. Not barking — just a low, steady warning. They know something you don't. Trust the dog.",
                effect = { need = "safety", delta = -1 },
            })
        end
    end

    -- Pet health-based moments
    if (pet.health or 100) < 40 then
        table.insert(moments, {
            text = name .. " moves slowly today. Stiff. " .. name .. " tries to hide it, but you can tell.",
            effect = { need = "comfort", delta = -2 },
        })
    end

    if (pet.loyalty or 50) > 85 then
        table.insert(moments, {
            text = name .. " follows your gaze. Watches what you watch. You've been together long enough that words aren't necessary.",
            effect = { need = "belonging", delta = 1 },
        })
    end

    if #moments == 0 then return nil end

    return RNG.pick(moments)
end

function Living:serialize() return {} end
function Living:deserialize(data) end

return Living
