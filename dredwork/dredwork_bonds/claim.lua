local Math = require("dredwork_core.math")
local ShadowClaim = {}


local function setup_of(game_state)
    return game_state and game_state.shadow_setup or nil
end

local function label_for(kind, value)
    local v = tonumber(value) or 0
    if kind == "legitimacy" then
        if v >= 72 then return "Credible" end
        if v >= 56 then return "Whispered" end
        if v >= 38 then return "Tenuous" end
        return "Denied"
    elseif kind == "proof" then
        if v >= 72 then return "Documented" end
        if v >= 56 then return "Substantiated" end
        if v >= 38 then return "Fragmentary" end
        return "Lost"
    elseif kind == "grievance" then
        if v >= 72 then return "Inherited Fire" end
        if v >= 56 then return "Hot" end
        if v >= 38 then return "Persistent" end
        return "Muted"
    elseif kind == "ambition" then
        if v >= 72 then return "Hungry" end
        if v >= 56 then return "Rising" end
        if v >= 38 then return "Measuring" end
        return "Cautious"
    elseif kind == "exposure" then
        if v >= 72 then return "Known" end
        if v >= 56 then return "Watched" end
        if v >= 38 then return "Rumored" end
        return "Hidden"
    elseif kind == "usurper_risk" then
        if v >= 72 then return "Usurper" end
        if v >= 56 then return "Predatory" end
        if v >= 38 then return "Dangerous" end
        return "Contained"
    end
    return tostring(v)
end

local function status_label(state)
    local legitimacy = state.legitimacy or 0
    local exposure = state.exposure or 0
    local proof = state.proof or 0
    if legitimacy >= 66 and proof >= 58 and exposure >= 52 then
        return "ASSERTED CLAIM"
    elseif legitimacy >= 46 and proof >= 38 then
        return "LIVING WHISPER"
    end
    return "BROKEN BRANCH"
end

function ShadowClaim.ensure_state(game_state)
    game_state.shadow_claim = game_state.shadow_claim or {}
    local state = game_state.shadow_claim
    if state.initialized then
        return state
    end

    local setup = setup_of(game_state) or {}
    local house_name = setup.claim_house_name or "Unnamed House"
    local burden = tostring(setup.burden or "")
    local faith = tostring(setup.faith or "")
    local occupation = tostring(setup.occupation or "")
    local education = tostring(setup.education or "")

    state.house_name = house_name
    state.legitimacy = 34
    state.proof = 24
    state.grievance = 58
    state.ambition = 44
    state.exposure = 16
    state.usurper_risk = 18
    state.path = "blood"

    if burden == "claim" then
        state.legitimacy = state.legitimacy + 14
        state.proof = state.proof + 8
        state.grievance = state.grievance + 12
        state.ambition = state.ambition + 10
        state.exposure = state.exposure + 8
    elseif burden == "wanted" then
        state.exposure = state.exposure + 16
        state.usurper_risk = state.usurper_risk + 8
    elseif burden == "oath" then
        state.proof = state.proof + 6
        state.legitimacy = state.legitimacy + 4
    elseif burden == "debt" then
        state.grievance = state.grievance + 8
    end

    if faith == "ancestor" then
        state.proof = state.proof + 8
        state.grievance = state.grievance + 6
    elseif faith == "cult" then
        state.exposure = state.exposure + 6
        state.usurper_risk = state.usurper_risk + 6
    elseif faith == "skeptic" then
        state.proof = state.proof + 4
    end

    if occupation == "courtier" then
        state.legitimacy = state.legitimacy + 6
        state.exposure = state.exposure + 10
        state.ambition = state.ambition + 8
    elseif occupation == "soldier" then
        state.exposure = state.exposure + 6
        state.usurper_risk = state.usurper_risk + 10
        state.ambition = state.ambition + 6
    elseif occupation == "scribe" then
        state.proof = state.proof + 12
    end

    if education == "court" then
        state.legitimacy = state.legitimacy + 6
        state.proof = state.proof + 6
    elseif education == "self" then
        state.proof = state.proof + 4
        state.grievance = state.grievance + 4
    end

    for key, value in pairs(state) do
        if key ~= "house_name" and key ~= "path" and key ~= "initialized" then
            state[key] = Math.clamp(value, 0, 100)
        end
    end

    state.initialized = true
    return state
end

function ShadowClaim.apply(game_state, payload)
    if not game_state or not payload then
        return ShadowClaim.snapshot(game_state)
    end
    local state = ShadowClaim.ensure_state(game_state)
    for key, delta in pairs(payload) do
        if state[key] ~= nil and type(delta) == "number" then
            state[key] = Math.clamp((state[key] or 0) + delta, 0, 100)
        elseif key == "path" and delta then
            state.path = tostring(delta)
        end
    end
    return ShadowClaim.snapshot(game_state)
end

function ShadowClaim.tick_year(game_state)
    if not game_state then
        return nil
    end
    local state = ShadowClaim.ensure_state(game_state)
    local shadow = game_state.shadow_state or {}
    if (shadow.notoriety or 0) >= 58 then
        state.exposure = Math.clamp(state.exposure + 2, 0, 100)
    end
    if (shadow.standing or 0) >= 56 then
        state.legitimacy = Math.clamp(state.legitimacy + 1, 0, 100)
    end
    if (shadow.stress or 0) >= 66 then
        state.usurper_risk = Math.clamp(state.usurper_risk + 2, 0, 100)
    end
    return ShadowClaim.snapshot(game_state)
end

function ShadowClaim.snapshot(game_state)
    if not game_state then
        return nil
    end
    local state = ShadowClaim.ensure_state(game_state)
    return {
        house_name = state.house_name,
        status = status_label(state),
        path = state.path or "blood",
        legitimacy = state.legitimacy,
        proof = state.proof,
        grievance = state.grievance,
        ambition = state.ambition,
        exposure = state.exposure,
        usurper_risk = state.usurper_risk,
        legitimacy_label = label_for("legitimacy", state.legitimacy),
        proof_label = label_for("proof", state.proof),
        grievance_label = label_for("grievance", state.grievance),
        ambition_label = label_for("ambition", state.ambition),
        exposure_label = label_for("exposure", state.exposure),
        usurper_label = label_for("usurper_risk", state.usurper_risk),
        reclaim_line = "Shadow of " .. state.house_name .. " | " .. status_label(state),
        state_line = "Legitimacy " .. label_for("legitimacy", state.legitimacy)
            .. " | Proof " .. label_for("proof", state.proof)
            .. " | Exposure " .. label_for("exposure", state.exposure),
        danger_line = "Grievance " .. label_for("grievance", state.grievance)
            .. " | Ambition " .. label_for("ambition", state.ambition)
            .. " | Usurper Risk " .. label_for("usurper_risk", state.usurper_risk),
    }
end

return ShadowClaim
