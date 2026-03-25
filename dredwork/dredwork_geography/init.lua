-- dredwork Geography — Module Entry
-- Foundation: Regions, Connectivity, and Biomes.

local Geography = {}
Geography.__index = Geography

function Geography.init(engine)
    local self = setmetatable({}, Geography)
    self.engine = engine
    self.map = require("dredwork_geography.map")
    self.regional_state = require("dredwork_geography.regional_state")
    self.journey_lib = require("dredwork_geography.journey")

    -- Initialize global map state
    engine.game_state.world_map = {
        regions = {},
        current_region_id = nil,
        regional_states = {},     -- region_id → regional state (suspicion, contacts, familiarity)
        active_journey = nil,     -- journey state when traveling
    }

    -- Expose geography data via event bus (queried by many modules)
    local Biomes = require("dredwork_geography.biomes")

    engine:on("GET_GEOGRAPHY_DATA", function(req)
        local wm = self.engine.game_state.world_map
        req.current_region_id = wm.current_region_id
        req.regions = wm.regions

        -- Resolve which region to describe
        local region = nil
        if req.region_id and wm.regions[req.region_id] then
            region = wm.regions[req.region_id]
        elseif wm.current_region_id and wm.regions[wm.current_region_id] then
            region = wm.regions[wm.current_region_id]
        end

        if region then
            req.biome = region.biome
            req.upkeep_mod = region.upkeep_mod
            req.label = region.label

            -- Expose full biome properties for downstream systems
            local biome_def = Biomes[region.biome]
            if biome_def then
                req.food_base = biome_def.food_base
                req.military_attrition = biome_def.military_attrition
                req.disease_risk = biome_def.disease_risk
                req.wildlife_growth = biome_def.wildlife_growth
                req.construction_mod = biome_def.construction_mod
                req.rumor_speed = biome_def.rumor_speed
                req.biome_tags = biome_def.tags
            end
        end
    end)

    -- Provide travel distance between regions
    engine:on("GET_TRAVEL_DISTANCE", function(req)
        if req.from and req.to then
            req.distance = self.map.get_distance(self.engine.game_state.world_map.regions, req.from, req.to)
        end
    end)

    -- Provide climate impact for Home module
    engine:on("GET_UPKEEP_MODIFIER", function(req)
        local region = self:get_current_region()
        if region then
            req.modifier = (req.modifier or 1.0) * region.upkeep_mod
        end
    end)

    -- Monthly: tick regional states (suspicion spread, reputation decay)
    engine:on("NEW_MONTH", function(clock)
        local wm = engine.game_state.world_map
        local capital_id = self:get_capital_id()
        for region_id, state in pairs(wm.regional_states) do
            local dist = 1
            if capital_id and region_id ~= capital_id then
                dist = self:get_travel_time(region_id, capital_id)
            end
            self.regional_state.tick_monthly(state, engine.game_state, dist)
        end
    end)

    -- Expose regional state data
    engine:on("GET_REGIONAL_STATE", function(req)
        if req.region_id then
            local wm = engine.game_state.world_map
            req.state = wm.regional_states[req.region_id]
        end
    end)

    -- Journey query
    engine:on("GET_JOURNEY", function(req)
        req.journey = engine.game_state.world_map.active_journey
    end)

    return self
end

--- Get travel time between regions.
function Geography:get_travel_time(id_a, id_b)
    local dist = self.map.get_distance(self.engine.game_state.world_map.regions, id_a, id_b)
    return dist
end

--- Add a region to the world.
function Geography:add_region(id, label, biome)
    local region = self.map.create_region(id, label, biome)
    self.engine.game_state.world_map.regions[id] = region
    self.engine.game_state.world_map.regional_states[id] = self.regional_state.create(id)
    if not self.engine.game_state.world_map.current_region_id then
        self.engine.game_state.world_map.current_region_id = id
    end
    return region
end

--- Link two existing regions.
function Geography:link_regions(id_a, id_b, dist)
    local reg_a = self.engine.game_state.world_map.regions[id_a]
    local reg_b = self.engine.game_state.world_map.regions[id_b]
    if reg_a and reg_b then
        self.map.link(reg_a, reg_b, dist)
    end
end

--- Get the current region data.
function Geography:get_current_region()
    local id = self.engine.game_state.world_map.current_region_id
    return self.engine.game_state.world_map.regions[id]
end

--- Set a region as the capital (seat of the ruling house).
function Geography:set_capital(region_id)
    local wm = self.engine.game_state.world_map
    for _, state in pairs(wm.regional_states) do
        state.is_capital = false
    end
    if wm.regional_states[region_id] then
        wm.regional_states[region_id].is_capital = true
    end
end

--- Get the capital region id.
function Geography:get_capital_id()
    for id, state in pairs(self.engine.game_state.world_map.regional_states) do
        if state.is_capital then return id end
    end
    return nil
end

--- Get regional state for a region.
function Geography:get_regional_state(region_id)
    return self.engine.game_state.world_map.regional_states[region_id]
end

