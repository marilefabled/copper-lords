-- Dark Legacy — Worldbuilder Mode Data
-- Definitions for expanded archetypes, estate types, and customization rules.

local WorldbuilderData = {}

-- =========================================================================
-- Rival House Archetypes (Expanded for Worldbuilder Mode)
-- =========================================================================
WorldbuilderData.faction_archetypes = {
    {
        id = "warlords",
        label = "Warlords",
        description = "Focused on physical power and conquest. Brute strength is their law.",
        category_scores = { physical = 75, mental = 40, social = 45, creative = 30 },
        personality = { PER_BLD = 80, PER_CRM = 70, PER_PRI = 65, PER_ADA = 30 },
        reputation = { primary = "warriors", secondary = "tyrants" },
        mottos = {
            "The debt is paid in iron.",
            "Strength is the only currency.",
            "We do not kneel. We foreclose.",
            "Blood before negotiation.",
            "The strong inherit. The rest default.",
            "No mercy. No extensions.",
            "We were forged, not financed.",
            "Let the weak be written off.",
            "Our blades collect first.",
            "Victory or the grave. Both settle accounts.",
        },
    },
    {
        id = "scholars",
        label = "Archivists",
        description = "Obsessed with lore and history. They fight with knowledge and secrets.",
        category_scores = { physical = 35, mental = 80, social = 50, creative = 50 },
        personality = { PER_CUR = 85, PER_OBS = 75, PER_PRI = 70, PER_BLD = 30 },
        reputation = { primary = "scholars", secondary = "seekers" },
        mottos = {
            "We keep the receipts.",
            "We remember what others overdraw.",
            "The truth outlasts the balance sheet.",
            "Every secret has a maturity date.",
            "We read the bones of old accounts.",
            "Ignorance is the only insolvency.",
            "The archive endures all audits.",
            "What is known cannot be expunged.",
            "We hoard what compounds.",
            "The pen carves deeper than the blade.",
        },
    },
    {
        id = "merchant_princes",
        label = "Merchants",
        description = "Masters of gold and diplomacy. Everything — and everyone — has a price.",
        category_scores = { physical = 40, mental = 55, social = 80, creative = 40 },
        personality = { PER_ADA = 80, PER_CRM = 70, PER_BLD = 75, PER_LOY = 25 },
        reputation = { primary = "diplomats", secondary = "traders" },
        mottos = {
            "The contract is the blade.",
            "Gold opens every gate. We hold the keys.",
            "We buy what we cannot take. Cheaper.",
            "Loyalty has a market rate. We set it.",
            "The ledger never lies.",
            "Profit is its own bloodline.",
            "We trade in futures. Yours, specifically.",
            "All debts are collected. Ask anyone.",
            "Coin is thicker than blood.",
            "The deal is the dynasty.",
        },
    },
    {
        id = "decadent_poets",
        label = "Poets",
        description = "A house of artisans and aesthetes. They view the world as a canvas.",
        category_scores = { physical = 30, mental = 50, social = 55, creative = 85 },
        personality = { PER_VOL = 75, PER_ADA = 65, PER_CUR = 70, PER_PRI = 60 },
        reputation = { primary = "artisans", secondary = "hedonists" },
        mottos = {
            "Even ash has a price.",
            "We make the unbearable beautiful.",
            "Art outlasts every account.",
            "The song remembers what the ledger omits.",
            "Beauty is the only rebellion worth financing.",
            "We paint in blood and tallow-light.",
            "Creation is the last honest debt.",
            "Let the tasteless default.",
            "Every age deserves its monument. We build the invoice.",
            "We suffer with style. It costs more.",
        },
    },
    {
        id = "zealots",
        label = "Zealots",
        description = "Driven by an unshakeable faith. They are as dangerous as they are devoted.",
        category_scores = { physical = 60, mental = 60, social = 40, creative = 50 },
        personality = { PER_OBS = 90, PER_LOY = 85, PER_PRI = 70, PER_VOL = 60 },
        reputation = { primary = "warriors", secondary = "faithful" },
        mottos = {
            "The tithe is absolute.",
            "Our god demands the principal and the interest.",
            "Doubt is the only default.",
            "We burn so others may see the balance.",
            "Conviction is non-negotiable.",
            "The rite is the only legal tender.",
            "We serve what you cannot audit.",
            "Purity compounds.",
            "The fire cleanses all accounts.",
            "One truth. One tithe. One end.",
        },
    },
    {
        id = "shadow_court",
        label = "Shadows",
        description = "Spies and assassins. They govern through fear and the unseen blade.",
        category_scores = { physical = 50, mental = 65, social = 40, creative = 45 },
        personality = { PER_CRM = 80, PER_ADA = 85, PER_OBS = 80, PER_BLD = 40 },
        reputation = { primary = "tyrants", secondary = "spies" },
        mottos = {
            "We see the fine print.",
            "The unseen clause cuts deepest.",
            "Trust is a derivative we trade.",
            "Silence is our margin.",
            "Every shadow has a balance.",
            "We were never on the books.",
            "Fear is cheaper than litigation.",
            "The knife remembers what the contract redacted.",
            "Secrets are our liquid assets.",
            "No one audits the auditor.",
        },
    },
    {
        id = "ancient_blood",
        label = "Ancients",
        description = "Traditionalists who cling to the old ways. Their strength is their rigidity.",
        category_scores = { physical = 65, mental = 50, social = 65, creative = 35 },
        personality = { PER_LOY = 90, PER_ADA = 20, PER_PRI = 80, PER_OBS = 60 },
        reputation = { primary = "traditionalists", secondary = "honor-bound" },
        mottos = {
            "We were here before the ledger.",
            "We were here before you opened your account.",
            "Tradition is the only solvent institution.",
            "The old debts hold.",
            "Honor above leverage.",
            "We do not restructure. We outlast.",
            "The ancestors audit from beyond.",
            "What was owed then is owed now.",
            "Our roots run deeper than your balance sheets.",
            "Time compounds. We do not bend.",
        },
    }
}

