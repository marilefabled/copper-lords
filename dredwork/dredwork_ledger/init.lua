-- dredwork Ledger — Module Entry
-- Generational impact scoring. Tracks what each heir accomplished across their reign.
-- Ported from Bloodweight's heir_ledger.lua, adapted for event bus.

local Math = require("dredwork_core.math")

local Ledger = {}
Ledger.__index = Ledger

--- Score weights for each impact category.
local WEIGHTS = {
    wealth_impact    = 0.15,
    military_impact  = 0.10,
    legitimacy_delta = 0.15,
    cultural_shift   = 0.10,
    alliances        = 0.15,
    territory        = 0.10,
    heritage         = 0.10,
    morality         = 0.05,
    survival         = 0.10,
}

--- Impact tier thresholds.
local TIERS = {
    { min = 80,  label = "Legendary" },
    { min = 60,  label = "Exalted" },
    { min = 40,  label = "Formidable" },
    { min = 20,  label = "Capable" },
    { min = 0,   label = "Mediocre" },
    { min = -20, label = "Wretched" },
    { min = -100, label = "Accursed" },
}

function Ledger.init(engine)
    local self = setmetatable({}, Ledger)
    self.engine = engine

    engine.game_state.ledger = {
        current = nil,      -- active ledger entry for current heir
        entries = {},       -- array of completed ledger entries
    }

    -- Start a new ledger entry when a generation begins
    engine:on("ADVANCE_GENERATION", function(context)
        self:close_and_start(self.engine.game_state)
    end)

    -- Track events that contribute to the ledger
    engine:on("MARRIAGE_PERFORMED", function(ctx)
        self:add_score("alliances", 8)
        self:add_deed("marriage", ctx.text or "A marriage was performed.")
    end)

    engine:on("COURT_BETRAYAL", function(ctx)
        self:add_score("alliances", -10)
        self:add_deed("betrayal", ctx.text or "A court member betrayed the house.")
    end)

    engine:on("COURT_BOON", function(ctx)
        self:add_score("alliances", 5)
    end)

    engine:on("RIVAL_ACTION", function(ctx)
        if ctx.type == "rival_raid" then
            self:add_score("military_impact", -5)
            self:add_score("survival", -3)
        elseif ctx.type == "rival_gift" then
            self:add_score("alliances", 5)
        end
    end)

    engine:on("DECISION_RESOLVED", function(ctx)
        if ctx.resisted then
            self:add_score("morality", 3) -- resistance shows character
        end
        self:add_deed("decision", ctx.option and ctx.option.label or "A choice was made.")
    end)

    -- Expose ledger data
    engine:on("GET_LEDGER_DATA", function(req)
        req.current = self.engine.game_state.ledger.current
        req.entries = self.engine.game_state.ledger.entries
    end)

    return self
end

--------------------------------------------------------------------------------
-- Ledger Entry Management
--------------------------------------------------------------------------------

--- Start a new ledger entry.
function Ledger:start(gs)
    gs.ledger.current = {
        heir_name = gs.heir_name or gs.current_heir and gs.current_heir.name or "Unknown",
        started_day = gs.clock and gs.clock.total_days or 0,
        generation = gs.clock and gs.clock.generation or 0,
        scores = {
            wealth_impact = 0,
            military_impact = 0,
            legitimacy_delta = 0,
            cultural_shift = 0,
            alliances = 0,
            territory = 0,
            heritage = 0,
            morality = 0,
            survival = 0,
        },
        deeds = {},
        epitaph = nil,
    }
end

--- Add to a score category.
function Ledger:add_score(category, delta)
    local current = self.engine.game_state.ledger.current
    if not current then return end
    current.scores[category] = (current.scores[category] or 0) + delta
end

--- Record a deed.
function Ledger:add_deed(type_key, description)
    local current = self.engine.game_state.ledger.current
    if not current then return end
    table.insert(current.deeds, {
        type = type_key,
        text = description,
        day = self.engine.game_state.clock and self.engine.game_state.clock.total_days or 0,
    })
end

--- Calculate composite score and tier for a ledger entry.
function Ledger.calculate_impact(entry)
    local composite = 0
    for category, weight in pairs(WEIGHTS) do
        local raw = entry.scores[category] or 0
        -- Normalize: scores are roughly -50 to +50, map to 0-100 centered at 50
        local normalized = Math.clamp(raw + 50, 0, 100)
        composite = composite + normalized * weight
    end

    -- Determine tier
    local tier = "Accursed"
    for _, t in ipairs(TIERS) do
        if composite >= t.min then
            tier = t.label
            break
        end
    end

    return composite, tier
end

--- Close the current entry and start a new one.
function Ledger:close_and_start(gs)
    local current = gs.ledger.current

    if current then
        -- Calculate final impact
        local score, tier = Ledger.calculate_impact(current)
        current.final_score = score
        current.tier = tier
        current.ended_day = gs.clock and gs.clock.total_days or 0

        -- Generate epitaph
        current.epitaph = string.format("%s the %s", current.heir_name, tier)

        table.insert(gs.ledger.entries, current)

        -- Emit for narrative
        self.engine:emit("LEDGER_CLOSED", {
            heir_name = current.heir_name,
            score = score,
            tier = tier,
            epitaph = current.epitaph,
        })
        self.engine:push_ui_event("LEDGER_CLOSED", {
            text = string.format("%s — %s (Score: %.0f)", current.epitaph, tier, score),
        })

        self.engine.log:info("Ledger: %s closed — %s (%.0f)", current.heir_name, tier, score)
    end

    -- Start fresh
    self:start(gs)
end

--- Get the current entry.
function Ledger:get_current()
    return self.engine.game_state.ledger.current
end

--- Get all past entries.
function Ledger:get_history()
    return self.engine.game_state.ledger.entries
end

function Ledger:serialize() return self.engine.game_state.ledger end
function Ledger:deserialize(data) self.engine.game_state.ledger = data end

return Ledger
