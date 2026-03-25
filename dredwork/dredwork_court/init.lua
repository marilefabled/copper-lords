-- dredwork Court — Module Entry
-- Manages the player's inner circle: advisors, siblings, spouse, elders.
-- Characters have loyalty, competence, and traits. They betray, die, and found cadet branches.
-- Ported from Bloodweight's court.lua, adapted for event bus architecture.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local EB = require("dredwork_core.entity_bridge")

local Court = {}
Court.__index = Court

function Court.init(engine)
    local self = setmetatable({}, Court)
    self.engine = engine

    -- Initialize state
    engine.game_state.court = {
        members = {},
        next_id = 1,
    }

    -- Expose court data via event bus
    engine:on("GET_COURT_DATA", function(req)
        local court = self.engine.game_state.court
        req.member_count = #court.members
        req.members = court.members
        req.loyalty_avg = self:_avg_loyalty()
    end)

    -- Monthly: loyalty drift based on realm health
    engine:on("NEW_MONTH", function(clock)
        self:tick_monthly(self.engine.game_state, clock)
    end)

    -- Yearly: betrayal checks, death chances, boon chances
    engine:on("NEW_YEAR", function(clock)
        self:tick_yearly(self.engine.game_state, clock)
    end)

    -- Generational: major court events
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick_generational(self.engine.game_state)
    end)

    return self
end

--------------------------------------------------------------------------------
-- Court Member Management
--------------------------------------------------------------------------------

--- Add a member to the court.
---@param spec table { name, role, loyalty, competence, traits, genome }
---@return table member
function Court:add_member(spec)
    local court = self.engine.game_state.court
    local member = {
        id = "court_" .. court.next_id,
        name = spec.name or "Unknown",
        role = spec.role or "advisor",  -- advisor, sibling, spouse, elder, general, priest
        loyalty = Math.clamp(spec.loyalty or RNG.range(30, 80), 0, 100),
        competence = Math.clamp(spec.competence or RNG.range(30, 80), 0, 100),
        traits = spec.traits or {},
        genome = spec.genome,
        status = "active",  -- active, exiled, dead
        joined_day = self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0,
    }
    court.next_id = court.next_id + 1
    table.insert(court.members, member)

    -- Shadow as entity
    member.entity_id = EB.register(self.engine, {
        type = "person", name = member.name,
        components = {
            court = { role = member.role, loyalty = member.loyalty, competence = member.competence },
            personality = spec.genome and spec.genome.traits or spec.personality or {},
            location = { region_id = self.engine.game_state.world_map and self.engine.game_state.world_map.current_region_id or nil },
            mortality = { age = spec.age or RNG.range(25, 55), max_age = RNG.range(60, 80) },
        },
        tags = { "court", member.role },
    })
    local focal = EB.get_focus(self.engine)
    if focal and member.entity_id then
        EB.relate(self.engine, focal, member.entity_id, member.role, member.loyalty)
    end

    self.engine.log:info("Court: %s (%s) has joined the court.", member.name, member.role)
    return member
end

--- Remove a member by id.
function Court:remove_member(member_id)
    local court = self.engine.game_state.court
    for i, m in ipairs(court.members) do
        if m.id == member_id then
            EB.unregister(self.engine, m.entity_id)
            m.status = "removed"
            table.remove(court.members, i)
            return m
        end
    end
    return nil
end

--- Get active members by role.
function Court:get_by_role(role)
    local results = {}
    for _, m in ipairs(self.engine.game_state.court.members) do
        if m.status == "active" and m.role == role then
            table.insert(results, m)
        end
    end
    return results
end

--- Get all active members.
function Court:get_active()
    local results = {}
    for _, m in ipairs(self.engine.game_state.court.members) do
        if m.status == "active" then table.insert(results, m) end
    end
    return results
end

--- Generate siblings for the heir.
function Court:generate_siblings(count)
    local names = require("dredwork_core.names")
    for _ = 1, (count or 2) do
        self:add_member({
            name = names.character(nil, RNG.pick({"male", "female"})),
            role = "sibling",
            loyalty = RNG.range(20, 90),
            competence = RNG.range(30, 70),
        })
    end
end

--------------------------------------------------------------------------------
-- Monthly Tick: Loyalty Drift
--------------------------------------------------------------------------------

