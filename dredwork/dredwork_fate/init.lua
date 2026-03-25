-- dredwork Fate — Module Entry
-- What happens when a character is destroyed. Not just death — exile, imprisonment,
-- enslavement, breaking, deposition. Each is a different ending to a different story.
-- And after every ending: "Who do you become next?"
--
-- Fate is the transition engine. It handles the moment between one life and the next.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local EB = require("dredwork_core.entity_bridge")

local Fate = {}
Fate.__index = Fate

--- Fate types — how a character can be destroyed.
local FATE_TYPES = {
    death_combat = {
        id = "death_combat",
        label = "Fallen in Battle",
        final = true,  -- character is gone forever
        text_pool = {
            "Steel found flesh. The world tilted. Then nothing.",
            "You fought. It wasn't enough. The last thing you saw was the sky.",
            "They were faster. Or luckier. It doesn't matter now.",
        },
    },
    death_disease = {
        id = "death_disease",
        label = "Claimed by Sickness",
        final = true,
        text_pool = {
            "The fever took everything slowly. First the strength. Then the clarity. Then the rest.",
            "You fought it. For weeks, for months. In the end, the body decides, not the will.",
            "The healer's face told you everything. The medicine stopped working days ago.",
        },
    },
    death_assassination = {
        id = "death_assassination",
        label = "Assassinated",
        final = true,
        text_pool = {
            "A shadow. A blade. A breath that never came. Someone paid for this.",
            "You never saw them. That was the point. The last thing you felt was surprise.",
            "Poison. The wine tasted wrong but you were too tired to care. A mistake.",
        },
    },
    death_old_age = {
        id = "death_old_age",
        label = "Passed Peacefully",
        final = true,
        text_pool = {
            "Sleep came, and did not leave. After everything, the end was gentle.",
            "You closed your eyes and the weight lifted. All of it. At once.",
            "The fire burned low. The room grew quiet. And then — peace.",
        },
    },
    death_squalor = {
        id = "death_squalor",
        label = "Perished in Squalor",
        final = true,
        text_pool = {
            "Cold. Hunger. Neglect. The world forgot you before you left it.",
            "Nobody came. Nobody checked. The end was not dramatic. It was nothing at all.",
        },
    },
    exile = {
        id = "exile",
        label = "Exiled",
        final = false,  -- character lives but is displaced
        text_pool = {
            "The gates closed behind you. Everything you built, everyone you knew — gone. You walk.",
            "They didn't kill you. That was either mercy or cruelty. You haven't decided which.",
            "A bag of coins and a horse. That's what your life here was worth. The road stretches ahead.",
        },
    },
    imprisoned = {
        id = "imprisoned",
        label = "Imprisoned",
        final = false,
        text_pool = {
            "The cell is small. The walls are damp. Time moves differently here.",
            "The door closed. The key turned. And the world continued without you.",
            "Darkness. Stone. The sound of dripping water and your own breathing. That's all there is now.",
        },
    },
    enslaved = {
        id = "enslaved",
        label = "Enslaved",
        final = false,
        text_pool = {
            "They took your name. They took your choices. What's left is a body that obeys.",
            "The collar is cold against your skin. You had a life once. You remember pieces.",
            "You belong to someone now. The thought doesn't fit anywhere inside you.",
        },
    },
    broken = {
        id = "broken",
        label = "Broken",
        final = false,
        text_pool = {
            "You're alive. You think. The person you were is somewhere far away. You can't reach them.",
            "Nothing matters. Not the pain, not the loss, not the sunrise. Nothing.",
            "You sit. You breathe. That's all you can manage. That's all there is.",
        },
    },
    deposed = {
        id = "deposed",
        label = "Deposed",
        final = false,
        text_pool = {
            "They took the crown. The seal. The chair. You're standing where you once sat. Just standing.",
            "The court bows to someone else now. You watch from the corner. Nobody meets your eyes.",
            "Power left you the way it came — suddenly, completely, and with the sound of doors closing.",
        },
    },
}

function Fate.init(engine)
    local self = setmetatable({}, Fate)
    self.engine = engine

    engine.game_state.fate = {
        current_fate = nil,       -- the active fate (if player is in a fate state)
        transition = nil,         -- the "who do you become?" state
        fate_history = {},        -- past characters and how they ended
    }

    -- Check for "broken" state monthly (all needs critically low)
    engine:on("NEW_MONTH", function(clock)
        self:_check_breaking(self.engine.game_state, clock)
    end)

    -- Listen for death events to trigger fate
    engine:on("HEIR_DIED", function(ctx)
        if ctx then
            local cause = ctx.cause or "fate"
            local fate_id = "death_" .. cause
            if not FATE_TYPES[fate_id] then fate_id = "death_combat" end
            self:trigger(fate_id, ctx.heir_name, ctx)
        end
    end)

    return self
end

--------------------------------------------------------------------------------
-- Fate Trigger
--------------------------------------------------------------------------------

