-- Dark Legacy — Discovery / Technology Tree
-- Permanent unlocks based on era + heir traits. Data-driven.
-- Pure Lua, zero Solar2D dependencies.

local Discoveries = {}
Discoveries.__index = Discoveries

--- Discovery definitions. Each requires era + trait thresholds.
Discoveries.definitions = {
    -- Ancient era
    { id = "fire_mastery", era = "ancient", label = "Fire Mastery",
      requires = { CRE_CRA = 55 },
      effect = { trait_bonus = { PHY_END = 3 } },
      flavor = "The flame obeys. The darkness retreats." },
    { id = "oral_tradition", era = "ancient", label = "Oral Tradition",
      requires = { CRE_NAR = 60, MEN_MEM = 55 },
      effect = { cultural_memory_decay_reduction = 0.05 },
      flavor = "Stories carry the weight of ancestors." },
    { id = "beast_taming", era = "ancient", label = "Beast Taming",
      requires = { PHY_STR = 60, MEN_COM = 50 },
      effect = { trait_bonus = { PHY_STR = 3 } },
      flavor = "What was wild now serves." },
    { id = "stargazing", era = "ancient", label = "Stargazing",
      requires = { MEN_ABS = 60 },
      effect = { mutation_pressure_reduction = 3 },
      flavor = "The sky whispers patterns to those who listen." },

    -- Iron era
    { id = "ironworking", era = "iron", label = "Ironworking",
      requires = { CRE_CRA = 60 },
      effect = { trait_bonus = { PHY_STR = 5 } },
      flavor = "The forge changes everything." },
    { id = "siege_craft", era = "iron", label = "Siege Craft",
      requires = { MEN_SPA = 60, CRE_MEC = 55 },
      effect = { trait_bonus = { MEN_STR = 3 } },
      flavor = "No wall stands forever." },
    { id = "written_law", era = "iron", label = "Written Law",
      requires = { MEN_ANA = 60, SOC_NEG = 55 },
      effect = { trait_bonus = { SOC_TRU = 3 } },
      flavor = "Words carved in stone outlast the hand that wrote them." },
    { id = "field_medicine", era = "iron", label = "Field Medicine",
      requires = { MEN_INT = 55, PHY_REC = 50 },
      effect = { trait_bonus = { PHY_VIT = 4 } },
      flavor = "The healers learn to save what war would take." },

    -- Dark era
    { id = "plague_lore", era = "dark", label = "Plague Lore",
      requires = { MEN_PAT = 60, PHY_IMM = 55 },
      effect = { trait_bonus = { PHY_IMM = 5 } },
      flavor = "To survive the plague, one must first understand it." },
    { id = "rationing", era = "dark", label = "Rationing",
      requires = { MEN_ANA = 55, SOC_LEA = 50 },
      effect = { trait_bonus = { PHY_MET = 3 } },
      flavor = "Every grain counted. Every mouth measured." },
    { id = "underground_networks", era = "dark", label = "Underground Networks",
      requires = { SOC_DEC = 55, MEN_CUN = 55 },
      effect = { trait_bonus = { SOC_INF = 4 } },
      flavor = "In the dark, the unseen paths matter most." },

    -- Arcane era
    { id = "arcane_theory", era = "arcane", label = "Arcane Theory",
      requires = { MEN_ABS = 65, CRE_SYM = 55 },
      effect = { mutation_pressure_reduction = 5 },
      flavor = "Magic has rules. Those who know them, survive." },
    { id = "dream_walking", era = "arcane", label = "Dream Walking",
      requires = { MEN_DRM = 70, MEN_ITU = 60 },
      effect = { trait_bonus = { MEN_DRM = 5 } },
      flavor = "The boundary between dream and waking thins." },
    { id = "transmutation", era = "arcane", label = "Transmutation",
      requires = { CRE_ING = 65, MEN_INT = 60 },
      effect = { trait_bonus = { CRE_CRA = 5, CRE_ING = 3 } },
      flavor = "Lead becomes gold. Flesh becomes something else." },
    { id = "ward_scribing", era = "arcane", label = "Ward Scribing",
      requires = { CRE_SYM = 60, MEN_FOC = 55 },
      effect = { trait_bonus = { PHY_VIT = 3 } },
      flavor = "Protection etched in symbols older than language." },

    -- Gilded era
    { id = "banking", era = "gilded", label = "Banking",
      requires = { MEN_ANA = 60, SOC_NEG = 60 },
      effect = { trait_bonus = { SOC_INF = 4, SOC_NEG = 3 } },
      flavor = "Money is its own kind of power." },
    { id = "printing", era = "gilded", label = "Printing",
      requires = { CRE_CRA = 55, CRE_ING = 55 },
      effect = { trait_bonus = { MEN_LRN = 4 } },
      flavor = "Knowledge multiplies. So does dissent." },
    { id = "grand_architecture", era = "gilded", label = "Grand Architecture",
      requires = { CRE_ARC = 65, CRE_AES = 55 },
      effect = { trait_bonus = { CRE_ARC = 5 } },
      flavor = "Beauty carved in stone that makes gods envious." },
    { id = "diplomacy_school", era = "gilded", label = "School of Diplomacy",
      requires = { SOC_ELO = 60, SOC_AWR = 55 },
      effect = { trait_bonus = { SOC_ELO = 3, SOC_CHA = 3 } },
      flavor = "Words sharpened into weapons more deadly than swords." },

    -- Twilight era
    { id = "prophecy_codex", era = "twilight", label = "Prophecy Codex",
      requires = { MEN_ITU = 65, CRE_SYM = 60 },
      effect = { mutation_pressure_reduction = 8 },
      flavor = "The future is written. Reading it is another matter." },
    { id = "soul_binding", era = "twilight", label = "Soul Binding",
      requires = { MEN_WIL = 70, MEN_ABS = 65 },
      effect = { trait_bonus = { MEN_WIL = 5 } },
      flavor = "The boundary between self and ancestor dissolves." },
    { id = "last_harvest", era = "twilight", label = "The Last Harvest",
      requires = { PHY_ADP = 60, CRE_RES = 60 },
      effect = { trait_bonus = { PHY_VIT = 5, PHY_IMM = 3 } },
      flavor = "In the twilight, every scrap of life is precious." },
}

