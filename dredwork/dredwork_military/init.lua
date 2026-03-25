-- dredwork Military — Module Entry
-- High-level management of armed forces, readiness, and power projection.

local EB = require("dredwork_core.entity_bridge")

local Military = {}
Military.__index = Military

function Military.init(engine)
    local self = setmetatable({}, Military)
    self.engine = engine

    self.logic = require("dredwork_military.logic")

    -- Initialize state
    engine.game_state.military = {
        units = {},
        total_power = 0
    }

    -- Expose military data via event bus (other modules query this)
    engine:on("GET_MILITARY_DATA", function(req)
        req.total_power = self.engine.game_state.military.total_power
        req.unit_count = #self.engine.game_state.military.units
    end)

    -- Geography provides base for force deployment
    engine:on("GET_REGIONAL_SECURITY", function(req)
        local total_power = 0
        for _, unit in ipairs(self.engine.game_state.military.units) do
            if unit.location_id == req.region_id then
                total_power = total_power + self.logic.calculate_power(unit)
            end
        end
        req.security_score = (req.security_score or 0) + total_power
    end)

    -- Military units tick monthly for attrition/readiness
    engine:on("NEW_MONTH", function(clock)
        self:tick_monthly(self.engine.game_state)
    end)

    -- Generational summary
    engine:on("ADVANCE_GENERATION", function(context)
        -- Generational summary
    end)

    return self
end

--- Deploy a unit to a specific region.
function Military:deploy(unit_index, region_id)
    local unit = self.engine.game_state.military.units[unit_index]
    if unit then
        unit.location_id = region_id
        return true
    end
    return false
end

--- Step military forces (Monthly).
function Military:tick_monthly(game_state)
    local total_power = 0
    local context = { in_war = false, attrition_mod = 1.0 }

    local req_tech = { field_id = "warfare", multiplier = 1.0 }
    self.engine:emit("GET_TECH_MULTIPLIER", req_tech)
    local tech_mod = req_tech.multiplier or 1.0

    local req_infra = { field_id = "infrastructure", multiplier = 1.0 }
    self.engine:emit("GET_TECH_MULTIPLIER", req_infra)
    context.attrition_mod = 1.0 / (req_infra.multiplier or 1.0)

    -- Query economy for resources via event bus
    local req_econ = { gold = 0 }
    self.engine:emit("GET_ECONOMIC_DATA", req_econ)

    for _, unit in ipairs(game_state.military.units) do
        local results = self.logic.tick(unit, { gold = req_econ.gold }, context, 1/12)
        total_power = total_power + (self.logic.calculate_power(unit) * tech_mod)
    end

    game_state.military.total_power = math.floor(total_power)
end

--- Recruit a new military force.
function Military:recruit(type_key, commander_id)
    local unit = self.logic.create(type_key, commander_id)

    -- Shadow as entity
    unit.entity_id = EB.register(self.engine, {
        type = "unit", name = unit.label or type_key,
        components = {
            military = { type = type_key, strength = unit.strength, readiness = unit.readiness },
            location = unit.location_id and { region_id = unit.location_id } or nil,
        },
        tags = { "military", type_key },
    })

    table.insert(self.engine.game_state.military.units, unit)
    return unit
end

function Military:serialize() return self.engine.game_state.military end
function Military:deserialize(data) self.engine.game_state.military = data end

return Military
