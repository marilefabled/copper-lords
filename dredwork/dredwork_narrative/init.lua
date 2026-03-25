-- dredwork Narrative — Module Entry
-- Manages multiple scoped narrators (lenses), each watching a subset of modules.
-- Games choose which narrators to activate based on what story they want to tell.
--
-- Built-in presets:
--   "chronicle" — grand historical voice (politics, conquest, heritage, ledger, rivals)
--   "whispers"  — intimate court drama (court, marriage, bonds, decisions, biography)
--   "streets"   — gritty ground-level (economy, crime, rumor, strife, punishment)
--   "nature"    — environmental/atmospheric (animals, peril, geography, home)
--   "divine"    — mythic/philosophical (religion, culture, technology, heritage)
--   "all"       — everything (legacy single-narrator mode)

local Narrator  = require("dredwork_narrative.narrator")
local Memory    = require("dredwork_narrative.memory")
local Templates = require("dredwork_narrative.templates")
local Chains    = require("dredwork_narrative.chains")

local Narrative = {}
Narrative.__index = Narrative

--- Narrator preset definitions.
local PRESETS = {
    chronicle = {
        channel = "chronicle",
        voice = "grand",
        events = {
            "ADVANCE_GENERATION", "REBELLION", "RIVAL_ACTION", "RIVAL_DEATH",
            "RIVAL_SUCCESSION", "RIVAL_CONFLICT", "RIVAL_FALLEN",
            "LEDGER_CLOSED", "MATCH_COMPLETED", "DUEL_STARTED", "DUEL_RESOLVED",
            "HEIR_DIED", "SUCCESSION_COMPLETE", "SUCCESSION_CRISIS", "SUCCESSION_CONTESTED",
        },
        temporal = { daily = false, monthly = true, yearly = true, generational = true },
        features = { chains = true, vignettes = false, flavor = true },
        throttle = { max_temperature = 10, temperature_window = 60 },
        priority_scale = 1.1,
    },
    whispers = {
        channel = "whispers",
        voice = "intimate",
        events = {
            "COURT_BETRAYAL", "COURT_DEATH", "COURT_BOON",
            "MARRIAGE_PERFORMED", "DECISION_PRESENTED", "DECISION_RESOLVED",
            "WILD_ATTRIBUTE_DETECTED", "CHILD_BORN", "CHILD_DIED",
            "HEIR_DIED", "SUCCESSION_COMPLETE", "ENTITY_ACTION",
        },
        temporal = { daily = false, monthly = true, yearly = false, generational = true },
        features = { chains = false, vignettes = true, flavor = false },
        throttle = { max_temperature = 8, temperature_window = 30 },
        priority_scale = 1.0,
    },
    streets = {
        channel = "streets",
        voice = "gritty",
        events = {
            "CRIMINAL_SENTENCED", "RUMOR_LEGITIMACY_IMPACT",
        },
        temporal = { daily = false, monthly = true, yearly = false, generational = false },
        features = { chains = true, vignettes = false, flavor = false },
        throttle = { max_temperature = 12, temperature_window = 30 },
        priority_scale = 0.9,
    },
    nature = {
        channel = "nature",
        voice = "atmospheric",
        events = {
            "PERIL_STRIKE",
        },
        temporal = { daily = false, monthly = true, yearly = true, generational = false },
        features = { chains = true, vignettes = false, flavor = true },
        throttle = { max_temperature = 6, temperature_window = 60 },
        priority_scale = 0.8,
    },
    divine = {
        channel = "divine",
        voice = "mythic",
        events = {},
        temporal = { daily = false, monthly = true, yearly = true, generational = true },
        features = { chains = false, vignettes = false, flavor = true },
        throttle = { max_temperature = 5, temperature_window = 90 },
        priority_scale = 0.9,
    },
    all = {
        channel = "all",
        voice = "omniscient",
        events = {
            "CRIMINAL_SENTENCED", "MATCH_COMPLETED", "SPORTS_VICTORY",
            "PERIL_STRIKE", "RUMOR_LEGITIMACY_IMPACT", "REBELLION",
            "COURT_BETRAYAL", "COURT_DEATH", "COURT_BOON",
            "RIVAL_ACTION", "RIVAL_DEATH", "RIVAL_SUCCESSION", "RIVAL_CONFLICT", "RIVAL_FALLEN",
            "MARRIAGE_PERFORMED", "DECISION_PRESENTED", "DECISION_RESOLVED",
            "WILD_ATTRIBUTE_DETECTED", "LEDGER_CLOSED", "DUEL_STARTED", "DUEL_RESOLVED",
            "HEIR_DIED", "SUCCESSION_COMPLETE", "SUCCESSION_CRISIS",
            "SUCCESSION_CONTESTED", "CHILD_BORN", "CHILD_DIED", "ENTITY_ACTION",
            "ENTITY_DIED", "FOCAL_ENTITY_CHANGED",
        },
        temporal = { daily = true, monthly = true, yearly = true, generational = true },
        features = { chains = true, vignettes = true, flavor = true },
        throttle = { max_temperature = 15, temperature_window = 30 },
        priority_scale = 1.0,
    },
}

