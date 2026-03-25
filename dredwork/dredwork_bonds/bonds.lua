local Math = require("dredwork_core.math")
local ShadowExpectations = require("dredwork_bonds.expectations")
local ShadowWitnesses = require("dredwork_bonds.witnesses")

local ShadowBonds = {}

local ROLE_SETS = {
    laborer = {
        { role = "SHIFTMATE", category = "work" },
        { role = "KIN", category = "kin" },
        { role = "FOREMAN", category = "power" },
        { role = "RIVAL HAND", category = "rival" },
        { role = "CHILDHOOD FRIEND", category = "intimate" },
        { role = "YOUNGER SIBLING", category = "dependent" },
    },
    scribe = {
        { role = "FELLOW CLERK", category = "work" },
        { role = "PATRON", category = "power" },
        { role = "RIVAL SCRIBE", category = "rival" },
        { role = "ARCHIVE KEEPER", category = "work" },
        { role = "CONFIDANT", category = "intimate" },
        { role = "INK RUNNER", category = "dependent" },
    },
    soldier = {
        { role = "COMRADE", category = "work" },
        { role = "CAPTAIN", category = "power" },
        { role = "PAYMASTER", category = "power" },
        { role = "OLD ENEMY", category = "rival" },
        { role = "CAMP LOVER", category = "intimate" },
        { role = "YOUNGER RECRUIT", category = "dependent" },
    },
    courtier = {
        { role = "PATRON", category = "power" },
        { role = "RIVAL COURTIER", category = "rival" },
        { role = "CONFIDANT", category = "intimate" },
        { role = "SERVANT-SPY", category = "work" },
        { role = "DISGRACED KIN", category = "kin" },
        { role = "PETITIONER", category = "dependent" },
    },
    tinker = {
        { role = "APPRENTICE", category = "dependent" },
        { role = "BUYER", category = "power" },
        { role = "RIVAL MAKER", category = "rival" },
        { role = "SCRAP RUNNER", category = "work" },
        { role = "BEDFELLOW", category = "intimate" },
        { role = "CREDITOR", category = "power" },
    },
    performer = {
        { role = "PATRON", category = "power" },
        { role = "COMPANION", category = "intimate" },
        { role = "RIVAL PLAYER", category = "rival" },
        { role = "DOORKEEPER", category = "work" },
        { role = "SIBLING", category = "kin" },
        { role = "DEVOTEE", category = "dependent" },
    },
}

local BASE_BOND_SEEDS = {
    { closeness = 58, strain = 16, obligation = 46, intimacy = 34, leverage = 18, dependency = 14, visibility = 36, volatility = 28 },
    { closeness = 46, strain = 24, obligation = 54, intimacy = 24, leverage = 42, dependency = 12, visibility = 48, volatility = 34 },
    { closeness = 30, strain = 40, obligation = 28, intimacy = 14, leverage = 50, dependency = 10, visibility = 54, volatility = 46 },
    { closeness = 22, strain = 52, obligation = 18, intimacy = 10, leverage = 44, dependency = 8, visibility = 38, volatility = 58 },
    { closeness = 52, strain = 18, obligation = 28, intimacy = 58, leverage = 18, dependency = 10, visibility = 26, volatility = 30 },
    { closeness = 40, strain = 26, obligation = 62, intimacy = 20, leverage = 20, dependency = 56, visibility = 22, volatility = 24 },
}


local function era_of(game_state)
    return game_state and game_state.start_era or "ancient"
end

local function occupation_of(game_state)
    return game_state and game_state.shadow_setup and game_state.shadow_setup.occupation or "laborer"
end

local function burden_of(game_state)
    return game_state and game_state.shadow_setup and game_state.shadow_setup.burden or ""
end

local function hash_text(seed, text)
    local hash = math.abs(seed or 1) % 2147483647
    local value = tostring(text or "")
    for index = 1, #value do
        hash = (hash * 1103515245 + value:byte(index) + 12345) % 2147483647
    end
    return hash
end

local NAME_PARTS = {
    ancient = {
        lead = { "Ash", "Uro", "Tha", "Gra", "Mor", "Nek", "Zan", "Kor" },
        tail = { "am", "eth", "or", "ael", "un", "ik", "esh", "ar" },
    },
    iron = {
        lead = { "Hal", "Bran", "Eld", "Tor", "Gund", "Rag", "Sven", "Orm" },
        tail = { "ric", "mar", "ulf", "en", "ard", "or", "ik", "a" },
    },
    dark = {
        lead = { "Sev", "Nyr", "Vel", "Myr", "Khi", "Cyr", "Sal", "Fen" },
        tail = { "ith", "ae", "en", "ra", "is", "or", "iel", "eth" },
    },
    arcane = {
        lead = { "Ael", "Quel", "Vael", "Ori", "Thae", "Ilu", "Ris", "Sae" },
        tail = { "ion", "iel", "ael", "or", "eth", "is", "as", "uin" },
    },
    gilded = {
        lead = { "Aur", "Luc", "Mar", "Ser", "Val", "Jul", "Leo", "Cla" },
        tail = { "ius", "ent", "or", "ia", "en", "iel", "a", "is" },
    },
    twilight = {
        lead = { "Ren", "El", "Mi", "Ca", "Ai", "Lo", "Si", "Ne" },
        tail = { "en", "a", "iel", "or", "e", "in", "ra", "el" },
    },
}

