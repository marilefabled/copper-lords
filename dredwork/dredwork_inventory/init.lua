-- dredwork Inventory — Module Entry
-- Personal possessions with history, emotional weight, and utility.
-- Items are not loot — they're artifacts of a life lived.
-- A father's blade. A stolen letter. A ring from a dead lover.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local EB = require("dredwork_core.entity_bridge")

local Inventory = {}
Inventory.__index = Inventory

--- Item categories and what they enable.
local ITEM_TYPES = {
    weapon    = { label = "Weapon",    slots = 1, duel_bonus = true },
    armor     = { label = "Armor",     slots = 1, duel_bonus = true },
    document  = { label = "Document",  slots = 0, leverage = true },
    keepsake  = { label = "Keepsake",  slots = 0, emotional = true },
    key       = { label = "Key",       slots = 0, access = true },
    gift      = { label = "Gift",      slots = 0, social = true },
    tool      = { label = "Tool",      slots = 0, utility = true },
    treasure  = { label = "Treasure",  slots = 0, value = true },
    medicine  = { label = "Medicine",  slots = 0, consumable = true },
    relic     = { label = "Relic",     slots = 0, spiritual = true },
}

function Inventory.init(engine)
    local self = setmetatable({}, Inventory)
    self.engine = engine

    -- Query handler
    engine:on("GET_INVENTORY", function(req)
        if not req.entity_id then return end
        local entities = engine:get_module("entities")
        if not entities then return end
        local entity = entities:get(req.entity_id)
        if entity and entity.components.inventory then
            req.items = entity.components.inventory.items
            req.capacity = entity.components.inventory.capacity
        end
    end)

    -- When an entity dies, their items can be inherited or lost
    engine:on("ENTITY_DIED", function(ctx)
        if not ctx or not ctx.entity_id then return end
        self:_on_death(ctx.entity_id)
    end)

    engine:on("HEIR_DIED", function(ctx)
        -- Heir's items transfer to successor
        local gs = engine.game_state
        if gs.current_heir and gs.current_heir.entity_id then
            self:_on_death(gs.current_heir.entity_id)
        end
    end)

    return self
end

--------------------------------------------------------------------------------
-- Item Creation
--------------------------------------------------------------------------------

--- Create an item.
---@param spec table { type, name, description, origin_entity_id, origin_text, emotional_weight, properties }
---@return table item
function Inventory.create_item(spec)
    return {
        id = (spec.type or "item") .. "_" .. RNG.range(1000, 9999),
        type = spec.type or "keepsake",
        name = spec.name or "Unknown Item",
        description = spec.description or "",
        origin = {
            entity_id = spec.origin_entity_id,
            text = spec.origin_text or "Found.",
            day = spec.day or 0,
        },
        emotional_weight = Math.clamp(spec.emotional_weight or 0, -10, 10),
        -- -10 = deeply painful, 0 = neutral, 10 = deeply cherished
        properties = spec.properties or {},
        -- { duel_bonus = 2, leverage_target = "entity_id", access_location = "region_id", gold_value = 50, ... }
        condition = spec.condition or 100,  -- 0-100, items degrade
    }
end

--- Give an item to an entity.
function Inventory:give(entity_id, item)
    local entities = self.engine:get_module("entities")
    if not entities then return false end
    local entity = entities:get(entity_id)
    if not entity then return false end

    entity.components.inventory = entity.components.inventory or { items = {}, capacity = 10 }
    local inv = entity.components.inventory

    if #inv.items >= inv.capacity then
        return false, "inventory full"
    end

    table.insert(inv.items, item)

    self.engine:emit("ITEM_RECEIVED", {
        entity_id = entity_id,
        entity_name = entity.name,
        item = item,
        text = entity.name .. " receives " .. item.name .. ".",
    })

    return true
end

--- Remove an item from an entity.
function Inventory:remove(entity_id, item_id)
    local entities = self.engine:get_module("entities")
    if not entities then return nil end
    local entity = entities:get(entity_id)
    if not entity or not entity.components.inventory then return nil end

    for i, item in ipairs(entity.components.inventory.items) do
        if item.id == item_id then
            table.remove(entity.components.inventory.items, i)
            self.engine:emit("ITEM_LOST", {
                entity_id = entity_id,
                entity_name = entity.name,
                item = item,
                text = entity.name .. " loses " .. item.name .. ".",
            })
            return item
        end
    end
    return nil
end

