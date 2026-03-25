-- dredwork Crime — Operations
-- Specific activities criminal organizations undertake.

local Operations = {
    extortion = {
        label = "Protection Racket",
        risk = 40,
        reward = 30,
        heat_gain = 10,
        unrest_gain = 5,
        requirements = { ruthlessness = 50 }
    },
    
    smuggling = {
        label = "Contraband Run",
        risk = 30,
        reward = 60,
        heat_gain = 5,
        unrest_gain = 2,
        requirements = { subtlety = 40 }
    },
    
    political_corruption = {
        label = "Buying Influence",
        risk = 20,
        reward = 10, -- Lower direct wealth, high systemic power
        heat_gain = 2,
        corruption_gain = 15,
        requirements = { influence = 60, wealth = 50 }
    }
}

return Operations