local function deterministic_name(game_state, seed_label)
    local era = era_of(game_state)
    local parts = NAME_PARTS[era] or NAME_PARTS.ancient
    local seed = hash_text((game_state and game_state.rng_seed or 1) + (game_state and game_state.generation or 1), seed_label)
    local lead = parts.lead[(seed % #parts.lead) + 1]
    local tail = parts.tail[((math.floor(seed / 17)) % #parts.tail) + 1]
    return lead .. tail
end

local function build_bond(game_state, seed_label, role_def, seed)
    local bond = {
        id = seed_label,
        name = deterministic_name(game_state, seed_label),
        role = role_def.role,
        category = role_def.category or "work",
        closeness = seed.closeness,
        strain = seed.strain,
        obligation = seed.obligation,
        intimacy = seed.intimacy,
        leverage = seed.leverage,
        dependency = seed.dependency,
        visibility = seed.visibility,
        volatility = seed.volatility,
        history = {},
    }
    bond.expectation = ShadowExpectations.generate(bond)
    return bond
end

local function build_setup_bond(spec, index)
    local seed = BASE_BOND_SEEDS[index] or BASE_BOND_SEEDS[1]
    local bond = {
        id = "core:" .. tostring(index),
        name = spec.name,
        role = spec.role,
        category = spec.category or "work",
        closeness = seed.closeness,
        strain = seed.strain,
        obligation = seed.obligation,
        intimacy = seed.intimacy,
        leverage = seed.leverage,
        dependency = seed.dependency,
        visibility = seed.visibility,
        volatility = seed.volatility,
        temperament = spec.temperament,
        history = {},
    }

    if spec.slot_id == "hearth" then
        bond.closeness = bond.closeness + 8
        bond.obligation = bond.obligation + 10
    elseif spec.slot_id == "friend" then
        bond.intimacy = bond.intimacy + 10
        bond.closeness = bond.closeness + 6
    elseif spec.slot_id == "rival" then
        bond.strain = bond.strain + 16
        bond.closeness = math.max(14, bond.closeness - 10)
        bond.leverage = bond.leverage + 6
    elseif spec.slot_id == "elder" then
        bond.obligation = bond.obligation + 10
        bond.leverage = bond.leverage + 8
        bond.visibility = bond.visibility + 10
    elseif spec.slot_id == "dependent" then
        bond.dependency = bond.dependency + 18
        bond.closeness = bond.closeness + 4
    end

    local temperament = tostring(spec.temperament_id or ""):lower()
    if temperament == "steadfast" then
        bond.closeness = bond.closeness + 8
        bond.obligation = bond.obligation + 8
        bond.volatility = math.max(0, bond.volatility - 10)
    elseif temperament == "hungry" then
        bond.leverage = bond.leverage + 10
        bond.visibility = bond.visibility + 8
        bond.strain = bond.strain + 4
    elseif temperament == "gentle" then
        bond.intimacy = bond.intimacy + 10
        bond.closeness = bond.closeness + 6
        bond.strain = math.max(0, bond.strain - 8)
    elseif temperament == "volatile" then
        bond.volatility = bond.volatility + 12
        bond.strain = bond.strain + 8
    elseif temperament == "devout" then
        bond.obligation = bond.obligation + 8
        bond.visibility = bond.visibility + 4
    elseif temperament == "calculating" then
        bond.leverage = bond.leverage + 12
        bond.strain = bond.strain + 4
    elseif temperament == "curious" then
        bond.intimacy = bond.intimacy + 4
        bond.visibility = bond.visibility + 6
        bond.volatility = bond.volatility + 6
    elseif temperament == "bitter" then
        bond.strain = bond.strain + 12
        bond.closeness = math.max(10, bond.closeness - 4)
    end

    bond.expectation = ShadowExpectations.generate(bond)
    return bond
end

local function status_for(bond)
    local pressure = (bond.closeness or 0) - (bond.strain or 0)
    if pressure >= 28 then
        return "Trusted"
    elseif pressure >= 12 then
        return "Close"
    elseif pressure >= -4 then
        return "Uneasy"
    elseif pressure >= -18 then
        return "Strained"
    end
    return "Hostile"
end

local function arc_for(bond)
    if (bond.dependency or 0) >= 58 then
        return "Dependent"
    elseif (bond.obligation or 0) >= 58 then
        return "Binding"
    elseif (bond.intimacy or 0) >= 58 and (bond.closeness or 0) >= (bond.strain or 0) then
        return "Intimate"
    elseif (bond.leverage or 0) >= 58 then
        return "Compromised"
    elseif (bond.strain or 0) >= 62 then
        return "Breaking"
    end
    return "Ordinary"
end

local function urgency_for(bond)
    return (bond.strain or 0) + math.floor((bond.obligation or 0) * 0.65) + math.floor((bond.dependency or 0) * 0.75)
        + math.floor((bond.leverage or 0) * 0.55) + math.floor((bond.visibility or 0) * 0.20)
        + math.floor((bond.volatility or 0) * 0.25) - math.floor((bond.closeness or 0) * 0.4)
end

local function sort_bonds(bonds)
    table.sort(bonds, function(a, b)
        local a_urgency = urgency_for(a)
        local b_urgency = urgency_for(b)
        if a_urgency == b_urgency then
            return a.name < b.name
        end
        return a_urgency > b_urgency
    end)
    return bonds
end

local function find_bond(state, id)
    for _, bond in ipairs(state.bonds or {}) do
        if bond.id == id then
            return bond
        end
    end
    return nil
end

local function push_history(bond, text)
    if not bond or not text or text == "" then
        return
    end
    bond.history = bond.history or {}
    bond.history[#bond.history + 1] = text
    while #bond.history > 4 do
        table.remove(bond.history, 1)
    end
end

local function recent_history_text(bond)
    local history = bond and bond.history or nil
    if not history or #history == 0 then
        return "No recent rupture or tenderness has yet been entered into the record."
    end
    return history[#history]
end

local function title_case_words(text)
    local lower = tostring(text or ""):lower()
    return (lower:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest
    end))
end

local function mode_label(mode)
    local labels = {
        depend = "Protect",
        repair = "Repair",
        reveal = "Confide",
        bargain = "Bargain",
        tend = "Tend",
    }
    return labels[mode] or title_case_words(mode)
end

local function thread_kind_for_bond(bond)
    local category = bond and bond.category or "work"
    if category == "kin" then
        return "legacy"
    elseif category == "intimate" then
        return "tenderness"
    elseif category == "rival" then
        return "feud"
    elseif category == "dependent" then
        return "need"
    elseif category == "power" then
        return "patronage"
    end
    return "entanglement"
end

local function ensure_threads(state)
    state.threads = state.threads or {}
    for _, bond in ipairs(state.bonds or {}) do
        local thread = state.threads[bond.id]
        if not thread then
            state.threads[bond.id] = {
                kind = thread_kind_for_bond(bond),
                stage = 1,
                heat = 42 + math.floor((bond.urgency or urgency_for(bond)) * 0.15),
                autonomy = 36 + math.floor((bond.volatility or 0) * 0.22),
                last_generation = 0,
            }
        else
            thread.kind = thread.kind or thread_kind_for_bond(bond)
        end
    end
    return state.threads
end

local function get_thread(state, bond)
    local threads = ensure_threads(state)
    return bond and threads[bond.id] or nil
end

local function thread_state_label(thread)
    local stage = thread and thread.stage or 1
    local heat = thread and thread.heat or 0
    if stage >= 4 and heat >= 70 then
        return "Crisis"
    elseif stage >= 3 and heat >= 56 then
        return "Escalating"
    elseif heat >= 52 then
        return "Smoldering"
    end
    return "Latent"
end

local function thread_pressure(thread, bond)
    return urgency_for(bond)
        + math.floor((thread and thread.heat or 0) * 1.10)
        + math.floor((thread and thread.autonomy or 0) * 0.75)
        + ((thread and thread.stage or 1) * 10)
end

local function nudge_thread(thread, bond, generation)
    if not thread or not bond then
        return nil
    end

    local pressure = urgency_for(bond)
    local target_heat = Math.clamp(26 + math.floor(pressure * 0.34), 12, 96)
    local target_autonomy = Math.clamp(24 + math.floor((bond.volatility or 0) * 0.55) + math.floor((bond.visibility or 0) * 0.25), 12, 96)

    if (thread.heat or 0) < target_heat then
        thread.heat = Math.clamp((thread.heat or 0) + math.max(1, math.floor((target_heat - (thread.heat or 0)) * 0.35)), 0, 100)
    else
        thread.heat = Math.clamp((thread.heat or 0) - 1, 0, 100)
    end

    if (thread.autonomy or 0) < target_autonomy then
        thread.autonomy = Math.clamp((thread.autonomy or 0) + math.max(1, math.floor((target_autonomy - (thread.autonomy or 0)) * 0.22)), 0, 100)
    elseif (thread.autonomy or 0) > target_autonomy + 6 then
        thread.autonomy = Math.clamp((thread.autonomy or 0) - 1, 0, 100)
    end

    local desired_stage = 1
    if pressure >= 108 or (thread.heat or 0) >= 82 then
        desired_stage = 4
    elseif pressure >= 90 or (thread.heat or 0) >= 68 then
        desired_stage = 3
    elseif pressure >= 72 or (thread.heat or 0) >= 54 then
        desired_stage = 2
    end

    thread.stage = Math.clamp(math.max(thread.stage or 1, desired_stage), 1, 4)
    if generation then
        thread.last_generation = thread.last_generation or 0
    end
    return thread
end

local function thread_summary(thread, bond)
    local state = thread_state_label(thread)
    local kind = title_case_words(thread and thread.kind or "entanglement")
    if not bond then
        return state .. " " .. kind .. "."
    end
    return state .. " " .. kind .. " around " .. bond.name .. "."
end

local function bond_agenda(bond, thread)
    local temperament = tostring(bond and bond.temperament or ""):lower()
    local category = bond and bond.category or "work"
    local kind = thread and thread.kind or thread_kind_for_bond(bond)

    local agenda = "Keep a usable place in the life."
    local fear = "Being discarded once they become inconvenient."
    local style = "They move quietly until the moment costs more than silence."

    if kind == "legacy" then
        agenda = "Make the denied branch impossible to forget."
        fear = "That the old grievance will die unheard and unproven."
        style = "They test memory, witnesses, and old blood with equal patience."
    elseif kind == "tenderness" then
        agenda = "Win a lasting place inside the private life."
        fear = "Remaining a secret long enough to become disposable."
        style = "They move by gesture, implication, and the audacity of staying near."
    elseif kind == "feud" then
        agenda = "Force the life to answer the injury between you."
        fear = "That you will outgrow the quarrel and leave them beneath it."
        style = "They use witnesses, timing, and resentment more than open force."
    elseif kind == "need" then
        agenda = "Survive by tying their need to your choices."
        fear = "Being told to drown alone once they become costly."
        style = "They make urgency real faster than comfort can keep up."
    elseif kind == "patronage" then
        agenda = "Keep the balance tilted where they can still call a price."
        fear = "Losing the upper hand and becoming merely another petitioner."
        style = "They prefer leverage, favor, and remembered debt to clean demands."
    elseif category == "work" then
        agenda = "Turn shared work into shared dependence."
        fear = "That usefulness will end before intimacy begins."
        style = "They arrive with opportunities that are never morally neutral."
    end

    if temperament == "steadfast" then
        style = "They move slowly, keep count, and do not forget promises once accepted."
    elseif temperament == "hungry" then
        agenda = agenda:gsub("%.$", "") .. " and come away higher than before."
        style = "They notice openings before other people notice the wall has shifted."
    elseif temperament == "gentle" then
        fear = "Hurting you badly enough that tenderness can no longer return."
        style = "They offer help first and let hurt arrive only after refusal."
    elseif temperament == "volatile" then
        style = "They move in surges, forcing the life to answer before it is ready."
    elseif temperament == "devout" then
        agenda = agenda:gsub("%.$", "") .. " without betraying the creed that gives them shape."
        style = "They test conscience and omen before they test affection."
    elseif temperament == "calculating" then
        fear = "Giving up leverage they cannot win back."
        style = "They arrive already having priced the outcome."
    elseif temperament == "curious" then
        style = "They follow hidden seams until secrecy itself becomes a pressure."
    elseif temperament == "bitter" then
        agenda = agenda:gsub("%.$", "") .. " and prove the old hurt was never imagined."
        style = "They carry grievance like a private scripture and quote from it often."
    end

    return {
        agenda = agenda,
        fear = fear,
        style = style,
        arc_title = title_case_words(kind),
    }
end

local function build_bond_reading(bond, thread)
    local autonomy = thread and thread.autonomy or 0
    local heat = thread and thread.heat or 0
    local temperament = tostring(bond and bond.temperament or ""):lower()
    local exp = bond and bond.expectation or nil
    local grievance = exp and exp.grievance or 0

    if autonomy >= 60 and heat >= 70 then
        return "Moving independently. No longer waiting for your lead."
    elseif autonomy >= 50 and grievance >= 40 then
        return "Carrying a grievance and beginning to act on it."
    elseif autonomy >= 44 then
        if temperament == "calculating" then
            return "Watching. Pricing outcomes before you've named them."
        elseif temperament == "volatile" then
            return "Restless. Looking for a reason to move."
        elseif temperament == "bitter" then
            return "Quiet, but the kind of quiet that remembers."
        elseif temperament == "hungry" then
            return "Positioning. Eyes on the next opening."
        elseif temperament == "gentle" then
            return "Present. Waiting to be needed."
        elseif temperament == "devout" then
            return "Measuring you against the creed."
        elseif temperament == "curious" then
            return "Watching the seams. Noticing what you hide."
        else
            return "Holding steady. Still deciding whether to trust the tie."
        end
    elseif heat >= 56 then
        return "The thread is heating. They are paying close attention."
    end
    return "Settled. No visible agenda beyond the ordinary."
end

local function build_bond_warning(bond, thread)
    local autonomy = thread and thread.autonomy or 0
    local heat = thread and thread.heat or 0
    local exp = bond and bond.expectation or nil
    local grievance = exp and exp.grievance or 0
    local stage = thread and thread.stage or 1

    if grievance >= 50 and autonomy >= 44 then
        return "A broken contract is close to becoming an action."
    elseif stage >= 4 and heat >= 70 then
        return "Crisis. This bond will force a reckoning soon."
    elseif grievance >= 25 and not (exp and exp.revealed) then
        return "Something unspoken is building between you."
    elseif autonomy >= 55 and heat >= 60 then
        return "Moving with unusual purpose."
    elseif bond and (bond.strain or 0) >= 60 and (bond.closeness or 0) <= 20 then
        return "The tie is close to breaking."
    end
    return nil
end

local function action_for_bond(bond)
    if not bond then
        return "tend"
    end
    if (bond.dependency or 0) >= 58 then
        return "depend"
    elseif (bond.strain or 0) >= 60 or status_for(bond) == "Hostile" then
        return "repair"
    elseif (bond.intimacy or 0) >= 56 and (bond.closeness or 0) >= 44 then
        return "reveal"
    elseif (bond.leverage or 0) >= 56 or (bond.obligation or 0) >= 58 then
        return "bargain"
    end
    return "tend"
end

function ShadowBonds.ensure_state(game_state)
    game_state.shadow_bonds = game_state.shadow_bonds or {}
    local state = game_state.shadow_bonds
    if state.initialized then
        return state
    end

    local occupation = occupation_of(game_state)
    state.bonds = {}
    local setup = game_state and game_state.shadow_setup or {}
    if setup.core_bonds and #setup.core_bonds > 0 then
        for index, spec in ipairs(setup.core_bonds) do
            state.bonds[#state.bonds + 1] = build_setup_bond(spec, index)
        end
    else
        local roles = ROLE_SETS[occupation] or ROLE_SETS.laborer
        for index, role_def in ipairs(roles) do
            state.bonds[#state.bonds + 1] = build_bond(game_state, occupation .. ":" .. (index - 1), role_def, BASE_BOND_SEEDS[index] or BASE_BOND_SEEDS[1])
        end
    end

    local burden = burden_of(game_state)
    if burden == "parent" then
        local bond = state.bonds[5] or state.bonds[2]
        if bond then
            bond.role = "CHILD"
            bond.category = "dependent"
            bond.closeness = 62
            bond.obligation = 72
            bond.dependency = 70
            bond.intimacy = 54
            push_history(bond, "Care entered the relationship before choice had a chance to.")
        end
    elseif burden == "wanted" then
        local bond = state.bonds[4]
        if bond then
            bond.role = "SAFEHOUSE KEEPER"
            bond.category = "power"
            bond.closeness = 32
            bond.obligation = 56
            bond.leverage = 58
            push_history(bond, "Shelter and blackmail entered the tie together.")
        end
    elseif burden == "claim" then
        local bond = state.bonds[1] or state.bonds[3]
        if bond then
            bond.role = "CLAIM KIN"
            bond.category = "kin"
            bond.obligation = 62
            bond.strain = 46
            push_history(bond, "Blood and grievance were braided before the game began.")
        end
    elseif burden == "debt" then
        local bond = state.bonds[4] or state.bonds[#state.bonds]
        if bond then
            bond.role = "CREDITOR'S GO-BETWEEN"
            bond.category = "power"
            bond.leverage = 62
            bond.visibility = 34
            push_history(bond, "They entered the life already counting what could be taken from it.")
        end
    elseif burden == "oath" then
        local bond = state.bonds[1] or state.bonds[2]
        if bond then
            bond.role = "WITNESS TO THE OATH"
            bond.category = "kin"
            bond.obligation = 66
            bond.intimacy = 46
            push_history(bond, "They remember what was promised even when you wish not to.")
        end
    end

    if setup.vice == "drink" and state.bonds[5] then
        state.bonds[5].strain = Math.clamp((state.bonds[5].strain or 0) + 8, 0, 100)
        push_history(state.bonds[5], "They have already watched appetite outlast explanation.")
    elseif setup.vice == "gaming" and state.bonds[2] then
        state.bonds[2].leverage = Math.clamp((state.bonds[2].leverage or 0) + 6, 0, 100)
        push_history(state.bonds[2], "They have lent help before and remember the exact sum.")
    elseif setup.vice == "obsession" and state.bonds[5] then
        state.bonds[5].intimacy = Math.clamp((state.bonds[5].intimacy or 0) + 8, 0, 100)
        state.bonds[5].strain = Math.clamp((state.bonds[5].strain or 0) + 4, 0, 100)
    end

    ensure_threads(state)
    state.recent_moves = state.recent_moves or {}
    state.initialized = true
    return state
end

function ShadowBonds.snapshot(game_state)
    local state = ShadowBonds.ensure_state(game_state)
    local bonds = {}
    for _, bond in ipairs(state.bonds or {}) do
        local thread = nudge_thread(get_thread(state, bond), bond, game_state and game_state.generation or 1)
        local agenda = bond_agenda(bond, thread)
        bonds[#bonds + 1] = {
            id = bond.id,
            name = bond.name,
            role = bond.role,
            category = bond.category,
            closeness = bond.closeness,
            strain = bond.strain,
            obligation = bond.obligation,
            intimacy = bond.intimacy,
            leverage = bond.leverage,
            dependency = bond.dependency,
            visibility = bond.visibility,
            volatility = bond.volatility,
            temperament = bond.temperament,
            expectation = ShadowExpectations.snapshot(bond),
            status = status_for(bond),
            arc = arc_for(bond),
            urgency = urgency_for(bond),
            thread_kind = thread and thread.kind or thread_kind_for_bond(bond),
            thread_stage = thread and thread.stage or 1,
            thread_heat = thread and thread.heat or 0,
            thread_autonomy = thread and thread.autonomy or 0,
            thread_state = thread_state_label(thread),
            thread_summary = thread_summary(thread, bond),
            agenda = agenda.agenda,
            fear = agenda.fear,
            style = agenda.style,
            arc_title = agenda.arc_title,
            summary = bond.name .. " remains " .. string.lower(status_for(bond)) .. ", with " .. arc_for(bond):lower() .. " pressure in the tie.",
            recent_history = recent_history_text(bond),
            witness_score = ShadowWitnesses.reputation_score(game_state, bond.id),
            reading = build_bond_reading(bond, thread),
            warning = build_bond_warning(bond, thread),
        }
    end
    return sort_bonds(bonds)
end

function ShadowBonds.detail_snapshot(game_state)
    local state = ShadowBonds.ensure_state(game_state)
    local bonds = ShadowBonds.snapshot(game_state)
    local strongest = nil
    local strongest_score = -math.huge
    local intimate = nil
    local rival = nil
    local dependent = nil
    local counts = {
        hostile = 0,
        intimate = 0,
        dependent = 0,
        compromised = 0,
    }
    for _, bond in ipairs(bonds) do
        local score = (bond.closeness or 0) + math.floor((bond.intimacy or 0) * 0.4) - math.floor((bond.strain or 0) * 0.3)
        if score > strongest_score then
            strongest = bond
            strongest_score = score
        end
        if bond.arc == "Intimate" and not intimate then intimate = bond end
        if (bond.status == "Hostile" or bond.arc == "Breaking" or bond.category == "rival") and not rival then rival = bond end
        if bond.arc == "Dependent" and not dependent then dependent = bond end
        if bond.status == "Hostile" then counts.hostile = counts.hostile + 1 end
        if bond.arc == "Intimate" then counts.intimate = counts.intimate + 1 end
        if bond.arc == "Dependent" then counts.dependent = counts.dependent + 1 end
        if bond.arc == "Compromised" or bond.arc == "Binding" then counts.compromised = counts.compromised + 1 end
    end

    local most_urgent = bonds[1]

    -- Intelligence layer: gather warnings and readings across the web
    local warnings = {}
    local active_grievances = 0
    local autonomous_count = 0
    for _, bond in ipairs(bonds) do
        if bond.warning then
            warnings[#warnings + 1] = { name = bond.name, warning = bond.warning }
        end
        if bond.expectation and (bond.expectation.grievance or 0) >= 20 then
            active_grievances = active_grievances + 1
        end
        if (bond.thread_autonomy or 0) >= 44 then
            autonomous_count = autonomous_count + 1
        end
    end

    local web_reading
    if autonomous_count >= 4 then
        web_reading = "Most of the web is moving independently. Control is nominal."
    elseif autonomous_count >= 2 then
        web_reading = "Several bonds are acting on their own judgment now."
    elseif active_grievances >= 2 then
        web_reading = "Multiple bonds carry unspoken grievances. The web is stressed."
    elseif #warnings >= 2 then
        web_reading = "More than one bond is showing signs of trouble."
    elseif most_urgent and (most_urgent.thread_autonomy or 0) >= 50 then
        web_reading = most_urgent.name .. " is the bond most likely to act without you."
    else
        web_reading = "The web holds. No bond is moving faster than you can track."
    end

    local witness_fragments = ShadowWitnesses.chronicle_fragments(game_state)

    return {
        bonds = bonds,
        strongest = strongest,
        most_urgent = most_urgent,
        intimate = intimate,
        rival = rival,
        dependent = dependent,
        counts = counts,
        recent_moves = state.recent_moves or {},
        warnings = warnings,
        active_grievances = active_grievances,
        autonomous_count = autonomous_count,
        web_reading = web_reading,
        witness_fragments = witness_fragments,
        summary_line = strongest
            and ("Closest tie: " .. strongest.name .. " (" .. strongest.role .. "), " .. string.lower(strongest.status) .. ".")
            or "No living ties remain.",
        pressure_line = most_urgent
            and ("Most dangerous tie: " .. most_urgent.name .. " (" .. most_urgent.arc .. ").")
            or "No relation is pressing for decision.",
        storyline_line = most_urgent
            and (most_urgent.thread_summary or ("The loudest thread remains " .. most_urgent.name .. "."))
            or "No relationship thread has yet learned to move without you.",
        knot_line = intimate
            and ("Most tender tie: " .. intimate.name .. ".")
            or (dependent and ("Most consuming tie: " .. dependent.name .. ".") or "No one is yet close enough to ruin you tenderly."),
        fracture_line = rival
            and ("Open fracture: " .. rival.name .. " (" .. string.lower(rival.status) .. ").")
            or "No active feud has yet become the room's architecture.",
    }
end

function ShadowBonds.spotlights(game_state, limit)
    local detail = ShadowBonds.detail_snapshot(game_state)
    local rows = {}
    local max_rows = limit or 3

    if detail.recent_moves and #detail.recent_moves > 0 then
        for index = #detail.recent_moves, 1, -1 do
            if #rows >= max_rows then
                break
            end
            local move = detail.recent_moves[index]
            local bond = nil
            for _, item in ipairs(detail.bonds or {}) do
                if item.id == move.id then
                    bond = item
                    break
                end
            end
            rows[#rows + 1] = {
                label = move.name .. " | " .. (bond and bond.arc_title or title_case_words(move.thread_kind or "thread")),
                value = move.tone == "supportive" and "Moved Without You" or "Forced the Issue",
                detail = move.summary,
                tone = move.tone or "uneasy",
            }
        end
    end

    local function add_bond(bond, label)
        if not bond or #rows >= max_rows then
            return
        end
        for _, row in ipairs(rows) do
            if row.label:find(bond.name, 1, true) then
                return
            end
        end
        rows[#rows + 1] = {
            label = bond.name .. " | " .. label,
            value = bond.thread_state or bond.arc,
            detail = bond.agenda,
            tone = bond.status == "Hostile" and "hostile" or "uneasy",
        }
    end

    add_bond(detail.most_urgent, "Loudest Thread")
    add_bond(detail.intimate, "Tender Pull")
    add_bond(detail.rival, "Open Fracture")

    return rows
end

local function choose_linked_bond(state, primary)
    local best = nil
    local best_score = -math.huge
    for _, candidate in ipairs(state.bonds or {}) do
        if candidate.id ~= primary.id then
            local score = (candidate.closeness or 0)
                + math.floor((candidate.obligation or 0) * 0.7)
                + math.floor((candidate.leverage or 0) * 0.6)
                + math.floor((candidate.visibility or 0) * 0.3)
                + math.floor((candidate.strain or 0) * 0.25)

            if primary.category == "dependent" and (candidate.category == "power" or candidate.category == "kin") then
                score = score + 20
            elseif primary.category == "intimate" and (candidate.category == "kin" or candidate.category == "rival") then
                score = score + 18
            elseif primary.category == "rival" and (candidate.category == "intimate" or candidate.category == "power") then
                score = score + 18
            elseif primary.category == "power" and (candidate.category == "dependent" or candidate.category == "work") then
                score = score + 18
            elseif primary.category == "kin" and (candidate.category == "power" or candidate.category == "rival") then
                score = score + 18
            elseif candidate.category == "power" or candidate.category == "rival" then
                score = score + 10
            end

            if score > best_score then
                best = candidate
                best_score = score
            end
        end
    end
    return best
end

local function make_bond_payload(id, fields, history)
    if not id then
        return nil
    end
    local payload = { id = id }
    for key, value in pairs(fields or {}) do
        payload[key] = value
    end
    payload.history = history
    return payload
end

local function make_thread_option(label, description, check, success, failure, gate)
    return {
        label = label,
        description = description,
        gate = gate,
        check = check,
        success = success,
        failure = failure,
    }
end

local function autonomy_line(thread, bond)
    local autonomy = thread and thread.autonomy or 0
    if autonomy >= 70 then
        return bond.name .. " has started moving without waiting for your permission."
    elseif autonomy >= 52 then
        return bond.name .. " is already making quiet decisions of their own."
    end
    return bond.name .. " still waits for you more than is healthy."
end

local function build_thread_event(primary, thread, linked, generation)
    local id_root = "shadow_bond_thread_" .. primary.id .. "_" .. tostring(generation) .. "_" .. tostring(thread.kind or "entanglement")
    local linked_name = linked and linked.name or "another witness"
    local linked_role = linked and linked.role or "WITNESS"
    local autonomy = autonomy_line(thread, primary)

    if thread.kind == "legacy" then
        return {
            id = id_root,
            source = "shadow",
            type = "bond_thread",
            title = primary.name .. " Names the Branch Aloud",
            narrative = primary.name .. " has begun speaking of the denied branch in rooms where it can no longer be called private grief. " .. linked_name .. " (" .. linked_role .. ") has heard enough to become part of the shape of it. " .. autonomy,
            options = {
                make_thread_option(
                    "Stand beside the claim",
                    "Let the old branch be spoken with witnesses present, even if the life grows hotter for it.",
                    { trait = "SOC_ELO", axis = "PER_BLD", difficulty = 58 },
                    {
                        narrative = "The branch is no less broken, but it is harder to pretend it never existed.",
                        effects = {
                            claim = { legitimacy = 8, exposure = 8, ambition = 6, grievance = 3 },
                            shadow = { standing = 2, notoriety = 2, stress = 1 },
                            bond = make_bond_payload(primary.id, { closeness = 5, obligation = 5, stage_delta = 1, heat_delta = 6, autonomy_delta = 2 }, "The old branch was spoken aloud with you beside it."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { closeness = 2, obligation = 2, strain = 1 }, linked and ("They became a witness to " .. primary.name .. "'s branch-claim.") or nil),
                            chronicle = primary.name .. " spoke the broken branch aloud and the protagonist chose not to hush them back into obscurity.",
                        },
                    },
                    {
                        narrative = "The room remembers the claim mainly as an irritation, which is still a form of memory.",
                        effects = {
                            claim = { exposure = 10, usurper_risk = 5, grievance = 4 },
                            shadow = { standing = -1, notoriety = 3, stress = 3 },
                            bond = make_bond_payload(primary.id, { strain = 6, obligation = 4, stage_delta = 1, heat_delta = 8, autonomy_delta = 4 }, "The branch was named before the room was ready to hear it."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 3, leverage = 2 }, linked and ("They learned the branch could be used as public leverage.") or nil),
                            chronicle = "Speaking the denied branch too boldly gave the room a grievance it could hold and repeat.",
                        },
                    }
                ),
                make_thread_option(
                    "Force the matter back into silence",
                    "Keep the branch alive only in private memory, even if the silence wounds the blood that still believes.",
                    { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 57 },
                    {
                        narrative = "The rumor cools, but the kinship does not forgive the cooling.",
                        effects = {
                            claim = { exposure = -4, grievance = 4 },
                            shadow = { stress = -1, standing = 1 },
                            bond = make_bond_payload(primary.id, { closeness = -2, strain = 5, stage_delta = 0, heat_delta = -4, autonomy_delta = 3 }, "You pushed the branch back under the tongue."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { closeness = 1, leverage = 2 }, linked and ("They learned you preferred the claim hidden and therefore negotiable.") or nil),
                            chronicle = "The protagonist forced the old branch back into private speech and paid for the caution in blood-memory.",
                        },
                    },
                    {
                        narrative = "Silencing them only proves that the old grievance is still alive enough to fight.",
                        effects = {
                            claim = { grievance = 5, ambition = 3 },
                            shadow = { stress = 2, standing = -1 },
                            bond = make_bond_payload(primary.id, { closeness = -4, strain = 7, stage_delta = 1, heat_delta = 6, autonomy_delta = 6 }, "Being silenced turned the kinship sharper, not smaller."),
                            chronicle = primary.name .. " did not agree to be turned back into a family secret.",
                        },
                    }
                ),
            },
        }
    elseif thread.kind == "tenderness" then
        return {
            id = id_root,
            source = "shadow",
            type = "bond_thread",
            title = primary.name .. " Wants a Place in the Life",
            narrative = primary.name .. " has stopped pretending that tenderness can survive forever as an implication. " .. linked_name .. " has already begun noticing what the tie costs and what it might ask next. " .. autonomy,
            options = {
                make_thread_option(
                    "Make room for them openly",
                    "Give the tie a shape in the life instead of letting it live in hints and stolen time.",
                    { trait = "SOC_ELO", axis = "PER_LOY", difficulty = 57 },
                    {
                        narrative = "The tie becomes warmer and less deniable in the same motion.",
                        effects = {
                            shadow = { bonds = 3, stress = -2, standing = 1 },
                            bond = make_bond_payload(primary.id, { closeness = 7, intimacy = 8, obligation = 3, stage_delta = 1, heat_delta = 4 }, "You gave the tie a place instead of a pretext."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 2, leverage = 1 }, linked and ("They were forced to reckon with the tenderness becoming visible.") or nil),
                            chronicle = "The protagonist gave " .. primary.name .. " more than secrecy and so invited the ordinary dangers of a real bond.",
                        },
                    },
                    {
                        narrative = "The promise lands unevenly and leaves both parties more visible than sheltered.",
                        effects = {
                            shadow = { bonds = 1, stress = 3, notoriety = 1 },
                            bond = make_bond_payload(primary.id, { closeness = 2, intimacy = 4, strain = 5, stage_delta = 1, heat_delta = 7 }, "Trying to make the tie official exposed its weak joints."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { leverage = 2, closeness = -1 }, linked and ("They learned where the tender seam in the life now lay.") or nil),
                            chronicle = "The attempt to give tenderness a public shape left the shape vulnerable to every nearby appetite.",
                        },
                    }
                ),
                make_thread_option(
                    "Keep it intimate and undefined",
                    "Protect the bond by refusing a future shape neither of you can yet afford.",
                    { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 55 },
                    {
                        narrative = "Ambiguity spares the future at the cost of clarity.",
                        effects = {
                            shadow = { stress = -1, standing = 1 },
                            bond = make_bond_payload(primary.id, { intimacy = 2, leverage = 2, strain = 1, heat_delta = -2, autonomy_delta = 2 }, "You preserved the tie by refusing to name its future."),
                            chronicle = "The protagonist chose ambiguity with " .. primary.name .. ", which is another way of saying they chose another year of postponement.",
                        },
                    },
                    {
                        narrative = "The refusal lands as cowardice with better diction.",
                        effects = {
                            shadow = { bonds = -2, stress = 2 },
                            bond = make_bond_payload(primary.id, { closeness = -3, intimacy = -1, strain = 6, stage_delta = 1, heat_delta = 6, autonomy_delta = 5 }, "Your refusal to define the tie taught it how to harden."),
                            chronicle = primary.name .. " heard the unsaid answer and let the hurt become structure.",
                        },
                    }
                ),
            },
        }
    elseif thread.kind == "feud" then
        return {
            id = id_root,
            source = "shadow",
            type = "bond_thread",
            title = primary.name .. " Sets the Story Against You",
            narrative = primary.name .. " is no longer content to hate you privately. They have begun arranging the room before you enter it, and " .. linked_name .. " is already hearing the hostile version first. " .. autonomy,
            options = {
                make_thread_option(
                    "Meet the feud in person",
                    "Cut across the rumor by confronting the bond before witnesses become the real enemy.",
                    { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 59 },
                    {
                        narrative = "The hatred cools enough to stop ruling every conversation.",
                        effects = {
                            shadow = { bonds = 2, stress = -1, standing = 1 },
                            bond = make_bond_payload(primary.id, { closeness = 2, strain = -8, leverage = -3, heat_delta = -6 }, "You met the feud directly before it could thicken into folklore."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { closeness = 1, strain = -1 }, linked and ("They saw the feud reduced to human scale for a little while.") or nil),
                            chronicle = "The protagonist met " .. primary.name .. " in the open and returned with a quarrel smaller than the one they carried in.",
                        },
                    },
                    {
                        narrative = "The confrontation gives the feud fresher language and better witnesses.",
                        effects = {
                            shadow = { stress = 4, standing = -1, notoriety = 1 },
                            bond = make_bond_payload(primary.id, { strain = 8, leverage = 3, stage_delta = 1, heat_delta = 8, autonomy_delta = 4 }, "The direct confrontation sharpened the feud instead of cooling it."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 2, leverage = 2 }, linked and ("They learned enough to become useful to the feud.") or nil),
                            chronicle = "Trying to cut the quarrel short merely gave it cleaner edges.",
                        },
                    }
                ),
                make_thread_option(
                    "Turn another bond into your shield",
                    "Use what you know of the web to make sure the feud breaks against someone else first.",
                    { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 58 },
                    {
                        narrative = "You survive the year by making the web absorb the first blow.",
                        effects = {
                            morality = { act = "betrayal" },
                            shadow = { stress = 1, notoriety = 2, standing = 1 },
                            bond = make_bond_payload(primary.id, { leverage = 8, closeness = -2, strain = -1, stage_delta = 1, heat_delta = 5 }, "You survived the feud by making it hit the web instead."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 5, closeness = -2, leverage = 3 }, linked and ("They were used as part of the shield against " .. primary.name .. ".") or nil),
                            chronicle = "The protagonist let another tie absorb the first force of the feud with " .. primary.name .. " and called that prudence.",
                        },
                    },
                    {
                        narrative = "The shield notices what it has been made to do and the feud doubles rather than divides.",
                        effects = {
                            morality = { act = "betrayal" },
                            shadow = { standing = -2, stress = 3, notoriety = 2 },
                            bond = make_bond_payload(primary.id, { strain = 6, leverage = 4, heat_delta = 6 }, "The feud remained and your indirection became part of it."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 7, closeness = -4, leverage = 4 }, linked and ("They learned exactly how disposable they could become in your hands.") or nil),
                            chronicle = "Trying to redirect the feud taught the whole web where the protagonist thought expendability began.",
                        },
                    },
                    { axis = "PER_CRM", min = 52, label = "Cruelty" }
                ),
            },
        }
    elseif thread.kind == "need" then
        return {
            id = id_root,
            source = "shadow",
            type = "bond_thread",
            title = primary.name .. " Needs More Than You Have",
            narrative = primary.name .. " has become a life inside the life: fed by it, frightened by it, and increasingly willing to act without asking if the door closes. " .. linked_name .. " is close enough to be pulled into the need as well. " .. autonomy,
            options = {
                make_thread_option(
                    "Make room and carry them again",
                    "Let the year bend around their need rather than pretend it can wait.",
                    { trait = "MEN_PAT", axis = "PER_LOY", difficulty = 57 },
                    {
                        narrative = "The need remains, but it no longer feels solitary.",
                        effects = {
                            wealth = -1,
                            shadow = { bonds = 2, stress = 2, standing = 1 },
                            bond = make_bond_payload(primary.id, { closeness = 7, dependency = -2, obligation = 5, strain = -1, stage_delta = 1, heat_delta = 4 }, "You bent the year around their need."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { obligation = 3, strain = 1 }, linked and ("They were drawn into carrying some of " .. primary.name .. "'s need.") or nil),
                            chronicle = "The protagonist made room for " .. primary.name .. "'s need and in doing so gave the whole year a narrower shape.",
                        },
                    },
                    {
                        narrative = "You keep them afloat by letting the rest of the life thin out around both of you.",
                        effects = {
                            wealth = -2,
                            shadow = { bonds = 1, stress = 5, health = -1 },
                            bond = make_bond_payload(primary.id, { closeness = 3, dependency = 5, obligation = 5, strain = 4, stage_delta = 1, heat_delta = 7 }, "Supporting them consumed more of the life than either of you could admit."),
                            chronicle = "The year spent keeping " .. primary.name .. " upright left the protagonist looking less certain of how many lives one body can carry.",
                        },
                    }
                ),
                make_thread_option(
                    "Set terms and force a harder future",
                    "Give the tie boundaries even if the first boundary feels like cruelty.",
                    { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 58 },
                    {
                        narrative = "The dependence loosens, though the gratitude does not hurry to replace it.",
                        effects = {
                            shadow = { bonds = -1, stress = -1, standing = 1 },
                            bond = make_bond_payload(primary.id, { closeness = -2, dependency = -10, obligation = -3, strain = 4, leverage = 2, heat_delta = -3, autonomy_delta = 4 }, "You forced the tie toward a harsher kind of survival."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { closeness = 1, obligation = 2 }, linked and ("They were left to catch some of the need you refused to hold alone.") or nil),
                            chronicle = "The protagonist forced " .. primary.name .. " toward a future less dependent and less gentle.",
                        },
                    },
                    {
                        narrative = "It reads as abandonment from every angle that matters.",
                        effects = {
                            shadow = { bonds = -3, stress = 3, notoriety = 1 },
                            bond = make_bond_payload(primary.id, { closeness = -5, dependency = 2, obligation = -1, strain = 8, stage_delta = 1, heat_delta = 8, autonomy_delta = 6 }, "The attempt to force independence landed as abandonment."),
                            chronicle = primary.name .. " learned what your care looked like once it became expensive.",
                        },
                    }
                ),
            },
        }
    elseif thread.kind == "patronage" then
        return {
            id = id_root,
            source = "shadow",
            type = "bond_thread",
            title = primary.name .. " Calls the Debt Due",
            narrative = primary.name .. " has decided that old help, old shelter, or old access must now be paid back in a form you do not control. " .. linked_name .. " is close enough to be used in settling the account. " .. autonomy,
            options = {
                make_thread_option(
                    "Pay the debt in labor and obedience",
                    "Keep the patronage alive by meeting its terms before it hardens into open punishment.",
                    { trait = "SOC_NEG", axis = "PER_LOY", difficulty = 57 },
                    {
                        narrative = "The debt is not erased, but it becomes survivable again.",
                        effects = {
                            shadow = { standing = 2, stress = 1 },
                            bond = make_bond_payload(primary.id, { leverage = -5, obligation = 3, closeness = 2, strain = -2, heat_delta = -4 }, "You paid the debt before it became spectacle."),
                            chronicle = "The protagonist paid " .. primary.name .. " in service and obedience and bought another year beneath the hand that already knew how to press.",
                        },
                    },
                    {
                        narrative = "Payment only teaches the patron how much more can still be taken.",
                        effects = {
                            shadow = { stress = 3, standing = -1 },
                            bond = make_bond_payload(primary.id, { leverage = 5, obligation = 4, strain = 4, stage_delta = 1, heat_delta = 6 }, "Meeting the debt proved only that the debt had room to grow."),
                            chronicle = "Paying the favor due to " .. primary.name .. " merely clarified the size of the appetite above the protagonist.",
                        },
                    }
                ),
                make_thread_option(
                    "Slip the cost onto another shoulder",
                    "Protect the self by making the patronage bite somewhere else in the web.",
                    { trait = "SOC_NEG", axis = "PER_CRM", difficulty = 58 },
                    {
                        narrative = "The patron remains satisfied and the web grows meaner around the edges.",
                        effects = {
                            morality = { act = "exploitation" },
                            wealth = 1,
                            shadow = { stress = 1, notoriety = 2 },
                            bond = make_bond_payload(primary.id, { leverage = 3, obligation = -1, heat_delta = 3, autonomy_delta = 3 }, "You paid the debt by feeding the patronage another life."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 6, dependency = 2, closeness = -3 }, linked and ("They were leaned on so your debt would not close around your own throat first.") or nil),
                            chronicle = "The protagonist satisfied patronage by pushing some of its cost into the surrounding web, which is to say into another human life.",
                        },
                    },
                    {
                        narrative = "The attempt to redirect the debt is seen clearly and remembered with the proper disgust.",
                        effects = {
                            morality = { act = "exploitation" },
                            shadow = { standing = -2, stress = 3, notoriety = 2 },
                            bond = make_bond_payload(primary.id, { leverage = 6, strain = 4, stage_delta = 1, heat_delta = 5 }, "The patronage learned you would betray the web to keep yourself standing."),
                            bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 5, closeness = -4, leverage = 3 }, linked and ("They learned exactly what value you put on them under pressure.") or nil),
                            chronicle = "Trying to misdirect the debt taught both patron and victim how cheaply the protagonist priced another person's safety.",
                        },
                    },
                    { axis = "PER_CRM", min = 52, label = "Cruelty" }
                ),
            },
        }
    end

    return {
        id = id_root,
        source = "shadow",
        type = "bond_thread",
        title = primary.name .. " Brings Work to the Door",
        narrative = primary.name .. " has become more than a relationship and less than a contract. Work, favors, resentment, and convenience now keep crossing the same threshold, and " .. linked_name .. " can already smell the next compromise. " .. autonomy,
        options = {
            make_thread_option(
                "Join the scheme together",
                "Take the offered work or plot and see whether shared risk can still resemble loyalty.",
                { trait = "SOC_NEG", axis = "PER_CUR", difficulty = 57 },
                {
                    narrative = "The scheme pays something, though not always in the currency you expected.",
                    effects = {
                        wealth = 1,
                        shadow = { bonds = 2, stress = 1, craft = 1 },
                        bond = make_bond_payload(primary.id, { closeness = 4, leverage = 2, obligation = 2, stage_delta = 1, heat_delta = 4 }, "You entered the scheme together and made the tie heavier with use."),
                        bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 2, leverage = 1 }, linked and ("They were drawn into the edges of the scheme.") or nil),
                        chronicle = "The protagonist joined " .. primary.name .. " in a shared scheme and let usefulness become another form of intimacy.",
                    },
                },
                {
                    narrative = "The work lands crooked and the tie inherits the full shape of the failure.",
                    effects = {
                        wealth = -1,
                        shadow = { stress = 3, notoriety = 1 },
                        bond = make_bond_payload(primary.id, { closeness = -2, strain = 5, leverage = 3, stage_delta = 1, heat_delta = 6 }, "The failed scheme made the tie feel transactional even in blame."),
                        chronicle = "The scheme with " .. primary.name .. " failed in the familiar way: first financially, then morally, then socially.",
                    },
                }
            ),
            make_thread_option(
                "Refuse and keep the threshold clean",
                "Turn down the work before it teaches the tie to survive only through mutual compromise.",
                { trait = "MEN_PAT", axis = "PER_ADA", difficulty = 55 },
                {
                    narrative = "Distance preserves the bond, though at the cost of some warmth and some possibility.",
                    effects = {
                        shadow = { stress = -1, standing = 1 },
                        bond = make_bond_payload(primary.id, { closeness = -1, strain = 1, heat_delta = -3 }, "You kept work from becoming the whole architecture of the tie."),
                        chronicle = "The protagonist refused the offered scheme and chose a cleaner threshold over a richer one.",
                    },
                },
                {
                    narrative = "The refusal sounds less principled than ungrateful from the other side of the door.",
                    effects = {
                        shadow = { bonds = -1, stress = 2 },
                        bond = make_bond_payload(primary.id, { closeness = -3, strain = 4, obligation = 2, stage_delta = 1, heat_delta = 5, autonomy_delta = 3 }, "Refusal taught the tie how quickly usefulness can become resentment."),
                        chronicle = primary.name .. " heard the refusal as ingratitude and let the work-tie darken accordingly.",
                    },
                }
            ),
        },
    }
