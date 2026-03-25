-- Dark Legacy — Culture Values System
-- Auto-derived from cultural memory every ~5 generations.
-- Values affect event flavor; customs provide mechanical bonuses.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Culture = {}
Culture.__index = Culture

-- Doctrine modifiers (set externally by WorldController before tick)
Culture._doctrine_culture_locked = false  -- prevents custom additions/removals
Culture._doctrine_rigidity_floor = 0      -- minimum rigidity

--- Custom definitions that can emerge from cultural patterns.
Culture.custom_definitions = {
    { id = "trial_by_combat", label = "Trial by Combat",
      trigger_cat = "physical", requires_priority = 65,
      effect = "physical_replaces_social_checks",
      description = "Disputes are settled with steel, not words." },
    { id = "scholarly_tradition", label = "Scholarly Tradition",
      trigger_cat = "mental", requires_priority = 65,
      effect = "mental_bonus_on_advance",
      description = "Every heir is educated before inheriting." },
    { id = "diplomatic_code", label = "Diplomatic Code",
      trigger_cat = "social", requires_priority = 65,
      effect = "social_bonus_on_alliance",
      description = "Words are sacred treaties." },
    { id = "artisan_guilds", label = "Artisan Guilds",
      trigger_cat = "creative", requires_priority = 65,
      effect = "creative_bonus_on_craft",
      description = "Craft is honored above commerce." },
    { id = "ancestor_worship", label = "Ancestor Worship",
      trigger_cat = nil, requires_priority = nil,
      requires_generation = 10,
      effect = "cultural_memory_decay_slow",
      description = "The dead are consulted before the living." },
    { id = "blood_oaths", label = "Blood Oaths",
      trigger_cat = "physical", requires_priority = 60,
      effect = "relationship_strength_bonus",
      description = "Alliances are sealed in blood, not ink." },
}

--- Create a new culture tracker.
---@return table Culture instance
function Culture.new()
    local self = setmetatable({}, Culture)
    self.values = {}     -- top 3 value labels
    self.customs = {}    -- active customs (from definitions above)
    self.rigidity = 30   -- 0-100, how resistant to change
    self.last_recalc_gen = 0
    return self
end

