-- dredwork Animals — Module Entry
-- High-level management of pets, wildlife populations, and pests.

local RNG = require("dredwork_core.rng")
local EB = require("dredwork_core.entity_bridge")

local Animals = {}
Animals.__index = Animals

function Animals.init(engine)
    local self = setmetatable({}, Animals)
    self.engine = engine

    self.logic = require("dredwork_animals.logic")
    self.species = require("dredwork_animals.species")

    -- Initialize state
    engine.game_state.animals = {
        pets = {},
        regional_populations = {}
    }

    -- Provide modifiers to Home module
    engine:on("GET_HOME_ENVIRONMENT_MOD", function(req)
        for _, pet in ipairs(self.engine.game_state.animals.pets) do
            if not pet.is_dead then
                req.comfort_delta = (req.comfort_delta or 0) + 5
            end
        end
        -- Query current region via event bus
        local req_geo = { current_region_id = nil }
        engine:emit("GET_GEOGRAPHY_DATA", req_geo)
        local current_region = req_geo.current_region_id
        if current_region and self.engine.game_state.animals.regional_populations[current_region] then
            local rats = self.engine.game_state.animals.regional_populations[current_region].rats
            if rats and rats.density > 40 then
                req.decay_delta = (req.decay_delta or 0) + (rats.density / 10)
            end
        end
    end)

    -- Daily population growth (Pests/Wildlife)
    engine:on("NEW_DAY", function(clock)
        self:tick_populations(self.engine.game_state)
    end)

    -- Generational pet summary
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick_pets(context.game_state)
    end)

    return self
end

--- Adopt/Purchase a pet.
function Animals:adopt_pet(species_key, name)
    local pet = self.logic.create_animal(species_key, name)

    -- Shadow as entity
    pet.entity_id = EB.register(self.engine, {
        type = "animal", name = pet.name or name or species_key,
        components = {
            species = { key = species_key },
            personality = { PER_LOY = RNG.range(60, 95), PER_BLD = RNG.range(30, 70) },
            mortality = { age = 0, max_age = RNG.range(8, 18) },
            location = { region_id = self.engine.game_state.world_map and self.engine.game_state.world_map.current_region_id or nil },
        },
        tags = { "pet", species_key },
    })
    local focal = EB.get_focus(self.engine)
    if focal and pet.entity_id then
        EB.relate(self.engine, focal, pet.entity_id, "owner_pet", RNG.range(60, 90))
    end

    table.insert(self.engine.game_state.animals.pets, pet)
    return pet
end

--- Initialize wildlife for a region.
function Animals:seed_region(region_id, species_key, density)
    self.engine.game_state.animals.regional_populations[region_id] = self.engine.game_state.animals.regional_populations[region_id] or {}
    self.engine.game_state.animals.regional_populations[region_id][species_key] = { density = density or 10 }
end

--- Step pet simulation.
function Animals:tick_pets(game_state)
    -- Query economy for pet upkeep cost via event bus
    local req_econ = { gold = 0 }
    self.engine:emit("GET_ECONOMIC_DATA", req_econ)

    for i = #game_state.animals.pets, 1, -1 do
        local pet = game_state.animals.pets[i]
        local results = self.logic.tick_pet(pet, { gold = req_econ.gold })
        for _, line in ipairs(results) do
            self.engine.log:info(line)
        end
        if pet.is_dead then table.remove(game_state.animals.pets, i) end
    end
end

--- Step regional populations (Wildlife/Pests).
function Animals:tick_populations(game_state)
    -- Query sacred species via event bus (decoupled from Religion)
    local req_rel = { sacred_species = nil }
    self.engine:emit("GET_RELIGION_DATA", req_rel)
    local sacred_key = req_rel.sacred_species

    for region_id, pops in pairs(game_state.animals.regional_populations) do
        for species_key, pop_state in pairs(pops) do
            -- Apply sacred bonus
            if species_key == sacred_key then
                pop_state.density = math.min(100, pop_state.density + 0.1)
            end

            self.logic.tick_population(pop_state, species_key)

            -- High danger wildlife spawns rumors
            local def = self.species[species_key]
            if def and def.danger > 50 and pop_state.density > 40 and RNG.chance(0.01) then
                local rumor_module = self.engine:get_module("rumor")
                if rumor_module then
                    rumor_module:inject(game_state, {
                        origin_type = "wildlife",
                        subject = region_id,
                        text = "Dangerous wildlife activity reported in " .. region_id .. ".",
                        heat = 40,
                        tags = { danger = true, wildlife = true }
                    })
                end
            end
        end
    end
end

function Animals:serialize() return self.engine.game_state.animals end
function Animals:deserialize(data) self.engine.game_state.animals = data end

return Animals
