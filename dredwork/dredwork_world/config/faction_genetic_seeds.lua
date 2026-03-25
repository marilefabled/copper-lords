-- Dark Legacy — Faction Genetic Seeds
-- Initial trait average overrides per starting faction.
-- Maps faction IDs to specific trait averages that define their genetic identity.

local faction_genetic_seeds = {
    house_mordthen = {
        PHY_STR = 68, PHY_END = 65, PHY_REF = 60, PHY_VIT = 62,
        PHY_AGI = 58, PHY_PAI = 64, PHY_BON = 63, PHY_HGT = 65,
        PHY_BLD = 66, PHY_SEN = 55,
        MEN_WIL = 58, MEN_COM = 55, MEN_DEC = 60,
        SOC_INM = 65, SOC_LEA = 58,
    },
    house_pallwick = {
        MEN_INT = 68, MEN_MEM = 65, MEN_FOC = 63, MEN_ANA = 66,
        MEN_PAT = 62, MEN_LRN = 64, MEN_STR = 60, MEN_ABS = 63,
        MEN_PER = 58, MEN_SPA = 60,
        CRE_ING = 58, CRE_VIS = 55,
        SOC_TEA = 56,
    },
    house_sablecourt = {
        SOC_CHA = 66, SOC_ELO = 65, SOC_DEC = 68, SOC_NEG = 63,
        SOC_AWR = 64, SOC_INF = 60, SOC_MAN = 66, SOC_CRD = 62,
        SOC_CUL = 58,
        MEN_CUN = 65, MEN_PER = 60, MEN_ITU = 58,
    },
    house_cinderwell = {
        CRE_ING = 66, CRE_CRA = 68, CRE_EXP = 65, CRE_AES = 64,
        CRE_VIS = 63, CRE_NAR = 60, CRE_MEC = 62, CRE_INN = 65,
        CRE_RES = 60, CRE_SYM = 58,
        PHY_END = 55, MEN_ABS = 56,
    },
    house_graith = {
        PHY_STR = 62, PHY_END = 64, PHY_VIT = 63, PHY_PAI = 60,
        PHY_BON = 62, PHY_IMM = 58, PHY_REC = 60,
        MEN_WIL = 65, MEN_COM = 60, MEN_STH = 58,
        SOC_LYS = 55, SOC_TRU = 56,
    },
}

return faction_genetic_seeds
