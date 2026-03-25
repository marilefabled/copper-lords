-- dredwork Narrative — Character Vignettes
-- Short personality-driven character snapshots based on traits and world state.

local RNG = require("dredwork_core.rng")

local Vignettes = {}

--- Determine the dominant personality axis for a character.
local function get_dominant_axis(heir)
    if not heir or not heir.traits then return "default" end

    -- Check key personality traits and return the most extreme
    local checks = {
        { axis = "bold",     trait = "PER_BLD", threshold = 70 },
        { axis = "cautious", trait = "PER_BLD", threshold = 30, invert = true },
        { axis = "cunning",  trait = "PER_OBS", threshold = 70 },
        { axis = "loyal",    trait = "PER_LOY", threshold = 70 },
        { axis = "volatile", trait = "PER_VOL", threshold = 70 },
        { axis = "kind",     trait = "SOC_EMP", threshold = 70 },
        { axis = "cruel",    trait = "SOC_EMP", threshold = 30, invert = true },
    }

    for _, check in ipairs(checks) do
        local t = heir.traits[check.trait]
        if t then
            local val = type(t) == "table" and (t.value or 50) or t
            if check.invert then
                if val < check.threshold then return check.axis end
            else
                if val > check.threshold then return check.axis end
            end
        end
    end

    return "default"
end

--- Determine the world mood from game_state.
local function get_world_mood(gs)
    -- Check for active conflict/war
    if gs.politics and gs.politics.unrest and gs.politics.unrest > 60 then
        return "unrest"
    end
    -- Check for active peril
    if gs.perils and gs.perils.active and #gs.perils.active > 0 then
        return "peril"
    end
    -- Check for famine
    if gs.markets then
        for _, market in pairs(gs.markets) do
            if market.prices and market.prices.food and market.prices.food > 15 then
                return "famine"
            end
        end
    end
    -- Check for prosperity
    if gs.resources and gs.resources.gold and gs.resources.gold > 500 then
        return "prosperity"
    end
    return "peace"
end

