-- Dark Legacy — Dynasty Milestones
-- ~30 trackable achievements per run that pop as toasts when reached.
-- Each milestone fires once per run.
-- Pure Lua, zero Solar2D dependencies.

local Milestones = {}

-- Milestone definitions
local milestone_defs = {
    -- ========== SURVIVAL ==========
    {
        id = "endured_plague",
        title = "Endured the Plague",
        description = "Survived a generation under plague conditions.",
        icon_hint = "skull",
        category = "survival",
        check = function(ctx)
            return ctx.has_plague
        end,
    },
    {
        id = "endured_famine",
        title = "Endured the Famine",
        description = "Survived a generation under famine conditions.",
        icon_hint = "wheat",
        category = "survival",
        check = function(ctx)
            return ctx.has_famine
        end,
    },
    {
        id = "endured_war",
        title = "Survived the War",
        description = "Survived a generation during wartime.",
        icon_hint = "sword",
        category = "survival",
        check = function(ctx)
            return ctx.has_war
        end,
    },
    {
        id = "iron_bloodline",
        title = "Iron Bloodline",
        description = "The dynasty has endured 10 generations.",
        icon_hint = "shield",
        category = "survival",
        check = function(ctx)
            return ctx.generation >= 10
        end,
    },
    {
        id = "ancient_dynasty",
        title = "Ancient Dynasty",
        description = "The dynasty has endured 25 generations.",
        icon_hint = "crown",
        category = "survival",
        check = function(ctx)
            return ctx.generation >= 25
        end,
    },
    {
        id = "eternal",
        title = "Eternal",
        description = "The dynasty has endured 50 generations.",
        icon_hint = "star",
        category = "survival",
        check = function(ctx)
            return ctx.generation >= 50
        end,
    },
    {
        id = "triple_threat",
        title = "The Triple Threat",
        description = "Survived plague, famine, and war simultaneously.",
        icon_hint = "fire",
        category = "survival",
        check = function(ctx)
            return ctx.has_plague and ctx.has_famine and ctx.has_war
        end,
    },

    -- ========== GENETICS ==========
    {
        id = "legendary_trait",
        title = "Legendary Trait",
        description = "An heir with a trait value of 90 or above.",
        icon_hint = "gem",
        category = "genetics",
        check = function(ctx)
            return ctx.max_trait >= 90
        end,
    },
    {
        id = "perfect_specimen",
        title = "Perfect Specimen",
        description = "An heir with 5 or more traits above 80.",
        icon_hint = "diamond",
        category = "genetics",
        check = function(ctx)
            return ctx.traits_above_80 >= 5
        end,
    },
    {
        id = "the_mutation",
        title = "The Mutation",
        description = "3 or more mutations in a single generation.",
        icon_hint = "dna",
        category = "genetics",
        check = function(ctx)
            return ctx.mutation_count >= 3
        end,
    },
    {
        id = "genetic_collapse",
        title = "Genetic Collapse",
        description = "An heir with 3 or more traits below 25.",
        icon_hint = "broken",
        category = "genetics",
        check = function(ctx)
            return ctx.traits_below_25 >= 3
        end,
    },

    -- ========== SOCIAL ==========
    {
        id = "first_alliance",
        title = "First Alliance",
        description = "Formed the first alliance with a rival house.",
        icon_hint = "handshake",
        category = "social",
        check = function(ctx)
            return ctx.allied_factions >= 1
        end,
    },
    {
        id = "blood_feud",
        title = "Blood Feud",
        description = "Made 3 or more enemy factions.",
        icon_hint = "dagger",
        category = "social",
        check = function(ctx)
            return ctx.enemy_factions >= 3
        end,
    },
    {
        id = "kingmaker",
        title = "Kingmaker",
        description = "Shifted the power balance of the realm.",
        icon_hint = "crown",
        category = "social",
        check = function(ctx)
            return ctx.faction_shifts >= 3
        end,
    },
    {
        id = "universal_disdain",
        title = "Universally Despised",
        description = "All active factions are hostile.",
        icon_hint = "skull",
        category = "social",
        check = function(ctx)
            return ctx.all_factions_hostile
        end,
    },

    -- ========== CULTURAL ==========
    {
        id = "identity_forged",
        title = "Identity Forged",
        description = "Family reputation locked for 5+ generations.",
        icon_hint = "scroll",
        category = "cultural",
        check = function(ctx)
            return ctx.reputation_locked_gens >= 5
        end,
    },
    {
        id = "taboo_formed",
        title = "First Taboo",
        description = "The family's first taboo was formed.",
        icon_hint = "chain",
        category = "cultural",
        check = function(ctx)
            return ctx.taboo_count >= 1
        end,
    },
    {
        id = "heavily_burdened",
        title = "Heavily Burdened",
        description = "The family carries 5 or more taboos.",
        icon_hint = "weight",
        category = "cultural",
        check = function(ctx)
            return ctx.taboo_count >= 5
        end,
    },
    {
        id = "the_shift",
        title = "The Shift",
        description = "Family reputation changed to a new archetype.",
        icon_hint = "arrows",
        category = "cultural",
        check = function(ctx)
            return ctx.reputation_changed
        end,
    },
    {
        id = "new_era",
        title = "New Dawn",
        description = "The world shifted to a new era.",
        icon_hint = "sun",
        category = "cultural",
        check = function(ctx)
            return ctx.era_shifted
        end,
    },

    -- ========== DRAMA ==========
    {
        id = "back_from_brink",
        title = "Back from the Brink",
        description = "Heir survived with >30% death chance.",
        icon_hint = "heart",
        category = "drama",
        check = function(ctx)
            return ctx.heir_death_chance and ctx.heir_death_chance > 0.30 and not ctx.heir_died
        end,
    },
    {
        id = "last_of_the_line",
        title = "Last of the Line",
        description = "Only 1 child survived this generation.",
        icon_hint = "candle",
        category = "drama",
        check = function(ctx)
            return ctx.surviving_children == 1 and ctx.total_children_attempted >= 2
        end,
    },
    {
        id = "the_black_sheep",
        title = "The Black Sheep",
        description = "An heir who contradicts the family identity.",
        icon_hint = "mask",
        category = "drama",
        check = function(ctx)
            return ctx.is_black_sheep
        end,
    },
    {
        id = "near_extinction",
        title = "Near Extinction",
        description = "Survived with 0 children — but heir persisted.",
        icon_hint = "flame",
        category = "drama",
        check = function(ctx)
            return ctx.near_extinction
        end,
    },
    {
        id = "first_legend",
        title = "First Legend",
        description = "An heir earned a legendary title.",
        icon_hint = "star",
        category = "drama",
        check = function(ctx)
            return ctx.has_legend
        end,
    },

    -- ========== SPECIAL ==========
    {
        id = "age_of_myth",
        title = "Children of Myth",
        description = "Started in the Age of Myth.",
        icon_hint = "book",
        category = "special",
        check = function(ctx)
            return ctx.start_era == "ancient" and ctx.generation == 1
        end,
    },
    {
        id = "twilight_reached",
        title = "The Twilight",
        description = "Reached the final era.",
        icon_hint = "moon",
        category = "special",
        check = function(ctx)
            return ctx.current_era == "twilight"
        end,
    },
    {
        id = "dynasty_of_scholars",
        title = "Dynasty of Scholars",
        description = "Mental trait priority above 70 for 3+ generations.",
        icon_hint = "book",
        category = "special",
        check = function(ctx)
            return ctx.mental_priority_high_gens >= 3
        end,
    },
    {
        id = "dynasty_of_warriors",
        title = "Dynasty of Warriors",
        description = "Physical trait priority above 70 for 3+ generations.",
        icon_hint = "sword",
        category = "special",
        check = function(ctx)
            return ctx.physical_priority_high_gens >= 3
        end,
    },

    -- ========== EMERGENT ==========
    {
        id = "dream_fulfilled",
        title = "Dream Realized",
        description = "The bloodline achieved what the ancestors envisioned.",
        icon_hint = "star",
        category = "special",
        check = function(ctx)
            return ctx.dream_fulfilled
        end,
    },
    {
        id = "ascending_blood",
        title = "Ascending Blood",
        description = "A trait category ascended for 3+ consecutive generations.",
        icon_hint = "arrow_up",
        category = "genetics",
        check = function(ctx)
            return ctx.has_ascending_momentum
        end,
    },
    {
        id = "fossil_restored",
        title = "Blood Remembers",
        description = "Restored a trait that had been lost to the generations.",
        icon_hint = "gem",
        category = "genetics",
        check = function(ctx)
            return ctx.has_fossil_restoration
        end,
    },
    {
        id = "ancestor_echo",
        title = "Echoes of the Past",
        description = "An heir whose traits echoed a distant ancestor.",
        icon_hint = "ghost",
        category = "drama",
        check = function(ctx)
            return ctx.has_ancestor_echo
        end,
    },
}

