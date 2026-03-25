-- Dark Legacy — Dynasty Doctrines
-- Permanent strategic modifiers adopted at generation milestones.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local ok_defs, doctrine_definitions = pcall(require, "dredwork_world.config.doctrine_definitions")
if not ok_defs then doctrine_definitions = {} end

local Doctrines = {}

-- Milestone generations that offer doctrine choices
local MILESTONE_GENS = { 7, 15, 20, 30 }

--- Check if doctrines are available at the current generation.
-- Returns 3 curated doctrine options based on family identity, or empty array.
---@param generation number current generation
---@param existing_doctrines table|nil array of { id, generation_adopted, title }
---@param cultural_memory table|nil CulturalMemory instance
---@return table array of doctrine definitions (3 choices, or empty)
function Doctrines.check_available(generation, existing_doctrines, cultural_memory)
    existing_doctrines = existing_doctrines or {}

    -- Check if this is a milestone generation
    local is_milestone = false
    for _, mg in ipairs(MILESTONE_GENS) do
        if generation == mg then
            is_milestone = true
            break
        end
    end
    if not is_milestone then return {} end

    -- Check if we already adopted a doctrine at this milestone
    for _, d in ipairs(existing_doctrines) do
        if d.generation_adopted == generation then
            return {}
        end
    end

    -- Build set of already-adopted doctrine IDs
    local adopted_set = {}
    for _, d in ipairs(existing_doctrines) do
        adopted_set[d.id] = true
    end

    -- Get family reputation
    local reputation_primary = "unknown"
    if cultural_memory and cultural_memory.reputation then
        reputation_primary = cultural_memory.reputation.primary or "unknown"
    end

    -- Get taboo count
    local taboo_count = 0
    if cultural_memory and cultural_memory.taboos then
        taboo_count = #cultural_memory.taboos
    end

    -- Filter eligible doctrines
    local eligible = {}
    for _, def in ipairs(doctrine_definitions) do
        if not adopted_set[def.id] then
            local passes = true

            -- Check reputation requirement
            if def.requires_reputation then
                local rep_match = false
                for _, rep in ipairs(def.requires_reputation) do
                    if rep == reputation_primary then rep_match = true; break end
                end
                if not rep_match then passes = false end
            end

            -- Check taboo count requirement
            if def.requires_taboo_count and taboo_count < def.requires_taboo_count then
                passes = false
            end

            -- Check generation minimum
            if def.requires_generation_min and generation < def.requires_generation_min then
                passes = false
            end

            if passes then
                eligible[#eligible + 1] = def
            end
        end
    end

    -- Select 3 from eligible (randomized)
    if #eligible <= 3 then return eligible end

    -- Shuffle and pick 3
    local shuffled = {}
    for _, e in ipairs(eligible) do shuffled[#shuffled + 1] = e end
    for i = #shuffled, 2, -1 do
        local j = rng.range(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    return { shuffled[1], shuffled[2], shuffled[3] }
end

--- Adopt a doctrine, adding it to the game state.
---@param doctrine_id string
---@param gameState table
function Doctrines.adopt(doctrine_id, gameState)
    gameState.doctrines = gameState.doctrines or {}

    -- Find the definition
    local def = nil
    for _, d in ipairs(doctrine_definitions) do
        if d.id == doctrine_id then def = d; break end
    end
    if not def then return end

    gameState.doctrines[#gameState.doctrines + 1] = {
        id = def.id,
        title = def.title,
        generation_adopted = gameState.generation,
        modifiers = def.modifiers,
    }
end

--- Get all active (adopted) doctrines.
---@param gameState table
---@return table array of adopted doctrines
function Doctrines.get_active(gameState)
    return gameState.doctrines or {}
end

--- Get a specific modifier value from all active doctrines (additive).
---@param gameState table
---@param modifier_key string
---@return number summed modifier value (0 if none)
function Doctrines.get_modifier(gameState, modifier_key)
    local total = 0
    for _, d in ipairs(gameState.doctrines or {}) do
        if d.modifiers and d.modifiers[modifier_key] then
            local val = d.modifiers[modifier_key]
            if type(val) == "number" then
                total = total + val
            end
        end
    end
    return total
end

--- Check if any active doctrine has a boolean modifier.
---@param gameState table
---@param modifier_key string
---@return boolean
function Doctrines.has_modifier(gameState, modifier_key)
    for _, d in ipairs(gameState.doctrines or {}) do
        if d.modifiers and d.modifiers[modifier_key] then
            return true
        end
    end
    return false
end

return Doctrines
