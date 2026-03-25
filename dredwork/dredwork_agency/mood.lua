-- dredwork Agency — Mood / Emotional State
-- Not a number. A state that colors everything.
-- Driven by recent memory events + need satisfaction + personality.
-- Mood affects available choices, NPC reactions, and narrative voice.

local Math = require("dredwork_core.math")

local Mood = {}

--- Mood states (ordered from worst to best).
Mood.STATES = {
    "desperate",   -- cornered, nothing to lose
    "grieving",    -- recent loss, withdrawn
    "anxious",     -- danger sensed, hypervigilant
    "bitter",      -- wronged, resentful
    "restless",    -- unfulfilled, seeking
    "calm",        -- neutral, steady
    "content",     -- needs met, comfortable
    "determined",  -- driven, focused
    "hopeful",     -- good signs, optimistic
    "triumphant",  -- recent victory, powerful
}

--- State effects: what each mood does.
Mood.EFFECTS = {
    desperate   = { boldness_mod = 20, caution_mod = -20, decision_tags = {"reckless_act"}, narrative_tone = "raw" },
    grieving    = { boldness_mod = -10, social_mod = -15, decision_tags = {"cautious_act"}, narrative_tone = "heavy" },
    anxious     = { observation_mod = 10, boldness_mod = -10, decision_tags = {"cautious_act"}, narrative_tone = "tense" },
    bitter      = { cruelty_mod = 10, loyalty_mod = -10, decision_tags = {"cruel_act"}, narrative_tone = "sharp" },
    restless    = { curiosity_mod = 10, patience_mod = -10, decision_tags = {"reckless_act"}, narrative_tone = "searching" },
    calm        = { narrative_tone = "steady" },
    content     = { social_mod = 5, loyalty_mod = 5, narrative_tone = "warm" },
    determined  = { boldness_mod = 10, focus_mod = 10, decision_tags = {"warfare"}, narrative_tone = "focused" },
    hopeful     = { social_mod = 10, boldness_mod = 5, narrative_tone = "light" },
    triumphant  = { boldness_mod = 15, pride_mod = 10, decision_tags = {"warfare"}, narrative_tone = "powerful" },
}

--- Calculate mood from entity state.
---@param entity table entity with components.memory, components.needs, components.personality
---@return string mood state name
function Mood.calculate(entity)
    if not entity then return "calm" end

    local score = 50  -- neutral baseline
    local needs = entity.components.needs
    local memory = entity.components.memory
    local personality = entity.components.personality or {}

    -- Needs drive mood heavily
    if needs then
        -- Low safety → anxious/desperate
        if (needs.safety or 50) < 20 then score = score - 25
        elseif (needs.safety or 50) < 35 then score = score - 10 end

        -- Low belonging → bitter/restless
        if (needs.belonging or 50) < 25 then score = score - 15 end

        -- High comfort + status → content/hopeful
        if (needs.comfort or 50) > 70 and (needs.status or 50) > 60 then score = score + 15 end

        -- Low everything → desperate
        local total_needs = (needs.safety or 50) + (needs.belonging or 50) + (needs.purpose or 50) + (needs.comfort or 50) + (needs.status or 50)
        if total_needs < 120 then score = score - 20 end
        if total_needs > 350 then score = score + 10 end
    end

    -- Memory: recent events shift mood
    if memory then
        -- Recent grudges → bitter
        if #(memory.grudges or {}) > 2 then score = score - 10 end

        -- Recent witnessed deaths → grieving
        for _, w in ipairs(memory.witnessed or {}) do
            if w.type == "death" or w.type == "heir_death" then
                score = score - 15
                break
            end
        end

        -- Recent debts (people owe you) → content
        if #(memory.debts or {}) > 1 then score = score + 5 end
    end

    -- Personality: volatile people swing harder
    local vol = personality.PER_VOL or 50
    if type(vol) == "table" then vol = vol.value or 50 end
    if vol > 65 then
        score = score + (score > 50 and 10 or -10)  -- amplify swings
    end

    -- Map score to state
    score = Math.clamp(score, 0, 100)

    if score < 10 then return "desperate"
    elseif score < 20 then return "grieving"
    elseif score < 30 then return "anxious"
    elseif score < 40 then return "bitter"
    elseif score < 50 then return "restless"
    elseif score < 60 then return "calm"
    elseif score < 70 then return "content"
    elseif score < 80 then return "determined"
    elseif score < 90 then return "hopeful"
    else return "triumphant" end
end

--- Get the effects of a mood state.
function Mood.get_effects(mood_state)
    return Mood.EFFECTS[mood_state] or Mood.EFFECTS.calm
end

--- Get the narrative tone for a mood.
function Mood.get_tone(mood_state)
    local effects = Mood.EFFECTS[mood_state]
    return effects and effects.narrative_tone or "steady"
end

return Mood