-- =========================================================================
-- Estate Types (Starting Holdings)
-- =========================================================================
WorldbuilderData.estate_types = {
    {
        id = "fortress",
        label = "The Iron Vault",
        description = "High walls and deep armories. +10 Steel, +5 Power Yield.",
        type = "fortress",
        size = 3,
        start_resources = { steel = 10 }
    },
    {
        id = "scriptorium",
        label = "The Archive Bone",
        description = "A hall of records carved from older ruin. +15 Lore, +5 Lore Yield.",
        type = "library",
        size = 3,
        start_resources = { lore = 15 }
    },
    {
        id = "trade_hub",
        label = "The Counting Wharf",
        description = "A port where everything has a price. +20 Gold, +10 Gold Yield.",
        type = "port",
        size = 3,
        start_resources = { gold = 20 }
    },
    {
        id = "temple",
        label = "The Marrow Shrine",
        description = "Where the bloodline prays to what it owes. +10 Lore, +5 Zealotry.",
        type = "temple",
        size = 3,
        start_resources = { lore = 10 }
    }
}

-- =========================================================================
-- Founder Customization Rules
-- =========================================================================
WorldbuilderData.founder_rules = {
    point_pool = 100, -- Points to add/subtract from baseline 50
    min_trait = 10,
    max_trait = 90,
    -- Functional traits that cost points
    traits_to_customize = {
        "PHY_STR", "PHY_VIT", "PHY_AGI", "PHY_FER", 
        "MEN_INT", "MEN_WIL", "MEN_COM", "MEN_CUN",
        "SOC_CHA", "SOC_ELO", "SOC_LEA", "SOC_NEG",
        "CRE_ING", "CRE_CRA", "CRE_VIS", "CRE_EXP",
        "PHY_HGT", "PHY_BLD"
    },
    -- Cosmetic traits that are free selections
    aesthetics = {
        {
            id = "PHY_SKN",
            label = "Skin Tone",
            options = {
                { label = "Ghostly", val = 10 },
                { label = "Fair",    val = 35 },
                { label = "Olive",   val = 55 },
                { label = "Bronze",  val = 75 },
                { label = "Deep",    val = 95 }
            }
        },
        {
            id = "PHY_EYE",
            label = "Eye Color",
            options = {
                { label = "Emerald", val = 10 },
                { label = "Icy Blue", val = 35 },
                { label = "Mist Grey", val = 50 },
                { label = "Amber",    val = 70 },
                { label = "Void",     val = 95 }
            }
        },
        {
            id = "PHY_HAI",
            label = "Hair Color",
            options = {
                { label = "Vivid Red", val = 15 },
                { label = "Platinum",  val = 35 },
                { label = "Autumn Gold", val = 50 },
                { label = "Chestnut",  val = 70 },
                { label = "Midnight",  val = 95 }
            }
        },
        {
            id = "PHY_HTX",
            label = "Hair Texture",
            options = {
                { label = "Straight", val = 10 },
                { label = "Wavy",     val = 45 },
                { label = "Curly",    val = 75 },
                { label = "Coily",    val = 95 }
            }
        },
        {
            id = "PHY_FSH",
            label = "Face Shape",
            options = {
                { label = "Soft",    val = 15 },
                { label = "Defined", val = 50 },
                { label = "Angular", val = 75 },
                { label = "Razor-Sharp", val = 95 }
            }
        }
    }
}

