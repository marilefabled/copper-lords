-- dredwork Crime — Criminal Organizations
-- Definitions for the power structures of the underworld.

local Organizations = {
    street_gang = {
        label = "Street Gang",
        description = "Violent, visible, and localized. High ruthlessness, low subtlety.",
        base_attributes = {
            ruthlessness = 80,
            subtlety = 20,
            influence = 10,
            wealth = 15
        },
        tags = { "violent", "localized", "recruitment_heavy" }
    },
    
    thieves_guild = {
        label = "Thieves Guild",
        description = "Professional burglars and informants. High subtlety, medium wealth.",
        base_attributes = {
            ruthlessness = 30,
            subtlety = 85,
            influence = 40,
            wealth = 50
        },
        tags = { "shadowy", "informants", "non_violent" }
    },
    
    shadow_cartel = {
        label = "Shadow Cartel",
        description = "Global criminal empire. High wealth, high influence, balanced ruthlessness.",
        base_attributes = {
            ruthlessness = 60,
            subtlety = 70,
            influence = 90,
            wealth = 100
        },
        tags = { "empire", "corruptive", "sophisticated" }
    }
}

return Organizations
