-- dredwork Rivals — Module Entry
-- Competing houses with named heirs, personality-driven autonomy, succession, and grudges.
-- Ported from Bloodweight's rival_heirs.lua + faction.lua, adapted for event bus.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local EB = require("dredwork_core.entity_bridge")

local Rivals = {}
Rivals.__index = Rivals

function Rivals.init(engine)
    local self = setmetatable({}, Rivals)
    self.engine = engine

    -- Initialize state
    engine.game_state.rivals = {
        houses = {},        -- array of rival house records
        graveyard = {},     -- dead heirs (capped at 30)
    }

    -- Expose rival data
    engine:on("GET_RIVAL_DATA", function(req)
        req.houses = self.engine.game_state.rivals.houses
        req.house_count = #self.engine.game_state.rivals.houses
    end)

    -- Monthly: resource accumulation
    engine:on("NEW_MONTH", function(clock)
        self:tick_monthly(self.engine.game_state, clock)
    end)

    -- Yearly: rival strategy execution, death checks
    engine:on("NEW_YEAR", function(clock)
        self:tick_yearly(self.engine.game_state, clock)
    end)

    -- Generational: succession, grudge decay
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick_generational(self.engine.game_state, context)
    end)

    return self
end

--------------------------------------------------------------------------------
-- Rival House Management
--------------------------------------------------------------------------------

--- Create a rival house.
---@param spec table { name, motto, personality, power, disposition, region_id }
---@return table house
function Rivals:create_house(spec)
    local house = {
        id = "house_" .. (spec.name or "unknown"):lower():gsub("%s", "_"),
        name = spec.name or "Unknown House",
        motto = spec.motto or "",
        status = "active",
        power = Math.clamp(spec.power or RNG.range(30, 70), 0, 100),
        disposition = Math.clamp(spec.disposition or RNG.range(-30, 30), -100, 100),
        region_id = spec.region_id,

        -- Faction personality (8 axes, same as characters)
        personality = spec.personality or {
            PER_BLD = RNG.range(30, 70), PER_CRM = RNG.range(30, 70),
            PER_OBS = RNG.range(30, 70), PER_LOY = RNG.range(30, 70),
            PER_CUR = RNG.range(30, 70), PER_VOL = RNG.range(30, 70),
            PER_PRI = RNG.range(30, 70), PER_ADA = RNG.range(30, 70),
        },

        -- Current heir
        heir = nil,

        -- Resources
        resources = { gold = RNG.range(50, 150), steel = RNG.range(10, 40) },

        -- Grudges (max 3)
        grudges = {},

        -- Interaction history
        history = {},

        -- Generations since neutral disposition
        neutral_stagnation = 0,
    }

    -- Shadow house as faction entity
    house.entity_id = EB.register(self.engine, {
        type = "faction", name = house.name,
        components = {
            faction = { power = house.power, disposition = house.disposition, motto = house.motto },
            location = { region_id = house.region_id },
        },
        tags = { "rival_house" },
    })

    -- Generate initial heir
    house.heir = self:_generate_heir(house, nil)

    table.insert(self.engine.game_state.rivals.houses, house)
    self.engine.log:info("Rivals: %s established with heir %s.", house.name, house.heir.name)
    return house
end

--- Generate an heir for a house.
function Rivals:_generate_heir(house, predecessor)
    local names = require("dredwork_core.names")
    local personality = {}

    -- Inherit from faction personality with drift
    for axis, base in pairs(house.personality) do
        personality[axis] = Math.clamp(base + RNG.range(-10, 10), 0, 100)
    end

    -- If predecessor exists, blend toward predecessor
    if predecessor and predecessor.personality then
        for axis, val in pairs(predecessor.personality) do
            personality[axis] = Math.clamp(
                math.floor((personality[axis] + val) / 2) + RNG.range(-5, 5),
                0, 100
            )
        end
    end

    local heir = {
        name = names.character(),
        house_id = house.id,
        house_name = house.name,
        personality = personality,
        alive = true,
        age = 0, -- in years, ticked yearly
        attitude = nil, -- computed
        rivalry_score = predecessor and math.floor((predecessor.rivalry_score or 0) * 0.5) or 0,
        generation_born = self.engine.game_state.clock and self.engine.game_state.clock.generation or 0,
    }

    heir.attitude = self:_compute_attitude(house.disposition, heir.personality)

    -- Shadow as entity
    heir.entity_id = EB.register(self.engine, {
        type = "person", name = heir.name,
        components = {
            personality = personality,
            mortality = { age = 0, max_age = RNG.range(55, 75) },
            location = { region_id = house.region_id },
        },
        tags = { "rival_heir", house.id },
    })
    if house.entity_id and heir.entity_id then
        EB.relate(self.engine, heir.entity_id, house.entity_id, "leads", 80)
    end

    return heir
