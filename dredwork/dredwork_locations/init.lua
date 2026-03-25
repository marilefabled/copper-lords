-- dredwork Locations — Module Entry
-- Sub-region points of interest. Characters exist at specific locations within regions.
-- Locations gate interactions, generate encounters, and give the world spatial texture.
-- "At the market" is different from "in the great hall" is different from "on the road."

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local EB = require("dredwork_core.entity_bridge")

local Locations = {}
Locations.__index = Locations

--- Location type definitions: what each type enables.
local LOCATION_TYPES = {
    home = {
        label = "Home",
        tags = { "private", "rest", "domestic" },
        interactions = { "rest", "pray", "scheme", "examine_possessions", "review_secrets", "repair_home", "clean_home", "host_feast" },
        encounter_pool = "domestic",
        ownable = true,
        default_owner_role = "ruler",
        income = 0,
        upkeep = 2,
    },
    court = {
        label = "Court",
        tags = { "political", "social", "public" },
        interactions = { "talk", "propose_alliance", "propose_marriage", "assign_role", "recruit", "exile", "confide", "give_gold", "threaten" },
        encounter_pool = "political",
        ownable = true,
        default_owner_role = "ruler",
        income = 0,
        upkeep = 5,
    },
    market = {
        label = "Market",
        tags = { "trade", "public", "social" },
        interactions = { "talk", "give_gold", "gift_item", "investigate", "spy_on" },
        encounter_pool = "trade",
        ownable = true,
        default_owner_role = "treasurer",
        income = 8,
        upkeep = 3,
        owner_bonus = { hears_trade_rumors = true },
    },
    barracks = {
        label = "Barracks",
        tags = { "military", "training" },
        interactions = { "train", "rally_troops", "inspect_unit", "deploy_unit", "challenge_duel" },
        encounter_pool = "military",
        ownable = true,
        default_owner_role = "general",
        income = 0,
        upkeep = 6,
        owner_bonus = { military_morale = 5 },
    },
    temple = {
        label = "Temple",
        tags = { "spiritual", "sanctuary" },
        interactions = { "pray", "confide", "talk", "mentor" },
        encounter_pool = "spiritual",
        ownable = true,
        default_owner_role = "priest",
        income = 3,
        upkeep = 2,
        owner_bonus = { zeal_influence = true },
    },
    tavern = {
        label = "Tavern",
        tags = { "social", "rumors", "criminal" },
        interactions = { "talk", "scheme", "investigate", "spy_on", "seduce", "blackmail" },
        encounter_pool = "underworld",
        ownable = true,
        default_owner_role = nil,  -- anyone can own a tavern
        income = 5,
        upkeep = 2,
        owner_bonus = { hears_all_rumors = true },
    },
    gate = {
        label = "Gate",
        tags = { "border", "travel", "military" },
        interactions = { "travel_to", "inspect_unit", "fortify_region" },
        encounter_pool = "border",
        ownable = true,
        default_owner_role = "general",
        income = 2,
        upkeep = 4,
        owner_bonus = { controls_access = true },
    },
    wilds = {
        label = "Wilds",
        tags = { "nature", "hunting", "danger" },
        interactions = { "explore", "pet", "feed", "command_hunt", "command_guard", "train" },
        encounter_pool = "wilderness",
        ownable = false,
    },
    dungeon = {
        label = "Dungeon",
        tags = { "dark", "punishment", "secret" },
        interactions = { "investigate", "threaten", "scheme" },
        encounter_pool = "prison",
        ownable = true,
        default_owner_role = "judge",
        income = 0,
        upkeep = 3,
        owner_bonus = { controls_prisoners = true },
    },
    road = {
        label = "Road",
        tags = { "travel", "exposed", "public" },
        interactions = { "travel_to", "explore" },
        encounter_pool = "travel",
        ownable = false,
    },
}

function Locations.init(engine)
    local self = setmetatable({}, Locations)
    self.engine = engine

    engine.game_state.locations = {
        regions = {},  -- region_id → { location_id → location_data }
    }

    -- Query handler
    engine:on("GET_LOCATION_DATA", function(req)
        if req.region_id then
            req.locations = self:get_locations(req.region_id)
        end
        if req.entity_id then
            req.current_location = self:get_entity_location(req.entity_id)
        end
    end)

    -- Expose available interactions for a location
    engine:on("GET_LOCATION_INTERACTIONS", function(req)
        if req.location_type then
            local loc_def = LOCATION_TYPES[req.location_type]
            req.interactions = loc_def and loc_def.interactions or {}
            req.tags = loc_def and loc_def.tags or {}
        end
    end)

    -- Monthly: locations generate income for owners, decay without upkeep
    engine:on("NEW_MONTH", function(clock)
        self:tick_monthly(self.engine.game_state, clock)
    end)

    -- Ownership events
    engine:on("ROLE_ASSIGNED", function(ctx)
        if not ctx then return end
        -- Auto-assign location ownership based on role
        self:_assign_by_role(ctx.role_id, ctx.entity_id)
    end)

    engine:on("ROLE_VACATED", function(ctx)
        if not ctx then return end
        self:_vacate_by_role(ctx.role_id, ctx.entity_id)
    end)

    return self
