-- dredwork Narrative — Night Passage
-- What happened while you slept. Rumors that spread. Decisions the world made.
-- The inner voice reflecting on the day. Bridges yesterday and tomorrow.

local RNG = require("dredwork_core.rng")
local MoodLib = require("dredwork_agency.mood")

local NightPassage = {}

--- Generate a night passage for the focal entity.
---@param entity table the focal entity
---@param gs table game_state
---@param day_actions table what the player did today
---@return table array of text lines for the passage
function NightPassage.generate(entity, gs, day_actions)
    if not entity or not entity.alive then return {} end

    local lines = {}
    local mood = MoodLib.calculate(entity)
    local needs = entity.components.needs

    -- TRANSITION LINE
    local transitions = {
        "Night falls. The world doesn't stop, but you do.",
        "Darkness. The fire burns low. The day replays behind your eyelids.",
        "You lie down. Sleep doesn't come immediately. It never does anymore.",
        "The sounds of the settlement fade. One by one, the lights go out.",
    }
    table.insert(lines, RNG.pick(transitions))

    -- REFLECTION on what you did today (if anything)
    if day_actions and #day_actions > 0 then
        local reflections = {
            "You think about what you did today. Whether it mattered. Whether anyone noticed.",
            "The day's choices replay. You wonder if you'd make them again.",
            "Today happened. You're not sure what it meant yet. Maybe tomorrow will clarify.",
        }
        table.insert(lines, RNG.pick(reflections))
    else
        table.insert(lines, "You did nothing today. The thought is uncomfortable.")
    end

    -- MOOD-COLORED night thought
    local night_thoughts = {
        desperate = "Sleep comes in fragments. Every noise is a threat. Every silence is worse.",
        grieving = "You dream of someone who isn't there anymore. Wake up reaching.",
        anxious = "Your mind races. Lists of dangers. Plans that dissolve on inspection. The dark amplifies everything.",
        bitter = "You catalogue the wrongs. The faces. The betrayals. The list grows longer than sleep.",
        restless = "You toss. Turn. The bed is wrong. The room is wrong. Everything is wrong except the itch to move.",
        calm = "Sleep comes. Deep and dark. The kind that heals.",
        content = "You fall asleep with something close to peace. It's fragile. You hold it gently.",
        determined = "Tomorrow. That's what matters. You plan it in the dark. Step by step.",
        hopeful = "For the first time in a while, you're looking forward to waking up.",
        triumphant = "You fall asleep with a smile. Whatever happens next, today was yours.",
    }
    table.insert(lines, night_thoughts[mood] or night_thoughts.calm)

    -- WORLD OVERNIGHT (what the simulation did while you slept)
    local world_lines = {}

    -- Rumors that circulated
    if gs.rumor_network and gs.rumor_network.rumors then
        local hot_rumors = {}
        for _, r in pairs(gs.rumor_network.rumors) do
            if not r.dead and (r.heat or 0) > 50 then table.insert(hot_rumors, r) end
        end
        if #hot_rumors > 0 and RNG.chance(0.4) then
            local r = RNG.pick(hot_rumors)
            table.insert(world_lines, "In the night, a rumor travels: \"" .. (r.text or "...") .. "\"")
        end
    end

    -- Rival activity
    if gs.rivals and gs.rivals.houses then
        for _, house in ipairs(gs.rivals.houses) do
            if house.heir and house.heir.attitude == "hostile" and RNG.chance(0.15) then
                table.insert(world_lines, "Somewhere beyond the walls, " .. house.name .. " makes plans you can't see.")
                break
            end
        end
    end

    -- Suspicion (if claim is active)
    if gs.claim and gs.claim.suspicion > 30 and RNG.chance(0.3) then
        if gs.claim.suspicion > 60 then
            table.insert(world_lines, "In the ruling house, someone is looking at a list. Your description might be on it.")
        else
            table.insert(world_lines, "Questions are being asked. About strangers. About blood. You feel it like a draft under the door.")
        end
    end

    -- Pick at most 1 world line (don't overwhelm)
    if #world_lines > 0 then
        table.insert(lines, RNG.pick(world_lines))
    end

    -- DAWN PREVIEW
    local dawn_lines = {
        "Then dawn. Another day. Another set of choices you can't take back.",
        "Light seeps in. The ceiling reappears. The world demands you again.",
        "Morning. Your body moves before your mind decides to. Habit keeps you alive.",
        "Dawn arrives like it always does. Indifferent. Beautiful. Relentless.",
    }
    table.insert(lines, RNG.pick(dawn_lines))

    return lines
end

return NightPassage
