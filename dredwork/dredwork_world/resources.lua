-- Dark Legacy — Resources (Logistics & Inventory)
-- Tracks the visceral commodities of the lineage: Grain, Steel, Lore, and Gold.
-- Pure Lua, zero Solar2D dependencies.

local Resources = {}
Resources.__index = Resources

--- Create a new Resources manager.
---@param custom_config table|nil optional overrides
---@return table Resources instance
function Resources.new(custom_config)
    local self = setmetatable({}, Resources)
    self.grain = 20  -- Food/Survival
    self.steel = 10  -- War/Defense
    self.lore  = 8   -- Technology/Progress
    self.gold  = 25  -- Trade/Bribes
    
    self.last_spenders = {
        grain = nil, -- { heir_name, gen }
        steel = nil,
        lore  = nil,
        gold  = nil,
    }

    if custom_config and custom_config.resources then
        for k, v in pairs(custom_config.resources) do
            if self[k] ~= nil then
                self[k] = self[k] + v
            end
        end
    end

    self.history = {}
    return self
end

--- Change a resource amount.
---@param type string grain, steel, lore, gold
---@param delta number
---@param reason string
---@param heir_name string|nil
---@param gen number|nil
function Resources:change(type, delta, reason, heir_name, gen)
    if not self[type] then return end
    self[type] = math.max(0, self[type] + delta)
    
    -- Track last significant spender
    if delta < 0 and heir_name and gen then
        self.last_spenders[type] = { name = heir_name, generation = gen }
    end

    -- Limit history to prevent bloat
    if #self.history > 20 then table.remove(self.history, 1) end
    self.history[#self.history + 1] = {
        type = type,
        delta = delta,
        reason = reason or "unknown"
    }
end

--- Get all current counts.
---@return table
function Resources:get_all()
    return {
        grain = math.floor(self.grain),
        steel = math.floor(self.steel),
        lore = math.floor(self.lore),
        gold = math.floor(self.gold)
    }
end

--- Check if the lineage is "Starving" or "Broke".
---@return boolean, string|nil
function Resources:check_crisis()
    if self.grain <= 0 then return true, "famine" end
    if self.steel <= 0 then return true, "vulnerability" end
    return false, nil
end

--- Compute nurture modifiers based on resource abundance or scarcity.
---@return table array of { trait, bonus, description }
function Resources:compute_nurture_modifiers()
    local mods = {}
    
    -- Grain (Vitality)
    if self.grain >= 35 then
        table.insert(mods, { trait = "PHY_VIT", bonus = 3, description = "Abundant food shapes a healthy youth." })
    elseif self.grain <= 5 then
        table.insert(mods, { trait = "PHY_VIT", bonus = -5, description = "Malnourishment scars the early years." })
    end

    -- Steel (Strength/Endurance)
    if self.steel >= 25 then
        table.insert(mods, { trait = "PHY_STR", bonus = 2, description = "A childhood of martial training and iron." })
    elseif self.steel <= 2 then
        table.insert(mods, { trait = "PHY_END", bonus = -3, description = "A fragile peace, untested by steel." })
    end

    -- Lore (Intellect/Curiosity + Crowd Reading from scholarly exposure)
    if self.lore >= 20 then
        table.insert(mods, { trait = "MEN_INT", bonus = 2, description = "Raised among the scrolls of the ancestors." })
        table.insert(mods, { trait = "SOC_CRD", bonus = 2, description = "Scholars taught the reading of faces and crowds." })
    end

    -- Gold (high wealth nurtures longevity through better medicine)
    if self.gold >= 40 then
        table.insert(mods, { trait = "PHY_LON", bonus = 2, description = "Gold buys the finest healers and diets." })
    end

    return mods
end

function Resources:to_table()
    return {
        grain = self.grain,
        steel = self.steel,
        lore = self.lore,
        gold = self.gold,
        last_spenders = self.last_spenders,
        history = self.history
    }
end

function Resources.from_table(data)
    local self = Resources.new()
    if data then
        self.grain = data.grain or self.grain
        self.steel = data.steel or self.steel
        self.lore = data.lore or self.lore
        self.gold = data.gold or self.gold
        self.last_spenders = data.last_spenders or self.last_spenders
        self.history = data.history or {}
    end
    return self
end

return Resources