end

function ShadowBonds.generate_story_events(game_state, limit)
    local state = ShadowBonds.ensure_state(game_state)
    ensure_threads(state)

    local generation = game_state and game_state.generation or 1
    local ranked = {}
    for _, bond in ipairs(state.bonds or {}) do
        local thread = nudge_thread(get_thread(state, bond), bond, generation)
        local cooldown = ((thread and thread.stage or 1) >= 3) and 0 or 1
        if generation - (thread and thread.last_generation or 0) >= cooldown then
            ranked[#ranked + 1] = {
                bond = bond,
                thread = thread,
                score = thread_pressure(thread, bond),
            }
        end
    end

    table.sort(ranked, function(a, b)
        if a.score == b.score then
            return a.bond.name < b.bond.name
        end
        return a.score > b.score
    end)

    local events = {}
    local max_events = limit or 2
    for index = 1, math.min(max_events, #ranked) do
        local item = ranked[index]
        local linked = choose_linked_bond(state, item.bond)
        item.thread.last_generation = generation
        events[#events + 1] = build_thread_event(item.bond, item.thread, linked, generation)
    end
    return events
end

local function find_snapshot_bond(game_state, bond_id)
    local detail = ShadowBonds.detail_snapshot(game_state)
    for _, bond in ipairs(detail.bonds or {}) do
        if bond.id == bond_id then
            return bond
        end
    end
    return nil
end

local function build_autonomy_aftermath_event(move, bond, linked, generation)
    if not move or not bond then
        return nil
    end

    local linked_name = linked and linked.name or "another witness"
    local linked_role = linked and linked.role or "WITNESS"
    local title = nil
    local narrative = nil
    local success = nil
    local failure = nil

    if move.thread_kind == "legacy" then
        title = move.name .. " Brings Proof and Trouble Together"
        narrative = move.summary .. " Now " .. linked_name .. " (" .. linked_role .. ") wants to know whether the branch is a burden to hide or a weapon to sharpen."
        success = {
            narrative = "You turn the rumor into usable memory before it rots into gossip.",
            effects = {
                claim = { proof = 6, legitimacy = 4, exposure = 2 },
                shadow = { standing = 1, stress = 1 },
                bond = make_bond_payload(move.id, { closeness = 3, obligation = 2, heat_delta = -2 }, "You helped make the branch-story coherent instead of merely loud."),
                bond_secondary = make_bond_payload(linked and linked.id or nil, { closeness = 2, obligation = 1 }, linked and ("They were made a deliberate witness instead of an accidental one.") or nil),
                chronicle = "What " .. move.name .. " stirred around the denied branch was gathered into something more durable than rumor.",
            },
        }
        failure = {
            narrative = "The branch story multiplies faster than the proof beneath it.",
            effects = {
                claim = { exposure = 6, usurper_risk = 3, grievance = 2 },
                shadow = { stress = 2, notoriety = 2 },
                bond = make_bond_payload(move.id, { strain = 4, heat_delta = 4, autonomy_delta = 2 }, "The branch-story outran the evidence again."),
                chronicle = "The denied branch grew louder without becoming cleaner, which is often how dangerous stories mature.",
            },
        }
    elseif move.thread_kind == "tenderness" then
        title = move.name .. " Wants an Answer to the Quiet Gesture"
        narrative = move.summary .. " The tenderness has now become visible enough that " .. linked_name .. " can either shelter it or wound it."
        success = {
            narrative = "You answer the gesture before shame or fear can do it for you.",
            effects = {
                shadow = { bonds = 2, stress = -1, standing = 1 },
                bond = make_bond_payload(move.id, { closeness = 4, intimacy = 4, strain = -1, heat_delta = -3 }, "You answered their quiet gesture with one of your own."),
                chronicle = "The protagonist answered what " .. move.name .. " had quietly risked and let tenderness become less one-sided.",
            },
        }
        failure = {
            narrative = "Delay turns the gesture sour and lets the room name it first.",
            effects = {
                shadow = { bonds = -1, stress = 2, notoriety = 1 },
                bond = make_bond_payload(move.id, { closeness = -2, strain = 4, heat_delta = 4, autonomy_delta = 2 }, "You let the quiet gesture sit long enough to curdle."),
                bond_secondary = make_bond_payload(linked and linked.id or nil, { leverage = 2, strain = 1 }, linked and ("They now know where the tender seam lies.") or nil),
                chronicle = "What " .. move.name .. " offered quietly was left unanswered long enough for the room to become part of it.",
            },
        }
    elseif move.thread_kind == "feud" then
        title = move.name .. " Has Witnesses Now"
        narrative = move.summary .. " The hostile story is no longer private, and " .. linked_name .. " is already deciding whether to repeat it, profit from it, or blunt it."
        success = {
            narrative = "You cut the feud off from easy witnesses before it fully hardens.",
            effects = {
                shadow = { standing = 1, stress = -1 },
                bond = make_bond_payload(move.id, { strain = -5, leverage = -2, heat_delta = -3 }, "You forced the feud back into a smaller room."),
                bond_secondary = make_bond_payload(linked and linked.id or nil, { closeness = 1, strain = -1 }, linked and ("They were denied the easy role of witness to the feud.") or nil),
                chronicle = "The protagonist moved quickly enough to keep " .. move.name .. "'s hostility from becoming common property.",
            },
        }
        failure = {
            narrative = "The feud expands, and the witnesses find their use in it.",
            effects = {
                shadow = { stress = 3, notoriety = 2, standing = -1 },
                bond = make_bond_payload(move.id, { strain = 5, leverage = 3, heat_delta = 5 }, "The feud found witnesses and therefore momentum."),
                bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 3, leverage = 2 }, linked and ("They found a position inside the feud and kept it.") or nil),
                chronicle = move.name .. "'s hostility escaped the private chamber and learned how to walk on its own.",
            },
        }
    elseif move.thread_kind == "need" then
        title = move.name .. " Has Spent the Help Already"
        narrative = move.summary .. " Whatever relief they found has already been consumed by the life. " .. linked_name .. " is close enough to be pulled into the aftershock."
        success = {
            narrative = "You convert the crisis into a harsher but steadier arrangement.",
            effects = {
                shadow = { bonds = 1, stress = 1, standing = 1 },
                bond = make_bond_payload(move.id, { dependency = -4, obligation = 2, closeness = 2, heat_delta = -2 }, "You built a rougher structure around their need."),
                bond_secondary = make_bond_payload(linked and linked.id or nil, { obligation = 2 }, linked and ("They were asked to help in a way that might actually hold.") or nil),
                chronicle = "The aftermath of " .. move.name .. "'s need was shaped into something less desperate and only slightly more humane.",
            },
        }
        failure = {
            narrative = "The aftershock lands on everyone near enough to care.",
            effects = {
                shadow = { stress = 3, bonds = -1 },
                bond = make_bond_payload(move.id, { dependency = 3, strain = 3, heat_delta = 4 }, "Their need returned before the previous answer was even cold."),
                bond_secondary = make_bond_payload(linked and linked.id or nil, { strain = 2, closeness = -1 }, linked and ("They were dragged into the second wave of the same crisis.") or nil),
                chronicle = "The help given to " .. move.name .. " bought less time than anyone had hoped and implicated more people than before.",
            },
        }
    else
        title = move.name .. " Uses the Opening"
        narrative = move.summary .. " The move has opened another practical door, and " .. linked_name .. " is already near enough to change what comes through it."
        success = {
            narrative = "You shape the opening before it becomes another trap disguised as opportunity.",
            effects = {
                shadow = { craft = 1, standing = 1 },
                bond = make_bond_payload(move.id, { closeness = 2, leverage = -1, heat_delta = -2 }, "You made use of the opening without fully surrendering to it."),
                chronicle = "The protagonist turned " .. move.name .. "'s opening into a usable advantage before the web could sour around it.",
            },
        }
        failure = {
            narrative = "The opening reveals itself as another pressure-point in the web.",
            effects = {
                shadow = { stress = 2, standing = -1 },
                bond = make_bond_payload(move.id, { leverage = 3, strain = 2, heat_delta = 3 }, "The opportunity became another handle on the life."),
                chronicle = "What began as an opening through " .. move.name .. " quickly learned how to behave like leverage instead.",
            },
        }
    end

    return {
        id = "shadow_bond_aftermath_" .. move.id .. "_" .. tostring(generation),
        source = "shadow",
        type = "bond_aftermath",
        title = title,
        narrative = narrative,
        options = {
            make_thread_option(
                "Take hold of it before it spreads",
                "Answer the consequence directly while it is still small enough to shape.",
                { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 57 },
                success,
                failure
            ),
            make_thread_option(
                "Let the web sort itself out",
                "Spend your attention elsewhere and trust the people involved to do what they will.",
                { trait = "MEN_PAT", axis = "PER_CUR", difficulty = 55 },
                {
                    narrative = "The consequence settles into the web without drawing fresh blood this time.",
                    effects = {
                        shadow = { stress = -1 },
                        bond = make_bond_payload(move.id, { heat_delta = -1, autonomy_delta = 2 }, "You allowed the aftermath to settle without intervening."),
                        chronicle = "The protagonist left the matter to the web itself and, for once, the web did not immediately demand more blood.",
                    },
                },
                {
                    narrative = "Neglect gives the consequence time to choose its own shape.",
                    effects = {
                        shadow = { stress = 2, standing = -1 },
                        bond = make_bond_payload(move.id, { strain = 3, heat_delta = 3, autonomy_delta = 3 }, "Neglect gave the aftermath time to harden."),
                        chronicle = "What was left alone did not stay small.",
                    },
                }
            ),
        },
    }
