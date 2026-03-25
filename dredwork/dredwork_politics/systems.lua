-- dredwork Politics — Systems
-- Definitions for different ways of organizing power.

local Systems = {
    monarchy = {
        label = "Absolute Monarchy",
        description = "Rule by a single bloodline. High stability, slow progress.",
        base_attributes = {
            order = 80,
            progress = 30,
            centralization = 90
        },
        trait_biases = { PHY_STR = 1.2, SOC_CHA = 1.1 } -- Values traditional power
    },
    
    oligarchy = {
        label = "Merchant Oligarchy",
        description = "Rule by the wealthy few. High economic growth, high corruption.",
        base_attributes = {
            order = 50,
            progress = 60,
            centralization = 60
        },
        trait_biases = { MEN_INT = 1.2, MEN_PLA = 1.3 } -- Values planning and cunning
    },
    
    meritocracy = {
        label = "Pure Meritocracy",
        description = "Rule by the most capable. High progress, low stability.",
        base_attributes = {
            order = 40,
            progress = 90,
            centralization = 30
        },
        trait_biases = { MEN_LRN = 1.5, CRE_IMP = 1.2 } -- Values learning and innovation
    }
}

return Systems
