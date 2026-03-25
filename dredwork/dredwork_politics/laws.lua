-- dredwork Politics — Laws
-- Specific active policies that modify the world state.

local Laws = {
    -- Economic Laws
    high_taxation = {
        label = "Heavy Tithes",
        category = "economic",
        effects = {
            gold_mod = 1.5,      -- Increases revenue
            faction_loyalty = -5 -- Angers factions
        },
        description = "Maximum gold extraction at the cost of stability."
    },
    
    trade_guilds = {
        label = "Guild Recognition",
        category = "economic",
        effects = {
            market_volatility = -0.5, -- Stabilizes prices
            wealth_drift = 2           -- Slow steady growth
        },
        description = "Empower merchants to manage the market."
    },
    
    -- Social Laws
    hereditary_titles = {
        label = "Bloodline Primacy",
        category = "social",
        effects = {
            rumor_spread = 0.8,    -- Rumors about nobles spread faster
            reputation_gain = 1.2, -- Reputation lasts longer/is more impactful
            tradition = 10
        },
        description = "Your name means more than your deeds."
    },
    
    open_learning = {
        label = "Public Archives",
        category = "social",
        effects = {
            progress_gain = 5,
            tradition = -5
        },
        description = "Knowledge is the property of all."
    }
}

return Laws
