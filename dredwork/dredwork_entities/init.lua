-- dredwork Entities — Module Entry
-- Universal entity registry. Every person, animal, unit, faction, and place is an entity.
-- Entities have composable components and relationships to other entities.
-- The simulation doesn't know who the player is watching — every entity is first-class.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Entities = {}
Entities.__index = Entities

function Entities.init(engine)
    local self = setmetatable({}, Entities)
    self.engine = engine

    engine.game_state.entities = {
        registry = {},          -- id → entity
        relationships = {},     -- array of { a, b, type, strength, data }
        next_id = 1,
        focal_entity_id = nil,  -- who the player is watching
        type_index = {},        -- type → { id, id, ... } for fast queries
        location_index = {},    -- region_id → { id, id, ... }
    }

    -- Query handlers
    engine:on("GET_ENTITY", function(req)
        if req.id then
            req.entity = self:get(req.id)
        end
    end)

    engine:on("GET_ENTITIES_BY_TYPE", function(req)
        req.entities = self:find_by_type(req.entity_type or "person")
    end)

    engine:on("GET_ENTITIES_AT_LOCATION", function(req)
        req.entities = self:find_at_location(req.region_id)
    end)

    engine:on("GET_RELATIONSHIPS", function(req)
        req.relationships = self:get_relationships(req.entity_id, req.rel_type)
    end)

    engine:on("GET_FOCAL_ENTITY", function(req)
        local es = self.engine.game_state.entities
        req.focal_id = es.focal_entity_id
        req.focal = es.focal_entity_id and es.registry[es.focal_entity_id] or nil
    end)

    -- Yearly: age all mortal entities
    engine:on("NEW_YEAR", function(clock)
        self:_tick_aging(clock)
    end)

    return self
end

--------------------------------------------------------------------------------
-- Entity CRUD
--------------------------------------------------------------------------------

--- Create a new entity.
---@param spec table { type, name, components }
---@return table entity
function Entities:create(spec)
    local es = self.engine.game_state.entities
    local id = "e_" .. es.next_id
    es.next_id = es.next_id + 1

    local entity = {
        id = id,
        type = spec.type or "person",   -- person, animal, unit, faction, place
        name = spec.name or "Unknown",
        alive = true,
        components = spec.components or {},
        tags = spec.tags or {},
        created_day = self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0,
    }

    es.registry[id] = entity

    -- Update type index
    es.type_index[entity.type] = es.type_index[entity.type] or {}
    table.insert(es.type_index[entity.type], id)

    -- Update location index
    if entity.components.location and entity.components.location.region_id then
        local region = entity.components.location.region_id
        es.location_index[region] = es.location_index[region] or {}
        table.insert(es.location_index[region], id)
    end

    self.engine:emit("ENTITY_CREATED", { entity = entity })
    return entity
end

--- Get an entity by ID.
function Entities:get(id)
    return self.engine.game_state.entities.registry[id]
end

--- Remove an entity.
function Entities:destroy(id)
    local es = self.engine.game_state.entities
    local entity = es.registry[id]
    if not entity then return end

    entity.alive = false

    -- Remove from type index
    local type_list = es.type_index[entity.type]
    if type_list then
        for i, eid in ipairs(type_list) do
            if eid == id then table.remove(type_list, i); break end
        end
    end

    -- Remove from location index
    if entity.components.location then
        local region = entity.components.location.region_id
        local loc_list = es.location_index[region]
        if loc_list then
            for i, eid in ipairs(loc_list) do
                if eid == id then table.remove(loc_list, i); break end
            end
        end
    end

    -- Remove relationships
    for i = #es.relationships, 1, -1 do
        local rel = es.relationships[i]
        if rel.a == id or rel.b == id then
            table.remove(es.relationships, i)
        end
    end

    self.engine:emit("ENTITY_DESTROYED", { entity_id = id, entity_name = entity.name })
end

--- Find entities by type.
function Entities:find_by_type(entity_type)
    local es = self.engine.game_state.entities
    local ids = es.type_index[entity_type] or {}
    local result = {}
    for _, id in ipairs(ids) do
        local e = es.registry[id]
        if e and e.alive then table.insert(result, e) end
    end
    return result
end

--- Find entities at a location.
function Entities:find_at_location(region_id)
    local es = self.engine.game_state.entities
    local ids = es.location_index[region_id] or {}
    local result = {}
    for _, id in ipairs(ids) do
        local e = es.registry[id]
        if e and e.alive then table.insert(result, e) end
    end
    return result
end

--- Find entity by name (first match).
function Entities:find_by_name(name)
    for _, entity in pairs(self.engine.game_state.entities.registry) do
        if entity.alive and entity.name == name then return entity end
    end
    return nil
end

--- Get all living entities.
function Entities:get_all_alive()
    local result = {}
    for _, entity in pairs(self.engine.game_state.entities.registry) do
        if entity.alive then table.insert(result, entity) end
    end
    return result
end

--- Move an entity to a new location.
function Entities:move_to(entity_id, region_id)
    local es = self.engine.game_state.entities
    local entity = es.registry[entity_id]
    if not entity then return end

    -- Remove from old location index
    local old_region = entity.components.location and entity.components.location.region_id
    if old_region and es.location_index[old_region] then
        for i, eid in ipairs(es.location_index[old_region]) do
            if eid == entity_id then table.remove(es.location_index[old_region], i); break end
        end
    end

    -- Set new location
    entity.components.location = entity.components.location or {}
    entity.components.location.region_id = region_id

    -- Add to new location index
    es.location_index[region_id] = es.location_index[region_id] or {}
    table.insert(es.location_index[region_id], entity_id)

    self.engine:emit("ENTITY_MOVED", { entity_id = entity_id, from = old_region, to = region_id })
