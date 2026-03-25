local Math = require("dredwork_core.math")
local Wealth = require("dredwork_world.wealth")
local Morality = require("dredwork_world.morality")
local ShadowCareer = require("dredwork_bonds.career")
local ShadowBonds = require("dredwork_bonds.bonds")
local ShadowBody = require("dredwork_bonds.body")
local ShadowClaim = require("dredwork_bonds.claim")
local ShadowPossessions = require("dredwork_bonds.possessions")
local ShadowExpectations = require("dredwork_bonds.expectations")
local ShadowWitnesses = require("dredwork_bonds.witnesses")
local ShadowSecrets = require("dredwork_bonds.secrets")
local ShadowCollusion = require("dredwork_bonds.collusion")

local ShadowYear = {}


local function setup_of(game_state)
    return game_state and game_state.shadow_setup or nil
end

local function trait(game_state, id)
    return game_state and game_state.current_heir and game_state.current_heir:get_value(id) or 50
end

local function axis(game_state, id)
    return game_state and game_state.heir_personality and game_state.heir_personality:get_axis(id) or 50
end

local function title_case_words(text)
    local lower = tostring(text or ""):lower()
    return (lower:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest
    end))
end

local function quality(score, difficulty)
    if score >= difficulty + 16 then
        return "triumph"
    elseif score >= difficulty then
        return "success"
    elseif score >= difficulty - 14 then
        return "failure"
    end
    return "disaster"
end

local function combine_score(game_state, check)
    if not check then
        return 50, nil
    end
    local total = 0
    local count = 0
    if check.trait then
        total = total + trait(game_state, check.trait)
        count = count + 1
    end
    if check.axis then
        total = total + axis(game_state, check.axis)
        count = count + 1
    end
    return count > 0 and (total / count) or 50, quality(count > 0 and (total / count) or 50, check.difficulty or 55)
end

local function add_resource_changes(world, deltas, heir_name, generation)
    if not world or not world.resources then
        return
    end
    for key, value in pairs(deltas or {}) do
        if value ~= 0 then
            world.resources:change(key, value, "shadow_year", heir_name, generation)
        end
    end
end

local function add_condition(world, payload)
    if not world or not world.world_state or not payload or not payload.type then
        return
    end
    world.world_state:add_condition(payload.type, payload.intensity or 0.25, payload.duration or 1)
end

