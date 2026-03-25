local Math = require("dredwork_core.math")
local rng = require("dredwork_core.rng")
local NameGenerator = require("dredwork_core.names")

local ShadowSetup = {}

local DEFAULT_ERA_KEY = "ancient"
local YOUNG_START_AGE = 16

local OPTION_ORDER = {
    "birthplace",
    "household",
    "education",
    "occupation",
    "faith",
    "vice",
    "burden",
}

local OPTIONS = {
    birthplace = {
        label = "BIRTHPLACE",
        prompt = "Where this life first learned the world's shape.",
        items = {
            { id = "holdfast", label = "HOLDFAST", description = "Stone walls, strict duty, and long memory.", trait_deltas = { PHY_VIT = 4, MEN_WIL = 4, SOC_LEA = 2 }, personality_deltas = { PER_LOY = 8, PER_ADA = -4 } },
            { id = "market", label = "MARKET WARD", description = "Trade, rumor, improvisation, and sharp tongues.", trait_deltas = { SOC_NEG = 6, SOC_ELO = 5, MEN_PAT = 2 }, personality_deltas = { PER_CUR = 6, PER_ADA = 6 } },
            { id = "abbey", label = "ABBEY CLOSE", description = "Silence, scripture, and disciplined observation.", trait_deltas = { MEN_INT = 6, CRE_RIT = 5, MEN_PAT = 4 }, personality_deltas = { PER_OBS = 6, PER_VOL = -4 } },
            { id = "frontier", label = "FRONTIER HAMLET", description = "Cold distances, scarcity, and practical endurance.", trait_deltas = { PHY_STR = 5, PHY_VIT = 5, MEN_WIL = 2 }, personality_deltas = { PER_BLD = 4, PER_ADA = 4 } },
            { id = "ruin", label = "RUIN DISTRICT", description = "Fallen estates, scavenged luxuries, and unsafe brilliance.", trait_deltas = { CRE_VIS = 5, MEN_PAT = 5, SOC_NEG = 2 }, personality_deltas = { PER_CUR = 8, PER_PRI = 4 } },
        },
    },
    household = {
        label = "HOUSEHOLD",
        prompt = "The room the child had to survive in.",
        items = {
            { id = "devout", label = "DEVOUT HOUSE", description = "Prayer, scrutiny, and rules that learned your name early.", trait_deltas = { CRE_RIT = 5, MEN_PAT = 3 }, personality_deltas = { PER_LOY = 5, PER_VOL = -2 } },
            { id = "debtor", label = "DEBTOR HOUSE", description = "Every kindness counted. Every meal remembered.", trait_deltas = { SOC_NEG = 3, MEN_WIL = 2 }, personality_deltas = { PER_ADA = 6, PER_PRI = -2 } },
            { id = "martial", label = "MARTIAL HOUSE", description = "Discipline, bruise-logic, and obedience spoken loudly.", trait_deltas = { PHY_STR = 4, MEN_WIL = 3, SOC_LEA = 2 }, personality_deltas = { PER_BLD = 4, PER_LOY = 2 } },
            { id = "scholarly", label = "SCHOLAR HOUSE", description = "Ledgers, lessons, and cold affection hidden in correction.", trait_deltas = { MEN_INT = 5, MEN_PAT = 3, CRE_NAR = 2 }, personality_deltas = { PER_OBS = 5, PER_CUR = 3 } },
            { id = "fractured", label = "FRACTURED HOUSE", description = "Doors slamming, loyalties splitting, and secrets moving room to room.", trait_deltas = { SOC_NEG = 2, MEN_WIL = 2 }, personality_deltas = { PER_VOL = 6, PER_ADA = 3 } },
            { id = "wandering", label = "WANDERING HOUSE", description = "No stable hearth. New roads before old grief cooled.", trait_deltas = { PHY_VIT = 3, SOC_ELO = 2, MEN_PAT = -2 }, personality_deltas = { PER_ADA = 7, PER_CUR = 3 } },
        },
    },
    education = {
        label = "EDUCATION",
        prompt = "How the mind was sharpened, neglected, or bent.",
        items = {
            { id = "field", label = "FIELD-TAUGHT", description = "Labor, survival, and practical instruction.", trait_deltas = { PHY_STR = 3, MEN_WIL = 4, CRE_TIN = 3 }, personality_deltas = { PER_ADA = 4 } },
            { id = "guild", label = "GUILD-TRAINED", description = "Apprenticeship, craft discipline, and measured ambition.", trait_deltas = { CRE_TIN = 6, MEN_PAT = 4, SOC_NEG = 2 }, personality_deltas = { PER_OBS = 4, PER_PRI = 2 } },
            { id = "temple", label = "TEMPLE-SCHOOLED", description = "Memory work, ritual literacy, and internal restraint.", trait_deltas = { MEN_INT = 5, CRE_RIT = 6, MEN_WIL = 2 }, personality_deltas = { PER_LOY = 4, PER_VOL = -3 } },
            { id = "court", label = "COURT-TUTORED", description = "Etiquette, reading, and the quiet violence of manners.", trait_deltas = { SOC_ELO = 6, SOC_NEG = 4, MEN_INT = 3 }, personality_deltas = { PER_PRI = 5, PER_CRM = 3 } },
            { id = "self", label = "SELF-MADE", description = "Fragments stolen from ledgers, gossip, and failure.", trait_deltas = { MEN_PAT = 5, CRE_NAR = 5, MEN_INT = 2 }, personality_deltas = { PER_CUR = 5, PER_ADA = 4 } },
        },
    },
    occupation = {
        label = "CALLING",
        prompt = "What kind of life already seems to be pulling on them.",
        items = {
            { id = "laborer", label = "LABOR-CALLED", description = "The body leans toward useful work, endurance, and tangible burdens.", trait_deltas = { PHY_STR = 4, PHY_BLD = 3, MEN_WIL = 2 }, personality_deltas = { PER_LOY = 2, PER_CUR = -2 } },
            { id = "scribe", label = "LEDGER-CALLED", description = "Words, codes, memory, and patterns already hold their eye.", trait_deltas = { MEN_INT = 6, MEN_PAT = 4, CRE_NAR = 4 }, personality_deltas = { PER_OBS = 5, PER_VOL = -2 } },
            { id = "soldier", label = "WAR-CALLED", description = "Conflict, command, and bodily courage wait under the skin.", trait_deltas = { PHY_STR = 4, PHY_VIT = 4, SOC_LEA = 3 }, personality_deltas = { PER_BLD = 5, PER_CRM = 2 } },
            { id = "courtier", label = "COURT-CALLED", description = "Masks, leverage, and the weather inside a room matter too much.", trait_deltas = { SOC_ELO = 6, SOC_NEG = 5, CRE_VIS = 2 }, personality_deltas = { PER_PRI = 5, PER_CRM = 2 } },
            { id = "tinker", label = "MAKER-CALLED", description = "Hands itch for salvage, pattern, and dangerous invention.", trait_deltas = { CRE_TIN = 7, MEN_PAT = 4, MEN_INT = 3 }, personality_deltas = { PER_CUR = 6, PER_ADA = 4 } },
            { id = "performer", label = "STAGE-CALLED", description = "Voice, presence, and reinvention feel too natural too early.", trait_deltas = { CRE_NAR = 6, CRE_VIS = 5, SOC_ELO = 4 }, personality_deltas = { PER_BLD = 3, PER_VOL = 4 } },
        },
    },
    vice = {
        label = "PRIVATE HUNGER",
        prompt = "What weakness already has its first hand on the throat.",
        items = {
            { id = "none", label = "NONE YET", description = "A rare season of restraint.", trait_deltas = { MEN_WIL = 3 }, personality_deltas = { PER_VOL = -2 } },
            { id = "drink", label = "DRINK", description = "Warmth, courage, and the slow wreck of discipline.", trait_deltas = { SOC_ELO = 2, PHY_VIT = -4 }, personality_deltas = { PER_VOL = 6, PER_BLD = 2 } },
            { id = "gaming", label = "GAMBLING", description = "Chance feels cleaner than duty.", trait_deltas = { SOC_NEG = 3, MEN_PAT = -3 }, personality_deltas = { PER_BLD = 5, PER_OBS = 2 } },
            { id = "fervor", label = "FERVOR", description = "Too much faith, too quickly weaponized.", trait_deltas = { CRE_RIT = 3, MEN_WIL = 2 }, personality_deltas = { PER_LOY = 4, PER_CRM = 3 } },
            { id = "obsession", label = "OBSESSION", description = "One thought digs deeper than sleep.", trait_deltas = { MEN_PAT = 4, MEN_INT = 2, PHY_VIT = -2 }, personality_deltas = { PER_OBS = 8, PER_VOL = 2 } },
            { id = "debt", label = "BORROWED BREATH", description = "Every decision already belongs partly to someone else.", trait_deltas = { SOC_NEG = 2, MEN_WIL = -3 }, personality_deltas = { PER_ADA = 3, PER_PRI = -2 } },
        },
    },
    faith = {
        label = "FAITH",
        prompt = "The unseen order they trust, resist, or counterfeit.",
        items = {
            { id = "state", label = "STATE CREED", description = "Public piety and sanctioned language.", trait_deltas = { CRE_RIT = 4, SOC_LEA = 2 }, personality_deltas = { PER_LOY = 5, PER_ADA = -2 } },
            { id = "old", label = "OLD RITES", description = "Whispers, taboos, and older debts than kings.", trait_deltas = { CRE_RIT = 6, MEN_PAT = 2 }, personality_deltas = { PER_OBS = 4, PER_CUR = 2 } },
            { id = "skeptic", label = "SKEPTIC", description = "Doubt as armor. Doubt as hunger.", trait_deltas = { MEN_INT = 4, MEN_PAT = 2 }, personality_deltas = { PER_CUR = 5, PER_LOY = -4 } },
            { id = "cult", label = "CULT INITIATE", description = "Private devotion with public consequences.", trait_deltas = { CRE_RIT = 5, SOC_NEG = 3 }, personality_deltas = { PER_OBS = 5, PER_BLD = 2 } },
            { id = "ancestor", label = "ANCESTOR HUSH", description = "The dead are close and never generous.", trait_deltas = { CRE_NAR = 4, MEN_WIL = 3 }, personality_deltas = { PER_LOY = 3, PER_OBS = 3 } },
        },
    },
    burden = {
        label = "BURDEN",
        prompt = "What follows the child into the first playable years.",
        items = {
            { id = "debt", label = "FAMILY DEBT", description = "Creditors already know the name.", trait_deltas = { SOC_NEG = 3, MEN_WIL = 2 }, personality_deltas = { PER_ADA = 4, PER_PRI = -2 }, creed = "Pay what should never have been owed." },
            { id = "oath", label = "BLOOD OATH", description = "A promise made before understanding its cost.", trait_deltas = { MEN_WIL = 4, SOC_LEA = 2 }, personality_deltas = { PER_LOY = 7, PER_ADA = -3 }, creed = "Keep the oath even when it rots." },
            { id = "scar", label = "OLD SCAR", description = "The body remembers a violence the mind still edits.", trait_deltas = { PHY_VIT = -4, MEN_WIL = 4, PHY_STR = 2 }, personality_deltas = { PER_BLD = 3, PER_VOL = 3 }, creed = "What cut once can cut again." },
            { id = "claim", label = "DENIED CLAIM", description = "A right nobody wants acknowledged until it matters.", trait_deltas = { SOC_ELO = 3, MEN_PAT = 2 }, personality_deltas = { PER_PRI = 6, PER_BLD = 2 }, creed = "Take the place they denied you." },
            { id = "wanted", label = "WANTED NAME", description = "The wrong people still remember the face.", trait_deltas = { SOC_NEG = 4, MEN_PAT = 2 }, personality_deltas = { PER_ADA = 5, PER_VOL = 2 }, creed = "Stay moving. Stay alive." },
            { id = "parent", label = "SICK PARENT", description = "Duty begins at home and never ends there.", trait_deltas = { MEN_WIL = 3, SOC_LEA = 2 }, personality_deltas = { PER_LOY = 5, PER_CRM = -2 }, creed = "Carry one more weight and keep walking." },
        },
    },
}

