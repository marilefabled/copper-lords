-- dredwork Encounters — Module Entry
-- Emergent daily micro-events generated from who's nearby, what's happening,
-- and what the character's relationships/secrets/needs produce.
-- "You pass Brennan in the corridor. He avoids your gaze."
-- That's not random — it's because his loyalty dropped and you hold a secret about him.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local MoodLib = require("dredwork_agency.mood")

local Encounters = {}
Encounters.__index = Encounters

function Encounters.init(engine)
    local self = setmetatable({}, Encounters)
    self.engine = engine

    engine.game_state.encounters = {
        today = nil,        -- current encounter (or nil)
        history = {},       -- recent encounters (last 10)
    }

    -- Daily: generate an encounter for the focal entity
    engine:on("NEW_DAY", function(clock)
        -- Only ~30% of days have encounters (not every day is eventful)
        if not RNG.chance(0.30) then
            self.engine.game_state.encounters.today = nil
            return
        end
        self:generate(self.engine.game_state, clock)
    end)

    return self
end

--------------------------------------------------------------------------------
-- Encounter Generation
--------------------------------------------------------------------------------

function Encounters:generate(gs, clock)
    local entities = self.engine:get_module("entities")
    if not entities then return end

    local focal = entities:get_focus()
    if not focal or not focal.alive then return end

    local day = clock and clock.total_days or 0
    local encounter = nil

    -- Gather context
    local rels = entities:get_relationships(focal.id)
    local nearby = {}
    local focal_loc = focal.components.location and focal.components.location.region_id
    if focal_loc then
        nearby = entities:find_at_location(focal_loc)
    end

    local mood = MoodLib.calculate(focal)
    local needs = focal.components.needs
    local memory = focal.components.memory
    local secrets = focal.components.secrets

    -- Encounter pool: each generator returns an encounter or nil
    local generators = {
        self._encounter_relationship,
        self._encounter_rumor,
        self._encounter_secret,
        self._encounter_need,
        self._encounter_mood,
        self._encounter_ambient,
    }

    -- Shuffle and try each generator until one produces something
    for _ = 1, #generators do
        local idx = RNG.range(1, #generators)
        encounter = generators[idx](self, focal, nearby, rels, gs, mood, day)
        if encounter then break end
    end

    if not encounter then
        encounter = self:_encounter_ambient(focal, nearby, rels, gs, mood, day)
    end

    if encounter then
        encounter.day = day
        encounter.mood = mood
        gs.encounters.today = encounter

        table.insert(gs.encounters.history, encounter)
        while #gs.encounters.history > 10 do
            table.remove(gs.encounters.history, 1)
        end

        -- Emit for narrative
        self.engine:emit("ENCOUNTER", encounter)
        self.engine:push_ui_event("ENCOUNTER", encounter)
    end
end

--------------------------------------------------------------------------------
-- Encounter Generators
--------------------------------------------------------------------------------

--- Relationship-driven: someone you know does something revealing.
function Encounters:_encounter_relationship(focal, nearby, rels, gs, mood, day)
    if #rels == 0 then return nil end
    local rel = RNG.pick(rels)
    local entities = self.engine:get_module("entities")
    local other_id = rel.a == focal.id and rel.b or rel.a
    local other = entities and entities:get(other_id)
    if not other or not other.alive then return nil end

    local strength = rel.strength or 50
    local name = other.name or "someone"

    if strength > 70 then
        return {
            type = "relationship",
            text = name .. " catches your eye across the room and nods. A small gesture, but it steadies you.",
            entity_id = other_id,
            effect = { comfort = 2 },
        }
    elseif strength < 30 then
        return {
            type = "relationship",
            text = "You pass " .. name .. " in the corridor. They avoid your gaze. The silence says everything.",
            entity_id = other_id,
            effect = { belonging = -1 },
        }
    elseif strength < 50 then
        return {
            type = "relationship",
            text = name .. " speaks to you with careful politeness. The warmth that was once there is gone.",
            entity_id = other_id,
            effect = {},
        }
    end
    return nil
end

--- Rumor-driven: you hear something.
function Encounters:_encounter_rumor(focal, nearby, rels, gs, mood, day)
    if not gs.rumor_network or not gs.rumor_network.rumors then return nil end

    local active = {}
    for _, r in pairs(gs.rumor_network.rumors) do
        if not r.dead and (r.heat or 0) > 30 then table.insert(active, r) end
    end
    if #active == 0 then return nil end

    local rumor = RNG.pick(active)
    return {
        type = "rumor",
        text = "A servant whispers as you pass: \"" .. (rumor.text or "...") .. "\" You pretend not to hear.",
        effect = {},
    }
end

--- Secret-driven: you know something, and it weighs on you.
function Encounters:_encounter_secret(focal, nearby, rels, gs, mood, day)
    local secrets = focal.components.secrets
    if not secrets or #(secrets.known or {}) == 0 then return nil end

    local secret = RNG.pick(secrets.known)
    local entities = self.engine:get_module("entities")
    local subject = entities and entities:get(secret.subject_id)
    local subject_name = subject and subject.name or "someone"

    return {
        type = "secret",
        text = "You think about what you know about " .. subject_name .. ". The knowledge sits heavy — a weapon you haven't drawn yet.",
        entity_id = secret.subject_id,
        effect = { purpose = 1 },
    }
end

--- Need-driven: your unmet needs produce intrusive thoughts.
function Encounters:_encounter_need(focal, nearby, rels, gs, mood, day)
    local needs = focal.components.needs
    if not needs then return nil end

    local NeedsLib = require("dredwork_agency.needs")
    local worst, worst_val = NeedsLib.get_most_unmet(needs)

    if worst_val > 35 then return nil end -- only fire when a need is really low

    local need_text = {
        safety = "Every shadow looks like a threat. You find yourself checking locks, testing exits, counting guards.",
        belonging = "The halls feel empty tonight. You eat alone and wonder if anyone would notice if you didn't.",
        purpose = "What are you doing here? The question arrives uninvited and refuses to leave.",
        comfort = "The cold seeps through the walls. Your bed is hard. Small miseries that compound.",
        status = "No one bowed today. No one asked your opinion. You are becoming furniture.",
    }

    return {
        type = "need",
        text = need_text[worst] or "Something feels wrong, but you can't name it.",
        effect = { [worst] = -1 }, -- unmet needs get worse when you dwell on them
    }
end

--- Mood-driven: your emotional state colors a mundane moment.
function Encounters:_encounter_mood(focal, nearby, rels, gs, mood, day)
    local mood_encounters = {
        desperate = "You stare at the ceiling. The cracks have multiplied since last you looked. Or maybe you're just seeing them clearly now.",
        grieving = "A song drifts in from somewhere. It was their favorite. You close your eyes.",
        anxious = "A door slams. Your hand goes to your belt. Nothing. Just the wind.",
        bitter = "Someone laughs in the next room. It sounds like mockery. Everything does lately.",
        restless = "You pace. The room is too small. The world is too small. Something needs to change.",
        calm = "Morning light through the window. A moment of stillness before the day takes you.",
        content = "For a breath, everything is as it should be. You know it won't last, but you hold it anyway.",
        determined = "You review your plans for the third time. Every detail matters. Every variable accounted for.",
        hopeful = "The sunrise is different today. Brighter, maybe. Or maybe you're different.",
        triumphant = "You catch your reflection and barely recognize the person staring back. They look powerful.",
    }

    return {
        type = "mood",
        text = mood_encounters[mood] or mood_encounters.calm,
        effect = {},
    }
end

--- Ambient: the world around you, filtered through your state.
function Encounters:_encounter_ambient(focal, nearby, rels, gs, mood, day)
    local month = gs.clock and gs.clock.month or 1
    local month_names = {"First Dawn","Deep Frost","High Bloom","Mist Rise","Sun Peak","Gold Harvest","Leaf Fall","Red Dusk","Pale Wind","Iron Shadow","Star Night","Final Cold"}
    local month_name = month_names[month] or "?"

    local pool = {
        "The market is quieter than usual. Fewer stalls, fewer faces. The world contracts.",
        "Children chase each other through the courtyard. They don't know what's coming. Maybe that's a mercy.",
        "Rain. The kind that lasts. You watch it from the window and plan nothing.",
        "An old woman sells dried flowers by the gate. She's been there every day of " .. month_name .. ". You've never spoken to her.",
        "The smell of bread from the kitchens. Simple. Grounding.",
        "A bird lands on the sill. Watches you. Leaves. You feel oddly judged.",
        "Clouds gather over the eastern ridge. Whether that's a metaphor is up to you.",
    }

    return {
        type = "ambient",
        text = RNG.pick(pool),
        effect = {},
    }
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function Encounters:get_today()
    return self.engine.game_state.encounters.today
end

function Encounters:get_history()
    return self.engine.game_state.encounters.history
end

function Encounters:serialize() return self.engine.game_state.encounters end
function Encounters:deserialize(data) self.engine.game_state.encounters = data end

return Encounters