--- Recalculate culture values from cultural memory.
--- Called every ~5 generations or when manually triggered.
---@param cultural_memory table CulturalMemory instance
---@param generation number
---@param era_key string|nil
function Culture:recalculate(cultural_memory, generation, era_key)
    if not cultural_memory then return end

    self.last_recalc_gen = generation

    -- Doctrine: culture_locked prevents custom changes (values still update)
    local customs_locked = Culture._doctrine_culture_locked

    -- Derive top values from trait priority categories
    local cat_sums = { physical = 0, mental = 0, social = 0, creative = 0 }
    local cat_counts = { physical = 0, mental = 0, social = 0, creative = 0 }
    local prefix_to_cat = { PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" }

    for id, priority in pairs(cultural_memory.trait_priorities or {}) do
        local prefix = id:sub(1, 3)
        local cat = prefix_to_cat[prefix]
        if cat then
            cat_sums[cat] = cat_sums[cat] + priority
            cat_counts[cat] = cat_counts[cat] + 1
        end
    end

    local cat_avgs = {}
    for cat, sum in pairs(cat_sums) do
        local count = cat_counts[cat]
        if count > 0 then
            cat_avgs[#cat_avgs + 1] = { cat = cat, avg = sum / count }
        end
    end
    table.sort(cat_avgs, function(a, b) return a.avg > b.avg end)

    -- Top 3 become culture values
    local value_labels = {
        physical = "strength", mental = "knowledge",
        social = "honor", creative = "beauty",
    }
    self.values = {}
    for i = 1, math.min(3, #cat_avgs) do
        self.values[i] = value_labels[cat_avgs[i].cat] or cat_avgs[i].cat
    end

    -- 2. Auto-evolve Education Style based on top category
    -- (This happens every 5 generations during recalculate)
    local top_cat = cat_avgs[1] and cat_avgs[1].cat
    if top_cat then
        local edu_config = require("dredwork_world.config.education_styles")
        local best_style = self.education_style
        for _, style in ipairs(edu_config.styles) do
            if style.primary_cat == top_cat then
                -- Check era affinity
                local current_era = era_key or "ancient"
                if style.era_affinity == "all" or style.era_affinity == current_era then
                    best_style = style.id
                    break
                else
                    local match = false
                    for _, e in ipairs(style.era_affinity or {}) do
                        if e == current_era then match = true; break end
                    end
                    if match then best_style = style.id; break end
                end
            end
        end
        self.education_style = best_style
    end

    -- Compute custom age sum for rigidity calc
    local custom_age_sum = 0
    for _, c in ipairs(self.customs) do
        custom_age_sum = custom_age_sum + (generation - (c.generation_adopted or 0))
    end

    -- Check for new customs (skipped if culture_locked doctrine active)
    if customs_locked then
        -- Rigidity still updates but no new customs can form
        self.rigidity = math.max(Culture._doctrine_rigidity_floor,
            math.min(80, 30 + math.floor(custom_age_sum * 0.5)))
        return
    end

    local blind_spots = cultural_memory.blind_spots or {}
    local blind_map = {}
    for _, cat in ipairs(blind_spots) do blind_map[cat] = true end

    for _, def in ipairs(Culture.custom_definitions) do
        local already_active = false
        for _, c in ipairs(self.customs) do
            if c.id == def.id then already_active = true; break end
        end

        if not already_active then
            local qualifies = true

            if def.trigger_cat then
                local cat_avg = 0
                for _, ca in ipairs(cat_avgs) do
                    if ca.cat == def.trigger_cat then cat_avg = ca.avg; break end
                end

                -- Blindspot penalty: threshold is much higher if category is a blind spot
                local threshold = def.requires_priority or 60
                if blind_map[def.trigger_cat] then
                    threshold = threshold + 20
                end

                if cat_avg < threshold then
                    qualifies = false
                end
            end

            if def.requires_generation and generation < def.requires_generation then
                qualifies = false
            end

            if qualifies then
                self.customs[#self.customs + 1] = {
                    id = def.id,
                    label = def.label,
                    effect = def.effect,
                    description = def.description,
                    generation_adopted = generation,
                    category = def.trigger_cat,
                }
                -- Add Weight: adoption itself pushes priorities
                if def.trigger_cat then
                    for id, priority in pairs(cultural_memory.trait_priorities) do
                        local prefix = id:sub(1, 3)
                        local cat = ({ PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" })[prefix]
                        if cat == def.trigger_cat then
                            cultural_memory.trait_priorities[id] = math.min(100, priority + 2)
                        end
                    end
                end
            end
        end
    end

    -- Recompute custom age sum (new customs may have been added)
    custom_age_sum = 0
    for _, c in ipairs(self.customs) do
        custom_age_sum = custom_age_sum + (generation - (c.generation_adopted or 0))
    end
    -- Rigidity = base 30 + age of customs (capped at 80, respects doctrine floor)
    self.rigidity = math.max(Culture._doctrine_rigidity_floor,
        math.min(80, 30 + math.floor(custom_age_sum * 0.5)))
end

--- Tick culture. Recalculate every 5 generations.
---@param cultural_memory table
---@param generation number
---@param era_key string|nil
function Culture:tick(cultural_memory, generation, era_key)
    if generation - self.last_recalc_gen >= 5 then
        self:recalculate(cultural_memory, generation, era_key)
    end
end

--- Check if a custom is active.
---@param custom_id string
---@return boolean
function Culture:has_custom(custom_id)
    for _, c in ipairs(self.customs) do
        if c.id == custom_id then return true end
    end
    return false
end

--- Get display info for UI.
---@return table
function Culture:get_display()
    return {
        values = self.values,
        customs = self.customs,
        rigidity = self.rigidity,
    }
end

--- Serialize to plain table.
---@return table
function Culture:to_table()
    return {
        values = self.values,
        customs = self.customs,
        education_style = self.education_style,
        rigidity = self.rigidity,
        last_recalc_gen = self.last_recalc_gen,
    }
end

--- Restore from saved table.
---@param data table
---@return table Culture
function Culture.from_table(data)
    local self = setmetatable({}, Culture)
    self.values = data and data.values or {}
    self.customs = data and data.customs or {}
    self.education_style = data and data.education_style or "the_iron_scriptorium"
    self.rigidity = data and data.rigidity or 30
    self.last_recalc_gen = data and data.last_recalc_gen or 0
    return self
end

--- Get the active education tradition.
---@return string style_id
function Culture:get_tradition()
    return self.education_style or "the_iron_scriptorium"
end

--- Set the family's active education tradition.
---@param style_id string
function Culture:set_tradition(style_id)
    self.education_style = style_id
end

return Culture
