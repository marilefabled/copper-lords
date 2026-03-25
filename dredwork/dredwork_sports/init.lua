-- dredwork Sports — Module Entry
-- High-level management of teams, rosters, scheduling, and sports-specific evolution.

local Sports = {}
Sports.__index = Sports

--- Initialize the module with the engine.
---@param engine table The central dredwork engine.
function Sports.init(engine)
    local self = setmetatable({}, Sports)
    self.engine = engine

    -- Sub-components
    self.match      = require("dredwork_sports.match")
    self.league     = require("dredwork_sports.league")
    self.genetics   = require("dredwork_sports.genetics_adapter")
    self.schedule   = require("dredwork_sports.scheduler")

    -- Monthly: run scheduled matches for the current month
    engine:on("NEW_MONTH", function(clock)
        self:tick_monthly(self.engine.game_state, clock)
    end)

    -- Generational: season advancement and retirements
    engine:on("ADVANCE_GENERATION", function(context)
        self:advance_season(context.game_state)
    end)

    return self
end

--- Create a new sports league.
function Sports:create_league(teams_config)
    self.engine.game_state.teams = teams_config or {}
    self.engine.game_state.season = 1
    self.engine.game_state.matches = {}
end

--- Play a match between two teams.
function Sports:play_match(match_id)
    local match = self.match.play(self.engine.game_state, match_id)

    if match and match.completed then
        self.engine:emit("MATCH_COMPLETED", {
            match_id = match_id,
            winner_id = match.winner_id,
            score = match.score
        })

        -- Winning team members gain bond reputation
        if match.winner_id then
            self.engine:emit("SPORTS_VICTORY", {
                team_id = match.winner_id,
                match_id = match_id
            })
        end
    end

    return match
end

--- Monthly tick: run any scheduled matches for this month.
function Sports:tick_monthly(game_state, clock)
    if not game_state.matches then return end

    local scheduled = self.schedule.get_matches_for_month(game_state, clock.month)
    for _, match_id in ipairs(scheduled or {}) do
        self:play_match(match_id)
    end
end

--- Advance the league by one season (retirements, recruitment).
function Sports:advance_season(game_state)
    -- Aging and Retirement
    self.league.process_aging(game_state)

    -- Recruitment (using the sports genetics adapter)
    self.league.process_recruitment(game_state, self.genetics)

    game_state.season = (game_state.season or 1) + 1
end

--- Standard module serialization.
function Sports:serialize()
    return {
        season = self.engine.game_state.season,
        teams = self.engine.game_state.teams,
        matches = self.engine.game_state.matches
    }
end

--- Standard module deserialization.
function Sports:deserialize(data)
    self.engine.game_state.season = data.season
    self.engine.game_state.teams = data.teams
    self.engine.game_state.matches = data.matches
end

return Sports
