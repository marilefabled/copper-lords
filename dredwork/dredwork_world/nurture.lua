-- Dark Legacy — Nurture Modifiers
-- Environmental bonuses applied after birth, representing upbringing.
-- Temporary (one generation) but stack with genetics.
-- Pure Lua, zero Solar2D dependencies.

local Nurture = {}

--- Compute nurture modifiers for a newborn based on world state.
---@param world_state table WorldState instance
---@param cultural_memory table CulturalMemory instance
---@param era_key string current era key
---@param discoveries table|nil Discoveries instance
---@param culture table|nil Culture instance for education style
---@return table array of { source, trait, bonus, description, mastery_tag }
function Nurture.compute(world_state, cultural_memory, era_key, discoveries, culture)
    local modifiers = {}

    -- 0. Education Tradition (Top priority)
    if culture and culture.get_tradition then
        local edu_config = require("dredwork_world.config.education_styles")
        local style_id = culture:get_tradition()
        local style = nil
        for _, s in ipairs(edu_config.styles) do
            if s.id == style_id then
                style = s
                break
            end
        end

        if style then
            for trait_id, bonus in pairs(style.traits) do
                local desc = style.flavor or "Schooled in the family tradition."
                if style.trait_flavors and style.trait_flavors[trait_id] then
                    desc = style.trait_flavors[trait_id]
                end
                modifiers[#modifiers + 1] = {
                    source = "education_style",
                    trait = trait_id,
                    bonus = bonus,
                    description = desc,
                    mastery_tag = style.mastery_tag,
                }
            end
        end
    end

    -- 1. Active condition modifiers
    if world_state then
        local conditions = world_state.conditions or {}
        for _, cond in ipairs(conditions) do
            if cond.type == "war" and cond.remaining_gens > 0 then
                local war_target = cond.metadata and cond.metadata.target_faction_name or nil
                local war_suffix = war_target and (" against " .. war_target) or ""
                modifiers[#modifiers + 1] = {
                    source = "war_era",
                    trait = "PHY_STR",
                    bonus = 5,
                    description = "Raised in wartime" .. war_suffix .. " — strength forged in conflict.",
                }
                modifiers[#modifiers + 1] = {
                    source = "war_era",
                    trait = "PHY_BON",
                    bonus = 3,
                    description = "Bones hardened by drills and labor.",
                }
                modifiers[#modifiers + 1] = {
                    source = "war_era",
                    trait = "MEN_COM",
                    bonus = 3,
                    description = "Composure earned under fire.",
                }
            end
            if cond.type == "plague" and cond.remaining_gens > 0 then
                modifiers[#modifiers + 1] = {
                    source = "plague_survivor",
                    trait = "PHY_IMM",
                    bonus = 8,
                    description = "Survived the plague — immune system hardened.",
                }
                modifiers[#modifiers + 1] = {
                    source = "plague_survivor",
                    trait = "PHY_LUN",
                    bonus = -3,
                    description = "The plague scarred the lungs of the young.",
                }
            end
            if cond.type == "famine" and cond.remaining_gens > 0 then
                modifiers[#modifiers + 1] = {
                    source = "famine_scarcity",
                    trait = "PHY_MET",
                    bonus = 4,
                    description = "Learned to survive on nothing.",
                }
                modifiers[#modifiers + 1] = {
                    source = "famine_scarcity",
                    trait = "CRE_RES",
                    bonus = 5,
                    description = "Resourcefulness born of necessity.",
                }
            end
            if cond.type == "war_weariness" and cond.remaining_gens > 0 then
                modifiers[#modifiers + 1] = {
                    source = "war_weariness",
                    trait = "PHY_END",
                    bonus = -3,
                    description = "Born in the shadow of a war that settled nothing.",
                }
                modifiers[#modifiers + 1] = {
                    source = "war_weariness",
                    trait = "MEN_COM",
                    bonus = 2,
                    description = "The exhaustion of the elders bred stoicism in the young.",
                }
            end
            if cond.type == "prosperity" and cond.remaining_gens > 0 then
                modifiers[#modifiers + 1] = {
                    source = "prosperity_abundance",
                    trait = "SOC_AWR",
                    bonus = 3,
                    description = "Raised in abundance — learned to read a room.",
                }
                modifiers[#modifiers + 1] = {
                    source = "prosperity_abundance",
                    trait = "SOC_HUM",
                    bonus = 2,
                    description = "Courts breed wit. Laughter is a currency.",
                }
                modifiers[#modifiers + 1] = {
                    source = "prosperity_abundance",
                    trait = "PHY_LON",
                    bonus = 3,
                    description = "A life of plenty extends the years.",
                }
            end
        end
    end

    -- 2. Cultural memory priority modifiers (top 2 family-valued categories)
    if cultural_memory and cultural_memory.trait_priorities then
        local cat_sums = { physical = 0, mental = 0, social = 0, creative = 0 }
        local cat_counts = { physical = 0, mental = 0, social = 0, creative = 0 }
        local prefix_to_cat = { PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" }

        for id, priority in pairs(cultural_memory.trait_priorities) do
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

        -- Top family category gets a small nurture bonus
        if cat_avgs[1] and cat_avgs[1].avg > 55 then
            local cat = cat_avgs[1].cat
            local cat_labels = {
                physical = "BODY", mental = "MIND", social = "WORD", creative = "ART",
            }
            -- Pick the representative trait for the category
            local rep_traits = {
                physical = "PHY_STR", mental = "MEN_INT",
                social = "SOC_CHA", creative = "CRE_ING",
            }
            modifiers[#modifiers + 1] = {
                source = "scholarly_lineage",
                trait = rep_traits[cat] or "MEN_INT",
                bonus = 3,
                description = "Raised in a lineage that prizes " .. (cat_labels[cat] or cat) .. ".",
            }
        end
    end

    -- 3. Era-based modifiers
    local era_modifiers = {
        ancient = { trait = "PHY_ADP", bonus = 3, description = "The old world demands adaptability." },
        iron = { trait = "PHY_END", bonus = 3, description = "Iron age endurance." },
        dark = { trait = "PHY_VIT", bonus = 3, description = "Only the vital survive the rotting years." },
        arcane = { trait = "MEN_ABS", bonus = 4, description = "Magic seeps into growing minds." },
        gilded = { trait = "SOC_AWR", bonus = 3, description = "Court intrigue is the first lesson." },
        twilight = { trait = "MEN_WIL", bonus = 4, description = "The twilight demands iron will." },
    }
    local era_mod = era_modifiers[era_key]
    if era_mod then
        modifiers[#modifiers + 1] = {
            source = "era_influence",
            trait = era_mod.trait,
            bonus = era_mod.bonus,
            description = era_mod.description,
        }
    end

    -- 4. Discovery bonuses (permanent unlocks apply as nurture)
    if discoveries then
        local effects = discoveries:get_effects()
        if effects and effects.trait_bonuses then
            for trait_id, bonus in pairs(effects.trait_bonuses) do
                if bonus > 0 then
                    modifiers[#modifiers + 1] = {
                        source = "discovery",
                        trait = trait_id,
                        bonus = bonus,
                        description = "Knowledge passed down through generations.",
                    }
                end
            end
        end
    end

    -- Cap at 5 modifiers (most impactful)
    if #modifiers > 5 then
        table.sort(modifiers, function(a, b) return a.bonus > b.bonus end)
        local capped = {}
        for i = 1, 5 do capped[i] = modifiers[i] end
        modifiers = capped
    end

    return modifiers
end

--- Apply nurture modifiers to a genome.
---@param genome table Genome
---@param modifiers table array from compute()
function Nurture.apply(genome, modifiers)
    genome.mastery_tags = genome.mastery_tags or {}

    for _, mod in ipairs(modifiers) do
        local trait = genome:get_trait(mod.trait)
        if trait then
            trait:set_value(trait:get_value() + mod.bonus)
        end

        -- Store education mastery if present
        if mod.mastery_tag then
            genome.mastery_tags[mod.mastery_tag] = true
        end
    end
end

return Nurture
