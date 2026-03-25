local Math = require("dredwork_core.math")
local ShadowExpectations = {}


local TEMPERAMENT_EXPECTATIONS = {
    steadfast = { type = "loyalty", label = "Loyalty — they expect you to stand when it costs something" },
    hungry = { type = "advancement", label = "Advancement — they expect you to lift them as you climb" },
    gentle = { type = "protection", label = "Protection — they expect you to shield them from the worst" },
    volatile = { type = "attention", label = "Attention — they expect you to notice before they have to shout" },
    devout = { type = "piety", label = "Piety — they expect you to honor what they hold sacred" },
    calculating = { type = "usefulness", label = "Usefulness — they expect you to remain worth the cost" },
    curious = { type = "honesty", label = "Honesty — they expect you to stop hiding things that matter" },
    bitter = { type = "acknowledgment", label = "Acknowledgment — they expect you to name the old wound aloud" },
}

local VIOLATION_CHECKS = {
    loyalty = function(game_state, bond, year_context)
        local shadow = game_state.shadow_state or {}
        if (shadow.bonds or 50) <= 28 then return true, "You let ties rot while they held." end
        if bond.strain and bond.strain >= 60 and bond.closeness and bond.closeness < 30 then
            return true, "You abandoned the tie when it needed attention."
        end
        return false
    end,
    advancement = function(game_state, bond, year_context)
        local shadow = game_state.shadow_state or {}
        if (shadow.standing or 50) <= 30 and (shadow.craft or 50) <= 30 then
            return true, "You sank instead of climbing and dragged them with you."
        end
        return false
    end,
    protection = function(game_state, bond, year_context)
        local body = game_state.shadow_body or {}
        local wound_total = 0
        for _, entry in pairs(body.wounds or {}) do
            wound_total = wound_total + (entry.severity or 0)
        end
        if wound_total >= 40 or ((game_state.shadow_state or {}).health or 50) <= 22 then
            return true, "You could not protect yourself, let alone them."
        end
        return false
    end,
    attention = function(game_state, bond, year_context)
        if bond.closeness and bond.closeness <= 20 and bond.strain and bond.strain >= 40 then
            return true, "You looked away long enough that looking back became a wound."
        end
        return false
    end,
    piety = function(game_state, bond, year_context)
        local morality = game_state.morality
        if morality and (morality.score or 0) <= -30 then
            return true, "Your deeds blackened everything they prayed over."
        end
        return false
    end,
    usefulness = function(game_state, bond, year_context)
        local shadow = game_state.shadow_state or {}
        if (shadow.craft or 50) <= 24 then
            return true, "You became expensive to keep and cheap to replace."
        end
        return false
    end,
    honesty = function(game_state, bond, year_context)
        local shadow = game_state.shadow_state or {}
        if (shadow.notoriety or 0) >= 64 and bond.visibility and bond.visibility >= 44 then
            return true, "Your reputation said what you refused to."
        end
        return false
    end,
    acknowledgment = function(game_state, bond, year_context)
        if bond.strain and bond.strain >= 50 and bond.intimacy and bond.intimacy <= 20 then
            return true, "You pretended the wound between you was nothing."
        end
        return false
    end,
}

function ShadowExpectations.generate(bond)
    if not bond then return nil end
    local temperament = tostring(bond.temperament or ""):lower()
    local template = TEMPERAMENT_EXPECTATIONS[temperament]
    if not template then
        template = TEMPERAMENT_EXPECTATIONS.steadfast
    end
    return {
        type = template.type,
        label = template.label,
        violated = false,
        violation_count = 0,
        grievance = 0,
        revealed = false,
    }
end

function ShadowExpectations.check_violations(game_state, year_context)
    if not game_state or not game_state.shadow_bonds then return {} end
    local state = game_state.shadow_bonds
    local lines = {}
    for _, bond in ipairs(state.bonds or {}) do
        local exp = bond.expectation
        if exp then
            local checker = VIOLATION_CHECKS[exp.type]
            if checker then
                local violated, reason = checker(game_state, bond, year_context)
                if violated then
                    exp.violated = true
                    exp.violation_count = (exp.violation_count or 0) + 1
                    exp.grievance = Math.clamp((exp.grievance or 0) + 8 + math.min(exp.violation_count * 3, 15), 0, 100)
                    if not exp.revealed and exp.grievance >= 30 then
                        exp.revealed = true
                        lines[#lines + 1] = bond.name .. " names the broken contract: " .. exp.label .. "."
                    end
                else
                    exp.violated = false
                end
            end
        end
    end
    return lines
end

function ShadowExpectations.apply(game_state)
    if not game_state or not game_state.shadow_bonds then return end
    local state = game_state.shadow_bonds
    for _, bond in ipairs(state.bonds or {}) do
        local exp = bond.expectation
        if exp and exp.grievance and exp.grievance > 0 then
            local strain_add = math.floor(exp.grievance / 30)
            if strain_add > 0 then
                bond.strain = Math.clamp((bond.strain or 0) + strain_add, 0, 100)
            end
        end
    end
end

function ShadowExpectations.grievance_count(game_state, threshold)
    threshold = threshold or 60
    if not game_state or not game_state.shadow_bonds then return 0 end
    local count = 0
    for _, bond in ipairs(game_state.shadow_bonds.bonds or {}) do
        if bond.expectation and (bond.expectation.grievance or 0) >= threshold then
            count = count + 1
        end
    end
    return count
end

function ShadowExpectations.snapshot(bond)
    if not bond or not bond.expectation then
        return nil
    end
    local exp = bond.expectation
    return {
        type = exp.type,
        label = exp.label,
        grievance = exp.grievance or 0,
        violated = exp.violated or false,
        violation_count = exp.violation_count or 0,
        revealed = exp.revealed or false,
    }
end

return ShadowExpectations