--- Build evaluation context from game data.
---@param params table
---@return table context
local function build_context(params)
    local ctx = {}

    -- Basic info
    ctx.generation = params.generation or 1
    ctx.start_era = params.start_era
    ctx.current_era = params.current_era

    -- World conditions
    ctx.has_plague = false
    ctx.has_famine = false
    ctx.has_war = false
    if params.conditions then
        for _, cond in ipairs(params.conditions) do
            if cond.type == "plague" then ctx.has_plague = true end
            if cond.type == "famine" then ctx.has_famine = true end
            if cond.type == "war" then ctx.has_war = true end
        end
    end

    -- Trait analysis
    ctx.max_trait = 0
    ctx.traits_above_80 = 0
    ctx.traits_below_25 = 0
    if params.heir_genome then
        local all_traits = params.heir_genome.traits or {}
        for _, trait in pairs(all_traits) do
            local val = trait:get_value()
            if val > ctx.max_trait then ctx.max_trait = val end
            if val >= 80 then ctx.traits_above_80 = ctx.traits_above_80 + 1 end
            if val < 25 then ctx.traits_below_25 = ctx.traits_below_25 + 1 end
        end
    end

    -- Mutation count
    ctx.mutation_count = params.mutation_count or 0

    -- Faction analysis
    ctx.allied_factions = 0
    ctx.enemy_factions = 0
    ctx.all_factions_hostile = false
    ctx.faction_shifts = params.faction_shifts or 0
    if params.factions then
        local active = params.factions:get_active()
        local hostile_count = 0
        for _, f in ipairs(active) do
            if f:is_friendly() then ctx.allied_factions = ctx.allied_factions + 1 end
            if f:is_hostile() then
                ctx.enemy_factions = ctx.enemy_factions + 1
                hostile_count = hostile_count + 1
            end
        end
        if #active > 0 and hostile_count == #active then
            ctx.all_factions_hostile = true
        end
    end

    -- Cultural memory
    ctx.taboo_count = 0
    ctx.reputation_changed = params.reputation_changed or false
    ctx.reputation_locked_gens = params.reputation_locked_gens or 0
    if params.cultural_memory then
        ctx.taboo_count = params.cultural_memory.taboos and #params.cultural_memory.taboos or 0
    end

    -- Era
    ctx.era_shifted = params.era_shifted or false

    -- Drama
    ctx.heir_death_chance = params.heir_death_chance
    ctx.heir_died = params.heir_died or false
    ctx.surviving_children = params.surviving_children
    ctx.total_children_attempted = params.total_children_attempted
    ctx.is_black_sheep = params.is_black_sheep or false
    ctx.near_extinction = params.near_extinction or false
    ctx.has_legend = params.has_legend or false

    -- Priority tracking
    ctx.mental_priority_high_gens = params.mental_priority_high_gens or 0
    ctx.physical_priority_high_gens = params.physical_priority_high_gens or 0

    -- Emergent systems
    ctx.dream_fulfilled = params.dream_fulfilled or false
    ctx.has_ascending_momentum = params.has_ascending_momentum or false
    ctx.has_fossil_restoration = params.has_fossil_restoration or false
    ctx.has_ancestor_echo = params.has_ancestor_echo or false

    return ctx
end

--- Check for newly triggered milestones.
---@param params table game context data
---@param achieved table|nil array of already achieved milestone IDs
---@return table array of { id, title, description, icon_hint }
function Milestones.check(params, achieved)
    achieved = achieved or {}

    -- Build set of already achieved
    local achieved_set = {}
    for _, a in ipairs(achieved) do
        local aid = type(a) == "table" and a.id or a
        achieved_set[aid] = true
    end

    local ctx = build_context(params)
    local newly_triggered = {}

    for _, def in ipairs(milestone_defs) do
        if not achieved_set[def.id] then
            local ok, matches = pcall(def.check, ctx)
            if ok and matches then
                newly_triggered[#newly_triggered + 1] = {
                    id = def.id,
                    title = def.title,
                    description = def.description,
                    icon_hint = def.icon_hint,
                }
            end
        end
    end

    return newly_triggered
end

--- Get total number of milestone definitions.
---@return number
function Milestones.get_total_count()
    return #milestone_defs
end

--- Get all milestone definitions (for testing/display).
---@return table
function Milestones.get_all_definitions()
    return milestone_defs
end

return Milestones