end

--------------------------------------------------------------------------------
-- Ownership
--------------------------------------------------------------------------------

--- Set the owner of a location.
function Locations:set_owner(location_id, entity_id)
    local loc = self:get_location(location_id)
    if not loc then return false end

    local loc_def = LOCATION_TYPES[loc.type]
    if not loc_def or not loc_def.ownable then return false, "cannot be owned" end

    local old_owner = loc.owner_id
    loc.owner_id = entity_id

    self.engine:emit("LOCATION_OWNERSHIP_CHANGED", {
        location_id = location_id,
        location_label = loc.label,
        location_type = loc.type,
        old_owner = old_owner,
        new_owner = entity_id,
        text = (loc.label or location_id) .. " has a new owner.",
    })
    self.engine:push_ui_event("LOCATION_OWNERSHIP_CHANGED", {
        text = (loc.label or location_id) .. " ownership changed.",
    })

    return true
end

--- Get the owner entity of a location.
function Locations:get_owner(location_id)
    local loc = self:get_location(location_id)
    if not loc or not loc.owner_id then return nil end
    local entities = self.engine:get_module("entities")
    return entities and entities:get(loc.owner_id)
end

--- Seize a location (hostile takeover).
function Locations:seize(location_id, new_owner_id, reason)
    local loc = self:get_location(location_id)
    if not loc then return false end

    local old_owner_id = loc.owner_id
    self:set_owner(location_id, new_owner_id)

    -- Seizure creates grudges
    if old_owner_id then
        local entities = self.engine:get_module("entities")
        if entities then
            local old_owner = entities:get(old_owner_id)
            if old_owner and old_owner.components.memory then
                local MemLib = require("dredwork_agency.memory")
                MemLib.add_grudge(old_owner.components.memory, new_owner_id, "seized " .. (loc.label or "my property"), 50)
            end
        end
    end

    self.engine:emit("LOCATION_SEIZED", {
        location_id = location_id,
        location_label = loc.label,
        old_owner = old_owner_id,
        new_owner = new_owner_id,
        reason = reason or "seized",
        text = (loc.label or location_id) .. " has been seized!",
    })

    -- Rumor about the seizure
    local rumor = self.engine:get_module("rumor")
    if rumor then
        rumor:inject(self.engine.game_state, {
            origin_type = "seizure",
            subject = loc.label or location_id,
            text = (loc.label or "A location") .. " has changed hands by force.",
            heat = 60, tags = { danger = true, scandal = true },
        })
    end

    return true
end

--- Get all locations owned by an entity.
function Locations:get_owned_by(entity_id)
    local result = {}
    for _, region_locs in pairs(self.engine.game_state.locations.regions) do
        for _, loc in pairs(region_locs) do
            if loc.owner_id == entity_id then table.insert(result, loc) end
        end
    end
    return result
end

--- Auto-assign location ownership based on role.
function Locations:_assign_by_role(role_id, entity_id)
    for _, region_locs in pairs(self.engine.game_state.locations.regions) do
        for _, loc in pairs(region_locs) do
            local loc_def = LOCATION_TYPES[loc.type]
            if loc_def and loc_def.default_owner_role == role_id and not loc.owner_id then
                self:set_owner(loc.id, entity_id)
            end
        end
    end
end

--- Vacate ownership when a role is lost.
function Locations:_vacate_by_role(role_id, entity_id)
    for _, region_locs in pairs(self.engine.game_state.locations.regions) do
        for _, loc in pairs(region_locs) do
            if loc.owner_id == entity_id then
                local loc_def = LOCATION_TYPES[loc.type]
                if loc_def and loc_def.default_owner_role == role_id then
                    loc.owner_id = nil
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Monthly Tick: Income & Decay
--------------------------------------------------------------------------------