end

--- Compute attitude string from disposition + personality.
function Rivals:_compute_attitude(disposition, personality)
    local cruelty = personality.PER_CRM or 50
    local pride = personality.PER_PRI or 50
    local loyalty = personality.PER_LOY or 50

    local score = disposition - (cruelty - 50) * 0.3 - (pride - 50) * 0.2 + (loyalty - 50) * 0.1

    if score < -40 then return "hostile"
    elseif score < -10 then return "wary"
    elseif score < 20 then return "neutral"
    elseif score < 50 then return "respectful"
    else return "devoted" end
end

--------------------------------------------------------------------------------
-- Grudge System
--------------------------------------------------------------------------------

--- Add a grudge to a house (max 3, replaces weakest).
function Rivals:add_grudge(house, reason, intensity)
    intensity = intensity or 30
    local grudge = {
        reason = reason,
        intensity = Math.clamp(intensity, 0, 100),
        created_day = self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0,
    }

    if #house.grudges >= 3 then
        -- Replace weakest
        local min_idx, min_val = 1, 999
        for i, g in ipairs(house.grudges) do
            if g.intensity < min_val then min_idx, min_val = i, g.intensity end
        end
        if intensity > min_val then
            house.grudges[min_idx] = grudge
        end
    else
        table.insert(house.grudges, grudge)
    end
end

--------------------------------------------------------------------------------
-- Monthly Tick: Resource Accumulation
--------------------------------------------------------------------------------

function Rivals:tick_monthly(gs, clock)
    for _, house in ipairs(gs.rivals.houses) do
        if house.status ~= "active" then goto continue end

        -- Passive resource gain based on power
        house.resources.gold = house.resources.gold + math.floor(house.power * 0.05)
        house.resources.steel = house.resources.steel + math.floor(house.power * 0.02)

        ::continue::
    end
end

--------------------------------------------------------------------------------
-- Yearly Tick: Strategy, Aging, Death
--------------------------------------------------------------------------------

function Rivals:tick_yearly(gs, clock)
    for _, house in ipairs(gs.rivals.houses) do
        if house.status ~= "active" or not house.heir or not house.heir.alive then goto continue end

        house.heir.age = house.heir.age + 1
        house.heir.attitude = self:_compute_attitude(house.disposition, house.heir.personality)

        -- Execute rival strategy based on attitude
        self:_execute_strategy(house, gs)

        -- Death check (age-based)
        local death_chance = 0
        if house.heir.age >= 60 then death_chance = 0.25
        elseif house.heir.age >= 45 then death_chance = 0.10
        elseif house.heir.age >= 30 then death_chance = 0.03
        end

        -- Modifiers
        if house.heir.attitude == "hostile" then death_chance = death_chance + 0.05 end
        if house.power <= 30 then death_chance = death_chance + 0.05 end

        if death_chance > 0 and RNG.chance(death_chance) then
            self:_kill_heir(house, gs)
        end

        ::continue::
    end

    -- INTER-RIVAL CONFLICT: Rivals fight each other
    self:_tick_inter_rival(gs, clock)
end

