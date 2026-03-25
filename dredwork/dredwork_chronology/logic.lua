-- dredwork Chronology — Clock Logic
-- Handles the progression of time across all scales.
-- Uses inline callback emission instead of accumulating event arrays.

local Calendar = require("dredwork_chronology.calendar")

local Logic = {}

--- Create a new clock state.
function Logic.create_clock()
    return {
        day = 1,
        month = 1,
        year = 0,
        generation = 0,
        era_label = "First Age",
        total_days = 0
    }
end

--- Advance the clock by a set number of days, emitting events inline via callback.
---@param clock table The clock state to advance.
---@param days number Number of days to advance.
---@param emit_fn function Callback: emit_fn(event_name, clock) fired as each event occurs.
function Logic.advance(clock, days, emit_fn)
    days = days or 1

    for _ = 1, days do
        clock.total_days = clock.total_days + 1
        clock.day = clock.day + 1
        emit_fn("NEW_DAY", clock)

        if clock.day > Calendar.days_per_month then
            clock.day = 1
            clock.month = clock.month + 1
            emit_fn("NEW_MONTH", clock)

            if clock.month > Calendar.months_per_year then
                clock.month = 1
                clock.year = clock.year + 1
                emit_fn("NEW_YEAR", clock)

                if clock.year % Calendar.years_per_generation == 0 then
                    clock.generation = clock.generation + 1
                    emit_fn("NEW_GENERATION", clock)
                end
            end
        end
    end
end

return Logic
