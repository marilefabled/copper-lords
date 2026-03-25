local Math = require("dredwork_core.math")
-- dredwork_dilemma/dilemma.lua
-- The dilemma engine. Takes collected pressures, pairs them into
-- forced trade-offs, and produces a single hard question per tick.
--
-- Philosophy: the player addresses ONE pressure. Everything else escalates.
-- The choice is never "good vs bad" — it's "which fire do you fight."

local Pressure = require("dredwork_dilemma.pressure")

local Dilemma = {}

-- Categories that create the most painful trade-offs when paired
local TENSION_PAIRS = {
    { "relationship", "survival" },
    { "reputation", "relationship" },
    { "survival", "identity" },
    { "reputation", "survival" },
    { "identity", "relationship" },
    { "conflict", "reputation" },
    { "conflict", "survival" },
}

local function categories_conflict(a, b)
    for _, pair in ipairs(TENSION_PAIRS) do
        if (a == pair[1] and b == pair[2]) or (a == pair[2] and b == pair[1]) then
            return true
        end
    end
    return false
end

local function tension_score(pressure_a, pressure_b)
    local score = 0
    -- Cross-category pairs are more interesting
    if categories_conflict(pressure_a.category, pressure_b.category) then
        score = score + 30
    end
    -- Different sources = harder trade-off
    if pressure_a.source ~= pressure_b.source then
        score = score + 20
    end
    -- Both urgent = maximum pain
    score = score + math.floor((pressure_a.urgency + pressure_b.urgency) * 0.3)
    -- Different subjects = split attention
    if pressure_a.subject ~= pressure_b.subject then
        score = score + 10
    end
    return score
end

