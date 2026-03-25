--- blood_memory.lua
--- Blood Memory Flashbacks — the dead speak through the living.
--- At event decision points, if a past heir faced a similar situation,
--- surface a one-liner referencing them. The bloodline does not forget.
---
--- Pure Lua. No Solar2D dependencies.

local rng = require("dredwork_core.rng")

local BloodMemory = {}

-- Flashback templates by event category.
-- Substitution vars: {past_heir}, {past_gen}, {outcome}, {faction_name}
local FLASHBACK_TEMPLATES = {
    war = {
        "Your ancestor {past_heir} faced these same walls in Generation {past_gen}.",
        "The blood remembers {past_heir}'s war. {outcome}",
        "{past_heir} stood where you stand now, sword in hand.",
    },
    plague = {
        "{past_heir} watched the same sickness spread in Generation {past_gen}.",
        "The blood carries {past_heir}'s fever still.",
        "Your ancestor {past_heir} buried half their court to this same plague.",
    },
    famine = {
        "{past_heir} knew this hunger. Generation {past_gen} nearly broke them.",
        "The granaries were empty for {past_heir} too.",
        "Your ancestor {past_heir} rationed the same dwindling stores.",
    },
    faction = {
        "{past_heir} dealt with {faction_name} before. It did not end well.",
        "The blood remembers {past_heir}'s alliance with {faction_name}.",
        "{past_heir} trusted {faction_name} once. Generation {past_gen}.",
    },
    personal = {
        "Your ancestor {past_heir} faced this same choice.",
        "{past_heir} would have known what to do here.",
        "The blood stirs. {past_heir} remembers.",
    },
    general = {
        "The blood remembers. {past_heir} walked this path in Generation {past_gen}.",
        "Your ancestor {past_heir} faced something like this.",
        "{past_heir}'s ghost whispers from Generation {past_gen}.",
    },
}

--- Classify an event into a flashback category.
local function classify_event(event)
    local pool = event.pool or ""
    local id = event.id or ""

    if pool == "world" then
        if id:find("war") or id:find("siege") or id:find("battle") then
            return "war"
        elseif id:find("plague") or id:find("disease") or id:find("sickness") then
            return "plague"
        elseif id:find("famine") or id:find("hunger") or id:find("drought") then
            return "famine"
        end
    elseif pool == "faction" then
        return "faction"
    elseif pool == "personal" then
        return "personal"
    end

    return "general"
end

--- Check if a blood memory flashback should fire for the current event.
--- Rate-limited to ~30% chance when conditions match.
---@param heir_ledger table array of ledger entries from gameState
---@param event table current event being presented
---@param generation number current generation
---@return string|nil flashback text or nil
function BloodMemory.check(heir_ledger, event, generation)
    -- Need at least 3 generations of history
    if not heir_ledger or #heir_ledger < 3 then return nil end
    if not event then return nil end

    -- 30% chance to trigger — the dead do not always speak
    if not rng.chance(0.30) then return nil end

    local category = classify_event(event)

    -- Gather eligible ancestors (not from last 2 generations — too recent to be memory)
    local eligible = {}
    for _, entry in ipairs(heir_ledger) do
        if entry.generation and entry.generation <= generation - 3 then
            eligible[#eligible + 1] = entry
        end
    end
    if #eligible == 0 then return nil end

    local past = eligible[rng.range(1, #eligible)]

    -- Substitution variables
    local vars = {
        past_heir = past.heir_name or "an ancestor",
        past_gen = tostring(past.generation or "?"),
        outcome = "The bloodline endured.",
        faction_name = event.faction_id or "that house",
    }

    -- Select and fill template
    local pool = FLASHBACK_TEMPLATES[category] or FLASHBACK_TEMPLATES.general
    local template = pool[rng.range(1, #pool)]

    local text = template:gsub("{([%w_]+)}", function(key)
        return vars[key] or ("{" .. key .. "}")
    end)

    return text
end

return BloodMemory