--- Vignette text pools: personality axis x world mood.
local VIGNETTE_POOL = {
    bold = {
        unrest   = {
            "{name}, ever defiant, addresses the crowd from the palace steps. Fear is not in their vocabulary.",
            "{name} sharpens their blade. If the people want a fight, they say, they will find one ready.",
        },
        peril    = {
            "{name} personally leads the relief column into the stricken district. Duty, they insist, demands no less.",
            "{name} refuses to leave the affected zone. Their courage inspires the weary relief workers.",
        },
        famine   = {
            "{name} orders the palace kitchens opened to the public. A bold gesture — or a reckless one.",
            "{name} rides out to inspect the granaries personally. No report can substitute for their own eyes.",
        },
        prosperity = {
            "{name} celebrates the good times with grand feasts and tournaments. Life is for living, they declare.",
            "{name} uses the surplus to fund an expedition beyond the borders. Fortune favors the bold.",
        },
        peace    = {
            "{name} grows restless in peacetime. They train harder, ride farther, and push every limit.",
            "{name} spars with the guard captain each morning. Stillness, they confide, makes them uneasy.",
        },
    },
    cautious = {
        unrest   = {
            "{name} retreats to the inner chambers, poring over intelligence reports. Every variable must be weighed.",
            "{name} quietly doubles the palace guard. No announcement is made. Caution before confrontation.",
        },
        peril    = {
            "{name} orders quarantine measures with methodical precision. No half-measures, no exceptions.",
            "{name} consults every healer and scholar before acting. Prudence, they insist, will save more lives than haste.",
        },
        famine   = {
            "{name} begins rationing the household stores personally, counting every grain.",
            "{name} summons the treasury officials. Every coin must be accounted for before aid is distributed.",
        },
        prosperity = {
            "{name} orders the surplus stored, not spent. Winter always comes, they remind the court.",
            "{name} invests quietly in fortifications and granaries. Wealth is only useful if it endures.",
        },
        peace    = {
            "{name} spends long hours in the archives, studying the mistakes of their predecessors.",
            "{name} walks the walls each evening, checking the watchmen. Vigilance is its own reward.",
        },
    },
    cunning = {
        unrest   = {
            "{name} plays factions against each other with a smile. Let them exhaust themselves, they think.",
            "{name} has been meeting with the opposition leaders in private. What was discussed, none can say.",
        },
        peril    = {
            "{name} sees opportunity where others see disaster. Contracts are signed, favors are called in.",
            "{name} quietly buys land from those fleeing the crisis. Their compassion is strategic.",
        },
        famine   = {
            "{name} has cornered the remaining grain supply. Whether to save the people or leverage them, time will tell.",
            "{name} offers food to the hungry — but only those who pledge loyalty first.",
        },
        prosperity = {
            "{name} uses the good times to build a web of alliances. Gold is temporary; debts last forever.",
            "{name} smiles at every courtier, remembers every name. Their generosity is never without purpose.",
        },
        peace    = {
            "{name} has been seen meeting with shadowy figures. Whether to combat the underworld or join it, none can say.",
            "{name} studies the court like a chessboard, positioning pieces for a game only they can see.",
        },
    },
    loyal = {
        unrest   = {
            "{name} stands firm beside the old order. Loyalty, even to a crumbling throne, defines them.",
            "{name} rallies the faithful with quiet conviction. Their steadfastness holds the center.",
        },
        famine   = {
            "{name} shares their own rations with the servants. They will not eat while others starve.",
        },
        peace    = {
            "{name} tends to their bonds with care — visiting old allies, writing letters, keeping promises.",
        },
        default  = {
            "{name} honors every commitment, remembers every oath. In a world of shifting loyalties, they are bedrock.",
        },
    },
    volatile = {
        unrest   = {
            "{name}'s temper flares. They overturn the council table and storm from the chamber. Advisors exchange uneasy glances.",
            "{name} makes a fiery speech that inspires some and terrifies others. There is no middle ground with them.",
        },
        peace    = {
            "{name} picks a quarrel with a visiting diplomat over a perceived slight. The court scrambles to contain the fallout.",
        },
        default  = {
            "{name}'s moods shift like weather. Today, brilliance. Tomorrow, fury. Those close to them learn to read the signs.",
        },
    },
    kind = {
        peril    = {
            "{name} weeps openly for the suffering. Their compassion is genuine — and, some whisper, a weakness.",
        },
        famine   = {
            "{name} gives away their own meals to the children of the court. They grow thinner as the crisis deepens.",
        },
        default  = {
            "{name} pauses to speak with a servant, asking after their family by name. Small kindnesses define them.",
            "{name} settles a dispute between two merchants with patience and warmth. Both leave satisfied.",
        },
    },
    cruel = {
        unrest   = {
            "{name} orders exemplary punishment for the ringleaders. Fear, they believe, is the only true authority.",
        },
        peace    = {
            "{name} finds sport in the suffering of those beneath them. The court pretends not to notice.",
        },
        default  = {
            "{name}'s gaze carries a chill that makes even loyal servants flinch. Mercy is a foreign concept to them.",
        },
    },
    default = {
        default  = {
            "{name} goes about the duties of the day. Quiet competence, if not brilliance.",
            "{name} attends to matters of state with a steady hand. History rarely remembers the reliable.",
            "Life continues for {name}. The days blur together — meetings, meals, the weight of expectation.",
        },
    },
}

--- Generate a vignette for the current heir.
---@param gs table game_state
---@return table|nil {text, display_hint, priority} or nil
function Vignettes.generate(gs)
    -- Probability gate: ~30% chance per call
    if not RNG.chance(0.3) then return nil end

    local heir = gs.current_heir
    if not heir or heir.is_dead then return nil end

    local axis = get_dominant_axis(heir)
    local mood = get_world_mood(gs)
    local name = heir.name or "The heir"

    -- Look up text pool
    local axis_pool = VIGNETTE_POOL[axis] or VIGNETTE_POOL.default
    local mood_pool = axis_pool[mood] or axis_pool.default or VIGNETTE_POOL.default.default

    if not mood_pool or #mood_pool == 0 then
        mood_pool = VIGNETTE_POOL.default.default
    end

    local text = RNG.pick(mood_pool)
    if not text then return nil end

    text = text:gsub("{name}", name)

    return {
        text = text,
        display_hint = "panel",
        priority = 45,
        tags = {"vignette", "character"},
    }
end

return Vignettes
