-- dredwork Mortality — Module Entry
-- Death, succession, and the generational loop.
-- The keystone module: when the heir dies, everything resets and cascades.
--
-- Death sources: old age, disease (peril), assassination (crime/rivals),
-- battle (military/conquest), execution (punishment), and random fate.
-- Succession: selects next heir from available candidates (children, siblings, court).
-- Emits events that cascade through every system via The Ripple.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local EB = require("dredwork_core.entity_bridge")

local Mortality = {}
Mortality.__index = Mortality

function Mortality.init(engine)
    local self = setmetatable({}, Mortality)
    self.engine = engine

    engine.game_state.mortality = {
        children = {},          -- potential heirs
        death_log = {},         -- history of deaths
        succession_line = {},   -- ordered candidates
        is_in_regency = false,
    }

    -- Expose mortality data
    engine:on("GET_MORTALITY_DATA", function(req)
        local m = self.engine.game_state.mortality
        req.children_count = #m.children
        req.children = m.children
        req.is_in_regency = m.is_in_regency
    end)

    --------------------------------------------------------------------------
    -- DEATH CHECKS (Monthly — slow accumulation of risk)
    --------------------------------------------------------------------------

    engine:on("NEW_MONTH", function(clock)
        local gs = self.engine.game_state
        local heir = gs.current_heir
        if not heir or heir.is_dead then return end

        local death_chance = 0
        local cause = nil

        -- 1. OLD AGE: exponential risk after 50
        local age = heir.age or 20
        if age >= 70 then
            death_chance = death_chance + 0.03
            cause = cause or "old_age"
        elseif age >= 60 then
            death_chance = death_chance + 0.01
            cause = cause or "old_age"
        elseif age >= 50 then
            death_chance = death_chance + 0.003
            cause = cause or "old_age"
        end

        -- 2. DISEASE: active plague + low medicine tech
        if gs.perils and gs.perils.active then
            for _, p in ipairs(gs.perils.active) do
                if p.category == "disease" then
                    local med_level = 1
                    if gs.technology and gs.technology.fields and gs.technology.fields.medicine then
                        med_level = gs.technology.fields.medicine.level or 1
                    end
                    -- Medicine tech reduces disease death risk
                    local disease_risk = 0.005 / math.max(1, med_level)
                    death_chance = death_chance + disease_risk
                    if disease_risk > 0.002 then cause = cause or "disease" end
                end
            end
        end

        -- 3. ASSASSINATION: high corruption + hostile rivals + low security
        local assassination_risk = 0
        if gs.underworld and gs.underworld.global_corruption > 50 then
            assassination_risk = assassination_risk + 0.002
        end
        if gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude == "hostile" and house.resources.steel > 30 then
                    assassination_risk = assassination_risk + 0.001
                end
            end
        end
        -- Security check reduces risk
        local req_sec = { security_score = 0 }
        engine:emit("GET_REGIONAL_SECURITY", req_sec)
        assassination_risk = assassination_risk / math.max(1, req_sec.security_score / 50)
        if assassination_risk > 0 then
            death_chance = death_chance + assassination_risk
            if assassination_risk > 0.003 then cause = cause or "assassination" end
        end

        -- 4. BATTLE: active conquest with high resistance
        if gs.empire and gs.empire.territories then
            for _, territory in ipairs(gs.empire.territories) do
                if (territory.resistance or 0) > 70 then
                    death_chance = death_chance + 0.002
                    cause = cause or "battle"
                end
            end
        end

        -- 5. HOME CONDITION: living in squalor
        if gs.home and gs.home.attributes then
            if (gs.home.attributes.condition or 50) < 15 then
                death_chance = death_chance + 0.002
                cause = cause or "squalor"
            end
        end

        -- Roll for death
        if death_chance > 0 and RNG.chance(death_chance) then
            self:kill_heir(cause or "fate", gs)
        end
    end)

    --------------------------------------------------------------------------
    -- CHILDREN: Generate potential heirs over time
    --------------------------------------------------------------------------

    engine:on("NEW_YEAR", function(clock)
        local gs = self.engine.game_state
        local heir = gs.current_heir
        if not heir or heir.is_dead then return end

        local age = heir.age or 20
        local m = gs.mortality

        -- Check for spouse
        local has_spouse = false
        if gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" and member.role == "spouse" then
                    has_spouse = true
                    break
                end
            end
        end

        -- Fertility window: 18-45, with spouse
        if has_spouse and age >= 18 and age <= 45 and RNG.chance(0.25) then
            local genetics = engine:get_module("genetics")
            local child_genome = nil
            if genetics then
                child_genome = genetics:create_genome()
            end

            local names = require("dredwork_core.names")
            local child = {
                name = names.character(),
                age = 0,
                genome = child_genome,
                is_dead = false,
                birth_year = clock.year,
                traits = child_genome and child_genome.traits or {},
            }

            -- Shadow as entity
            child.entity_id = EB.register(engine, {
                type = "person", name = child.name,
                components = {
                    mortality = { age = 0, max_age = RNG.range(60, 80) },
                    personality = child_genome and child_genome.traits or {},
                    location = { region_id = gs.world_map and gs.world_map.current_region_id or nil },
                },
                tags = { "child", "potential_heir" },
            })
            local focal = EB.get_focus(engine)
            if focal and child.entity_id then
                EB.relate(engine, focal, child.entity_id, "parent", 90)
            end

            table.insert(m.children, child)

            engine:emit("CHILD_BORN", {
                child = child,
                parent_name = heir.name,
                text = string.format("A child is born to %s: %s.", heir.name or "the heir", child.name),
            })
            engine:push_ui_event("CHILD_BORN", {
                text = string.format("A child is born: %s.", child.name),
            })

            engine.log:info("Mortality: %s born to %s.", child.name, heir.name or "the heir")
        end

        -- Age existing children
        for _, child in ipairs(m.children) do
            if not child.is_dead then
                child.age = (child.age or 0) + 1

                -- Child mortality (harsh but real)
                if child.age < 5 and RNG.chance(0.03) then
                    child.is_dead = true
                    EB.unregister(engine, child.entity_id)
                    engine:emit("CHILD_DIED", {
                        child = child,
                        text = string.format("Tragedy strikes. Young %s has perished.", child.name),
                    })
                    engine:push_ui_event("CHILD_DIED", {
                        text = string.format("Young %s has perished.", child.name),
                    })
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    -- SUCCESSION (triggered by heir death)
    --------------------------------------------------------------------------

    -- Listen for external kill commands (e.g., from decisions, rivals)
    engine:on("KILL_HEIR", function(ctx)
        local gs = self.engine.game_state
        self:kill_heir(ctx and ctx.cause or "fate", gs)
    end)

    return self
end

--------------------------------------------------------------------------------
-- Kill the Heir
--------------------------------------------------------------------------------

function Mortality:kill_heir(cause, gs)
    local heir = gs.current_heir
    if not heir or heir.is_dead then return end

    heir.is_dead = true

    local cause_text = {
        old_age = "died of old age",
        disease = "succumbed to disease",
        assassination = "was assassinated",
        battle = "fell in battle",
        squalor = "perished in squalor",
        execution = "was executed",
        fate = "met an untimely end",
    }

    local text = string.format("%s %s.", heir.name or "The heir", cause_text[cause] or cause_text.fate)

    -- Record death
    table.insert(gs.mortality.death_log, {
        name = heir.name,
        age = heir.age,
        cause = cause,
        day = gs.clock and gs.clock.total_days or 0,
        generation = gs.clock and gs.clock.generation or 0,
    })

    -- Emit death event (The Ripple will cascade this everywhere)
    local death_event = {
        type = "heir_death",
        cause = cause,
        heir_name = heir.name,
        heir_age = heir.age,
        text = text,
    }
    self.engine:emit("HEIR_DIED", death_event)
    self.engine:push_ui_event("HEIR_DIED", death_event)
    self.engine.log:warn("Mortality: %s", text)

    -- Trigger succession
    self:_run_succession(gs)
end

--------------------------------------------------------------------------------
-- Succession
--------------------------------------------------------------------------------

function Mortality:_run_succession(gs)
    local m = gs.mortality

    -- Build candidate list: living children (oldest first), then siblings from court
    local candidates = {}

    -- Children (oldest first, must be at least 12)
    local living_children = {}
    for _, child in ipairs(m.children) do
        if not child.is_dead and (child.age or 0) >= 12 then
            table.insert(living_children, child)
        end
    end
    table.sort(living_children, function(a, b) return (a.age or 0) > (b.age or 0) end)
    for _, child in ipairs(living_children) do
        table.insert(candidates, { source = "child", person = child })
    end

    -- Siblings from court
    if gs.court then
        for _, member in ipairs(gs.court.members or {}) do
            if member.status == "active" and member.role == "sibling" then
                table.insert(candidates, { source = "sibling", person = member })
            end
        end
    end

    if #candidates == 0 then
        -- No heir available — regency or game over
        m.is_in_regency = true
        self.engine:emit("SUCCESSION_CRISIS", {
            text = "There is no heir. The line is broken. A regency must be established.",
            type = "no_heir",
        })
        self.engine:push_ui_event("SUCCESSION_CRISIS", {
            text = "No heir available. The bloodline faces extinction.",
        })
        self.engine.log:error("Mortality: No succession candidates available!")

        -- Create a distant relative as fallback
        local names = require("dredwork_core.names")
        local genetics = self.engine:get_module("genetics")
        local genome = genetics and genetics:create_genome() or nil
        local fallback = {
            name = names.character(),
            age = RNG.range(20, 35),
            genome = genome,
            traits = genome and genome.traits or {},
            is_dead = false,
        }
        self:_install_heir(fallback, "distant_relative", gs)
        return
    end

    -- Primary candidate
    local primary = candidates[1]
    local contested = #candidates > 1 and candidates[2].source ~= primary.source

    if contested then
        -- Succession is contested — emit crisis for decisions module to handle
        self.engine:emit("SUCCESSION_CONTESTED", {
            candidates = candidates,
            primary = primary,
            text = string.format("The succession is contested. %s claims the seat, but others disagree.",
                primary.person.name or "The eldest"),
        })
        self.engine:push_ui_event("SUCCESSION_CONTESTED", {
            text = "The succession is contested!",
        })
    end

    -- Install the primary candidate (games can override via SUCCESSION_CONTESTED handler)
    self:_install_heir(primary.person, primary.source, gs)
end

--- Install a new heir.
function Mortality:_install_heir(person, source, gs)
    -- Transfer genome/traits to current_heir format
    gs.current_heir = person
    gs.current_heir.is_dead = false
    gs.heir_name = person.name

    -- Shadow as entity and set as focal point
    if not person.entity_id then
        person.entity_id = EB.register(self.engine, {
            type = "person", name = person.name,
            components = {
                personality = person.traits or person.personality or {},
                mortality = { age = person.age or 18, max_age = RNG.range(60, 80) },
                location = { region_id = gs.world_map and gs.world_map.current_region_id or nil },
            },
            tags = { "heir", "player" },
        })
    end
    EB.set_focus(self.engine, person.entity_id)

    -- Reset mortality children (old heir's children become court members or leave)
    local m = gs.mortality
    for _, child in ipairs(m.children) do
        if not child.is_dead and child ~= person then
            -- Add surviving children as court siblings
            local court = self.engine:get_module("court")
            if court and (child.age or 0) >= 12 then
                court:add_member({
                    name = child.name,
                    role = "sibling",
                    loyalty = RNG.range(30, 70),
                    competence = RNG.range(30, 60),
                    genome = child.genome,
                })
            end
        end
    end
    m.children = {}
    m.is_in_regency = false

    -- Recalculate biography
    local biography = self.engine:get_module("biography")
    if biography then biography:recalculate(gs) end

    -- Start new ledger
    local ledger = self.engine:get_module("ledger")
    if ledger then ledger:start(gs) end

    -- Emit succession complete
    local event = {
        type = "succession_complete",
        heir_name = person.name,
        heir_age = person.age,
        source = source,
        text = string.format("%s ascends. A new chapter begins.", person.name or "The heir"),
    }
    self.engine:emit("SUCCESSION_COMPLETE", event)
    self.engine:push_ui_event("SUCCESSION_COMPLETE", event)
    self.engine.log:info("Mortality: %s takes the seat (source: %s).", person.name or "?", source)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Get living children.
function Mortality:get_children()
    local result = {}
    for _, child in ipairs(self.engine.game_state.mortality.children) do
        if not child.is_dead then table.insert(result, child) end
    end
    return result
end

--- Get the death log.
function Mortality:get_death_log()
    return self.engine.game_state.mortality.death_log
end

--- Force kill the heir (for external systems).
function Mortality:force_kill(cause)
    self:kill_heir(cause or "fate", self.engine.game_state)
end

function Mortality:serialize() return self.engine.game_state.mortality end
function Mortality:deserialize(data) self.engine.game_state.mortality = data end

return Mortality
