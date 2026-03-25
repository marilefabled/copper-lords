-- Dark Legacy — Religion System
-- Auto-generates at gen 3-5 from cultural memory. Provides bonuses via tenets.
-- Schism mechanic when heir contradicts religion.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Religion = {}
Religion.__index = Religion

-- Doctrine modifiers (set externally by WorldController before tick)
Religion._doctrine_zealotry_floor = 0            -- zealotry can't drop below this
Religion._doctrine_religion_locked = false        -- prevents tenet changes
Religion._doctrine_schism_pressure_mult = 1.0     -- multiplier on schism pressure gain
Religion._doctrine_zealotry_bonus_mult = 1.0      -- multiplier on zealotry gain

--- Faith name fragments for procedural generation.
local name_prefixes = {
    "Ember", "Iron", "Hollow", "Scarred", "Blood",
    "Ashen", "Tallow", "Blind", "Salted", "Marrow",
}
local name_suffixes = {
    "Rite", "Tithe", "Compact", "Writ", "Doctrine",
    "Covenant", "Toll", "Ledger", "Demand", "Seal",
}

--- Tenet templates keyed by category.
local tenet_templates = {
    physical = {
        { id = "valor_above_all", label = "Valor Above All", trait_id = "PHY_STR", bonus = 5, description = "Strength is sacred." },
        { id = "the_body_is_temple", label = "The Body Is Temple", trait_id = "PHY_VIT", bonus = 4, description = "Flesh must be honed." },
    },
    mental = {
        { id = "seek_knowledge", label = "Seek Knowledge", trait_id = "MEN_INT", bonus = 5, description = "Ignorance is sin." },
        { id = "clarity_of_mind", label = "Clarity of Mind", trait_id = "MEN_WIL", bonus = 4, description = "A sharp mind cuts deepest." },
    },
    social = {
        { id = "bonds_unbroken", label = "Bonds Unbroken", trait_id = "SOC_CHA", bonus = 5, description = "Loyalty is the highest virtue." },
        { id = "the_spoken_word", label = "The Spoken Word", trait_id = "SOC_ELO", bonus = 4, description = "A promise once given is iron." },
    },
    creative = {
        { id = "beauty_endures", label = "Beauty Endures", trait_id = "CRE_ING", bonus = 5, description = "Creation outlasts the creator." },
        { id = "the_makers_hands", label = "The Maker's Hands", trait_id = "CRE_AES", bonus = 4, description = "To build is to pray." },
    },
}

--- Return religion name with "The " prefix, avoiding "The The ...".
--- Works with both old saves ("The Hollow Writ") and new ("Hollow Writ").
---@param name string religion name
---@return string
function Religion.display_name(name)
    if not name then return "the faith" end
    if name:sub(1, 4) == "The " then return name end
    return "The " .. name
end

--- Create a new religion (empty, call :generate() to initialize).
---@return table Religion instance
function Religion.new()
    local self = setmetatable({}, Religion)
    self.name = nil
    self.tenets = {}
    self.zealotry = 0
    self.schism_pressure = 0
    self.generation_founded = nil
    self.active = false
    self.schism_count = 0
    self.pantheon = {} -- array of { heir_name, generation, domain, bonus_applied }
    return self
end