local CORE_BOND_SLOTS = {
    { id = "hearth", label = "HEARTH TIE", role = "HEARTH KIN", category = "kin", description = "The person home put nearest to the throat." },
    { id = "friend", label = "CLOSE TIE", role = "CHILDHOOD FRIEND", category = "intimate", description = "The one who knew the child before the mask hardened." },
    { id = "rival", label = "RIVAL TIE", role = "RIVAL", category = "rival", description = "The person already measuring themselves against you." },
    { id = "elder", label = "ELDER TIE", role = "ELDER KEEPER", category = "power", description = "The older hand that can guide, bind, or claim a price." },
    { id = "dependent", label = "YOUNGER TIE", role = "YOUNGER SHADOW", category = "dependent", description = "Someone smaller, needier, or more exposed than you." },
}

local CORE_TONES = {
    { id = "steadfast", label = "STEADFAST", description = "Reliable, disciplined, and difficult to move.", bond_deltas = { closeness = 10, obligation = 8, volatility = -8 }, personality_deltas = { PER_LOY = 2 } },
    { id = "hungry", label = "HUNGRY", description = "Ambitious, restless, and always noticing advantage.", bond_deltas = { leverage = 10, visibility = 8, strain = 4 }, personality_deltas = { PER_PRI = 2, PER_CUR = 1 } },
    { id = "gentle", label = "GENTLE", description = "Tender, patient, and slow to weaponize pain.", bond_deltas = { closeness = 8, intimacy = 10, strain = -6 }, personality_deltas = { PER_CRM = -2 } },
    { id = "volatile", label = "VOLATILE", description = "Mercurial, warm one hour and ruinous the next.", bond_deltas = { volatility = 12, strain = 8, intimacy = 4 }, personality_deltas = { PER_VOL = 3 } },
    { id = "devout", label = "DEVOUT", description = "Ruled by creed, omen, or inherited taboo.", bond_deltas = { obligation = 8, visibility = 4, closeness = 4 }, personality_deltas = { PER_LOY = 2, PER_OBS = 1 } },
    { id = "calculating", label = "CALCULATING", description = "Never fully absent, never fully innocent.", bond_deltas = { leverage = 12, closeness = -2, strain = 4 }, personality_deltas = { PER_CRM = 2, PER_OBS = 1 } },
    { id = "curious", label = "CURIOUS", description = "Drawn toward the forbidden, the hidden, and the costly.", bond_deltas = { intimacy = 6, volatility = 6, visibility = 6 }, personality_deltas = { PER_CUR = 3 } },
    { id = "bitter", label = "BITTER", description = "Already carrying a grievance like a private saint.", bond_deltas = { strain = 12, closeness = -4, leverage = 4 }, personality_deltas = { PER_VOL = 1, PER_PRI = 2 } },
}

