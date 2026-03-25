local Math = require("dredwork_core.math")
local ShadowSecrets = {}


local SECRET_ACTIONS = {
    leverage_play = { label = "Leverage Play", hostile = true, description_template = "%s traded your weakness to a stranger." },
    quiet_gift = { label = "Quiet Gift", hostile = false, description_template = "%s left something useful where you would find it." },
    sabotage = { label = "Sabotage", hostile = true, description_template = "%s undid something you were building." },
    confession = { label = "Confession", hostile = false, description_template = "%s told you something they had been carrying for years." },
    alliance_bid = { label = "Alliance Bid", hostile = false, description_template = "%s offered another bond an arrangement that includes you." },
    withdrawal = { label = "Withdrawal", hostile = true, description_template = "%s pulled back from the tie without explanation." },
}

local TEMPERAMENT_MATRIX = {
    steadfast = { default = "quiet_gift", hostile = "withdrawal" },
    hungry = { default = "leverage_play", hostile = "leverage_play" },
    gentle = { default = "quiet_gift", hostile = "confession" },
    volatile = { default = "sabotage", hostile = "sabotage" },
    devout = { default = "confession", hostile = "withdrawal" },
    calculating = { default = "alliance_bid", hostile = "leverage_play" },
    curious = { default = "confession", hostile = "leverage_play" },
    bitter = { default = "sabotage", hostile = "sabotage" },
}

local THREAD_OVERRIDES = {
    feud = "leverage_play",
    tenderness = "confession",
    need = "quiet_gift",
    patronage = "alliance_bid",
    legacy = "withdrawal",
}

local function pick_secret(bond, thread, game_state)
    local temperament = tostring(bond.temperament or ""):lower()
    local matrix = TEMPERAMENT_MATRIX[temperament] or TEMPERAMENT_MATRIX.steadfast
    local exp = bond.expectation
    local grieved = exp and (exp.grievance or 0) >= 40

    local action_id
    if grieved then
        action_id = matrix.hostile
    else
        local kind = thread and thread.kind or "entanglement"
        action_id = THREAD_OVERRIDES[kind] or matrix.default
    end

    return action_id
end

function ShadowSecrets.generate(game_state, focus_id)
    if not game_state or not game_state.shadow_bonds then return nil end
    local state = game_state.shadow_bonds
    local threads = state.threads or {}

    local candidates = {}
    for _, bond in ipairs(state.bonds or {}) do
        local thread = threads[bond.id]
        if thread and (thread.autonomy or 0) >= 44 then
            local action_id = pick_secret(bond, thread, game_state)
            local action = SECRET_ACTIONS[action_id]
            if action then
                local pressure = (thread.heat or 0) + (thread.autonomy or 0)
                    + ((bond.expectation and bond.expectation.grievance or 0) * 0.5)
                candidates[#candidates + 1] = {
                    bond = bond,
                    thread = thread,
                    action_id = action_id,
                    action = action,
                    pressure = pressure,
                }
            end
        end
    end

    if #candidates == 0 then return nil end

    table.sort(candidates, function(a, b) return a.pressure > b.pressure end)
    local chosen = candidates[1]
    local bond = chosen.bond
    local action = chosen.action
    local description = string.format(action.description_template, bond.name)

    local event = {
        id = "secret:" .. chosen.action_id .. ":" .. bond.id,
        title = "A Move in the Dark",
        description = description,
        source = "secrets",
        bond_id = bond.id,
        bond_name = bond.name,
        secret_type = chosen.action_id,
        hostile = action.hostile,
        options = {
            {
                id = "secret_accept",
                label = "Accept what happened",
                description = "Let the consequence stand.",
                success = {
                    narrative = "You absorbed the blow. The bond shifted, but held.",
                    effects = {
                        shadow = { stress = 2 },
                        bond_effect = {
                            id = bond.id,
                            closeness = action.hostile and -4 or 3,
                            strain = action.hostile and 6 or -2,
                        },
                    },
                },
                failure = {
                    narrative = "Acceptance felt like submission. The tie moved against you.",
                    effects = {
                        shadow = { stress = 4, bonds = -1 },
                        bond_effect = {
                            id = bond.id,
                            strain = action.hostile and 8 or 2,
                            closeness = -2,
                        },
                    },
                },
            },
            {
                id = "secret_confront",
                label = "Confront them",
                description = "Name what they did.",
                success = {
                    narrative = "The naming cleared something. The air between you sharpened but also steadied.",
                    effects = {
                        shadow = { stress = 3, bonds = 1 },
                        bond_effect = {
                            id = bond.id,
                            strain = action.hostile and -4 or 4,
                            closeness = action.hostile and 2 or -3,
                            visibility = 4,
                        },
                    },
                },
                failure = {
                    narrative = "Confrontation made the wound public. Now others are watching.",
                    effects = {
                        shadow = { stress = 5, notoriety = 2 },
                        bond_effect = {
                            id = bond.id,
                            strain = 6,
                            visibility = 6,
                        },
                    },
                },
            },
        },
    }

    return event
end

return ShadowSecrets