function Narrative.init(engine)
    local self = setmetatable({}, Narrative)
    self.engine = engine
    self.incidents = require("dredwork_narrative.incidents")

    -- Narrator instances keyed by channel name
    self.narrators = {}

    -- Initialize state
    engine.game_state.narrative = {
        active_narrators = {},  -- list of channel names that are active
        settings = {
            verbosity = "normal",
        },
    }

    -- Default: activate "all" narrator for backward compatibility
    self:activate_narrator("all")

    -- Expose narrative context via event bus
    engine:on("GET_NARRATIVE_CONTEXT", function(req)
        req.narrator_count = 0
        req.active_channels = {}
        for channel, _ in pairs(self.narrators) do
            req.narrator_count = req.narrator_count + 1
            table.insert(req.active_channels, channel)
        end
        req.active_chains = self:get_all_active_arcs()
    end)

    engine:on("GET_ACTIVE_STORY_ARCS", function(req)
        req.arcs = self:get_all_active_arcs()
    end)

    return self
end

--------------------------------------------------------------------------------
-- Narrator Management
--------------------------------------------------------------------------------

--- Activate a narrator by preset name or custom config.
---@param preset_or_config string|table — preset name or full config table
---@return table Narrator instance
function Narrative:activate_narrator(preset_or_config)
    local config
    if type(preset_or_config) == "string" then
        config = PRESETS[preset_or_config]
        if not config then
            self.engine.log:warn("Narrative: Unknown preset '%s'", preset_or_config)
            return nil
        end
    else
        config = preset_or_config
    end

    local channel = config.channel
    if self.narrators[channel] then
        self.engine.log:warn("Narrative: Narrator '%s' already active", channel)
        return self.narrators[channel]
    end

    local narrator = Narrator.new(config, self.engine)
    self.narrators[channel] = narrator

    -- Track in game_state
    local ns = self.engine.game_state.narrative
    ns.active_narrators = ns.active_narrators or {}
    local found = false
    for _, name in ipairs(ns.active_narrators) do
        if name == channel then found = true; break end
    end
    if not found then table.insert(ns.active_narrators, channel) end

    self.engine.log:info("Narrative: Activated narrator '%s'", channel)
    return narrator
end

--- Deactivate a narrator by channel name.
function Narrative:deactivate_narrator(channel)
    self.narrators[channel] = nil
    local ns = self.engine.game_state.narrative
    if ns.active_narrators then
        for i, name in ipairs(ns.active_narrators) do
            if name == channel then table.remove(ns.active_narrators, i); break end
        end
    end
    self.engine.log:info("Narrative: Deactivated narrator '%s'", channel)
end

--- Get a narrator by channel name.
function Narrative:get_narrator(channel)
    return self.narrators[channel]
end

--- Get all active narrator channel names.
function Narrative:get_active_channels()
    local channels = {}
    for channel, _ in pairs(self.narrators) do
        table.insert(channels, channel)
    end
    return channels
