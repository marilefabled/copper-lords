-- dredwork Notebook — Discovery System
-- You don't get told how the world works. You DISCOVER it.
-- Each entry is something you learned through living.
--
-- "You've noticed bread costs more after dry months."
-- "The mountain people consider bears sacred."
-- "When the crime rate rises, the tavern gets busier."
-- "Your dog seems restless before storms."
--
-- Not a tutorial. Not a codex. A record of understanding.
-- The world teaches you its rules if you pay attention.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Notebook = {}
Notebook.__index = Notebook

-- Discovery categories
local CATEGORIES = {
    economy   = { label = "Trade & Wealth", color = "amber" },
    politics  = { label = "Power & Law", color = "red" },
    military  = { label = "War & Strength", color = "steel" },
    religion  = { label = "Faith & Ritual", color = "gold" },
    culture   = { label = "People & Custom", color = "warm" },
    nature    = { label = "Land & Beast", color = "green" },
    crime     = { label = "Shadow & Vice", color = "dark" },
    personal  = { label = "Self & Bond", color = "purple" },
    secrets   = { label = "Hidden Knowledge", color = "blood" },
}

-- Discovery definitions: condition → entry
-- Each discovery checks game state and unlocks when conditions are met.
-- The player discovers the rule by experiencing it.
local DISCOVERIES = {
    -- ECONOMY
    {
        id = "bread_prices_drought",
        category = "economy",
        text = "Bread costs more in dry months. The harvest dictates the market.",
        condition = function(gs)
            if not gs.markets then return false end
            for _, m in pairs(gs.markets) do
                if m.prices and m.prices.food and m.prices.food > 12 then return true end
            end
            return false
        end,
    },
    {
        id = "trade_routes_matter",
        category = "economy",
        text = "Prices are lower in regions with trade routes. Isolation breeds scarcity.",
        condition = function(gs)
            return gs.economy and gs.economy.trade_routes and #gs.economy.trade_routes > 0
        end,
    },
    {
        id = "taxes_unrest",
        category = "economy",
        text = "High taxes breed resentment. The treasury fills while loyalty drains.",
        condition = function(gs)
            return gs.politics and (gs.politics.tax_rate or 0) > 30 and (gs.politics.unrest or 0) > 30
        end,
    },

    -- POLITICS
    {
        id = "legitimacy_matters",
        category = "politics",
        text = "Legitimacy is everything. Without it, even loyal subjects begin to doubt.",
        condition = function(gs)
            return gs.politics and (gs.politics.legitimacy or 50) < 30
        end,
    },
    {
        id = "military_suppresses_unrest",
        category = "politics",
        text = "A strong military quiets dissent. Fear and safety walk the same road.",
        condition = function(gs)
            return gs.politics and (gs.politics.unrest or 0) > 40 and
                   gs.military and (gs.military.total_power or 0) > 60
        end,
    },
    {
        id = "cruelty_suppresses_unrest",
        category = "politics",
        text = "Your cruelty keeps the people in line. They're too afraid to rebel. For now.",
        condition = function(gs)
            return gs.patterns and gs.patterns.tag_counts and
                   (gs.patterns.tag_counts.cruelty or 0) >= 5 and
                   gs.politics and (gs.politics.unrest or 0) < 20
        end,
    },

    -- RELIGION
    {
        id = "sacred_animals",
        category = "religion",
        text = "Some animals are sacred. Harming them is heresy. Protecting them is devotion.",
        condition = function(gs)
            return gs.religion and gs.religion.active_faith and
                   gs.religion.active_faith.sacred_species and
                   #gs.religion.active_faith.sacred_species > 0
        end,
    },
    {
        id = "zeal_intolerance",
        category = "religion",
        text = "High zeal makes the faithful fervent — and intolerant. Diversity becomes danger.",
        condition = function(gs)
            return gs.religion and gs.religion.active_faith and
                   gs.religion.active_faith.attributes and
                   (gs.religion.active_faith.attributes.zeal or 0) > 60 and
                   (gs.religion.diversity or 0) > 30
        end,
    },

    -- NATURE
    {
        id = "wolves_fear",
        category = "nature",
        text = "When wolves grow numerous, people grow afraid. Fear changes how they act.",
        condition = function(gs)
            if not gs.animals or not gs.animals.regional_populations then return false end
            for _, pops in pairs(gs.animals.regional_populations) do
                if pops.wolves and (pops.wolves.density or 0) > 50 then return true end
            end
            return false
        end,
    },
    {
        id = "rats_disease",
        category = "nature",
        text = "Rats carry more than filth. Where they thrive, plague follows.",
        condition = function(gs)
            if not gs.animals or not gs.animals.regional_populations then return false end
            for _, pops in pairs(gs.animals.regional_populations) do
                if pops.rats and (pops.rats.density or 0) > 40 then return true end
            end
            return false
        end,
    },
    {
        id = "pet_comfort",
        category = "nature",
        text = "Your companion's presence is a comfort. The simplest kind. The best kind.",
        condition = function(gs)
            return gs.animals and gs.animals.pets and #gs.animals.pets > 0
        end,
    },
    {
        id = "pet_guard",
        category = "nature",
        text = "A loyal hound guards more than the door. They guard your peace of mind.",
        condition = function(gs)
            if not gs.animals or not gs.animals.pets then return false end
            for _, pet in ipairs(gs.animals.pets) do
                if not pet.is_dead and pet.species_key == "hound" then return true end
            end
            return false
        end,
    },

    -- MILITARY
    {
        id = "morale_matters",
        category = "military",
        text = "Numbers don't win battles. Morale does. Broken soldiers flee regardless of orders.",
        condition = function(gs)
            if not gs.military or not gs.military.units then return false end
            for _, u in ipairs(gs.military.units) do
                if (u.morale or 50) < 20 then return true end
            end
            return false
        end,
    },
    {
        id = "conquest_tribute",
        category = "military",
        text = "Conquered territories pay tribute. Empire is expensive, but the rewards are real.",
        condition = function(gs)
            return gs.empire and gs.empire.territories and #gs.empire.territories > 0
        end,
    },

    -- CRIME
    {
        id = "corruption_spreads",
        category = "crime",
        text = "Corruption breeds corruption. Once the rot sets in, it's hard to cut out.",
        condition = function(gs)
            return gs.underworld and (gs.underworld.global_corruption or 0) > 40
        end,
    },
    {
        id = "crime_unrest_link",
        category = "crime",
        text = "Crime thrives in chaos. When the people are restless, the underworld grows bold.",
        condition = function(gs)
            return gs.politics and (gs.politics.unrest or 0) > 40 and
                   gs.underworld and (gs.underworld.global_corruption or 0) > 30
        end,
    },

    -- CULTURE
    {
        id = "tradition_vs_progress",
        category = "culture",
        text = "Tradition resists change. Progress demands it. Every society is pulled between them.",
        condition = function(gs)
            return gs.culture and gs.culture.axes and
                   gs.culture.axes.tradition_progress and
                   math.abs((gs.culture.axes.tradition_progress or 50) - 50) > 20
        end,
    },
    {
        id = "culture_tech_link",
        category = "culture",
        text = "Progressive cultures invent faster. Tradition preserves — but it doesn't discover.",
        condition = function(gs)
            return gs.technology and gs.technology.fields and
                   gs.culture and gs.culture.axes and
                   (gs.culture.axes.tradition_progress or 50) > 65
        end,
    },

    -- PERSONAL
    {
        id = "mercy_reputation",
        category = "personal",
        text = "People notice mercy. It becomes a reputation. Reputations become expectations.",
        condition = function(gs)
            return gs.patterns and gs.patterns.tag_counts and
                   (gs.patterns.tag_counts.mercy or 0) >= 3
        end,
    },
    {
        id = "grudges_persist",
        category = "personal",
        text = "Grudges fade — but slowly. What you did to someone stays with them for months.",
        condition = function(gs)
            return gs.echoes and gs.echoes.triggered and #gs.echoes.triggered > 0
        end,
    },
    {
        id = "needs_drive_behavior",
        category = "personal",
        text = "Desperate people do desperate things. Watch someone's needs, predict their actions.",
        condition = function(gs)
            if not gs.entities or not gs.entities.registry then return false end
            for _, e in pairs(gs.entities.registry) do
                if e.alive and e.components and e.components.needs then
                    for _, v in pairs(e.components.needs) do
                        if type(v) == "number" and v < 20 then return true end
                    end
                end
            end
            return false
        end,
    },
    {
        id = "location_shapes_perception",
        category = "personal",
        text = "Where you stand changes what you see. The tavern reveals different truths than the court.",
        condition = function(gs)
            -- Unlocked after visiting 3+ different location types
            return gs._locations_visited and gs._locations_visited >= 3
        end,
    },

    -- SECRETS
    {
        id = "suspicion_grows",
        category = "secrets",
        text = "Suspicion grows when you act in the shadows. Every scheme leaves a trace.",
        condition = function(gs)
            return gs.claim and (gs.claim.suspicion or 0) > 30
        end,
    },
    {
        id = "echoes_return",
        category = "secrets",
        text = "The past returns. Not as memory — as people. Choices echo through the months.",
        condition = function(gs)
            return gs.echoes and gs.echoes.triggered and #gs.echoes.triggered >= 2
        end,
    },
}