end

function ShadowBonds.generate_aftermath_events(game_state, limit)
    local state = ShadowBonds.ensure_state(game_state)
    local generation = game_state and game_state.generation or 1
    local moves = state.recent_moves or {}
    if #moves == 0 then
        return {}
    end

    local events = {}
    local max_events = limit or 1
    for index = #moves, 1, -1 do
        if #events >= max_events then
            break
        end
        local move = moves[index]
        local bond = find_bond(state, move.id)
        if bond then
            local linked = choose_linked_bond(state, bond)
            local event = build_autonomy_aftermath_event(move, bond, linked, generation)
            if event then
                events[#events + 1] = event
            end
        end
    end
    return events
end

local function rank_targets(detail)
    local picks = {}
    local seen = {}
    local function add(bond)
        if bond and not seen[bond.id] then
            seen[bond.id] = true
            picks[#picks + 1] = bond
        end
    end
    add(detail.most_urgent)
    add(detail.intimate)
    add(detail.dependent)
    add(detail.rival)
    add(detail.strongest)
    while #picks > 3 do
        table.remove(picks)
    end
    return picks
end

local function build_action_for_target(target)
    if not target then
        return nil
    end

    local mode = action_for_bond(target)
    local action_id = "bond_" .. mode .. ":" .. target.id
    local title = nil
    local description = nil
    local check = nil
    local success = nil
    local failure = nil

    if mode == "depend" then
        title = "Keep " .. target.name .. " from Paying for Your Life"
        description = "The tie has become a dependency. Spend the year protecting them, feeding them, or refusing to let the world reach them through you."
        check = { trait = "MEN_PAT", axis = "PER_LOY", difficulty = 57 }
        success = {
            narrative = target.name .. " remains in your orbit without being crushed by it.",
            effects = {
                wealth = -1,
                shadow = { bonds = 4, standing = 1, stress = 1 },
                chronicle = target.name .. " was carried through the year by the protagonist's steadier choices, which made affection and burden briefly indistinguishable.",
            },
        }
        failure = {
            narrative = "Care turns ragged. Love survives, but not gently.",
            effects = {
                wealth = -2,
                shadow = { bonds = 1, stress = 5, standing = -1, health = -1 },
                chronicle = "The dependent tie around " .. target.name .. " consumed the year and left both parties looking narrower than before.",
            },
        }
    elseif mode == "repair" then
        title = "Salvage " .. target.name
        description = "The tie is close to breaking. Spend the year on apology, negotiation, and the dangerous work of not letting pride speak first."
        check = { trait = "SOC_NEG", axis = "PER_ADA", difficulty = 58 }
        success = {
            narrative = "The damage remains visible, but it stops spreading for now.",
            effects = {
                shadow = { bonds = 3, stress = -1, standing = 1 },
                chronicle = "The protagonist spent the year repairing what had nearly become an enemy in " .. target.name .. ".",
            },
        }
        failure = {
            narrative = "The conversation clarifies the wound instead of closing it.",
            effects = {
                shadow = { bonds = -2, stress = 4, standing = -1, notoriety = 1 },
                chronicle = "The attempt to repair matters with " .. target.name .. " left the quarrel better named and therefore harder to escape.",
            },
        }
    elseif mode == "reveal" then
        title = "Trust " .. target.name .. " with the Worst of It"
        description = "The tie has become intimate enough to change the life if you speak plainly. Spend the year risking honesty instead of performance."
        check = { trait = "SOC_ELO", axis = "PER_LOY", difficulty = 56 }
        success = {
            narrative = "Trust makes the tie dearer and more dangerous, which is to say more real.",
            effects = {
                shadow = { bonds = 4, stress = -2, standing = 1 },
                chronicle = "The protagonist stopped performing long enough for " .. target.name .. " to meet the unguarded version beneath.",
            },
        }
        failure = {
            narrative = "The truth arrives without shelter and does not land kindly.",
            effects = {
                shadow = { bonds = -1, stress = 4, notoriety = 1 },
                chronicle = "Honesty toward " .. target.name .. " proved noble in intent and untidy in result.",
            },
        }
    elseif mode == "bargain" then
        title = "Renegotiate " .. target.name
        description = "The tie is knotted with leverage and old promises. Spend the year trying to make the bond survivable without pretending it is clean."
        check = { trait = "SOC_NEG", axis = "PER_CUR", difficulty = 58 }
        success = {
            narrative = "The terms improve. The memory of the old terms remains.",
            effects = {
                wealth = 1,
                shadow = { bonds = 2, stress = -1, standing = 2 },
                chronicle = "The protagonist spent the year renegotiating the terms of life with " .. target.name .. " and emerged less owned than before.",
            },
        }
        failure = {
            narrative = "The bargain holds, but not in your favor.",
            effects = {
                wealth = -1,
                shadow = { bonds = -1, stress = 3, standing = -1 },
                chronicle = target.name .. " kept the upper hand through another year, and the protagonist learned the price of staying useful.",
            },
        }
    else
        title = "Tend the Tie with " .. target.name
        description = "Not every decisive year is dramatic. Spend this one reinforcing a bond before scarcity, work, or fear gets there first."
        check = { trait = "SOC_LEA", axis = "PER_LOY", difficulty = 55 }
        success = {
            narrative = "The bond becomes harder for the year to strip away.",
            effects = {
                shadow = { bonds = 4, stress = -1, standing = 1 },
                chronicle = "The protagonist spent the year on the plain labor of keeping " .. target.name .. " close, and the plain labor held.",
            },
        }
        failure = {
            narrative = "Ordinary neglect does what open cruelty often fails to do.",
            effects = {
                shadow = { bonds = -1, stress = 2 },
                chronicle = "The tie with " .. target.name .. " was not betrayed, merely underfed, which can amount to the same thing by winter.",
            },
        }
    end

    return {
        id = action_id,
        title = title,
        subtitle = "Relationships",
        description = description,
        check = check,
        success = success,
        failure = failure,
    }
end

function ShadowBonds.generate_actions(game_state)
    local detail = ShadowBonds.detail_snapshot(game_state)
    local actions = {}
    for _, target in ipairs(rank_targets(detail)) do
        actions[#actions + 1] = build_action_for_target(target)
    end
    return actions
end

function ShadowBonds.generate_action(game_state)
    local actions = ShadowBonds.generate_actions(game_state)
    return actions[1]
end

function ShadowBonds.apply_focus(game_state, focus_id, quality)
    local state = ShadowBonds.ensure_state(game_state)
    local raw_mode, bond_id = tostring(focus_id or ""):match("^bond_([^:]+):(.+)$")
    local target = bond_id and find_bond(state, bond_id) or nil
    local mode = raw_mode or "tend"

    if not target then
        local first = state.bonds and state.bonds[1] or nil
        local second = state.bonds and state.bonds[2] or nil
        local third = state.bonds and state.bonds[3] or nil
        local fourth = state.bonds and state.bonds[4] or nil
        local text = tostring(focus_id or "")
        if text:find("^occupation_") then
            if quality == "triumph" or quality == "success" then
                if second then
                    second.closeness = Math.clamp(second.closeness + 3, 0, 100)
                end
                if third then
                    third.strain = Math.clamp(third.strain + 2, 0, 100)
                end
            else
                if second then
                    second.strain = Math.clamp(second.strain + 3, 0, 100)
                end
                if fourth then
                    fourth.leverage = Math.clamp(fourth.leverage + 2, 0, 100)
                end
            end
        elseif text:find("^burden_") then
            if quality == "triumph" or quality == "success" then
                if first then
                    first.closeness = Math.clamp(first.closeness + 2, 0, 100)
                end
                if third then
                    third.strain = Math.clamp(third.strain - 1, 0, 100)
                end
            else
                if first then
                    first.strain = Math.clamp(first.strain + 4, 0, 100)
                end
                if third then
                    third.strain = Math.clamp(third.strain + 3, 0, 100)
                end
                if fourth then
                    fourth.visibility = Math.clamp(fourth.visibility + 2, 0, 100)
                end
            end
        elseif text:find("^private_") or text:find("^body_") then
            if quality == "triumph" or quality == "success" then
                if first then
                    first.closeness = Math.clamp(first.closeness + 1, 0, 100)
                end
            else
                if first then
                    first.strain = Math.clamp(first.strain + 3, 0, 100)
                end
                if second then
                    second.strain = Math.clamp(second.strain + 2, 0, 100)
                end
            end
        end

        local passive = ShadowBonds.snapshot(game_state)
        local lines = {}
        for index = 1, math.min(2, #passive) do
            local bond = passive[index]
            lines[#lines + 1] = bond.name .. " (" .. bond.role .. "): " .. bond.status .. "."
        end
        return lines
    end

    local impact = quality == "triumph" and 2 or (quality == "success" and 1 or (quality == "failure" and -1 or -2))

    if mode == "depend" then
        target.closeness = Math.clamp(target.closeness + 5 * impact, 0, 100)
        target.dependency = Math.clamp(target.dependency + (impact > 0 and -6 or 8), 0, 100)
        target.obligation = Math.clamp(target.obligation + (impact > 0 and -2 or 5), 0, 100)
        target.strain = Math.clamp(target.strain + (impact > 0 and -4 or 6), 0, 100)
    elseif mode == "repair" then
        target.closeness = Math.clamp(target.closeness + 4 * impact, 0, 100)
        target.strain = Math.clamp(target.strain + (impact > 0 and -8 or 8), 0, 100)
        target.leverage = Math.clamp(target.leverage + (impact > 0 and -3 or 4), 0, 100)
    elseif mode == "reveal" then
        target.intimacy = Math.clamp(target.intimacy + (impact > 0 and 8 or -4), 0, 100)
        target.closeness = Math.clamp(target.closeness + (impact > 0 and 5 or -3), 0, 100)
        target.strain = Math.clamp(target.strain + (impact > 0 and -2 or 5), 0, 100)
    elseif mode == "bargain" then
        target.leverage = Math.clamp(target.leverage + (impact > 0 and -7 or 6), 0, 100)
        target.obligation = Math.clamp(target.obligation + (impact > 0 and -3 or 5), 0, 100)
        target.closeness = Math.clamp(target.closeness + (impact > 0 and 2 or -2), 0, 100)
        target.strain = Math.clamp(target.strain + (impact > 0 and -3 or 4), 0, 100)
    else
        target.closeness = Math.clamp(target.closeness + (impact > 0 and 5 or -2), 0, 100)
        target.intimacy = Math.clamp(target.intimacy + (impact > 0 and 2 or 0), 0, 100)
        target.strain = Math.clamp(target.strain + (impact > 0 and -2 or 2), 0, 100)
    end
    local thread = nudge_thread(get_thread(state, target), target, game_state and game_state.generation or 1)
    if thread then
        thread.heat = Math.clamp((thread.heat or 0) + (impact > 0 and -3 or 5), 0, 100)
        thread.autonomy = Math.clamp((thread.autonomy or 0) + (impact > 0 and 1 or 4), 0, 100)
        if impact < 0 then
            thread.stage = Math.clamp((thread.stage or 1) + 1, 1, 4)
        end
    end
    push_history(target, mode_label(mode) .. " year: " .. (impact > 0 and "the tie held" or "the tie worsened") .. ".")

    local lines = {
        mode_label(mode) .. " " .. target.name .. ": " .. status_for(target) .. " | " .. arc_for(target) .. ".",
        "Closeness " .. target.closeness .. " | Strain " .. target.strain .. " | Obligation " .. target.obligation .. ".",
    }

    local bonds = ShadowBonds.snapshot(game_state)
    if bonds[1] then
        lines[#lines + 1] = "Most pressing tie: " .. bonds[1].name .. " (" .. bonds[1].arc .. ")."
    end
    return lines
end

function ShadowBonds.apply_event(game_state, payload)
    if not payload or not payload.id then
        return
    end

    local state = ShadowBonds.ensure_state(game_state)
    local target = find_bond(state, payload.id)
    if not target then
        return
    end

    local deltas = {
        closeness = payload.closeness or 0,
        strain = payload.strain or 0,
        obligation = payload.obligation or 0,
        intimacy = payload.intimacy or 0,
        leverage = payload.leverage or 0,
        dependency = payload.dependency or 0,
        visibility = payload.visibility or 0,
        volatility = payload.volatility or 0,
    }

    for key, delta in pairs(deltas) do
        if delta ~= 0 then
            target[key] = Math.clamp((target[key] or 0) + delta, 0, 100)
        end
    end

    local thread = nudge_thread(get_thread(state, target), target, game_state and game_state.generation or 1)
    if thread then
        if payload.stage_delta and payload.stage_delta ~= 0 then
            thread.stage = Math.clamp((thread.stage or 1) + payload.stage_delta, 1, 4)
        end
        if payload.heat_delta and payload.heat_delta ~= 0 then
            thread.heat = Math.clamp((thread.heat or 0) + payload.heat_delta, 0, 100)
        end
        if payload.autonomy_delta and payload.autonomy_delta ~= 0 then
            thread.autonomy = Math.clamp((thread.autonomy or 0) + payload.autonomy_delta, 0, 100)
        end
        if payload.stage then
            thread.stage = Math.clamp(payload.stage, 1, 4)
        end
        if payload.heat then
            thread.heat = Math.clamp(payload.heat, 0, 100)
        end
        if payload.autonomy then
            thread.autonomy = Math.clamp(payload.autonomy, 0, 100)
        end
        thread.last_generation = payload.generation or (game_state and game_state.generation or thread.last_generation or 0)
    end

    push_history(target, payload.history or "Event fallout altered the tie without asking permission.")
end

function ShadowBonds.tick_year(game_state, focus_id, quality)
    local state = ShadowBonds.ensure_state(game_state)
    local active_id = tostring(focus_id or ""):match("^bond_[^:]+:(.+)$")
    local stress = game_state and game_state.shadow_state and game_state.shadow_state.stress or 50
    local body_weight = 0
    if game_state and game_state.shadow_body then
        local wound = game_state.shadow_body.wounds and game_state.shadow_body.wounds[1]
        local illness = game_state.shadow_body.illnesses and game_state.shadow_body.illnesses[1]
        local compulsion = game_state.shadow_body.compulsions and game_state.shadow_body.compulsions[1]
        body_weight = math.max(
            wound and wound.severity or 0,
            illness and illness.severity or 0,
            compulsion and compulsion.severity or 0
        )
    end

    local lines = {}
    for _, bond in ipairs(state.bonds or {}) do
        if bond.id ~= active_id then
            local strain_delta = 0
            local closeness_delta = 0
            if bond.category == "dependent" then
                bond.dependency = Math.clamp((bond.dependency or 0) + 1, 0, 100)
                strain_delta = strain_delta + (stress >= 60 and 2 or 1)
            elseif bond.category == "intimate" then
                strain_delta = strain_delta + (stress >= 62 and 2 or 1)
                closeness_delta = closeness_delta - (((quality == "failure") or (quality == "disaster")) and 2 or 1)
            elseif bond.category == "rival" then
                bond.leverage = Math.clamp((bond.leverage or 0) + 1 + ((((quality == "failure") or (quality == "disaster")) and 1) or 0), 0, 100)
                strain_delta = strain_delta + 1
            elseif bond.category == "power" then
                bond.obligation = Math.clamp((bond.obligation or 0) + 1, 0, 100)
                strain_delta = strain_delta + (stress >= 70 and 1 or 0)
            else
                strain_delta = strain_delta + (stress >= 74 and 1 or 0)
            end

            if body_weight >= 12 then
                strain_delta = strain_delta + 1
            end
            if quality == "triumph" then
                closeness_delta = closeness_delta + 1
            elseif quality == "disaster" then
                strain_delta = strain_delta + 1
            end

            if strain_delta ~= 0 then
                bond.strain = Math.clamp((bond.strain or 0) + strain_delta, 0, 100)
            end
            if closeness_delta ~= 0 then
                bond.closeness = Math.clamp((bond.closeness or 0) + closeness_delta, 0, 100)
            end
        end
        local thread = nudge_thread(get_thread(state, bond), bond, game_state and game_state.generation or 1)
        if thread then
            thread.heat = Math.clamp((thread.heat or 0) + (stress >= 70 and 2 or 1) + ((quality == "failure" or quality == "disaster") and 1 or 0), 0, 100)
            if bond.id ~= active_id then
                thread.autonomy = Math.clamp((thread.autonomy or 0) + 1 + (((quality == "failure" or quality == "disaster") and 1) or 0), 0, 100)
            end
            if (thread.heat or 0) >= 78 then
                thread.stage = Math.clamp(math.max(thread.stage or 1, 4), 1, 4)
            elseif (thread.heat or 0) >= 62 then
                thread.stage = Math.clamp(math.max(thread.stage or 1, 3), 1, 4)
            end
        end
    end

    local detail = ShadowBonds.detail_snapshot(game_state)
    if detail.dependent then
        lines[#lines + 1] = "Need gathers around " .. detail.dependent.name .. "."
    end
    if detail.rival then
        lines[#lines + 1] = "The fracture with " .. detail.rival.name .. " keeps widening in the dark."
    end
    if detail.most_urgent and detail.most_urgent.thread_state then
        lines[#lines + 1] = detail.most_urgent.name .. ": " .. detail.most_urgent.thread_state .. " thread."
    end
    return lines
end

local function apply_shadow_delta(game_state, key, delta)
    local state = game_state and game_state.shadow_state or nil
    if not state or state[key] == nil or not delta or delta == 0 then
        return
    end
    state[key] = Math.clamp((state[key] or 0) + delta, 0, 100)
end

local function apply_claim_delta(game_state, key, delta)
    local state = game_state and game_state.shadow_claim or nil
    if not state or state[key] == nil or not delta or delta == 0 then
        return
    end
    state[key] = Math.clamp((state[key] or 0) + delta, 0, 100)
end

local function autonomy_record(state, bond, thread, summary, tone)
    state.recent_moves = state.recent_moves or {}
    state.recent_moves[#state.recent_moves + 1] = {
        id = bond.id,
        name = bond.name,
        role = bond.role,
        category = bond.category,
        thread_kind = thread and thread.kind or thread_kind_for_bond(bond),
        tone = tone or "uneasy",
        summary = summary,
    }
    while #state.recent_moves > 6 do
        table.remove(state.recent_moves, 1)
    end
end

local function resolve_autonomous_move(game_state, state, bond, thread, quality)
    local supportive = ((bond.closeness or 0) + math.floor((bond.intimacy or 0) * 0.4)) >= ((bond.strain or 0) + math.floor((bond.leverage or 0) * 0.2))
        and quality ~= "failure"
        and quality ~= "disaster"

    local summary = nil
    if thread.kind == "legacy" then
        if supportive then
            apply_claim_delta(game_state, "proof", 2)
            apply_claim_delta(game_state, "legitimacy", 1)
            bond.obligation = Math.clamp((bond.obligation or 0) + 2, 0, 100)
            bond.closeness = Math.clamp((bond.closeness or 0) + 2, 0, 100)
            summary = bond.name .. " gathered another whisper in favor of the denied branch."
        else
            apply_claim_delta(game_state, "exposure", 3)
            apply_claim_delta(game_state, "usurper_risk", 2)
            bond.strain = Math.clamp((bond.strain or 0) + 2, 0, 100)
            summary = bond.name .. " spoke of the denied branch where too many ears were listening."
        end
    elseif thread.kind == "tenderness" then
        if supportive then
            apply_shadow_delta(game_state, "stress", -1)
            apply_shadow_delta(game_state, "bonds", 1)
            bond.closeness = Math.clamp((bond.closeness or 0) + 2, 0, 100)
            bond.intimacy = Math.clamp((bond.intimacy or 0) + 2, 0, 100)
            summary = bond.name .. " quietly kept a place for you when the year narrowed."
        else
            apply_shadow_delta(game_state, "stress", 2)
            bond.strain = Math.clamp((bond.strain or 0) + 3, 0, 100)
            bond.closeness = Math.clamp((bond.closeness or 0) - 1, 0, 100)
            summary = bond.name .. " withdrew just enough to let the loss be felt."
        end
    elseif thread.kind == "feud" then
        if supportive then
            bond.strain = Math.clamp((bond.strain or 0) - 2, 0, 100)
            bond.leverage = Math.clamp((bond.leverage or 0) - 1, 0, 100)
            summary = bond.name .. " let the feud cool for a week and reminded you how strange relief can feel."
        else
            apply_shadow_delta(game_state, "notoriety", 2)
            apply_shadow_delta(game_state, "standing", -1)
            bond.strain = Math.clamp((bond.strain or 0) + 3, 0, 100)
            bond.leverage = Math.clamp((bond.leverage or 0) + 2, 0, 100)
            summary = bond.name .. " set another hostile story moving through the ward without waiting for your consent."
        end
    elseif thread.kind == "need" then
        if supportive then
            apply_shadow_delta(game_state, "stress", 1)
            bond.dependency = Math.clamp((bond.dependency or 0) - 1, 0, 100)
            bond.obligation = Math.clamp((bond.obligation or 0) + 2, 0, 100)
            summary = bond.name .. " tried to help themselves and only partly succeeded."
        else
            apply_shadow_delta(game_state, "stress", 2)
            bond.dependency = Math.clamp((bond.dependency or 0) + 3, 0, 100)
            bond.strain = Math.clamp((bond.strain or 0) + 2, 0, 100)
            summary = bond.name .. " made a desperate decision that pushed their need back into your hands."
        end
    elseif thread.kind == "patronage" then
        if supportive then
            apply_shadow_delta(game_state, "standing", 1)
            bond.leverage = Math.clamp((bond.leverage or 0) - 2, 0, 100)
            bond.obligation = Math.clamp((bond.obligation or 0) + 1, 0, 100)
            summary = bond.name .. " opened a small door and made sure you knew who still held the hinge."
        else
            apply_shadow_delta(game_state, "stress", 2)
            apply_shadow_delta(game_state, "standing", -1)
            bond.leverage = Math.clamp((bond.leverage or 0) + 3, 0, 100)
            bond.strain = Math.clamp((bond.strain or 0) + 2, 0, 100)
            summary = bond.name .. " called a debt due in a way that left no room to ignore the hierarchy."
        end
    else
        if supportive then
            apply_shadow_delta(game_state, "craft", 1)
            bond.closeness = Math.clamp((bond.closeness or 0) + 1, 0, 100)
            summary = bond.name .. " brought you work, rumor, or practical help before you had to ask."
        else
            apply_shadow_delta(game_state, "stress", 1)
            bond.leverage = Math.clamp((bond.leverage or 0) + 1, 0, 100)
            bond.strain = Math.clamp((bond.strain or 0) + 2, 0, 100)
            summary = bond.name .. " complicated the year in the ordinary way: by arriving with need, timing, and appetite."
        end
    end

    thread.heat = Math.clamp((thread.heat or 0) + (supportive and -1 or 3), 0, 100)
    thread.autonomy = Math.clamp((thread.autonomy or 0) + 2, 0, 100)
    if not supportive and (thread.heat or 0) >= 60 then
        thread.stage = Math.clamp(math.max(thread.stage or 1, 3), 1, 4)
    end
    push_history(bond, summary)
    autonomy_record(state, bond, thread, summary, supportive and "supportive" or "hostile")
    return summary
end

function ShadowBonds.resolve_autonomy(game_state, quality)
    local state = ShadowBonds.ensure_state(game_state)
    ensure_threads(state)
    state.recent_moves = {}

    local ranked = {}
    for _, bond in ipairs(state.bonds or {}) do
        local thread = nudge_thread(get_thread(state, bond), bond, game_state and game_state.generation or 1)
        ranked[#ranked + 1] = {
            bond = bond,
            thread = thread,
            score = thread_pressure(thread, bond) + math.floor((thread and thread.autonomy or 0) * 0.8),
        }
    end
    table.sort(ranked, function(a, b)
        if a.score == b.score then
            return a.bond.name < b.bond.name
        end
        return a.score > b.score
    end)

    local stress = game_state and game_state.shadow_state and game_state.shadow_state.stress or 50
    local move_count = stress >= 70 and 3 or 2
    local lines = {}
    for index = 1, math.min(move_count, #ranked) do
        local item = ranked[index]
        if item.thread and ((item.thread.autonomy or 0) >= 30 or (item.thread.heat or 0) >= 48) then
            lines[#lines + 1] = resolve_autonomous_move(game_state, state, item.bond, item.thread, quality)
        end
    end
    return lines
end

return ShadowBonds
