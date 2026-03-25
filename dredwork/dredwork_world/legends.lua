-- Dark Legacy — Lineage Legends (Emergent Titles)
-- Automatically detects remarkable trait/personality/event combinations
-- and awards titles to heirs. Pure Lua, zero Solar2D dependencies.
-- One title per heir max. Highest-priority match wins.

local rng = require("dredwork_core.rng")
local Legends = {}

-- Priority tiers: higher = rarer, wins over lower
local PRIORITY = {
    mythic    = 100,  -- once-in-a-dynasty moments
    rare      = 80,   -- very unusual combinations
    dramatic  = 60,   -- event-driven, memorable
    notable   = 40,   -- statistical outliers
    common    = 20,   -- solid but less unique
}

-- Title templates: {era} {lineage} {faction} are substituted at runtime
local legend_conditions = {
    -- ========== FEARED ==========
    {
        id = "the_butcher",
        category = "feared",
        priority = PRIORITY.rare,
        titles = {
            "The Butcher of the {era}",
            "The Red Hand of {era}",
            "{heir_name} the Merciless",
        },
        check = function(ctx)
            return ctx.cruelty >= 85 and ctx.strength >= 70 and ctx.has_war
        end,
    },
    {
        id = "the_tyrant",
        category = "feared",
        priority = PRIORITY.dramatic,
        titles = {
            "{heir_name} the Tyrant",
            "The Iron Fist of {lineage}",
        },
        check = function(ctx)
            return ctx.cruelty >= 80 and ctx.pride >= 75 and ctx.intimidation >= 70
        end,
    },
    {
        id = "the_dread",
        category = "feared",
        priority = PRIORITY.notable,
        titles = {
            "{heir_name} the Dread",
            "The Terror of {era}",
        },
        check = function(ctx)
            return ctx.cruelty >= 75 and ctx.volatility >= 75
        end,
    },

    -- ========== BELOVED ==========
    {
        id = "the_beloved",
        category = "beloved",
        priority = PRIORITY.dramatic,
        titles = {
            "{heir_name} the Beloved",
            "The Light of {lineage}",
            "The People's {heir_name}",
        },
        check = function(ctx)
            return ctx.cruelty <= 20 and ctx.charisma >= 80 and ctx.empathy >= 70
        end,
    },
    {
        id = "the_merciful",
        category = "beloved",
        priority = PRIORITY.notable,
        titles = {
            "{heir_name} the Merciful",
            "Gentle {heir_name}",
        },
        check = function(ctx)
            return ctx.cruelty <= 15 and ctx.loyalty >= 70
        end,
    },
    {
        id = "the_healer",
        category = "beloved",
        priority = PRIORITY.rare,
        titles = {
            "{heir_name} the Healer",
            "The Mender of {lineage}",
        },
        check = function(ctx)
            return ctx.cruelty <= 20 and ctx.has_plague and ctx.immune >= 80 and ctx.vitality >= 75
        end,
    },

    -- ========== CURSED ==========
    {
        id = "the_cursed",
        category = "cursed",
        priority = PRIORITY.rare,
        titles = {
            "{heir_name} the Cursed",
            "The Blight of {lineage}",
        },
        check = function(ctx)
            return ctx.child_deaths >= 2 and ctx.has_plague and ctx.vitality <= 35
        end,
    },
    {
        id = "the_doomed",
        category = "cursed",
        priority = PRIORITY.dramatic,
        titles = {
            "{heir_name} the Doomed",
            "Last Breath of {lineage}",
        },
        check = function(ctx)
            return ctx.vitality <= 20 and ctx.longevity <= 25
        end,
    },
    {
        id = "plague_bearer",
        category = "cursed",
        priority = PRIORITY.notable,
        titles = {
            "{heir_name}, Plague-Touched",
            "The Sickly One",
        },
        check = function(ctx)
            return ctx.has_plague and ctx.immune <= 25 and ctx.vitality <= 40
        end,
    },

    -- ========== GENIUS ==========
    {
        id = "the_genius",
        category = "genius",
        priority = PRIORITY.rare,
        titles = {
            "{heir_name} the Brilliant",
            "The Great Mind of {era}",
            "The Prodigy of {lineage}",
        },
        check = function(ctx)
            return ctx.mental_above_85 >= 3
        end,
    },
    {
        id = "the_sage",
        category = "genius",
        priority = PRIORITY.notable,
        titles = {
            "{heir_name} the Sage",
            "Wise {heir_name}",
        },
        check = function(ctx)
            return ctx.intellect >= 85 and ctx.curiosity >= 75
        end,
    },
    {
        id = "the_mastermind",
        category = "genius",
        priority = PRIORITY.dramatic,
        titles = {
            "{heir_name} the Mastermind",
            "The Architect of {lineage}'s Rise",
        },
        check = function(ctx)
            return ctx.intellect >= 80 and ctx.cunning >= 80 and ctx.strategic >= 75
        end,
    },

    -- ========== MONSTER ==========
    {
        id = "the_monster",
        category = "monster",
        priority = PRIORITY.mythic,
        titles = {
            "{heir_name} the Monster",
            "The Abomination of {lineage}",
            "The Beast of {era}",
        },
        check = function(ctx)
            return ctx.cruelty >= 90 and ctx.volatility >= 80
        end,
    },
    {
        id = "the_mad",
        category = "monster",
        priority = PRIORITY.rare,
        titles = {
            "Mad {heir_name}",
            "{heir_name} the Unhinged",
        },
        check = function(ctx)
            return ctx.volatility >= 90 and ctx.composure <= 20
        end,
    },

    -- ========== SURVIVOR ==========
    {
        id = "the_survivor",
        category = "survivor",
        priority = PRIORITY.rare,
        titles = {
            "{heir_name} the Unkillable",
            "The Survivor of {era}",
            "{heir_name} Who Would Not Die",
        },
        check = function(ctx)
            return ctx.survived_death_check and ctx.has_plague and ctx.has_famine
        end,
    },
    {
        id = "iron_will",
        category = "survivor",
        priority = PRIORITY.notable,
        titles = {
            "{heir_name}, Iron Will",
            "The Unbroken",
        },
        check = function(ctx)
            return ctx.survived_death_check and ctx.willpower >= 80
        end,
    },
    {
        id = "plague_survivor",
        category = "survivor",
        priority = PRIORITY.common,
        titles = {
            "{heir_name}, Plague Survivor",
            "The One Who Endured",
        },
        check = function(ctx)
            return ctx.survived_death_check and ctx.has_plague
        end,
    },

    -- ========== BREAKER ==========
    {
        id = "the_breaker",
        category = "breaker",
        priority = PRIORITY.mythic,
        titles = {
            "{heir_name} the Breaker",
            "The One Who Changed Everything",
            "The Heretic of {lineage}",
        },
        check = function(ctx)
            return ctx.is_black_sheep and ctx.cultural_shift > 15
        end,
    },
    {
        id = "the_rebel",
        category = "breaker",
        priority = PRIORITY.dramatic,
        titles = {
            "{heir_name} the Rebel",
            "The Defiant One",
        },
        check = function(ctx)
            return ctx.is_black_sheep and ctx.boldness >= 75
        end,
    },

    -- ========== ANCIENT ==========
    {
        id = "the_eternal",
        category = "ancient",
        priority = PRIORITY.mythic,
        titles = {
            "The Eternal Line of {lineage}",
            "{lineage}, Undying",
        },
        check = function(ctx)
            return ctx.generation >= 50
        end,
    },
    {
        id = "the_ancient",
        category = "ancient",
        priority = PRIORITY.rare,
        titles = {
            "{heir_name} of the Ancient Blood",
            "Elder {heir_name}",
        },
        check = function(ctx)
            return ctx.generation >= 30
        end,
    },

    -- ========== KINGMAKER ==========
    {
        id = "the_kingmaker",
        category = "kingmaker",
        priority = PRIORITY.rare,
        titles = {
            "{heir_name} the Kingmaker",
            "The Power Behind {lineage}",
        },
        check = function(ctx)
            return ctx.faction_shifts >= 3
        end,
    },
    {
        id = "the_diplomat",
        category = "kingmaker",
        priority = PRIORITY.notable,
        titles = {
            "{heir_name} the Diplomat",
            "The Peacemaker",
        },
        check = function(ctx)
            return ctx.charisma >= 75 and ctx.negotiation >= 75 and ctx.faction_shifts >= 1
        end,
    },

    -- ========== GHOST ==========
    {
        id = "the_ghost",
        category = "ghost",
        priority = PRIORITY.rare,
        titles = {
            "{heir_name} the Ghost",
            "The Empty One",
            "The Hollow Heir",
        },
        check = function(ctx)
            return ctx.personality_below_30 >= 6
        end,
    },
    {
        id = "the_stoic",
        category = "ghost",
        priority = PRIORITY.common,
        titles = {
            "{heir_name} the Stoic",
            "The Unmoved",
        },
        check = function(ctx)
            return ctx.volatility <= 15 and ctx.boldness <= 20 and ctx.pride <= 20
        end,
    },

    -- ========== WARRIOR ==========
    {
        id = "the_champion",
        category = "warrior",
        priority = PRIORITY.dramatic,
        titles = {
            "{heir_name} the Champion",
            "The Blade of {lineage}",
        },
        check = function(ctx)
            return ctx.strength >= 85 and ctx.boldness >= 80 and ctx.has_war
        end,
    },
    {
        id = "the_berserker",
        category = "warrior",
        priority = PRIORITY.rare,
        titles = {
            "{heir_name} the Berserker",
            "The Fury of {era}",
        },
        check = function(ctx)
            return ctx.strength >= 80 and ctx.volatility >= 85 and ctx.boldness >= 75
        end,
    },

    -- ========== ARTISAN ==========
    {
        id = "the_artisan",
        category = "artisan",
        priority = PRIORITY.notable,
        titles = {
            "{heir_name} the Artisan",
            "The Maker of {era}",
        },
        check = function(ctx)
            return ctx.creative_above_85 >= 3
        end,
    },
    {
        id = "the_visionary",
        category = "artisan",
        priority = PRIORITY.rare,
        titles = {
            "{heir_name} the Visionary",
            "The Dreamer of {lineage}",
        },
        check = function(ctx)
            return ctx.vision >= 85 and ctx.ingenuity >= 80 and ctx.curiosity >= 75
        end,
    },

    -- ========== SPECIAL COMBINATIONS ==========
    {
        id = "the_perfect",
        category = "perfect",
        priority = PRIORITY.mythic,
        titles = {
            "{heir_name} the Perfect",
            "The Pinnacle of {lineage}",
        },
        check = function(ctx)
            return ctx.traits_above_80 >= 5
        end,
    },
    {
        id = "the_oathbound",
        category = "loyal",
        priority = PRIORITY.dramatic,
        titles = {
            "{heir_name} the Oathbound",
            "The Faithful of {lineage}",
        },
        check = function(ctx)
            return ctx.loyalty >= 90 and ctx.cruelty <= 30
        end,
    },
    {
        id = "the_obsessed",
        category = "obsessed",
        priority = PRIORITY.dramatic,
        titles = {
            "{heir_name} the Obsessed",
            "The Consumed",
        },
        check = function(ctx)
            return ctx.obsession >= 90 and ctx.focus >= 80
        end,
    },
    {
        id = "the_shapeshifter",
        category = "adaptive",
        priority = PRIORITY.notable,
        titles = {
            "{heir_name} the Shapeshifter",
            "The Adaptable One",
        },
        check = function(ctx)
            return ctx.adaptability >= 90 and ctx.cunning >= 70
        end,
    },
    {
        id = "the_wretched",
        category = "cursed",
        priority = PRIORITY.dramatic,
        titles = {
            "{heir_name} the Wretched",
            "The Ruin of {lineage}",
        },
        check = function(ctx)
            return ctx.physical_below_25 >= 3 and ctx.generation >= 5
        end,
    },
}