end

--- Switch from "all" mode to focused mode (deactivate "all", activate specific narrators).
---@param channels table array of preset names to activate
function Narrative:focus(channels)
    -- Deactivate everything
    for channel, _ in pairs(self.narrators) do
        self:deactivate_narrator(channel)
    end
    -- Activate requested
    for _, channel in ipairs(channels) do
        self:activate_narrator(channel)
    end
end

--------------------------------------------------------------------------------
-- Public API (delegates to narrators)
--------------------------------------------------------------------------------

--- Pop beats from a specific narrator (or all narrators).
---@param channel string|nil — specific channel, or nil for all
---@return table beats
function Narrative:pop_beats(channel)
    if channel and self.narrators[channel] then
        return self.narrators[channel]:pop_beats()
    end

    -- Pop from all narrators, merged
    local all = {}
    for _, narrator in pairs(self.narrators) do
        for _, beat in ipairs(narrator:pop_beats()) do
            table.insert(all, beat)
        end
    end
    -- Sort by timestamp then priority
    table.sort(all, function(a, b)
        if a.timestamp == b.timestamp then return a.priority > b.priority end
        return a.timestamp < b.timestamp
    end)
    return all
end

--- Peek at beats without clearing.
function Narrative:peek_beats(channel)
    if channel and self.narrators[channel] then
        return self.narrators[channel]:peek_beats()
    end
    local all = {}
    for _, narrator in pairs(self.narrators) do
        for _, beat in ipairs(narrator:peek_beats()) do
            table.insert(all, beat)
        end
    end
    return all
end

--- Inject a beat into a specific narrator (or the first available).
function Narrative:inject(text, opts)
    opts = opts or {}
    local channel = opts.channel

    if channel and self.narrators[channel] then
        self.narrators[channel]:inject(text, opts)
        return
    end

    -- Default: inject into first narrator
    for _, narrator in pairs(self.narrators) do
        narrator:inject(text, opts)
        return
    end
end

--- Register a custom template.
function Narrative:register_template(tmpl)
    Templates.register(tmpl)
end

--- Get all active story arcs across all narrators.
function Narrative:get_active_arcs()
    return self:get_all_active_arcs()
end

function Narrative:get_all_active_arcs()
    local all = {}
    for channel, narrator in pairs(self.narrators) do
        for _, arc in ipairs(narrator:get_active_arcs()) do
            arc.channel = channel
            table.insert(all, arc)
        end
    end
    return all
end

--- Set verbosity.
function Narrative:set_verbosity(level)
    self.engine.game_state.narrative.settings.verbosity = level
end

--- Generate an incident.
function Narrative:generate_incident(context)
    return self.incidents.generate(self.engine, context)
end

--- Get available preset names.
function Narrative.get_presets()
    local names = {}
    for name, _ in pairs(PRESETS) do
        table.insert(names, name)
    end
    return names
end

--- Create a fully custom narrator (not from presets).
---@param config table { channel, events, temporal, features, throttle, ... }
---@return table Narrator instance
function Narrative:create_custom_narrator(config)
    return self:activate_narrator(config)
end

--------------------------------------------------------------------------------
-- Serialize / Deserialize
--------------------------------------------------------------------------------

function Narrative:serialize()
    local data = {
        settings = self.engine.game_state.narrative.settings,
        active_narrators = {},
        narrator_states = {},
    }
    for channel, narrator in pairs(self.narrators) do
        table.insert(data.active_narrators, channel)
        data.narrator_states[channel] = narrator:serialize()
    end
    return data
end

function Narrative:deserialize(data)
    if not data then return end
    self.engine.game_state.narrative.settings = data.settings or { verbosity = "normal" }

    -- Restore narrator states (narrators were already created in init)
    if data.narrator_states then
        for channel, state in pairs(data.narrator_states) do
            if self.narrators[channel] then
                self.narrators[channel]:deserialize(state)
            end
        end
    end
end

return Narrative
