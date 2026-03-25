-- The Ripple — Agency Bridge
-- NPCs take autonomous actions that create problems for the player.
-- The world doesn't wait. Court members scheme, rivals investigate, allies act.
-- This is the bridge between NPC simulation state and player-facing consequences.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    --------------------------------------------------------------------------
    -- NPC AUTONOMOUS ACTIONS (monthly tick)
    -- Court members, rivals, and known NPCs take initiative
    --------------------------------------------------------------------------

    engine:on("NEW_MONTH", function(clock)
        local entities = engine:get_module("entities")
        if not entities then return end
        local focal = entities:get_focus()
        if not focal then return end

        local gs = engine.game_state
        local day = clock and clock.total_days or 0

        -- Only fire after the first month (let the player settle in)
        if day < 30 then return end

        -- Gather NPCs who might act
        local actors = {}
        for _, entity in pairs(gs.entities.registry) do
            if not entity.alive then goto skip end
            if entity.id == focal.id then goto skip end
            if entity.type ~= "person" then goto skip end
            table.insert(actors, entity)
            ::skip::
        end

        if #actors == 0 then return end

        -- Each NPC has a small chance to take an autonomous action
        local actions_this_month = 0
        local max_actions = 2  -- cap visible NPC actions per month

        for _, npc in ipairs(actors) do
            if actions_this_month >= max_actions then break end

            local action = Bridge._pick_npc_action(npc, focal, gs, engine)
            if action then
                actions_this_month = actions_this_month + 1

                -- Emit as narrative beat
                engine:emit("NARRATIVE_BEAT", {
                    channel = "whispers",
                    text = action.text,
                    priority = action.priority or 58,
                    display_hint = action.hint or "encounter",
                    tags = action.tags or { "npc_agency" },
                    timestamp = day,
                })
                engine:push_ui_event("NARRATIVE_BEAT", {
                    channel = "whispers",
                    text = action.text,
                    priority = action.priority or 58,
                    display_hint = action.hint or "encounter",
                })

                -- Apply consequences
                if action.suspicion_delta then
                    gs.claim.suspicion = Math.clamp(
                        (gs.claim.suspicion or 0) + action.suspicion_delta, 0, 100)
                end
                if action.need_effects and focal.components.needs then
                    for need, delta in pairs(action.need_effects) do
                        focal.components.needs[need] = Math.clamp(
                            (focal.components.needs[need] or 50) + delta, 0, 100)
                    end
                end

                -- Some actions inject happenings
                if action.happening_def then
                    engine:emit("HAPPENING_INJECT", { happening_def = action.happening_def })
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    -- CONSEQUENCE CHAINS: Happenings that reference player history
    --------------------------------------------------------------------------

    -- After a happening resolves, check if it should spawn a follow-up
    engine:on("HAPPENING_RESOLVED", function(ctx)
        if not ctx then return end
        local gs = engine.game_state
        local history = gs.happenings.history

        -- Check for consequence chains based on past choices
        local last = history[#history]
        if not last then return end

        -- Theft consequence: if you stole, someone may have seen
        if last.option_chosen == "steal" and RNG.chance(0.4) then
            -- Queue a follow-up happening 5-15 days later
            local follow_up = {
                id = "theft_consequence",
                title = "A Witness",
                category = "crime",
                text = "Someone grabs your sleeve in the alley. 'I saw what you did at the market. With the purse.' They're not angry. They're calculating.",
                options = {
                    {
                        id = "bribe_witness",
                        label = "Pay for their silence.",
                        description = "Everyone has a price.",
                        requires_gold = 10,
                        consequences = {
                            { type = "text", value = "Coins change hands. They nod. 'Never happened.' But it did. And now two people know it." },
                            { type = "gold", delta = -10, reason = "bribed witness" },
                        },
                    },
                    {
                        id = "threaten_witness",
                        label = "Make them understand the cost of talking.",
                        description = "Fear is free.",
                        requires_personality = { PER_BLD = 45 },
                        consequences = {
                            { type = "text", value = "You step close. Very close. They see something in your eyes. They back away. They won't talk. But they'll remember." },
                            { type = "need", need = "belonging", delta = -5 },
                        },
                        tags = { "cruel_act", "hostile" },
                    },
                    {
                        id = "deny_theft",
                        label = "Deny everything. Walk away.",
                        description = "Their word against yours.",
                        consequences = {
                            { type = "text", value = "You shrug. Walk away. Behind you, they're already talking to someone else. The rumor will spread." },
                            { type = "suspicion", delta = 5 },
                            { type = "rumor", subject = "a stranger", rumor_text = "Someone in the market has sticky fingers. Watch your purse.", heat = 30, tags = { scandal = true } },
                        },
                    },
                },
            }
            engine:emit("HAPPENING_INJECT", { happening_def = follow_up })
        end

        -- Helped someone consequence: they return the favor later
        if (last.option_chosen == "hide_them" or last.option_chosen == "help" or last.option_chosen == "feed_them")
           and RNG.chance(0.35) then
            local follow_up = {
                id = "favor_returned",
                title = "A Debt Repaid",
                category = "social",
                text = "A familiar face appears. Someone you helped, once. They carry something — a bundle, wrapped carefully. 'I said I wouldn't forget. I meant it.'",
                options = {
                    {
                        id = "accept_favor",
                        label = "Accept graciously.",
                        description = "Kindness compounds.",
                        consequences = {
                            { type = "text", value = "Inside the bundle: coin, and a name. Someone who might help your cause. Both are valuable. The coin you expected. The name — that's worth more." },
                            { type = "gold", delta = 8, reason = "favor returned" },
                            { type = "need", need = "belonging", delta = 5 },
                            { type = "need", need = "purpose", delta = 3 },
                        },
                    },
                    {
                        id = "redirect_favor",
                        label = "Ask for information instead.",
                        description = "Knowledge over coin.",
                        requires_affinity = { domain = "espionage", min = 30 },
                        consequences = {
                            { type = "text", value = "They hesitate. Then lean in. What they tell you changes the shape of several plans. The kind of information that people kill for." },
                            { type = "affinity_train", domain = "espionage", amount = 4 },
                            { type = "need", need = "purpose", delta = 8 },
                        },
                    },
                },
            }
            engine:emit("HAPPENING_INJECT", { happening_def = follow_up })
        end

        -- Fire investigation consequence: if you investigated the cause
        if last.option_chosen == "investigate_cause" and RNG.chance(0.3) then
            engine:emit("HAPPENING_INJECT", { happening_def = {
                id = "arson_trail",
                title = "Following the Trail",
                category = "crime",
                text = "The arson investigation leads somewhere. A name surfaces — connected to the court. Someone is using fire as a weapon, and they're not finished.",
                options = {
                    {
                        id = "report_arson",
                        label = "Report what you found.",
                        description = "Let the authorities handle it.",
                        consequences = {
                            { type = "text", value = "The guard captain listens. Nods. 'We'll look into it.' They won't. But you're on record now — that could help or hurt." },
                            { type = "need", need = "purpose", delta = 3 },
                            { type = "suspicion", delta = 3 },
                        },
                    },
                    {
                        id = "use_arson_info",
                        label = "Keep the information. Use it yourself.",
                        description = "Leverage doesn't expire.",
                        consequences = {
                            { type = "text", value = "You file the name away. Useful. Dangerous. The kind of knowledge that opens doors — or gets you killed." },
                            { type = "affinity_train", domain = "crime", amount = 3 },
                            { type = "affinity_train", domain = "espionage", amount = 2 },
                            { type = "need", need = "purpose", delta = 5 },
                        },
                    },
                },
            } })
        end
    end)
end

--------------------------------------------------------------------------------
-- NPC ACTION PICKER
-- Each NPC evaluates what autonomous action they'd take this month
--------------------------------------------------------------------------------

function Bridge._pick_npc_action(npc, focal, gs, engine)
    local name = npc.name or "Someone"
    local mem = npc.components.memory
    local pers = npc.components.personality or {}
    local court = npc.components.court
    local bld = pers.PER_BLD or 50; if type(bld) == "table" then bld = bld.value or 50 end
    local loy = pers.PER_LOY or 50; if type(loy) == "table" then loy = loy.value or 50 end
    local crm = pers.PER_CRM or 50; if type(crm) == "table" then crm = crm.value or 50 end
    local obs = pers.PER_OBS or 50; if type(obs) == "table" then obs = obs.value or 50 end

    -- Check if this NPC knows the claim
    local knows_claim = false
    if gs.claim and gs.claim.known_by then
        for _, kid in ipairs(gs.claim.known_by) do
            if kid == npc.id then knows_claim = true; break end
        end
    end

    -- Get relationship to focal
    local rel_mod = engine:get_module("entities")
    local rel_strength = 0
    if rel_mod then
        local _rels = rel_mod:get_relationships(npc.id)
        for _, _r in ipairs(_rels) do
            if _r.a == focal.id or _r.b == focal.id then rel_strength = rel_strength + (_r.strength or 0) end
        end
    end

    -- HOSTILE NPC INVESTIGATES (low loyalty, doesn't like you, knows something)
    if loy < 40 and rel_strength < 30 and obs > 45 and RNG.chance(0.08) then
        if gs.claim and gs.claim.type then
            return {
                text = name .. " has been asking questions about you. Not casually — methodically. Where you came from. Who your parents were. Someone is putting pieces together.",
                priority = 62,
                hint = "signal",
                tags = { "npc_agency", "investigation" },
                suspicion_delta = 5,
                need_effects = { safety = -5 },
            }
        end
    end

    -- ALLY REVEALS WITHOUT PERMISSION (knows claim, loyal but impulsive)
    if knows_claim and bld > 60 and loy > 55 and RNG.chance(0.05) then
        return {
            text = name .. " told someone. About you. About your claim. You hear it secondhand — a look, a whisper, a silence that wasn't there before. They meant well. That doesn't help.",
            priority = 65,
            hint = "echo",
            tags = { "npc_agency", "claim_leak" },
            suspicion_delta = 8,
            need_effects = { safety = -8, belonging = -3 },
        }
    end

    -- COURT MEMBER DEMANDS LOYALTY OATH (priest or advisor, high loyalty to house)
    if court and (court.role == "priest" or court.role == "advisor") and loy > 60 and RNG.chance(0.06) then
        return {
            text = name .. " calls a gathering. Formal. Everyone must reaffirm their oath to the house. Your turn comes. Every eye in the room is on you.",
            priority = 60,
            hint = "encounter",
            tags = { "npc_agency", "loyalty_test" },
            need_effects = { safety = -3, status = -2 },
            happening_def = {
                id = "loyalty_oath",
                title = "The Oath",
                category = "politics",
                text = name .. " stands before the assembled court. 'In these uncertain times, loyalty must be spoken aloud. Each of you will reaffirm your oath.' Your turn approaches.",
                options = {
                    {
                        id = "swear_oath",
                        label = "Swear the oath. Mean none of it.",
                        description = "The words cost nothing. The truth costs everything.",
                        consequences = {
                            { type = "text", value = "The words come out smooth. Practiced. " .. name .. " nods, satisfied. The irony burns — swearing loyalty to the house you plan to claim." },
                            { type = "need", need = "purpose", delta = -5 },
                            { type = "need", need = "safety", delta = 5 },
                            { type = "suspicion", delta = -3 },
                        },
                    },
                    {
                        id = "hesitate_oath",
                        label = "Hesitate. The words catch in your throat.",
                        description = "Some lies are harder than others.",
                        consequences = {
                            { type = "text", value = "The pause is noticed. By everyone. You recover — barely — but the damage is done. " .. name .. " watches you differently now." },
                            { type = "suspicion", delta = 8 },
                            { type = "need", need = "safety", delta = -5 },
                        },
                    },
                    {
                        id = "deflect_oath",
                        label = "Reframe: 'I serve the land and its people.'",
                        description = "True without being the truth they wanted.",
                        requires_affinity = { domain = "politics", min = 35 },
                        consequences = {
                            { type = "text", value = "A murmur. Some admiration. Some suspicion. " .. name .. " narrows their eyes but can't fault the sentiment. A diplomat's escape." },
                            { type = "suspicion", delta = 3 },
                            { type = "need", need = "status", delta = 3 },
                            { type = "affinity_train", domain = "politics", amount = 2 },
                        },
                    },
                },
            },
        }
    end

    -- RIVAL MAKES A POWER MOVE (ambitious NPC, not court member)
    if not court and crm > 55 and bld > 50 and RNG.chance(0.06) then
        return {
            text = name .. " has been consolidating. You hear reports — meetings, deals, alliances being forged behind closed doors. Whatever they're building, it's not small.",
            priority = 55,
            hint = "signal",
            tags = { "npc_agency", "power_move" },
            need_effects = { safety = -2 },
        }
    end

    -- NPC GOSSIPS ABOUT YOUR REPUTATION (observant NPC, gossip about patterns)
    if obs > 55 and gs.patterns and RNG.chance(0.05) then
        local dominant_axis = nil
        local best_count = 0
        for axis, count in pairs(gs.patterns.tag_counts or {}) do
            if count > best_count then
                dominant_axis = axis; best_count = count
            end
        end
        if dominant_axis and best_count >= 3 then
            local axis_words = {
                mercy = "merciful", cruelty = "cruel", courage = "brave",
                cowardice = "cautious", diplomacy = "silver-tongued",
                aggression = "dangerous", scheming = "untrustworthy",
                violence = "violent", trust = "naive",
            }
            local word = axis_words[dominant_axis] or "interesting"
            return {
                text = "You overhear " .. name .. " talking about you to someone. '...always " .. word .. ", have you noticed? Every time. It's like they can't help it.' They don't know you're listening.",
                priority = 52,
                hint = "signal",
                tags = { "npc_agency", "gossip" },
            }
        end
    end

    return nil  -- No action this month
end

return Bridge