--- Trigger a fate event for the focal character.
---@param fate_type_id string
---@param character_name string|nil
---@param context table|nil extra context
function Fate:trigger(fate_type_id, character_name, context)
    local fate_type = FATE_TYPES[fate_type_id]
    if not fate_type then return end

    local gs = self.engine.game_state
    local day = gs.clock and gs.clock.total_days or 0
    local text = RNG.pick(fate_type.text_pool) or "The end comes."

    local fate = {
        type = fate_type_id,
        label = fate_type.label,
        final = fate_type.final,
        character_name = character_name or "Unknown",
        text = text,
        day = day,
        context = context,
    }

    gs.fate.current_fate = fate

    -- Record in history
    table.insert(gs.fate.fate_history, {
        character_name = fate.character_name,
        fate_type = fate_type_id,
        label = fate_type.label,
        day = day,
        final = fate_type.final,
    })

    -- Emit the fate event
    self.engine:emit("FATE_TRIGGERED", fate)
    self.engine:push_ui_event("FATE_TRIGGERED", fate)
    self.engine.log:warn("Fate: %s — %s", fate.character_name, fate.label)

    -- If not final, the character still exists but in an altered state
    if not fate_type.final then
        self:_apply_non_fatal_fate(fate_type_id, gs)
    end

    -- Begin transition: "Who do you become next?"
    self:_begin_transition(gs)
end

--- Apply consequences of non-fatal fates.
function Fate:_apply_non_fatal_fate(fate_id, gs)
    local entities = self.engine:get_module("entities")
    if not entities then return end
    local focal = entities:get_focus()
    if not focal then return end

    if fate_id == "exile" then
        -- Strip all roles
        local roles = self.engine:get_module("roles")
        if roles then roles:vacate_all(focal.id, "exile") end
        -- Move to a random region (away from home)
        local req_geo = { regions = {} }
        self.engine:emit("GET_GEOGRAPHY_DATA", req_geo)
        if req_geo.regions then
            local region_ids = {}
            for rid, _ in pairs(req_geo.regions) do
                if rid ~= (focal.components.location and focal.components.location.region_id) then
                    table.insert(region_ids, rid)
                end
            end
            if #region_ids > 0 then
                entities:move_to(focal.id, RNG.pick(region_ids))
            end
        end
        -- Lose most items
        local inv = focal.components.inventory
        if inv and inv.items then
            local keepsakes = {}
            for _, item in ipairs(inv.items) do
                if item.emotional_weight > 5 then
                    table.insert(keepsakes, item)  -- only keep deeply cherished items
                end
            end
            inv.items = keepsakes
        end
        -- Needs crash
        if focal.components.needs then
            focal.components.needs.belonging = 5
            focal.components.needs.status = 5
            focal.components.needs.comfort = 10
        end

    elseif fate_id == "imprisoned" then
        -- Move to dungeon
        local locations = self.engine:get_module("locations")
        if locations and focal.components.location then
            local region = focal.components.location.region_id
            local dungeon_id = region .. "_dungeon"
            locations:move_entity(focal.id, dungeon_id)
        end
        -- Lose all items
        if focal.components.inventory then focal.components.inventory.items = {} end
        -- Needs crash hard
        if focal.components.needs then
            focal.components.needs.safety = 5
            focal.components.needs.comfort = 5
            focal.components.needs.status = 0
            focal.components.needs.belonging = 10
        end
        -- Strip roles
        local roles = self.engine:get_module("roles")
        if roles then roles:vacate_all(focal.id, "imprisonment") end

    elseif fate_id == "enslaved" then
        -- Lose everything
        if focal.components.inventory then focal.components.inventory.items = {} end
        if focal.components.personal_wealth then focal.components.personal_wealth.gold = 0 end
        -- All needs bottom out
        if focal.components.needs then
            for need, _ in pairs(focal.components.needs) do
                if type(focal.components.needs[need]) == "number" then
                    focal.components.needs[need] = Math.clamp(focal.components.needs[need] - 40, 0, 100)
                end
            end
        end
        local roles = self.engine:get_module("roles")
        if roles then roles:vacate_all(focal.id, "enslavement") end

    elseif fate_id == "broken" then
        -- Character is alive but hollow
        if focal.components.needs then
            focal.components.needs.purpose = 0
            focal.components.needs.comfort = 10
        end
        focal.components.mood = "desperate"

    elseif fate_id == "deposed" then
        -- Lose role but keep possessions and location
        local roles = self.engine:get_module("roles")
        if roles then roles:vacate_all(focal.id, "deposed") end
        if focal.components.needs then
            focal.components.needs.status = 5
            focal.components.needs.purpose = 15
        end
        -- Legitimacy tanks
        self.engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = -20 })
    end
end

--------------------------------------------------------------------------------
-- Breaking Check
--------------------------------------------------------------------------------

