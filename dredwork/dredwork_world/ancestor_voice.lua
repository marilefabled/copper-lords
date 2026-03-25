-- ancestor_voice.lua
-- "The Ancestor Speaks" — rare first-person moments where the collective
-- ancestral memory addresses the current heir. Limited to 3-5 per run
-- so each utterance feels sacred. Pure Lua, no Solar2D dependencies.

local rng = require("dredwork_core.rng")

local AncestorVoice = {}

local MAX_SPEAKS = 5
local _speak_count = 0
local _last_speak_gen = 0
local MIN_GAP = 5 -- minimum generations between speaks

-- Trigger categories with first-person lines.
-- Voice: intimate, weary, ancient. Gene Wolfe addressing the reader.
local VOICE_LINES = {
    -- When heir resists your council action (personality autonomy)
    heir_resists = {
        "We have guided this blood for {gen_count} generations. And still they fight us.",
        "Let them rebel. The stubborn ones last longer.",
        "We were like this once. Before we learned.",
    },
    -- Dynasty near collapse (1-2 heirs, low resources)
    near_collapse = {
        "Not yet. We are not finished yet.",
        "We have been here before. The granaries empty, the heir afraid. We endured.",
        "The weight is heavy now. But it has been heavier.",
        "Hold. Just hold.",
    },
    -- First grandchild (generation 2+)
    first_grandchild = {
        "The line continues. The weight passes to smaller hands.",
        "Another one. We feel the blood stretch thinner.",
        "This one has {past_heir}'s eyes. We remember those eyes.",
    },
    -- Heir achieves something exceptional (legend earned)
    legend_earned = {
        "Yes. This is why we endure.",
        "We have waited {gen_count} generations for this.",
        "Remember this one. The blood will need to remember.",
    },
    -- Ascending momentum streak (3+ generations of improvement)
    ascending_blood = {
        "The blood strengthens. We feel it in our bones — all of our bones.",
        "Three generations ascending. The old ones are pleased.",
        "We built this. Generation by generation. Do not let it fall.",
    },
    -- Heir death / near-miss (surviving a death check)
    close_call = {
        "We almost lost them. The thread is thin.",
        "Too close. We cannot afford to be careless with this one.",
        "The blood nearly spilled. Steady now.",
    },
    -- New era dawns
    era_shift = {
        "The world changes. We have seen this before.",
        "A new age. The old rules will not save them now.",
        "We remember when the last age turned. Few survived.",
    },
    -- Apotheosis within reach
    apotheosis_near = {
        "We can feel it. The boundary thins.",
        "Generations of sacrifice. All for this moment.",
        "The weight lifts. After all this time, the weight lifts.",
    },
}

--- Reset state for a new run.
function AncestorVoice.reset()
    _speak_count = 0
    _last_speak_gen = 0
end

--- Attempt to trigger an ancestor voice line.
--- Returns nil most of the time. Only fires at sacred moments.
---@param trigger string one of the VOICE_LINES keys
---@param context table { generation, heir_name, past_heir, gen_count, lineage_name }
---@return string|nil voice line or nil
function AncestorVoice.speak(trigger, context)
    if _speak_count >= MAX_SPEAKS then return nil end

    local generation = context and context.generation or 1
    if generation - _last_speak_gen < MIN_GAP then return nil end

    local pool = VOICE_LINES[trigger]
    if not pool or #pool == 0 then return nil end

    -- Even when conditions match, only 50% chance (keeps it rare)
    if not rng.chance(0.50) then return nil end

    local template = pool[rng.range(1, #pool)]

    -- Substitute variables
    local vars = {
        gen_count = tostring(generation),
        heir_name = context and context.heir_name or "the heir",
        past_heir = context and context.past_heir or "an ancestor",
        lineage = context and context.lineage_name or "the bloodline",
    }

    local text = template:gsub("{([%w_]+)}", function(key)
        return vars[key] or ("{" .. key .. "}")
    end)

    _speak_count = _speak_count + 1
    _last_speak_gen = generation

    return text
end

--- Get how many speaks remain.
---@return number
function AncestorVoice.remaining()
    return MAX_SPEAKS - _speak_count
end

return AncestorVoice
