-- dredwork Locations — Atmospheric Descriptions
-- Each location has descriptions that shift with time of day, season, and world state.
-- You don't just arrive at "The Market." You arrive at the market at dawn during a famine
-- and the stalls are thin and the vendors won't meet your eyes.

local RNG = require("dredwork_core.rng")

local Descriptions = {}

--- Time-of-day slots mapped to atmosphere.
local TIME_MOODS = {
    dawn      = "early",
    morning   = "busy",
    midday    = "peak",
    afternoon = "winding",
    evening   = "settling",
    night     = "dark",
}

--- Base descriptions by location type × time mood.
local BASE = {
    home = {
        early = {
            "Grey light through the window. The room is cold. Your breath hangs.",
            "Dawn. The ceiling is the first thing you see. Same cracks. Same silence.",
        },
        busy = {
            "Daylight fills the room. The sounds of the world outside filter through the walls.",
            "Morning light. Dust motes in the air. The hearth has gone cold.",
        },
        peak = {
            "Midday. The room is warm. Too warm. The walls feel closer.",
            "The sun is high. Through the window, you can hear the market. In here, just your breathing.",
        },
        settling = {
            "The light is amber now. Long shadows stretch across the floor.",
            "Afternoon. The room holds the day's warmth like a memory.",
        },
        dark = {
            "Candlelight flickers. The walls breathe shadows. Outside, the world sleeps. Or pretends to.",
            "Night. The fire pops. Your shadow dances on the stone. You are alone with your thoughts.",
        },
    },
    court = {
        early = {
            "The great hall is nearly empty. A servant sweeps. The throne catches the first light.",
            "Dawn at court. The seats are cold. The real conversations happen before the hall fills.",
        },
        busy = {
            "The court buzzes. Voices overlap. Everyone watching everyone. Smiles that mean nothing.",
            "Morning session. The powerful stand close to power. The rest find walls to lean against.",
        },
        peak = {
            "The hall is full. The air thick with perfume and ambition. Every word is measured.",
            "Midday court. Petitions. Grievances. The machinery of rule, grinding forward.",
        },
        dark = {
            "The court is closed. The hall echoes. Only the guards remain, and whatever hides in the corners.",
            "Night. The throne is empty. But the shadows around it are not.",
        },
    },
    market = {
        early = {
            "The vendors are setting up. Carts creak. The smell of bread from somewhere you can't see.",
            "Dawn market. The serious traders are here. The ones who know what things are really worth.",
        },
        busy = {
            "The market throbs. Bodies press. Someone shouts a price. Someone shouts it back lower.",
            "Morning trade. Colors and noise. A child weaves between legs. A merchant watches you watch them.",
        },
        peak = {
            "Peak hours. Every stall occupied. The air tastes of dust and spice. Money changes hands like handshakes.",
        },
        settling = {
            "The crowd thins. Vendors count their take. The day's unsold produce begins to wilt.",
            "Late market. The desperate sellers drop their prices. The desperate buyers appear.",
        },
        dark = {
            "The market is closed. Shadows between empty stalls. Something skitters in the dark.",
            "Night market. The stalls are shuttered. But some business only happens after hours.",
        },
    },
    tavern = {
        early = {
            "The tavern is quiet. Last night's candles are puddles of wax. Someone is sleeping in the corner.",
        },
        busy = {
            "Voices and smoke. The morning drinkers are a different breed. Quieter. Sadder.",
        },
        settling = {
            "The evening crowd arrives. Louder now. The ale flows. Tongues loosen.",
            "Dusk at the tavern. This is when the real conversations begin. And the real lies.",
        },
        dark = {
            "The tavern is alive at night. Laughter that could be genuine or could be a performance. You can't tell.",
            "Night. The corner tables are full. Conversations that stop when you walk past.",
            "Smoke and stories. Someone is lying about something. Everyone knows. Nobody cares.",
        },
    },
    barracks = {
        early = {
            "Dawn drill. The clang of practice swords. Breath steaming in the cold air.",
        },
        busy = {
            "The barracks hum with purpose. Soldiers clean, sharpen, mend. The rhythm of preparation.",
        },
        dark = {
            "Night watch. The barracks are quiet except for snoring and the occasional patrol.",
        },
    },
    temple = {
        early = {
            "Dawn prayer. The faithful kneel in rows. Incense rises like questions without answers.",
            "First light through colored glass. The temple breathes.",
        },
        busy = {
            "The temple is busy with devotion. Whispered prayers and the sound of knees on stone.",
        },
        settling = {
            "Evening rites. Fewer faithful. The ones who come at this hour come because they need to.",
        },
        dark = {
            "The temple at night. Empty pews. The eternal flame. Whatever lives here, it's awake.",
        },
    },
    wilds = {
        early = {
            "Dawn in the wilds. Mist on the ground. Birdsong from somewhere deep. The world before people.",
            "The forest wakes. Dew on every surface. Your footsteps are loud here.",
        },
        busy = {
            "Daylight filters through the canopy. Insects hum. Something large moves in the undergrowth.",
        },
        dark = {
            "Night in the wilds. Every sound is amplified. Your fire is the only light, and it attracts attention.",
            "Darkness between the trees. The stars are sharp here, far from the smoke of the city.",
        },
    },
    gate = {
        early = {
            "The gate opens at dawn. Travelers wait in a line that formed before you woke.",
        },
        busy = {
            "The gate is busy. Carts, merchants, soldiers, refugees. Everyone moving. Everyone watched.",
        },
        dark = {
            "The gate is closed for the night. Guards on the wall. The road beyond is a dark line.",
        },
    },
    road = {
        early = { "The road is empty and cold. Your shadow stretches ahead of you." },
        busy = { "Travelers pass. Nods exchanged. Nobody asks where you're going." },
        dark = { "Night road. The moon is your lantern. Every sound could be anything." },
    },
    dungeon = {
        early = { "There is no dawn here. Just the slow realization that you're awake again." },
        dark = { "The dungeon doesn't know time. It's always dark. It's always cold. It's always listening." },
    },
}

