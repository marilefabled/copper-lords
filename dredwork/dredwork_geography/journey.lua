-- dredwork Geography — Journey System
-- Travel between regions is a multi-day experience, not a teleport.
-- Each day on the road presents an event, a choice, or a quiet moment.
-- The journey surfaces modules that don't get seen during city life:
-- Animals (wildlife encounters), Peril (weather/disease), Crime (bandits),
-- Religion (roadside shrines), Strife (refugees), Economy (merchants).
--
-- "The road teaches you things the city never will."

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Journey = {}

--- Start a journey between two regions.
---@param from_id string source region
---@param to_id string destination region
---@param distance number days of travel
---@param focal table focal entity
---@param gs table game_state
---@return table journey state
function Journey.start(from_id, to_id, distance, focal, gs)
    local pw = focal.components.personal_wealth
    local gold = pw and pw.gold or 0

    -- Supply cost: 2 gold per travel day
    local supply_cost = distance * 2

    return {
        from_id = from_id,
        to_id = to_id,
        from_label = gs.world_map.regions[from_id] and gs.world_map.regions[from_id].label or from_id,
        to_label = gs.world_map.regions[to_id] and gs.world_map.regions[to_id].label or to_id,
        distance = distance,
        day = 0,                    -- current travel day (0 = departure)
        total_days = distance,
        supplies = math.min(gold, supply_cost),
        supply_cost = supply_cost,
        health = 100,               -- 0 = you arrive sick/wounded
        morale = 50,                -- affects arrival state
        events = {},                -- log of journey events
        current_event = nil,        -- active event awaiting response
        companion = nil,            -- pet traveling with you
        finished = false,
        abandoned = false,
        -- Biome of the route (use destination biome for flavor)
        route_biome = gs.world_map.regions[to_id] and gs.world_map.regions[to_id].biome or "temperate",
    }
end

--- Get the cost to travel (for preview before committing).
function Journey.get_cost(distance)
    return distance * 2
end

--- Advance one day on the journey. Returns an event or nil (quiet day).
function Journey.advance_day(journey, gs, focal)
    journey.day = journey.day + 1

    -- Consume supplies
    if journey.supplies > 0 then
        journey.supplies = journey.supplies - 1
    else
        -- No supplies: health and morale drain
        journey.health = Math.clamp(journey.health - 8, 0, 100)
        journey.morale = Math.clamp(journey.morale - 10, 0, 100)
    end

    -- Natural fatigue
    journey.health = Math.clamp(journey.health - 2, 0, 100)

    -- Check if arrived
    if journey.day >= journey.total_days then
        journey.finished = true
        return Journey._arrival_event(journey)
    end

    -- Generate a travel event (70% chance per day, guaranteed day 1)
    if journey.day == 1 or RNG.chance(0.70) then
        local event = Journey._generate_event(journey, gs, focal)
        journey.current_event = event
        return event
    end

    -- Quiet day on the road
    local quiet = Journey._quiet_moment(journey)
    table.insert(journey.events, { day = journey.day, type = "quiet", text = quiet.text })
    return quiet
end

--- Respond to the current event.
function Journey.respond(journey, option_id)
    local event = journey.current_event
    if not event or not event.options then return nil end

    for _, opt in ipairs(event.options) do
        if opt.id == option_id then
            -- Apply consequences
            if opt.health then journey.health = Math.clamp(journey.health + opt.health, 0, 100) end
            if opt.morale then journey.morale = Math.clamp(journey.morale + opt.morale, 0, 100) end
            if opt.supplies then journey.supplies = math.max(0, journey.supplies + opt.supplies) end
            if opt.gold_delta then
                -- Gold changes applied on arrival
                opt._applied = true
            end

            table.insert(journey.events, {
                day = journey.day,
                type = event.category or "event",
                text = opt.result_text or "You make your choice.",
                option = option_id,
            })

            journey.current_event = nil
            return opt
        end
    end
    return nil
end

--- Is the journey waiting for player input?
function Journey.needs_input(journey)
    return journey.current_event ~= nil and journey.current_event.options ~= nil
end

--- Get progress as fraction 0-1.
function Journey.get_progress(journey)
    return journey.day / math.max(1, journey.total_days)