--[[
    Generate a dilemma from a list of pressures.
    Returns nil if there aren't enough pressures to create a meaningful choice.

    Dilemma record:
    {
        id           = "dilemma:<gen>"
        generation   = when this was generated
        pressures    = { pressure_a, pressure_b } (the two competing demands)
        tension      = score representing how painful this trade-off is
        options      = {
            {
                id       = "address_a"
                label    = "Address: <pressure_a.label>"
                summary  = what happens if you pick this
                address  = pressure_a (the one you fix)
                neglect  = pressure_b (the one that escalates)
            },
            {
                id       = "address_b"
                label    = "Address: <pressure_b.label>"
                summary  = what happens if you pick this
                address  = pressure_b
                neglect  = pressure_a
            },
            -- Optional third option: split attention (weaker on both)
        }
        chosen       = nil (set when the player decides)
    }
]]
function Dilemma.generate(pressures, generation)
    if not pressures or #pressures < 2 then return nil end
    generation = generation or 1

    -- Find the highest-tension pair
    local best_a, best_b, best_score = nil, nil, -1
    local limit = math.min(6, #pressures) -- only consider top 6 by urgency (already sorted)
    for i = 1, limit do
        for j = i + 1, limit do
            local score = tension_score(pressures[i], pressures[j])
            if score > best_score then
                best_a = pressures[i]
                best_b = pressures[j]
                best_score = score
            end
        end
    end

    if not best_a or not best_b then return nil end

    -- Build the dilemma
    local options = {
        {
            id = "address_a",
            label = best_a.label,
            summary = best_a.address.narrative,
            detail = "Neglected: " .. best_b.label .. ". " .. best_b.neglect.narrative,
            address = best_a,
            neglect = best_b,
        },
        {
            id = "address_b",
            label = best_b.label,
            summary = best_b.address.narrative,
            detail = "Neglected: " .. best_a.label .. ". " .. best_a.neglect.narrative,
            address = best_b,
            neglect = best_a,
        },
    }

    -- Third option: split attention — address both poorly
    if best_score >= 50 then
        options[#options + 1] = {
            id = "split",
            label = "Split Your Attention",
            summary = "Half-measures on both. Neither is solved. Neither explodes this year.",
            detail = "Both pressures persist at reduced intensity.",
            address = nil,
            neglect = nil,
            split = true,
        }
    end

    return {
        id = "dilemma:" .. tostring(generation),
        generation = generation,
        pressures = { best_a, best_b },
        tension = best_score,
        options = options,
        chosen = nil,
        -- All pressures that exist but weren't picked for the dilemma
        -- These escalate silently in the background
        background_pressures = (function()
            local bg = {}
            for _, p in ipairs(pressures) do
                if p.id ~= best_a.id and p.id ~= best_b.id then
                    bg[#bg + 1] = p
                end
            end
            return bg
        end)(),
    }
end

--[[
    Resolve a dilemma choice. Returns the effects to apply.
    option_index: 1, 2, or 3 (split)

    Returns:
    {
        address_effects = { ... } or nil,
        neglect_effects = { ... } or nil,
        background_effects = { ... }, -- all other pressures escalate
        narrative_lines = { ... },
    }
]]
function Dilemma.resolve(dilemma, option_index)
    if not dilemma or not dilemma.options then return nil end
    local option = dilemma.options[option_index]
    if not option then return nil end

    dilemma.chosen = option.id
    local result = {
        address_effects = nil,
        neglect_effects = nil,
        background_effects = {},
        narrative_lines = {},
    }

    if option.split then
        -- Split: half-strength address on both, no full neglect
        result.narrative_lines[#result.narrative_lines + 1] = "You divided the year between two fires. Neither was extinguished."
        -- Mild versions of both address effects
        for _, pressure in ipairs(dilemma.pressures) do
            result.narrative_lines[#result.narrative_lines + 1] = pressure.label .. " — held in place, not resolved."
        end
    else
        -- Full address on chosen, full neglect on the other
        result.address_effects = option.address and option.address.address and option.address.address.effects or nil
        result.neglect_effects = option.neglect and option.neglect.neglect and option.neglect.neglect.effects or nil

        result.narrative_lines[#result.narrative_lines + 1] = option.address and option.address.address and option.address.address.narrative or "You made your choice."
        result.narrative_lines[#result.narrative_lines + 1] = option.neglect and option.neglect.neglect and option.neglect.neglect.narrative or "Something was left behind."
    end

    -- Background pressures: everything not in the dilemma gets worse
    for _, pressure in ipairs(dilemma.background_pressures or {}) do
        result.background_effects[#result.background_effects + 1] = {
            pressure_id = pressure.id,
            effects = pressure.neglect and pressure.neglect.effects or {},
            narrative = pressure.neglect and pressure.neglect.narrative or (pressure.label .. " was left unattended."),
        }
        if pressure.urgency >= 60 then
            result.narrative_lines[#result.narrative_lines + 1] = pressure.label .. " grew worse while you looked elsewhere."
        end
    end

    return result
end

--[[
    Snapshot for UI: simplified view of a dilemma for rendering.
]]
function Dilemma.snapshot(dilemma)
    if not dilemma then return nil end

    local options = {}
    for _, opt in ipairs(dilemma.options or {}) do
        options[#options + 1] = {
            id = opt.id,
            label = opt.label,
            summary = opt.summary,
            detail = opt.detail,
            split = opt.split or false,
        }
    end

    return {
        id = dilemma.id,
        generation = dilemma.generation,
        tension = dilemma.tension,
        pressure_a = {
            label = dilemma.pressures[1].label,
            summary = dilemma.pressures[1].summary,
            urgency = dilemma.pressures[1].urgency,
            category = dilemma.pressures[1].category,
            source = dilemma.pressures[1].source,
        },
        pressure_b = {
            label = dilemma.pressures[2].label,
            summary = dilemma.pressures[2].summary,
            urgency = dilemma.pressures[2].urgency,
            category = dilemma.pressures[2].category,
            source = dilemma.pressures[2].source,
        },
        options = options,
        chosen = dilemma.chosen,
        background_count = #(dilemma.background_pressures or {}),
    }
end

return Dilemma
