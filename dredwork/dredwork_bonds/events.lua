local Math = require("dredwork_core.math")
local Wealth = require("dredwork_world.wealth")
local Morality = require("dredwork_world.morality")
local ShadowBody = require("dredwork_bonds.body")
local ShadowBonds = require("dredwork_bonds.bonds")
local ShadowClaim = require("dredwork_bonds.claim")
local ShadowPossessions = require("dredwork_bonds.possessions")
local ShadowClaimHunter = require("dredwork_bonds.claim_hunter")

local ShadowEvents = {}


local function profile_of(game_state)
    return game_state and game_state.shadow_setup or nil
end

local function ensure_story(game_state)
    game_state.shadow_story = game_state.shadow_story or {
        seen_events = {},
    }
    return game_state.shadow_story
end

local function make_chronicle_entry(world, text)
    if not world or not world.world_state or not world.world_state.chronicle or not text or text == "" then
        return
    end
    world.world_state.chronicle[#world.world_state.chronicle + 1] = { text = text }
    while #world.world_state.chronicle > 20 do
        table.remove(world.world_state.chronicle, 1)
    end
end

local function add_resources(world, deltas, heir_name, generation)
    if not world or not world.resources then
        return
    end
    for key, value in pairs(deltas or {}) do
        if value ~= 0 then
            world.resources:change(key, value, "shadow_event", heir_name, generation)
        end
    end
end

local function add_condition(world, payload)
    if not world or not world.world_state or not payload or not payload.type then
        return
    end
    world.world_state:add_condition(payload.type, payload.intensity or 0.4, payload.duration or 2)
end

local function change_power(game_state, delta)
    if not game_state or not game_state.lineage_power then
        return
    end
    game_state.lineage_power.value = Math.clamp((game_state.lineage_power.value or 45) + (delta or 0), 0, 100)
end

local function apply_shadow_changes(game_state, payload)
    if not game_state or not payload then
        return
    end
    game_state.shadow_state = game_state.shadow_state or {}
    local state = game_state.shadow_state
    for key, value in pairs(payload or {}) do
        if type(value) == "number" and state[key] ~= nil then
            state[key] = Math.clamp((state[key] or 0) + value, 0, 100)
        end
    end
end

local function change_wealth(game_state, delta, generation, description)
    if not game_state or not game_state.wealth or not delta or delta == 0 then
        return
    end
    Wealth.change(game_state.wealth, delta, delta >= 0 and "trade" or "loss", generation or 1, description or "shadow_event")
end

local function apply_morality(game_state, payload, generation, description)
    if not game_state or not game_state.morality or not payload then
        return
    end
    if payload.act then
        Morality.record_act(game_state.morality, payload.act, generation or 1, description or payload.act)
    elseif payload.delta and payload.delta ~= 0 then
        game_state.morality.score = Math.clamp((game_state.morality.score or 0) + payload.delta, -100, 100)
    end
end

local function get_trait(game_state, id)
    return game_state and game_state.current_heir and game_state.current_heir:get_value(id) or 50
end

local function get_axis(game_state, id)
    return game_state and game_state.heir_personality and game_state.heir_personality:get_axis(id) or 50
end

local function gate_reason(check)
    if check.trait then
        return "Requires " .. tostring(check.label or check.trait) .. " " .. tostring(check.min or 0) .. "."
    end
    if check.axis then
        return "Requires " .. tostring(check.label or check.axis) .. " " .. tostring(check.min or 0) .. "."
    end
    return "That path is barred."
end

local function option_available(game_state, option)
    local gate = option.gate
    if not gate then
        return true, nil
    end
    local value = gate.trait and get_trait(game_state, gate.trait) or get_axis(game_state, gate.axis)
    if value >= (gate.min or 0) then
        return true, nil
    end
    return false, gate.reason or gate_reason(gate)
end

local function check_quality(game_state, option)
    local check = option.check
    if not check then
        return nil
    end

    local total = 0
    local count = 0
    if check.trait then
        total = total + get_trait(game_state, check.trait)
        count = count + 1
    end
    if check.axis then
        total = total + get_axis(game_state, check.axis)
        count = count + 1
    end
    local score = count > 0 and (total / count) or 50
    local difficulty = check.difficulty or 55

    if score >= difficulty + 16 then
        return "triumph"
    elseif score >= difficulty then
        return "success"
    elseif score >= difficulty - 14 then
        return "failure"
    end
    return "disaster"
end

local function resolve_effect_bundle(world, game_state, bundle, generation)
    if not bundle then
        return {}
    end

    local function apply_bond_payload(payload)
        if not payload then
            return
        end
        if payload.id then
            ShadowBonds.apply_event(game_state, payload)
            return
        end
        for _, item in ipairs(payload or {}) do
            ShadowBonds.apply_event(game_state, item)
        end
    end

    add_resources(world, bundle.resources, game_state.heir_name, generation)
    change_wealth(game_state, bundle.wealth, generation, bundle.description)
    apply_morality(game_state, bundle.morality, generation, bundle.description)
    change_power(game_state, bundle.power)
    apply_shadow_changes(game_state, bundle.shadow)
    add_condition(world, bundle.condition)
    ShadowBody.apply(game_state, bundle.body)
    ShadowClaim.apply(game_state, bundle.claim)
    ShadowPossessions.apply(game_state, bundle.possessions)
    apply_bond_payload(bundle.bond)
    apply_bond_payload(bundle.bond_secondary)
    apply_bond_payload(bundle.bonds)
    if bundle.notice then
        game_state.shadow_notice_override = bundle.notice
    end
    if bundle.relationship and game_state.cultural_memory and game_state.cultural_memory.add_relationship then
        pcall(game_state.cultural_memory.add_relationship, game_state.cultural_memory, bundle.relationship.faction, bundle.relationship.kind or "ally", generation, bundle.relationship.strength or 35, bundle.relationship.reason or "shadow_event")
    end
    make_chronicle_entry(world, bundle.chronicle)
    local lines = {}
    local detail = ShadowBonds.detail_snapshot(game_state)
    local body = ShadowBody.snapshot(game_state)
    local claim = ShadowClaim.snapshot(game_state)
    local possessions = ShadowPossessions.snapshot(game_state)

    if bundle.claim then
        local target = detail and ((detail.most_urgent and (detail.most_urgent.thread_kind == "legacy" or detail.most_urgent.category == "kin") and detail.most_urgent) or detail.rival or detail.strongest) or nil
        local positive_claim = ((bundle.claim.legitimacy or 0) + (bundle.claim.proof or 0)) >= ((bundle.claim.exposure or 0) + (bundle.claim.usurper_risk or 0))
        if target then
            if positive_claim then
                ShadowBonds.apply_event(game_state, {
                    id = target.id,
                    closeness = 2,
                    obligation = 2,
                    history = "Claim-fallout made the tie feel more consequential.",
                })
                lines[#lines + 1] = target.name .. " felt the branch-story grow heavier."
            else
                ShadowBonds.apply_event(game_state, {
                    id = target.id,
                    strain = 2,
                    leverage = 2,
                    visibility = 1,
                    history = "Claim-fallout gave the tie another sharp edge.",
                })
                lines[#lines + 1] = target.name .. " found new leverage in the branch-story."
            end
        end
    end

    if bundle.body and body then
        local target = (detail and detail.intimate) or (detail and detail.dependent) or (detail and detail.strongest) or nil
        if target and (((body.compulsion_load or 0) >= 18) or ((body.wound_load or 0) + (body.illness_load or 0) >= 20)) then
            ShadowBonds.apply_event(game_state, {
                id = target.id,
                strain = 2,
                closeness = -1,
                heat_delta = 2,
                history = "The body's new cost reached the tie immediately.",
            })
            lines[#lines + 1] = target.name .. " had to absorb the body's new damage."
        end
    end

    if bundle.possessions and possessions then
        local held = (possessions.people and possessions.people[1]) or (possessions.places and possessions.places[1]) or nil
        local target = (detail and detail.dependent) or (detail and detail.most_urgent) or nil
        if held and target then
            ShadowBonds.apply_event(game_state, {
                id = target.id,
                obligation = 2,
                dependency = held.kind == "person" and 2 or 0,
                leverage = held.kind == "place" and 1 or 0,
                history = held.label .. " became entangled in the tie's price.",
            })
            lines[#lines + 1] = held.label .. " entered the social web as pressure, not furniture."
        end
    end

    if claim and (claim.exposure or 0) >= 56 and possessions and possessions.place_count and possessions.place_count > 0 then
        local place = possessions.places[1]
        if place then
            ShadowPossessions.apply(game_state, {
                adjust = {
                    {
                        id = place.id,
                        status = "Watched",
                        stain = 1,
                        note = "Claim-rumor drew witnesses to the threshold.",
                    },
                },
            })
            lines[#lines + 1] = place.label .. " now sits under a more suspicious eye."
        end
    end

    return lines
end

local function base_event(id, kind, title, narrative, options)
    return {
        id = id,
        source = "shadow",
        type = kind,
        title = title,
        narrative = narrative,
        options = options,
    }
end

local OCCUPATION_EVENTS = {
    laborer = function(game_state)
        return base_event(
            "shadow_laborer_quarry",
            "occupation",
            "The Quarry Foreman Calls",
            "A stone haul has gone wrong at dawn. Three workers are pinned, and the foreman wants silence before the owners arrive.",
            {
                {
                    label = "Lead the rescue yourself",
                    description = "Risk the body to drag them free before the wall shifts again.",
                    check = { trait = "PHY_STR", axis = "PER_BLD", difficulty = 60 },
                    success = {
                        narrative = "You haul two of them free and earn the crew's fierce loyalty.",
                        effects = { resources = { grain = 2 }, power = 2, morality = { act = "protection" }, chronicle = "At the quarry, the protagonist took the falling weight onto their own shoulders and came back with the living." },
                    },
                    failure = {
                        narrative = "The rescue costs blood and leaves the yard muttering about bad omens.",
                        effects = { resources = { grain = -1 }, power = -1, condition = { type = "war_weariness", intensity = 0.2, duration = 1 }, chronicle = "The quarry rescue failed cleanly enough to be called brave and badly enough to be remembered." },
                    },
                },
                {
                    label = "Order the tunnel sealed",
                    description = "Save the daybook, the stone, and whoever is still standing.",
                    gate = { axis = "PER_CRM", min = 58, label = "Cruelty" },
                    check = { axis = "PER_CRM", trait = "SOC_LEA", difficulty = 57 },
                    success = {
                        narrative = "The owners praise your cold arithmetic, even while the camp spits when you pass.",
                        effects = { resources = { steel = 2 }, wealth = 4, morality = { act = "abandonment" }, power = 2, chronicle = "When the quarry closed over the trapped, the protagonist chose the ledger over the lungs beneath it." },
                    },
                    failure = {
                        narrative = "The order breaks the gang. Someone talks. The owners step back from you for now.",
                        effects = { wealth = -2, morality = { act = "abandonment" }, power = -2, chronicle = "The sealed quarry would not stay sealed in rumor." },
                    },
                },
            }
        )
    end,
    scribe = function(game_state)
        return base_event(
            "shadow_scribe_irregularity",
            "occupation",
            "The Ledger Disagrees",
            "A tax record and a burial register name the same man alive and dead in the same week. Someone has altered the books.",
            {
                {
                    label = "Untangle it quietly",
                    description = "Spend the night comparing hands, seals, and missing pages.",
                    check = { trait = "MEN_INT", axis = "PER_OBS", difficulty = 62 },
                    success = {
                        narrative = "You find the forgery and keep the shame private. A patron notices the precision.",
                        effects = { resources = { lore = 2, gold = 1 }, wealth = 2, power = 1, chronicle = "The protagonist found a lie nested inside the tax books and removed it so cleanly that only the guilty noticed." },
                    },
                    failure = {
                        narrative = "The books yield nothing except lost sleep and a worse suspicion than before.",
                        effects = { resources = { lore = -1 }, condition = { type = "exodus", intensity = 0.2, duration = 1 }, chronicle = "A forgery in the records remained a forgery in the records, and the night spent chasing it bought no certainty." },
                    },
                },
                {
                    label = "Sell the secret",
                    description = "Take payment from the house that benefits and let the dead remain administratively alive.",
                    gate = { axis = "PER_CRM", min = 54, label = "Cruelty" },
                    check = { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 58 },
                    success = {
                        narrative = "The money is good. So is the silence, for now.",
                        effects = { resources = { gold = 4 }, wealth = 4, morality = { act = "exploitation" }, chronicle = "The forged ledger bought the protagonist a purse heavy enough to quiet the conscience for a week." },
                    },
                    failure = {
                        narrative = "You are underpaid and overexposed. The buyer trusts you exactly as much as they should.",
                        effects = { resources = { gold = 1 }, wealth = -1, morality = { act = "exploitation" }, power = -1, chronicle = "Selling the secret proved easier than owning the sale." },
                    },
                },
            }
        )
    end,
    soldier = function(game_state)
        return base_event(
            "shadow_soldier_summons",
            "occupation",
            "A Captain Remembers Your Name",
            "A captain from an older campaign wants you for a night raid no honest officer would sign.",
            {
                {
                    label = "Take the raid",
                    description = "Violence still pays better than principle.",
                    check = { trait = "PHY_STR", axis = "PER_BLD", difficulty = 60 },
                    success = {
                        narrative = "The raid lands hard. So does your new reputation.",
                        effects = { resources = { steel = 2, gold = 2 }, wealth = 2, power = 3, morality = { act = "cruelty" }, body = { wounds = { { id = "night_raid_scars", label = "Night Raid Scars", severity = 10 } } }, condition = { type = "war", intensity = 0.4, duration = 2 }, chronicle = "The protagonist took the captain's unlawful work and came back with plunder, scars, and a thinner claim to innocence." },
                    },
                    failure = {
                        narrative = "The raid breaks. Men die for nothing worth naming.",
                        effects = { resources = { steel = -1 }, wealth = -2, power = -2, morality = { act = "cruelty" }, body = { wounds = { { id = "deep_gash", label = "Deep Gash", severity = 18 } }, illnesses = { { id = "camp_fever", label = "Camp Fever", severity = 8 } } }, chronicle = "The night raid came apart in mud and shouting, which is to say it became itself." },
                    },
                },
                {
                    label = "Refuse and vanish for a while",
                    description = "Walk away before old loyalties become a gallows.",
                    check = { trait = "MEN_WIL", axis = "PER_ADA", difficulty = 56 },
                    success = {
                        narrative = "You slip the captain cleanly and keep your neck.",
                        effects = { power = 1, morality = { act = "protection" }, condition = { type = "exodus", intensity = 0.3, duration = 1 }, chronicle = "Rather than serve the captain's appetite again, the protagonist chose disappearance." },
                    },
                    failure = {
                        narrative = "The refusal is remembered. Doors close before you reach them.",
                        effects = { wealth = -2, power = -1, chronicle = "The refused captain did not forgive, which surprised no one with a functioning memory." },
                    },
                },
            }
        )
    end,
    courtier = function(game_state)
        return base_event(
            "shadow_courtier_patron",
            "occupation",
            "A Patron Wants a Ruin",
            "A patron asks for a smiling lie that will disinherit a quieter rival by week's end.",
            {
                {
                    label = "Compose the lie elegantly",
                    description = "If it must be done, do it beautifully.",
                    check = { trait = "SOC_ELO", axis = "PER_PRI", difficulty = 61 },
                    success = {
                        narrative = "The rival is ruined in silk and applause.",
                        effects = { resources = { gold = 3 }, wealth = 5, power = 3, morality = { act = "betrayal" }, chronicle = "The courtier's lie was so graceful that half the room admired it before understanding what had died." },
                    },
                    failure = {
                        narrative = "The lie reaches the room, but not intact enough to protect you.",
                        effects = { wealth = -2, power = -2, morality = { act = "betrayal" }, chronicle = "The court accepted the slander only after deciding it had come from a clumsier mouth than yours." },
                    },
                },
                {
                    label = "Warn the rival privately",
                    description = "Trade profit for an uncertain ally.",
                    check = { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 55 },
                    success = {
                        narrative = "You lose the patron and gain a dangerous gratitude.",
                        effects = { resources = { lore = 1 }, wealth = -1, morality = { act = "mercy" }, power = 1, chronicle = "The rival was warned in time, and gratitude entered the record wearing a knife under its sleeve." },
                    },
                    failure = {
                        narrative = "Neither side trusts you afterwards.",
                        effects = { wealth = -2, power = -1, morality = { act = "mercy" }, chronicle = "Attempting decency at court had the usual result: two enemies instead of one." },
                    },
                },
            }
        )
    end,
    tinker = function(game_state)
        return base_event(
            "shadow_tinker_device",
            "occupation",
            "The Device Runs Hot",
            "A buyer wants the prototype demonstrated before the casing is safe to touch.",
            {
                {
                    label = "Demonstrate it anyway",
                    description = "Risk flesh for proof.",
                    check = { trait = "CRE_TIN", axis = "PER_BLD", difficulty = 60 },
                    success = {
                        narrative = "The device survives the demonstration and so do you, mostly.",
                        effects = { resources = { lore = 3, gold = 2 }, wealth = 3, power = 1, body = { wounds = { { id = "burned_hands", label = "Burned Hands", severity = 8 } } }, chronicle = "The device held. The hands that built it blistered, but less than expected." },
                    },
                    failure = {
                        narrative = "The prototype spits sparks and panic into the room.",
                        effects = { resources = { lore = -1 }, wealth = -2, body = { wounds = { { id = "burned_hands", label = "Burned Hands", severity = 16 } } }, condition = { type = "war_weariness", intensity = 0.2, duration = 1 }, chronicle = "The demonstration became a small mechanical betrayal." },
                    },
                },
                {
                    label = "Delay and reinforce it",
                    description = "Lose money now to keep the invention alive.",
                    check = { trait = "MEN_PAT", axis = "PER_OBS", difficulty = 58 },
                    success = {
                        narrative = "The buyer curses the delay, then pays more when the thing finally sings.",
                        effects = { resources = { lore = 2 }, wealth = 2, power = 1, chronicle = "Patience cost a week and saved the device from becoming merely another burn scar." },
                    },
                    failure = {
                        narrative = "The buyer walks. The work remains yours and unpaid.",
                        effects = { wealth = -3, chronicle = "The safer design arrived exactly when the patron's patience did not." },
                    },
                },
            }
        )
    end,
    performer = function(game_state)
        return base_event(
            "shadow_performer_feast",
            "occupation",
            "The Noble Feast Wants Blood",
            "A feast crowd tires of charm and asks for mockery sharp enough to ruin someone real.",
            {
                {
                    label = "Give them the cruelty they paid for",
                    description = "Turn wit into a blade and collect the applause.",
                    check = { trait = "CRE_NAR", axis = "PER_CRM", difficulty = 58 },
                    success = {
                        narrative = "The room roars. So does the one you cut, once the candles go out.",
                        effects = { resources = { gold = 3 }, wealth = 3, morality = { act = "cruelty" }, power = 2, chronicle = "The feast laughed hardest where the joke tore flesh." },
                    },
                    failure = {
                        narrative = "You miss the rhythm and buy yourself a quieter kind of danger.",
                        effects = { wealth = -2, power = -1, morality = { act = "cruelty" }, chronicle = "The cruelty landed badly, which is only to say it landed on the wrong witness." },
                    },
                },
                {
                    label = "Turn the crowd against the patron instead",
                    description = "Slip the blade upward and pray they enjoy daring as much as malice.",
                    gate = { trait = "SOC_ELO", min = 56, label = "Eloquence" },
                    check = { trait = "SOC_ELO", axis = "PER_BLD", difficulty = 60 },
                    success = {
                        narrative = "The room breaks in your favor. The patron does not.",
                        effects = { wealth = 1, power = 3, morality = { act = "pragmatism" }, chronicle = "The patron became the punchline and discovered too late that the room preferred courage to obedience." },
                    },
                    failure = {
                        narrative = "The patron smiles with their mouth and ruins your week with everything else.",
                        effects = { wealth = -3, power = -2, chronicle = "Mocking the patron would have worked in a fairer room." },
                    },
                },
            }
        )
    end,
}

local BIRTHPLACE_EVENTS = {
    holdfast = function()
        return base_event("shadow_birthplace_holdfast", "origin", "The Gate Captain Remembers Your Blood", "A gate captain studies your face too long and asks whether your branch still teaches its children to stand straight under insult.", {
            {
                label = "Answer with discipline",
                description = "Let restraint do the work that outrage would only cheapen.",
                check = { trait = "MEN_WIL", axis = "PER_LOY", difficulty = 57 },
                success = {
                    narrative = "The captain lets the matter rest and leaves with a better measure of you than before.",
                    effects = { power = 1, shadow = { standing = 1, stress = -1 }, chronicle = "At the holdfast gate, the protagonist answered insult with such controlled posture that it became a form of warning." },
                },
                failure = {
                    narrative = "The answer is too stiff to sound natural and too heated to sound innocent.",
                    effects = { shadow = { stress = 2, standing = -1 }, chronicle = "The holdfast captain found the old branch easier to provoke than to trust." },
                },
            },
            {
                label = "Answer insult with insult",
                description = "If they want the old blood roused, give them enough of it to remember.",
                check = { trait = "SOC_ELO", axis = "PER_PRI", difficulty = 58 },
                success = {
                    narrative = "The room enjoys the sharpness almost as much as the insolence.",
                    effects = { power = 2, shadow = { notoriety = 1 }, chronicle = "The gate was crossed only after the protagonist left a sharper answer behind than the guard had expected to receive." },
                },
                failure = {
                    narrative = "The retort lands, but so does the captain's authority.",
                    effects = { shadow = { stress = 2, standing = -2, notoriety = 1 }, chronicle = "The holdfast remembered insolence more accurately than wit." },
                },
            },
        })
    end,
    market = function()
        return base_event("shadow_birthplace_market", "origin", "The Market Wants a Mouth", "A trader from the old ward offers you a stall, a crowd, and a lie small enough to pass as enthusiasm.", {
            {
                label = "Sell honestly and harder than the others",
                description = "Use your tongue without selling your sleep along with the wares.",
                check = { trait = "SOC_ELO", axis = "PER_ADA", difficulty = 57 },
                success = {
                    narrative = "The crowd leaves lighter of purse and fonder of your name.",
                    effects = { resources = { gold = 2 }, wealth = 2, shadow = { standing = 1 }, chronicle = "In the market ward, the protagonist proved that charm need not always arrive carrying fraud." },
                },
                failure = {
                    narrative = "Honesty proves slower than the crowd's appetite for noise.",
                    effects = { wealth = -1, shadow = { stress = 1 }, chronicle = "The market rewarded louder mouths before it rewarded cleaner ones." },
                },
            },
            {
                label = "Sell the lie the crowd came to buy",
                description = "If the market wants theater, give it a better stage than the next stall.",
                gate = { axis = "PER_CRM", min = 52, label = "Cruelty" },
                check = { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 58 },
                success = {
                    narrative = "The lie moves well enough to look like skill.",
                    effects = { resources = { gold = 3 }, wealth = 3, morality = { act = "exploitation" }, shadow = { notoriety = 1 }, chronicle = "The market ward paid the protagonist for a lie the crowd had already prepared itself to believe." },
                },
                failure = {
                    narrative = "The stall profits less than the rumor that you cheated the wrong buyer.",
                    effects = { wealth = 1, morality = { act = "exploitation" }, shadow = { standing = -1, notoriety = 2 }, chronicle = "The market forgives deception unevenly and remembers clumsy deception forever." },
                },
            },
        })
    end,
    abbey = function()
        return base_event("shadow_birthplace_abbey", "origin", "A Cellar of Forbidden Leaves", "A younger cleric shows you a locked cupboard of scraped manuscripts and asks whether reverence means preserving them or reporting them.", {
            {
                label = "Read before anyone can forbid it again",
                description = "Knowledge is often clearest exactly where authority least wants light.",
                check = { trait = "MEN_INT", axis = "PER_CUR", difficulty = 58 },
                success = {
                    narrative = "The pages open and leave a useful stain behind on the mind.",
                    effects = { resources = { lore = 2 }, shadow = { craft = 1 }, chronicle = "In the abbey close, the protagonist read what piety had hidden and came away more informed and less governable." },
                },
                failure = {
                    narrative = "The leaves yield fragments and dread in roughly equal measure.",
                    effects = { resources = { lore = 1 }, shadow = { stress = 1 }, chronicle = "The forbidden leaves were legible enough to trouble and too broken to fully teach." },
                },
            },
            {
                label = "Report the cupboard and keep your hands clean",
                description = "Better the present order than another private heresy learning to breathe.",
                check = { trait = "SOC_NEG", axis = "PER_LOY", difficulty = 56 },
                success = {
                    narrative = "The abbot approves, though the younger cleric never does again.",
                    effects = { power = 1, morality = { act = "ruthless_order" }, shadow = { standing = 1 }, chronicle = "The hidden cupboard was surrendered to authority and the protagonist learned how clean choices can still feel cold." },
                },
                failure = {
                    narrative = "Authority arrives late and suspicion earlier than that.",
                    effects = { morality = { act = "betrayal" }, shadow = { standing = -1, stress = 1 }, chronicle = "Reporting the cupboard bought less absolution than distrust." },
                },
            },
        })
    end,
    frontier = function()
        return base_event("shadow_birthplace_frontier", "origin", "Tracks at the Edge of the Hamlet", "Before dawn someone finds tracks circling the goat pens, too clever for wolves and too hungry for comfort.", {
            {
                label = "Take the watch yourself",
                description = "Cold, patience, and a blade are still older than fear.",
                check = { trait = "PHY_VIT", axis = "PER_BLD", difficulty = 58 },
                success = {
                    narrative = "The thing withdraws after learning the hamlet is not unwatched.",
                    effects = { resources = { grain = 1 }, shadow = { standing = 1, stress = -1 }, chronicle = "On the frontier edge, the protagonist held the cold long enough for the thing in it to decide the village cost too much." },
                },
                failure = {
                    narrative = "The watch keeps no clean victory, only a colder memory and fewer animals.",
                    effects = { resources = { grain = -1 }, body = { wounds = { { id = "night_scratches", label = "Night Scratches", severity = 6 } } }, shadow = { stress = 2 }, chronicle = "The frontier watch proved brave, costly, and only partially persuasive." },
                },
            },
            {
                label = "Drive the panic toward someone else's door",
                description = "Survival on the frontier is often just redistributing where danger sleeps.",
                gate = { axis = "PER_CRM", min = 52, label = "Cruelty" },
                check = { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 57 },
                success = {
                    narrative = "Your own animals survive. So does your conscience, but more weakly.",
                    effects = { resources = { grain = 1 }, morality = { act = "betrayal" }, shadow = { stress = 1, notoriety = 1 }, chronicle = "The frontier panic was redirected with practical intelligence and the usual spiritual cost." },
                },
                failure = {
                    narrative = "The hamlet notices exactly where the fear was encouraged to settle.",
                    effects = { morality = { act = "betrayal" }, shadow = { standing = -2, notoriety = 1 }, chronicle = "On the frontier, redistributed danger has a habit of learning its way back to the person who mapped it." },
                },
            },
        })
    end,
    ruin = function()
        return base_event("shadow_birthplace_ruin", "origin", "A Painted Wall Opens", "Rain peels plaster from an abandoned hall and reveals a mural older than the names now spoken around it.", {
            {
                label = "Copy what can be saved",
                description = "Take the image before damp, greed, or doctrine finishes eating it.",
                check = { trait = "CRE_VIS", axis = "PER_OBS", difficulty = 57 },
                success = {
                    narrative = "The fragments become a map, a warning, and a private obsession all at once.",
                    effects = { resources = { lore = 2 }, shadow = { craft = 1 }, chronicle = "In the ruin district, the protagonist copied enough of the old mural to carry its warning forward into younger walls." },
                },
                failure = {
                    narrative = "The damp takes half and your memory mislays the rest.",
                    effects = { resources = { lore = 1 }, shadow = { stress = 1 }, chronicle = "The ruin yielded only partial beauty, which is often how the past bargains." },
                },
            },
            {
                label = "Sell the location before the wall collapses",
                description = "If the ruin still has value, convert it before reverence claims it for free.",
                check = { trait = "SOC_NEG", axis = "PER_PRI", difficulty = 58 },
                success = {
                    narrative = "The buyer pays quickly and arrives faster than caution would prefer.",
                    effects = { resources = { gold = 2 }, wealth = 2, morality = { act = "exploitation" }, chronicle = "The ruin's hidden mural was sold before preservation could put a pious hand over profit." },
                },
                failure = {
                    narrative = "The buyer comes with questions, fewer coins, and too many friends.",
                    effects = { wealth = -1, morality = { act = "exploitation" }, shadow = { stress = 2 }, chronicle = "Selling the ruin's secret yielded less money than company." },
                },
            },
        })
    end,
}

local HOUSEHOLD_EVENTS = {
    devout = function()
        return base_event("shadow_household_devout", "household", "The Family Shrine Demands a Gesture", "Someone in the devout house has noticed how often your body pauses before the old household shrine and wants proof of what still rules you.", {
            {
                label = "Give the gesture honestly",
                description = "Let the house see what obedience still lives in you.",
                check = { trait = "CRE_RIT", axis = "PER_LOY", difficulty = 56 },
                success = {
                    narrative = "The house softens by one degree, which in such places counts as warmth.",
                    effects = { shadow = { standing = 1, stress = -1 }, morality = { act = "honoring_oath" }, chronicle = "At the family shrine, the protagonist offered obedience plain enough to quiet suspicion for a time." },
                },
                failure = {
                    narrative = "The gesture satisfies the room less than its own hunger for certainty.",
                    effects = { shadow = { stress = 1 }, chronicle = "The devout house took the ritual and still found reason to doubt the heart behind it." },
                },
            },
            {
                label = "Refuse and call it private",
                description = "Keep faith, doubt, or contempt from becoming household property.",
                check = { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 55 },
                success = {
                    narrative = "The refusal lands with less thunder than expected.",
                    effects = { shadow = { standing = 1 }, chronicle = "The household was told that prayer and performance were not the same duty." },
                },
                failure = {
                    narrative = "Privacy sounds too much like rebellion when spoken indoors.",
                    effects = { shadow = { standing = -1, stress = 1 }, chronicle = "The devout house interpreted privacy in the old efficient way: as dissent." },
                },
            },
        })
    end,
    debtor = function()
        return base_event("shadow_household_debtor", "household", "A Ledger from Home Is Found Open", "A family ledger lies open on the table, and someone has circled your name as if anticipation itself were collateral.", {
            {
                label = "Offer a plan and own the numbers",
                description = "Beat shame to the room by naming the arithmetic before it names you.",
                check = { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 56 },
                success = {
                    narrative = "The household believes the plan because they badly need to.",
                    effects = { shadow = { standing = 1 }, chronicle = "The debtor house accepted a repayment plan mostly because despair had run short of better mathematics." },
                },
                failure = {
                    narrative = "The plan sounds like another postponement dressed for supper.",
                    effects = { shadow = { stress = 2, standing = -1 }, chronicle = "In the debtor house, optimism was received as a late form of insult." },
                },
            },
            {
                label = "Close the ledger and leave the room",
                description = "Refuse to be measured tonight, even if tomorrow arrives meaner for it.",
                check = { trait = "MEN_WIL", axis = "PER_PRI", difficulty = 57 },
                success = {
                    narrative = "The room hates the gesture and respects it a little.",
                    effects = { shadow = { standing = 1, stress = 1 }, chronicle = "The open ledger was shut with the hand rather than the purse, and the room had to live with that for one evening." },
                },
                failure = {
                    narrative = "The slammed book keeps speaking after you've left it.",
                    effects = { shadow = { stress = 2, standing = -1, notoriety = 1 }, chronicle = "Closing the ledger solved nothing except the question of whether the room would remember the exit." },
                },
            },
        })
    end,
    martial = function()
        return base_event("shadow_household_martial", "household", "A Training Yard Challenge", "Someone from the martial house decides the child has been spoken of too gently and asks for a public correction under everyone else's eyes.", {
            {
                label = "Take the correction and answer it",
                description = "Pain can still be turned into standing if it lands in the right witness-field.",
                check = { trait = "PHY_STR", axis = "PER_BLD", difficulty = 58 },
                success = {
                    narrative = "The yard gives you bruises and a clearer place in its memory.",
                    effects = { body = { wounds = { { id = "yard_bruises", label = "Yard Bruises", severity = 6 } } }, shadow = { standing = 2 }, chronicle = "The martial house marked the protagonist in the training yard and, in doing so, also marked them as difficult to dismiss." },
                },
                failure = {
                    narrative = "The lesson lands harder than the respect you hoped to buy with it.",
                    effects = { body = { wounds = { { id = "yard_bruises", label = "Yard Bruises", severity = 10 } } }, shadow = { stress = 2, standing = -1 }, chronicle = "The training yard taught the usual lesson about public humiliation: everyone remembers it more clearly than any improvement that follows." },
                },
            },
            {
                label = "Refuse the yard and challenge the custom",
                description = "If discipline must be public, make the refusal public too.",
                check = { trait = "SOC_ELO", axis = "PER_PRI", difficulty = 58 },
                success = {
                    narrative = "The house is angered into listening.",
                    effects = { shadow = { standing = 1, notoriety = 1 }, chronicle = "The protagonist refused the training-yard correction and left the martial house briefly uncertain whether insolence and courage were the same thing." },
                },
                failure = {
                    narrative = "The refusal is counted as weakness rather than principle.",
                    effects = { shadow = { standing = -2, stress = 1 }, chronicle = "The martial house interpreted principle through its older and simpler vocabulary." },
                },
            },
        })
    end,
    scholarly = function()
        return base_event("shadow_household_scholarly", "household", "A Tutor's Margin Note", "An old family lesson-book yields a margin note about your branch that was never meant for young eyes and is now too late to hide.", {
            {
                label = "Trace the note back to its source",
                description = "If the insult has a hand behind it, know whose wrist carried the pen.",
                check = { trait = "MEN_INT", axis = "PER_OBS", difficulty = 58 },
                success = {
                    narrative = "You find the hand behind the insult and inherit a sharper silence from it.",
                    effects = { resources = { lore = 2 }, shadow = { stress = 1 }, chronicle = "The family lesson-book gave up its margin secret only after the protagonist proved patient enough to deserve another wound." },
                },
                failure = {
                    narrative = "The note clarifies the injury and nothing else.",
                    effects = { shadow = { stress = 2 }, chronicle = "The scholarly house proved once again that education can preserve insult with exquisite care." },
                },
            },
            {
                label = "Write your own correction beside it",
                description = "If the record wounded you, wound the record back into honesty.",
                check = { trait = "CRE_NAR", axis = "PER_PRI", difficulty = 57 },
                success = {
                    narrative = "Your note is better written and therefore more dangerous.",
                    effects = { resources = { lore = 1 }, shadow = { standing = 1 }, chronicle = "The protagonist answered the old margin with a newer one and made the page less obedient than before." },
                },
                failure = {
                    narrative = "The correction is found before the truth has time to root.",
                    effects = { shadow = { standing = -1, stress = 1 }, chronicle = "The corrected margin drew more punishment than agreement." },
                },
            },
        })
    end,
    fractured = function()
        return base_event("shadow_household_fractured", "household", "A Door Slams and Stays Open", "Another domestic quarrel runs too hot, and what spills out of the room cannot be put back into kinship by morning.", {
            {
                label = "Step between them",
                description = "Take the bruise now rather than letting the split choose its own shape.",
                check = { trait = "SOC_NEG", axis = "PER_LOY", difficulty = 57 },
                success = {
                    narrative = "The rupture pauses, though no one mistakes pause for healing.",
                    effects = { shadow = { standing = 1, stress = 1 }, chronicle = "In the fractured house, the protagonist stood in the doorway long enough for the quarrel to remember human language." },
                },
                failure = {
                    narrative = "The quarrel expands to include the person who tried to save it.",
                    effects = { shadow = { stress = 3, standing = -1 }, chronicle = "The fractured house made one more body responsible for damage it had already chosen to prefer." },
                },
            },
            {
                label = "Take what matters and leave the room to itself",
                description = "Sometimes survival begins by refusing the privilege of mediation.",
                check = { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 56 },
                success = {
                    narrative = "You lose the argument and keep the self.",
                    effects = { shadow = { stress = -1, standing = 1 }, chronicle = "The protagonist let the fractured room remain fractured and chose self-preservation without the usual decorative excuses." },
                },
                failure = {
                    narrative = "Leaving is slower than the room's desire to accuse.",
                    effects = { shadow = { stress = 2, notoriety = 1 }, chronicle = "Even retreat could not outrun the fractured house's instinct to find one more person to blame." },
                },
            },
        })
    end,
    wandering = function()
        return base_event("shadow_household_wandering", "household", "The Household Talks of Another Road", "The wandering house has started speaking in bundles, routes, and distances again. Staying would mean breaking with habit older than comfort.", {
            {
                label = "Argue for one rooted season",
                description = "Try to win the household a year in which not everything is carried by hand.",
                check = { trait = "SOC_NEG", axis = "PER_LOY", difficulty = 56 },
                success = {
                    narrative = "The household stays, resentfully and usefully.",
                    effects = { resources = { grain = 1 }, shadow = { standing = 1 }, chronicle = "The wandering house was persuaded to remain long enough for a roof to become more than weather." },
                },
                failure = {
                    narrative = "The argument sounds like ingratitude toward survival itself.",
                    effects = { shadow = { stress = 1, standing = -1 }, chronicle = "The wandering house heard rootedness described and mistook it, not unreasonably, for softness." },
                },
            },
            {
                label = "Take the road and learn what it costs again",
                description = "Accept that movement is this household's oldest kind of prayer.",
                check = { trait = "PHY_VIT", axis = "PER_ADA", difficulty = 57 },
                success = {
                    narrative = "The road strips comfort and sharpens the senses in the old familiar order.",
                    effects = { shadow = { craft = 1, stress = 1 }, chronicle = "The protagonist took the road with the wandering house and found, once more, that motion can resemble inheritance." },
                },
                failure = {
                    narrative = "The road gives little and remembers every weakness.",
                    effects = { body = { illnesses = { { id = "road_fever", label = "Road Fever", severity = 6 } } }, shadow = { stress = 2 }, chronicle = "The wandering road welcomed the household in its usual generous fashion: by charging the body first." },
                },
            },
        })
    end,
}

local function youth_event(game_state)
    local setup = profile_of(game_state) or {}
    local age = setup.start_age or 16
    return base_event("shadow_youth_first_reach", "youth", "The First Reach Beyond Permission", "At age " .. tostring(age) .. ", the life has started pressing beyond what elders, creditors, and better intentions would prefer. Something this year will be done for the first time without asking.", {
        {
            label = "Reach carefully and learn the edges",
            description = "Treat youth as a field to scout rather than a wall to strike.",
            check = { trait = "MEN_PAT", axis = "PER_CUR", difficulty = 55 },
            success = {
                narrative = "The first disobedience comes back carrying knowledge instead of disaster.",
                effects = { resources = { lore = 1 }, shadow = { craft = 1, stress = -1 }, chronicle = "The protagonist's first reach beyond permission returned with more knowledge than damage, which is rare enough to count as luck." },
            },
            failure = {
                narrative = "Curiosity opens a door that closes badly.",
                effects = { shadow = { stress = 2 }, chronicle = "Youth pushed too far and learned, in return, the exact width of the world's patience." },
            },
        },
        {
            label = "Reach boldly and let the year answer",
            description = "Some first actions are only worth taking if they arrive like a challenge.",
            check = { trait = "SOC_ELO", axis = "PER_BLD", difficulty = 57 },
            success = {
                narrative = "The audacity pays once, which is enough to make it dangerous later.",
                effects = { power = 1, shadow = { notoriety = 1 }, chronicle = "The protagonist reached beyond permission with enough force to make the year flinch first." },
            },
            failure = {
                narrative = "The bold reach is answered in the old adult language of consequence.",
                effects = { shadow = { stress = 2, standing = -1 }, chronicle = "Youth made itself conspicuous and the world, unfortunately, noticed." },
            },
        },
    })
end

local function scandal_event(game_state)
    local shadow = game_state and game_state.shadow_state or {}
    if (shadow.notoriety or 0) < 60 then
        return nil
    end
    return base_event("shadow_big_scandal", "big_swing", "Scandal Finds a Larger Room", "A private disgrace has crossed into public currency. The story has become useful to people who do not know you and therefore enjoy judging you more efficiently.", {
        {
            label = "Seize the story and name yourself first",
            description = "If the scandal is already marching, force it to wear your version of the face.",
            check = { trait = "SOC_ELO", axis = "PER_ADA", difficulty = 60 },
            success = {
                narrative = "The scandal survives, but it now serves more than one master.",
                effects = { shadow = { standing = 3, notoriety = 1, stress = 1 }, chronicle = "The protagonist met scandal with authorship and denied their enemies the pleasure of sole ownership." },
            },
            failure = {
                narrative = "The attempted correction only sharpens the appetite around the story.",
                effects = { shadow = { standing = -3, notoriety = 3, stress = 3 }, chronicle = "Trying to master the scandal merely proved that the scandal still had room to grow." },
            },
        },
        {
            label = "Feed the room a cleaner scandal",
            description = "If they want a ruin, give them another one and step aside while they feed.",
            gate = { axis = "PER_CRM", min = 53, label = "Cruelty" },
            check = { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 59 },
            success = {
                narrative = "The room turns on fresher meat, and your own name cools by comparison.",
                effects = { morality = { act = "betrayal" }, shadow = { standing = 1, notoriety = -1, stress = 1 }, chronicle = "The protagonist escaped scandal by teaching the room a more convenient cruelty." },
            },
            failure = {
                narrative = "The substitution is seen too clearly and counted against you twice.",
                effects = { morality = { act = "betrayal" }, shadow = { standing = -2, notoriety = 2, stress = 2 }, chronicle = "The attempted redirection left the room with two scandals instead of one and the protagonist embedded in both." },
            },
        },
    })
end

local function death_event(game_state)
    local body = ShadowBody.snapshot(game_state)
    local shadow = game_state and game_state.shadow_state or {}
    if (shadow.health or 50) > 30 and ((body.wound_load or 0) + (body.illness_load or 0)) < 42 then
        return nil
    end
    return base_event("shadow_big_death", "big_swing", "Death Waits in the Same House", "The body has stopped pretending this is an abstract argument. One bad week, one wrong choice, or one unkind season more could let death stop asking permission entirely.", {
        {
            label = "Spend everything to hold the body together",
            description = "Buy time with rest, medicine, and humiliating caution.",
            check = { trait = "MEN_WIL", axis = "PER_LOY", difficulty = 58 },
            success = {
                narrative = "The body remains yours, though at a poorer and narrower price than before.",
                effects = { wealth = -2, body = { ease_wounds = 10, ease_illnesses = 10 }, shadow = { health = 4, stress = 1, standing = -1 }, chronicle = "The protagonist forced another year out of a failing body by treating survival as a full occupation." },
            },
            failure = {
                narrative = "The bargain buys less time than it costs and leaves death better informed.",
                effects = { wealth = -2, body = { wounds = { { id = "wasting_decline", label = "Wasting Decline", severity = 12 } }, illnesses = { { id = "grave_fever", label = "Grave Fever", severity = 12 } } }, shadow = { health = -6, stress = 3 }, chronicle = "The attempt to outbid death left the protagonist living and more clearly in debt to the future than before." },
            },
        },
        {
            label = "Walk into the danger and dare it to finish",
            description = "Sometimes defiance is only another form of despair wearing stronger posture.",
            check = { trait = "PHY_VIT", axis = "PER_BLD", difficulty = 60 },
            success = {
                narrative = "You survive the stroke of danger and become harder to frighten for exactly the wrong reason.",
                effects = { body = { wounds = { { id = "death_near_miss", label = "Death Near-Miss", severity = 8 } } }, shadow = { health = -1, standing = 2, notoriety = 1 }, chronicle = "The protagonist walked into danger badly enough to brush death and came back with the sort of courage that often ages into recklessness." },
            },
            failure = {
                narrative = "The body pays for the gesture more honestly than the spirit does.",
                effects = { body = { wounds = { { id = "death_near_miss", label = "Death Near-Miss", severity = 16 } }, illnesses = { { id = "organ_shock", label = "Organ Shock", severity = 10 } } }, shadow = { health = -8, stress = 4, standing = -1 }, chronicle = "The challenge thrown at death was answered in flesh." },
            },
        },
    })
end

local function duel_event(game_state)
    local detail = ShadowBonds.detail_snapshot(game_state)
    local rival = nil
    for _, bond in ipairs(detail.bonds or {}) do
        if bond.category == "rival" then
            rival = bond
            break
        end
    end
    local feud_ready = rival
        and (
            (rival.strain or 0) >= 68
            or ((rival.thread_heat or 0) >= 74 and (rival.thread_stage or 1) >= 3)
        )
    if not feud_ready then
        return nil
    end
    return base_event("shadow_big_duel", "big_swing", rival.name .. " Demands a Public Reckoning", rival.name .. " has let the quarrel grow ceremonial. There will be witnesses, a narrow ground, and the usual lie that public violence clarifies anything except hierarchy.", {
        {
            label = "Meet them steel to steel",
            description = "Answer the feud in its preferred language and let the room watch who remains standing.",
            check = { trait = "PHY_STR", axis = "PER_BLD", difficulty = 60 },
            success = {
                narrative = "You win the ground and inherit the witness-field around it.",
                effects = { power = 3, body = { wounds = { { id = "duel_cut", label = "Duel Cut", severity = 8 } } }, bond = { id = rival.id, strain = -10, leverage = -6, closeness = -2 }, shadow = { standing = 2, notoriety = 1 }, chronicle = "The public duel with " .. rival.name .. " ended with the protagonist still standing and the feud forced to learn a new shape." },
            },
            failure = {
                narrative = "You leave blood on the ground and dignity in the witnesses' mouths.",
                effects = { power = -2, body = { wounds = { { id = "duel_cut", label = "Duel Cut", severity = 16 } } }, bond = { id = rival.id, strain = 6, leverage = 4 }, shadow = { standing = -2, stress = 2, notoriety = 1 }, chronicle = "The duel gave " .. rival.name .. " the cleaner ending and the protagonist the more expensive scar." },
            },
        },
        {
            label = "Turn the duel into a courtroom instead",
            description = "Refuse the blade and force the feud to survive under words, witnesses, and accusation.",
            check = { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 59 },
            success = {
                narrative = "The room accepts the substitution and starts weighing the feud more cautiously.",
                effects = { bond = { id = rival.id, strain = -5, leverage = -2 }, shadow = { standing = 2, stress = -1 }, chronicle = "The protagonist refused the duel's clean brutality and forced the feud to live under a meaner but less mortal kind of scrutiny." },
            },
            failure = {
                narrative = "The refusal looks strategic to your allies and cowardly to everyone else.",
                effects = { bond = { id = rival.id, strain = 4, leverage = 3 }, shadow = { standing = -2, stress = 2 }, chronicle = "The denied duel left the quarrel intact and the room unconvinced for the worst possible reasons." },
            },
        },
    })
end

local function inheritance_event(game_state)
    local career = game_state and game_state.shadow_career or {}
    local claim = game_state and game_state.shadow_claim or {}
    local possessions = ShadowPossessions.snapshot(game_state)
    local has_opening = (career.stability or 0) >= 48
        or (career.income or 0) >= 42
        or (claim.proof or 0) >= 46
        or (possessions and ((possessions.place_count or 0) + (possessions.item_count or 0) >= 4))
    if not has_opening then
        return nil
    end
    return base_event("shadow_big_inheritance", "big_swing", "An Inheritance Is Mentioned, Poorly", "A death or legal weakness elsewhere has opened the possibility of a room, a chest, a title-fragment, or a debt-laced inheritance sliding toward your branch if you are willing to fight for polluted gain.", {
        {
            label = "Press the claim before cleaner hands arrive",
            description = "Take the inheritance knowing it comes with obligations, witnesses, and mold in the joints.",
            check = { trait = "SOC_NEG", axis = "PER_PRI", difficulty = 58 },
            success = {
                narrative = "You come away holding something tangible and several new reasons to regret it later.",
                effects = {
                    resources = { gold = 3, lore = 1 },
                    wealth = 3,
                    power = 2,
                    shadow = { standing = 1 },
                    possessions = {
                        add = {
                            {
                                id = "inheritance_room",
                                label = "Inheritance Room",
                                kind = "place",
                                status = "Contested",
                                upkeep = 1,
                                yield = 2,
                                weight = "claimed",
                                stain = 1,
                            },
                            {
                                id = "inheritance_chest",
                                label = "Inheritance Chest",
                                kind = "item",
                                status = "Sealed",
                                upkeep = 0,
                                yield = 2,
                                weight = "dust-heavy",
                                stain = 1,
                            },
                        },
                    },
                    chronicle = "The protagonist pressed the dirty inheritance hard enough to make it theirs before more reputable predators could arrive.",
                },
            },
            failure = {
                narrative = "The bid draws attention without ownership.",
                effects = { wealth = -1, shadow = { stress = 2, standing = -1 }, chronicle = "The inheritance was contested loudly enough to stain the protagonist and not loudly enough to enrich them." },
            },
        },
        {
            label = "Refuse the poisoned gift",
            description = "Let another branch inherit the rot and keep your own hands lighter.",
            check = { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 56 },
            success = {
                narrative = "You keep less wealth and more room to breathe.",
                effects = { shadow = { stress = -1, standing = 1 }, morality = { delta = 1 }, chronicle = "The protagonist refused the offered inheritance and let another house inherit the mold inside it." },
            },
            failure = {
                narrative = "The refusal is read as weakness by people who only understand appetite.",
                effects = { shadow = { standing = -1, stress = 1 }, chronicle = "Declining the inheritance improved the soul more than the reputation." },
            },
        },
    })
end

local function disappearance_event(game_state)
    local shadow = game_state and game_state.shadow_state or {}
    local detail = ShadowBonds.detail_snapshot(game_state)
    local target = detail.most_urgent or detail.strongest
    local disappearance_ready = (shadow.stress or 0) >= 72
        or (
            target
            and (target.thread_autonomy or 0) >= 66
            and (target.thread_stage or 1) >= 3
        )
    if not disappearance_ready then
        return nil
    end
    local target_name = target and target.name or "Someone close enough to matter"
    return base_event("shadow_big_disappearance", "big_swing", target_name .. " Cannot Be Found", target_name .. " has vanished from the places where they should have been easy to hate, love, or count on. Their absence has already started reorganizing the web around it.", {
        {
            label = "Search personally and hard",
            description = "Treat the disappearance as a wound in the life, not a rumor to be managed later.",
            check = { trait = "MEN_PAT", axis = "PER_LOY", difficulty = 58 },
            success = {
                narrative = "You find the edge of the disappearance before the city fully seals over it.",
                effects = { shadow = { stress = 1, bonds = 2 }, bond = target and { id = target.id, closeness = 4, strain = -1, obligation = 2 } or nil, chronicle = "The protagonist searched for " .. target_name .. " personally and found enough of the trail to keep absence from becoming a final grammar." },
            },
            failure = {
                narrative = "The search teaches you how many places a person can vanish before the city calls it ordinary.",
                effects = { shadow = { stress = 4, bonds = -1 }, bond = target and { id = target.id, strain = 4, heat_delta = 5 } or nil, chronicle = "The search for " .. target_name .. " found effort, rumor, and very little else." },
            },
        },
        {
            label = "Turn the disappearance into leverage",
            description = "Someone will profit from the gap. Decide it might as well be you.",
            gate = { axis = "PER_CRM", min = 52, label = "Cruelty" },
            check = { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 58 },
            success = {
                narrative = "You gain room, though the room feels colder than it did when occupied.",
                effects = { morality = { act = "exploitation" }, wealth = 2, shadow = { standing = 1, notoriety = 1 }, chronicle = "The disappearance was used as an opening before grief had time to fully arrive." },
            },
            failure = {
                narrative = "People notice exactly how quickly you began measuring the empty space.",
                effects = { morality = { act = "exploitation" }, shadow = { standing = -2, stress = 2, notoriety = 2 }, chronicle = "Using the disappearance too quickly taught the room what kind of appetite the protagonist had been hiding." },
            },
        },
    })
end

local function arrest_event(game_state)
    local shadow = game_state and game_state.shadow_state or {}
    local claim = game_state and game_state.shadow_claim or {}
    local exposed_enough = (claim.exposure or 0) >= 58 or (claim.usurper_risk or 0) >= 44
    local notorious_and_exposed = (shadow.notoriety or 0) >= 70 and (claim.exposure or 0) >= 42
    if not (exposed_enough or notorious_and_exposed) then
        return nil
    end
    return base_event("shadow_big_arrest", "big_swing", "Men with Authority Arrive Early", "The law, or something close enough to wear its coat, arrives at an hour meant to humiliate. Whether the charge is honest matters less than whether it can be made to hold long enough to break momentum.", {
        {
            label = "Submit and prepare the defense",
            description = "Let the arrest happen in public so the later answer can happen there too.",
            check = { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 58 },
            success = {
                narrative = "The law closes around you briefly and finds you harder to keep than expected.",
                effects = { shadow = { standing = 1, stress = 2, notoriety = 1 }, claim = { exposure = 2 }, chronicle = "The protagonist submitted to arrest long enough to make the later release look less like luck than resilience." },
            },
            failure = {
                narrative = "The cell teaches the room what to call you before you can answer back.",
                effects = { shadow = { standing = -3, stress = 4, notoriety = 2 }, claim = { exposure = 4, usurper_risk = 2 }, chronicle = "The arrest entered the public record ahead of any defense and left a stain that argued well for itself." },
            },
        },
        {
            label = "Run and make the charge earn its breath",
            description = "If law wants the body, let it work for the privilege.",
            check = { trait = "PHY_VIT", axis = "PER_BLD", difficulty = 59 },
            success = {
                narrative = "You escape the hands if not the story.",
                effects = { shadow = { stress = 2, notoriety = 3 }, claim = { exposure = 3, usurper_risk = 3 }, chronicle = "The protagonist ran from arrest and left the law with only the story of not having caught them." },
            },
            failure = {
                narrative = "The run becomes part of the charge and the bruises part of the lesson.",
                effects = { body = { wounds = { { id = "custody_beating", label = "Custody Beating", severity = 12 } } }, shadow = { standing = -2, stress = 4, notoriety = 3 }, claim = { exposure = 5, usurper_risk = 4 }, chronicle = "Flight failed in the practical sense and succeeded only in making the arrest feel deserved to people who already wanted it to be." },
            },
        },
    })
end

local function miracle_event(game_state)
    local setup = profile_of(game_state) or {}
    local shadow = game_state and game_state.shadow_state or {}
    if setup.faith ~= "ancestor" and setup.faith ~= "old" and setup.faith ~= "cult" and (shadow.stress or 0) < 58 then
        return nil
    end
    return base_event("shadow_big_miracle", "big_swing", "A Miracle Asks to Be Interpreted", "A moment arrives that refuses the ordinary explanations gracefully available to it. The question becomes not whether it happened, but who gets to own the meaning before the room chooses for itself.", {
        {
            label = "Accept wonder and build a meaning around it",
            description = "Treat the miracle as a door rather than a trap and see who follows you through.",
            check = { trait = "CRE_RIT", axis = "PER_OBS", difficulty = 58 },
            success = {
                narrative = "The wonder remains dangerous, but now it bends at least slightly in your direction.",
                effects = { power = 3, resources = { lore = 2 }, shadow = { standing = 1, notoriety = 1 }, chronicle = "The protagonist accepted the miracle quickly enough to become part of its first authoritative meaning." },
            },
            failure = {
                narrative = "You reach for the wonder and come away with heat instead of insight.",
                effects = { shadow = { stress = 3, standing = -1 }, chronicle = "The miracle was approached too eagerly and left the protagonist scorched more than enlightened." },
            },
        },
        {
            label = "Expose the need beneath the wonder",
            description = "Even miracles often arrive hand-in-hand with hunger, theater, and timing.",
            check = { trait = "MEN_INT", axis = "PER_CUR", difficulty = 58 },
            success = {
                narrative = "The wonder shrinks just enough to become human again.",
                effects = { resources = { lore = 1 }, shadow = { standing = 1, stress = -1 }, chronicle = "The protagonist stripped enough theater from the miracle to reveal the human appetite beneath it." },
            },
            failure = {
                narrative = "The crowd prefers wonder and punishes the person who arrives carrying arithmetic.",
                effects = { shadow = { standing = -2, stress = 2, notoriety = 1 }, chronicle = "Reason addressed the miracle and was answered by a crowd that had no use for smaller explanations." },
            },
        },
    })
end

local function big_swing_event(game_state)
    local candidates = {
        arrest_event,
        death_event,
        duel_event,
        scandal_event,
        disappearance_event,
        miracle_event,
        inheritance_event,
    }
    for _, builder in ipairs(candidates) do
        local event = builder(game_state)
        if event then
            return event
        end
    end
    return nil
end

local function upheaval_event(game_state)
    local state = game_state and game_state.shadow_state or {}
    local setup = profile_of(game_state) or {}
    local claim = game_state and game_state.shadow_claim or {}
    if (state.notoriety or 0) >= 58 then
        return base_event("shadow_upheaval_scandal", "upheaval", "Your Name Is Said in the Wrong Rooms", "A story about you has crossed from private annoyance into public currency. The trouble is no longer whether it is true, but whether it is useful.", {
            {
                label = "Take hold of the story yourself",
                description = "If the scandal is already loose, teach it your own version of events.",
                check = { trait = "SOC_ELO", axis = "PER_ADA", difficulty = 59 },
                success = {
                    narrative = "The scandal survives, but now it serves more than one master.",
                    effects = { shadow = { standing = 2, notoriety = 1 }, chronicle = "The protagonist met scandal with authorship and made the story less obedient to their enemies than before." },
                },
                failure = {
                    narrative = "The attempted correction only proves the story deserves another hearing.",
                    effects = { shadow = { standing = -2, stress = 2, notoriety = 2 }, chronicle = "Trying to seize the scandal merely taught it how much room remained to grow." },
                },
            },
            {
                label = "Disappear until the room finds another appetite",
                description = "Retreat can still be strategy when the story has become louder than the self.",
                check = { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 57 },
                success = {
                    narrative = "The room cools and you return smaller, but still return.",
                    effects = { shadow = { stress = -1, standing = -1 }, chronicle = "The protagonist withdrew until the scandal found fresher meat and then stepped back into the ward with fewer witnesses still interested." },
                },
                failure = {
                    narrative = "Absence looks too much like confession to the people who wanted one.",
                    effects = { shadow = { stress = 2, standing = -2, notoriety = 1 }, chronicle = "Withdrawal granted the scandal a cleaner silhouette to hang itself upon." },
                },
            },
        })
    elseif (claim.exposure or 0) >= 52 or (claim.usurper_risk or 0) >= 48 then
        return base_event("shadow_upheaval_claim_heat", "upheaval", "The Denied Branch Draws Notice", "The old branch has begun appearing in conversations not meant for family ears. Some are curious. Some are preparing to be offended by your existence professionally.", {
            {
                label = "Gather proof before pride outruns it",
                description = "Force the claim back onto evidence while it still can be made to kneel there.",
                check = { trait = "MEN_INT", axis = "PER_OBS", difficulty = 58 },
                success = {
                    narrative = "The claim loses some heat and gains sharper bones.",
                    effects = { claim = { proof = 8, legitimacy = 4, exposure = -2 }, chronicle = "The denied branch was forced back into evidence and, for once, became slightly harder to dismiss." },
                },
                failure = {
                    narrative = "The search for proof only spreads the shape of the ambition.",
                    effects = { claim = { exposure = 5, usurper_risk = 3, grievance = 2 }, shadow = { stress = 2 }, chronicle = "Seeking proof for the old branch advertised the hunger beneath it at least as clearly as the case itself." },
                },
            },
            {
                label = "Lean into the danger and let them react",
                description = "Sometimes the claim must arrive like a threat before anyone remembers it is also a wound.",
                check = { trait = "SOC_ELO", axis = "PER_PRI", difficulty = 60 },
                success = {
                    narrative = "The room does not yield, but it does begin to brace.",
                    effects = { claim = { legitimacy = 4, exposure = 6, ambition = 4, usurper_risk = 2 }, shadow = { standing = 1, notoriety = 2 }, chronicle = "The protagonist let the denied branch enter the room like a danger and was, accordingly, remembered." },
                },
                failure = {
                    narrative = "The heat becomes accusation faster than it becomes legitimacy.",
                    effects = { claim = { exposure = 8, usurper_risk = 5 }, shadow = { standing = -1, stress = 2, notoriety = 2 }, chronicle = "The old branch arrived hotter than the room was willing to call lawful." },
                },
            },
        })
    end
    return nil
end

local BURDEN_EVENTS = {
    debt = function()
        return base_event("shadow_burden_creditor", "burden", "The Creditor Arrives Early", "The creditor comes before breakfast with two hired hands and a number that has somehow grown overnight.", {
            {
                label = "Pay enough to buy a month",
                description = "Bleed coin now and keep the door unbroken.",
                check = { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 54 },
                success = {
                    narrative = "The creditor leaves counting. You remain breathing and poorer.",
                    effects = { resources = { gold = -4 }, wealth = -4, chronicle = "The creditor was paid enough to leave and not enough to forget." },
                },
                failure = {
                    narrative = "The payment insults them. The month is not yours after all.",
                    effects = { resources = { gold = -3 }, wealth = -3, condition = { type = "exodus", intensity = 0.3, duration = 1 }, chronicle = "A partial payment proved partial in its usefulness." },
                },
            },
            {
                label = "Threaten them off the step",
                description = "Bet fear against arithmetic.",
                gate = { trait = "PHY_STR", min = 58, label = "Strength" },
                check = { trait = "PHY_STR", axis = "PER_BLD", difficulty = 60 },
                success = {
                    narrative = "They leave furious and unconvinced, which is still a kind of victory.",
                    effects = { power = 2, morality = { act = "pragmatism" }, chronicle = "The creditor withdrew under threat, writing the insult somewhere interest could later find it." },
                },
                failure = {
                    narrative = "One of the hired hands was waiting for exactly this kind of courage.",
                    effects = { wealth = -2, power = -2, condition = { type = "war_weariness", intensity = 0.2, duration = 1 }, chronicle = "The doorstep argument descended into the usual language of bruises." },
                },
            },
        })
    end,
    oath = function()
        return base_event("shadow_burden_oath", "burden", "The Oath Demands a Witness", "A messenger arrives to collect on a promise you inherited before you could consent to it.", {
            {
                label = "Honor it publicly",
                description = "Let the room see exactly what still rules you.",
                check = { trait = "MEN_WIL", axis = "PER_LOY", difficulty = 58 },
                success = {
                    narrative = "The oath binds tighter, but your name hardens with it.",
                    effects = { power = 2, morality = { act = "honoring_oath" }, chronicle = "The inherited oath was honored in public, which made it heavier and therefore more respectable." },
                },
                failure = {
                    narrative = "You keep the oath, but badly enough to embolden those who smell weakness in virtue.",
                    effects = { power = -1, morality = { act = "honoring_oath" }, chronicle = "The oath held. The dignity of its performance did not." },
                },
            },
            {
                label = "Break it before it owns you",
                description = "Destroy the chain while it is still only symbolic.",
                gate = { axis = "PER_ADA", min = 56, label = "Adaptability" },
                check = { axis = "PER_ADA", trait = "SOC_NEG", difficulty = 60 },
                success = {
                    narrative = "Freedom opens, but not cleanly. Someone older than you will remember.",
                    effects = { wealth = 1, morality = { act = "oath_breaking" }, power = 1, chronicle = "The oath was broken deliberately, which at least spared the protagonist the vulgar excuse of accident." },
                },
                failure = {
                    narrative = "The broken oath throws back more heat than light.",
                    effects = { wealth = -2, morality = { act = "oath_breaking" }, power = -2, chronicle = "Breaking the oath proved easier than escaping its witnesses." },
                },
            },
        })
    end,
    scar = function()
        return base_event("shadow_burden_scar", "burden", "The Scar Opens in the Cold", "The old wound wakes before dawn and asks what price will be paid this season for still carrying it.", {
            {
                label = "Work through it",
                description = "Take pain as an argument, not a command.",
                check = { trait = "MEN_WIL", axis = "PER_BLD", difficulty = 57 },
                success = {
                    narrative = "The day is won against the body, though not by much.",
                    effects = { power = 1, morality = { delta = 1 }, body = { ease_wounds = 8, preferred_wound = "old_scar" }, chronicle = "The old scar was carried through the day like a private liturgy of endurance." },
                },
                failure = {
                    narrative = "The body sets the terms after all.",
                    effects = { resources = { grain = -1 }, body = { wounds = { { id = "old_scar", label = "Old Scar", severity = 8 } } }, condition = { type = "war_weariness", intensity = 0.3, duration = 1 }, chronicle = "The scar reminded the protagonist that earlier violence still drew interest." },
                },
            },
            {
                label = "Buy a healer's attention",
                description = "Turn coin into relief, if relief is still for sale.",
                check = { trait = "SOC_NEG", axis = "PER_CUR", difficulty = 54 },
                success = {
                    narrative = "The healer helps, and leaves you with instructions nobody vigorous ever likes.",
                    effects = { resources = { gold = -2 }, wealth = -1, body = { ease_wounds = 10, preferred_wound = "old_scar" }, chronicle = "The healer extracted pain from the scar and money from the purse, leaving both lighter." },
                },
                failure = {
                    narrative = "The healer takes the coin and leaves the pain better informed.",
                    effects = { resources = { gold = -2 }, wealth = -2, chronicle = "Some treatments are merely expensive forms of weather." },
                },
            },
        })
    end,
    claim = function()
        return base_event("shadow_burden_claim", "burden", "The Claim Is Mentioned Aloud", "Someone in a crowded room speaks your denied claim as if testing whether the air itself objects.", {
            {
                label = "Press the matter",
                description = "If the wound is open, put your hand in it.",
                check = { trait = "SOC_ELO", axis = "PER_PRI", difficulty = 60 },
                success = {
                    narrative = "The room does not concede, but it starts measuring you differently.",
                    effects = { power = 3, wealth = 1, chronicle = "The denied claim entered the room and refused to kneel." },
                },
                failure = {
                    narrative = "You overplay it. Laughter is a kind of temporary defeat.",
                    effects = { power = -2, chronicle = "The claim was heard, weighed, and found entertaining." },
                },
            },
            {
                label = "Deny caring",
                description = "Bury the claim deeper and live longer with it.",
                check = { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 55 },
                success = {
                    narrative = "The room loses interest. You do not.",
                    effects = { morality = { delta = -1 }, wealth = 1, chronicle = "The claim was denied with a practiced face and an unpracticed pulse." },
                },
                failure = {
                    narrative = "The denial looks rehearsed in the wrong way.",
                    effects = { power = -1, chronicle = "Pretending not to want the claim only advertised its appetite." },
                },
            },
        })
    end,
    wanted = function()
        return base_event("shadow_burden_wanted", "burden", "Someone Knows the Face", "A stranger in the square looks too long and then too carefully away.", {
            {
                label = "Confront them first",
                description = "Force certainty before it can become pursuit.",
                check = { trait = "SOC_NEG", axis = "PER_BLD", difficulty = 58 },
                success = {
                    narrative = "The stranger talks fast and leaves faster. The city still feels smaller after.",
                    effects = { power = 2, condition = { type = "exodus", intensity = 0.2, duration = 1 }, chronicle = "The face was recognized and then, temporarily, discouraged." },
                },
                failure = {
                    narrative = "The confrontation confirms more than it conceals.",
                    effects = { wealth = -2, power = -2, condition = { type = "exodus", intensity = 0.5, duration = 2 }, chronicle = "The protagonist asked the wrong stranger the right question." },
                },
            },
            {
                label = "Leave town by dusk",
                description = "Live first. Explain later.",
                check = { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 54 },
                success = {
                    narrative = "You lose ground and keep the pulse.",
                    effects = { wealth = -1, condition = { type = "exodus", intensity = 0.4, duration = 2 }, chronicle = "The wiser part of the protagonist left town before pride could interfere." },
                },
                failure = {
                    narrative = "The exit is clumsy and therefore memorable.",
                    effects = { wealth = -2, power = -1, condition = { type = "exodus", intensity = 0.5, duration = 2 }, chronicle = "Flight worked in the technical sense and failed in every social one." },
                },
            },
        })
    end,
    parent = function()
        return base_event("shadow_burden_parent", "burden", "The Parent Worsens", "The fever returns. The room smells of vinegar, old sheets, and arithmetic nobody wants to do aloud.", {
            {
                label = "Sell something and call a better physician",
                description = "Trade future comfort for present hope.",
                check = { trait = "SOC_NEG", axis = "PER_LOY", difficulty = 55 },
                success = {
                    narrative = "The parent survives the week. So does your obligation.",
                    effects = { resources = { gold = -3 }, wealth = -2, morality = { act = "sacrifice" }, body = { illnesses = { { id = "caregiver_fever", label = "Caregiver Fever", severity = 6 } }, ease_illnesses = 2 }, chronicle = "Coin was traded for medicine and time, which is the oldest bargain and still the least reliable." },
                },
                failure = {
                    narrative = "The physician comes late and speaks softly, the way expensive men do near failure.",
                    effects = { resources = { gold = -3 }, wealth = -3, morality = { act = "sacrifice" }, body = { illnesses = { { id = "caregiver_fever", label = "Caregiver Fever", severity = 10 }, { id = "sleeplessness", label = "Sleeplessness", severity = 6 } } }, chronicle = "The physician improved the bedside manner more than the bedside." },
                },
            },
            {
                label = "Keep working and pray the fever breaks",
                description = "Duty to the living future against duty to the dying present.",
                check = { trait = "MEN_PAT", axis = "PER_CRM", difficulty = 52 },
                success = {
                    narrative = "The parent lives, and your guilt does too.",
                    effects = { wealth = 1, morality = { act = "abandonment" }, chronicle = "The workday was kept. So was the fever, though not permanently." },
                },
                failure = {
                    narrative = "You keep the wages and lose the argument with yourself.",
                    effects = { wealth = 1, morality = { act = "abandonment" }, power = -1, chronicle = "By the time the protagonist returned, the room had already become a place for speaking quietly." },
                },
            },
        })
    end,
}

local VICE_EVENTS = {
    drink = function()
        return base_event("shadow_vice_drink", "vice", "The Cup Finds You First", "A tavern keeper offers a private bottle and a private confidence that might be worth more sober than heard this way.", {
            {
                label = "Stay sober and listen",
                description = "Take the rumor without the fog.",
                check = { trait = "MEN_PAT", axis = "PER_OBS", difficulty = 55 },
                success = {
                    narrative = "You leave with useful gossip and the satisfaction of refusing yourself.",
                    effects = { resources = { lore = 1 }, morality = { delta = 1 }, body = { ease_compulsions = 8, preferred_compulsion = "drink_hunger" }, chronicle = "The cup was refused, which improved both memory and reputation with exactly one witness." },
                },
                failure = {
                    narrative = "You leave thirsty and none the wiser.",
                    effects = { power = -1, chronicle = "Restraint is less glamorous when it buys nothing." },
                },
            },
            {
                label = "Drink until the story becomes yours",
                description = "Some doors open easiest through appetite.",
                check = { trait = "SOC_ELO", axis = "PER_VOL", difficulty = 57 },
                success = {
                    narrative = "The room loosens. So does your mouth, but not fatally.",
                    effects = { resources = { gold = -1 }, wealth = -1, morality = { act = "pragmatism" }, body = { compulsions = { { id = "drink_hunger", label = "Bottle Hunger", severity = 8 } } }, chronicle = "Drink made the room generous enough to speak before it made the protagonist foolish enough to spoil it." },
                },
                failure = {
                    narrative = "The story comes, and so does the bill, and your discretion leaves before either.",
                    effects = { resources = { gold = -2 }, wealth = -2, morality = { act = "pragmatism" }, body = { compulsions = { { id = "drink_hunger", label = "Bottle Hunger", severity = 12 } }, illnesses = { { id = "morning_sickness", label = "Morning Sickness", severity = 6 } } }, chronicle = "The tavern took coin, dignity, and the clean edge of memory in one smooth motion." },
                },
            },
        })
    end,
    gaming = function()
        return base_event("shadow_vice_gaming", "vice", "The Dice Know Your Name", "A familiar table opens a seat exactly where your better judgment would least like to see it.", {
            {
                label = "Walk past it",
                description = "Let the hunger go unanswered once.",
                check = { trait = "MEN_WIL", axis = "PER_OBS", difficulty = 56 },
                success = {
                    narrative = "The refusal hurts like a wound and pays like one later.",
                    effects = { morality = { delta = 1 }, power = 1, body = { ease_compulsions = 8, preferred_compulsion = "gaming_hunger" }, chronicle = "The dice were refused, which is not the same as being forgotten." },
                },
                failure = {
                    narrative = "You keep walking in body only. The rest of you remains at the table.",
                    effects = { power = -1, chronicle = "Refusing the game was technically successful and spiritually fraudulent." },
                },
            },
            {
                label = "Sit and chase the turn",
                description = "Chance has ruined others more deserving than you.",
                check = { trait = "SOC_NEG", axis = "PER_BLD", difficulty = 58 },
                success = {
                    narrative = "Luck smiles just long enough to feel personal.",
                    effects = { resources = { gold = 2 }, wealth = 2, morality = { act = "theft" }, body = { compulsions = { { id = "gaming_hunger", label = "Gaming Hunger", severity = 8 } } }, chronicle = "The table yielded coin and strengthened the ancient superstition that luck has favorites." },
                },
                failure = {
                    narrative = "The table takes what it came for.",
                    effects = { resources = { gold = -3 }, wealth = -3, morality = { act = "theft" }, body = { compulsions = { { id = "gaming_hunger", label = "Gaming Hunger", severity = 12 } } }, chronicle = "The dice resumed the educational function for which they were invented." },
                },
            },
        })
    end,
    fervor = function()
        return base_event("shadow_vice_fervor", "vice", "The Zealot Requests Proof", "A devout stranger asks for an act of public certainty your cooler instincts would prefer to postpone.", {
            {
                label = "Refuse spectacle",
                description = "Keep faith private enough to survive it.",
                check = { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 55 },
                success = {
                    narrative = "You lose their admiration and keep your center.",
                    effects = { morality = { delta = 1 }, chronicle = "The demand for spectacle was refused in favor of a quieter and less theatrical piety." },
                },
                failure = {
                    narrative = "They call your caution cowardice, and the room agrees just enough to sting.",
                    effects = { power = -1, chronicle = "Restraint looked too much like fear from the wrong angle." },
                },
            },
            {
                label = "Give them a public sign",
                description = "Conviction grows easier once witnesses are watching.",
                check = { trait = "CRE_RIT", axis = "PER_LOY", difficulty = 57 },
                success = {
                    narrative = "The crowd bends toward you. So does trouble.",
                    effects = { power = 2, morality = { act = "ruthless_order" }, chronicle = "Public fervor made the protagonist briefly magnetic and therefore briefly dangerous." },
                },
                failure = {
                    narrative = "The sign feels forced, and everyone can tell except the faithful.",
                    effects = { power = -1, morality = { act = "ruthless_order" }, chronicle = "The performance of certainty convinced only the people most committed to being convinced." },
                },
            },
        })
    end,
    obsession = function()
        return base_event("shadow_vice_obsession", "vice", "The Thought Will Not Leave", "The same unfinished idea has begun arriving before sleep and staying after waking.", {
            {
                label = "Feed it",
                description = "Give it hours, paper, and blood if required.",
                check = { trait = "MEN_INT", axis = "PER_OBS", difficulty = 62 },
                success = {
                    narrative = "The obsession pays in insight and exacts the usual private interest.",
                    effects = { resources = { lore = 3 }, wealth = 1, morality = { delta = -1 }, body = { compulsions = { { id = "obsessive_fixation", label = "Obsessive Fixation", severity = 8 } }, illnesses = { { id = "sleeplessness", label = "Sleeplessness", severity = 4 } } }, chronicle = "The obsession was indulged and, in exchange, briefly became useful." },
                },
                failure = {
                    narrative = "The work deepens without clarifying.",
                    effects = { resources = { lore = 1 }, condition = { type = "war_weariness", intensity = 0.2, duration = 1 }, chronicle = "The unfinished thought fed well without producing anything edible." },
                },
            },
            {
                label = "Starve it for a week",
                description = "Prove to yourself that the thought does not own the body.",
                check = { trait = "MEN_WIL", axis = "PER_VOL", difficulty = 55 },
                success = {
                    narrative = "The mind quiets enough to hear the rest of life again.",
                    effects = { morality = { delta = 1 }, power = 1, body = { ease_compulsions = 8, preferred_compulsion = "obsessive_fixation" }, chronicle = "The obsession was denied its customary ration and did not, to its own surprise, kill the host." },
                },
                failure = {
                    narrative = "The denial only teaches the obsession where to wait.",
                    effects = { power = -1, chronicle = "Suppressing the thought merely taught it patience." },
                },
            },
        })
    end,
}

local FAITH_EVENTS = {
    state = function()
        return base_event("shadow_faith_state", "faith", "The Creed Wants a Public Gesture", "An official of the state creed asks for a visible service that will tie your name to theirs.", {
            {
                label = "Accept the public service",
                description = "Trade independence for sanctioned standing.",
                check = { trait = "SOC_LEA", axis = "PER_LOY", difficulty = 56 },
                success = {
                    narrative = "The office notices your obedience and rewards it just enough to be addictive.",
                    effects = { wealth = 1, power = 2, morality = { act = "honoring_oath" }, chronicle = "The state creed drew the protagonist into its public orbit with the usual mixture of honor and leash." },
                },
                failure = {
                    narrative = "You serve badly enough to be remembered and not well enough to be protected.",
                    effects = { power = -1, chronicle = "Official devotion proved less lucrative than advertised." },
                },
            },
            {
                label = "Decline politely",
                description = "Remain useful without becoming owned.",
                check = { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 55 },
                success = {
                    narrative = "The refusal lands softly. The distance remains.",
                    effects = { power = 1, chronicle = "The invitation was refused with sufficient grace to postpone retaliation." },
                },
                failure = {
                    narrative = "Politeness fails against institutions designed to resent it.",
                    effects = { power = -2, chronicle = "Refusal, however courteous, still counted as refusal." },
                },
            },
        })
    end,
    old = function()
        return base_event("shadow_faith_old", "faith", "The Old Place Is Open", "An older shrine than the law approves of stands open tonight and asks whether you still remember how to enter.", {
            {
                label = "Keep the rite",
                description = "Honor what survives by being hidden.",
                check = { trait = "CRE_RIT", axis = "PER_OBS", difficulty = 57 },
                success = {
                    narrative = "The rite steadies something in you that the sanctioned world never learned to touch.",
                    effects = { resources = { lore = 2 }, morality = { act = "forgiveness" }, chronicle = "At the hidden shrine, the protagonist kept faith with something older than permission." },
                },
                failure = {
                    narrative = "The rite is kept badly, which is still better than forgetting it.",
                    effects = { resources = { lore = 1 }, chronicle = "The old rite survived the performance even if the performer did not master it." },
                },
            },
            {
                label = "Report it instead",
                description = "Turn memory into favor with the present order.",
                gate = { axis = "PER_CRM", min = 52, label = "Cruelty" },
                check = { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 56 },
                success = {
                    narrative = "Officials thank you. The neighborhood does not.",
                    effects = { wealth = 1, morality = { act = "betrayal" }, power = 1, chronicle = "The hidden shrine was sold to the present by someone the past had assumed was still listening." },
                },
                failure = {
                    narrative = "The report reaches office slower than it reaches rumor.",
                    effects = { power = -1, morality = { act = "betrayal" }, chronicle = "The denunciation bought less favor than enmity." },
                },
            },
        })
    end,
    skeptic = function()
        return base_event("shadow_faith_skeptic", "faith", "A Wonder Is Claimed Nearby", "Everyone in the ward is suddenly certain a miracle happened across the river, which makes you suspect bookkeeping before divinity.", {
            {
                label = "Investigate the claim",
                description = "If it is a fraud, know it exactly.",
                check = { trait = "MEN_INT", axis = "PER_CUR", difficulty = 58 },
                success = {
                    narrative = "The miracle turns out mortal, profitable, and carefully staged.",
                    effects = { resources = { lore = 2 }, power = 1, chronicle = "The claimed wonder dissolved under scrutiny into craft, hunger, and a modest talent for timing." },
                },
                failure = {
                    narrative = "The investigation proves only that belief is better organized than truth.",
                    effects = { power = -1, chronicle = "The skeptic found facts insufficiently armed for the crowd." },
                },
            },
            {
                label = "Exploit the fervor",
                description = "If people need a wonder, sell them a smaller one.",
                gate = { trait = "SOC_ELO", min = 56, label = "Eloquence" },
                check = { trait = "SOC_ELO", axis = "PER_ADA", difficulty = 58 },
                success = {
                    narrative = "The crowd mistakes timing for revelation and rewards both.",
                    effects = { resources = { gold = 2 }, wealth = 2, morality = { act = "exploitation" }, chronicle = "The false wonder multiplied in the usual way: by meeting a real appetite." },
                },
                failure = {
                    narrative = "The crowd wants faith, not competition.",
                    effects = { wealth = -1, morality = { act = "exploitation" }, chronicle = "Competing with a miracle requires more charisma than fraud alone can supply." },
                },
            },
        })
    end,
}

local function instantiate(template_fn, game_state)
    if not template_fn then
        return nil
    end
    local event = template_fn(game_state)
    if not event then
        return nil
    end
    for _, option in ipairs(event.options or {}) do
        local available, reason = option_available(game_state, option)
        option.available = available
        option.gated_reason = reason
    end
    return event
end

local function finalize_event(event, game_state)
    if not event then
        return nil
    end
    for _, option in ipairs(event.options or {}) do
        local available, reason = option_available(game_state, option)
        option.available = available
        option.gated_reason = reason
    end
    return event
end

local function relationship_event(game_state)
    local detail = ShadowBonds.detail_snapshot(game_state)
    local bond = detail.most_urgent or detail.strongest
    if not bond then
        return nil
    end

    if bond.arc == "Dependent" then
        return base_event("shadow_relationship_dependent_" .. bond.id, "relationship", bond.name .. " Cannot Carry Their Share", bond.name .. " arrives with the exhausted face of someone who has already spent every other option. If you do not absorb the weight, no one else will.", {
            {
                label = "Take the full burden for now",
                description = "Spend the year keeping " .. bond.name .. " upright even if the cost lands squarely on your own body and purse.",
                check = { trait = "MEN_PAT", axis = "PER_LOY", difficulty = 57 },
                success = {
                    narrative = bond.name .. " remains yours to protect, and the tie deepens under the strain.",
                    effects = { wealth = -1, shadow = { bonds = 3, stress = 2, standing = 1 }, bond = { id = bond.id, closeness = 8, dependency = -4, obligation = 4, strain = -2, intimacy = 3 }, chronicle = "When " .. bond.name .. " could not stand alone, the protagonist absorbed the weight and called it love, duty, or merely arithmetic." },
                },
                failure = {
                    narrative = "You keep them afloat, but only by letting the rest of the life fray.",
                    effects = { wealth = -2, shadow = { bonds = 1, stress = 5, health = -1 }, bond = { id = bond.id, closeness = 3, dependency = 6, obligation = 6, strain = 4 }, chronicle = "Supporting " .. bond.name .. " consumed a year and left both parties more frightened of the next one." },
                },
            },
            {
                label = "Force them toward someone else",
                description = "Break the pattern before it finishes consuming the whole life.",
                check = { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 58 },
                success = {
                    narrative = "The dependence loosens, though not without resentment.",
                    effects = { shadow = { bonds = -1, stress = -1, standing = 1 }, bond = { id = bond.id, closeness = -2, dependency = -10, obligation = -4, strain = 4, leverage = 2 }, chronicle = "The protagonist shoved " .. bond.name .. " toward other hands and called the cruelty a necessary one." },
                },
                failure = {
                    narrative = "The attempt looks like abandonment from every angle that matters.",
                    effects = { shadow = { bonds = -3, stress = 3, notoriety = 1 }, bond = { id = bond.id, closeness = -5, dependency = 2, obligation = -2, strain = 8 }, chronicle = bond.name .. " learned exactly how conditional the protagonist's care could become once it grew expensive." },
                },
            },
        })
    elseif bond.status == "Hostile" or bond.arc == "Breaking" then
        return base_event("shadow_relationship_hostile_" .. bond.id, "relationship", bond.name .. " Stops Pretending", bond.name .. " no longer bothers with politeness. The quarrel has become a structure in the life, and everyone nearby already knows its floorplan.", {
            {
                label = "Meet them in private and end it cleanly",
                description = "Try to cut the feud back to human size before it grows into public ruin.",
                check = { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 59 },
                success = {
                    narrative = "The feud cools enough to stop ruling every room.",
                    effects = { shadow = { bonds = 2, stress = -1, standing = 1 }, bond = { id = bond.id, closeness = 2, strain = -10, leverage = -4 }, chronicle = "The protagonist met " .. bond.name .. " away from witnesses and returned with a feud reduced to survivable size." },
                },
                failure = {
                    narrative = "Privacy only gives the hatred cleaner acoustics.",
                    effects = { shadow = { bonds = -2, stress = 4, standing = -1 }, bond = { id = bond.id, strain = 8, leverage = 3 }, chronicle = "The private reckoning with " .. bond.name .. " merely refined the hostility and sent it back into the world better armed." },
                },
            },
            {
                label = "Use what you know against them",
                description = "End the problem by making sure their footing collapses first.",
                gate = { axis = "PER_CRM", min = 54, label = "Cruelty" },
                check = { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 58 },
                success = {
                    narrative = "The tie becomes uglier and less dangerous, which is still a gain.",
                    effects = { morality = { act = "betrayal" }, shadow = { stress = 1, notoriety = 2, standing = 1 }, bond = { id = bond.id, closeness = -4, strain = -2, leverage = 10, obligation = -4 }, chronicle = "The protagonist turned private knowledge against " .. bond.name .. " and bought safety at the usual moral exchange rate." },
                },
                failure = {
                    narrative = "The strike misses and leaves you looking exactly like what you are becoming.",
                    effects = { morality = { act = "betrayal" }, shadow = { stress = 3, notoriety = 3, standing = -2 }, bond = { id = bond.id, strain = 10, leverage = 4 }, chronicle = "The attempt to ruin " .. bond.name .. " failed cleanly enough to leave the protagonist publicly diminished and privately unmistakable." },
                },
            },
        })
    elseif bond.arc == "Compromised" or bond.arc == "Binding" then
        return base_event("shadow_relationship_bargain_" .. bond.id, "relationship", bond.name .. " Wants New Terms", "The tie with " .. bond.name .. " has grown dense with promises, favors, and remembered leverage. They want the arrangement rewritten before the year closes.", {
            {
                label = "Renegotiate in good faith",
                description = "Give up some advantage to make the bond survivable.",
                check = { trait = "SOC_NEG", axis = "PER_CUR", difficulty = 57 },
                success = {
                    narrative = "The tie loosens without breaking.",
                    effects = { wealth = -1, shadow = { bonds = 2, stress = -1, standing = 1 }, bond = { id = bond.id, leverage = -8, obligation = -5, closeness = 3, strain = -3 }, chronicle = "The protagonist and " .. bond.name .. " rewrote the terms of mutual use and managed, briefly, to sound like allies instead of accountants." },
                },
                failure = {
                    narrative = "The negotiation merely itemizes the damage.",
                    effects = { shadow = { stress = 3, standing = -1 }, bond = { id = bond.id, leverage = 4, obligation = 4, strain = 5 }, chronicle = "Trying to civilize the arrangement with " .. bond.name .. " only clarified how much of it had already curdled." },
                },
            },
            {
                label = "Exploit the advantage while you still can",
                description = "If the tie is already unequal, make the inequality pay before it turns on you.",
                gate = { axis = "PER_CRM", min = 52, label = "Cruelty" },
                check = { trait = "SOC_NEG", axis = "PER_PRI", difficulty = 58 },
                success = {
                    narrative = "The bargain worsens and the life becomes richer in precisely the wrong way.",
                    effects = { wealth = 2, morality = { act = "exploitation" }, shadow = { notoriety = 2, stress = 1 }, bond = { id = bond.id, leverage = 8, closeness = -2, strain = 4, obligation = 2 }, chronicle = "The protagonist leaned into the imbalance with " .. bond.name .. " and called the resulting profit necessity." },
                },
                failure = {
                    narrative = "They were waiting for you to become obvious.",
                    effects = { morality = { act = "exploitation" }, shadow = { standing = -2, stress = 3, notoriety = 2 }, bond = { id = bond.id, leverage = -2, closeness = -4, strain = 7 }, chronicle = bond.name .. " let the protagonist overreach and then made sure the overreach had witnesses." },
                },
            },
        })
    end

    return base_event("shadow_relationship_close_" .. bond.id, "relationship", bond.name .. " Asks What This Tie Is", "The bond with " .. bond.name .. " has deepened enough that vagueness now feels like cowardice. They want the relationship named, not merely inhabited.", {
        {
            label = "Speak plainly",
            description = "Risk honesty and let the tie become more exact.",
            check = { trait = "SOC_ELO", axis = "PER_LOY", difficulty = 56 },
            success = {
                narrative = "Naming the tie gives it weight and shelter in the same motion.",
                effects = { shadow = { bonds = 3, stress = -2 }, bond = { id = bond.id, closeness = 6, intimacy = 8, strain = -2, obligation = 2 }, chronicle = "The protagonist named what lay between them and " .. bond.name .. ", and the name held long enough to matter." },
            },
            failure = {
                narrative = "Clarity arrives without grace and leaves both of you exposed.",
                effects = { shadow = { bonds = -1, stress = 3 }, bond = { id = bond.id, closeness = -2, intimacy = 3, strain = 5 }, chronicle = "Trying to name the tie with " .. bond.name .. " gave the truth a shape and the truth gave the room a wound." },
            },
        },
        {
            label = "Keep it useful and unnamed",
            description = "Preserve the bond by refusing the kind of clarity that might force a costlier future.",
            check = { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 55 },
            success = {
                narrative = "The tie survives in ambiguity, which is sometimes the same thing as survival itself.",
                effects = { shadow = { stress = -1, standing = 1 }, bond = { id = bond.id, leverage = 2, intimacy = -1, obligation = -1 }, chronicle = "The protagonist left the bond with " .. bond.name .. " strategically unnamed and bought another year of usable ambiguity." },
            },
            failure = {
                narrative = "Evasion does the injury that direct speech might have avoided.",
                effects = { shadow = { bonds = -2, stress = 2 }, bond = { id = bond.id, closeness = -3, strain = 4, leverage = 3 }, chronicle = bond.name .. " heard the protagonist's refusal to name the tie and understood it with brutal accuracy." },
            },
        },
    })
end

local function claim_event(game_state)
    local setup = profile_of(game_state) or {}
    local house_name = setup.claim_house_name or "the elder house"
    return base_event(
        "shadow_claim_token",
        "claim",
        "A Relic of the Broken Branch",
        "An elder opens a wrapped bundle and shows you the sign of " .. house_name .. ". They say it was hidden when your blood was turned out and that names alone never restore what blood remembers.",
        {
            {
                label = "Study the proof in secret",
                description = "Take the token, the names, and the grievance into memory before the world can deny it again.",
                check = { trait = "MEN_PAT", axis = "PER_OBS", difficulty = 58 },
                success = {
                    narrative = "The proof is incomplete but real enough to alter the way the future looks at you.",
                    effects = { resources = { lore = 2 }, claim = { proof = 12, legitimacy = 8, grievance = 4 }, chronicle = "The protagonist received the first hard remnant of the denied house and learned that grievance becomes more dangerous when it can be footnoted." },
                },
                failure = {
                    narrative = "The thing is old, damaged, and easier to believe in than to use.",
                    effects = { claim = { proof = 6, grievance = 4 }, shadow = { stress = 2 }, chronicle = "The hidden relic of the denied branch proved genuine enough to wound and too incomplete to satisfy." },
                },
            },
            {
                label = "Show it to a witness with rank",
                description = "Force the matter into another mouth before fear can put it back under cloth.",
                check = { trait = "SOC_ELO", axis = "PER_BLD", difficulty = 57 },
                success = {
                    narrative = "The witness does not grant your right, but they stop calling it a fantasy.",
                    effects = { claim = { legitimacy = 10, exposure = 10, ambition = 6, path = "witness" }, shadow = { standing = 2, notoriety = 3 }, chronicle = "A witness of rank heard the old branch named and could not wholly laugh it away." },
                },
                failure = {
                    narrative = "The witness smiles the smile used for dangerous children and starts remembering your name too clearly.",
                    effects = { claim = { exposure = 12, usurper_risk = 6, grievance = 4, path = "witness" }, shadow = { stress = 3, notoriety = 4 }, chronicle = "The claim was shown too early and turned from private inheritance into public vulnerability." },
                },
            },
        }
    )
end

function ShadowEvents.generate(world, game_state)
    local setup = profile_of(game_state)
    if not setup then
        return {}
    end

    local story = ensure_story(game_state)
    local generation = game_state.generation or 1
    local events = {}
    local stress = game_state and game_state.shadow_state and game_state.shadow_state.stress or 50
    local bond_thread_limit = stress >= 70 and 3 or (stress >= 55 and 2 or 1)
    local aftermath_limit = stress >= 68 and 2 or 1

    local function maybe_add(id, template_fn)
        if not story.seen_events[id] then
            local event = instantiate(template_fn, game_state)
            if event then
                event.story_key = id
                events[#events + 1] = event
            end
        end
    end

    local function add_event(event)
        local finalized = finalize_event(event, game_state)
        if finalized then
            events[#events + 1] = finalized
        end
    end

    local function add_bond_threads(limit)
        for _, event in ipairs(ShadowBonds.generate_story_events(game_state, limit) or {}) do
            add_event(event)
        end
    end

    local function add_bond_aftermath(limit)
        for _, event in ipairs(ShadowBonds.generate_aftermath_events(game_state, limit) or {}) do
            add_event(event)
        end
    end

    if generation == 1 then
        maybe_add("claim:introduction", claim_event)
        maybe_add("youth:introduction", youth_event)
        maybe_add("birthplace:" .. tostring(setup.birthplace), BIRTHPLACE_EVENTS[setup.birthplace])
        maybe_add("occupation:" .. tostring(setup.occupation), OCCUPATION_EVENTS[setup.occupation])
        maybe_add("burden:" .. tostring(setup.burden), BURDEN_EVENTS[setup.burden])
        add_bond_threads(1)
    elseif generation == 2 then
        maybe_add("household:" .. tostring(setup.household), HOUSEHOLD_EVENTS[setup.household])
        if setup.vice and setup.vice ~= "none" then
            maybe_add("vice:" .. tostring(setup.vice), VICE_EVENTS[setup.vice])
        end
        maybe_add("faith:" .. tostring(setup.faith), FAITH_EVENTS[setup.faith])
        maybe_add("relationship:" .. tostring(generation), relationship_event)
        add_bond_aftermath(aftermath_limit)
        add_bond_threads(bond_thread_limit)
    elseif generation == 3 then
        maybe_add("burden_follow:" .. tostring(setup.burden), BURDEN_EVENTS[setup.burden])
        add_event(upheaval_event(game_state))
        add_event(big_swing_event(game_state))
        maybe_add("relationship:" .. tostring(generation), relationship_event)
        add_bond_aftermath(aftermath_limit)
        add_bond_threads(bond_thread_limit)
    elseif generation >= 4 then
        add_event(upheaval_event(game_state))
        add_event(big_swing_event(game_state))
        maybe_add("relationship:" .. tostring(generation), relationship_event)
        add_bond_aftermath(aftermath_limit)
        add_bond_threads(bond_thread_limit)
    end

    -- Claim hunter: escalating events driven by exposure and usurper risk
    for _, event in ipairs(ShadowClaimHunter.generate(game_state, generation) or {}) do
        events[#events + 1] = event
    end

    return events
end

function ShadowEvents.resolve(event, option_index, world, game_state)
    local option = event and event.options and event.options[option_index] or nil
    if not event or not option then
        return { narrative = "", consequence_lines = {} }
    end

    local story = ensure_story(game_state)
    story.seen_events[event.id] = true
    if event.story_key then
        story.seen_events[event.story_key] = true
    end

    local quality = check_quality(game_state, option)
    local branch = nil
    if quality == "triumph" or quality == "success" then
        branch = option.success
    else
        branch = option.failure
    end

    local reaction_lines = resolve_effect_bundle(world, game_state, branch and branch.effects, game_state.generation or 1)

    local consequence_lines = {}
    local profile = profile_of(game_state)
    if profile and profile.burden_label then
        consequence_lines[#consequence_lines + 1] = {
            text = "The burden remains: " .. profile.burden_label .. ".",
        }
    end
    if profile and profile.occupation_label then
        consequence_lines[#consequence_lines + 1] = {
            text = "This path exists because the protagonist is " .. string.lower(profile.occupation_label) .. ".",
        }
    end
    if profile and event.type == "origin" and profile.birthplace_label then
        consequence_lines[#consequence_lines + 1] = {
            text = "This omen is native to " .. string.lower(profile.birthplace_label) .. ".",
        }
    end
    if profile and event.type == "household" and profile.household_label then
        consequence_lines[#consequence_lines + 1] = {
            text = "The old house still rules part of this answer: " .. string.lower(profile.household_label) .. ".",
        }
    end
    if event.type == "upheaval" then
        consequence_lines[#consequence_lines + 1] = {
            text = "This pressure exists because the life has become loud enough to draw larger consequences.",
        }
    end
    if event.type == "big_swing" then
        consequence_lines[#consequence_lines + 1] = {
            text = "This was no ordinary year-turn. The life widened suddenly and demanded a harder answer.",
        }
    end
    if profile and event.type == "vice" and profile.vice_label then
        consequence_lines[#consequence_lines + 1] = {
            text = "The weakness at work here is " .. string.lower(profile.vice_label) .. ".",
        }
    end
    if event.type == "relationship" then
        local detail = ShadowBonds.detail_snapshot(game_state)
        if detail.most_urgent then
            consequence_lines[#consequence_lines + 1] = {
                text = "The tightest knot now is " .. detail.most_urgent.name .. " (" .. string.lower(detail.most_urgent.arc) .. ").",
            }
        end
    end
    if profile and event.type == "faith" and profile.faith_label then
        consequence_lines[#consequence_lines + 1] = {
            text = "This omen answers to " .. string.lower(profile.faith_label) .. ".",
        }
    end
    for _, line in ipairs(reaction_lines or {}) do
        consequence_lines[#consequence_lines + 1] = {
            text = line,
        }
    end

    return {
        narrative = branch and branch.narrative or event.narrative or "",
        consequence_lines = consequence_lines,
        stat_check_quality = quality,
    }
end

return ShadowEvents