--- Simulate conflict between rival houses.
function Rivals:_tick_inter_rival(gs, clock)
    local houses = gs.rivals.houses
    if not houses or #houses < 2 then return end

    for i = 1, #houses do
        local aggressor = houses[i]
        if aggressor.status ~= "active" or not aggressor.heir or not aggressor.heir.alive then goto skip end

        -- Only aggressive houses pick fights
        if aggressor.heir.attitude ~= "hostile" and aggressor.heir.attitude ~= "wary" then goto skip end
        if aggressor.resources.steel < 10 then goto skip end
        if not RNG.chance(0.15) then goto skip end

        -- Pick a target (different house, not devoted to them)
        local targets = {}
        for j = 1, #houses do
            if j ~= i and houses[j].status == "active" then
                table.insert(targets, houses[j])
            end
        end
        if #targets == 0 then goto skip end
        local target = RNG.pick(targets)

        -- Conflict!
        aggressor.resources.steel = aggressor.resources.steel - 10
        local aggressor_power = aggressor.power + RNG.range(-10, 10)
        local target_power = target.power + RNG.range(-10, 10)

        if aggressor_power > target_power then
            -- Aggressor wins: steals resources, gains power
            local loot = RNG.range(10, 25)
            aggressor.resources.gold = aggressor.resources.gold + loot
            target.resources.gold = math.max(0, target.resources.gold - loot)
            aggressor.power = Math.clamp(aggressor.power + 3, 10, 100)
            target.power = Math.clamp(target.power - 5, 10, 100)

            local event = {
                type = "rival_vs_rival",
                aggressor = aggressor.name,
                target = target.name,
                winner = aggressor.name,
                text = string.format("%s has raided %s and seized their resources!", aggressor.name, target.name),
            }
            self.engine:emit("RIVAL_CONFLICT", event)
            self.engine:push_ui_event("RIVAL_CONFLICT", event)

            -- Add grudge
            self:add_grudge(target, "raided by " .. aggressor.name, RNG.range(20, 40))
        else
            -- Target repels the attack
            aggressor.power = Math.clamp(aggressor.power - 3, 10, 100)
            target.power = Math.clamp(target.power + 2, 10, 100)

            local event = {
                type = "rival_vs_rival",
                aggressor = aggressor.name,
                target = target.name,
                winner = target.name,
                text = string.format("%s attacked %s but was repelled!", aggressor.name, target.name),
            }
            self.engine:emit("RIVAL_CONFLICT", event)
            self.engine:push_ui_event("RIVAL_CONFLICT", event)
        end

        -- Weak houses can fall
        if target.power <= 15 and target.resources.gold <= 0 then
            target.status = "fallen"
            local event = {
                type = "rival_fallen",
                house = target.name,
                conqueror = aggressor.name,
                text = string.format("%s has been destroyed by %s! A great house falls.", target.name, aggressor.name),
            }
            self.engine:emit("RIVAL_FALLEN", event)
            self.engine:push_ui_event("RIVAL_FALLEN", event)

            -- Absorb power
            aggressor.power = Math.clamp(aggressor.power + 15, 10, 100)
        end

        ::skip::
    end
end

--- Execute a rival house's strategy based on their heir's attitude.
function Rivals:_execute_strategy(house, gs)
    local attitude = house.heir.attitude
    local heir_name = house.heir.name

    -- Hostile: raid player
    if attitude == "hostile" and house.resources.steel >= 15 and RNG.chance(0.25) then
        house.resources.steel = house.resources.steel - 15

        -- Damage player resources
        local econ = self.engine:get_module("economy")
        if econ then econ:change_wealth(-RNG.range(20, 50)) end

        -- Damage legitimacy
        self.engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = -3 })

        local event = {
            type = "rival_raid",
            house = house.name,
            heir = heir_name,
            text = string.format("%s of %s has raided our holdings!", heir_name, house.name),
        }
        self.engine:emit("RIVAL_ACTION", event)
        self.engine:push_ui_event("RIVAL_ACTION", event)

        -- Add to history
        table.insert(house.history, {
            day = gs.clock and gs.clock.total_days or 0,
            type = "raid",
            text = heir_name .. " launched a raid.",
        })

        -- Create grudge trigger for player
        self:add_grudge(house, "unprovoked raid", 40)
        return
    end

    -- Wary: demand tribute
    if attitude == "wary" and RNG.chance(0.15) then
        local event = {
            type = "rival_demand",
            house = house.name,
            heir = heir_name,
            cost = 10,
            text = string.format("%s of %s demands tribute to maintain the peace.", heir_name, house.name),
        }
        self.engine:emit("RIVAL_ACTION", event)
        self.engine:push_ui_event("RIVAL_ACTION", event)
        return
    end

    -- Devoted: gift
    if attitude == "devoted" and RNG.chance(0.20) then
        local econ = self.engine:get_module("economy")
        if econ then econ:change_wealth(RNG.range(15, 30)) end

        local event = {
            type = "rival_gift",
            house = house.name,
            heir = heir_name,
            text = string.format("%s of %s sends a generous gift as a show of support.", heir_name, house.name),
        }
        self.engine:emit("RIVAL_ACTION", event)
        self.engine:push_ui_event("RIVAL_ACTION", event)

        -- Improve disposition
        house.disposition = Math.clamp(house.disposition + 3, -100, 100)
        return
    end
end

