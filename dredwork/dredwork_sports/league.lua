-- dredwork Sports — League Management
-- Season progression, standings, aging, retirement, and recruitment.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local League = {}

--- Process aging for all team rosters.
function League.process_aging(game_state)
    if not game_state.teams then return end

    for _, team in ipairs(game_state.teams) do
        if team.roster then
            for i = #team.roster, 1, -1 do
                local player = team.roster[i]
                player.age = (player.age or 20) + 1

                -- Decline: stats degrade after peak age
                if player.age > 30 then
                    local decline = (player.age - 30) * 2
                    player.skill = Math.clamp((player.skill or 50) - decline, 0, 100)
                    player.fitness = Math.clamp((player.fitness or 50) - decline * 0.5, 0, 100)
                end

                -- Retirement check
                local retire_chance = 0
                if player.age >= 35 then retire_chance = 0.3
                elseif player.age >= 40 then retire_chance = 0.7
                elseif player.age >= 45 then retire_chance = 1.0
                end

                if retire_chance > 0 and RNG.chance(retire_chance) then
                    player.retired = true
                    table.remove(team.roster, i)
                end
            end
        end
    end
end

--- Process recruitment for all teams.
function League.process_recruitment(game_state, genetics_adapter)
    if not game_state.teams then return end

    for _, team in ipairs(game_state.teams) do
        team.roster = team.roster or {}

        -- Fill empty roster spots
        local target_size = team.roster_size or 15
        while #team.roster < target_size do
            local recruit
            if genetics_adapter then
                recruit = genetics_adapter.generate_athlete(team)
            else
                recruit = {
                    name = "Recruit #" .. RNG.range(100, 999),
                    age = RNG.range(18, 24),
                    skill = RNG.range(30, 70),
                    fitness = RNG.range(40, 80),
                    morale = RNG.range(50, 80),
                }
            end
            table.insert(team.roster, recruit)
        end
    end
end

--- Calculate team standings from match results.
function League.calculate_standings(game_state)
    if not game_state.teams or not game_state.matches then return {} end

    local standings = {}
    for _, team in ipairs(game_state.teams) do
        standings[team.id] = { team_id = team.id, wins = 0, losses = 0, draws = 0, points = 0 }
    end

    for _, match in ipairs(game_state.matches) do
        if match.completed and match.winner_id then
            local winner = standings[match.winner_id]
            local loser_id = match.team_a_id == match.winner_id and match.team_b_id or match.team_a_id
            local loser = standings[loser_id]
            if winner then winner.wins = winner.wins + 1; winner.points = winner.points + 3 end
            if loser then loser.losses = loser.losses + 1 end
        end
    end

    -- Sort by points
    local sorted = {}
    for _, s in pairs(standings) do table.insert(sorted, s) end
    table.sort(sorted, function(a, b) return a.points > b.points end)
    return sorted
end

return League
