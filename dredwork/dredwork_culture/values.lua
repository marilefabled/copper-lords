-- dredwork Culture — Values
-- Definitions for the core axes of cultural identity.
-- Each axis is a spectrum from 0 to 100. The midpoint (50) is neutral.
-- These affect genetics, technology, religion, strife, economy, military, and more
-- through The Ripple and direct event bus queries.

local Values = {
    -- Tradition vs Progress (CUL_TRD)
    -- 0: Radical Progress, 100: Strict Tradition
    -- Affects: tech speed, rumor spread, religious tension, strife bias
    tradition = {
        id = "CUL_TRD",
        label = "Tradition",
        low_label = "Progressive",
        high_label = "Traditional",
        drift_rate = 0.1,  -- natural regression toward center per month
        personality_bias = { PER_ADA = 0.3 },  -- high tradition → adaptability bias
    },

    -- Martial vs Pacifist (CUL_MAR)
    -- 0: Absolute Pacifism, 100: Warrior Culture
    -- Affects: military morale, sports enthusiasm, conquest willingness, heir boldness
    martial = {
        id = "CUL_MAR",
        label = "Martial",
        low_label = "Pacifist",
        high_label = "Warlike",
        drift_rate = 0.15,
        personality_bias = { PER_BLD = 0.4 },  -- martial culture → boldness
    },

    -- Collective vs Individual (CUL_COL)
    -- 0: High Individualism, 100: Total Collectivism
    -- Affects: taxation, unrest thresholds, crime tolerance, loyalty norms
    collective = {
        id = "CUL_COL",
        label = "Collectivism",
        low_label = "Individualist",
        high_label = "Collectivist",
        drift_rate = 0.1,
        personality_bias = { PER_LOY = 0.3 },  -- collective → loyalty
    },

    -- Faith vs Reason (CUL_FAI)
    -- 0: Pure Rationalism, 100: Deep Mysticism
    -- Affects: religion zeal, technology speed, tolerance, superstition
    faith = {
        id = "CUL_FAI",
        label = "Mysticism",
        low_label = "Rational",
        high_label = "Mystical",
        drift_rate = 0.08,
        personality_bias = { PER_CUR = -0.2 },  -- mysticism dampens curiosity
    },

    -- Honor vs Pragmatism (CUL_HON)
    -- 0: Pure Pragmatism, 100: Rigid Honor Code
    -- Affects: crime tolerance, betrayal frequency, duel culture, court loyalty
    honor = {
        id = "CUL_HON",
        label = "Honor",
        low_label = "Pragmatic",
        high_label = "Honor-bound",
        drift_rate = 0.1,
        personality_bias = { PER_PRI = 0.3 },  -- honor → pride
    },

    -- Openness vs Insularity (CUL_OPN)
    -- 0: Total Isolation, 100: Radical Openness
    -- Affects: strife/migration tolerance, trade, rumor speed, religious diversity
    openness = {
        id = "CUL_OPN",
        label = "Openness",
        low_label = "Insular",
        high_label = "Cosmopolitan",
        drift_rate = 0.12,
        personality_bias = { PER_ADA = 0.2, PER_CUR = 0.2 },
    },

    -- Austerity vs Indulgence (CUL_AUS)
    -- 0: Hedonistic Excess, 100: Monastic Austerity
    -- Affects: economy spending, home comfort expectations, crime temptation, religion zeal
    austerity = {
        id = "CUL_AUS",
        label = "Austerity",
        low_label = "Indulgent",
        high_label = "Austere",
        drift_rate = 0.1,
        personality_bias = { PER_VOL = 0.2 },  -- austerity → composure
    },

    -- Hierarchy vs Egalitarianism (CUL_HIE)
    -- 0: Total Equality, 100: Rigid Caste System
    -- Affects: politics system fit, court loyalty mechanics, strife, succession
    hierarchy = {
        id = "CUL_HIE",
        label = "Hierarchy",
        low_label = "Egalitarian",
        high_label = "Hierarchical",
        drift_rate = 0.08,
        personality_bias = { PER_OBS = 0.2 },  -- hierarchy → observance of rules
    },
}

return Values