function Locations:tick_monthly(gs, clock)
    local entities = self.engine:get_module("entities")
    local day = clock and clock.total_days or 0

    for _, region_locs in pairs(gs.locations.regions) do
        for _, loc in pairs(region_locs) do
            local loc_def = LOCATION_TYPES[loc.type]
            if not loc_def then goto skip end

            -- Income for owner
            if loc.owner_id and (loc_def.income or 0) > 0 and entities then
                local owner = entities:get(loc.owner_id)
                if owner and owner.alive and owner.components.personal_wealth then
                    local WealthLib = require("dredwork_agency.wealth")
                    WealthLib.change(owner.components.personal_wealth, loc_def.income, "income: " .. loc.label, day)
                end
            end

            -- Upkeep: condition decays without owner or funds
            if loc_def.ownable then
                if loc.owner_id then
                    -- Owner pays upkeep from personal wealth
                    local owner = entities and entities:get(loc.owner_id)
                    if owner and owner.alive and owner.components.personal_wealth then
                        local WealthLib = require("dredwork_agency.wealth")
                        if WealthLib.can_afford(owner.components.personal_wealth, loc_def.upkeep or 0) then
                            WealthLib.change(owner.components.personal_wealth, -(loc_def.upkeep or 0), "upkeep: " .. loc.label, day)
                            loc.condition = Math.clamp((loc.condition or 100) + 1, 0, 100)
                        else
                            loc.condition = Math.clamp((loc.condition or 100) - 3, 0, 100)
                        end
                    else
                        loc.condition = Math.clamp((loc.condition or 100) - 2, 0, 100)
                    end
                else
                    -- No owner: slow decay
                    loc.condition = Math.clamp((loc.condition or 100) - 1, 0, 100)
                end
            end

            -- Owner bonuses
            if loc.owner_id and loc_def.owner_bonus then
                local owner = entities and entities:get(loc.owner_id)
                if owner and owner.alive then
                    -- Military morale bonus
                    if loc_def.owner_bonus.military_morale and gs.military then
                        for _, unit in ipairs(gs.military.units or {}) do
                            if unit.location_id == loc.region_id then
                                unit.morale = Math.clamp((unit.morale or 50) + 0.5, 0, 100)
                            end
                        end
                    end

                    -- Zeal influence
                    if loc_def.owner_bonus.zeal_influence and gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
                        gs.religion.active_faith.attributes.zeal = Math.clamp(
                            (gs.religion.active_faith.attributes.zeal or 50) + 0.2, 0, 100)
                    end
                end
            end

            -- Ruined locations lose their function
            if (loc.condition or 100) <= 0 then
                loc.ruined = true
                if not loc._ruin_announced then
                    self.engine:emit("LOCATION_RUINED", {
                        location_id = loc.id,
                        location_label = loc.label,
                        text = (loc.label or "A location") .. " has fallen to ruin.",
                    })
                    loc._ruin_announced = true
                end
            elseif (loc.condition or 100) > 20 then
                loc.ruined = false
                loc._ruin_announced = false
            end

            ::skip::
        end
    end
end

--------------------------------------------------------------------------------
-- Location Management
--------------------------------------------------------------------------------

--- Add a location to a region.
function Locations:add_location(region_id, location_type, custom_label)
    local gs = self.engine.game_state
    gs.locations.regions[region_id] = gs.locations.regions[region_id] or {}

    local loc_def = LOCATION_TYPES[location_type]
    if not loc_def then return nil end

    local location_id = region_id .. "_" .. location_type
    local location = {
        id = location_id,
        type = location_type,
        region_id = region_id,
        label = custom_label or loc_def.label,
        tags = loc_def.tags,
        entities_here = {},  -- entity_ids currently at this location
        condition = 100,     -- 0-100
        owner_id = nil,      -- entity who controls this location
        ruined = false,
    }

    gs.locations.regions[region_id][location_id] = location
    return location
end

--- Get all locations in a region.
function Locations:get_locations(region_id)
    local gs = self.engine.game_state
    if not gs.locations.regions[region_id] then return {} end

    local result = {}
    for _, loc in pairs(gs.locations.regions[region_id]) do
        table.insert(result, loc)
    end
    return result
end

--- Get a specific location.
function Locations:get_location(location_id)
    for _, region_locs in pairs(self.engine.game_state.locations.regions) do
        if region_locs[location_id] then return region_locs[location_id] end
    end
    return nil
end

