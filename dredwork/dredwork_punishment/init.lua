-- dredwork Punishment — Module Entry
-- High-level management of dungeons, jails, and social retribution.

local Punishment = {}
Punishment.__index = Punishment

function Punishment.init(engine)
    local self = setmetatable({}, Punishment)
    self.engine = engine

    self.logic = require("dredwork_punishment.logic")
    self.archetypes = require("dredwork_punishment.archetypes")

    -- Initialize state
    engine.game_state.justice = {
        active_facility = { type = "dungeon", label = "Royal Dungeons" },
        prisoners = {},
        terror_score = 0
    }

    -- Influence Politics (Legitimacy/Unrest) via event bus
    engine:on("GET_POLITICAL_UNREST_MOD", function(req)
        local terror = self.engine.game_state.justice.terror_score
        if terror > 10 then
            -- High terror suppresses unrest but drains legitimacy over time
            req.unrest_delta = (req.unrest_delta or 0) - (terror / 2)

            -- Emit legitimacy drain via event bus (decoupled from Politics)
            self.engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = -(terror / 20) })
        end
    end)

    -- Provide service for Crime failures
    engine:on("CRIMINAL_SENTENCED", function(ctx)
        local days = (ctx.years or 25) * 360
        self:sentence_person(ctx.person_id or "unknown_thief", days)
        self.engine.log:info("A criminal has been hauled to the %s for %d days.",
            self.engine.game_state.justice.active_facility.label, days)
    end)

    -- Daily sentence reduction
    engine:on("NEW_DAY", function(clock)
        local justice = self.engine.game_state.justice
        local facility_def = self.archetypes[justice.active_facility.type]

        for i = #justice.prisoners, 1, -1 do
            local p = justice.prisoners[i]
            p.years_remaining = math.max(0, p.years_remaining - 1)

            if p.years_remaining <= 0 then
                self.engine.log:info("Prisoner %s release date has arrived.", p.person_id)
                table.remove(justice.prisoners, i)
            end
        end
    end)

    -- Tick punishment per generation
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick(context.game_state)
    end)

    return self
end

--- Sentence a character to the current facility.
function Punishment:sentence_person(person_id, years)
    local facility = self.engine.game_state.justice.active_facility
    local record = self.logic.sentence(person_id, facility, years)
    table.insert(self.engine.game_state.justice.prisoners, record)
    return record
end

--- Step justice simulation.
function Punishment:tick(game_state)
    local justice = game_state.justice
    local facility_def = self.archetypes[justice.active_facility.type]

    for i = #justice.prisoners, 1, -1 do
        local p = justice.prisoners[i]
        local results = self.logic.tick_prisoner(p, facility_def)
        for _, line in ipairs(results) do
            self.engine.log:info(line)
        end

        -- Clean up released/dead
        if p.years_remaining <= 0 or p.health_mod <= 0 then
            table.remove(justice.prisoners, i)
        end
    end

    -- Calculate systemic terror
    justice.terror_score = self.logic.calculate_terror(facility_def, #justice.prisoners)
end

function Punishment:serialize() return self.engine.game_state.justice end
function Punishment:deserialize(data) self.engine.game_state.justice = data end

return Punishment
