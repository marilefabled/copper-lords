-- dredwork Religion — Belief Systems
-- Definitions for various faiths and spiritual structures.

local Beliefs = {
    theocracy = {
        label = "High Theocracy",
        description = "Rule by divine mandate. High zeal, low tolerance.",
        base_attributes = {
            zeal = 80,
            tolerance = 20,
            tradition = 90
        },
        tags = { "dogmatic", "organized", "strict" },
        sacred_species = "hound"
    },
    
    animism = {
        label = "Old Animism",
        description = "Spirits in all things. High tradition, medium tolerance.",
        base_attributes = {
            zeal = 40,
            tolerance = 60,
            tradition = 85
        },
        tags = { "spiritual", "decentralized", "nature" },
        sacred_species = "wolves"
    },
    
    cult_of_reason = {
        label = "Cult of Reason",
        description = "Logic as the highest power. Low tradition, high progress.",
        base_attributes = {
            zeal = 30,
            tolerance = 70,
            tradition = 10
        },
        tags = { "intellectual", "secular", "modern" },
        sacred_species = "rats" -- ironic choice
    }
}

return Beliefs
