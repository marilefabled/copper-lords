-- dredwork Geography — World Configuration
-- The physical world. Regions, connections, distances, cultural profiles.
-- Separated from code so you can rename, reshape, and rebuild without touching logic.
--
-- NAMING: All region IDs and labels are placeholder archetypes.
-- Replace them with real names when they feel right.
-- The code doesn't care what they're called.
--
-- STRUCTURE: Concentric rings from the capital.
--   Core (1-2 days) → Middle Ring (2-4 days) → Outer Ring (4-6 days) → Edge (7+ days)
--   Distance from power = safety from suspicion, but also isolation from the claim.

local WorldConfig = {}

--------------------------------------------------------------------------------
-- REGIONS
-- Each region: { id, label, biome, archetype, description,
--   culture_profile, population, tags }
--
-- culture_profile: overrides for the 8 culture axes (CUL_TRD, CUL_OPN, etc.)
--   These shift NPC speech, available interactions, and overheard fragments.
--
-- archetype: gameplay role (capital, pastoral, trade, holy, rival_house,
--   contested, free_port, wildlands, distant, pastoral_edge)
--------------------------------------------------------------------------------

WorldConfig.regions = {
    ---------------------------------------------------------------------------
    -- THE CORE
    ---------------------------------------------------------------------------
    {
        id = "capital",
        label = "The Capital",           -- RENAME ME
        biome = "urban",
        archetype = "capital",
        description = "Seat of the ruling house. Where power lives and secrets die.",
        is_capital = true,
        population = "dense",
        culture_profile = {
            CUL_TRD = 55,   -- tradition (moderate — old money respects the old ways)
            CUL_OPN = 40,   -- openness (guarded — outsiders are watched)
            CUL_FAI = 50,   -- mysticism (moderate — faith is political here)
            CUL_MIL = 60,   -- militarism (strong — the crown's army is everywhere)
            CUL_MRC = 65,   -- commerce (high — wealth flows to the capital)
            CUL_JUS = 55,   -- justice (formal courts, harsh for treason)
            CUL_IND = 50,   -- individualism (moderate — you're a subject first)
            CUL_ART = 60,   -- artistry (patronage, theater, propaganda)
        },
        npc_archetypes = { "courtier", "guard", "merchant", "noble", "spy", "servant", "priest" },
        tags = { "dangerous", "rich", "political", "crowded" },
    },
    {
        id = "crownlands",
        label = "The Crownlands",        -- RENAME ME
        biome = "temperate",
        archetype = "pastoral",
        description = "Farmland that feeds the capital. Peaceful villages where big decisions crush little lives.",
        population = "moderate",
        culture_profile = {
            CUL_TRD = 70,   -- deeply traditional
            CUL_OPN = 30,   -- suspicious of outsiders
            CUL_FAI = 60,   -- faith is part of daily life
            CUL_MIL = 35,   -- no soldiers here, just farmers
            CUL_MRC = 40,   -- subsistence, not commerce
            CUL_JUS = 45,   -- village justice, not courts
            CUL_IND = 35,   -- community over individual
            CUL_ART = 30,   -- no time for art, there's plowing to do
        },
        npc_archetypes = { "farmer", "elder", "healer", "wanderer", "child", "widow" },
        tags = { "peaceful", "poor", "traditional", "quiet" },
    },

    ---------------------------------------------------------------------------
    -- THE MIDDLE RING
    ---------------------------------------------------------------------------
    {
        id = "tradecity",
        label = "The Trade City",        -- RENAME ME
        biome = "coastal",
        archetype = "trade",
        description = "Where money flows. Information flows. Crime flows. Everyone's watching everyone.",
        population = "dense",
        culture_profile = {
            CUL_TRD = 30,   -- tradition means nothing when gold talks
            CUL_OPN = 75,   -- everyone's welcome if they have coin
            CUL_FAI = 25,   -- faith is for the poor
            CUL_MIL = 40,   -- private guards, not armies
            CUL_MRC = 85,   -- commerce IS the culture
            CUL_JUS = 35,   -- justice is for sale
            CUL_IND = 70,   -- every person for themselves
            CUL_ART = 55,   -- art as commodity
        },
        npc_archetypes = { "merchant", "sailor", "smuggler", "banker", "entertainer", "foreigner" },
        tags = { "wealthy", "cosmopolitan", "corrupt", "busy" },
    },
    {
        id = "holyseat",
        label = "The Holy Seat",         -- RENAME ME
        biome = "mountain",
        archetype = "holy",
        description = "Where the old faith lives. Archives. Records. Retired witnesses. Truth in stone.",
        population = "sparse",
        culture_profile = {
            CUL_TRD = 80,   -- the old ways ARE the ways
            CUL_OPN = 20,   -- outsiders are heretics until proven otherwise
            CUL_FAI = 90,   -- faith is everything
            CUL_MIL = 25,   -- monks, not soldiers
            CUL_MRC = 20,   -- commerce is sin (mostly)
            CUL_JUS = 70,   -- divine justice, absolute
            CUL_IND = 20,   -- the self dissolves in service
            CUL_ART = 65,   -- illuminated manuscripts, sacred music, architecture
        },
        npc_archetypes = { "priest", "archivist", "pilgrim", "penitent", "scholar", "hermit" },
        tags = { "quiet", "sacred", "isolated", "old" },
    },
    {
        id = "rival_east",
        label = "Eastern Holdings",      -- RENAME ME
        biome = "temperate",
        archetype = "rival_house",
        description = "Their land. Their rules. Their culture. You're a foreigner here.",
        rival_house = "House Ashmark",   -- link to rival house (RENAME)
        population = "moderate",
        culture_profile = {
            CUL_TRD = 65,
            CUL_OPN = 35,
            CUL_FAI = 45,
            CUL_MIL = 70,   -- martial culture
            CUL_MRC = 50,
            CUL_JUS = 60,
            CUL_IND = 55,
            CUL_ART = 35,   -- no time for art, there's training to do
        },
        npc_archetypes = { "soldier", "noble", "servant", "smith", "stablehand", "spy" },
        tags = { "hostile", "martial", "proud", "foreign" },
    },
    {
        id = "rival_south",
        label = "Southern Reach",        -- RENAME ME
        biome = "tropical",
        archetype = "rival_house",
        description = "Lush. Wealthy. Different in ways you don't expect. They smile more here. It means less.",
        rival_house = "House Solara",    -- link to rival house (RENAME)
        population = "moderate",
        culture_profile = {
            CUL_TRD = 25,   -- progressive
            CUL_OPN = 70,   -- welcoming on the surface
            CUL_FAI = 35,   -- faith is personal, not public
            CUL_MIL = 30,
            CUL_MRC = 70,
            CUL_JUS = 40,   -- flexible justice
            CUL_IND = 75,   -- personal freedom valued
            CUL_ART = 80,   -- art, music, beauty — central to identity
        },
        npc_archetypes = { "artist", "merchant", "noble", "musician", "scholar", "courtier" },
        tags = { "beautiful", "deceptive", "artistic", "warm" },
    },

    ---------------------------------------------------------------------------
    -- THE OUTER RING
    ---------------------------------------------------------------------------
    {
        id = "contested",
        label = "The Contested March",   -- RENAME ME
        biome = "steppe",
        archetype = "contested",
        description = "Two powers fight over this land. The people just try to survive between them.",
        population = "sparse",
        culture_profile = {
            CUL_TRD = 40,
            CUL_OPN = 50,   -- take help from anyone
            CUL_FAI = 55,   -- pray harder when death is near
            CUL_MIL = 80,   -- everyone knows how to fight
            CUL_MRC = 30,   -- hard to trade in a warzone
            CUL_JUS = 25,   -- justice is whoever holds the sword
            CUL_IND = 60,   -- survival is personal
            CUL_ART = 15,   -- art is a luxury they can't afford
        },
        npc_archetypes = { "soldier", "refugee", "deserter", "medic", "scavenger", "orphan" },
        tags = { "dangerous", "war-torn", "chaotic", "desperate" },
    },
    {
        id = "freeport",
        label = "The Free Port",         -- RENAME ME
        biome = "coastal",
        archetype = "free_port",
        description = "No king. No law. No questions. You can buy anything here, including a new identity.",
        population = "dense",
        culture_profile = {
            CUL_TRD = 10,   -- tradition is for the mainland
            CUL_OPN = 90,   -- everyone and everything welcome
            CUL_FAI = 15,   -- gods don't come here
            CUL_MIL = 45,   -- private armies, pirates, mercs
            CUL_MRC = 90,   -- if it exists, it's for sale
            CUL_JUS = 10,   -- justice is a joke
            CUL_IND = 90,   -- radical individualism
            CUL_ART = 40,   -- rough art — tattoos, shanties, graffiti
        },
        npc_archetypes = { "pirate", "smuggler", "fence", "exile", "mercenary", "opium_dealer", "tattoo_artist" },
        tags = { "lawless", "free", "dangerous", "diverse" },
    },
    {
        id = "wildlands",
        label = "The Old Forest",        -- RENAME ME
        biome = "swamp",
        archetype = "wildlands",
        description = "Before the kingdoms. Before the roads. The land remembers what people forgot.",
        population = "minimal",
        culture_profile = {
            CUL_TRD = 90,   -- ancient ways
            CUL_OPN = 15,   -- outsiders don't last long
            CUL_FAI = 80,   -- old gods, old rituals
            CUL_MIL = 20,   -- no armies, but the land fights for itself
            CUL_MRC = 10,   -- barter, not coin
            CUL_JUS = 30,   -- nature's justice
            CUL_IND = 40,   -- tribe over self
            CUL_ART = 50,   -- cave paintings, bone carvings, oral tradition
        },
        npc_archetypes = { "hermit", "hunter", "shaman", "outlaw", "beast_tamer", "refugee" },
        tags = { "ancient", "dangerous", "spiritual", "untamed" },
    },

    ---------------------------------------------------------------------------
    -- THE EDGE
    ---------------------------------------------------------------------------
    {
        id = "distant",
        label = "The Distant Kingdom",   -- RENAME ME
        biome = "desert",
        archetype = "distant",
        description = "A different world. Different tongue. Different gods. Your claim means nothing here.",
        population = "moderate",
        culture_profile = {
            CUL_TRD = 50,
            CUL_OPN = 60,   -- curious about foreigners
            CUL_FAI = 70,   -- different faith entirely
            CUL_MIL = 55,
            CUL_MRC = 65,   -- trade with the known world
            CUL_JUS = 50,
            CUL_IND = 45,
            CUL_ART = 75,   -- calligraphy, poetry, architecture
        },
        npc_archetypes = { "scholar", "merchant", "mystic", "warrior_poet", "diplomat", "herbalist" },
        tags = { "foreign", "exotic", "safe", "distant" },
    },
    {
        id = "pastoraledge",
        label = "The Quiet Reaches",     -- RENAME ME
        biome = "temperate",
        archetype = "pastoral_edge",
        description = "The end of the world. Sheep. Rain. Old stone walls. News arrives months late.",
        population = "minimal",
        culture_profile = {
            CUL_TRD = 75,
            CUL_OPN = 40,   -- polite but cautious
            CUL_FAI = 55,
            CUL_MIL = 15,   -- what army?
            CUL_MRC = 25,   -- what market?
            CUL_JUS = 40,   -- the elder decides
            CUL_IND = 50,
            CUL_ART = 35,   -- folk songs, wood carving
        },
        npc_archetypes = { "farmer", "shepherd", "elder", "midwife", "wanderer", "deserter" },
        tags = { "peaceful", "isolated", "forgotten", "beautiful" },
    },
}

--------------------------------------------------------------------------------
-- CONNECTIONS
-- Each connection: { from, to, distance_days, route_biome, danger, description }
-- distance_days determines travel time and supply cost.
-- danger: "safe", "moderate", "dangerous", "deadly"
--------------------------------------------------------------------------------

WorldConfig.connections = {
    -- CORE internal
    { from = "capital",     to = "crownlands",   distance = 1, route_biome = "temperate", danger = "safe",
      description = "A day's ride through farmland. The capital's smoke is still visible behind you." },

    -- CORE → MIDDLE
    { from = "capital",     to = "tradecity",    distance = 3, route_biome = "coastal",   danger = "moderate",
      description = "The coastal road. Merchants, patrols, and the occasional bandit." },
    { from = "capital",     to = "holyseat",     distance = 3, route_biome = "mountain",  danger = "moderate",
      description = "Uphill. The air thins. The world gets quieter." },
    { from = "capital",     to = "rival_east",   distance = 2, route_biome = "temperate", danger = "moderate",
      description = "Across the border. The signs change language before the landscape does." },
    { from = "crownlands",  to = "rival_south",  distance = 3, route_biome = "tropical",  danger = "safe",
      description = "South through the fields, then jungle. The warmth hits you before the colors do." },
    { from = "crownlands",  to = "holyseat",     distance = 2, route_biome = "mountain",  danger = "safe",
      description = "The pilgrim's road. Well-maintained. Shrines every mile." },

    -- MIDDLE internal
    { from = "tradecity",   to = "rival_south",  distance = 2, route_biome = "coastal",   danger = "safe",
      description = "The merchant's route. Busy. Safe. Boring." },
    { from = "rival_east",  to = "contested",    distance = 2, route_biome = "steppe",    danger = "dangerous",
      description = "Into the disputed lands. The road has scars." },
    { from = "holyseat",    to = "wildlands",    distance = 3, route_biome = "mountain",  danger = "dangerous",
      description = "Down from the holy mountain into the old places. The priests warn you not to go." },

    -- MIDDLE → OUTER
    { from = "tradecity",   to = "freeport",     distance = 4, route_biome = "coastal",   danger = "moderate",
      description = "The law thins as you sail. By the time you dock, it's gone entirely." },
    { from = "rival_east",  to = "wildlands",    distance = 3, route_biome = "steppe",    danger = "dangerous",
      description = "Past the last garrison. Past the last road. Into the green." },
    { from = "contested",   to = "freeport",     distance = 3, route_biome = "steppe",    danger = "dangerous",
      description = "Through the warzone to the coast. Every mile is a negotiation." },

    -- OUTER internal
    { from = "freeport",    to = "wildlands",    distance = 3, route_biome = "swamp",     danger = "deadly",
      description = "Nobody takes this road by choice. The swamp takes what it wants." },

    -- OUTER → EDGE
    { from = "freeport",    to = "distant",      distance = 5, route_biome = "desert",    danger = "moderate",
      description = "Across the sea, then overland. Days of sand. The stars are different here." },
    { from = "wildlands",   to = "pastoraledge", distance = 4, route_biome = "temperate", danger = "moderate",
      description = "Through the forest and out the other side. The world opens up. Fields. Sky. Silence." },
    { from = "contested",   to = "pastoraledge", distance = 3, route_biome = "temperate", danger = "safe",
      description = "Away from the fighting. The further you walk, the less anyone cares about borders." },
    { from = "distant",     to = "pastoraledge", distance = 5, route_biome = "desert",    danger = "moderate",
      description = "A long road between worlds. You'll arrive a different person than when you left." },
}

--------------------------------------------------------------------------------
-- STARTING LOCATIONS
-- Based on claim type — different origins start in different places.
--------------------------------------------------------------------------------

WorldConfig.starting_regions = {
    bastard       = "crownlands",    -- raised in the shadow of the capital
    exiled_sibling = "rival_east",   -- cast out to a rival's territory
    disinherited  = "capital",       -- stripped of title but still in the city
    lost_child    = "pastoraledge",  -- raised at the edge of the world, far from truth
    pretender     = "tradecity",     -- built your story in a place where stories are currency
}

--------------------------------------------------------------------------------
-- HELPER: Get region config by id.
--------------------------------------------------------------------------------

function WorldConfig.get_region(id)
    for _, r in ipairs(WorldConfig.regions) do
        if r.id == id then return r end
    end
    return nil
end

--- Get all connections from a region.
function WorldConfig.get_connections_from(id)
    local conns = {}
    for _, c in ipairs(WorldConfig.connections) do
        if c.from == id then
            table.insert(conns, c)
        elseif c.to == id then
            -- Reverse direction
            table.insert(conns, {
                from = c.to, to = c.from,
                distance = c.distance, route_biome = c.route_biome,
                danger = c.danger, description = c.description,
            })
        end
    end
    return conns
end

--- Get the starting region for a claim type.
function WorldConfig.get_starting_region(claim_type)
    return WorldConfig.starting_regions[claim_type] or "crownlands"
end

return WorldConfig
