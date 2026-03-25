local Math = require("dredwork_core.math")
local ShadowCareer = {}

local TITLES = {
    laborer = { "HAND", "FOREMAN'S RUNNER", "YARD BOSS", "GANG CHIEF", "MASTER OF STONE" },
    scribe = { "COPYIST", "CLERK", "RECORD-KEEPER", "ARCHIVIST", "MASTER OF ACCOUNTS" },
    soldier = { "BLADE FOR HIRE", "SERGEANT'S HAND", "CAPTAIN'S DOG", "RAID LEADER", "WAR-CAPTAIN" },
    courtier = { "ATTENDANT", "WHISPER-BEARER", "HOUSE FAVORITE", "CHAMBER VOICE", "COURT FIXER" },
    tinker = { "PATCHER", "MAKER", "WORKSHOP HAND", "DEVICE-SMITH", "MASTER TINKER" },
    performer = { "PLAYER", "ROOM FAVORITE", "SALON FIXTURE", "HOUSE ENTERTAINER", "VOICE OF THE SEASON" },
}

local function occupation_of(game_state)
    return game_state and game_state.shadow_setup and game_state.shadow_setup.occupation or "laborer"
end

local function label_of(game_state)
    return game_state and game_state.shadow_setup and (game_state.shadow_setup.calling_label or game_state.shadow_setup.occupation_label) or "LABOR-CALLED"
end

local function title_for(occupation, rank)
    if rank < 20 then
        return "UNFORMED"
    end
    local titles = TITLES[occupation] or TITLES.laborer
    if rank >= 82 then
        return titles[5]
    elseif rank >= 66 then
        return titles[4]
    elseif rank >= 50 then
        return titles[3]
    elseif rank >= 34 then
        return titles[2]
    end
    return titles[1]
end

function ShadowCareer.ensure_state(game_state)
    game_state.shadow_career = game_state.shadow_career or {}
    local state = game_state.shadow_career
    if state.initialized then
        return state
    end

    local occupation = occupation_of(game_state)
    local label = label_of(game_state)
    local rank = 12
    local income = 18
    local stability = 44

    if occupation == "scribe" then
        rank = 14
        income = 19
        stability = 47
    elseif occupation == "soldier" then
        rank = 15
        income = 18
        stability = 36
    elseif occupation == "courtier" then
        rank = 13
        income = 20
        stability = 35
    elseif occupation == "tinker" then
        rank = 12
        income = 18
        stability = 40
    elseif occupation == "performer" then
        rank = 12
        income = 17
        stability = 34
    elseif occupation == "laborer" then
        rank = 11
        income = 17
        stability = 45
    end

    state.occupation = occupation
    state.occupation_label = label
    state.rank = rank
    state.income = income
    state.stability = stability
    state.title = title_for(occupation, rank)
    state.initialized = true
    return state
end

function ShadowCareer.snapshot(game_state)
    local state = ShadowCareer.ensure_state(game_state)
    return {
        occupation = state.occupation_label,
        title = state.title,
        rank = state.rank,
        income = state.income,
        stability = state.stability,
    }
end

function ShadowCareer.apply_focus(game_state, focus_id, quality)
    local state = ShadowCareer.ensure_state(game_state)
    local before_title = state.title
    local delta_rank = 0
    local delta_income = 0
    local delta_stability = 0

    if tostring(focus_id or ""):find("^occupation_") then
        if quality == "triumph" then
            delta_rank = 7
            delta_income = 6
            delta_stability = 2
        elseif quality == "success" then
            delta_rank = 4
            delta_income = 3
            delta_stability = 1
        elseif quality == "failure" then
            delta_rank = 1
            delta_income = -1
            delta_stability = -2
        else
            delta_rank = -2
            delta_income = -4
            delta_stability = -5
        end
    elseif tostring(focus_id or ""):find("^bond_") then
        if quality == "triumph" or quality == "success" then
            delta_stability = 2
        else
            delta_stability = -1
        end
    elseif tostring(focus_id or ""):find("^burden_") then
        if quality == "triumph" or quality == "success" then
            delta_income = 1
            delta_stability = 1
        else
            delta_income = -2
            delta_stability = -3
        end
    elseif tostring(focus_id or ""):find("^private_") then
        if quality == "triumph" or quality == "success" then
            delta_rank = 1
        else
            delta_stability = -2
        end
    elseif tostring(focus_id or ""):find("^possession_") then
        if quality == "triumph" then
            delta_income = 3
            delta_stability = 3
        elseif quality == "success" then
            delta_income = 2
            delta_stability = 2
        elseif quality == "failure" then
            delta_income = 0
            delta_stability = -1
        else
            delta_income = -2
            delta_stability = -4
        end
    end

    state.rank = Math.clamp(state.rank + delta_rank, 0, 100)
    state.income = Math.clamp(state.income + delta_income, 0, 100)
    state.stability = Math.clamp(state.stability + delta_stability, 0, 100)
    state.title = title_for(state.occupation, state.rank)

    local lines = {
        "Career: " .. state.title .. " | Rank " .. state.rank .. " | Income " .. state.income .. " | Stability " .. state.stability .. ".",
    }
    if state.title ~= before_title then
        lines[#lines + 1] = "The work now names you differently: " .. state.title .. "."
    end
    return lines
end

return ShadowCareer
