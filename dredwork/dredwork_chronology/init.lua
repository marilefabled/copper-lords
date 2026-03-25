-- dredwork Chronology — Module Entry
-- The master source of temporal truth for the engine.

local Chronology = {}
Chronology.__index = Chronology

function Chronology.init(engine)
    local self = setmetatable({}, Chronology)
    self.engine = engine

    self.logic = require("dredwork_chronology.logic")
    self.calendar = require("dredwork_chronology.calendar")

    -- Initialize state
    engine.game_state.clock = self.logic.create_clock()

    return self
end

--- Advance the master clock, emitting temporal events inline.
function Chronology:tick(days)
    self.logic.advance(self.engine.game_state.clock, days, function(event, clock)
        self.engine:emit(event, clock)

        -- Map NEW_GENERATION to the global legacy event
        if event == "NEW_GENERATION" then
            self.engine:emit("ADVANCE_GENERATION", {
                game_state = self.engine.game_state,
                generation = clock.generation,
                year = clock.year
            })
        end
    end)
end

--- Get a formatted string of the current time.
function Chronology:get_formatted_time()
    return self.calendar.format(self.engine.game_state.clock)
end

function Chronology:serialize() return self.engine.game_state.clock end
function Chronology:deserialize(data) self.engine.game_state.clock = data end

return Chronology