--- Move an entity to a specific location within their region.
function Locations:move_entity(entity_id, location_id)
    local entities = self.engine:get_module("entities")
    if not entities then return false end
    local entity = entities:get(entity_id)
    if not entity then return false end

    -- Remove from old location
    local old_loc_id = entity.components.sub_location
    if old_loc_id then
        local old_loc = self:get_location(old_loc_id)
        if old_loc then
            for i, eid in ipairs(old_loc.entities_here) do
                if eid == entity_id then table.remove(old_loc.entities_here, i); break end
            end
        end
    end

    -- Add to new location
    local new_loc = self:get_location(location_id)
    if new_loc then
        table.insert(new_loc.entities_here, entity_id)
        entity.components.sub_location = location_id

        self.engine:emit("ENTITY_MOVED_LOCAL", {
            entity_id = entity_id,
            entity_name = entity.name,
            from = old_loc_id,
            to = location_id,
            location_label = new_loc.label,
        })
        return true
    end

    return false
end

--- Get which location an entity is currently at.
function Locations:get_entity_location(entity_id)
    local entities = self.engine:get_module("entities")
    if not entities then return nil end
    local entity = entities:get(entity_id)
    if not entity then return nil end
    local loc_id = entity.components.sub_location
    if not loc_id then return nil end
    return self:get_location(loc_id)
end

--- Get all entities at a specific location.
function Locations:get_entities_at(location_id)
    local loc = self:get_location(location_id)
    if not loc then return {} end

    local entities = self.engine:get_module("entities")
    if not entities then return {} end

    local result = {}
    for _, eid in ipairs(loc.entities_here) do
        local e = entities:get(eid)
        if e and e.alive then table.insert(result, e) end
    end
    return result
end

--- Get which interactions are available at a location.
function Locations:get_location_actions(location_type)
    local loc_def = LOCATION_TYPES[location_type]
    return loc_def and loc_def.interactions or {}
end

--- Check if a specific interaction is allowed at this location.
function Locations:is_action_allowed(location_type, action_id)
    local allowed = self:get_location_actions(location_type)
    for _, a in ipairs(allowed) do
        if a == action_id then return true end
    end
    return false
end

--- Get location tags (for encounter filtering).
function Locations:get_location_tags(location_type)
    local loc_def = LOCATION_TYPES[location_type]
    return loc_def and loc_def.tags or {}
end

--------------------------------------------------------------------------------
-- Seed Locations for a Region
--------------------------------------------------------------------------------

--- Create default locations for a region based on its biome.
function Locations:seed_region(region_id, biome)
    -- Every region gets these core locations
    self:add_location(region_id, "home", "Your Chambers")
    self:add_location(region_id, "court", "The Great Hall")
    self:add_location(region_id, "market")
    self:add_location(region_id, "gate")
    self:add_location(region_id, "road")

    -- Biome-specific locations
    if biome == "urban" then
        self:add_location(region_id, "tavern", "The Crow's Nest")
        self:add_location(region_id, "barracks")
        self:add_location(region_id, "dungeon")
    elseif biome == "temperate" then
        self:add_location(region_id, "temple")
        self:add_location(region_id, "barracks")
        self:add_location(region_id, "wilds", "The Outer Fields")
        self:add_location(region_id, "tavern", "The Hearthstone")
    elseif biome == "tundra" then
        self:add_location(region_id, "barracks", "The Frost Garrison")
        self:add_location(region_id, "temple", "The Ice Shrine")
        self:add_location(region_id, "wilds", "The Frozen Wastes")
    elseif biome == "tropical" then
        self:add_location(region_id, "temple", "The Vine Temple")
        self:add_location(region_id, "wilds", "The Deep Jungle")
        self:add_location(region_id, "tavern", "The Driftwood")
    elseif biome == "coastal" then
        self:add_location(region_id, "tavern", "The Salt Dog")
        self:add_location(region_id, "wilds", "The Shore Cliffs")
    elseif biome == "mountain" then
        self:add_location(region_id, "temple", "The Peak Shrine")
        self:add_location(region_id, "wilds", "The High Passes")
        self:add_location(region_id, "dungeon", "The Deep Mines")
    elseif biome == "steppe" then
        self:add_location(region_id, "wilds", "The Open Plains")
        self:add_location(region_id, "barracks", "The Rider Camp")
    elseif biome == "swamp" then
        self:add_location(region_id, "wilds", "The Mire")
        self:add_location(region_id, "tavern", "The Stilthouse")
    elseif biome == "desert" then
        self:add_location(region_id, "temple", "The Sand Shrine")
        self:add_location(region_id, "wilds", "The Dunes")
    end
end

--- Get location type definitions (for UI).
function Locations.get_types()
    return LOCATION_TYPES
end

function Locations:serialize() return self.engine.game_state.locations end
function Locations:deserialize(data) self.engine.game_state.locations = data end

return Locations