function Notebook.init(engine)
    local self = setmetatable({}, Notebook)
    self.engine = engine

    engine.game_state.notebook = {
        discovered = {},     -- id → { text, category, day_discovered }
        total_count = 0,
        locations_visited = {},  -- track for location discovery
    }

    -- Track location visits
    engine:on("ENTITY_MOVED", function(ctx)
        if not ctx then return end
        local entities = engine:get_module("entities")
        local focal = entities and entities:get_focus()
        if not focal or ctx.entity_id ~= focal.id then return end

        local nb = engine.game_state.notebook
        if ctx.location_type and not nb.locations_visited[ctx.location_type] then
            nb.locations_visited[ctx.location_type] = true
            engine.game_state._locations_visited = 0
            for _ in pairs(nb.locations_visited) do
                engine.game_state._locations_visited = engine.game_state._locations_visited + 1
            end
        end
    end)

    -- Check for new discoveries monthly
    engine:on("NEW_MONTH", function(clock)
        self:check_discoveries(engine.game_state, clock)
    end)

    return self
end

function Notebook:check_discoveries(gs, clock)
    local day = clock and clock.total_days or 0
    local nb = gs.notebook
    local new_count = 0

    for _, disc in ipairs(DISCOVERIES) do
        if nb.discovered[disc.id] then goto skip end

        local ok, result = pcall(disc.condition, gs)
        if ok and result then
            nb.discovered[disc.id] = {
                text = disc.text,
                category = disc.category,
                day_discovered = day,
            }
            nb.total_count = nb.total_count + 1
            new_count = new_count + 1

            -- Announce the discovery
            self.engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = disc.text,
                priority = 55,
                display_hint = "discovery",
                tags = { "discovery", disc.category },
                timestamp = day,
            })

            self.engine:emit("DISCOVERY_MADE", {
                id = disc.id,
                category = disc.category,
                text = disc.text,
            })

            -- Only one discovery per month (don't overwhelm)
            if new_count >= 1 then return end
        end

        ::skip::
    end
end

function Notebook:get_all(gs)
    gs = gs or self.engine.game_state
    local result = {}
    for id, entry in pairs(gs.notebook.discovered) do
        table.insert(result, {
            id = id,
            text = entry.text,
            category = entry.category,
            category_label = CATEGORIES[entry.category] and CATEGORIES[entry.category].label or entry.category,
            day = entry.day_discovered,
        })
    end
    table.sort(result, function(a, b) return a.day > b.day end)
    return result
end

function Notebook:get_count(gs)
    gs = gs or self.engine.game_state
    return gs.notebook.total_count
end

function Notebook:get_categories()
    return CATEGORIES
end

function Notebook:serialize() return self.engine.game_state.notebook end
function Notebook:deserialize(data) self.engine.game_state.notebook = data end

return Notebook
