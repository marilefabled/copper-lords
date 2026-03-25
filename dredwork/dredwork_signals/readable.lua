-- dredwork Signals — Readable (Bidirectional Perception)
-- The world reads YOU. NPCs with high observation notice your state.
-- Your trembling hands. Your absences. Your late-night tavern visits.
-- How well you hide depends on composure and deception.
-- This is information warfare.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local Affinity = require("dredwork_signals.affinity")

local Readable = {}

--- Calculate how "readable" an entity is.
--- High readability = easy to read. Low = opaque.
---@param entity table the entity being read
---@return number readability 0-100
function Readable.calculate_readability(entity)
    local p = entity.components.personality or {}
    local function get(id)
        local v = p[id]; if type(v) == "table" then return v.value or 50 end; return v or 50
    end

    -- Composure (inverse of volatility) makes you harder to read
    local vol = get("PER_VOL")
    local obs = get("PER_OBS")  -- observant people are also better at hiding (they know what to conceal)
    local ada = get("PER_ADA")  -- adaptive people mask well

    local readability = 50
    readability = readability + (vol - 50) * 0.4   -- volatile = more readable
    readability = readability - (obs - 50) * 0.3   -- observant = harder to read
    readability = readability - (ada - 50) * 0.2   -- adaptive = harder to read

    -- Mood affects readability: extreme moods are harder to hide
    local mood = entity.components.mood
    if mood == "desperate" or mood == "triumphant" or mood == "grieving" then
        readability = readability + 15  -- extreme emotions leak
    elseif mood == "calm" or mood == "content" then
        readability = readability - 10  -- stable moods are hard to read
    end

    -- Low needs are visible: hunger shows, fear shows
    local needs = entity.components.needs
    if needs then
        if (needs.safety or 50) < 20 then readability = readability + 10 end
        if (needs.comfort or 50) < 20 then readability = readability + 5 end
        if (needs.belonging or 50) < 20 then readability = readability + 5 end
    end

    return Math.clamp(readability, 0, 100)
end

--- What an NPC can read about the focal entity.
--- Returns signals the NPC generates about YOU.
---@param reader table the NPC reading you
---@param target table the entity being read (usually focal)
---@return table|nil signal they generate (or nil if they can't read you)
function Readable.npc_reads_you(reader, target)
    if not reader or not target then return nil end
    if not reader.components.personality then return nil end

    local reader_p = reader.components.personality or {}
    local reader_obs = reader_p.PER_OBS or 50
    if type(reader_obs) == "table" then reader_obs = reader_obs.value or 50 end

    -- Reader's observation skill vs target's readability
    local readability = Readable.calculate_readability(target)
    local read_chance = (reader_obs + readability) / 200
    read_chance = Math.clamp(read_chance, 0.05, 0.8)

    if not RNG.chance(read_chance) then return nil end

    -- What do they notice?
    local needs = target.components.needs
    local mood = target.components.mood
    local signals = {}

    -- Physical tells
    if needs and (needs.safety or 50) < 25 then
        table.insert(signals, {
            what = "fear",
            text = reader.name .. " notices your hands aren't steady. Their eyes narrow.",
            severity = "warning",
        })
    end
    if needs and (needs.belonging or 50) < 20 then
        table.insert(signals, {
            what = "isolation",
            text = reader.name .. " watches you eat alone. Again. They file that away.",
            severity = "warning",
        })
    end
    if needs and (needs.comfort or 50) < 20 then
        table.insert(signals, {
            what = "weakness",
            text = reader.name .. " notices the shadows under your eyes. The weight you've lost. They say nothing.",
            severity = "warning",
        })
    end

    -- Mood tells
    if mood == "desperate" then
        table.insert(signals, {
            what = "desperation",
            text = reader.name .. " sees the look in your eyes. The look of someone with nothing left to lose. They step back.",
            severity = "critical",
        })
    elseif mood == "bitter" then
        table.insert(signals, {
            what = "resentment",
            text = reader.name .. " catches the edge in your voice. The bitterness you thought you were hiding. You weren't.",
            severity = "warning",
        })
    elseif mood == "triumphant" then
        table.insert(signals, {
            what = "power",
            text = reader.name .. " notices you walk differently now. Head higher. Steps heavier. They take note.",
            severity = "warning",
        })
    end

    -- Secret activity tells (if the reader is observant enough)
    if reader_obs > 60 then
        local agenda = target.components.agenda
        if agenda and agenda.active_plan and agenda.active_plan.status == "active" then
            if agenda.active_plan.template_id == "coup" or agenda.active_plan.template_id == "subversion" then
                table.insert(signals, {
                    what = "scheming",
                    text = reader.name .. " has been watching you come and go at odd hours. They haven't said anything. Yet.",
                    severity = "critical",
                })
            end
        end
    end

    if #signals == 0 then return nil end
    return RNG.pick(signals)
end

--- What consequences come from being read.
--- NPCs who read you may adjust their behavior.
---@param reader table the NPC who read you
---@param signal table what they noticed
---@param engine table
function Readable.react_to_reading(reader, signal, engine)
    if not reader or not signal then return end

    local reader_p = reader.components.personality or {}
    local crm = reader_p.PER_CRM or 50
    if type(crm) == "table" then crm = crm.value or 50 end
    local loy = reader_p.PER_LOY or 50
    if type(loy) == "table" then loy = loy.value or 50 end

    -- Loyal readers who see weakness → offer help (strengthen relationship)
    if signal.what == "fear" or signal.what == "weakness" or signal.what == "isolation" then
        if loy > 60 then
            local entities = engine:get_module("entities")
            if entities then
                local focal = entities:get_focus()
                if focal then
                    entities:shift_relationship(reader.id, focal.id, "concern", 3)
                end
            end
        end
    end

    -- Cruel readers who see weakness → exploit it
    if signal.what == "fear" or signal.what == "desperation" or signal.what == "weakness" then
        if crm > 60 then
            local entities = engine:get_module("entities")
            if entities then
                local focal = entities:get_focus()
                if focal then
                    entities:shift_relationship(reader.id, focal.id, "contempt", 5)
                    -- May start scheming against you
                    if reader.components.memory then
                        local MemLib = require("dredwork_agency.memory")
                        MemLib.remember(reader.components.memory,
                            engine.game_state.clock and engine.game_state.clock.total_days or 0,
                            "saw_weakness", focal.id, "noticed vulnerability", 3)
                    end
                end
            end
        end
    end

    -- Readers who notice scheming → become wary or join
    if signal.what == "scheming" then
        if loy > 65 then
            -- Loyal reader warns you (or warns others about you)
            local rumor = engine:get_module("rumor")
            if rumor and RNG.chance(0.3) then
                rumor:inject(engine.game_state, {
                    origin_type = "observation",
                    subject = "someone",
                    text = "Whispers about unusual activity. Someone is watching.",
                    heat = 30, tags = { scandal = true },
                })
            end
        elseif crm > 55 then
            -- Cruel/ambitious reader may try to leverage this
            if reader.components.secrets then
                local SecretsLib = require("dredwork_agency.secrets")
                local focal = engine:get_module("entities") and engine:get_module("entities"):get_focus()
                if focal then
                    SecretsLib.learn(reader.components.secrets, {
                        id = "observed_scheming_" .. (engine.game_state.clock and engine.game_state.clock.total_days or 0),
                        type = "conspiracy",
                        subject_id = focal.id,
                        text = focal.name .. " has been acting strangely. Meetings. Absences. Something is planned.",
                        severity = 50,
                        known_day = engine.game_state.clock and engine.game_state.clock.total_days or 0,
                    })
                end
            end
        end
    end
end

return Readable
