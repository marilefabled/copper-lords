-- Dark Legacy — Education Styles & Traditions
-- Defines the institutional paths that shape an heir's mind and body.
-- Ties into Culture (Tradition), Factions (Sponsorship), and Eras.

local Education = {}

Education.styles = {
    {
        id = "the_iron_scriptorium",
        label = "The Counting House",
        era_affinity = { "iron", "gilded" },
        primary_cat = "mental",
        traits = { MEN_MEM = 8, MEN_ANA = 5, SOC_ELO = 5 },
        trait_flavors = {
            MEN_MEM = "Filing systems. Cross-references. The dull machinery of not forgetting.",
            MEN_ANA = "Trained to dissect problems like a surgeon.",
            SOC_ELO = "The Scriptorium teaches words as instruments of debt collection.",
        },
        mastery_tag = "MASTER_SCHOLAR",
        flavor = "Filing systems. Cross-references. The dull machinery of not forgetting.",
        description = "Intensive study of law and history. Reduces cultural memory decay."
    },
    {
        id = "the_blood_pit",
        label = "The Flaying Floor",
        era_affinity = { "ancient", "iron" },
        primary_cat = "physical",
        traits = { PHY_STR = 8, PHY_PAI = 8, PHY_END = 5 },
        trait_flavors = {
            PHY_STR = "Those who break are not discussed. Those who remain are enrolled.",
            PHY_PAI = "The body learns what the mind would rather not know.",
            PHY_END = "Forged in the pit. Tempered by exhaustion.",
        },
        mastery_tag = "MASTER_WARRIOR",
        flavor = "Those who break are not discussed. Those who remain are enrolled.",
        description = "Brutal physical conditioning. Increases survival chance in combat crucibles."
    },
    {
        id = "the_gutter_logic",
        label = "The Back-Ledger",
        era_affinity = { "dark", "gilded" },
        primary_cat = "social",
        traits = { SOC_DEC = 8, MEN_CUN = 8, SOC_AWR = 5 },
        trait_flavors = {
            SOC_DEC = "Every transaction documented. Every weakness catalogued.",
            MEN_CUN = "Every angle has an angle. Find it first.",
            SOC_AWR = "Survival means reading the room before entering it.",
        },
        mastery_tag = "MASTER_SPY",
        flavor = "Every transaction documented. Every weakness catalogued.",
        description = "Schooled in the back-alleys and counting houses. Increases Wealth generation."
    },
    {
        id = "the_star_gaze",
        label = "The Margin Notes",
        era_affinity = { "ancient", "arcane", "twilight" },
        primary_cat = "creative",
        traits = { CRE_SYM = 8, MEN_ABS = 8, MEN_DRM = 5 },
        trait_flavors = {
            CRE_SYM = "Pattern recognition applied to things that may not have patterns.",
            MEN_ABS = "The mind stretches toward things that have no shape.",
            MEN_DRM = "Dreams are data the conscious mind refuses to file properly.",
        },
        mastery_tag = "MASTER_MYSTIC",
        flavor = "Pattern recognition applied to things that may not have patterns.",
        description = "Mystical and abstract education. Reduces mutation pressure."
    },
    {
        id = "the_vassal_path",
        label = "The Debtor's Walk",
        era_affinity = "all",
        primary_cat = "social",
        traits = { SOC_PAK = 10, SOC_LYS = 10, SOC_CHA = 5 },
        trait_flavors = {
            SOC_PAK = "Service is a ledger entry. Loyalty is the interest rate.",
            SOC_LYS = "Loyalty is a currency that never inflates.",
            SOC_CHA = "A vassal learns to charm before they learn to command.",
        },
        mastery_tag = "MASTER_DIPLOMAT",
        flavor = "Service is a ledger entry. Loyalty is the interest rate.",
        description = "Education sponsored by a rival house. Boosts faction relations but grants them influence."
    }
}

return Education
