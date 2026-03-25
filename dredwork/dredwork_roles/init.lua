-- dredwork Roles — Module Entry
-- Entities can hold positions/roles that grant authority, responsibility, and perks.
-- Roles are slots that entities occupy based on competence, personality, relationships, and availability.
-- When a role is vacated (death, betrayal, removal), succession is contested.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local EB = require("dredwork_core.entity_bridge")

local Roles = {}
Roles.__index = Roles

--- Role definitions: what positions exist in the world.
local ROLE_DEFS = {
    ruler         = { id = "ruler",         label = "Ruler",          authority = 100, salary = 0,  requires = {} },
    heir          = { id = "heir",          label = "Heir Apparent",  authority = 80,  salary = 0,  requires = {} },
    general       = { id = "general",       label = "General",        authority = 70,  salary = 15, requires = { PER_BLD = 45 } },
    spymaster     = { id = "spymaster",     label = "Spymaster",      authority = 60,  salary = 12, requires = { PER_OBS = 50 } },
    treasurer     = { id = "treasurer",     label = "Treasurer",      authority = 55,  salary = 10, requires = {} },
    priest        = { id = "priest",        label = "High Priest",    authority = 50,  salary = 5,  requires = {} },
    steward       = { id = "steward",       label = "Steward",        authority = 45,  salary = 8,  requires = { PER_LOY = 45 } },
    ambassador    = { id = "ambassador",    label = "Ambassador",     authority = 40,  salary = 10, requires = { PER_LOY = 40 } },
    judge         = { id = "judge",         label = "Judge",          authority = 50,  salary = 8,  requires = {} },
    master_hunter = { id = "master_hunter", label = "Master of the Hunt", authority = 30, salary = 5, requires = { PER_BLD = 40 } },
}

function Roles.init(engine)
    local self = setmetatable({}, Roles)
    self.engine = engine

    engine.game_state.roles = {
        assignments = {},   -- role_id → entity_id
        history = {},       -- { role_id, entity_id, entity_name, assigned_day, vacated_day, reason }
    }

    -- Expose role data
    engine:on("GET_ROLE_DATA", function(req)
        req.assignments = self.engine.game_state.roles.assignments
        req.available_roles = ROLE_DEFS
    end)

    -- When an entity dies, vacate their roles
    engine:on("ENTITY_DIED", function(ctx)
        if ctx and ctx.entity_id then
            self:vacate_all(ctx.entity_id, "death")
        end
    end)

    engine:on("ENTITY_DESTROYED", function(ctx)
        if ctx and ctx.entity_id then
            self:vacate_all(ctx.entity_id, "removed")
        end
    end)

    -- When a court member is betrayed/removed, vacate their role
    engine:on("COURT_BETRAYAL", function(ctx)
        if ctx and ctx.member and ctx.member.entity_id then
            self:vacate_all(ctx.member.entity_id, "betrayal")
        end
    end)

    return self
end

--------------------------------------------------------------------------------
-- Role Management
--------------------------------------------------------------------------------

--- Assign an entity to a role.
---@return boolean success
---@return string|nil reason
function Roles:assign(role_id, entity_id)
    local role_def = ROLE_DEFS[role_id]
    if not role_def then return false, "unknown role" end

    local entities = self.engine:get_module("entities")
    if not entities then return false, "no entity system" end
    local entity = entities:get(entity_id)
    if not entity or not entity.alive then return false, "entity not found" end

    local gs = self.engine.game_state

    -- Check personality requirements
    local p = entity.components.personality or {}
    for axis, min_val in pairs(role_def.requires) do
        local val = p[axis] or 50
        if type(val) == "table" then val = val.value or 50 end
        if val < min_val then return false, "lacks required " .. axis end
    end

    -- Vacate current holder if any
    local current = gs.roles.assignments[role_id]
    if current then
        self:vacate(role_id, "replaced")
    end

    -- Assign
    gs.roles.assignments[role_id] = entity_id

    -- Set role on entity
    entity.components.role = entity.components.role or {}
    entity.components.role[role_id] = true

    self.engine:emit("ROLE_ASSIGNED", {
        role_id = role_id,
        role_label = role_def.label,
        entity_id = entity_id,
        entity_name = entity.name,
        text = entity.name .. " has been appointed " .. role_def.label .. ".",
    })
    self.engine:push_ui_event("ROLE_ASSIGNED", {
        text = entity.name .. " appointed " .. role_def.label,
    })

    return true
