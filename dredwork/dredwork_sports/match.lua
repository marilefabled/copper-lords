-- dredwork Sports — Match Simulation
-- Handles scoring, highlights, and tactical results for a single match.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Match = {}

local function roster_strength(world, team_id)
    local roster = world:get_team_roster(team_id)
    if #roster == 0 then return 50 end
    local total = 0
    for _, person in ipairs(roster) do
        local ratings = person.ratings or { skill = 50, grit = 50, charisma = 50 }
        total = total + (ratings.skill or 50) + ((ratings.grit or 50) * 0.35) + ((ratings.charisma or 50) * 0.15)
    end
    return total / #roster
end

local function choose_team(world, match, home_strength, away_strength, rules)
    local factor = rules.score_swing_factor or 0.1
    local bias = rules.side_bias or 2
    local home_weight = home_strength + ((match.score.home - match.score.away) * factor) + bias
    local away_weight = away_strength + ((match.score.away - match.score.home) * factor) + bias

    return RNG.weighted_pick({
        { side = "home", weight = Math.clamp(home_weight, 1, 1000) },
        { side = "away", weight = Math.clamp(away_weight, 1, 1000) },
    }, function(item) return item.weight end)
end

local function choose_actor(world, roster, rating_key, inverse)
    return RNG.weighted_pick(roster, function(person)
        local ratings = person.ratings or {}
        local rating = ratings[rating_key] or 50
        local weight = inverse and (110 - rating) or rating
        return Math.clamp(weight, 1, 200)
    end)
end

--- Play a match between two teams.
---@param world table The game world/state object
---@param match_id string The ID of the match to play
---@param rules table Configuration for match simulation
---@return table The updated match record
function Match.play(world, match_id, rules)
    local match = world.matches[match_id]
    if not match or match.completed then return match end

    rules = rules or {
        score_swing_factor = 0.1,
        side_bias = 2,
        event_weights = { score = 40, highlight = 15, turnover = 10, controversy = 5, injury = 2, confrontation = 5, defensive_stop = 23 }
    }

    local home_roster = world:get_team_roster(match.home_team_id)
    local away_roster = world:get_team_roster(match.away_team_id)
    local home_strength = roster_strength(world, match.home_team_id)
    local away_strength = roster_strength(world, match.away_team_id)
    
    local phases = RNG.range(world.sport.phases_per_match.min or 10, world.sport.phases_per_match.max or 15)
    
    match.score = match.score or { home = 0, away = 0 }
    match.box = match.box or {}

    for phase = 1, phases do
        local event_type = RNG.weighted_pick({
            { kind = "score", weight = rules.event_weights.score },
            { kind = "highlight", weight = rules.event_weights.highlight },
            { kind = "turnover", weight = rules.event_weights.turnover },
            { kind = "controversy", weight = rules.event_weights.controversy },
            { kind = "injury", weight = rules.event_weights.injury },
            { kind = "confrontation", weight = rules.event_weights.confrontation },
            { kind = "defensive_stop", weight = rules.event_weights.defensive_stop },
        }, function(i) return i.weight end).kind

        local acting_side = choose_team(world, match, home_strength, away_strength, rules).side
        local acting_roster = acting_side == "home" and home_roster or away_roster
        local defending_roster = acting_side == "home" and away_roster or home_roster

        if event_type == "score" or event_type == "highlight" then
            local actor = choose_actor(world, acting_roster, event_type == "highlight" and "flair" or "skill", false)
            local points = RNG.pick(world.sport.scoring or { 1, 2, 3 })
            
            if acting_side == "home" then match.score.home = match.score.home + points
            else match.score.away = match.score.away + points end
            
            match.box[actor.id] = match.box[actor.id] or { points = 0, highlights = 0 }
            match.box[actor.id].points = match.box[actor.id].points + points
            if event_type == "highlight" then match.box[actor.id].highlights = match.box[actor.id].highlights + 1 end
            
            world:add_event({
                kind = event_type,
                match_id = match.id,
                team_id = acting_side == "home" and match.home_team_id or match.away_team_id,
                primary_person_id = actor.id,
                points = points,
                summary = string.format("%s scored %d", world:person_name(actor.id), points)
            })
        end
        -- ... (other event types handled similarly)
    end

    match.completed = true
    match.winner_id = match.score.home > match.score.away and match.home_team_id or match.away_team_id
    
    return match
end

return Match