end

--------------------------------------------------------------------------------
-- EVENT GENERATION
-- Each event surfaces a different module. Signal affinity gates bonus options.
--------------------------------------------------------------------------------

function Journey._generate_event(journey, gs, focal)
    local biome = journey.route_biome
    local day = journey.day
    local aff = focal and focal.components.signal_affinity or {}

    -- Weight events by biome and journey phase
    local pool = {}

    -- ANIMALS: wildlife encounters (all biomes)
    table.insert(pool, Journey._event_wildlife(biome, aff))

    -- PERIL: weather and disease (harsh biomes more likely)
    if biome == "tundra" or biome == "swamp" or biome == "desert" or biome == "volcanic" or RNG.chance(0.4) then
        table.insert(pool, Journey._event_weather(biome))
    end

    -- CRIME: bandits (mid-journey, more likely on trade routes)
    if day > 1 and day < journey.total_days then
        table.insert(pool, Journey._event_bandits(aff))
    end

    -- RELIGION: roadside shrine
    if RNG.chance(0.3) then
        table.insert(pool, Journey._event_shrine(biome))
    end

    -- ECONOMY: traveling merchant
    if RNG.chance(0.35) then
        table.insert(pool, Journey._event_merchant(journey))
    end

    -- STRIFE: refugees / displaced people
    if gs.politics and (gs.politics.unrest or 0) > 30 then
        table.insert(pool, Journey._event_refugees(gs))
    end

    -- CLAIM: someone on the road recognizes you
    if gs.claim and gs.claim.type and gs.claim.suspicion > 20 and RNG.chance(0.2) then
        table.insert(pool, Journey._event_recognized(gs))
    end

    -- NATURE: the land itself
    table.insert(pool, Journey._event_landscape(biome))

    return RNG.pick(pool)
end

--------------------------------------------------------------------------------
-- EVENT TEMPLATES
--------------------------------------------------------------------------------

function Journey._event_wildlife(biome, aff)
    local animals = {
        temperate = { "wolves", "deer", "hawks" },
        tundra = { "bears", "arctic foxes", "elk" },
        tropical = { "serpents", "monkeys", "bright birds" },
        desert = { "scorpions", "sand cats", "vultures" },
        swamp = { "crocodiles", "herons", "mosquito swarms" },
        mountain = { "mountain goats", "eagles", "cave bats" },
        steppe = { "wild horses", "prairie dogs", "hawks" },
    }
    local creature = RNG.pick(animals[biome] or animals.temperate)
    local nature_aff = (aff.nature or 0) >= 35

    return {
        category = "wildlife",
        title = "Movement in the Brush",
        text = "You hear rustling. Then you see them — " .. creature .. ". Close enough to matter.",
        options = {
            { id = "observe", label = "Watch quietly",
              result_text = "You hold still. They move through their world, unaware of yours. There's a lesson in that.",
              morale = 5 },
            { id = "hunt", label = "Hunt for supplies",
              result_text = "The hunt is brief. Messy. But your pack is heavier now. That matters on the road.",
              supplies = 2, morale = -3 },
            nature_aff and { id = "track", label = "Read their trail — something spooked them",
              result_text = "The tracks tell a story. Something larger passed through here recently. You adjust your route. The detour costs an hour but might save your life.",
              morale = 8, health = 3 } or nil,
        },
    }
end

function Journey._event_weather(biome)
    local weather = {
        tundra = { name = "blizzard", text = "The wind hits like a wall. White. Everywhere. You can't see your hand. You hunker down and pray it passes." },
        desert = { name = "sandstorm", text = "The horizon disappears. Sand strips exposed skin. You bury your face in cloth and wait." },
        swamp = { name = "fever fog", text = "The mist is warm. Wrong-warm. By afternoon your head pounds and the edges of things blur." },
        tropical = { name = "monsoon", text = "Rain like you've never seen. The path dissolves. You're wading now, not walking." },
        volcanic = { name = "ash fall", text = "The sky turns grey. Fine ash drifts down like snow. Your lungs burn." },
        temperate = { name = "thunderstorm", text = "Lightning cracks the sky. The rain is violent, personal. The road turns to mud." },
        mountain = { name = "rockslide", text = "A rumble. Then the mountain moves. Rocks cascade across the path ahead." },
    }
    local w = weather[biome] or weather.temperate

    return {
        category = "weather",
        title = "The Sky Changes",
        text = w.text,
        options = {
            { id = "push_through", label = "Push through. You can't afford to stop.",
              result_text = "Every step costs twice what it should. But you keep moving. The " .. w.name .. " doesn't care about your schedule. Neither do you.",
              health = -12, morale = -5 },
            { id = "shelter", label = "Find shelter. Wait it out.",
              result_text = "You lose half a day. Maybe more. But you're alive, dry, and your body will thank you tomorrow.",
              morale = 3 },
        },
    }