--- World-state overlays that modify descriptions.
local OVERLAYS = {
    famine = {
        market = {
            "The stalls are thin. What's left is priced for the desperate. Children watch from the edges with hollow eyes.",
            "Half the vendors didn't come today. The ones who did look like they wish they hadn't.",
        },
        home = {
            "Your stomach reminds you of what you don't have.",
        },
    },
    plague = {
        market = {
            "People keep distance. Cloth over faces. The vendors handle coins with gloves.",
        },
        temple = {
            "The faithful are desperate today. More prayers. Louder. As if volume matters to the divine.",
        },
        home = {
            "You check your hands. Your forehead. Looking for signs that aren't there. Yet.",
        },
    },
    unrest = {
        court = {
            "The tension is visible. Guards doubled at the doors. Conversations die when you approach.",
        },
        market = {
            "A patrol passes through. The vendors go quiet. When they leave, the whispers resume.",
        },
        gate = {
            "Extra guards at the gate. They're checking faces now. Not just cargo.",
        },
    },
    war = {
        barracks = {
            "The barracks are buzzing. Real purpose now, not drills. Something is coming.",
        },
        gate = {
            "The gate is fortified. Sandbags and spears. The road beyond looks like a threat.",
        },
    },
    prosperity = {
        market = {
            "The market is alive with abundance. Colors you haven't seen in months. Laughter that isn't forced.",
        },
        tavern = {
            "The ale flows freely. Someone is buying rounds. The mood is dangerously good.",
        },
    },
    corruption = {
        market = {
            "The stalls look the same. But the real business happens in the gaps between them.",
            "A vendor glances left, right, then slides something under the counter. Nobody reacts. This is normal now.",
        },
        tavern = {
            "The back table is busy tonight. Faces you don't recognize. Money you don't want to ask about.",
            "The tavern used to feel warm. Now it feels careful. Everyone watching everyone.",
        },
        court = {
            "The court conducts its business. But the real decisions were made last night, in rooms without windows.",
        },
        home = {
            "You check the lock twice. You didn't use to do that.",
        },
    },
    terror = {
        market = {
            "The market is orderly. Perfectly orderly. Nobody lingers. Nobody raises their voice. The peace is immaculate and lifeless.",
        },
        court = {
            "The court is quiet. Obedient. The magistrate's shadow is long today.",
        },
        tavern = {
            "The tavern is half-empty. Those who are here drink in silence. The jokes died weeks ago.",
        },
    },
}

--- Generate a description for a location.
---@param location_type string
---@param time_slot_id string (dawn, morning, midday, afternoon, evening, night)
---@param gs table game_state (for world-state overlays)
---@return string
function Descriptions.generate(location_type, time_slot_id, gs)
    local time_mood = TIME_MOODS[time_slot_id] or "busy"

    -- Get base description
    local loc_pool = BASE[location_type]
    if not loc_pool then return "You are here." end

    local mood_pool = loc_pool[time_mood] or loc_pool.busy or loc_pool.dark
    if not mood_pool then
        -- Fallback: pick any available mood
        for _, pool in pairs(loc_pool) do
            if pool and #pool > 0 then mood_pool = pool; break end
        end
    end
    if not mood_pool or #mood_pool == 0 then return "You are here." end

    local text = RNG.pick(mood_pool)

    -- World-state overlay
    local world_mood = Descriptions._get_world_mood(gs)
    if world_mood and OVERLAYS[world_mood] and OVERLAYS[world_mood][location_type] then
        local overlay_pool = OVERLAYS[world_mood][location_type]
        if overlay_pool and #overlay_pool > 0 and RNG.chance(0.6) then
            text = text .. " " .. RNG.pick(overlay_pool)
        end
    end

    return text
end

--- Determine the dominant world mood.
function Descriptions._get_world_mood(gs)
    if gs.perils and gs.perils.active then
        for _, p in ipairs(gs.perils.active) do
            if p.category == "disease" then return "plague" end
        end
    end
    if gs.markets then
        for _, m in pairs(gs.markets) do
            if m.prices and m.prices.food and m.prices.food > 15 then return "famine" end
        end
    end
    if gs.politics and gs.politics.unrest and gs.politics.unrest > 60 then return "unrest" end
    if gs.empire and gs.empire.territories and #gs.empire.territories > 0 then return "war" end
    -- Corruption: the consequence of mercy (or neglect)
    if gs.underworld and (gs.underworld.global_corruption or 0) > 35 then return "corruption" end
    -- Terror: the consequence of cruelty (or control)
    if gs.justice and (gs.justice.terror_score or 0) > 40 then return "terror" end
    if gs.resources and gs.resources.gold and gs.resources.gold > 300 then return "prosperity" end
    return nil
end

return Descriptions