--- Kill a rival heir and trigger succession.
function Rivals:_kill_heir(house, gs)
    local dead = house.heir
    dead.alive = false
    dead.generation_died = gs.clock and gs.clock.generation or 0
    EB.unregister(self.engine, dead.entity_id)

    -- Move to graveyard
    table.insert(gs.rivals.graveyard, dead)
    while #gs.rivals.graveyard > 30 do table.remove(gs.rivals.graveyard, 1) end

    -- Death causes
    local causes = {"fell in battle", "succumbed to illness", "was assassinated", "died of old age", "perished in a duel"}
    local cause = dead.age >= 50 and "died of old age" or RNG.pick(causes)

    local event = {
        type = "rival_death",
        house = house.name,
        heir = dead.name,
        cause = cause,
        text = string.format("%s of %s %s.", dead.name, house.name, cause),
    }
    self.engine:emit("RIVAL_DEATH", event)
    self.engine:push_ui_event("RIVAL_DEATH", event)

    -- Generate successor
    house.heir = self:_generate_heir(house, dead)

    local succession_event = {
        type = "rival_succession",
        house = house.name,
        new_heir = house.heir.name,
        text = string.format("%s now leads %s.", house.heir.name, house.name),
    }
    self.engine:emit("RIVAL_SUCCESSION", succession_event)
    self.engine:push_ui_event("RIVAL_SUCCESSION", succession_event)

    self.engine.log:info("Rivals: %s of %s %s. Succeeded by %s.", dead.name, house.name, cause, house.heir.name)
end

--------------------------------------------------------------------------------
-- Generational Tick: Disposition Drift, Grudge Decay
--------------------------------------------------------------------------------

function Rivals:tick_generational(gs, context)
    for _, house in ipairs(gs.rivals.houses) do
        if house.status ~= "active" then goto continue end

        -- Disposition drift: friendly decays at 10%, hostile at 8%
        if house.disposition > 0 then
            house.disposition = house.disposition - math.floor(house.disposition * 0.10)
        elseif house.disposition < 0 then
            house.disposition = house.disposition - math.floor(house.disposition * 0.08)
        end

        -- Neutral stagnation: if neutral too long, drift hostile
        if math.abs(house.disposition) < 20 then
            house.neutral_stagnation = house.neutral_stagnation + 1
            if house.neutral_stagnation > 6 then
                house.disposition = house.disposition - 2
            end
        else
            house.neutral_stagnation = 0
        end

        -- Grudge decay
        for i = #house.grudges, 1, -1 do
            house.grudges[i].intensity = house.grudges[i].intensity - 2
            if house.grudges[i].intensity <= 0 then
                table.remove(house.grudges, i)
            end
        end

        -- Grudge caps disposition recovery
        for _, grudge in ipairs(house.grudges) do
            local cap = -(grudge.intensity / 2)
            if house.disposition > cap then
                house.disposition = math.floor(cap)
            end
        end

        -- Power drift (random walk)
        house.power = Math.clamp(house.power + RNG.range(-5, 5), 10, 100)

        -- Update heir attitude
        if house.heir and house.heir.alive then
            house.heir.attitude = self:_compute_attitude(house.disposition, house.heir.personality)
        end

        ::continue::
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Shift a house's disposition.
function Rivals:change_disposition(house_id, delta)
    for _, house in ipairs(self.engine.game_state.rivals.houses) do
        if house.id == house_id then
            house.disposition = Math.clamp(house.disposition + delta, -100, 100)
            if house.heir and house.heir.alive then
                house.heir.attitude = self:_compute_attitude(house.disposition, house.heir.personality)
            end
            return true
        end
    end
    return false
end

--- Get a house by ID.
function Rivals:get_house(house_id)
    for _, house in ipairs(self.engine.game_state.rivals.houses) do
        if house.id == house_id then return house end
    end
    return nil
end

--- Record an interaction with a rival house.
function Rivals:record_interaction(house_id, event_type, description, rivalry_delta)
    local house = self:get_house(house_id)
    if not house then return end

    table.insert(house.history, {
        day = self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0,
        type = event_type,
        text = description,
    })

    if house.heir and rivalry_delta then
        house.heir.rivalry_score = Math.clamp((house.heir.rivalry_score or 0) + rivalry_delta, -100, 100)
    end
end

function Rivals:serialize() return self.engine.game_state.rivals end
function Rivals:deserialize(data) self.engine.game_state.rivals = data end

return Rivals
