-- dredwork Home — Simulation Logic
-- Decay, environment, upkeep, upgrades, rooms, and household management.

local Math = require("dredwork_core.math")
local RNG = require("dredwork_core.rng")
local Templates = require("dredwork_home.templates")

local Logic = {}

function Logic.create(type_key)
    local template = Templates[type_key] or Templates.castle
    local home = {
        type = type_key,
        label = template.label,
        attributes = {},
        upkeep_cost = template.base_upkeep,
        rooms = {},              -- upgradeable rooms
        upgrades = {},           -- applied upgrades
        age = 0,                 -- how long this home has existed (in months)
        damage_history = {},     -- recent damage events
        tags = {},
    }

    for k, v in pairs(template.base_attributes) do
        home.attributes[k] = v
    end
    for _, tag in ipairs(template.tags) do
        table.insert(home.tags, tag)
    end

    -- Default rooms
    home.rooms = {
        { id = "main_hall",  label = "Main Hall",  condition = 80, comfort_bonus = 5 },
        { id = "hearth",     label = "Hearth Room", condition = 90, comfort_bonus = 8 },
        { id = "storage",    label = "Storage",     condition = 70, comfort_bonus = 0 },
    }

    return home
end

--- Simulate one tick of home life.
function Logic.tick(home, resources, upkeep_modifier, env_mods)
    local lines = {}
    upkeep_modifier = upkeep_modifier or 1.0
    local effective_upkeep = home.upkeep_cost * upkeep_modifier

    home.age = (home.age or 0) + 1

    -- 1. Upkeep Check
    local gold = resources and resources.gold or 0
    local paid = gold >= effective_upkeep

    if paid then
        -- Condition improves slowly
        home.attributes.condition = Math.clamp(home.attributes.condition + 1, 0, 100)
        -- Room maintenance
        for _, room in ipairs(home.rooms or {}) do
            room.condition = Math.clamp(room.condition + 0.5, 0, 100)
        end
    else
        -- Decay if upkeep is unpaid
        home.attributes.condition = Math.clamp(home.attributes.condition - 8, 0, 100)
        home.attributes.comfort = Math.clamp(home.attributes.comfort - 5, 0, 100)
        -- Rooms decay too
        for _, room in ipairs(home.rooms or {}) do
            room.condition = Math.clamp(room.condition - 3, 0, 100)
        end
        table.insert(lines, string.format("Upkeep for %s FAILED. The structure decays.", home.label))
    end

    -- 2. Natural aging: slow deterioration over time
    if home.age > 120 then -- after 10 years
        home.attributes.condition = Math.clamp(home.attributes.condition - 0.3, 0, 100)
    end

    -- 3. Environmental modifiers (from animals, peril, etc.)
    if env_mods then
        if (env_mods.comfort_delta or 0) ~= 0 then
            home.attributes.comfort = Math.clamp(home.attributes.comfort + env_mods.comfort_delta, 0, 100)
        end
        if (env_mods.decay_delta or 0) > 0 then
            home.attributes.condition = Math.clamp(home.attributes.condition - env_mods.decay_delta, 0, 100)
            table.insert(home.damage_history, { type = "environmental", delta = env_mods.decay_delta, month = home.age })
        end
    end

    -- 4. Comfort recalculation from rooms
    local room_comfort = 0
    local room_count = 0
    for _, room in ipairs(home.rooms or {}) do
        if room.condition > 20 then
            room_comfort = room_comfort + room.comfort_bonus * (room.condition / 100)
            room_count = room_count + 1
        end
    end
    if room_count > 0 then
        -- Rooms contribute up to +20 comfort
        local room_bonus = Math.clamp(room_comfort / room_count, 0, 20)
        home.attributes.comfort = Math.clamp(home.attributes.comfort + room_bonus * 0.05, 0, 100)
    end

    -- 5. Warnings
    if home.attributes.condition < 30 then
        table.insert(lines, "The home is in serious disrepair. Structural collapse is possible.")
    elseif home.attributes.condition < 50 then
        table.insert(lines, "Drafts and leaks are becoming a problem.")
    end

    -- Keep damage history manageable
    while #home.damage_history > 20 do table.remove(home.damage_history, 1) end

    return lines
end

--- Add an upgrade to the home.
function Logic.add_upgrade(home, upgrade)
    table.insert(home.upgrades, upgrade)
    -- Apply upgrade effects
    if upgrade.comfort_bonus then
        home.attributes.comfort = Math.clamp(home.attributes.comfort + upgrade.comfort_bonus, 0, 100)
    end
    if upgrade.condition_bonus then
        home.attributes.condition = Math.clamp(home.attributes.condition + upgrade.condition_bonus, 0, 100)
    end
    if upgrade.upkeep_delta then
        home.upkeep_cost = math.max(1, home.upkeep_cost + upgrade.upkeep_delta)
    end
end

--- Add a room to the home.
function Logic.add_room(home, room)
    table.insert(home.rooms, {
        id = room.id or "room_" .. #home.rooms,
        label = room.label or "New Room",
        condition = room.condition or 100,
        comfort_bonus = room.comfort_bonus or 3,
    })
end

--- Apply direct damage to the home (from raids, disasters, etc.).
function Logic.apply_damage(home, amount, cause)
    home.attributes.condition = Math.clamp(home.attributes.condition - amount, 0, 100)
    table.insert(home.damage_history, { type = cause or "damage", delta = amount, month = home.age })

    -- Damage can destroy rooms
    if amount > 20 then
        for _, room in ipairs(home.rooms or {}) do
            if RNG.chance(amount / 200) then
                room.condition = Math.clamp(room.condition - amount * 0.5, 0, 100)
            end
        end
    end
end

--- Calculate the "Soul" or "Mood" of the house.
function Logic.get_environment_modifier(home)
    local modifier = 0
    modifier = modifier + (home.attributes.comfort - 50) * 0.2
    modifier = modifier + ((home.attributes.luxury or 50) - 50) * 0.1
    if home.attributes.condition < 50 then
        modifier = modifier - (50 - home.attributes.condition) * 0.5
    end
    -- Room quality contributes
    for _, room in ipairs(home.rooms or {}) do
        if room.condition > 60 then
            modifier = modifier + 1
        end
    end
    return modifier
end

return Logic
