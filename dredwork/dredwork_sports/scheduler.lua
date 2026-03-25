-- dredwork Sports — Match Scheduler
-- Generates and manages match schedules across a season.

local RNG = require("dredwork_core.rng")

local Scheduler = {}

--- Generate a round-robin schedule for a season.
---@param teams table array of team objects (need .id)
---@return table schedule: array of { month, team_a_id, team_b_id, match_id }
function Scheduler.generate_season(teams)
    if not teams or #teams < 2 then return {} end

    local schedule = {}
    local match_counter = 0
    local ids = {}
    for _, t in ipairs(teams) do table.insert(ids, t.id) end

    -- Simple round-robin: each pair plays once per season
    local month = 1
    for i = 1, #ids do
        for j = i + 1, #ids do
            match_counter = match_counter + 1
            table.insert(schedule, {
                match_id = "match_" .. match_counter,
                month = month,
                team_a_id = ids[i],
                team_b_id = ids[j],
                completed = false,
            })
            -- Spread matches across months (max 3 per month)
            if match_counter % 3 == 0 then
                month = month + 1
                if month > 12 then month = 12 end
            end
        end
    end

    return schedule
end

--- Get matches scheduled for a specific month.
function Scheduler.get_matches_for_month(game_state, month)
    if not game_state.matches then return {} end

    local due = {}
    for _, match in ipairs(game_state.matches) do
        if match.month == month and not match.completed then
            table.insert(due, match.match_id)
        end
    end
    return due
end

--- Mark a match as completed.
function Scheduler.complete_match(game_state, match_id, result)
    if not game_state.matches then return end
    for _, match in ipairs(game_state.matches) do
        if match.match_id == match_id then
            match.completed = true
            match.winner_id = result.winner_id
            match.score = result.score
            break
        end
    end
end

return Scheduler