--- Get current regional state.
function Geography:get_current_regional_state()
    local id = self.engine.game_state.world_map.current_region_id
    return self.engine.game_state.world_map.regional_states[id]
end

--- Start a journey to another region.
function Geography:begin_journey(to_id)
    local wm = self.engine.game_state.world_map
    local from_id = wm.current_region_id
    if not from_id or from_id == to_id then return nil end

    local distance = self:get_travel_time(from_id, to_id)
    if distance >= 999 then return nil end  -- unreachable

    local entities = self.engine:get_module("entities")
    local focal = entities and entities:get_focus()
    if not focal then return nil end

    -- Pay supply cost from personal wealth
    local cost = self.journey_lib.get_cost(distance)
    local pw = focal.components.personal_wealth
    if pw then
        local WealthLib = require("dredwork_agency.wealth")
        local actual_cost = math.min(pw.gold, cost)
        if actual_cost > 0 then
            WealthLib.change(pw, -actual_cost, "travel supplies")
        end
    end

    local journey = self.journey_lib.start(from_id, to_id, distance, focal, self.engine.game_state)
    wm.active_journey = journey

    self.engine:emit("JOURNEY_STARTED", {
        from = from_id, to = to_id, distance = distance,
        text = "You pack what you can carry and leave " .. journey.from_label .. " behind.",
    })

    return journey
end

--- Advance the active journey by one day.
function Geography:advance_journey()
    local wm = self.engine.game_state.world_map
    local journey = wm.active_journey
    if not journey then return nil end

    local entities = self.engine:get_module("entities")
    local focal = entities and entities:get_focus()

    local event = self.journey_lib.advance_day(journey, self.engine.game_state, focal)

    if journey.finished then
        self:_complete_journey(journey, focal)
    end

    return event
end

--- Respond to the current journey event.
function Geography:respond_journey(option_id)
    local wm = self.engine.game_state.world_map
    local journey = wm.active_journey
    if not journey then return nil end

    local result = self.journey_lib.respond(journey, option_id)

    -- Apply gold changes immediately
    if result and result.gold_delta then
        local entities = self.engine:get_module("entities")
        local focal = entities and entities:get_focus()
        if focal and focal.components.personal_wealth then
            local WealthLib = require("dredwork_agency.wealth")
            WealthLib.change(focal.components.personal_wealth, result.gold_delta, "travel")
        end
    end

    return result
end

--- Complete a journey — arrive at destination.
function Geography:_complete_journey(journey, focal)
    local wm = self.engine.game_state.world_map

    -- Move to destination
    wm.current_region_id = journey.to_id
    if focal and focal.components.location then
        focal.components.location.region_id = journey.to_id
    end

    -- Update regional states
    local dest_state = wm.regional_states[journey.to_id]
    if dest_state then
        local day = self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0
        self.regional_state.arrive(dest_state, day)
    end

    -- Apply health/morale to needs
    if focal and focal.components.needs then
        local Math = require("dredwork_core.math")
        if journey.health < 50 then
            focal.components.needs.safety = Math.clamp((focal.components.needs.safety or 50) - 10, 0, 100)
            focal.components.needs.comfort = Math.clamp((focal.components.needs.comfort or 50) - 15, 0, 100)
        end
        if journey.morale > 60 then
            focal.components.needs.purpose = Math.clamp((focal.components.needs.purpose or 50) + 5, 0, 100)
        elseif journey.morale < 30 then
            focal.components.needs.purpose = Math.clamp((focal.components.needs.purpose or 50) - 8, 0, 100)
        end
    end

    -- Clear journey
    wm.active_journey = nil

    -- Emit arrival
    self.engine:emit("JOURNEY_COMPLETED", {
        from = journey.from_id, to = journey.to_id,
        days = journey.day, health = journey.health, morale = journey.morale,
        text = "You have arrived at " .. journey.to_label .. ".",
    })
    self.engine:push_ui_event("JOURNEY_COMPLETED", {
        text = "You have arrived at " .. journey.to_label .. ".",
    })
end

--- Is a journey active?
function Geography:is_traveling()
    return self.engine.game_state.world_map.active_journey ~= nil
end

--- Get travel preview (cost, distance, danger) without starting.
function Geography:get_travel_preview(to_id)
    local wm = self.engine.game_state.world_map
    local from_id = wm.current_region_id
    if not from_id then return nil end

    local distance = self:get_travel_time(from_id, to_id)
    if distance >= 999 then return nil end

    local dest_state = wm.regional_states[to_id]
    local dest_region = wm.regions[to_id]

    return {
        from_id = from_id,
        to_id = to_id,
        to_label = dest_region and dest_region.label or to_id,
        distance = distance,
        cost = self.journey_lib.get_cost(distance),
        danger = dest_state and dest_state.danger_level or "unknown",
        familiarity = dest_state and self.regional_state.get_familiarity(dest_state) or "unknown",
        contacts = dest_state and #dest_state.contacts or 0,
        biome = dest_region and dest_region.biome or "unknown",
    }
end

function Geography:serialize()
    return self.engine.game_state.world_map
end

function Geography:deserialize(data)
    self.engine.game_state.world_map = data
end

return Geography