--- Deify a legendary ancestor, adding them to the pantheon and granting a permanent bonus.
---@param heir_name string
---@param generation number
---@param domain string "war", "harvest", "secrets", "fertility", "rot", "iron"
function Religion:deify_ancestor(heir_name, generation, domain)
    if not self.active then return end
    
    local new_god = {
        heir_name = heir_name,
        generation = generation,
        domain = domain
    }
    
    -- Add domain-specific tenet/bonus
    if domain == "war" or domain == "iron" then
        self.tenets[#self.tenets + 1] = {
            id = "god_of_war_" .. generation, label = "The God of Blades (" .. heir_name .. ")", category = "physical", bonus = 5,
            description = "The immortal rage of " .. heir_name .. " guides our hands in battle."
        }
    elseif domain == "harvest" then
        self.tenets[#self.tenets + 1] = {
            id = "god_of_harvest_" .. generation, label = "The Bountiful Dead (" .. heir_name .. ")", category = "social", bonus = 5,
            description = heir_name .. " ensures our granaries never empty."
        }
    elseif domain == "secrets" then
        self.tenets[#self.tenets + 1] = {
            id = "god_of_secrets_" .. generation, label = "The Whispering Shade (" .. heir_name .. ")", category = "mental", bonus = 5,
            description = heir_name .. " trades secrets from beyond the veil."
        }
    elseif domain == "fertility" then
        self.tenets[#self.tenets + 1] = {
            id = "god_of_fertility_" .. generation, label = "The Mother of Blood (" .. heir_name .. ")", category = "physical", bonus = 5,
            description = heir_name .. " protects the unborn and the weak."
        }
    elseif domain == "rot" then
        self.tenets[#self.tenets + 1] = {
            id = "god_of_rot_" .. generation, label = "The God of Rot (" .. heir_name .. ")", category = "mental", bonus = 5,
            description = heir_name .. " mastered the plague in life, and commands it in death."
        }
    end
    
    self.pantheon[#self.pantheon + 1] = new_god
    while #self.tenets > 8 do table.remove(self.tenets, 2) end
    self.zealotry = math.min(100, self.zealotry + 30) -- Massive religious revival
end

--- Get world-state effects from the pantheon.
---@return table { grain_bonus, steel_bonus, plague_intensity_mod, war_intensity_mod, lore_bonus }
function Religion:get_world_effects()
    local effects = {
        grain_bonus = 0,
        steel_bonus = 0,
        plague_intensity_mod = 0,
        war_intensity_mod = 0,
        lore_bonus = 0,
        fertility_bonus = 0,
    }
    
    if not self.active then 
        -- If religion is inactive (abandoned), "God of Rot" effects turn negative
        -- Prompt: "If your world abandons the God of Rot, plague conditions become deadlier."
        return effects 
    end

    local scale = self.zealotry / 100
    
    for _, god in ipairs(self.pantheon) do
        if god.domain == "harvest" then
            effects.grain_bonus = effects.grain_bonus + math.floor(15 * scale)
        elseif god.domain == "war" or god.domain == "iron" then
            effects.steel_bonus = effects.steel_bonus + math.floor(10 * scale)
            effects.war_intensity_mod = effects.war_intensity_mod - (0.2 * scale)
        elseif god.domain == "secrets" then
            effects.lore_bonus = effects.lore_bonus + math.floor(5 * scale)
        elseif god.domain == "rot" then
            -- While worshipped, the God of Rot lessens the plague's sting
            effects.plague_intensity_mod = effects.plague_intensity_mod - (0.3 * scale)
        elseif god.domain == "fertility" then
            effects.fertility_bonus = effects.fertility_bonus + (10 * scale)
        end
    end
    
    return effects
end

--- Generate religion from cultural memory priorities.
--- Should be called around generation 3-5.
---@param cultural_memory table CulturalMemory instance
---@param generation number current generation
function Religion:generate(cultural_memory, generation)
    -- Generate name
    self.name = name_prefixes[rng.range(1, #name_prefixes)] .. " " ..
                name_suffixes[rng.range(1, #name_suffixes)]
    self.generation_founded = generation
    self.zealotry = rng.range(30, 50)
    self.active = true

    -- Derive tenets from top 2 cultural memory categories
    local cat_sums = { physical = 0, mental = 0, social = 0, creative = 0 }
    local cat_counts = { physical = 0, mental = 0, social = 0, creative = 0 }
    local prefix_to_cat = { PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" }

    if cultural_memory and cultural_memory.trait_priorities then
        for id, priority in pairs(cultural_memory.trait_priorities) do
            local prefix = id:sub(1, 3)
            local cat = prefix_to_cat[prefix]
            if cat then
                cat_sums[cat] = cat_sums[cat] + priority
                cat_counts[cat] = cat_counts[cat] + 1
            end
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

    -- Pick tenets from top 2 categories
    self.tenets = {}
    for i = 1, math.min(2, #cat_avgs) do
        local cat = cat_avgs[i].cat
        local templates = tenet_templates[cat]
        if templates and #templates > 0 then
            local tmpl = templates[rng.range(1, #templates)]
            self.tenets[#self.tenets + 1] = {
                id = tmpl.id,
                label = tmpl.label,
                category = cat,
                bonus = tmpl.bonus,
                trait_id = tmpl.trait_id,
                description = tmpl.description,
            }
        end
    end
end

--- Tick religion each generation. Updates zealotry, checks schism.
---@param heir_genome table Genome of current heir
---@param cultural_memory table CulturalMemory instance
---@param generation number
---@return table { zealotry_changed, schism_triggered }
function Religion:tick(heir_genome, cultural_memory, generation)
    if not self.active then
        return { zealotry_changed = 0, schism_triggered = false }
    end

    local results = { zealotry_changed = 0, schism_triggered = false }

    -- Check alignment: does heir match tenet categories?
    local alignment = 0
    local prefix_map = { physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE" }

    for _, tenet in ipairs(self.tenets) do
        local prefix = prefix_map[tenet.category]
        if prefix and heir_genome then
            -- Average heir traits in tenet category
            local sum, count = 0, 0
            for id, _ in pairs(heir_genome.traits or {}) do
                if id:sub(1, 3) == prefix then
                    sum = sum + (heir_genome:get_value(id) or 50)
                    count = count + 1
                end
            end
            local avg = count > 0 and (sum / count) or 50
            if avg >= 55 then
                alignment = alignment + 1  -- heir aligns with tenet
            elseif avg < 40 then
                alignment = alignment - 1  -- heir contradicts tenet
            end
        end
    end

    -- Adjust zealotry
    if alignment > 0 then
        local boost = alignment * rng.range(2, 4)
        boost = math.floor(boost * Religion._doctrine_zealotry_bonus_mult)
        self.zealotry = math.min(100, self.zealotry + boost)
        results.zealotry_changed = boost
        -- Reduce schism pressure
        self.schism_pressure = math.max(0, self.schism_pressure - rng.range(3, 8))
    elseif alignment < 0 then
        local drop = math.abs(alignment) * rng.range(1, 3)
        self.zealotry = math.max(0, self.zealotry - drop)
        results.zealotry_changed = -drop
        -- Build schism pressure (doctrine multiplier)
        local pressure_gain = rng.range(5, 12)
        pressure_gain = math.floor(pressure_gain * Religion._doctrine_schism_pressure_mult)
        self.schism_pressure = math.min(100, self.schism_pressure + pressure_gain)
    end

    -- Natural zealotry decay (respects doctrine floor)
    self.zealotry = math.max(Religion._doctrine_zealotry_floor, self.zealotry - 1)

    -- Integration: "The Unclean Heir"
    -- If the heir is blighted (low vitality), it creates religious scandal
    if heir_genome then
        local vit = heir_genome:get_value("PHY_VIT") or 50
        if vit < 25 then
            self.schism_pressure = math.min(100, self.schism_pressure + 20)
            -- This will be chronicled by the controller
        end
    end

    -- Schism check (doctrine: religion_locked prevents schism)
    if self.schism_pressure >= 80 and not Religion._doctrine_religion_locked then
        results.schism_triggered = true
        self.schism_count = self.schism_count + 1
        self.schism_pressure = 0
        self.zealotry = math.max(Religion._doctrine_zealotry_floor,
            math.floor(self.zealotry * 0.5))
    end

    return results
end

--- Get trait bonuses from religion tenets, scaled by zealotry.
---@return table { [trait_id] = bonus }
function Religion:get_bonuses()
    if not self.active then return {} end
    local bonuses = {}
    local scale = self.zealotry / 100
    for _, tenet in ipairs(self.tenets) do
        if tenet.trait_id then
            bonuses[tenet.trait_id] = (bonuses[tenet.trait_id] or 0) +
                math.floor(tenet.bonus * scale)
        end
    end
    return bonuses
end


--- Get display info for UI.
---@return table { name, tenets, zealotry, schism_pressure, active }
function Religion:get_display()
    return {
        name = self.name or "None",
        tenets = self.tenets,
        zealotry = self.zealotry,
        schism_pressure = self.schism_pressure,
        active = self.active,
        generation_founded = self.generation_founded,
        schism_count = self.schism_count,
    }
end

--- Serialize to plain table.
---@return table
function Religion:to_table()
    return {
        name = self.name,
        tenets = self.tenets,
        zealotry = self.zealotry,
        schism_pressure = self.schism_pressure,
        generation_founded = self.generation_founded,
        active = self.active,
        schism_count = self.schism_count,
        pantheon = self.pantheon,
    }
end

--- Restore from saved table.
---@param data table
---@return table Religion
function Religion.from_table(data)
    local self = setmetatable({}, Religion)
    self.name = data.name
    self.tenets = data.tenets or {}
    self.zealotry = data.zealotry or 0
    self.schism_pressure = data.schism_pressure or 0
    self.generation_founded = data.generation_founded
    self.active = data.active or false
    self.schism_count = data.schism_count or 0
    self.pantheon = data.pantheon or {}
    return self
end

return Religion
