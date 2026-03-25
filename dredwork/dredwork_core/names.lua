-- dredwork Core — Name Generator
-- Names that sound like people, not random syllable soup.
-- Organized by cultural feel so different regions produce different names.
-- No "ash", "grim", "shaw", "vane". Real sounds. Human sounds.

local Names = {}

local RNG = require("dredwork_core.rng")

--------------------------------------------------------------------------------
-- NAME POOLS
-- Each pool is a cultural cluster. Mix and match for variety.
-- First names and surnames are separate — combine for full names.
--------------------------------------------------------------------------------

local FIRST_NAMES = {
    -- Northern / martial feel
    northern = {
        "Renn", "Cade", "Jorik", "Bram", "Torven", "Kael", "Soren", "Aldric",
        "Leith", "Daven", "Corvin", "Maren", "Ilsa", "Brynn", "Eira", "Katla",
        "Sigrid", "Petra", "Anya", "Dagny", "Halvar", "Osric", "Ulf", "Nils",
    },
    -- Southern / warm / artistic feel
    southern = {
        "Luca", "Sera", "Amara", "Dion", "Calla", "Nico", "Paz", "Estela",
        "Ivo", "Lira", "Miro", "Sola", "Thea", "Zara", "Roque", "Dalia",
        "Fenn", "Jael", "Tomas", "Cassia", "Idris", "Oriel", "Belen", "Varo",
    },
    -- Holy / scholarly feel
    scholarly = {
        "Caedmon", "Elara", "Sybil", "Clement", "Ansel", "Maud", "Benedict",
        "Isolde", "Rowan", "Phelan", "Agnes", "Barnard", "Colm", "Edith",
        "Aldous", "Hilde", "Lucan", "Nesta", "Prior", "Quill",
    },
    -- Criminal / port / rough feel
    rough = {
        "Cog", "Dirk", "Moll", "Pike", "Nix", "Rue", "Slab", "Wren",
        "Kit", "Brine", "Cork", "Fen", "Grit", "Hemp", "Joss", "Lug",
        "Patch", "Tack", "Voss", "Wedge", "Brick", "Dross", "Flint", "Hock",
    },
    -- Rural / pastoral feel
    pastoral = {
        "Hale", "Nell", "Jem", "Pru", "Walt", "Meg", "Tam", "Bess",
        "Gale", "Hodge", "Ivy", "Lane", "Mill", "Oat", "Pip", "Robin",
        "Seth", "Tilly", "Willow", "Clay", "Dale", "Fern", "Glen", "Heath",
    },
    -- Foreign / distant kingdom feel
    foreign = {
        "Navid", "Farah", "Zahir", "Leyla", "Karim", "Yara", "Omid", "Safiya",
        "Reza", "Dina", "Hasan", "Mina", "Tariq", "Zain", "Basma", "Khalil",
        "Jalil", "Noura", "Sami", "Rasha",
    },
}

local SURNAMES = {
    -- Occupational
    occupational = {
        "Cooper", "Thatcher", "Miller", "Fletcher", "Tanner", "Mason",
        "Carter", "Wheeler", "Porter", "Weaver", "Chandler", "Barker",
    },
    -- Place-based (subtle, not fantasy)
    place = {
        "of the Hill", "from the Ford", "of Low Bridge", "by the Well",
        "of the Ridge", "from Salt Lane", "of North Gate", "by the Mill",
    },
    -- Patronymic
    patronymic = {
        "son of Ren", "daughter of Kael", "of Maren's line",
        "born of Petra", "child of Soren",
    },
    -- Descriptive (earned, not inherited)
    descriptive = {
        "the Quiet", "the Tall", "One-Eye", "Red Hand", "Half-smile",
        "the Lame", "Iron Jaw", "Soft Voice", "Cold Hands", "Long Memory",
        "the Patient", "No-Shadow", "Twice-Born", "the Listener",
    },
}

local TITLES_BY_ROLE = {
    advisor  = { "Counselor", "Voice", "Keeper of Accounts" },
    general  = { "Captain", "Commander", "Marshal", "War-Leader" },
    priest   = { "Father", "Mother", "Brother", "Sister", "Prior" },
    elder    = { "Elder", "Grandmother", "Old" },
    spouse   = {},  -- no title, just name
    sibling  = {},
    steward  = { "Steward", "Keeper" },
    judge    = { "Magistrate", "Justice" },
}

--------------------------------------------------------------------------------
-- GENERATION
--------------------------------------------------------------------------------

--- Generate a character name.
---@param culture string|nil "northern", "southern", "scholarly", "rough", "pastoral", "foreign"
---@param opts table|nil { with_surname, with_title, role }
function Names.character(culture, opts)
    opts = opts or {}
    culture = culture or "northern"

    local pool = FIRST_NAMES[culture] or FIRST_NAMES.northern
    local first = RNG.pick(pool)

    -- Optional surname (50% chance unless requested)
    if opts.with_surname or (opts.with_surname == nil and RNG.chance(0.4)) then
        local surname_type = RNG.pick({"occupational", "descriptive", "place"})
        local surname_pool = SURNAMES[surname_type] or SURNAMES.occupational
        first = first .. " " .. RNG.pick(surname_pool)
    end

    -- Optional title prefix based on role
    if opts.role and TITLES_BY_ROLE[opts.role] and #TITLES_BY_ROLE[opts.role] > 0 then
        local title = RNG.pick(TITLES_BY_ROLE[opts.role])
        first = title .. " " .. first
    end

    return first
end

--- Generate a house name.
function Names.house()
    local prefixes = {
        "House", "The", "Clan",
    }
    local words = {
        "Vael", "Thorn", "Crest", "Morrow", "Holt", "Drace",
        "Tern", "Calden", "Brack", "Selwyn", "Roth", "Kyne",
        "Meriden", "Alcott", "Renworth", "Calloway", "Dunmore",
        "Halcott", "Severn", "Wyndham", "Corran", "Montrose",
    }
    return RNG.pick(prefixes) .. " " .. RNG.pick(words)
end

--- Generate a name for a lineage.
function Names.lineage()
    return Names.house()
end

--- Get the culture key for a region archetype.
function Names.culture_for_archetype(archetype)
    local map = {
        capital = "northern",
        pastoral = "pastoral",
        trade = "southern",
        holy = "scholarly",
        rival_house = "northern",
        contested = "northern",
        free_port = "rough",
        wildlands = "pastoral",
        distant = "foreign",
        pastoral_edge = "pastoral",
    }
    return map[archetype] or "northern"
end

--- Generate a random NPC name appropriate for a region.
function Names.for_region(region_def, opts)
    local culture = Names.culture_for_archetype(region_def.archetype or "capital")
    return Names.character(culture, opts)
end

return Names