-- =========================================================================
-- Starting Conditions
-- =========================================================================
WorldbuilderData.starting_conditions = {
    { id = "none",   label = "Calm Shores",     desc = "No crisis. A rare window of peace to build foundations." },
    { id = "war",    label = "Born in Blood",    desc = "War rages from the first day. Forges strength — or breaks the bloodline early.", intensity = 0.5, duration = 3 },
    { id = "famine", label = "The Hungry Start", desc = "Stores are empty. Survival itself is the first test.", intensity = 0.4, duration = 3 },
    { id = "plague", label = "The Pox Cradle",   desc = "Disease saturates the land. Only the immune thrive.", intensity = 0.5, duration = 3 },
}

-- =========================================================================
-- Founding Relic Templates
-- =========================================================================
WorldbuilderData.relic_types = {
    { id = "weapon", label = "Weapon",   desc = "A blade, bow, or bludgeon. The argument of last resort.", icon = "W" },
    { id = "tome",   label = "Tome",     desc = "A book of secrets. Knowledge is the slowest poison.",     icon = "T" },
    { id = "crown",  label = "Crown",    desc = "A symbol of authority. Power made visible.",              icon = "C" },
    { id = "relic",  label = "Relic",     desc = "A fragment of something older. Its purpose is half-forgotten.", icon = "R" },
}

WorldbuilderData.relic_effects = {
    { id = "PHY_STR", label = "Strength",   category = "physical", bonus = 5 },
    { id = "PHY_VIT", label = "Vitality",   category = "physical", bonus = 5 },
    { id = "MEN_INT", label = "Intellect",  category = "mental",   bonus = 5 },
    { id = "MEN_WIL", label = "Willpower",  category = "mental",   bonus = 5 },
    { id = "SOC_CHA", label = "Charisma",   category = "social",   bonus = 5 },
    { id = "SOC_LEA", label = "Leadership", category = "social",   bonus = 5 },
    { id = "CRE_ING", label = "Ingenuity",  category = "creative", bonus = 5 },
    { id = "CRE_VIS", label = "Vision",     category = "creative", bonus = 5 },
}

-- =========================================================================
-- Personality Axis Display Names
-- =========================================================================
WorldbuilderData.personality_axes = {
    { id = "PER_BLD", label = "Boldness",      low = "Cautious",    high = "Reckless" },
    { id = "PER_CRM", label = "Cruelty/Mercy",  low = "Merciful",    high = "Cruel" },
    { id = "PER_OBS", label = "Obsession",      low = "Detached",    high = "Obsessive" },
    { id = "PER_LOY", label = "Loyalty",        low = "Treacherous",  high = "Devoted" },
    { id = "PER_CUR", label = "Curiosity",      low = "Incurious",   high = "Restless" },
    { id = "PER_VOL", label = "Volatility",     low = "Steady",      high = "Volatile" },
    { id = "PER_PRI", label = "Pride",          low = "Humble",      high = "Proud" },
    { id = "PER_ADA", label = "Adaptability",    low = "Rigid",       high = "Adaptive" },
}