local BASE_TRAITS = {
    PHY_STR = 52,
    PHY_VIT = 51,
    PHY_BLD = 50,
    MEN_INT = 53,
    MEN_PAT = 50,
    MEN_WIL = 52,
    SOC_NEG = 49,
    SOC_ELO = 48,
    SOC_LEA = 47,
    CRE_VIS = 50,
    CRE_NAR = 49,
    CRE_RIT = 48,
    CRE_TIN = 47,
}

local BASE_PERSONALITY = {
    PER_BLD = 50,
    PER_CRM = 50,
    PER_OBS = 50,
    PER_LOY = 50,
    PER_CUR = 50,
    PER_VOL = 50,
    PER_PRI = 50,
    PER_ADA = 50,
}


local function hash_text(seed, text)
    local hash = math.abs(seed or 1) % 2147483647
    local value = tostring(text or "")
    for index = 1, #value do
        hash = (hash * 1103515245 + value:byte(index) + 12345) % 2147483647
    end
    return hash
end

local function unit_noise(seed, label)
    return (hash_text(seed, label) % 100000) / 100000
end

local function signed_noise(seed, label)
    return unit_noise(seed, label) * 2 - 1
end

local function bell_noise(seed, label)
    return (
        signed_noise(seed, label .. ":a")
        + signed_noise(seed, label .. ":b")
        + signed_noise(seed, label .. ":c")
    ) / 3
