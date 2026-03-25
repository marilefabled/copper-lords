local Math = require("dredwork_core.math")
local ShadowWitnesses = {}


function ShadowWitnesses.ensure_ledger(game_state)
    if not game_state or not game_state.shadow_bonds then return {} end
    game_state.shadow_bonds.witness_ledger = game_state.shadow_bonds.witness_ledger or {}
    return game_state.shadow_bonds.witness_ledger
end

function ShadowWitnesses.select_witnesses(game_state, act_label, max_count)
    max_count = max_count or 3
    if not game_state or not game_state.shadow_bonds then return {} end
    local state = game_state.shadow_bonds
    local candidates = {}
    for _, bond in ipairs(state.bonds or {}) do
        if (bond.visibility or 0) >= 44 then
            candidates[#candidates + 1] = {
                bond = bond,
                score = (bond.visibility or 0) + math.floor((bond.closeness or 0) * 0.3) + math.floor((bond.strain or 0) * 0.2),
            }
        end
    end
    table.sort(candidates, function(a, b) return a.score > b.score end)
    local selected = {}
    for i = 1, math.min(max_count, #candidates) do
        selected[#selected + 1] = candidates[i].bond
    end
    return selected
end

function ShadowWitnesses.record(game_state, act_label, tone, generation)
    if not game_state or not game_state.shadow_bonds then return {} end
    local ledger = ShadowWitnesses.ensure_ledger(game_state)
    local witnesses = ShadowWitnesses.select_witnesses(game_state, act_label)
    local weight = tone == "approving" and 1 or -1
    local lines = {}
    for _, bond in ipairs(witnesses) do
        ledger[bond.id] = ledger[bond.id] or {}
        local entries = ledger[bond.id]
        entries[#entries + 1] = {
            gen = generation or (game_state.generation or 1),
            act = act_label,
            tone = tone,
            weight = weight,
        }
        while #entries > 12 do
            table.remove(entries, 1)
        end
    end
    return witnesses
end

function ShadowWitnesses.reputation_score(game_state, bond_id)
    if not game_state or not game_state.shadow_bonds then return 0 end
    local ledger = game_state.shadow_bonds.witness_ledger or {}
    local entries = ledger[bond_id] or {}
    local total = 0
    for _, entry in ipairs(entries) do
        total = total + (entry.weight or 0)
    end
    return total
end

function ShadowWitnesses.chronicle_fragments(game_state)
    if not game_state or not game_state.shadow_bonds then return {} end
    local ledger = game_state.shadow_bonds.witness_ledger or {}
    local state = game_state.shadow_bonds
    local fragments = {}
    for _, bond in ipairs(state.bonds or {}) do
        local entries = ledger[bond.id]
        if entries and #entries >= 2 then
            local total = 0
            local harsh = 0
            for _, entry in ipairs(entries) do
                total = total + 1
                if entry.weight < 0 then harsh = harsh + 1 end
            end
            if harsh > total / 2 then
                fragments[#fragments + 1] = bond.name .. " watched " .. tostring(total) .. " choices and judged " .. tostring(harsh) .. " harshly."
            elseif harsh == 0 and total >= 3 then
                fragments[#fragments + 1] = bond.name .. " witnessed " .. tostring(total) .. " decisions and found none wanting."
            else
                fragments[#fragments + 1] = bond.name .. " watched " .. tostring(total) .. " choices with mixed opinion."
            end
        end
    end
    return fragments
end

return ShadowWitnesses