-- =========================================================================
-- Founding Faith Domains
-- =========================================================================
WorldbuilderData.faith_domains = {
    { id = "war",       label = "War",       desc = "Steel and blood. The faith glorifies conquest." },
    { id = "harvest",   label = "Harvest",   desc = "Grain and growth. The faith blesses the land." },
    { id = "secrets",   label = "Secrets",   desc = "Knowledge and shadow. The faith hoards truth." },
    { id = "iron",      label = "Iron",      desc = "Industry and endurance. The faith forges." },
    { id = "rot",       label = "Rot",       desc = "Decay and renewal. The faith embraces entropy." },
    { id = "fertility", label = "Fertility", desc = "Life and lineage. The faith demands heirs." },
}

-- =========================================================================
-- Founder Archetypes (Quick-select presets)
-- =========================================================================
WorldbuilderData.founder_archetypes = {
    {
        id = "warrior",
        label = "Warrior",
        desc = "Strength and endurance. The bloodline begins with iron in its veins.",
        trait_bias = { PHY_STR = 15, PHY_END = 10, SOC_INM = 8, SOC_LEA = 5 },
        personality = { PER_BLD = 70, PER_PRI = 70, PER_CRM = 65, PER_ADA = 35 },
    },
    {
        id = "scholar",
        label = "Scholar",
        desc = "Intellect and focus. The bloodline begins with questions.",
        trait_bias = { MEN_INT = 15, MEN_FOC = 10, MEN_ANA = 8, MEN_LRN = 5 },
        personality = { PER_CUR = 75, PER_VOL = 30, PER_CRM = 35, PER_OBS = 65 },
    },
    {
        id = "diplomat",
        label = "Diplomat",
        desc = "Charisma and negotiation. The bloodline begins with open hands.",
        trait_bias = { SOC_CHA = 15, SOC_NEG = 10, SOC_ELO = 8, SOC_AWR = 5 },
        personality = { PER_ADA = 75, PER_LOY = 60, PER_PRI = 55, PER_VOL = 30 },
    },
    {
        id = "survivor",
        label = "Survivor",
        desc = "Vitality and grit. The bloodline begins stubborn.",
        trait_bias = { PHY_VIT = 15, PHY_END = 10, PHY_IMM = 8, PHY_REC = 5 },
        personality = { PER_LOY = 75, PER_ADA = 70, PER_PRI = 35, PER_VOL = 40 },
    },
    {
        id = "schemer",
        label = "Schemer",
        desc = "Cunning and deception. The bloodline begins in shadow.",
        trait_bias = { MEN_CUN = 15, SOC_DEC = 10, SOC_MAN = 8, MEN_PAT = 5 },
        personality = { PER_OBS = 70, PER_LOY = 35, PER_CRM = 65, PER_BLD = 40 },
    },
    {
        id = "artisan",
        label = "Artisan",
        desc = "Vision and craft. The bloodline begins with calloused hands.",
        trait_bias = { CRE_ING = 15, CRE_CRA = 10, CRE_VIS = 8, CRE_EXP = 5 },
        personality = { PER_CUR = 70, PER_VOL = 60, PER_ADA = 65, PER_OBS = 55 },
    },
}

-- =========================================================================
-- Bloodline Motto Presets
-- =========================================================================
WorldbuilderData.motto_presets = {
    "We endure.",
    "By iron, not mercy.",
    "Ours is the longer memory.",
    "What was taken will be returned.",
    "Neither fire nor flood.",
    "Until the last breath.",
    "We do not kneel.",
    "The debt is owed to us.",
    "What is ours is ours.",
    "The line holds.",
    "Every heir is a wager.",
    "The blood remembers.",
    "Nothing ends when you die.",
    "Your bloodline will answer for this.",
    "We were not given. We took.",
    "The ledger never closes.",
    "All accounts settle eventually.",
    "We pay in generations.",
    "The interest compounds.",
    "Ruin is patient. So are we.",
}

return WorldbuilderData