local function add_chronicle(world, text)
    if not world or not world.world_state or not world.world_state.chronicle or not text or text == "" then
        return
    end
    world.world_state.chronicle[#world.world_state.chronicle + 1] = { text = text }
    while #world.world_state.chronicle > 20 do
        table.remove(world.world_state.chronicle, 1)
    end
end

local function shift_trait(game_state, id, delta)
    if not game_state or not game_state.current_heir or not id or not delta or delta == 0 then
        return
    end
    game_state.current_heir:set_value(id, Math.clamp((game_state.current_heir:get_value(id) or 50) + delta, 0, 100))
end

local function shift_axis(game_state, id, delta)
    if not game_state or not game_state.heir_personality or not id or not delta or delta == 0 then
        return
    end
    game_state.heir_personality.axes[id] = Math.clamp((game_state.heir_personality:get_axis(id) or 50) + delta, 0, 100)
end

local function metric_label(kind, value)
    local v = tonumber(value) or 0
    if kind == "health" then
        if v >= 72 then return "Hardy" end
        if v >= 56 then return "Steady" end
        if v >= 40 then return "Worn" end
        return "Broken"
    elseif kind == "stress" then
        if v >= 72 then return "Ragged" end
        if v >= 56 then return "Pressed" end
        if v >= 40 then return "Tense" end
        return "Calm"
    elseif kind == "bonds" then
        if v >= 72 then return "Entrenched" end
        if v >= 56 then return "Reliable" end
        if v >= 40 then return "Thin" end
        return "Alone"
    elseif kind == "standing" then
        if v >= 72 then return "Formidable" end
        if v >= 56 then return "Established" end
        if v >= 40 then return "Marginal" end
        return "Precarious"
    elseif kind == "notoriety" then
        if v >= 72 then return "Infamous" end
        if v >= 56 then return "Watched" end
        if v >= 40 then return "Rumored" end
        return "Obscure"
    elseif kind == "craft" then
        if v >= 72 then return "Mastered" end
        if v >= 56 then return "Seasoned" end
        if v >= 40 then return "Practiced" end
        return "Unproven"
    end
    return tostring(v)
end

local function build_next_hook(shadow, body, relationship_detail, claim)
    local urgent = relationship_detail and relationship_detail.most_urgent or nil
    if urgent and ((urgent.thread_state == "Crisis") or (urgent.thread_stage or 1) >= 4 or (urgent.urgency or 0) >= 96) then
        return urgent.name .. " will not stay quiet next year."
    end
    if claim and (((claim.exposure or 0) >= 60) or ((claim.usurper_risk or 0) >= 58)) then
        return "The denied branch is becoming dangerous to speak aloud."
    end
    if body and ((body.compulsion_load or 0) >= 34) then
        return "The habit will ask its price again next year."
    end
    if body and (((body.wound_load or 0) + (body.illness_load or 0)) >= 42) then
        return "The body is beginning to bargain like an enemy."
    end
    if shadow and ((shadow.stress or 0) >= 64) then
        return "Pressure is rising. Next year will come in harder."
    end
    if urgent then
        return urgent.name .. " is still moving under the surface."
    end
    return "The record is not done with this life yet."
end

local function build_loop_preview(game_state)
    local detail = ShadowBonds.detail_snapshot(game_state)
    local body = ShadowBody.snapshot(game_state)
    local claim = ShadowClaim.snapshot(game_state)
    local career = ShadowCareer.snapshot(game_state)
    local possessions = ShadowPossessions.snapshot(game_state)

    local prize = "A steadier place in the world is within reach."
    if claim and ((claim.proof or 0) < 56) and (((claim.grievance or 0) >= 52) or has_possession(possessions, "branch_token")) then
        prize = "The denied branch could become more speakable next year."
    elseif detail and detail.intimate then
        prize = detail.intimate.name .. " could become indispensable if you do not fumble the tie."
    elseif career and (career.rank or 0) < 55 then
        prize = "A cleaner station is close enough to chase."
    elseif possessions and ((possessions.place_count or 0) == 0 or (possessions.yield or 0) <= 2) then
        prize = "A better room or tool could change what this life can attempt."
    end

    local risk = "The next year could still be an ordinary loss."
    if body and (((body.wound_load or 0) + (body.illness_load or 0)) >= 34) then
        risk = "The body is beginning to ask for years back."
    elseif body and (body.compulsion_load or 0) >= 24 then
        risk = "Habit is close to choosing for you."
    elseif detail and detail.rival then
        risk = detail.rival.name .. " is close to turning private strain into public harm."
    elseif claim and ((claim.exposure or 0) >= 56 or (claim.usurper_risk or 0) >= 52) then
        risk = "The branch-story is growing loud enough to start costing you."
    end

    local rows = {
        { label = "LOUDEST THREAD", value = detail and (detail.storyline_line or "No thread has risen above the noise yet.") or "No thread has risen above the noise yet." },
        { label = "NEAREST PRIZE", value = prize },
        { label = "BIGGEST RISK", value = risk },
    }

    local urge_line = "One more year could either harden the life into shape or let the wrong person shape it first."
    if detail and detail.most_urgent and detail.most_urgent.thread_state == "Crisis" then
        urge_line = detail.most_urgent.name .. " is already in crisis. Delay is a choice with teeth."
    elseif claim and ((claim.proof or 0) >= 56) and ((claim.legitimacy or 0) >= 46) then
        urge_line = "The claim is close enough to touch that the next year might finally make it real."
    elseif career and (career.rank or 0) >= 42 then
        urge_line = "The life is starting to take form. Another year could lock it in."
    end

    return {
        chase_rows = rows,
        urge_line = urge_line,
    }
end

local function build_progress_rows(before, after)
    local rows = {}
    if not before or not after then
        return rows
    end

    if after.shadow and before.shadow then
        if after.shadow.craft_label ~= before.shadow.craft_label then
            rows[#rows + 1] = { label = "CRAFT TURNED", value = before.shadow.craft_label .. " -> " .. after.shadow.craft_label, tone = "good" }
        end
        if after.shadow.standing_label ~= before.shadow.standing_label then
            rows[#rows + 1] = { label = "STANDING SHIFTED", value = before.shadow.standing_label .. " -> " .. after.shadow.standing_label, tone = "gold" }
        end
        if after.shadow.notoriety_label ~= before.shadow.notoriety_label then
            rows[#rows + 1] = { label = "NAME CHANGED", value = before.shadow.notoriety_label .. " -> " .. after.shadow.notoriety_label, tone = "bad" }
        end
    end

    if after.claim and before.claim then
        if after.claim.status ~= before.claim.status then
            rows[#rows + 1] = { label = "CLAIM MOVED", value = before.claim.status .. " -> " .. after.claim.status, tone = "bad" }
        elseif after.claim.proof_label ~= before.claim.proof_label then
            rows[#rows + 1] = { label = "PROOF SHIFTED", value = before.claim.proof_label .. " -> " .. after.claim.proof_label, tone = "gold" }
        end
    end

    if after.career and before.career then
        if after.career.title ~= before.career.title then
            rows[#rows + 1] = { label = "CAREER HARDENED", value = before.career.title .. " -> " .. after.career.title, tone = "good" }
        elseif (after.career.rank or 0) ~= (before.career.rank or 0) then
            rows[#rows + 1] = { label = "RANK MOVED", value = tostring(before.career.rank or 0) .. " -> " .. tostring(after.career.rank or 0), tone = "good" }
        end
    end

    if after.possessions and before.possessions then
        local before_total = (before.possessions.item_count or 0) + (before.possessions.place_count or 0) + (before.possessions.people_count or 0)
        local after_total = (after.possessions.item_count or 0) + (after.possessions.place_count or 0) + (after.possessions.people_count or 0)
        if after_total ~= before_total then
            rows[#rows + 1] = {
                label = after_total > before_total and "HOLDINGS GREW" or "HOLDINGS THINNED",
                value = tostring(before_total) .. " -> " .. tostring(after_total),
                tone = after_total > before_total and "good" or "bad",
            }
        end
    end

    if after.body and before.body then
        if after.body.wound_label ~= before.body.wound_label then
            rows[#rows + 1] = { label = "BODY MARKED", value = before.body.wound_label .. " -> " .. after.body.wound_label, tone = "bad" }
        elseif after.body.compulsion_label ~= before.body.compulsion_label then
            rows[#rows + 1] = { label = "HABIT SHIFTED", value = before.body.compulsion_label .. " -> " .. after.body.compulsion_label, tone = "bad" }
        end
    end

    if after.relationship_detail and before.relationship_detail then
        local after_urgent = after.relationship_detail.most_urgent
        local before_urgent = before.relationship_detail.most_urgent
        if after_urgent and before_urgent and after_urgent.name ~= before_urgent.name then
            rows[#rows + 1] = { label = "WEB TIGHTENED", value = before_urgent.name .. " -> " .. after_urgent.name, tone = "gold" }
        elseif after_urgent and before_urgent and after_urgent.thread_state ~= before_urgent.thread_state then
            rows[#rows + 1] = { label = "THREAD DEEPENED", value = after_urgent.name .. " | " .. before_urgent.thread_state .. " -> " .. after_urgent.thread_state, tone = "gold" }
        end
    end

    while #rows > 4 do
        table.remove(rows)
    end
    return rows
end

function ShadowYear.ensure_state(game_state)
    game_state.shadow_state = game_state.shadow_state or {}
    local state = game_state.shadow_state
    local setup = setup_of(game_state) or {}
    ShadowBody.ensure_state(game_state)

    if state.initialized then
        return state
    end

    local health = 58 + math.floor((trait(game_state, "PHY_VIT") - 50) * 0.20)
    local bonds = 34 + math.floor((axis(game_state, "PER_LOY") - 50) * 0.18)
    local standing = 36 + math.floor((trait(game_state, "SOC_LEA") - 50) * 0.22)
    local notoriety = 18 + math.floor((axis(game_state, "PER_BLD") - 50) * 0.14)
    local craft = 40
    local stress = 42

    if setup.occupation == "soldier" then
        standing = standing + 6
        stress = stress + 8
        notoriety = notoriety + 5
    elseif setup.occupation == "courtier" then
        standing = standing + 9
        bonds = bonds + 4
        notoriety = notoriety + 4
    elseif setup.occupation == "scribe" then
        craft = craft + 8
    elseif setup.occupation == "tinker" then
        craft = craft + 10
        stress = stress + 3
    elseif setup.occupation == "performer" then
        bonds = bonds + 6
        notoriety = notoriety + 6
    elseif setup.occupation == "laborer" then
        health = health + 4
        craft = craft + 3
    end

    if setup.burden == "debt" then
        stress = stress + 9
    elseif setup.burden == "wanted" then
        notoriety = notoriety + 12
        stress = stress + 6
    elseif setup.burden == "parent" then
        bonds = bonds + 7
        stress = stress + 5
    elseif setup.burden == "scar" then
        health = health - 8
    elseif setup.burden == "claim" then
        standing = standing + 4
        notoriety = notoriety + 5
    elseif setup.burden == "oath" then
        bonds = bonds + 5
        stress = stress + 4
    end

    if setup.vice == "drink" then
        health = health - 5
        stress = stress + 4
    elseif setup.vice == "gaming" then
        stress = stress + 5
        notoriety = notoriety + 3
    elseif setup.vice == "obsession" then
        craft = craft + 5
        stress = stress + 6
    elseif setup.vice == "fervor" then
        standing = standing + 3
        notoriety = notoriety + 2
    end

    state.health = Math.clamp(health, 10, 95)
    state.stress = Math.clamp(stress, 5, 95)
    state.bonds = Math.clamp(bonds, 5, 95)
    state.standing = Math.clamp(standing, 5, 95)
    state.notoriety = Math.clamp(notoriety, 0, 95)
    state.craft = Math.clamp(craft, 5, 95)
    state.yearly_actions_taken = state.yearly_actions_taken or 0
    state.last_focus = state.last_focus or "survive"
    state.initialized = true
    return state
end

function ShadowYear.snapshot(game_state)
    local state = ShadowYear.ensure_state(game_state)
    local loop = build_loop_preview(game_state)
    return {
        health = state.health,
        stress = state.stress,
        bonds = state.bonds,
        standing = state.standing,
        notoriety = state.notoriety,
        craft = state.craft,
        health_label = metric_label("health", state.health),
        stress_label = metric_label("stress", state.stress),
        bonds_label = metric_label("bonds", state.bonds),
        standing_label = metric_label("standing", state.standing),
        notoriety_label = metric_label("notoriety", state.notoriety),
        craft_label = metric_label("craft", state.craft),
        last_focus = title_case_words((state.last_focus or "survive"):gsub("_", " ")),
        chase_rows = loop.chase_rows,
        urge_line = loop.urge_line,
    }
end

local function base_action(id, title, subtitle, description, check, branches)
    return {
        id = id,
        title = title,
        subtitle = subtitle,
        description = description,
        check = check,
        success = branches.success,
        failure = branches.failure,
    }
end

local function occupation_action(setup)
    local occupation = setup and setup.occupation or "laborer"
    if occupation == "scribe" then
        return base_action("occupation_scribe", "Work the Ledgers by Candle", "Career", "Spend the year buried in records, ink, and private leverage.", { trait = "MEN_INT", axis = "PER_OBS", difficulty = 58 }, {
            success = { narrative = "The ledgers yield leverage, not merely wages.", effects = { resources = { lore = 2, gold = 1 }, wealth = 2, shadow = { craft = 5, standing = 3, stress = 2 }, trait = { MEN_INT = 1 }, chronicle = "The protagonist vanished into the ledgers for a year and came back with cleaner numbers and dirtier leverage." } },
            failure = { narrative = "The work consumes the year without improving your position much.", effects = { shadow = { craft = 2, stress = 4 }, wealth = -1, chronicle = "A year in the ledgers produced fatigue in abundance and advantage only in rumor." } },
        })
    elseif occupation == "soldier" then
        return base_action("occupation_soldier", "Sell the Sword Again", "Career", "Take paid violence where the state prefers unofficial hands.", { trait = "PHY_STR", axis = "PER_BLD", difficulty = 60 }, {
            success = { narrative = "The contract hardens your name and your purse.", effects = { resources = { steel = 2, gold = 2 }, wealth = 2, morality = { act = "cruelty" }, shadow = { standing = 4, notoriety = 5, stress = 5, health = -2, craft = 2 }, body = { wounds = { { id = "fresh_bruising", label = "Fresh Bruising", severity = 8 } } }, trait = { PHY_STR = 1 }, chronicle = "The protagonist sold steel for another year and returned with coin, bruises, and a name that traveled ahead of them." } },
            failure = { narrative = "The contract pays in scars and half-kept promises.", effects = { wealth = -1, shadow = { notoriety = 3, stress = 7, health = -5 }, body = { wounds = { { id = "sword_cut", label = "Sword Cut", severity = 16 } }, illnesses = { { id = "camp_fever", label = "Camp Fever", severity = 10 } } }, condition = { type = "war_weariness", intensity = 0.25, duration = 1 }, chronicle = "The year's soldiering proved more memorable to the body than to the purse." } },
        })
    elseif occupation == "courtier" then
        return base_action("occupation_courtier", "Pursue Patronage", "Career", "Spend the year turning wit, beauty, and obedience into standing.", { trait = "SOC_ELO", axis = "PER_PRI", difficulty = 59 }, {
            success = { narrative = "The room accepts you, which is never the same as trusting you.", effects = { resources = { gold = 3 }, wealth = 3, shadow = { standing = 6, bonds = 3, notoriety = 3, stress = 2 }, trait = { SOC_ELO = 1 }, chronicle = "The court admitted the protagonist more fully this year, which merely changed the quality of the knives." } },
            failure = { narrative = "You remain visible without becoming secure.", effects = { wealth = -1, shadow = { standing = -2, notoriety = 4, stress = 5 }, chronicle = "The year at court taught visibility without protection." } },
        })
    elseif occupation == "tinker" then
        return base_action("occupation_tinker", "Build in Secret", "Career", "Spend the year on craft that might become livelihood or evidence.", { trait = "CRE_TIN", axis = "PER_CUR", difficulty = 58 }, {
            success = { narrative = "The work holds. So does your confidence.", effects = { resources = { lore = 2, steel = 1 }, wealth = 2, shadow = { craft = 6, stress = 2, standing = 2 }, body = { wounds = { { id = "burned_hands", label = "Burned Hands", severity = 6 } }, ease_compulsions = 2 }, trait = { CRE_TIN = 1 }, chronicle = "The workshop kept the protagonist through the year and produced one fewer failure than expected." } },
            failure = { narrative = "The project teaches more than it earns.", effects = { wealth = -2, shadow = { craft = 2, stress = 6 }, body = { wounds = { { id = "burned_hands", label = "Burned Hands", severity = 14 } } }, chronicle = "A year vanished into sparks, scrap, and stubbornness." } },
        })
    elseif occupation == "performer" then
        return base_action("occupation_performer", "Play the High Room", "Career", "Chase richer audiences and the danger that comes with being remembered.", { trait = "CRE_NAR", axis = "PER_VOL", difficulty = 57 }, {
            success = { narrative = "The room wants more of you than is safe, which is better than obscurity.", effects = { resources = { gold = 2 }, wealth = 2, shadow = { bonds = 4, notoriety = 6, standing = 2, stress = 3 }, trait = { CRE_NAR = 1 }, chronicle = "The protagonist played brighter rooms this year and left more mouths speaking their name than before." } },
            failure = { narrative = "The applause was thin and the enemies better funded.", effects = { wealth = -1, shadow = { notoriety = 2, stress = 5, bonds = -1 }, chronicle = "Performance kept the protagonist fed and not much else." } },
        })
    end

    return base_action("occupation_laborer", "Take Every Shift", "Career", "Keep the body in the work until coin and exhaustion become the same thing.", { trait = "PHY_STR", axis = "PER_LOY", difficulty = 56 }, {
        success = { narrative = "You grind out a steadier year than most.", effects = { resources = { grain = 2, gold = 1 }, wealth = 1, shadow = { health = -2, craft = 3, standing = 1, stress = 2 }, trait = { MEN_WIL = 1 }, chronicle = "The protagonist worked every shift that could be survived and ended the year tired, fed, and still standing." } },
        failure = { narrative = "The work keeps you alive and strips something from you anyway.", effects = { wealth = -1, shadow = { health = -5, stress = 5 }, chronicle = "A year of labor took its payment directly from the body." } },
    })
end

local function household_action(setup)
    local household = setup and setup.household or "fractured"
    if household == "devout" then
        return base_action("household_devout", "Keep the House Rite", "Household", "Spend the year obeying the house's devotions closely enough to avoid becoming its scandal.", { trait = "CRE_RIT", axis = "PER_LOY", difficulty = 55 }, {
            success = { narrative = "The house remains stern, but it names you reliable.", effects = { shadow = { standing = 2, stress = 1, bonds = 2 }, morality = { delta = 1 }, chronicle = "The house rite held through the year, and the protagonist was judged steady enough to remain inside it." } },
            failure = { narrative = "The house remembers every failure more clearly than any kindness.", effects = { shadow = { stress = 4, bonds = -2, notoriety = 1 }, chronicle = "A year of devotions ended with more scrutiny than peace." } },
        })
    elseif household == "debtor" then
        return base_action("household_debtor", "Keep the House Credible", "Household", "Spend the year helping the house look solvent, respectable, and worth sparing.", { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 56 }, {
            success = { narrative = "The house holds together another year on borrowed appearances.", effects = { wealth = 1, shadow = { stress = 1, standing = 2, bonds = 1 }, chronicle = "The protagonist spent the year preserving a household whose solvency was part arithmetic and part theater." } },
            failure = { narrative = "The house survives, but everyone inside it becomes easier to own.", effects = { wealth = -2, shadow = { stress = 5, bonds = -1, standing = -1 }, chronicle = "Another year was fed into the debtor house, and the house remained hungry." } },
        })
    elseif household == "martial" then
        return base_action("household_martial", "Endure the House Discipline", "Household", "Submit to drills, tests, and corrections until obedience becomes useful or corrosive.", { trait = "MEN_WIL", axis = "PER_BLD", difficulty = 57 }, {
            success = { narrative = "The discipline leaves marks, but also competence.", effects = { shadow = { craft = 2, standing = 2, stress = 2 }, trait = { PHY_STR = 1 }, chronicle = "The martial house hardened the protagonist another year and called it instruction." } },
            failure = { narrative = "The discipline teaches pain better than skill.", effects = { shadow = { health = -2, stress = 5, bonds = -1 }, body = { wounds = { { id = "discipline_bruising", label = "Discipline Bruising", severity = 6 } } }, chronicle = "The house mistook endurance for learning and did not entirely care about the difference." } },
        })
    elseif household == "scholarly" then
        return base_action("household_scholarly", "Study Under Cold Eyes", "Household", "Spend the year under correction, memory work, and the strain of being watched for excellence.", { trait = "MEN_INT", axis = "PER_OBS", difficulty = 56 }, {
            success = { narrative = "The lessons cut deep enough to stay useful.", effects = { resources = { lore = 1 }, shadow = { craft = 4, stress = 1 }, trait = { MEN_INT = 1 }, chronicle = "The scholarly house fed the protagonist another year of difficult instruction and got results worth bragging about." } },
            failure = { narrative = "The lessons remain, but affection does not accompany them.", effects = { shadow = { craft = 1, stress = 4, bonds = -1 }, chronicle = "Another year of study produced sharpened memory and no corresponding mercy." } },
        })
    elseif household == "wandering" then
        return base_action("household_wandering", "Keep the Household Moving", "Household", "Spend the year helping the house remain one move ahead of hunger, weather, or notice.", { trait = "PHY_VIT", axis = "PER_ADA", difficulty = 55 }, {
            success = { narrative = "The house survives another year by never quite settling long enough to fail.", effects = { shadow = { health = 1, stress = 2, bonds = 1 }, chronicle = "The wandering house kept moving and took the protagonist with it, which counted as victory by local standards." } },
            failure = { narrative = "Movement keeps becoming the problem it was meant to solve.", effects = { shadow = { health = -2, stress = 5, standing = -1 }, chronicle = "The wandering house crossed another year without finding anything willing to become home." } },
        })
    end

    return base_action("household_fractured", "Keep the House from Splitting Wide", "Household", "Spend the year mediating quarrels, choosing silences, and learning which truth would ruin dinner.", { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 57 }, {
        success = { narrative = "The house does not become healthy, only temporarily governable.", effects = { shadow = { bonds = 3, stress = 2 }, chronicle = "The protagonist spent the year holding a fractured house together with timing, omissions, and luck." } },
        failure = { narrative = "The house teaches you rupture faster than loyalty.", effects = { shadow = { bonds = -3, stress = 5, notoriety = 1 }, chronicle = "Another year in the fractured house made silence more strategic and love more conditional." } },
    })
end

local function faith_action(setup)
    local faith = setup and setup.faith or "skeptic"
    if faith == "state" then
        return base_action("faith_state", "Serve the Public Creed", "Faith", "Spend the year aligning the self with sanctioned ritual and its rewards.", { trait = "CRE_RIT", axis = "PER_LOY", difficulty = 55 }, {
            success = { narrative = "The sanctioned words open a few doors and close a few questions.", effects = { shadow = { standing = 3, bonds = 1 }, resources = { gold = 1 }, chronicle = "The protagonist spent the year close to the state creed and was rewarded in the ordinary, compromising ways." } },
            failure = { narrative = "You remain visible to the creed without becoming protected by it.", effects = { shadow = { stress = 3, notoriety = 1 }, chronicle = "The public creed accepted performance and withheld shelter." } },
        })
    elseif faith == "old" then
        return base_action("faith_old", "Keep the Old Rites Alive", "Faith", "Give the year to inherited taboo, hidden ceremony, and useful fear.", { trait = "CRE_RIT", axis = "PER_OBS", difficulty = 56 }, {
            success = { narrative = "The old rites answer, though never in plain language.", effects = { resources = { lore = 1 }, shadow = { bonds = 1, stress = 1, craft = 2 }, chronicle = "The old rites survived another year in the protagonist's care and took some payment in private." } },
            failure = { narrative = "The rite remains, but confidence in it thins under pressure.", effects = { shadow = { stress = 4, bonds = -1 }, chronicle = "The old rite was kept in form and doubted in substance." } },
        })
    elseif faith == "cult" then
        return base_action("faith_cult", "Descend Further into the Cellar Creed", "Faith", "Spend the year serving a private devotion that prefers secrecy to innocence.", { trait = "SOC_NEG", axis = "PER_OBS", difficulty = 58 }, {
            success = { narrative = "The hidden circle tightens around you and begins to pay in influence.", effects = { resources = { lore = 2 }, shadow = { standing = 2, notoriety = 3, bonds = 2 }, chronicle = "The protagonist moved deeper into the hidden creed and found it generous only where it wanted ownership." } },
            failure = { narrative = "The creed consumes the year without clarifying who serves whom.", effects = { shadow = { stress = 5, notoriety = 3, bonds = -1 }, chronicle = "The cellar creed deepened through the year and left the protagonist less explainable in daylight." } },
        })
    elseif faith == "ancestor" then
        return base_action("faith_ancestor", "Keep the Dead Near but Quiet", "Faith", "Spend the year feeding remembrance without letting it take command of the living room.", { trait = "CRE_NAR", axis = "PER_LOY", difficulty = 55 }, {
            success = { narrative = "The dead remain close enough to guide without fully ruling.", effects = { resources = { lore = 1 }, shadow = { bonds = 2, stress = -1 }, chronicle = "The protagonist spent the year making room for the dead without fully yielding the house to them." } },
            failure = { narrative = "The dead begin speaking too loudly for comfort.", effects = { shadow = { stress = 4, bonds = -1 }, body = { compulsions = { { id = "ancestor_fixation", label = "Ancestor Fixation", severity = 6 } } }, chronicle = "Remembrance deepened through the year until it resembled occupation." } },
        })
    end

    return base_action("faith_skeptic", "Live Without the Script", "Faith", "Spend the year leaning on doubt instead of inherited certainty.", { trait = "MEN_INT", axis = "PER_CUR", difficulty = 55 }, {
        success = { narrative = "Doubt protects you from some humiliations and creates others.", effects = { shadow = { craft = 2, standing = 1, stress = -1 }, chronicle = "The protagonist trusted doubt for another year and found it a thinner but more honest blanket than creed." } },
        failure = { narrative = "Without a script, every demand feels newly invented and equally exhausting.", effects = { shadow = { stress = 4, bonds = -1 }, chronicle = "Another year without creed yielded freedom in theory and fatigue in practice." } },
    })
end

local function youth_action(setup)
    local calling = setup and setup.occupation or "laborer"
    if calling == "scribe" then
        return base_action("youth_scribe", "Steal Hours from the Lamp", "Youth", "Spend the year chasing literacy, pattern, and private mastery before anyone decides it is useful.", { trait = "MEN_INT", axis = "PER_CUR", difficulty = 54 }, {
            success = { narrative = "The mind gets there before permission does.", effects = { resources = { lore = 1 }, shadow = { craft = 3, stress = 1 }, trait = { MEN_INT = 1 }, chronicle = "The protagonist spent the year stealing knowledge hours and making them count." } },
            failure = { narrative = "The effort remains real even where the gain does not.", effects = { shadow = { stress = 3, craft = 1 }, chronicle = "The year produced hunger for learning more reliably than learning itself." } },
        })
    elseif calling == "soldier" then
        return base_action("youth_soldier", "Test the Body Early", "Youth", "Spend the year proving courage before the body has learned how long consequences last.", { trait = "PHY_STR", axis = "PER_BLD", difficulty = 55 }, {
            success = { narrative = "Bravery wins attention before wisdom has any equal say.", effects = { shadow = { standing = 2, notoriety = 2, stress = 2 }, trait = { PHY_STR = 1 }, chronicle = "The protagonist spent the year testing courage early and was rewarded mostly by being noticed." } },
            failure = { narrative = "The body learns consequence faster than glory.", effects = { shadow = { health = -2, stress = 4 }, body = { wounds = { { id = "training_injury", label = "Training Injury", severity = 7 } } }, chronicle = "An early attempt at valor educated the body more completely than the soul." } },
        })
    elseif calling == "courtier" then
        return base_action("youth_courtier", "Learn the Room Before It Learns You", "Youth", "Spend the year studying favor, tone, and the small humiliations that govern power.", { trait = "SOC_ELO", axis = "PER_OBS", difficulty = 55 }, {
            success = { narrative = "You leave the year more legible to the room and less innocent inside it.", effects = { shadow = { standing = 2, craft = 2, stress = 1 }, chronicle = "The protagonist spent the year learning the room's weather before trying to command it." } },
            failure = { narrative = "The room notices you first, which is often the worse order.", effects = { shadow = { stress = 4, notoriety = 2 }, chronicle = "The room taught the protagonist how visibility can feel like a debt." } },
        })
    elseif calling == "tinker" then
        return base_action("youth_tinker", "Take Things Apart that Matter", "Youth", "Spend the year following curiosity into hinges, springs, locks, and consequences.", { trait = "CRE_TIN", axis = "PER_CUR", difficulty = 54 }, {
            success = { narrative = "The hands learn enough to begin calling themselves useful.", effects = { resources = { steel = 1 }, shadow = { craft = 4, stress = 1 }, trait = { CRE_TIN = 1 }, chronicle = "The protagonist spent the year taking things apart and, unusually, putting enough of them back together." } },
            failure = { narrative = "Curiosity remains strong even where the result does not.", effects = { shadow = { stress = 3, craft = 1 }, body = { wounds = { { id = "tool_cut", label = "Tool Cut", severity = 5 } } }, chronicle = "A year of making taught breakage more reliably than mastery." } },
        })
    elseif calling == "performer" then
        return base_action("youth_performer", "Practice the First Mask", "Youth", "Spend the year learning how to hold a room before it decides what to do with you.", { trait = "CRE_NAR", axis = "PER_BLD", difficulty = 54 }, {
            success = { narrative = "Presence begins arriving before confidence catches up to it.", effects = { shadow = { bonds = 2, notoriety = 2, craft = 2 }, chronicle = "The protagonist spent the year building the first usable mask and discovering it fit a little too well." } },
            failure = { narrative = "The mask slips more often than the room forgives.", effects = { shadow = { stress = 3, bonds = -1 }, chronicle = "Performance remained a calling in theory and embarrassment in practice." } },
        })
    end

    return base_action("youth_laborer", "Learn to Make the Body Useful", "Youth", "Spend the year turning effort into stamina before the world starts charging full price for both.", { trait = "PHY_VIT", axis = "PER_LOY", difficulty = 53 }, {
        success = { narrative = "The year leaves the body tired but more trustworthy.", effects = { shadow = { health = 1, craft = 2, stress = 1 }, trait = { MEN_WIL = 1 }, chronicle = "The protagonist spent the year making the body useful and nearly managed to keep it their own." } },
        failure = { narrative = "Useful work and early exhaustion become difficult to distinguish.", effects = { shadow = { health = -2, stress = 3 }, chronicle = "The body learned utility faster than mercy." } },
    })
end

local function burden_action(setup)
    local burden = setup and setup.burden or "debt"
    if burden == "wanted" then
        return base_action("burden_wanted", "Stay Ahead of the Face", "Burden", "Keep moving, lie well, and make sure recognition dies before it reaches law.", { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 58 }, {
            success = { narrative = "You remain difficult to pin down.", effects = { shadow = { notoriety = -3, stress = 1, standing = 1 }, condition = { type = "exodus", intensity = 0.2, duration = 1 }, chronicle = "The protagonist survived another year by refusing to stay still long enough to become a certainty." } },
            failure = { narrative = "You stay free, but not quietly.", effects = { wealth = -2, shadow = { notoriety = 6, stress = 6, bonds = -2 }, condition = { type = "exodus", intensity = 0.35, duration = 1 }, chronicle = "Flight kept the protagonist alive and advertised them more than it should have." } },
        })
    elseif burden == "parent" then
        return base_action("burden_parent", "Keep the Room Alive", "Burden", "Spend the year balancing care, medicine, wages, and resentment.", { trait = "MEN_PAT", axis = "PER_LOY", difficulty = 55 }, {
            success = { narrative = "Duty holds, though nothing about it becomes lighter.", effects = { resources = { gold = -1 }, morality = { act = "sacrifice" }, shadow = { bonds = 5, stress = 3, standing = 1 }, body = { illnesses = { { id = "sleeplessness", label = "Sleeplessness", severity = 4 } }, ease_illness = 2 }, chronicle = "The protagonist spent another year keeping the sick room from winning outright." } },
            failure = { narrative = "The house remains intact by sacrificing everything around it.", effects = { resources = { gold = -2 }, wealth = -2, shadow = { bonds = 2, stress = 7, health = -2 }, body = { illnesses = { { id = "sleeplessness", label = "Sleeplessness", severity = 10 }, { id = "caregiver_fever", label = "Caregiver Fever", severity = 8 } } }, chronicle = "Care became the year's full occupation and still could not guarantee mercy." } },
        })
    elseif burden == "claim" then
        return base_action("burden_claim", "Press the Denied Claim", "Burden", "Use the year to gather witnesses, whispers, and leverage around what should have been yours.", { trait = "SOC_ELO", axis = "PER_PRI", difficulty = 59 }, {
            success = { narrative = "Your claim gains weight, even without justice.", effects = { shadow = { standing = 5, notoriety = 4, stress = 2 }, wealth = 1, chronicle = "The denied claim acquired more listeners this year and therefore more danger." } },
            failure = { narrative = "You become easier to mock than to reward.", effects = { shadow = { standing = -2, notoriety = 3, stress = 5 }, chronicle = "The claim remained alive, which is not the same as becoming plausible." } },
        })
    elseif burden == "oath" then
        return base_action("burden_oath", "Keep the Oath in Sight", "Burden", "Let the year be governed by an inherited promise you never fully chose.", { trait = "MEN_WIL", axis = "PER_LOY", difficulty = 57 }, {
            success = { narrative = "Keeping the oath costs freedom and purchases a harder kind of respect.", effects = { morality = { act = "honoring_oath" }, shadow = { bonds = 3, standing = 3, stress = 2 }, chronicle = "The oath was kept through another year, which made the protagonist narrower and easier to name." } },
            failure = { narrative = "The oath holds, but your life bends around it badly.", effects = { shadow = { standing = -1, stress = 6, bonds = 1 }, chronicle = "Another year disappeared into fidelity without elegance." } },
        })
    elseif burden == "scar" then
        return base_action("burden_scar", "Negotiate with the Body", "Burden", "Shape the year around pain before pain decides the shape for you.", { trait = "MEN_WIL", axis = "PER_ADA", difficulty = 55 }, {
            success = { narrative = "You keep the wound from ruling the whole year.", effects = { shadow = { health = 2, stress = -1 }, body = { ease_wounds = 8, preferred_wound = "old_scar" }, chronicle = "The old scar remained a tyrant with limited jurisdiction." } },
            failure = { narrative = "Pain keeps the calendar now.", effects = { shadow = { health = -4, stress = 4 }, body = { wounds = { { id = "old_scar", label = "Old Scar", severity = 8 } } }, chronicle = "The old wound collected another year of interest." } },
        })
    end

    return base_action("burden_debt", "Cut at the Debt", "Burden", "Spend the year bargaining, hiding coin, and trying not to be owned outright.", { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 56 }, {
        success = { narrative = "The debt shrinks enough to let you breathe.", effects = { resources = { gold = -1 }, wealth = 1, shadow = { stress = -3, standing = 1 }, chronicle = "The protagonist spent the year reducing a debt that had previously mistaken itself for destiny." } },
        failure = { narrative = "The debt remains better organized than you.", effects = { resources = { gold = -2 }, wealth = -2, shadow = { stress = 6, standing = -1 }, chronicle = "Another year was fed into the debt and failed to satisfy it." } },
    })
end

local function private_action(setup)
    local vice = setup and setup.vice or "none"
    if vice == "drink" then
        return base_action("private_drink", "Starve the Bottle", "Private", "Spend the year trying to keep appetite from writing the whole script.", { trait = "MEN_WIL", axis = "PER_VOL", difficulty = 57 }, {
            success = { narrative = "The year stays more yours than the bottle's.", effects = { morality = { delta = 1 }, shadow = { health = 3, stress = -2, craft = 1 }, body = { ease_compulsions = 12, preferred_compulsion = "drink_hunger" }, chronicle = "For one year, at least, the protagonist denied the bottle the final word." } },
            failure = { narrative = "The bottle loses some days and wins the year.", effects = { resources = { gold = -2 }, wealth = -2, shadow = { health = -4, stress = 5, notoriety = 2 }, body = { compulsions = { { id = "drink_hunger", label = "Bottle Hunger", severity = 12 } }, illnesses = { { id = "morning_sickness", label = "Morning Sickness", severity = 6 } } }, chronicle = "Another year was diluted and lost in the cup." } },
        })
    elseif vice == "gaming" then
        return base_action("private_gaming", "Stay Away from the Table", "Private", "Refuse the clean false clarity of chance for one whole year.", { trait = "MEN_PAT", axis = "PER_OBS", difficulty = 56 }, {
            success = { narrative = "Restraint leaves you poorer in thrill and richer everywhere else.", effects = { morality = { delta = 1 }, shadow = { stress = -1, craft = 1 }, wealth = 1, body = { ease_compulsions = 10, preferred_compulsion = "gaming_hunger" }, chronicle = "The protagonist denied the gaming table long enough to discover that dread and freedom can resemble one another." } },
            failure = { narrative = "You keep thinking about the turn that would have saved you.", effects = { resources = { gold = -2 }, wealth = -2, shadow = { stress = 4, notoriety = 2 }, body = { compulsions = { { id = "gaming_hunger", label = "Gaming Hunger", severity = 10 } } }, chronicle = "Refusing the table in public did not stop the year from being governed by it in private." } },
        })
    elseif vice == "obsession" then
        return base_action("private_obsession", "Feed the Obsession Carefully", "Private", "Give the dangerous thought a year without letting it eat the entire life.", { trait = "MEN_INT", axis = "PER_OBS", difficulty = 60 }, {
            success = { narrative = "The obsession produces something worth the damage.", effects = { resources = { lore = 3 }, shadow = { craft = 5, stress = 4, health = -1 }, body = { compulsions = { { id = "obsessive_fixation", label = "Obsessive Fixation", severity = 6 } }, illnesses = { { id = "sleeplessness", label = "Sleeplessness", severity = 4 } } }, trait = { MEN_INT = 1 }, chronicle = "The protagonist fed the obsession for a year and extracted from it one useful and expensive thing." } },
            failure = { narrative = "The obsession takes the year and leaves a polished nothing behind.", effects = { shadow = { stress = 7, health = -2, bonds = -1 }, body = { compulsions = { { id = "obsessive_fixation", label = "Obsessive Fixation", severity = 12 } }, illnesses = { { id = "sleeplessness", label = "Sleeplessness", severity = 8 } } }, chronicle = "The obsession consumed another year and left no witness willing to call the ashes progress." } },
        })
    elseif vice == "fervor" then
        return base_action("private_fervor", "Temper the Zeal", "Private", "Try to remain devout without becoming theatrical or monstrous.", { trait = "CRE_RIT", axis = "PER_ADA", difficulty = 56 }, {
            success = { narrative = "Conviction survives the year without becoming a weapon first.", effects = { morality = { delta = 1 }, shadow = { bonds = 2, stress = -1, notoriety = -1 }, body = { ease_compulsions = 8, preferred_compulsion = "ecstatic_fervor" }, chronicle = "The protagonist kept faith through the year without immediately turning it outward like a blade." } },
            failure = { narrative = "The year leaves you more certain and less easy to live beside.", effects = { shadow = { notoriety = 3, stress = 3, bonds = -1 }, body = { compulsions = { { id = "ecstatic_fervor", label = "Ecstatic Fervor", severity = 8 } } }, chronicle = "Zeal deepened through the year and took conversation down with it." } },
        })
    end

    return base_action("private_study", "Train the Self", "Private", "Give the year to discipline instead of appetite.", { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 54 }, {
        success = { narrative = "A quieter year hardens into a useful habit.", effects = { shadow = { craft = 3, health = 1, stress = -2 }, body = { ease_compulsions = 4, ease_illness = 2 }, trait = { MEN_WIL = 1 }, chronicle = "The protagonist spent the year practicing restraint and found it could be learned like any other difficult trade." } },
        failure = { narrative = "The discipline never quite takes root.", effects = { shadow = { stress = 1 }, chronicle = "The year's attempted self-mastery mostly clarified how much mastering remained." } },
    })
end

local function body_action(game_state)
    local snapshot = ShadowBody.snapshot(game_state)
    local top_wound = snapshot.wounds[1]
    local top_illness = snapshot.illnesses[1]
    local top_compulsion = snapshot.compulsions[1]
    local wound_severity = top_wound and top_wound.severity or -1
    local illness_severity = top_illness and top_illness.severity or -1
    local compulsion_severity = top_compulsion and top_compulsion.severity or -1

    if top_illness and illness_severity >= wound_severity and illness_severity >= compulsion_severity then
        return base_action("body_illness", "Keep the Fever from Winning", "Body", "Give the year to treatment, sleep, and whatever humility sickness still permits.", { trait = "PHY_VIT", axis = "PER_ADA", difficulty = 56 }, {
            success = { narrative = "The illness loosens its grip enough to let the rest of life back in.", effects = { shadow = { health = 3, stress = -2 }, body = { ease_illnesses = 12, preferred_illness = top_illness.id }, chronicle = "The protagonist spent the year bargaining with sickness and, this once, was not overcharged." } },
            failure = { narrative = "The bed keeps more of the year than you meant to surrender.", effects = { wealth = -1, shadow = { health = -2, stress = 3, standing = -1 }, body = { illnesses = { { id = top_illness.id, label = top_illness.label, severity = 8 } } }, chronicle = "The illness accepted treatment as a suggestion and kept collecting the year." } },
        })
    elseif top_wound and wound_severity >= compulsion_severity then
        return base_action("body_wound", "Protect the Injured Body", "Body", "Bind the damage, work more carefully, and accept limits before they become permanent.", { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 55 }, {
            success = { narrative = "The body remains compromised, but not surrendered.", effects = { shadow = { health = 2, stress = -1, craft = 1 }, body = { ease_wounds = 12, preferred_wound = top_wound.id }, chronicle = "The protagonist spent the year treating pain as a schedule instead of a prophecy." } },
            failure = { narrative = "The wound settles deeper into the life instead of leaving it.", effects = { wealth = -1, shadow = { health = -3, stress = 2, craft = -1 }, body = { wounds = { { id = top_wound.id, label = top_wound.label, severity = 8 } } }, chronicle = "The injured body accepted another year and kept the damage as earnest money." } },
        })
    elseif top_compulsion then
        return base_action("body_compulsion", "Deny the Ruling Hunger", "Body", "Treat appetite like an occupying force instead of a private preference.", { trait = "MEN_WIL", axis = "PER_ADA", difficulty = 58 }, {
            success = { narrative = "The craving does not disappear, but it ceases to command the room.", effects = { shadow = { stress = -2, bonds = 1, standing = 1 }, body = { ease_compulsions = 12, preferred_compulsion = top_compulsion.id }, chronicle = "The protagonist spent the year refusing the reigning appetite and discovered refusal can be a craft." } },
            failure = { narrative = "The hunger becomes more articulate under pressure, not less.", effects = { wealth = -1, shadow = { stress = 4, bonds = -1, notoriety = 1 }, body = { compulsions = { { id = top_compulsion.id, label = top_compulsion.label, severity = 10 } } }, chronicle = "The appetite resisted discipline and finished the year speaking more fluently than before." } },
        })
    end

    return nil
end

local function claim_action(game_state)
    local claim = ShadowClaim.snapshot(game_state)
    if not claim then
        return nil
    end
    return base_action(
        "claim_reclaim",
        "Work the Broken Claim",
        "Birthright",
        "Spend the year gathering proof, allies, and dangerous attention around " .. claim.house_name .. ".",
        { trait = "MEN_PAT", axis = "PER_PRI", difficulty = 58 },
        {
            success = {
                narrative = "The buried branch stops feeling like a story told to children and starts feeling like a case others must answer.",
                effects = {
                    resources = { lore = 2, gold = 1 },
                    shadow = { standing = 3, stress = 2, notoriety = 2 },
                    claim = { legitimacy = 8, proof = 10, exposure = 6, ambition = 4, path = "reclamation" },
                    chronicle = "The protagonist spent a year making the denied branch legible in ledgers, witnesses, and rumor.",
                },
            },
            failure = {
                narrative = "You stir the ash but raise more notice than proof.",
                effects = {
                    shadow = { stress = 4, notoriety = 3 },
                    claim = { exposure = 8, grievance = 4, usurper_risk = 4, path = "reclamation" },
                    chronicle = "The old claim was spoken aloud often enough to wake enemies and not often enough to produce a right.",
                },
            },
        }
    )
end

local function possession_action(game_state)
    local possessions = ShadowPossessions.snapshot(game_state)
    local state = ShadowYear.snapshot(game_state)
    if not possessions or not state then
        return nil
    end

    if possessions.place_count == 0 then
        return base_action("possession_place", "Put Your Name on a Door", "Possessions", "Spend the year securing a room, stall, or lease that answers to your hand instead of someone else's whim.", { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 55 }, {
            success = {
                narrative = "The year ends with a real threshold under your control.",
                effects = {
                    wealth = -1,
                    shadow = { stress = -2, standing = 2 },
                    possessions = { add = { { id = "leased_stall", label = "Leased Stall", kind = "place", status = "Yours for Now", upkeep = 1, yield = 2, weight = "claimed", stain = 0 } } },
                    chronicle = "The protagonist spent the year buying enough stability to call one threshold their own.",
                },
            },
            failure = {
                narrative = "You pay for almost-security and receive the usual fraction of it.",
                effects = {
                    wealth = -2,
                    shadow = { stress = 2 },
                    chronicle = "The year's housing bargain proved cheaper than ownership and more expensive than it looked.",
                },
            },
        })
    elseif possessions.item_count <= 1 then
        return base_action("possession_item", "Buy the Proper Implements", "Possessions", "Turn coin into tools, clothes, seals, and other things that make the world take you more seriously.", { trait = "MEN_PAT", axis = "PER_CUR", difficulty = 54 }, {
            success = {
                narrative = "The right object changes what work will open to you.",
                effects = {
                    wealth = -1,
                    shadow = { craft = 2, standing = 1 },
                    possessions = { add = { { id = "house_seal", label = "House Seal Ring", kind = "item", status = "Convincing", upkeep = 0, yield = 2, weight = "precise", stain = 0 } } },
                    chronicle = "The protagonist bought tools and signs that made the next door open more like it was expected to.",
                },
            },
            failure = {
                narrative = "The purchase improves the costume more than the life.",
                effects = {
                    wealth = -2,
                    shadow = { stress = 1 },
                    chronicle = "The year's acquisition proved more decorative than transformative.",
                },
            },
        })
    elseif possessions.people_count == 0 and state.standing >= 46 and (game_state.wealth and (game_state.wealth.value or 0) >= 40) then
        return base_action("possession_indenture", "Bind a Desperate Hand", "Possessions", "Turn another person's hunger into your convenience by taking an indentured servant into the house. It will steady the work and stain the life.", { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 59 }, {
            success = {
                narrative = "The house runs smoother, and the record darkens to match.",
                effects = {
                    wealth = 1,
                    morality = { act = "exploitation" },
                    shadow = { standing = 2, stress = -1, bonds = -1, notoriety = 1 },
                    possessions = { add = { { id = "indentured_hand", label = "Indentured Hand", kind = "person", status = "Bound", upkeep = 1, yield = 3, weight = "human", stain = 3, note = "A life folded under your roof for debt." } } },
                    chronicle = "The protagonist took a desperate hand into indenture and called the arrangement necessity until the word curdled.",
                },
            },
            failure = {
                narrative = "The arrangement sours before it fully takes hold.",
                effects = {
                    morality = { act = "exploitation" },
                    shadow = { stress = 3, notoriety = 3, bonds = -2 },
                    chronicle = "The attempted indenture produced resentment faster than obedience and rumor faster than profit.",
                },
            },
        })
    end

    return base_action("possession_govern", "Govern What Is Yours", "Possessions", "Spend the year maintaining tools, rooms, papers, and obligations so ownership remains more than a rumor.", { trait = "MEN_PAT", axis = "PER_LOY", difficulty = 55 }, {
        success = {
            narrative = "What you own begins yielding shape instead of merely cost.",
            effects = {
                wealth = 1,
                shadow = { stress = -1, standing = 1 },
                possessions = { adjust = { { id = possessions.entries[1] and possessions.entries[1].id or "", status = "Kept in Order", yield = 1 } } },
                chronicle = "The protagonist spent the year keeping possession from decaying into embarrassment.",
            },
        },
        failure = {
            narrative = "Ownership behaves like another appetite with its own calendar.",
            effects = {
                wealth = -1,
                shadow = { stress = 2 },
                chronicle = "What was owned this year proved eager to own time in return.",
            },
        },
    })
end

function ShadowYear.generate_actions(world, game_state)
    local setup = setup_of(game_state)
    if not setup then
        return {}
    end
    ShadowYear.ensure_state(game_state)
    ShadowCareer.ensure_state(game_state)
    ShadowBonds.ensure_state(game_state)
    local actions = {
        youth_action(setup),
        household_action(setup),
        occupation_action(setup),
        faith_action(setup),
        burden_action(setup),
        private_action(setup),
    }
    local claim = claim_action(game_state)
    if claim then
        actions[#actions + 1] = claim
    end
    local possessions = possession_action(game_state)
    if possessions then
        actions[#actions + 1] = possessions
    end
    for _, relationship in ipairs(ShadowBonds.generate_actions(game_state) or {}) do
        if relationship then
            actions[#actions + 1] = relationship
        end
    end
    local body = body_action(game_state)
    if body then
        actions[#actions + 1] = body
    end
    -- Convalescence gating: when wound+scar+illness load is severe,
    -- occupation and body actions become harder, and a rest action appears.
    local body_snap = ShadowBody.snapshot(game_state)
    if body_snap and body_snap.convalescing then
        for _, action in ipairs(actions) do
            if action.check then
                local aid = action.id or ""
                if aid:find("^occupation_") then
                    action.check.difficulty = (action.check.difficulty or 50) + 12
                elseif aid:find("^body_") then
                    action.check.difficulty = (action.check.difficulty or 50) + 8
                end
            end
        end
        actions[#actions + 1] = {
            id = "convalescence_rest",
            title = "Rest and Convalesce",
            subtitle = "Body",
            description = "The body demands a year of stillness. Healing is slow, but not resting is slower.",
            check = { trait = "MEN_WIL", axis = "PER_ADA", difficulty = 42 },
            success = {
                narrative = "The year passed in stillness. The body remembered something older than ambition.",
                effects = {
                    shadow = { health = 8, stress = -6 },
                    body = { ease_wounds = 12, ease_illnesses = 10 },
                    chronicle = "The protagonist chose stillness when the body demanded it.",
                },
            },
            failure = {
                narrative = "Rest did not come easily. The mind fought the body's need and both lost ground.",
                effects = {
                    shadow = { health = 3, stress = 4 },
                    body = { ease_wounds = 4, ease_illnesses = 4 },
                    chronicle = "An attempt at rest proved that patience was another thing the years had worn thin.",
                },
            },
        }
    end
    return actions
end

local function apply_shadow_changes(game_state, payload)
    if not payload then
        return
    end
    local state = ShadowYear.ensure_state(game_state)
    for key, value in pairs(payload or {}) do
        if value ~= 0 and state[key] ~= nil then
            state[key] = Math.clamp((state[key] or 0) + value, 0, 100)
        end
    end
end

local function apply_effects(world, game_state, effects)
    if not effects then
        return
    end
    add_resource_changes(world, effects.resources, game_state.heir_name, game_state.generation)
    if effects.wealth and effects.wealth ~= 0 and game_state.wealth then
        Wealth.change(game_state.wealth, effects.wealth, effects.wealth >= 0 and "trade" or "loss", game_state.generation or 1, "shadow_year")
    end
    if effects.morality and game_state.morality then
        if effects.morality.act then
            Morality.record_act(game_state.morality, effects.morality.act, game_state.generation or 1, "shadow_year")
        elseif effects.morality.delta then
            game_state.morality.score = Math.clamp((game_state.morality.score or 0) + effects.morality.delta, -100, 100)
        end
    end
    if effects.power and game_state.lineage_power then
        game_state.lineage_power.value = Math.clamp((game_state.lineage_power.value or 45) + effects.power, 0, 100)
    end
    if effects.possessions then
        ShadowPossessions.apply(game_state, effects.possessions)
    end
    apply_shadow_changes(game_state, effects.shadow)
    ShadowClaim.apply(game_state, effects.claim)
    ShadowBody.apply(game_state, effects.body)
    add_condition(world, effects.condition)
    if effects.trait then
        for id, delta in pairs(effects.trait) do
            shift_trait(game_state, id, delta)
        end
    end
    if effects.personality then
        for id, delta in pairs(effects.personality) do
            shift_axis(game_state, id, delta)
        end
    end
    add_chronicle(world, effects.chronicle)
end

local function has_possession(snapshot, id)
    for _, entry in ipairs(snapshot and snapshot.entries or {}) do
        if entry.id == id then
            return entry
        end
    end
    return nil
end

local function first_entry(entries)
    return entries and entries[1] or nil
end

local function apply_relationship_interlocks(game_state)
    local lines = {}
    local detail = ShadowBonds.detail_snapshot(game_state)
    local body = ShadowBody.snapshot(game_state)
    local claim = ShadowClaim.snapshot(game_state)
    local possessions = ShadowPossessions.snapshot(game_state)
    local urgent = detail and detail.most_urgent or nil
    local strongest = detail and detail.strongest or nil

    if urgent and (urgent.thread_kind == "legacy" or urgent.category == "kin") then
        if urgent.status == "Trusted" or urgent.status == "Close" then
            local proof_push = has_possession(possessions, "branch_token") and 3 or 2
            ShadowClaim.apply(game_state, { legitimacy = 2, proof = proof_push, exposure = 1 })
            lines[#lines + 1] = urgent.name .. " kept the denied branch speakable this year."
        else
            ShadowClaim.apply(game_state, { grievance = 2, exposure = 2, usurper_risk = 2 })
            ShadowBonds.apply_event(game_state, {
                id = urgent.id,
                leverage = 2,
                visibility = 2,
                history = "Claim-talk taught the tie a new appetite for pressure.",
            })
            lines[#lines + 1] = urgent.name .. " turned branch-memory into a fresh pressure."
        end
    elseif claim and (claim.exposure or 0) >= 56 and detail and detail.rival then
        ShadowBonds.apply_event(game_state, {
            id = detail.rival.id,
            leverage = 2,
            strain = 1,
            visibility = 2,
            history = "Claim-rumor gave the feud a wider audience.",
        })
        lines[#lines + 1] = detail.rival.name .. " found new leverage in the claim-rumor."
    end

    if body and (body.compulsion_load or 0) >= 18 then
        local target = (detail and detail.intimate) or strongest
        if target then
            ShadowBonds.apply_event(game_state, {
                id = target.id,
                closeness = -1,
                strain = 2,
                heat_delta = 2,
                history = "Your habit taught the tie its price again.",
            })
            lines[#lines + 1] = "Habit taxed the bond with " .. target.name .. "."
        end
    end

    if body and (((body.wound_load or 0) + (body.illness_load or 0)) >= 34) then
        local target = (detail and detail.dependent) or strongest
        if target then
            ShadowBonds.apply_event(game_state, {
                id = target.id,
                dependency = 2,
                obligation = 1,
                strain = 1,
                history = "The body's weakness made the tie more costly to carry.",
            })
            lines[#lines + 1] = target.name .. " had to answer the body's failing weight."
        end
    end

    local held_person = first_entry(possessions and possessions.people)
    if held_person and (detail and (detail.dependent or urgent)) then
        local handler = detail.dependent or urgent
        ShadowPossessions.apply(game_state, {
            adjust = {
                {
                    id = held_person.id,
                    upkeep = 1,
                    stain = 1,
                    note = "The social web tightened around this held life.",
                },
            },
        })
        ShadowBonds.apply_event(game_state, {
            id = handler.id,
            obligation = 2,
            dependency = 1,
            history = held_person.label .. " became another argument inside the tie.",
        })
        lines[#lines + 1] = held_person.label .. " became part of the year's relationship pressure."
    end

    local watched_place = first_entry(possessions and possessions.places)
    if watched_place and claim and (claim.exposure or 0) >= 56 and detail and detail.rival then
        ShadowPossessions.apply(game_state, {
            adjust = {
                {
                    id = watched_place.id,
                    status = "Watched",
                    stain = 1,
                    note = "Claim-rumor drew witnesses to the threshold.",
                },
            },
        })
        lines[#lines + 1] = watched_place.label .. " drew eyes once the claim grew louder."
    end

    return lines
end

function ShadowYear.resolve(action, world, game_state)
    if not action then
        return { narrative = "", consequence_lines = {} }
    end

    local before_shadow = ShadowYear.snapshot(game_state)
    local before_body = ShadowBody.snapshot(game_state)
    local before_career = ShadowCareer.snapshot(game_state)
    local before_claim = ShadowClaim.snapshot(game_state)
    local before_possessions = ShadowPossessions.snapshot(game_state)
    local before_relationship_detail = ShadowBonds.detail_snapshot(game_state)
    local _, check_quality = combine_score(game_state, action.check)
    local branch = (check_quality == "triumph" or check_quality == "success") and action.success or action.failure
    apply_effects(world, game_state, branch and branch.effects)
    local career_lines = ShadowCareer.apply_focus(game_state, action.id, check_quality)
    local bond_lines = ShadowBonds.apply_focus(game_state, action.id, check_quality)
    local bond_drift_lines = ShadowBonds.tick_year(game_state, action.id, check_quality)
    local bond_autonomy_lines = ShadowBonds.resolve_autonomy(game_state, check_quality)
    local interlock_lines = apply_relationship_interlocks(game_state)

    -- Expectations: check violations and apply grievance pressure
    local expectation_lines = ShadowExpectations.check_violations(game_state, { focus = action.id, quality = check_quality })
    ShadowExpectations.apply(game_state)

    -- Witnesses: record this year's action as a witnessed act
    local witness_tone = (check_quality == "triumph" or check_quality == "success") and "approving" or "condemning"
    ShadowWitnesses.record(game_state, action.title or action.id or "unknown", witness_tone, game_state.generation or 1)

    -- Secrets: generate mid-year interruption if a bond acts in the dark
    local secret_event = ShadowSecrets.generate(game_state, action.id)

    -- Collusion: check for bond-pair tension events
    local collusion_events = ShadowCollusion.generate(game_state, game_state.generation or 1)

    local shadow = ShadowYear.snapshot(game_state)
    local body = ShadowBody.snapshot(game_state)
    local career = ShadowCareer.snapshot(game_state)
    local claim = ShadowClaim.tick_year(game_state)
    local possessions = ShadowPossessions.tick_year(game_state)
    local relationship_detail = ShadowBonds.detail_snapshot(game_state)
    local relationship_spotlights = ShadowBonds.spotlights(game_state, 3)
    local next_loop = build_loop_preview(game_state)
    local progress_rows = build_progress_rows({
        shadow = before_shadow,
        body = before_body,
        career = before_career,
        claim = before_claim,
        possessions = before_possessions,
        relationship_detail = before_relationship_detail,
    }, {
        shadow = shadow,
        body = body,
        career = career,
        claim = claim,
        possessions = possessions,
        relationship_detail = relationship_detail,
    })
    game_state.shadow_state.last_focus = action.title or action.id or "survive"
    local state_lines = {
        "Health " .. shadow.health_label .. " | Stress " .. shadow.stress_label .. " | Bonds " .. shadow.bonds_label .. ".",
        "Standing " .. shadow.standing_label .. " | Notoriety " .. shadow.notoriety_label .. " | Craft " .. shadow.craft_label .. ".",
        "Wounds " .. body.wound_label .. " | Illness " .. body.illness_label .. " | Habit " .. body.compulsion_label .. ".",
    }
    local lines = {}
    for _, line in ipairs(state_lines) do
        lines[#lines + 1] = line
    end
    if claim then
        lines[#lines + 1] = claim.reclaim_line .. "."
        lines[#lines + 1] = claim.danger_line .. "."
    end
    for _, line in ipairs(career_lines or {}) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(bond_lines or {}) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(bond_drift_lines or {}) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(bond_autonomy_lines or {}) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(interlock_lines or {}) do
        lines[#lines + 1] = line
    end
    for _, line in ipairs(expectation_lines or {}) do
        lines[#lines + 1] = line
    end

    local all_drift_lines = {}
    for _, line in ipairs(bond_drift_lines or {}) do
        all_drift_lines[#all_drift_lines + 1] = line
    end
    for _, line in ipairs(bond_autonomy_lines or {}) do
        all_drift_lines[#all_drift_lines + 1] = line
    end

    return {
        title = action.title,
        subtitle = action.subtitle,
        narrative = branch and branch.narrative or action.description or "",
        next_hook = build_next_hook(shadow, body, relationship_detail, claim),
        reward_line = (check_quality == "triumph" or check_quality == "success")
            and "The year gave something back."
            or "The year took more than it returned.",
        progress_rows = progress_rows,
        state_lines = state_lines,
        career_lines = career_lines or {},
        relationship_lines = bond_lines or {},
        drift_lines = all_drift_lines,
        autonomy_lines = bond_autonomy_lines or {},
        interlock_lines = interlock_lines or {},
        state_rows = {
            { label = "Health", value = shadow.health_label },
            { label = "Stress", value = shadow.stress_label },
            { label = "Standing", value = shadow.standing_label },
            { label = "Notoriety", value = shadow.notoriety_label },
            { label = "Bonds", value = shadow.bonds_label },
            { label = "Craft", value = shadow.craft_label },
        },
        body_rows = {
            { label = "Wounds", value = body.wound_label },
            { label = "Illness", value = body.illness_label },
            { label = "Habit", value = body.compulsion_label },
        },
        career_rows = {
            { label = "Career", value = career.title },
            { label = "Rank", value = tostring(career.rank) },
            { label = "Income", value = tostring(career.income) },
            { label = "Stability", value = tostring(career.stability) },
        },
        possession_rows = possessions and {
            { label = "Items", value = tostring(possessions.item_count) },
            { label = "Places", value = tostring(possessions.place_count) },
            { label = "Held People", value = tostring(possessions.people_count) },
            { label = "Top Holding", value = possessions.place_line ~= "None" and possessions.place_line or possessions.item_line },
        } or {},
        claim_rows = claim and {
            { label = "Claim", value = claim.status },
            { label = "Legitimacy", value = claim.legitimacy_label },
            { label = "Proof", value = claim.proof_label },
            { label = "Usurper Risk", value = claim.usurper_label },
        } or {},
        social_rows = {
            { label = "Closest tie", value = relationship_detail.strongest and (relationship_detail.strongest.name .. " | " .. relationship_detail.strongest.status) or "None" },
            { label = "Open fracture", value = relationship_detail.rival and (relationship_detail.rival.name .. " | " .. relationship_detail.rival.arc) or "None" },
            { label = "Tender tie", value = relationship_detail.intimate and (relationship_detail.intimate.name .. " | " .. relationship_detail.intimate.arc) or "None" },
            { label = "Autonomous thread", value = relationship_detail.most_urgent and (relationship_detail.most_urgent.name .. " | " .. (relationship_detail.most_urgent.thread_state or relationship_detail.most_urgent.arc)) or "None" },
        },
        expectation_lines = expectation_lines or {},
        witness_fragments = ShadowWitnesses.chronicle_fragments(game_state),
        body_whispers = ShadowBody.get_whispers(game_state),
        interruption_events = (function()
            local events = {}
            if secret_event then events[#events + 1] = secret_event end
            for _, e in ipairs(collusion_events or {}) do events[#events + 1] = e end
            return events
        end)(),
        spotlight_rows = relationship_spotlights,
        chase_rows = next_loop.chase_rows,
        urge_line = next_loop.urge_line,
        lines = lines,
        consequence_lines = (function()
            local out = {}
            for _, line in ipairs(lines) do
                out[#out + 1] = { text = line }
            end
            return out
        end)(),
        stat_check_quality = check_quality,
    }
end

function ShadowYear.apply_aging(game_state)
    local state = ShadowYear.ensure_state(game_state)
    local age = (setup_of(game_state) and setup_of(game_state).start_age or 20) + math.max(0, (game_state.generation or 1) - 1)
    local vitality_loss = age >= 45 and 2 or (age >= 34 and 1 or 0)
    local patience_gain = age >= 30 and 1 or 0
    local volatility_loss = age >= 28 and 1 or 0

    if vitality_loss > 0 then
        shift_trait(game_state, "PHY_VIT", -vitality_loss)
        state.health = Math.clamp(state.health - vitality_loss, 0, 100)
    end
    if patience_gain > 0 then
        shift_trait(game_state, "MEN_PAT", patience_gain)
    end
    if volatility_loss > 0 and game_state.heir_personality then
        shift_axis(game_state, "PER_VOL", -volatility_loss)
    end
    state.yearly_actions_taken = (state.yearly_actions_taken or 0) + 1
    return ShadowBody.tick_year(game_state)
end

return ShadowYear
