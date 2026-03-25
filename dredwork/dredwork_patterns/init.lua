-- dredwork Patterns — Narrator Pattern Detection
-- "This is the third time you've chosen mercy. People are beginning to notice."
-- "You always pick the violent option. It's becoming a reputation."
-- "Every time someone offers you trust, you betray it. What does that make you?"
--
-- The narrator watches your choices. Not to judge — to REFLECT.
-- Patterns emerge. The game names them before you do.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Patterns = {}
Patterns.__index = Patterns

-- What we track: tags from decisions, interactions, and approaches
local TRACKED_TAGS = {
    -- Moral axis
    merciful_act = { axis = "mercy",    weight = 1 },
    cruel_act    = { axis = "cruelty",  weight = 1 },
    kind         = { axis = "mercy",    weight = 0.5 },
    cold         = { axis = "cruelty",  weight = 0.5 },
    -- Action style
    brave        = { axis = "courage",  weight = 1 },
    cowardly     = { axis = "cowardice", weight = 1 },
    -- Social axis
    diplomatic   = { axis = "diplomacy", weight = 1 },
    hostile      = { axis = "aggression", weight = 1 },
    -- Trust axis
    suspicious   = { axis = "paranoia",  weight = 1 },
    warm         = { axis = "trust",     weight = 1 },
    -- Power axis
    pragmatic    = { axis = "pragmatism", weight = 1 },
    -- Other
    espionage    = { axis = "scheming",  weight = 1 },
    warfare      = { axis = "violence",  weight = 1 },
}

-- Pattern thresholds: how many tags before the narrator comments
local PATTERN_THRESHOLDS = { 3, 5, 8, 12 }

-- Narrator observations per axis per threshold tier
local OBSERVATIONS = {
    mercy = {
        [3] = {
            "Three times now, you've chosen mercy. Coincidence — or conviction?",
            "A pattern forms. You keep choosing the softer path. People notice these things.",
        },
        [5] = {
            "Five acts of mercy. It's not a choice anymore — it's who you are. Or who you're becoming.",
            "The merciful one, they're starting to call you. Behind your back, for now.",
        },
        [8] = {
            "Your reputation walks ahead of you now. People approach you differently. Softer. Hopeful. Dangerous, in its own way.",
            "Mercy has a price. The ones you spared remember. Some with gratitude. Some with contempt for your weakness.",
        },
        [12] = {
            "You've become legendary for your mercy. Songs, even. But legends attract those who want to test them.",
        },
    },
    cruelty = {
        [3] = {
            "Three times now. The hard choice. The one that leaves marks.",
            "You keep choosing the blade. Maybe it's practical. Maybe it's something else.",
        },
        [5] = {
            "Five cruel acts. It's not circumstance anymore. It's preference. The people around you are learning that.",
            "They flinch when you enter a room now. Not all of them. But enough.",
        },
        [8] = {
            "Cruelty has made you efficient. Also lonely. The two go together more often than you'd think.",
            "Children cross the street when they see you coming. They were taught to.",
        },
        [12] = {
            "You've become the thing people warn their children about. How does that feel?",
        },
    },
    courage = {
        [3] = {
            "You keep stepping forward when others step back. It's noticed.",
            "Brave, or reckless? The line is thin and you keep walking it.",
        },
        [5] = {
            "Five times facing what others fled. Your name is becoming shorthand for a certain kind of foolishness. Or heroism. Same thing, really.",
        },
        [8] = {
            "Courage is a resource. You spend it freely. One day the account may be empty.",
        },
    },
    cowardice = {
        [3] = {
            "Three times you've turned away. Self-preservation is rational. But it's starting to define you.",
            "You keep choosing safety. Nothing wrong with that. Except the way people look at you afterward.",
        },
        [5] = {
            "The safe choice, every time. People stop asking you for help eventually. You've almost reached that point.",
        },
        [8] = {
            "You survived everything by avoiding it. An accomplishment, of a kind. A lonely kind.",
        },
    },
    diplomacy = {
        [3] = {
            "Words over weapons, three times running. You're building something — whether you mean to or not.",
        },
        [5] = {
            "Five negotiations. Five bridges instead of battles. The diplomats are starting to see you as one of their own.",
        },
        [8] = {
            "Your reputation for talk has become its own kind of power. People seek you out to mediate. That's influence.",
        },
    },
    aggression = {
        [3] = {
            "Three confrontations. Three escalations. A pattern is forming in blood.",
        },
        [5] = {
            "You've made enemies efficiently. Five conflicts, and the list of people who'd rather see you gone grows longer.",
        },
    },
    paranoia = {
        [3] = {
            "You doubt everyone. Maybe you're right to. But the suspicion is becoming visible.",
        },
        [5] = {
            "Five times choosing distrust. Your allies are beginning to wonder if you can be one.",
        },
    },
    trust = {
        [3] = {
            "Open-hearted, three times over. In this world, that's either courage or naivety.",
        },
        [5] = {
            "You keep letting people in. Most of them deserve it. The ones who don't — they'll find the gaps you've made.",
        },
    },
    pragmatism = {
        [3] = {
            "Three practical choices. No sentiment. No waste. People respect that. Some of them.",
        },
        [5] = {
            "You always take the deal. The efficient path. It works. But it doesn't inspire.",
        },
    },
    scheming = {
        [3] = {
            "Three times in the shadows. You're getting comfortable there.",
        },
        [5] = {
            "The shadows know your name now. That's useful — until someone else learns it too.",
        },
    },
    violence = {
        [3] = {
            "Three times you chose the sword. The world bends to force — for a while.",
        },
        [5] = {
            "War follows you. Or maybe you follow it. Five violent choices and counting.",
        },
    },
}

