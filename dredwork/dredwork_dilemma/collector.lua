-- dredwork_dilemma/collector.lua
-- Collects pressures from any registered source.
-- Sources are functions that take game_state and return pressure specs.
-- The collector is the bridge between your game's systems and the dilemma engine.

local Pressure = require("dredwork_dilemma.pressure")

local Collector = {}

--[[
    A collector holds registered source functions.
    Each source: function(game_state) -> { pressure_spec, ... }
]]

function Collector.new()
    return {
        sources = {},
    }
end

function Collector.register(collector, name, source_fn)
    if not collector or not name or not source_fn then return end
    collector.sources[name] = source_fn
end

function Collector.gather(collector, game_state)
    if not collector or not game_state then return {} end
    local pressures = {}
    for name, source_fn in pairs(collector.sources) do
        local ok, results = pcall(source_fn, game_state)
        if ok and results then
            for _, spec in ipairs(results) do
                local p = Pressure.create(spec)
                if p then
                    pressures[#pressures + 1] = p
                end
            end
        end
    end
    -- Sort by urgency descending
    table.sort(pressures, function(a, b) return a.urgency > b.urgency end)
    return pressures
end

-- ============================================================
-- Built-in source functions for dredwork modules.
-- Use these as templates or register them directly.
-- ============================================================

--[[
    Bond grievances → pressures.
    Requires game_state.shadow_bonds with expectations.
]]
function Collector.source_bond_grievances(game_state)
    if not game_state or not game_state.shadow_bonds then return {} end
    local pressures = {}
    for _, bond in ipairs(game_state.shadow_bonds.bonds or {}) do
        local exp = bond.expectation
        if exp and (exp.grievance or 0) >= 20 then
            local urgency = math.min(95, exp.grievance + (exp.violation_count or 0) * 5)
            pressures[#pressures + 1] = {
                id = "bond:grievance:" .. bond.id,
                source = "bonds",
                category = "relationship",
                urgency = urgency,
                label = bond.name .. "'s Broken Contract",
                summary = bond.name .. " carries a grievance of " .. tostring(exp.grievance) .. ". The expectation was " .. (exp.type or "unknown") .. ".",
                subject = bond.name,
                tags = { "grievance", "bond", exp.type or "unknown" },
                address = {
                    narrative = "You named the wound between you and " .. bond.name .. ". It cost a year, but the grievance loosened.",
                    effects = {
                        shadow = { stress = 3, bonds = 2 },
                        bond_effect = { id = bond.id, strain = -8, closeness = 4 },
                        expectation_effect = { id = bond.id, grievance = -20 },
                    },
                },
                neglect = {
                    narrative = bond.name .. "'s silence grew heavier. The contract stayed broken.",
                    effects = {
                        bond_effect = { id = bond.id, strain = 6, closeness = -3 },
                        expectation_effect = { id = bond.id, grievance = 10 },
                    },
                },
            }
        end
    end
    return pressures
end

--[[
    Hot rumors → pressures.
    Requires game_state.rumor_network.
]]
function Collector.source_rumors(game_state)
    if not game_state or not game_state.rumor_network then return {} end
    local pressures = {}
    for _, rumor in pairs(game_state.rumor_network.rumors or {}) do
        if not rumor.dead and not rumor.calcified and rumor.heat >= 40 and rumor.reach >= 2 then
            local urgency = math.min(95, rumor.heat + rumor.severity * 5)
            local shameful = false
            for _, tag in ipairs(rumor.tags or {}) do
                if tag == "shame" or tag == "betrayal" or tag == "cruelty" then shameful = true end
            end
            pressures[#pressures + 1] = {
                id = "rumor:" .. rumor.id,
                source = "rumor",
                category = "reputation",
                urgency = urgency,
                label = "A Rumor About " .. rumor.subject,
                summary = "\"" .. rumor.current_text .. "\" Heat " .. tostring(rumor.heat) .. ", reach " .. tostring(rumor.reach) .. ".",
                subject = rumor.subject,
                tags = { "rumor", shameful and "shameful" or "neutral" },
                address = {
                    narrative = "You confronted the story directly. It cost standing but changed the shape of what people say.",
                    effects = {
                        shadow = { stress = 2, notoriety = shameful and -3 or 2 },
                        rumor_effect = { id = rumor.id, action = (rumor.truth_score or 0) >= 60 and "confirm" or "deny" },
                    },
                },
                neglect = {
                    narrative = "The story kept traveling. Another mouth, another version.",
                    effects = {
                        rumor_effect = { id = rumor.id, heat_boost = 10 },
                    },
                },
            }
        end
    end
    return pressures
end

--[[
    Body decay → pressures.
    Requires game_state.shadow_body.
]]
function Collector.source_body(game_state)
    if not game_state or not game_state.shadow_body then return {} end
    local body = game_state.shadow_body
    local pressures = {}

    local wound_load = 0
    for _, entry in pairs(body.wounds or {}) do
        wound_load = wound_load + (entry.severity or 0)
    end
    local illness_load = 0
    for _, entry in pairs(body.illnesses or {}) do
        illness_load = illness_load + (entry.severity or 0)
    end
    local compulsion_load = 0
    for _, entry in pairs(body.compulsions or {}) do
        compulsion_load = compulsion_load + (entry.severity or 0)
    end

    if wound_load >= 30 then
        pressures[#pressures + 1] = {
            id = "body:wounds",
            source = "body",
            category = "survival",
            urgency = math.min(95, 40 + wound_load),
            label = "The Body Is Failing",
            summary = "Wound load at " .. tostring(wound_load) .. ". The damage is becoming structural.",
            subject = game_state.heir_name or "the protagonist",
            tags = { "body", "wounds" },
            address = {
                narrative = "You gave the year to the body. Rest, treatment, concession.",
                effects = {
                    shadow = { health = 4, stress = -2, craft = -2 },
                    body = { ease_wounds = 15 },
                },
            },
            neglect = {
                narrative = "The body kept its complaints. They will be louder next year.",
                effects = {
                    body = { wounds = { { id = "neglect_damage", label = "Neglected Damage", severity = 8 } } },
                },
            },
        }
    end

    if compulsion_load >= 30 then
        pressures[#pressures + 1] = {
            id = "body:compulsion",
            source = "body",
            category = "survival",
            urgency = math.min(95, 35 + compulsion_load),
            label = "The Habit Demands a Year",
            summary = "Compulsion load at " .. tostring(compulsion_load) .. ". Appetite is winning the argument.",
            subject = game_state.heir_name or "the protagonist",
            tags = { "body", "compulsion" },
            address = {
                narrative = "You starved the habit for a year. It did not go quietly.",
                effects = {
                    shadow = { stress = 4, bonds = -1 },
                    body = { ease_compulsions = 12 },
                },
            },
            neglect = {
                narrative = "The habit continued its education. You are a slower student than it.",
                effects = {
                    body = { compulsions = { { id = "habit_growth", label = "Habit Growth", severity = 8 } } },
                    shadow = { stress = 3 },
                },
            },
        }
    end

    return pressures
end

--[[
    Claim escalation → pressures.
    Requires game_state.shadow_claim.
]]
function Collector.source_claim(game_state)
    if not game_state or not game_state.shadow_claim then return {} end
    local claim = game_state.shadow_claim
    if not claim.initialized then return {} end
    local pressures = {}

    if (claim.exposure or 0) >= 50 or (claim.usurper_risk or 0) >= 50 then
        local urgency = math.min(95, math.max(claim.exposure or 0, claim.usurper_risk or 0) + 10)
        pressures[#pressures + 1] = {
            id = "claim:exposure",
            source = "claim",
            category = "identity",
            urgency = urgency,
            label = "The Bloodline Question",
            summary = "Exposure " .. tostring(claim.exposure or 0) .. ", usurper risk " .. tostring(claim.usurper_risk or 0) .. ". The denied branch is becoming dangerous to carry.",
            subject = game_state.heir_name or "the protagonist",
            tags = { "claim", "identity", "danger" },
            address = {
                narrative = "You spent the year managing the claim — burying some threads, feeding others.",
                effects = {
                    shadow = { stress = 3, notoriety = -2 },
                    claim = { exposure = -8, usurper_risk = -6 },
                },
            },
            neglect = {
                narrative = "The claim kept growing in mouths you can't reach.",
                effects = {
                    claim = { exposure = 6, usurper_risk = 4 },
                },
            },
        }
    end

    return pressures
end

return Collector
