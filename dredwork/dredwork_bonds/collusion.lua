local Math = require("dredwork_core.math")
local ShadowCollusion = {}


local TENSION_PAIRS = {
    { a = "rival", b = "power", id = "leverage_conspiracy", title = "Leverage Conspiracy", description = "Two bonds have found each other and agreed you are the commodity." },
    { a = "intimate", b = "dependent", id = "emotional_blackmail", title = "Emotional Blackmail", description = "The person you need and the person who needs you have begun collaborating." },
    { a = "rival", b = "intimate", id = "vulnerability_exploit", title = "Vulnerability Exploit", description = "Your enemy knows what your closest tie knows about you." },
    { a = "power", b = "kin", id = "claim_weaponization", title = "Claim Weaponization", description = "Your patron and your kin have begun speaking about you in terms that feel legal." },
    { a = "dependent", b = "rival", id = "hostage_dynamic", title = "Hostage Dynamic", description = "Your dependent has become your enemy's leverage." },
    { a = "kin", b = "intimate", id = "forced_choice", title = "Forced Choice", description = "Blood and tenderness have agreed to demand the same impossible thing." },
}

local function meets_threshold(bond_a, bond_b, thread_a, thread_b)
    local heat_a = thread_a and thread_a.heat or 0
    local heat_b = thread_b and thread_b.heat or 0
    local autonomy_a = thread_a and thread_a.autonomy or 0
    local autonomy_b = thread_b and thread_b.autonomy or 0

    if heat_a >= 48 and heat_b >= 48 then return true end
    if (autonomy_a + autonomy_b) >= 80 then return true end
    return false
end

function ShadowCollusion.generate(game_state, generation)
    if not game_state or not game_state.shadow_bonds then return {} end
    local state = game_state.shadow_bonds
    local threads = state.threads or {}
    generation = generation or (game_state.generation or 1)

    state.collusion_cooldowns = state.collusion_cooldowns or {}

    local bonds_by_category = {}
    for _, bond in ipairs(state.bonds or {}) do
        local cat = bond.category or "work"
        bonds_by_category[cat] = bonds_by_category[cat] or {}
        bonds_by_category[cat][#bonds_by_category[cat] + 1] = bond
    end

    local events = {}
    for _, pair_def in ipairs(TENSION_PAIRS) do
        local list_a = bonds_by_category[pair_def.a] or {}
        local list_b = bonds_by_category[pair_def.b] or {}

        for _, bond_a in ipairs(list_a) do
            for _, bond_b in ipairs(list_b) do
                if bond_a.id ~= bond_b.id then
                    local cooldown_key = bond_a.id .. "+" .. bond_b.id
                    local last = state.collusion_cooldowns[cooldown_key] or 0

                    if (generation - last) >= 3 then
                        local thread_a = threads[bond_a.id]
                        local thread_b = threads[bond_b.id]
                        if meets_threshold(bond_a, bond_b, thread_a, thread_b) then
                            state.collusion_cooldowns[cooldown_key] = generation

                            local event = {
                                id = "collusion:" .. pair_def.id .. ":" .. bond_a.id .. "+" .. bond_b.id,
                                title = pair_def.title,
                                description = pair_def.description .. " " .. bond_a.name .. " and " .. bond_b.name .. " are moving together.",
                                source = "collusion",
                                bond_ids = { bond_a.id, bond_b.id },
                                bond_names = { bond_a.name, bond_b.name },
                                options = {
                                    {
                                        id = "collusion_address",
                                        label = "Address them together",
                                        description = "Confront the pair before their arrangement hardens.",
                                        success = {
                                            narrative = "You broke the arrangement before it finished forming. Both bonds shifted.",
                                            effects = {
                                                shadow = { stress = 3, standing = 1 },
                                                bond_effects = {
                                                    { id = bond_a.id, strain = -4, closeness = 2, visibility = 4 },
                                                    { id = bond_b.id, strain = -4, closeness = 2, visibility = 4 },
                                                },
                                            },
                                        },
                                        failure = {
                                            narrative = "Confrontation only proved they were right to conspire.",
                                            effects = {
                                                shadow = { stress = 6, bonds = -2 },
                                                bond_effects = {
                                                    { id = bond_a.id, strain = 6, leverage = 4 },
                                                    { id = bond_b.id, strain = 6, leverage = 4 },
                                                },
                                            },
                                        },
                                    },
                                    {
                                        id = "collusion_exploit",
                                        label = "Exploit the split between them",
                                        description = "Turn one against the other.",
                                        success = {
                                            narrative = "You drove a wedge. One bond cooled, the other sharpened.",
                                            effects = {
                                                shadow = { stress = 2, notoriety = 2 },
                                                bond_effects = {
                                                    { id = bond_a.id, closeness = 4, strain = -4 },
                                                    { id = bond_b.id, strain = 8, closeness = -4 },
                                                },
                                            },
                                        },
                                        failure = {
                                            narrative = "They saw through the play. Now they trust each other more than you.",
                                            effects = {
                                                shadow = { stress = 5, bonds = -2, notoriety = 3 },
                                                bond_effects = {
                                                    { id = bond_a.id, strain = 4, leverage = 6 },
                                                    { id = bond_b.id, strain = 4, leverage = 6 },
                                                },
                                            },
                                        },
                                    },
                                },
                            }
                            events[#events + 1] = event
                            if #events >= 1 then return events end
                        end
                    end
                end
            end
        end
        if #events >= 1 then break end
    end

    return events
end

return ShadowCollusion