--- Create a new discoveries tracker.
---@return table Discoveries instance
function Discoveries.new()
    local self = setmetatable({}, Discoveries)
    self.unlocked = {}  -- { id = { generation, heir_name } }
    return self
end

--- Check which discoveries can be unlocked this generation.
---@param genome table Genome of current heir
---@param era_key string current era key
---@return table array of unlockable discovery definitions
function Discoveries:get_available(genome, era_key)
    local available = {}
    for _, def in ipairs(Discoveries.definitions) do
        if not self.unlocked[def.id] and def.era == era_key then
            local qualifies = true
            for trait_id, threshold in pairs(def.requires) do
                local val = genome:get_value(trait_id) or 0
                if val < threshold then
                    qualifies = false
                    break
                end
            end
            if qualifies then
                available[#available + 1] = def
            end
        end
    end
    return available
end

--- Unlock a discovery.
---@param discovery_id string
---@param generation number
---@param heir_name string|nil
function Discoveries:unlock(discovery_id, generation, heir_name)
    self.unlocked[discovery_id] = {
        generation = generation,
        heir_name = heir_name or "unknown",
    }
end

--- Get all unlocked discoveries with their definitions.
---@return table array of { definition, unlock_data }
function Discoveries:get_unlocked()
    local result = {}
    for _, def in ipairs(Discoveries.definitions) do
        if self.unlocked[def.id] then
            result[#result + 1] = {
                definition = def,
                unlock_data = self.unlocked[def.id],
            }
        end
    end
    return result
end

--- Apply permanent effects of all unlocked discoveries.
---@return table { trait_bonuses = {id=bonus}, mutation_pressure_reduction = N }
function Discoveries:get_effects()
    local effects = {
        trait_bonuses = {},
        mutation_pressure_reduction = 0,
        cultural_memory_decay_reduction = 0,
    }
    for _, def in ipairs(Discoveries.definitions) do
        if self.unlocked[def.id] and def.effect then
            if def.effect.trait_bonus then
                for id, bonus in pairs(def.effect.trait_bonus) do
                    effects.trait_bonuses[id] = (effects.trait_bonuses[id] or 0) + bonus
                end
            end
            if def.effect.mutation_pressure_reduction then
                effects.mutation_pressure_reduction =
                    effects.mutation_pressure_reduction + def.effect.mutation_pressure_reduction
            end
            if def.effect.cultural_memory_decay_reduction then
                effects.cultural_memory_decay_reduction =
                    effects.cultural_memory_decay_reduction + def.effect.cultural_memory_decay_reduction
            end
        end
    end
    return effects
end

--- Count unlocked discoveries.
---@return number
function Discoveries:count()
    local n = 0
    for _ in pairs(self.unlocked) do n = n + 1 end
    return n
end

--- Serialize to plain table.
---@return table
function Discoveries:to_table()
    return { unlocked = self.unlocked }
end

--- Restore from saved table.
---@param data table
---@return table Discoveries
function Discoveries.from_table(data)
    local self = setmetatable({}, Discoveries)
    self.unlocked = data and data.unlocked or {}
    return self
end

return Discoveries