function Court:tick_monthly(gs, clock)
    -- Query realm health
    local req_pol = { legitimacy = 50, unrest = 0 }
    self.engine:emit("GET_POLITICAL_UNREST_MOD", req_pol)
    local req_econ = { gold = 100 }
    self.engine:emit("GET_ECONOMIC_DATA", req_econ)

    local legitimacy = req_pol.legitimacy or 50
    local gold = req_econ.gold or 100

    for _, member in ipairs(gs.court.members) do
        if member.status == "active" then
            -- Low legitimacy erodes loyalty
            if legitimacy < 30 then
                member.loyalty = member.loyalty - RNG.range(0, 2) / 12
            elseif legitimacy > 70 then
                member.loyalty = member.loyalty + RNG.range(0, 1) / 12
            end

            -- Poverty erodes loyalty
            if gold < 20 then
                member.loyalty = member.loyalty - RNG.range(1, 3) / 12
            end

            member.loyalty = Math.clamp(member.loyalty, 0, 100)
        end
    end
end

--------------------------------------------------------------------------------
-- Yearly Tick: Betrayal, Death, Boons
--------------------------------------------------------------------------------

function Court:tick_yearly(gs, clock)
    local events = {}

    for i = #gs.court.members, 1, -1 do
        local member = gs.court.members[i]
        if member.status ~= "active" then goto continue end

        -- Betrayal check: loyalty < 20, 20% chance per year
        if member.loyalty < 20 and RNG.chance(0.20) then
            member.status = "exiled"
            table.remove(gs.court.members, i)

            local event = {
                type = "court_betrayal",
                member = member,
                text = string.format("%s has betrayed %s and fled into the night.",
                    member.name, gs.lineage_name or "the house"),
            }
            table.insert(events, event)
            self.engine:emit("COURT_BETRAYAL", event)
            self.engine:push_ui_event("COURT_BETRAYAL", event)

            -- Betrayal damages legitimacy
            self.engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = -3 })

            -- Inject scandal rumor
            local rumor = self.engine:get_module("rumor")
            if rumor then
                rumor:inject(gs, {
                    origin_type = "court",
                    subject = member.name,
                    text = member.name .. " has defected from the court. Dark secrets may follow.",
                    heat = 70,
                    tags = { scandal = true, shame = true },
                })
            end

            goto continue
        end

        -- Boon check: loyalty > 80, 15% chance per year
        if member.loyalty > 80 and RNG.chance(0.15) then
            local boon_types = {"gold", "legitimacy", "intelligence"}
            local boon = RNG.pick(boon_types)
            local event = {
                type = "court_boon",
                member = member,
                boon = boon,
                text = string.format("%s, ever loyal, has secured an advantage for the house.", member.name),
            }
            table.insert(events, event)
            self.engine:emit("COURT_BOON", event)

            if boon == "gold" then
                local econ = self.engine:get_module("economy")
                if econ then econ:change_wealth(RNG.range(20, 50)) end
            elseif boon == "legitimacy" then
                self.engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = 2 })
            end
        end

        -- Death check: non-spouse, non-heir. Base 5% per year, higher for elders.
        if member.role ~= "spouse" then
            local death_chance = 0.05
            if member.role == "elder" then death_chance = 0.12 end

            if RNG.chance(death_chance) then
                member.status = "dead"
                table.remove(gs.court.members, i)

                local event = {
                    type = "court_death",
                    member = member,
                    text = string.format("%s has passed away. The court mourns.", member.name),
                }
                table.insert(events, event)
                self.engine:emit("COURT_DEATH", event)
                self.engine:push_ui_event("COURT_DEATH", event)
            end
        end

        ::continue::
    end

    return events
end

--------------------------------------------------------------------------------
-- Generational Tick
--------------------------------------------------------------------------------

function Court:tick_generational(gs)
    -- Elders who survived a full generation gain loyalty
    for _, member in ipairs(gs.court.members) do
        if member.status == "active" and member.role == "elder" then
            member.loyalty = Math.clamp(member.loyalty + 5, 0, 100)
        end
    end
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

function Court:_avg_loyalty()
    local court = self.engine.game_state.court
    if #court.members == 0 then return 50 end
    local sum = 0
    for _, m in ipairs(court.members) do
        if m.status == "active" then sum = sum + m.loyalty end
    end
    return sum / math.max(1, #court.members)
end

function Court:serialize() return self.engine.game_state.court end
function Court:deserialize(data) self.engine.game_state.court = data end

return Court
