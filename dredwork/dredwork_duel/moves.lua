-- dredwork Duel — Move Definitions
-- 16 moves across 5 categories. Theme-agnostic labels can be reskinned.
-- Ported from 5 Steps Ahead.

local defs = {
    high_punch      = { name = "High Strike",     category = "Strike",     threat = "Pressure",    height = "high", damage = 2, posture = 1 },
    mid_punch       = { name = "Mid Strike",      category = "Strike",     threat = "Reliable",    height = "mid",  damage = 2, posture = 1 },
    low_kick        = { name = "Low Strike",      category = "Strike",     threat = "Control",     height = "low",  damage = 1, posture = 2, tags = { low = true } },
    stomp           = { name = "Heavy Strike",    category = "Strike",     threat = "High Damage", height = "low",  damage = 3, posture = 2, tags = { heavy = true, anti_low = true } },
    clinch_attempt  = { name = "Clinch",          category = "Movement",   threat = "Control",     damage = 1, posture = 2, tags = { clinch = true }, setsStance = "Aggressive" },

    guard_high      = { name = "Guard High",      category = "Defense",    threat = "Block",  height = "high", block = { high = true, mid = true }, setsStance = "Defensive" },
    guard_low       = { name = "Guard Low",       category = "Defense",    threat = "Block",  height = "low",  block = { low = true }, setsStance = "Defensive" },
    parry           = { name = "Parry",           category = "Defense",    threat = "Counter", tags = { parry = true }, setsStance = "Defensive" },

    duck            = { name = "Duck",            category = "Evasion",    threat = "Avoid High", tags = { duck = true } },
    sidestep        = { name = "Sidestep",        category = "Evasion",    threat = "Reposition", tags = { sidestep = true }, setsStance = "Neutral" },
    retreat         = { name = "Retreat",         category = "Evasion",    threat = "Reset",      tags = { retreat = true }, setsStance = "Defensive" },

    advance         = { name = "Advance",         category = "Movement",   threat = "Pressure", tags = { advance = true }, setsStance = "Aggressive" },
    circle          = { name = "Circle",          category = "Movement",   threat = "Angle",    tags = { circle = true }, setsStance = "Neutral" },

    feint           = { name = "Feint",           category = "Disruption", threat = "Bait",        tags = { feint = true }, setsStance = "Neutral" },
    delay           = { name = "Delay",           category = "Disruption", threat = "Timing",      tags = { delay = true }, setsStance = "Neutral" },
    bait            = { name = "Bait",            category = "Disruption", threat = "Countertrap", tags = { bait = true }, setsStance = "Defensive" },
}

local pool = {
    "high_punch", "mid_punch", "low_kick", "stomp",
    "guard_high", "guard_low", "parry",
    "duck", "sidestep", "retreat",
    "advance", "circle", "clinch_attempt",
    "feint", "delay", "bait",
}

local categoryMoves = { Strike = {}, Defense = {}, Evasion = {}, Movement = {}, Disruption = {} }
for _, id in ipairs(pool) do
    local m = defs[id]
    categoryMoves[m.category][#categoryMoves[m.category] + 1] = id
end

return { defs = defs, pool = pool, categoryMoves = categoryMoves }