--- Transfer an item between entities.
function Inventory:transfer(from_id, to_id, item_id)
    local item = self:remove(from_id, item_id)
    if not item then return false end

    local ok = self:give(to_id, item)
    if not ok then
        -- Put it back
        self:give(from_id, item)
        return false
    end

    self.engine:emit("ITEM_TRANSFERRED", {
        from_id = from_id,
        to_id = to_id,
        item = item,
        text = item.name .. " changes hands.",
    })

    -- Transfer creates/strengthens a bond
    local entities = self.engine:get_module("entities")
    if entities then
        entities:shift_relationship(from_id, to_id, "gift", 5)
    end

    -- Receiving a gift creates a debt in memory
    local to_entity = entities and entities:get(to_id)
    if to_entity and to_entity.components.memory then
        local MemLib = require("dredwork_agency.memory")
        MemLib.add_debt(to_entity.components.memory, from_id, "gifted " .. item.name, item.emotional_weight * 2)
    end

    return true
end

--- Get all items an entity has.
function Inventory:get_items(entity_id)
    local entities = self.engine:get_module("entities")
    if not entities then return {} end
    local entity = entities:get(entity_id)
    if not entity or not entity.components.inventory then return {} end
    return entity.components.inventory.items
end

--- Find a specific item by type on an entity.
function Inventory:find_by_type(entity_id, item_type)
    local items = self:get_items(entity_id)
    for _, item in ipairs(items) do
        if item.type == item_type then return item end
    end
    return nil
end

--- Check if entity has a document about a specific target (for leverage).
function Inventory:has_leverage(entity_id, target_id)
    local items = self:get_items(entity_id)
    for _, item in ipairs(items) do
        if item.type == "document" and item.properties.leverage_target == target_id then
            return true, item
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- Death: Items scatter
--------------------------------------------------------------------------------

function Inventory:_on_death(entity_id)
    local entities = self.engine:get_module("entities")
    if not entities then return end
    local entity = entities:get(entity_id)
    if not entity or not entity.components.inventory then return end

    local items = entity.components.inventory.items
    if #items == 0 then return end

    -- Find heir or closest relative to inherit items
    local related = entities:get_related(entity_id)
    local heir_id = nil
    for _, rel in ipairs(related) do
        if rel.relationship.type == "parent" or rel.relationship.type == "spouse" then
            heir_id = rel.entity.id
            break
        end
    end

    if heir_id then
        -- Transfer all items to heir
        for _, item in ipairs(items) do
            -- Keepsakes gain emotional weight when inherited from the dead
            if item.type == "keepsake" or item.emotional_weight > 3 then
                item.emotional_weight = Math.clamp(item.emotional_weight + 3, -10, 10)
                item.origin.text = "Inherited from " .. (entity.name or "the deceased") .. "."
            end
            self:give(heir_id, item)
        end
    end

    entity.components.inventory.items = {}
end

--------------------------------------------------------------------------------
-- Item Templates (for world_setup and stimulator)
--------------------------------------------------------------------------------

function Inventory.templates()
    return {
        fathers_blade = { type = "weapon", name = "Father's Blade", description = "Nicked, worn, but sharp where it matters.",
            emotional_weight = 7, properties = { duel_bonus = 1 } },
        mothers_ring = { type = "keepsake", name = "Mother's Ring", description = "A simple band. Warm to the touch, always.",
            emotional_weight = 8, properties = {} },
        stolen_ledger = { type = "document", name = "Stolen Ledger", description = "Proof of someone's treachery. Names and numbers.",
            emotional_weight = -2, properties = { leverage_target = nil } },  -- set target when created
        healing_herbs = { type = "medicine", name = "Healing Herbs", description = "Bitter roots that dull pain and speed recovery.",
            emotional_weight = 0, properties = { health_restore = 3 } },
        gold_coins = { type = "treasure", name = "Pouch of Gold", description = "Heavy enough to buy silence or loyalty.",
            emotional_weight = 0, properties = { gold_value = 50 } },
        house_key = { type = "key", name = "House Key", description = "Opens a door that matters.",
            emotional_weight = 2, properties = { access_location = nil } },
        holy_relic = { type = "relic", name = "Holy Relic", description = "The faithful say it glows in darkness.",
            emotional_weight = 5, properties = { zeal_bonus = 3 } },
        love_letter = { type = "keepsake", name = "Love Letter", description = "The ink has faded. The words have not.",
            emotional_weight = 9, properties = {} },
        poison_vial = { type = "tool", name = "Poison Vial", description = "One drop. That's all it takes.",
            emotional_weight = -5, properties = { kill_target = true } },
        map_fragment = { type = "document", name = "Map Fragment", description = "Part of something larger. Where does it lead?",
            emotional_weight = 1, properties = { discovery = true } },
    }
end

function Inventory:serialize() return {} end
function Inventory:deserialize(data) end

return Inventory
