-- Dark Legacy — Personality Axis Mappings
-- Defines the 8 personality axes and their trait influence weights.
-- Each axis is 60% directly inherited, 40% derived from these trait inputs.

local personality_maps = {}

personality_maps.axes = {
    {
        id = "PER_BLD",
        name = "Boldness",
        low_label = "Cautious, risk-averse, calculating",
        high_label = "Reckless, courageous, first-to-act",
        inheritance_mode = "dominant_recessive",
    },
    {
        id = "PER_CRM",
        name = "Cruelty / Mercy",
        low_label = "Deeply merciful, self-sacrificing",
        high_label = "Ruthless, no hesitation, cold",
        inheritance_mode = "blended",
    },
    {
        id = "PER_OBS",
        name = "Obsession",
        low_label = "Detached, easily shifts focus",
        high_label = "Monomaniacal, will not let go",
        inheritance_mode = "dominant_recessive",
    },
    {
        id = "PER_LOY",
        name = "Loyalty",
        low_label = "Self-serving, pragmatic betrayer",
        high_label = "Family-first, will die for blood",
        inheritance_mode = "blended",
    },
    {
        id = "PER_CUR",
        name = "Curiosity",
        low_label = "Incurious, traditional, stays in lane",
        high_label = "Relentless explorer, questioner",
        inheritance_mode = "blended",
    },
    {
        id = "PER_VOL",
        name = "Volatility",
        low_label = "Stoic, unshakeable, emotionally flat",
        high_label = "Explosive, unpredictable, passionate",
        inheritance_mode = "dominant_recessive",
    },
    {
        id = "PER_PRI",
        name = "Pride",
        low_label = "Humble, self-effacing, no ego",
        high_label = "Vain, status-obsessed, legacy-driven",
        inheritance_mode = "blended",
    },
    {
        id = "PER_ADA",
        name = "Adaptability",
        low_label = "Rigid doctrine, never compromises beliefs",
        high_label = "Fluid thinker, shapeshifter, no fixed identity",
        inheritance_mode = "blended",
    },
}

-- Trait-to-personality influence mappings
-- Positive weight = trait pushes axis UP; negative = pushes axis DOWN
personality_maps.axis_maps = {
    PER_BLD = {
        trait_inputs = {
            PHY_STR = 0.1,
            MEN_WIL = 0.15,
            MEN_COM = 0.1,
            MEN_DEC = 0.15,
        },
    },
    PER_CRM = {
        trait_inputs = {
            SOC_EMP = -0.2,
            MEN_COM = 0.1,
            SOC_INM = 0.1,
        },
    },
    PER_OBS = {
        trait_inputs = {
            MEN_FOC = 0.15,
            MEN_WIL = 0.1,
            MEN_PLA = -0.1,
        },
    },
    PER_LOY = {
        trait_inputs = {
            SOC_PAK = 0.15,
            SOC_TRU = 0.1,
            SOC_EMP = 0.1,
        },
    },
    PER_CUR = {
        trait_inputs = {
            MEN_ABS = 0.1,
            CRE_ING = 0.1,
            MEN_PAT = 0.1,
            CRE_INN = 0.1,
        },
    },
    PER_VOL = {
        trait_inputs = {
            MEN_STH = -0.15,
            MEN_COM = -0.1,
            PHY_PAI = -0.05,
        },
    },
    PER_PRI = {
        trait_inputs = {
            SOC_CHA = 0.1,
            SOC_INF = 0.1,
            SOC_INM = 0.05,
        },
    },
    PER_ADA = {
        trait_inputs = {
            MEN_PLA = 0.15,
            PHY_ADP = 0.1,
            SOC_CUL = 0.1,
        },
    },
}

-- Build lookup by axis ID
personality_maps.by_id = {}
for _, axis in ipairs(personality_maps.axes) do
    personality_maps.by_id[axis.id] = axis
end

return personality_maps