end

function Journey._event_bandits(aff)
    local crime_aff = (aff.crime or 0) >= 35
    return {
        category = "crime",
        title = "Figures on the Road",
        text = "Three figures step out of the treeline. They don't draw weapons — yet. But their positioning says everything. This is a toll road. Their toll.",
        options = {
            { id = "pay_toll", label = "Pay them. It's not worth dying over.",
              result_text = "'Smart.' They take your coin and vanish. The road opens up again. You wonder how many others weren't smart.",
              supplies = -2, morale = -5 },
            { id = "fight", label = "Draw your blade. No.",
              result_text = "The first one hesitates. That's enough. You press the advantage. They scatter. Your hands shake for an hour afterward, but the coin stays.",
              health = -8, morale = 10 },
            { id = "bluff", label = "Walk toward them. Slowly. Hands visible. 'I have nothing worth taking.'",
              result_text = "They study you. One looks to the leader. The leader shrugs. 'Move on.' Maybe they believed you. Maybe you weren't worth the effort. Either way — you pass.",
              morale = 5 },
            crime_aff and { id = "recognize", label = "You know that sigil. They're guild.",
              result_text = "You flash the sign. Subtle. The leader's eyes widen. 'Apologies. We didn't know.' They step aside. Being known has its advantages — on the road, at least.",
              morale = 8 } or nil,
        },
    }
end

function Journey._event_shrine(biome)
    return {
        category = "religion",
        title = "A Shrine by the Road",
        text = "Stones stacked carefully. Offerings — flowers, coins, a child's shoe. Someone tends this place. A roadside shrine, older than the road itself.",
        options = {
            { id = "pray", label = "Kneel. Pray.",
              result_text = "The words come from somewhere deeper than memory. When you rise, something has shifted. Not the world. You.",
              morale = 12, health = 3 },
            { id = "leave_offering", label = "Leave something of yours.",
              result_text = "A coin. It's all you can spare. But the gesture matters — to you, if not to the gods.",
              supplies = -1, morale = 8 },
            { id = "pass", label = "Keep walking.",
              result_text = "You glance at it as you pass. The eyes of the carved figure seem to follow you. Probably the light.",
              morale = -2 },
        },
    }
end

function Journey._event_merchant(journey)
    return {
        category = "economy",
        title = "A Merchant's Cart",
        text = "Wheels creak. A merchant traveling the opposite direction, cart heavy with goods. They pull over when they see you. 'Headed to " .. journey.to_label .. "? Long road. Need supplies?'",
        options = {
            { id = "buy", label = "Buy supplies. You'll need them.",
              result_text = "The prices are highway robbery. But out here, choice is a luxury you don't have. Your pack is heavier. Your purse is lighter.",
              supplies = 3, gold_delta = -8 },
            { id = "trade_info", label = "Trade information instead of coin.",
              result_text = "You swap news. The merchant knows the road ahead — washed-out bridge, patrol schedules, a town with cheap lodging. Worth more than supplies.",
              morale = 5 },
            { id = "decline", label = "Not today.",
              result_text = "'Your loss.' The cart rumbles on. You watch it shrink into the distance and hope you don't regret this.",
            },
        },
    }
end