--- Build evaluation context from game data.
---@param heir_genome table
---@param heir_personality table
---@param cultural_memory table
---@param world_state table
---@param generation_events table (events resolved this generation)
---@param extra table|nil optional { child_deaths, survived_death_check, is_black_sheep, cultural_shift, faction_shifts }
---@return table context
local function build_context(heir_genome, heir_personality, cultural_memory, world_state, generation_events, extra)
    extra = extra or {}
    local ctx = {}

    -- Trait shortcuts
    ctx.strength = heir_genome:get_value("PHY_STR") or 50
    ctx.vitality = heir_genome:get_value("PHY_VIT") or 50
    ctx.longevity = heir_genome:get_value("PHY_LON") or 50
    ctx.immune = heir_genome:get_value("PHY_IMM") or 50
    ctx.charisma = heir_genome:get_value("SOC_CHA") or 50
    ctx.empathy = heir_genome:get_value("SOC_EMP") or 50
    ctx.intimidation = heir_genome:get_value("SOC_INM") or 50
    ctx.negotiation = heir_genome:get_value("SOC_NEG") or 50
    ctx.intellect = heir_genome:get_value("MEN_INT") or 50
    ctx.cunning = heir_genome:get_value("MEN_CUN") or 50
    ctx.strategic = heir_genome:get_value("MEN_STR") or 50
    ctx.willpower = heir_genome:get_value("MEN_WIL") or 50
    ctx.composure = heir_genome:get_value("MEN_COM") or 50
    ctx.focus = heir_genome:get_value("MEN_FOC") or 50
    ctx.ingenuity = heir_genome:get_value("CRE_ING") or 50
    ctx.vision = heir_genome:get_value("CRE_VIS") or 50

    -- Personality shortcuts
    ctx.boldness = heir_personality and heir_personality:get_axis("PER_BLD") or 50
    ctx.cruelty = heir_personality and heir_personality:get_axis("PER_CRM") or 50
    ctx.obsession = heir_personality and heir_personality:get_axis("PER_OBS") or 50
    ctx.loyalty = heir_personality and heir_personality:get_axis("PER_LOY") or 50
    ctx.curiosity = heir_personality and heir_personality:get_axis("PER_CUR") or 50
    ctx.volatility = heir_personality and heir_personality:get_axis("PER_VOL") or 50
    ctx.pride = heir_personality and heir_personality:get_axis("PER_PRI") or 50
    ctx.adaptability = heir_personality and heir_personality:get_axis("PER_ADA") or 50

    -- Count trait thresholds
    ctx.mental_above_85 = 0
    ctx.creative_above_85 = 0
    ctx.traits_above_80 = 0
    ctx.physical_below_25 = 0
    ctx.personality_below_30 = 0

    -- Count traits per category
    local all_traits = heir_genome.traits or {}
    for _, trait in pairs(all_traits) do
        local val = trait:get_value()
        local cat = trait.category
        if val >= 85 then
            if cat == "mental" then ctx.mental_above_85 = ctx.mental_above_85 + 1 end
            if cat == "creative" then ctx.creative_above_85 = ctx.creative_above_85 + 1 end
        end
        if val >= 80 then ctx.traits_above_80 = ctx.traits_above_80 + 1 end
        if val < 25 and cat == "physical" then ctx.physical_below_25 = ctx.physical_below_25 + 1 end
    end

    -- Count personality axes below 30
    local axes = { "PER_BLD", "PER_CRM", "PER_OBS", "PER_LOY", "PER_CUR", "PER_VOL", "PER_PRI", "PER_ADA" }
    for _, axis in ipairs(axes) do
        local val = heir_personality and heir_personality:get_axis(axis) or 50
        if val < 30 then ctx.personality_below_30 = ctx.personality_below_30 + 1 end
    end

    -- World conditions
    ctx.has_plague = false
    ctx.has_war = false
    ctx.has_famine = false
    if world_state and world_state.conditions then
        for _, cond in ipairs(world_state.conditions) do
            if cond.type == "plague" then ctx.has_plague = true end
            if cond.type == "war" then ctx.has_war = true end
            if cond.type == "famine" then ctx.has_famine = true end
        end
    end

    -- Generation
    ctx.generation = world_state and world_state.generation or 1

    -- Extra context from caller
    ctx.child_deaths = extra.child_deaths or 0
    ctx.survived_death_check = extra.survived_death_check or false
    ctx.is_black_sheep = extra.is_black_sheep or false
    ctx.cultural_shift = extra.cultural_shift or 0
    ctx.faction_shifts = extra.faction_shifts or 0

    -- Era name
    ctx.era = "the age"
    if world_state and world_state.get_era_name then
        ctx.era = world_state:get_era_name() or "the age"
    end

    -- Lineage name
    ctx.lineage = "the bloodline"
    if cultural_memory and cultural_memory.reputation then
        ctx.lineage = cultural_memory.reputation.primary or "the bloodline"
    end

    return ctx
