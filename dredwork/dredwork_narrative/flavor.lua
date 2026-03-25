-- dredwork Narrative — Ambient Flavor Text
-- Seasonal, atmospheric, and world-state-driven atmospheric narrative.

local RNG = require("dredwork_core.rng")

local Flavor = {}

--- Season mapping from month index.
local SEASONS = {
    [1]  = "winter",   -- First Dawn
    [2]  = "winter",   -- Deep Frost
    [3]  = "spring",   -- High Bloom
    [4]  = "spring",   -- Mist Rise
    [5]  = "summer",   -- Sun Peak
    [6]  = "summer",   -- Gold Harvest
    [7]  = "autumn",   -- Leaf Fall
    [8]  = "autumn",   -- Red Dusk
    [9]  = "autumn",   -- Pale Wind
    [10] = "winter",   -- Iron Shadow
    [11] = "winter",   -- Star Night
    [12] = "winter",   -- Final Cold
}

local MONTH_NAMES = {
    "First Dawn", "Deep Frost", "High Bloom", "Mist Rise",
    "Sun Peak", "Gold Harvest", "Leaf Fall", "Red Dusk",
    "Pale Wind", "Iron Shadow", "Star Night", "Final Cold"
}

local SEASONAL_TEXT = {
    winter = {
        "The cold deepens. Frost clings to every surface and breath hangs like smoke in the still air.",
        "Winter tightens its grip on {region}. The hearth fires burn low and the nights grow longer.",
        "Snow blankets {region}. The world is quiet, muffled, waiting.",
        "The bitter cold drives all but the desperate indoors. Even the wolves have gone silent.",
    },
    spring = {
        "New life stirs. The first green shoots push through the thawing earth of {region}.",
        "Spring arrives in {region} — tentative at first, then undeniable. The air smells of turned soil and possibility.",
        "The ice melts. Rivers swell. {region} shakes off the long sleep of winter.",
    },
    summer = {
        "The sun beats down on {region}. The fields ripen and the air shimmers with heat.",
        "Summer in {region} — long days, short tempers, and the promise of harvest ahead.",
        "The warmth of summer fills the streets of {region} with life. Children play where only mud stood weeks ago.",
    },
    autumn = {
        "The leaves turn in {region}. Gold and crimson carpet the roads as the air sharpens.",
        "Autumn settles over {region}. The harvest is in, and the people prepare for what comes next.",
        "The days shorten. In {region}, smoke rises from every chimney as preparations for winter begin.",
    },
}

local OVERLAY_TEXT = {
    war = {
        "Soldiers march through {region}. The rhythm of boots on stone has become the heartbeat of the land.",
        "The shadow of conflict hangs over everything. Even the market chatter carries a nervous edge.",
    },
    plague = {
        "The sick cough behind shuttered windows. The air carries a faint sweetness that everyone pretends not to notice.",
        "Herb-sellers do brisk trade. The temples are full — of the desperate, the dying, and the devout.",
    },
    famine = {
        "The markets are thin. What little food remains commands impossible prices.",
        "Hunger is visible now — in the faces, in the way people walk, in the silence where laughter once lived.",
    },
    prosperity = {
        "The markets overflow. Music drifts from taverns. For once, {region} knows abundance.",
        "Gold flows freely. New construction rises. The people dare to plan for the future.",
    },
}

--- Generate seasonal flavor text.
---@param month number
---@param gs table game_state
---@param region_name string
---@return table|nil {text, display_hint, priority}
function Flavor.get_seasonal(month, gs, region_name)
    -- Probability gate: ~20% chance
    if not RNG.chance(0.2) then return nil end

    local season = SEASONS[month] or "winter"
    local pool = SEASONAL_TEXT[season]
    if not pool or #pool == 0 then return nil end

    local text = RNG.pick(pool)
    text = text:gsub("{region}", region_name or "the realm")

    -- Apply world-state overlay
    local overlay = nil
    if gs.politics and gs.politics.unrest and gs.politics.unrest > 60 then
        overlay = "war"
    elseif gs.perils and gs.perils.active and #gs.perils.active > 0 then
        overlay = "plague"
    elseif gs.markets then
        for _, market in pairs(gs.markets) do
            if market.prices and market.prices.food and market.prices.food > 15 then
                overlay = "famine"
                break
            end
        end
    end
    if not overlay and gs.resources and gs.resources.gold and gs.resources.gold > 500 then
        overlay = "prosperity"
    end

    if overlay and OVERLAY_TEXT[overlay] then
        local extra = RNG.pick(OVERLAY_TEXT[overlay])
        if extra then
            text = text .. " " .. extra:gsub("{region}", region_name or "the realm")
        end
    end

    return {
        text = text,
        display_hint = "log",
        priority = 25,
        tags = {"flavor", "seasonal"},
    }
end

--- Generate year-end summary.
function Flavor.get_year_summary(gs, region_name)
    local year = gs.clock and gs.clock.year or 0
    local lineage = gs.lineage_name or "the bloodline"

    local pool = {
        string.format("Year %d draws to a close. %s endures.", year, lineage),
        string.format("Another year passes for %s. The wheel turns.", lineage),
        string.format("Year %d is consigned to history. The ledgers are closed, the stories told.", year),
    }

    return {
        text = RNG.pick(pool),
        display_hint = "panel",
        priority = 50,
        tags = {"flavor", "summary"},
    }
end

--- Generate generational summary.
function Flavor.get_generational_summary(gs)
    local gen = gs.clock and gs.clock.generation or 0
    local lineage = gs.lineage_name or "the bloodline"

    local pool = {
        string.format("A generation has passed. The world %s knew is not the world their children will inherit.", lineage),
        string.format("The torch passes. Generation %d begins. The old ways fade; new ones take root.", gen),
        string.format("Twenty-five years gone. The elders who remember the old days grow fewer. A new era dawns for %s.", lineage),
    }

    return {
        text = RNG.pick(pool),
        display_hint = "fullscreen",
        priority = 85,
        tags = {"flavor", "generation"},
    }
end

--- Generate festival/religious flavor.
function Flavor.get_festival(month, gs)
    local month_name = MONTH_NAMES[month] or "this month"

    -- Query religion data would be via event bus at the caller level
    -- Here we just provide generic festival text
    local pool = {
        "The faithful gather for the rites of " .. month_name .. ", filling the temples with incense and prayer.",
        "A festival marks the turn of " .. month_name .. ". For a moment, the world's troubles are forgotten.",
        "The people celebrate the customs of " .. month_name .. ". Old songs fill the evening air.",
    }

    -- Only fire occasionally
    if not RNG.chance(0.1) then return nil end

    return {
        text = RNG.pick(pool),
        display_hint = "log",
        priority = 20,
        tags = {"flavor", "festival"},
    }
end

return Flavor