function Fate:_check_breaking(gs, clock)
    local entities = self.engine:get_module("entities")
    if not entities then return end
    local focal = entities:get_focus()
    if not focal or not focal.alive then return end
    if gs.fate.current_fate then return end  -- already in a fate state

    local needs = focal.components.needs
    if not needs then return end

    -- All five needs below 15 = broken
    local all_critical = true
    for _, need in ipairs({"safety", "belonging", "purpose", "comfort", "status"}) do
        if (needs[need] or 50) >= 15 then all_critical = false; break end
    end

    if all_critical then
        self:trigger("broken", focal.name)
    end
end

--------------------------------------------------------------------------------
-- Transition: "Who do you become?"
--------------------------------------------------------------------------------

function Fate:_begin_transition(gs)
    local entities = self.engine:get_module("entities")
    if not entities then return end

    -- Build list of candidates the player can become
    local candidates = {}
    local focal_id = gs.entities and gs.entities.focal_entity_id

    for _, entity in pairs(gs.entities.registry) do
        if not entity.alive then goto skip end
        if entity.id == focal_id then goto skip end

        -- Filter: only persons and animals with personality
        if entity.type ~= "person" and entity.type ~= "animal" then goto skip end
        if not entity.components.personality then goto skip end

        -- Score by relationship to the fallen character
        local score = 0
        local rels = entities:get_relationships(entity.id)
        for _, rel in ipairs(rels) do
            if rel.a == focal_id or rel.b == focal_id then
                score = score + rel.strength
            end
        end

        -- Role makes them more interesting
        local roles_mod = self.engine:get_module("roles")
        if roles_mod then
            local held = roles_mod:get_entity_roles(entity.id)
            score = score + #held * 20
        end

        -- Proximity to the fallen character's location
        local focal_entity = entities:get(focal_id)
        if focal_entity and focal_entity.components.location and entity.components.location then
            if focal_entity.components.location.region_id == entity.components.location.region_id then
                score = score + 30
            end
        end

        table.insert(candidates, {
            entity = entity,
            score = score,
            relationship = score > 50 and "close" or (score > 20 and "acquaintance" or "stranger"),
        })

        ::skip::
    end

    -- Sort by score (most connected first)
    table.sort(candidates, function(a, b) return a.score > b.score end)

    -- Cap at 8 candidates
    while #candidates > 8 do table.remove(candidates) end

    gs.fate.transition = {
        candidates = candidates,
        text = "A life has ended. But the world does not stop. Who will you become?",
    }

    self.engine:emit("FATE_TRANSITION", gs.fate.transition)
    self.engine:push_ui_event("FATE_TRANSITION", gs.fate.transition)
end

--- Player selects who to become.
function Fate:become(entity_id)
    local gs = self.engine.game_state
    local entities = self.engine:get_module("entities")
    if not entities then return end

    local entity = entities:get(entity_id)
    if not entity or not entity.alive then return end

    -- Set as new focal entity
    entities:set_focus(entity_id)

    -- Initialize components if missing
    if not entity.components.signal_affinity then
        local Aff = require("dredwork_signals.affinity")
        local role = nil
        local roles_mod = self.engine:get_module("roles")
        if roles_mod then
            local held = roles_mod:get_entity_roles(entity_id)
            if #held > 0 then role = held[1].role_id end
        end
        entity.components.signal_affinity = Aff.create(entity.components.personality, role)
    end
    if not entity.components.memory then
        local MemLib = require("dredwork_agency.memory")
        entity.components.memory = MemLib.create()
    end
    if not entity.components.needs then
        local NeedsLib = require("dredwork_agency.needs")
        entity.components.needs = NeedsLib.create()
    end
    if not entity.components.secrets then
        local SecretsLib = require("dredwork_agency.secrets")
        entity.components.secrets = SecretsLib.create()
    end
    if not entity.components.inventory then
        entity.components.inventory = { items = {}, capacity = 10 }
    end
    if not entity.components.personal_wealth then
        local WealthLib = require("dredwork_agency.wealth")
        entity.components.personal_wealth = WealthLib.create(RNG.range(5, 30))
    end

    -- Calculate initial mood
    local MoodLib = require("dredwork_agency.mood")
    entity.components.mood = MoodLib.calculate(entity)

    -- Clear fate state
    gs.fate.current_fate = nil
    gs.fate.transition = nil

    -- Narrative
    self.engine:emit("FATE_BECAME", {
        entity_id = entity_id,
        entity_name = entity.name,
        entity_type = entity.type,
        text = "You are " .. entity.name .. " now. A new pair of eyes. A new set of scars. The world looks different from here.",
    })
    self.engine:push_ui_event("FATE_BECAME", {
        text = "You are " .. entity.name .. " now.",
    })

    self.engine.log:info("Fate: Player becomes %s (%s)", entity.name, entity.type)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function Fate:get_current_fate() return self.engine.game_state.fate.current_fate end
function Fate:get_transition() return self.engine.game_state.fate.transition end
function Fate:get_history() return self.engine.game_state.fate.fate_history end
function Fate:get_fate_types() return FATE_TYPES end

function Fate:serialize() return self.engine.game_state.fate end
function Fate:deserialize(data) self.engine.game_state.fate = data end

return Fate