function Patterns.init(engine)
    local self = setmetatable({}, Patterns)
    self.engine = engine

    engine.game_state.patterns = {
        tag_counts = {},        -- axis → count
        last_fired = {},        -- axis → threshold tier last fired
        choice_log = {},        -- recent tagged choices (max 50)
        streak = nil,           -- current streak: { axis, count }
        last_axis = nil,        -- axis of most recent choice
    }

    -- Listen for tagged decisions
    engine:on("DECISION_RESOLVED", function(ctx)
        if ctx and ctx.option and ctx.option.tags then
            self:record_tags(ctx.option.tags, engine.game_state)
        end
    end)

    -- Listen for tagged interactions
    engine:on("INTERACTION_PERFORMED", function(ctx)
        if ctx and ctx.tags then
            self:record_tags(ctx.tags, engine.game_state)
        end
    end)

    -- Listen for approach responses
    engine:on("APPROACH_RESOLVED", function(ctx)
        if ctx and ctx.tags then
            self:record_tags(ctx.tags, engine.game_state)
        end
    end)

    return self
end

--------------------------------------------------------------------------------
-- RECORDING: Track tags and detect patterns
--------------------------------------------------------------------------------

function Patterns:record_tags(tags, gs)
    local ps = gs.patterns
    local day = gs.clock and gs.clock.total_days or 0

    for _, tag in ipairs(tags) do
        local tracked = TRACKED_TAGS[tag]
        if tracked then
            local axis = tracked.axis
            local w = tracked.weight or 1

            ps.tag_counts[axis] = (ps.tag_counts[axis] or 0) + w

            -- Track streak
            if axis == ps.last_axis then
                if ps.streak and ps.streak.axis == axis then
                    ps.streak.count = ps.streak.count + 1
                else
                    ps.streak = { axis = axis, count = 2 }
                end
            else
                ps.streak = { axis = axis, count = 1 }
            end
            ps.last_axis = axis

            -- Log it
            table.insert(ps.choice_log, { axis = axis, tag = tag, day = day })
            while #ps.choice_log > 50 do
                table.remove(ps.choice_log, 1)
            end

            -- Check if we crossed a threshold
            self:_check_threshold(axis, ps, day)
        end
    end
end

function Patterns:_check_threshold(axis, ps, day)
    local count = ps.tag_counts[axis] or 0
    local last_tier = ps.last_fired[axis] or 0

    for _, threshold in ipairs(PATTERN_THRESHOLDS) do
        if count >= threshold and threshold > last_tier then
            -- Fire this observation
            ps.last_fired[axis] = threshold

            local texts = OBSERVATIONS[axis] and OBSERVATIONS[axis][threshold]
            if texts then
                local text = RNG.pick(texts)
                self.engine:push_ui_event("NARRATIVE_BEAT", {
                    channel = "whispers",
                    text = text,
                    priority = 75,
                    display_hint = "pattern",
                    tags = { "pattern", axis },
                    timestamp = day,
                })
                self.engine:emit("PATTERN_DETECTED", {
                    axis = axis,
                    count = count,
                    threshold = threshold,
                    text = text,
                })
            end
            return  -- Only fire one per tag recording
        end
    end

    -- Streak observation (3+ of the same axis in a row)
    if ps.streak and ps.streak.axis == axis and ps.streak.count == 3 then
        local streak_texts = {
            mercy = "Mercy again. It's becoming a reflex.",
            cruelty = "Again. The cruel choice. Again.",
            courage = "Into the fire. Again. Don't you ever hesitate?",
            cowardice = "Running. Again. The legs remember even when the mind forgets.",
            diplomacy = "Words, words, words. Your weapon of choice.",
            violence = "Blood answers blood answers blood.",
        }
        local text = streak_texts[axis]
        if text then
            self.engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = text,
                priority = 65,
                display_hint = "pattern",
                tags = { "streak", axis },
                timestamp = day,
            })
        end
    end
end

--------------------------------------------------------------------------------
-- QUERIES
--------------------------------------------------------------------------------

function Patterns:get_dominant_axis(gs)
    gs = gs or self.engine.game_state
    local ps = gs.patterns
    local best_axis, best_count = nil, 0
    for axis, count in pairs(ps.tag_counts) do
        if count > best_count then
            best_axis, best_count = axis, count
        end
    end
    return best_axis, best_count
end

function Patterns:get_axis_count(axis, gs)
    gs = gs or self.engine.game_state
    return gs.patterns.tag_counts[axis] or 0
end

function Patterns:get_reputation_label(gs)
    gs = gs or self.engine.game_state
    local axis, count = self:get_dominant_axis(gs)
    if not axis or count < 5 then return nil end

    local labels = {
        mercy = "The Merciful",
        cruelty = "The Cruel",
        courage = "The Brave",
        cowardice = "The Cautious",
        diplomacy = "The Silver-Tongued",
        aggression = "The Wrathful",
        paranoia = "The Watchful",
        trust = "The Open-Hearted",
        pragmatism = "The Practical",
        scheming = "The Shadow",
        violence = "The Bloodied",
    }
    return labels[axis]
end

function Patterns:serialize() return self.engine.game_state.patterns end
function Patterns:deserialize(data) self.engine.game_state.patterns = data end

return Patterns