end

--- Substitute variables in a title template.
---@param template string
---@param ctx table evaluation context
---@param heir_name string
---@return string
local function substitute_title(template, ctx, heir_name)
    local result = template
    result = result:gsub("{era}", ctx.era or "the age")
    result = result:gsub("{lineage}", ctx.lineage or "the bloodline")
    result = result:gsub("{heir_name}", heir_name or "the heir")
    return result
end

--- Evaluate an heir for a legend title.
---@param heir_genome table
---@param heir_personality table
---@param cultural_memory table
---@param world_state table
---@param generation_events table
---@param extra table|nil
---@param heir_name string|nil
---@return table|nil { title, category, trigger, id } or nil if no legend earned
function Legends.evaluate(heir_genome, heir_personality, cultural_memory, world_state, generation_events, extra, heir_name)
    local ctx = build_context(heir_genome, heir_personality, cultural_memory, world_state, generation_events, extra)

    local best = nil
    local best_priority = -1

    for _, legend in ipairs(legend_conditions) do
        local ok, matches = pcall(legend.check, ctx)
        if ok and matches then
            if legend.priority > best_priority then
                best = legend
                best_priority = legend.priority
            end
        end
    end

    if not best then return nil end

    -- Pick a random title from the template pool
    local titles = best.titles
    local template = titles[rng.range(1, #titles)]
    local title = substitute_title(template, ctx, heir_name)

    return {
        title = title,
        category = best.category,
        trigger = best.id,
        id = best.id,
    }
end

--- Get all legend condition IDs (for testing).
---@return table array of condition IDs
function Legends.get_all_condition_ids()
    local ids = {}
    for _, legend in ipairs(legend_conditions) do
        ids[#ids + 1] = legend.id
    end
    return ids
end

--- Get total number of legend conditions.
---@return number
function Legends.get_condition_count()
    return #legend_conditions
end

return Legends