end

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

--- Get a component from an entity.
function Entities:get_component(entity_id, component_name)
    local entity = self:get(entity_id)
    if not entity then return nil end
    return entity.components[component_name]
end

--- Set a component on an entity.
function Entities:set_component(entity_id, component_name, data)
    local entity = self:get(entity_id)
    if not entity then return end
    entity.components[component_name] = data
end

--- Check if an entity has a component.
function Entities:has_component(entity_id, component_name)
    local entity = self:get(entity_id)
    return entity and entity.components[component_name] ~= nil
end

--------------------------------------------------------------------------------
-- Relationships
--------------------------------------------------------------------------------

--- Add a relationship between two entities.
---@param a_id string
---@param b_id string
---@param rel_type string e.g. "loyalty", "parent", "owner_pet", "commands", "rival", "spouse", "sibling"
---@param strength number 0-100
---@param data table|nil extra data
function Entities:add_relationship(a_id, b_id, rel_type, strength, data)
    local es = self.engine.game_state.entities
    -- Check for existing relationship of same type
    for _, rel in ipairs(es.relationships) do
        if rel.a == a_id and rel.b == b_id and rel.type == rel_type then
            rel.strength = Math.clamp(strength or rel.strength, 0, 100)
            if data then rel.data = data end
            return rel
        end
    end

    local rel = {
        a = a_id,
        b = b_id,
        type = rel_type,
        strength = Math.clamp(strength or 50, 0, 100),
        data = data,
        created_day = self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0,
    }
    table.insert(es.relationships, rel)
    return rel
end

--- Get all relationships for an entity (optionally filtered by type).
function Entities:get_relationships(entity_id, rel_type)
    local es = self.engine.game_state.entities
    local result = {}
    for _, rel in ipairs(es.relationships) do
        if (rel.a == entity_id or rel.b == entity_id) then
            if not rel_type or rel.type == rel_type then
                table.insert(result, rel)
            end
        end
    end
    return result
end

--- Get the other entity in a relationship.
function Entities:get_related(entity_id, rel_type)
    local rels = self:get_relationships(entity_id, rel_type)
    local result = {}
    for _, rel in ipairs(rels) do
        local other_id = rel.a == entity_id and rel.b or rel.a
        local other = self:get(other_id)
        if other and other.alive then
            table.insert(result, { entity = other, relationship = rel })
        end
    end
    return result
end

--- Shift relationship strength.
function Entities:shift_relationship(a_id, b_id, rel_type, delta)
    local es = self.engine.game_state.entities
    for _, rel in ipairs(es.relationships) do
        if rel.a == a_id and rel.b == b_id and rel.type == rel_type then
            rel.strength = Math.clamp(rel.strength + delta, 0, 100)
            return rel
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Focal Point
--------------------------------------------------------------------------------

--- Set which entity the player is watching.
function Entities:set_focus(entity_id)
    self.engine.game_state.entities.focal_entity_id = entity_id
    self.engine:emit("FOCAL_ENTITY_CHANGED", {
        entity_id = entity_id,
        entity = self:get(entity_id),
    })
    self.engine:push_ui_event("FOCAL_ENTITY_CHANGED", {
        entity_id = entity_id,
        text = "Focus shifted to " .. (self:get(entity_id) and self:get(entity_id).name or "?"),
    })
end

--- Get the focal entity.
function Entities:get_focus()
    local es = self.engine.game_state.entities
    return es.focal_entity_id and es.registry[es.focal_entity_id] or nil
end

--- Get the focal entity ID.
function Entities:get_focus_id()
    return self.engine.game_state.entities.focal_entity_id
end

--------------------------------------------------------------------------------
-- Aging (for all mortal entities)
--------------------------------------------------------------------------------

function Entities:_tick_aging(clock)
    for _, entity in pairs(self.engine.game_state.entities.registry) do
        if not entity.alive then goto continue end
        local mortality = entity.components.mortality
        if mortality then
            mortality.age = (mortality.age or 0) + 1

            -- Natural death check for non-player entities
            if entity.id ~= self.engine.game_state.entities.focal_entity_id then
                local max_age = mortality.max_age or 80
                if mortality.age > max_age then
                    if RNG.chance(0.3) then
                        entity.alive = false
                        self.engine:emit("ENTITY_DIED", {
                            entity_id = entity.id,
                            entity_name = entity.name,
                            entity_type = entity.type,
                            cause = "old_age",
                            age = mortality.age,
                            text = entity.name .. " has passed away at age " .. mortality.age .. ".",
                        })
                    end
                end
            end
        end
        ::continue::
    end
end

--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------

--- Count entities by type.
function Entities:count_by_type(entity_type)
    local count = 0
    for _, entity in pairs(self.engine.game_state.entities.registry) do
        if entity.alive and entity.type == entity_type then count = count + 1 end
    end
    return count
end

--- Get summary stats.
function Entities:get_summary()
    local counts = {}
    local total = 0
    for _, entity in pairs(self.engine.game_state.entities.registry) do
        if entity.alive then
            counts[entity.type] = (counts[entity.type] or 0) + 1
            total = total + 1
        end
    end
    return { total = total, by_type = counts }
end

function Entities:serialize()
    return self.engine.game_state.entities
end

function Entities:deserialize(data)
    self.engine.game_state.entities = data
end

return Entities
