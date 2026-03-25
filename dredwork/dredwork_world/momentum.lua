-- Dark Legacy — Generational Momentum (Streak Psychology)
-- Tracks consecutive generations where a trait category's average improves.
-- 3+ consecutive rising generations = "ASCENDING BLOOD" status.
-- Breaking a 3+ streak = "THE BLOOD COOLS" narrative moment.
-- Pure Lua, zero Solar2D dependencies.

local Momentum = {}

local CATEGORIES = { "physical", "mental", "social", "creative" }

local ASCENDING_THRESHOLD = 3

local ascending_narratives = {
    physical = "The blood grows stronger with each generation.",
    mental = "The mind sharpens across the generations.",
    social = "The family's influence deepens with each heir.",
    creative = "Inspiration flows through the bloodline unbroken.",
}

local cooling_narratives = {
    physical = "The body falters. The strength of the ancestors fades.",
    mental = "The sharpness dims. The mind's edge has dulled.",
    social = "The family's voice carries less weight than before.",
    creative = "The spark of creation gutters. Inspiration abandons the blood.",
}

--- Create a fresh momentum data table.
---@return table momentum_data { physical = { streak, direction }, ... }
function Momentum.new()
    local data = {}
    for _, cat in ipairs(CATEGORIES) do
        data[cat] = { streak = 0, direction = "neutral" }
    end
    return data
end

--- Update momentum tracking after cultural memory update.
--- Compares old category averages to new ones, updates streaks.
---@param momentum_data table current momentum state (mutated in-place)
---@param old_avgs table { physical = N, mental = N, ... }
---@param new_avgs table { physical = N, mental = N, ... }
---@return table { changes = array of change events, streaks = updated momentum_data }
function Momentum.update(momentum_data, old_avgs, new_avgs)
    momentum_data = momentum_data or Momentum.new()
    old_avgs = old_avgs or {}
    new_avgs = new_avgs or {}

    local changes = {}

    for _, cat in ipairs(CATEGORIES) do
        local old_val = old_avgs[cat] or 50
        local new_val = new_avgs[cat] or 50
        local delta = new_val - old_val
        local entry = momentum_data[cat] or { streak = 0, direction = "neutral" }

        local new_direction
        if delta > 0.5 then
            new_direction = "rising"
        elseif delta < -0.5 then
            new_direction = "falling"
        else
            new_direction = "neutral"
        end

        if new_direction == "neutral" then
            -- Flat: no change to streak, no event
        elseif new_direction == entry.direction then
            -- Same direction: extend streak
            entry.streak = entry.streak + 1
            if entry.streak == ASCENDING_THRESHOLD and new_direction == "rising" then
                changes[#changes + 1] = {
                    category = cat,
                    streak = entry.streak,
                    direction = new_direction,
                    label = "ASCENDING",
                    narrative = ascending_narratives[cat],
                }
            end
        else
            -- Direction changed
            local old_streak = entry.streak
            local old_dir = entry.direction

            -- Fire "blood cools" if breaking a 3+ rising streak
            if old_dir == "rising" and old_streak >= ASCENDING_THRESHOLD then
                changes[#changes + 1] = {
                    category = cat,
                    streak = 0,
                    direction = new_direction,
                    label = "COOLING",
                    narrative = cooling_narratives[cat],
                }
            end

            entry.streak = 1
            entry.direction = new_direction
        end

        momentum_data[cat] = entry
    end

    return { changes = changes, streaks = momentum_data }
end

--- Get categories with active ascending blood status (streak >= 3, rising).
---@param momentum_data table
---@return table array of { category, streak }
function Momentum.get_ascending(momentum_data)
    if not momentum_data then return {} end
    local result = {}
    for _, cat in ipairs(CATEGORIES) do
        local entry = momentum_data[cat]
        if entry and entry.streak >= ASCENDING_THRESHOLD and entry.direction == "rising" then
            result[#result + 1] = { category = cat, streak = entry.streak }
        end
    end
    return result
end

--- Compute nurture modifiers based on momentum streaks.
---@param momentum_data table
---@return table array of { trait, bonus, description }
function Momentum.compute_nurture_modifiers(momentum_data)
    if not momentum_data then return {} end
    local mods = {}
    
    local cat_to_trait = {
        physical = "PHY_STR",
        mental   = "MEN_INT",
        social   = "SOC_CHA",
        creative = "CRE_ING"
    }
    
    for cat, entry in pairs(momentum_data) do
        if entry.streak >= 3 and entry.direction == "rising" then
            -- Ascending: +2 bonus
            if cat_to_trait[cat] then
                table.insert(mods, {
                    trait = cat_to_trait[cat],
                    bonus = 2,
                    description = "Born into a rising " .. cat .. " tradition."
                })
            end
        elseif entry.direction == "falling" and entry.streak >= 2 then
            -- Falling: -2 penalty
            if cat_to_trait[cat] then
                table.insert(mods, {
                    trait = cat_to_trait[cat],
                    bonus = -2,
                    description = "Born during a decline in the family's " .. cat .. " focus."
                })
            end
        end
    end
    
    return mods
end

--- Get display labels for all categories.
---@param momentum_data table
---@return table { physical = "ASCENDING (5)" or nil, ... }
function Momentum.get_labels(momentum_data)
    if not momentum_data then return {} end
    local labels = {}
    for _, cat in ipairs(CATEGORIES) do
        local entry = momentum_data[cat]
        if entry and entry.streak >= ASCENDING_THRESHOLD and entry.direction == "rising" then
            labels[cat] = "ASCENDING (" .. entry.streak .. ")"
        end
    end
    return labels
end

--- Serialize momentum data for save/load.
---@param momentum_data table
---@return table
function Momentum.to_table(momentum_data)
    if not momentum_data then return nil end
    local t = {}
    for _, cat in ipairs(CATEGORIES) do
        local entry = momentum_data[cat]
        if entry then
            t[cat] = { streak = entry.streak, direction = entry.direction }
        end
    end
    return t
end

--- Deserialize momentum data from save.
---@param data table
---@return table
function Momentum.from_table(data)
    if not data then return Momentum.new() end
    local m = Momentum.new()
    for _, cat in ipairs(CATEGORIES) do
        if data[cat] then
            m[cat] = { streak = data[cat].streak or 0, direction = data[cat].direction or "neutral" }
        end
    end
    return m
end

return Momentum
