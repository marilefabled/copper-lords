-- dredwork Animals — Simulation Logic
-- Handles population growth, pet health, and pest impact.

local Math = require("dredwork_core.math")
local Species = require("dredwork_animals.species")

local Logic = {}

--- Create a specific animal instance (usually for pets).
function Logic.create_animal(species_key, name)
    local def = Species[species_key] or Species.hound
    return {
        species = species_key,
        label = def.label,
        name = name or "Unnamed",
        health = 100,
        loyalty = 50,
        age = 0,
        is_dead = false
    }
end

--- Simulate a pet for one generation.
function Logic.tick_pet(pet, resources)
    local lines = {}
    local def = Species[pet.species]
    
    pet.age = pet.age + 1
    
    -- Maintenance check
    local paid = (resources and resources.gold or 0) >= (def.maintenance or 0)
    if paid then
        pet.health = Math.clamp(pet.health + 5, 0, 100)
        pet.loyalty = Math.clamp(pet.loyalty + 10, 0, 100)
    else
        pet.health = Math.clamp(pet.health - 20, 0, 100)
        pet.loyalty = Math.clamp(pet.loyalty - 10, 0, 100)
        table.insert(lines, string.format("%s is starving.", pet.name))
    end
    
    -- Natural death
    if pet.health <= 0 or (pet.age > 1 and math.random() > 0.7) then
        pet.is_dead = true
        table.insert(lines, string.format("%s has passed away.", pet.name))
    end
    
    return lines
end

--- Simulate regional wildlife/pest populations.
function Logic.tick_population(pop_state, species_key)
    local def = Species[species_key]
    if not def then return end
    
    -- Logistic growth
    local growth_rate = (def.reproduction or 10) / 100
    local carrying_capacity = 100
    local current = pop_state.density or 0
    
    local change = current * growth_rate * (1 - current / carrying_capacity)
    pop_state.density = Math.clamp(current + change + (math.random() * 5 - 2), 0, 100)
end

return Logic
