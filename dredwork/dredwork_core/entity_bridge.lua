-- dredwork Core — Entity Bridge
-- Stateless utility for shadowing flat-array objects as entities.
-- Every function is a no-op if the entities module isn't registered.
-- Modules call these inside their existing creation/removal methods.

local Bridge = {}

--- Shadow a flat-array object as an entity.
---@param engine table
---@param spec table { type, name, components, tags }
---@return string|nil entity_id
function Bridge.register(engine, spec)
    local entities = engine:get_module("entities")
    if not entities then return nil end
    local entity = entities:create({
        type = spec.type or "person",
        name = spec.name or "Unknown",
        components = spec.components or {},
        tags = spec.tags or {},
    })
    return entity and entity.id or nil
end

--- Remove entity shadow.
function Bridge.unregister(engine, entity_id)
    if not entity_id then return end
    local entities = engine:get_module("entities")
    if not entities then return end
    entities:destroy(entity_id)
end

--- Create a relationship between two shadowed objects.
function Bridge.relate(engine, a_id, b_id, rel_type, strength)
    if not a_id or not b_id then return end
    local entities = engine:get_module("entities")
    if not entities then return end
    entities:add_relationship(a_id, b_id, rel_type, strength or 50)
end

--- Sync a component on the entity from flat-array data.
function Bridge.sync(engine, entity_id, component_name, data)
    if not entity_id then return end
    local entities = engine:get_module("entities")
    if not entities then return end
    entities:set_component(entity_id, component_name, data)
end

--- Move an entity to a new location.
function Bridge.move(engine, entity_id, region_id)
    if not entity_id then return end
    local entities = engine:get_module("entities")
    if not entities then return end
    entities:move_to(entity_id, region_id)
end

--- Set focal entity.
function Bridge.set_focus(engine, entity_id)
    if not entity_id then return end
    local entities = engine:get_module("entities")
    if not entities then return end
    entities:set_focus(entity_id)
end

--- Get focal entity ID.
function Bridge.get_focus(engine)
    local entities = engine:get_module("entities")
    if not entities then return nil end
    return entities:get_focus_id()
end

return Bridge