end

local function merge_deltas(target, deltas)
    for key, value in pairs(deltas or {}) do
        target[key] = (target[key] or 0) + value
    end
end

local function current_choice(state, key)
    local def = OPTIONS[key]
    local index = (state.selections and state.selections[key]) or 1
    return def, def.items[index], index
end

local function reseed(seed)
    rng.seed(seed or os.time())
end

local function core_tone(index)
    return CORE_TONES[index] or CORE_TONES[1]
end

local function core_slot(index)
    return CORE_BOND_SLOTS[index] or CORE_BOND_SLOTS[1]
end

local function reroll_core_bond_name(state, index)
    local bond = state.core_bonds and state.core_bonds[index]
    if not bond then
        return nil
    end
    bond.name_seed = (bond.name_seed or state.name_seed or state.seed or os.time()) + 41 + index * 7
    reseed(bond.name_seed)
    bond.name = NameGenerator.character(DEFAULT_ERA_KEY, 1)
    return bond
end

local function initialize_core_bonds(state)
    state.core_bonds = state.core_bonds or {}
    for index, slot in ipairs(CORE_BOND_SLOTS) do
        local bond = state.core_bonds[index] or {
            slot_id = slot.id,
            name_seed = (state.seed or os.time()) + index * 53,
            tone_index = ((index - 1) % #CORE_TONES) + 1,
        }
        bond.slot_id = slot.id
        bond.label = slot.label
        bond.role = slot.role
        bond.category = slot.category
        bond.slot_description = slot.description
        if not bond.name or bond.name == "" then
            state.core_bonds[index] = bond
            reroll_core_bond_name(state, index)
        else
            state.core_bonds[index] = bond
        end
    end
end

function ShadowSetup.new(seed)
    local base_seed = seed or os.time()
    local state = {
        seed = base_seed,
        roll_seed = base_seed + 211,
        name_seed = base_seed + 17,
        selections = {},
        heir_name = nil,
        lineage_name = nil,
        claim_house_name = nil,
        core_bonds = {},
    }
    for _, key in ipairs(OPTION_ORDER) do
        state.selections[key] = 1
    end
    initialize_core_bonds(state)
    ShadowSetup.reroll_identity(state)
    return state
end

function ShadowSetup.get_option_order()
    return OPTION_ORDER
end

function ShadowSetup.get_definition(key)
    return OPTIONS[key]
end

function ShadowSetup.get_choice(state, key)
    local _, choice = current_choice(state, key)
    return choice
end

function ShadowSetup.cycle(state, key, direction)
    local def, _, index = current_choice(state, key)
    local total = #(def.items or {})
    local step = direction or 1
    local next_index = ((index - 1 + step) % total) + 1
    state.selections[key] = next_index
    return def.items[next_index]
end

function ShadowSetup.cycle_core_bond_tone(state, index, direction)
    initialize_core_bonds(state)
    local bond = state.core_bonds[index]
    if not bond then
        return nil
    end
    local total = #CORE_TONES
    local current = bond.tone_index or 1
    local step = direction or 1
    bond.tone_index = ((current - 1 + step) % total) + 1
    return core_tone(bond.tone_index)
end

function ShadowSetup.reroll_core_bond_name(state, index)
    initialize_core_bonds(state)
    return reroll_core_bond_name(state, index)
end

function ShadowSetup.reroll_identity(state)
    state.name_seed = (state.name_seed or state.seed or os.time()) + 37
    reseed(state.name_seed)
    state.heir_name = NameGenerator.character(DEFAULT_ERA_KEY, 1)
    state.lineage_name = NameGenerator.lineage()
    state.claim_house_name = "House " .. NameGenerator.lineage()
    initialize_core_bonds(state)
    for index = 1, #state.core_bonds do
        ShadowSetup.reroll_core_bond_name(state, index)
    end
    return state
end

function ShadowSetup.randomize(state)
    state.seed = (state.seed or os.time()) + 101
    state.roll_seed = (state.roll_seed or state.seed or os.time()) + 73
    reseed(state.seed)
    for _, key in ipairs(OPTION_ORDER) do
        local def = OPTIONS[key]
        state.selections[key] = rng.range(1, #(def.items or {}))
    end
    initialize_core_bonds(state)
    for index = 1, #state.core_bonds do
        state.core_bonds[index].tone_index = rng.range(1, #CORE_TONES)
        ShadowSetup.reroll_core_bond_name(state, index)
    end
    ShadowSetup.reroll_identity(state)
    return state
end

function ShadowSetup.build_profile(state)
    initialize_core_bonds(state)

    local trait_bias = {}
    local personality_bias = {}
    local notes = {}
    local summary = {}
    local people = {}

    for _, key in ipairs(OPTION_ORDER) do
        local choice = ShadowSetup.get_choice(state, key)
        merge_deltas(trait_bias, choice and choice.trait_deltas or nil)
        merge_deltas(personality_bias, choice and choice.personality_deltas or nil)
    end

    local birthplace = ShadowSetup.get_choice(state, "birthplace")
    local household = ShadowSetup.get_choice(state, "household")
    local education = ShadowSetup.get_choice(state, "education")
    local calling = ShadowSetup.get_choice(state, "occupation")
    local vice = ShadowSetup.get_choice(state, "vice")
    local faith = ShadowSetup.get_choice(state, "faith")
    local burden = ShadowSetup.get_choice(state, "burden")

    notes[#notes + 1] = household.description
    notes[#notes + 1] = burden.description
    notes[#notes + 1] = "They raised the child on the grievance that " .. (state.claim_house_name or "an older house") .. " kept the seat and cast this branch into shadow."
    notes[#notes + 1] = "No career has hardened around the child yet. The first years will decide which callings survive contact with the world."

    for index, bond in ipairs(state.core_bonds or {}) do
        local tone = core_tone(bond.tone_index)
        merge_deltas(personality_bias, tone and tone.personality_deltas or nil)
        people[#people + 1] = {
            index = index,
            slot_id = bond.slot_id,
            label = bond.label,
            role = bond.role,
            category = bond.category,
            name = bond.name,
            temperament = tone.label,
            temperament_id = tone.id,
            description = tone.description,
            slot_description = bond.slot_description,
        }
    end

    local traits = {}
    for key, base in pairs(BASE_TRAITS) do
        local bias = trait_bias[key] or 0
        local spread = 8 + math.min(6, math.abs(bias) * 0.35)
        local drift = bell_noise(state.roll_seed, "trait:" .. key) * spread
        local undertow = bell_noise(state.roll_seed, "trait_bias:" .. key) * math.max(2, math.abs(bias) * 0.45)
        traits[key] = Math.clamp(math.floor(base + bias * 0.78 + drift + undertow + 0.5), 18, 92)
    end

    local personality = {}
    for key, base in pairs(BASE_PERSONALITY) do
        local bias = personality_bias[key] or 0
        local spread = 7 + math.min(5, math.abs(bias) * 0.30)
        local drift = bell_noise(state.roll_seed, "personality:" .. key) * spread
        local undertow = bell_noise(state.roll_seed, "personality_bias:" .. key) * math.max(2, math.abs(bias) * 0.40)
        personality[key] = Math.clamp(math.floor(base + bias * 0.74 + drift + undertow + 0.5), 15, 85)
    end

    summary[#summary + 1] = "Age " .. tostring(YOUNG_START_AGE) .. " | " .. birthplace.label .. " | " .. household.label
    summary[#summary + 1] = calling.label .. " | " .. education.label
    summary[#summary + 1] = vice.label .. " | " .. faith.label
    summary[#summary + 1] = "Shadow of " .. (state.claim_house_name or "an unnamed house")
    summary[#summary + 1] = "The child enters under " .. burden.label .. "."

    return {
        heir_name = state.heir_name or "Unnamed",
        lineage_name = state.lineage_name or "Unknown",
        house_title = "Record of " .. (state.lineage_name or "Unknown"),
        claim_house_title = state.claim_house_name or "House Unknown",
        age = YOUNG_START_AGE,
        birthplace = birthplace,
        household = household,
        education = education,
        occupation = calling,
        vice = vice,
        faith = faith,
        burden = burden,
        traits = traits,
        personality = personality,
        trait_bias = trait_bias,
        personality_bias = personality_bias,
        creed = burden.creed or "Keep walking.",
        summary_lines = summary,
        notes = notes,
        core_bonds = people,
    }
end

function ShadowSetup.build_rows(state)
    initialize_core_bonds(state)
    local rows = {}
    for _, key in ipairs(OPTION_ORDER) do
        local def, choice = current_choice(state, key)
        rows[#rows + 1] = {
            key = key,
            label = def.label,
            value = choice.label,
            description = choice.description,
            prompt = def.prompt,
        }
    end
    for index, bond in ipairs(state.core_bonds or {}) do
        local tone = core_tone(bond.tone_index)
        rows[#rows + 1] = {
            key = "bond_name:" .. tostring(index),
            label = bond.label .. " NAME",
            value = bond.name,
            description = bond.slot_description,
            prompt = "CLICK TO REROLL NAME",
            action = "setup_bond_name:" .. tostring(index),
        }
        rows[#rows + 1] = {
            key = "bond_tone:" .. tostring(index),
            label = bond.label .. " NATURE",
            value = bond.role .. " | " .. tone.label,
            description = tone.description,
            prompt = "CLICK TO CYCLE TEMPERAMENT",
            action = "setup_bond_tone:" .. tostring(index),
        }
    end
    return rows
end

function ShadowSetup.build_run_options(state)
    local profile = ShadowSetup.build_profile(state)
    local setup_bonds = {}
    for _, bond in ipairs(profile.core_bonds or {}) do
        setup_bonds[#setup_bonds + 1] = {
            slot_id = bond.slot_id,
            label = bond.label,
            name = bond.name,
            role = bond.role,
            category = bond.category,
            temperament = bond.temperament,
            temperament_id = bond.temperament_id,
            description = bond.description,
        }
    end

    return {
        era_key = DEFAULT_ERA_KEY,
        lineage_name = profile.lineage_name,
        heir_name = profile.heir_name,
        motto = profile.creed,
        traits = profile.traits,
        personality = profile.personality,
        shadow_setup = {
            start_age = profile.age,
            start_age_id = "y16",
            birthplace = profile.birthplace.id,
            birthplace_label = profile.birthplace.label,
            household = profile.household.id,
            household_label = profile.household.label,
            education = profile.education.id,
            education_label = profile.education.label,
            occupation = profile.occupation.id,
            occupation_label = profile.occupation.label,
            calling_label = profile.occupation.label,
            vice = profile.vice.id,
            vice_label = profile.vice.label,
            faith = profile.faith.id,
            faith_label = profile.faith.label,
            burden = profile.burden.id,
            burden_label = profile.burden.label,
            creed = profile.creed,
            claim_house_name = profile.claim_house_title,
            core_bonds = setup_bonds,
        },
    }
end

return ShadowSetup
