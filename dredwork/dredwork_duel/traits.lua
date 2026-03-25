-- dredwork Duel — Combat Traits
-- Modifiers that alter duel behavior. Can be assigned from genetics/biography.

return {
    Telegraphed       = { id = "Telegraphed",       description = "Moves are easier to read" },
    Unorthodox        = { id = "Unorthodox",        description = "Move order may be shuffled unexpectedly" },
    Misdirection      = { id = "Misdirection",      description = "Revealed intent may be false" },
    ["Momentum Fighter"] = { id = "Momentum Fighter", description = "Consecutive strikes gain bonus damage" },
    ["Counter Specialist"] = { id = "Counter Specialist", description = "Parries deal extra posture pressure" },
    SeesFuture        = { id = "SeesFuture",        description = "Adapts plan after opponent commits" },
    Veiled            = { id = "Veiled",            description = "Exact intent cannot be read" },
    Prophet           = { id = "Prophet",           description = "Near-perfect counter ability + veiled" },
}
