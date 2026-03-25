-- Dark Legacy — The Undercurrent
-- Detects sustained hidden patterns across generations.
-- Whispers, murmurs, and roars of systemic genetic and cultural trends.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")
local trait_definitions = require("dredwork_genetics.config.trait_definitions")

local ok_patterns, patterns = pcall(require, "dredwork_world.config.undercurrent_patterns")
if not ok_patterns then patterns = {} end

local Undercurrent = {}

-- Helper: compute category average from a genome
local function category_avg(genome, cat_key)
    local prefix = ({ physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE" })[cat_key]
    if not prefix or not genome then return 50 end
    local sum, count = 0, 0
    for _, def in ipairs(trait_definitions) do
        if def.id:sub(1, 3) == prefix then
            local t = genome:get_trait(def.id)
            if t then
                sum = sum + t:get_value()
                count = count + 1
            end
        end
    end
    return count > 0 and (sum / count) or 50
end

--- Detect active undercurrent patterns for the current generation.
-- Increments streak counters and fires patterns that cross thresholds.
---@param gameState table the full game state
---@return table array of { pattern_id, title, narrative, severity, generation_span }
function Undercurrent.detect(gameState)
    if not gameState then return {} end

    -- Initialize streak storage
    gameState.undercurrent_streaks = gameState.undercurrent_streaks or {}
    local streaks = gameState.undercurrent_streaks

    -- Store previous category averages for drift detection
    local genome = gameState.current_heir
    if genome then
        gameState._undercurrent_prev_avgs = gameState._undercurrent_prev_avgs or {}
    end

    -- Pass world conditions for pattern checks
    if gameState._world_state and gameState._world_state.conditions then
        gameState._world_conditions = gameState._world_state.conditions
    end

    local active = {}

    for _, pattern in ipairs(patterns) do
        local ok, result = pcall(pattern.check, gameState)
        if ok and result then
            streaks[pattern.id] = (streaks[pattern.id] or 0) + 1
        else
            streaks[pattern.id] = 0
        end

        local count = streaks[pattern.id] or 0
        if count >= pattern.threshold then
            -- Determine severity from severity_map
            local severity = "whisper"
            local sorted_thresholds = {}
            for k, v in pairs(pattern.severity_map) do
                sorted_thresholds[#sorted_thresholds + 1] = { threshold = k, severity = v }
            end
            table.sort(sorted_thresholds, function(a, b) return a.threshold < b.threshold end)
            for _, st in ipairs(sorted_thresholds) do
                if count >= st.threshold then
                    severity = st.severity
                end
            end

            local narrative = pattern.narratives[severity] or pattern.narratives.whisper or ""

            active[#active + 1] = {
                pattern_id = pattern.id,
                title = pattern.title,
                narrative = narrative,
                severity = severity,
                generation_span = count,
            }
        end
    end

    -- Update previous averages for next generation's drift detection
    if genome then
        for _, cat in ipairs({ "physical", "mental", "social", "creative" }) do
            gameState._undercurrent_prev_avgs[cat] = category_avg(genome, cat)
        end
    end

    return active
end

--- Get the highest-severity undercurrent from a detection result.
---@param undercurrents table array from detect()
---@return table|nil the most severe undercurrent
function Undercurrent.get_strongest(undercurrents)
    if not undercurrents or #undercurrents == 0 then return nil end
    local severity_rank = { whisper = 1, murmur = 2, roar = 3 }
    local best = undercurrents[1]
    for i = 2, #undercurrents do
        local u = undercurrents[i]
        if (severity_rank[u.severity] or 0) > (severity_rank[best.severity] or 0) then
            best = u
        end
    end
    return best
end

return Undercurrent
