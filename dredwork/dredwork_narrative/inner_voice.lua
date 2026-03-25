-- dredwork Narrative — Inner Voice
-- First-person thoughts for the focal character.
-- Not "The famine worsens" but "You watch the empty stalls and feel your stomach tighten."
-- Driven by mood + personality + memory + world state.

local RNG = require("dredwork_core.rng")
local MoodLib = require("dredwork_agency.mood")

local InnerVoice = {}

--- Thought pools by mood × world condition.
local THOUGHTS = {
    -- DESPERATE
    desperate = {
        famine  = { "There's nothing left. You count the grains in the jar. Not enough. Not nearly enough.",
                    "When did you last eat? You can't remember. That's a bad sign." },
        war     = { "They're coming. You can feel it. Every instinct screams: run.",
                    "You're going to die here. The thought arrives calmly, like an old friend." },
        default = { "One more day. Just one more day. That's all you ask.",
                    "The walls are closing in. You need a way out. Any way out." },
    },
    -- GRIEVING
    grieving = {
        default = { "You keep reaching for someone who isn't there anymore.",
                    "The world goes on. How dare it.",
                    "They would have known what to do. You don't." },
    },
    -- ANXIOUS
    anxious = {
        default = { "Something's wrong. You don't know what yet, but your hands won't stop shaking.",
                    "Every footstep behind you sounds deliberate. Measured. Following.",
                    "You check the door again. Still locked. Check again." },
    },
    -- BITTER
    bitter = {
        betrayal = { "They looked you in the eye and lied. You'll remember that.",
                     "Trust is a currency you can no longer afford." },
        default  = { "Everyone wants something. At least now you see it clearly.",
                     "Kindness is just manipulation with better packaging." },
    },
    -- RESTLESS
    restless = {
        default = { "This isn't enough. There has to be more than this.",
                    "You stare at the same four walls and imagine what lies beyond.",
                    "The itch to move, to DO something, to be anywhere but here." },
    },
    -- CALM
    calm = {
        default = { "A breath in. A breath out. The world can wait a moment.",
                    "You sit with yourself. It's not uncomfortable, for once.",
                    "The fire crackles. The light is warm. This is enough." },
    },
    -- CONTENT
    content = {
        default = { "It's not perfect. But it's yours. And that counts for something.",
                    "You look at what you've built and, for once, don't see what's missing.",
                    "A good day. You've learned not to take those for granted." },
    },
    -- DETERMINED
    determined = {
        default = { "You know what needs to be done. The question is no longer if, but when.",
                    "Focus. Every distraction is a luxury you can't afford.",
                    "One step at a time. Each one deliberate. Each one closer." },
    },
    -- HOPEFUL
    hopeful = {
        default = { "Maybe this is the turn. Maybe the worst is behind you.",
                    "Something in the air today. Promise, possibility. You almost trust it.",
                    "For the first time in a long while, you can see tomorrow." },
    },
    -- TRIUMPHANT
    triumphant = {
        default = { "You did this. Not luck. Not fate. You.",
                    "Let them look. Let them see what you've become.",
                    "The world bends for those who refuse to break." },
    },
}

--- Generate an inner thought for the focal entity.
---@param entity table focal entity
---@param gs table game_state
---@return table|nil { text, mood, tone }
function InnerVoice.generate(entity, gs)
    if not entity or not entity.alive then return nil end

    -- Probability gate: not every tick produces a thought
    if not RNG.chance(0.15) then return nil end

    local mood = MoodLib.calculate(entity)
    local tone = MoodLib.get_tone(mood)

    -- Determine world condition
    local condition = "default"
    if gs.markets then
        for _, market in pairs(gs.markets) do
            if market.prices and market.prices.food and market.prices.food > 12 then
                condition = "famine"; break
            end
        end
    end
    if gs.perils and gs.perils.active then
        for _, p in ipairs(gs.perils.active) do
            if p.category == "disease" then condition = "war"; break end  -- "war" covers any active threat
        end
    end
    if gs.politics and gs.politics.unrest and gs.politics.unrest > 60 then
        condition = "war"
    end

    -- Check for betrayal-specific bitterness
    if mood == "bitter" and entity.components.memory then
        if #(entity.components.memory.grudges or {}) > 0 then
            condition = "betrayal"
        end
    end

    -- Select from pool
    local mood_pool = THOUGHTS[mood] or THOUGHTS.calm
    local condition_pool = mood_pool[condition] or mood_pool.default or THOUGHTS.calm.default
    if not condition_pool or #condition_pool == 0 then
        condition_pool = THOUGHTS.calm.default
    end

    local text = RNG.pick(condition_pool)
    if not text then return nil end

    return {
        text = text,
        mood = mood,
        tone = tone,
        display_hint = "thought",  -- new display type: rendered differently from events
        priority = 55,
        tags = { "inner_voice", mood },
    }
end

return InnerVoice