function Journey._event_refugees(gs)
    return {
        category = "strife",
        title = "People on the Move",
        text = "A line of people stretches along the road. Families. Children. Everything they own on their backs. They don't look at you. They've stopped looking at anyone.",
        options = {
            { id = "share", label = "Share what you can.",
              result_text = "You give food. Water. Not enough — never enough. A woman grips your hand. Her eyes say what her voice can't. You walk on, lighter in every way.",
              supplies = -2, morale = 10 },
            { id = "ask", label = "Ask where they're coming from.",
              result_text = "'From the burning.' That's all they'll say. The burning. You don't ask what burned. The answer is in their eyes.",
              morale = -3 },
            { id = "pass_refugees", label = "Lower your head. Keep moving.",
              result_text = "You walk past. Past the children. Past the old man carrying a younger man. Past the dog that follows no one. The road goes on.",
              morale = -5 },
        },
    }
end

function Journey._event_recognized(gs)
    return {
        category = "claim",
        title = "A Second Look",
        text = "A traveler passes you. Stops. Turns back. They're staring. Not at your pack or your blade — at your face. Your jaw. Your eyes. They're seeing someone you look like.",
        options = {
            { id = "keep_walking", label = "Don't slow down. Don't run. Walk.",
              result_text = "You feel their gaze on your back for a hundred paces. Then it fades. Maybe they convinced themselves otherwise. Maybe.",
            },
            { id = "confront_traveler", label = "Turn around. 'Something on your mind?'",
              result_text = "'No. Sorry. You remind me of... no.' They walk away quickly. Too quickly. They'll talk about you at the next inn. You're sure of it.",
              morale = -5 },
        },
    }
end

function Journey._event_landscape(biome)
    local landscapes = {
        temperate = { "You crest a hill. The valley below is golden with late wheat. A river cuts through it like a vein. Beautiful. And completely indifferent to you.",
                      "An oak tree, ancient. Its roots have cracked the road. You rest in its shade and feel small in a way that's almost comforting." },
        tundra =    { "The horizon is a line. Nothing above, nothing below. Just the white and the wind. You've never felt so exposed.",
                      "Ice formations catch the light. For a moment, the frozen world is cathedral-beautiful. Then the wind reminds you where you are." },
        tropical =  { "The canopy closes overhead. Green light. Bird calls that sound like questions. The air is thick enough to chew.",
                      "A waterfall. Hidden by the jungle until you're right on top of it. The mist on your face is the first clean thing you've felt in days." },
        desert =    { "Sand dunes. The wind sculpts them constantly. By tomorrow, this landscape won't exist. It'll be something new. There's a metaphor there.",
                      "A night sky so dense with stars it looks artificial. The desert takes everything but gives you this." },
        mountain =  { "A pass between two peaks. The world spreads below you in every direction. You can see three regions from here. Everything feels possible.",
                      "Thin air. Your lungs work harder. But the silence up here — it's the loudest thing you've ever heard." },
    }
    local texts = landscapes[biome] or landscapes.temperate

    return {
        category = "landscape",
        title = "The Road",
        text = RNG.pick(texts),
        -- No options — just a moment. Click to continue.
    }
end

function Journey._quiet_moment(journey)
    local texts = {
        "The road stretches. Your feet know the rhythm now. Step, step, step. The world narrows to the next horizon.",
        "Silence. The good kind. No demands. No secrets. Just the road and whatever you left behind.",
        "You count your supplies. Do the math. It'll be tight. It always is.",
        "A bird follows you for an hour. You start talking to it. It doesn't judge.",
        "Dusk. You make camp. The fire is small but it's yours. Tomorrow, more road.",
        "Rain. Light, persistent. It doesn't stop you. Nothing stops you anymore.",
    }
    return {
        category = "quiet",
        title = nil,
        text = RNG.pick(texts),
    }
end

function Journey._arrival_event(journey)
    local health_word
    if journey.health > 80 then health_word = "strong"
    elseif journey.health > 50 then health_word = "tired but whole"
    elseif journey.health > 25 then health_word = "battered"
    else health_word = "barely standing" end

    return {
        category = "arrival",
        title = journey.to_label,
        text = "The road ends. " .. journey.to_label .. " rises before you — walls, smoke, life. You're " .. health_word .. ". "
            .. journey.day .. " days on the road. "
            .. (journey.supplies > 0 and "Supplies held." or "Supplies ran out.")
            .. " A new place. A new start. Or a new set of problems.",
    }
end

return Journey