end

--- Vacate a specific role.
function Roles:vacate(role_id, reason)
    local gs = self.engine.game_state
    local entity_id = gs.roles.assignments[role_id]
    if not entity_id then return end

    local entities = self.engine:get_module("entities")
    local entity = entities and entities:get(entity_id)
    local name = entity and entity.name or "?"

    -- Remove role from entity
    if entity and entity.components.role then
        entity.components.role[role_id] = nil
    end

    -- Record history
    table.insert(gs.roles.history, {
        role_id = role_id,
        entity_id = entity_id,
        entity_name = name,
        vacated_day = gs.clock and gs.clock.total_days or 0,
        reason = reason or "unknown",
    })

    gs.roles.assignments[role_id] = nil

    self.engine:emit("ROLE_VACATED", {
        role_id = role_id,
        role_label = ROLE_DEFS[role_id] and ROLE_DEFS[role_id].label or role_id,
        entity_name = name,
        reason = reason,
        text = name .. " has vacated the position of " .. (ROLE_DEFS[role_id] and ROLE_DEFS[role_id].label or role_id) .. ".",
    })
end

--- Vacate all roles held by an entity.
function Roles:vacate_all(entity_id, reason)
    local gs = self.engine.game_state
    for role_id, holder_id in pairs(gs.roles.assignments) do
        if holder_id == entity_id then
            self:vacate(role_id, reason)
        end
    end
end

--- Get who holds a role.
function Roles:get_holder(role_id)
    local entity_id = self.engine.game_state.roles.assignments[role_id]
    if not entity_id then return nil end
    local entities = self.engine:get_module("entities")
    return entities and entities:get(entity_id)
end

--- Get all roles held by an entity.
function Roles:get_entity_roles(entity_id)
    local result = {}
    for role_id, holder_id in pairs(self.engine.game_state.roles.assignments) do
        if holder_id == entity_id then
            table.insert(result, { role_id = role_id, label = ROLE_DEFS[role_id] and ROLE_DEFS[role_id].label or role_id })
        end
    end
    return result
end

--- Find the best candidate for a role from available entities.
function Roles:find_best_candidate(role_id)
    local role_def = ROLE_DEFS[role_id]
    if not role_def then return nil end

    local entities = self.engine:get_module("entities")
    if not entities then return nil end

    local gs = self.engine.game_state
    local candidates = {}

    for _, entity in pairs(gs.entities.registry) do
        if not entity.alive or entity.type ~= "person" then goto skip end

        -- Already holds this role
        if gs.roles.assignments[role_id] == entity.id then goto skip end

        -- Check requirements
        local p = entity.components.personality or {}
        local qualified = true
        for axis, min_val in pairs(role_def.requires) do
            local val = p[axis] or 50
            if type(val) == "table" then val = val.value or 50 end
            if val < min_val then qualified = false; break end
        end
        if not qualified then goto skip end

        -- Score based on competence (from court component or personality)
        local score = 0
        local court = entity.components.court
        if court then score = score + (court.competence or 50) end

        -- Personality alignment
        for axis, _ in pairs(role_def.requires) do
            local val = p[axis] or 50
            if type(val) == "table" then val = val.value or 50 end
            score = score + (val - 50) * 0.3
        end

        -- Relationship strength to focal entity
        local focal_id = gs.entities.focal_entity_id
        if focal_id then
            local rels = entities:get_relationships(entity.id, nil)
            for _, rel in ipairs(rels) do
                if rel.a == focal_id or rel.b == focal_id then
                    score = score + rel.strength * 0.2
                end
            end
        end

        table.insert(candidates, { entity = entity, score = score })
        ::skip::
    end

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b) return a.score > b.score end)
    return candidates[1].entity
end

--- Auto-fill vacant roles (called on generation change or when roles empty).
function Roles:auto_fill()
    local gs = self.engine.game_state
    for role_id, _ in pairs(ROLE_DEFS) do
        if role_id ~= "ruler" and not gs.roles.assignments[role_id] then
            local candidate = self:find_best_candidate(role_id)
            if candidate then
                self:assign(role_id, candidate.id)
            end
        end
    end
end

--- Get role definitions.
function Roles.get_definitions()
    return ROLE_DEFS
end

function Roles:serialize() return self.engine.game_state.roles end
function Roles:deserialize(data) self.engine.game_state.roles = data end

return Roles
