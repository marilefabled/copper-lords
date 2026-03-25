-- dredwork Narrative — Narrator (Scoped Narrative Lens)
-- A single narrator instance that watches specific events and produces beats
-- through its own memory, throttle, and voice configuration.
--
-- Multiple narrators can coexist, each focused on different module domains.
-- They share template and chain definitions but have independent state.

local RNG = require("dredwork_core.rng")
local Memory = require("dredwork_narrative.memory")
local Templates = require("dredwork_narrative.templates")
local Chains = require("dredwork_narrative.chains")
local Vignettes = require("dredwork_narrative.vignettes")
local Flavor = require("dredwork_narrative.flavor")

local Narrator = {}
Narrator.__index = Narrator

--- Create a new scoped narrator.
---@param config table {
---   channel: string — output channel name (e.g. "chronicle", "whispers", "streets")
---   voice: string|nil — narrative tone label
---   events: table — array of event names to subscribe to
---   temporal: table|nil — { daily=bool, monthly=bool, yearly=bool, generational=bool }
---   features: table|nil — { chains=bool, vignettes=bool, flavor=bool }
---   throttle: table|nil — { max_temperature, temperature_window }
---   priority_scale: number|nil — multiply all priorities (default 1.0)
---   display_hint_override: string|nil — force all beats to this hint
--- }
---@param engine table
---@return table Narrator instance
function Narrator.new(config, engine)
    local self = setmetatable({}, Narrator)
    self.engine = engine
    self.channel = config.channel or "default"
    self.voice = config.voice or "neutral"
    self.priority_scale = config.priority_scale or 1.0
    self.display_hint_override = config.display_hint_override
    self.features = config.features or { chains = true, vignettes = true, flavor = true }

    -- Independent state
    self.state = {
        active_chains = {},
        memory = Memory.create(),
        queue = {},
    }

    -- Apply throttle overrides
    if config.throttle then
        if config.throttle.max_temperature then
            self.state.memory.max_temperature = config.throttle.max_temperature
        end
        if config.throttle.temperature_window then
            self.state.memory.temperature_window = config.throttle.temperature_window
        end
    end

    -- Subscribe to specified events
    local events = config.events or {}
    for _, event_name in ipairs(events) do
        engine:on(event_name, function(ctx)
            self:_on_event(event_name, ctx)
        end)
    end

    -- Temporal hooks
    local temporal = config.temporal or {}

    if temporal.daily then
        engine:on("NEW_DAY", function(clock)
            self:_tick_daily(clock)
        end)
    end

    if temporal.monthly ~= false then -- default on
        engine:on("NEW_MONTH", function(clock)
            self:_tick_monthly(clock)
        end)
    end

    if temporal.yearly ~= false then -- default on
        engine:on("NEW_YEAR", function(clock)
            self:_tick_yearly(clock)
        end)
    end

    if temporal.generational ~= false then -- default on
        engine:on("ADVANCE_GENERATION", function(context)
            self:_tick_generational(context)
        end)
    end

    return self
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

--- Generic event handler — turns any event into a narrative beat.
function Narrator:_on_event(event_name, ctx)
    local gs = self.engine.game_state
    local clock = gs.clock or {}

    -- Try to extract text from context
    local text = nil
    local priority = 50
    local display_hint = "toast"
    local tags = { event_name:lower() }

    if type(ctx) == "table" then
        text = ctx.text or ctx.narrative or ctx.title
        priority = ctx.priority or priority

        -- Event-specific display hints
        if event_name:match("DEATH") or event_name:match("BETRAYAL") or event_name:match("REBELLION") then
            display_hint = "panel"
            priority = math.max(priority, 70)
        end
        if event_name:match("LEDGER") or event_name:match("GENERATION") then
            display_hint = "fullscreen"
            priority = math.max(priority, 85)
        end

        -- Collect tags from context
        if ctx.tags then
            if type(ctx.tags) == "table" then
                for _, t in ipairs(ctx.tags) do table.insert(tags, t) end
                for k, v in pairs(ctx.tags) do
                    if v == true then table.insert(tags, k) end
                end
            end
        end
        if ctx.type then table.insert(tags, ctx.type) end
    end

    -- If no text, try template
    if not text then
        local template_id = "event_" .. event_name:lower()
        local vars = self:_build_vars(gs)
        text = Templates.render(template_id, vars)
    end

    -- Still no text — generate a fallback
    if not text then
        text = event_name:gsub("_", " "):lower()
        text = text:sub(1, 1):upper() .. text:sub(2) .. "."
        priority = math.max(priority - 10, 10)
    end

    self:_emit_beat({
        template_id = "event_" .. event_name:lower(),
        text = text,
        display_hint = display_hint,
        priority = priority,
        tags = tags,
    }, clock)
end

--------------------------------------------------------------------------------
-- Temporal Ticks
--------------------------------------------------------------------------------

function Narrator:_tick_daily(clock)
    if not self.features.chains then return end
    local gs = self.engine.game_state
    local vars = self:_build_vars(gs)

    local beats = Chains.tick_daily(self.state.active_chains, gs, clock, vars)
    for _, beat in ipairs(beats) do
        self:_emit_beat(beat, clock)
    end
end

function Narrator:_tick_monthly(clock)
    local gs = self.engine.game_state
    local vars = self:_build_vars(gs)

    -- Chains
    if self.features.chains then
        local new_beats, new_chains = Chains.check_triggers(self.state.active_chains, gs, clock, vars)
        for _, ac in ipairs(new_chains) do
            table.insert(self.state.active_chains, ac)
            Memory.start_thread(self.state.memory, ac.chain_id, clock)
        end
        for _, beat in ipairs(new_beats) do
            self:_emit_beat(beat, clock)
        end
    end

    -- Vignettes
    if self.features.vignettes then
        local vignette = Vignettes.generate(gs)
        if vignette then
            self:_emit_beat({
                template_id = "vignette",
                text = vignette.text,
                display_hint = vignette.display_hint,
                priority = vignette.priority,
                tags = vignette.tags or {"vignette"},
            }, clock)
        end
    end

    -- Flavor
    if self.features.flavor then
        local region_name = self:_get_region_name()
        local seasonal = Flavor.get_seasonal(clock.month, gs, region_name)
        if seasonal then
            self:_emit_beat({
                template_id = "flavor_seasonal_" .. clock.month,
                text = seasonal.text,
                display_hint = seasonal.display_hint,
                priority = seasonal.priority,
                tags = seasonal.tags or {"flavor"},
            }, clock)
        end

        local festival = Flavor.get_festival(clock.month, gs)
        if festival then
            self:_emit_beat({
                template_id = "flavor_festival_" .. clock.month,
                text = festival.text,
                display_hint = festival.display_hint,
                priority = festival.priority,
                tags = festival.tags or {"flavor"},
            }, clock)
        end
    end

    -- Memory cleanup
    Memory.cleanup(self.state.memory, clock)
end

function Narrator:_tick_yearly(clock)
    if not self.features.flavor then return end
    local gs = self.engine.game_state
    local region_name = self:_get_region_name()
    local summary = Flavor.get_year_summary(gs, region_name)
    if summary then
        self:_emit_beat({
            template_id = "summary_year",
            text = summary.text,
            display_hint = summary.display_hint,
            priority = summary.priority,
            tags = summary.tags or {"summary"},
        }, clock)
    end
end

function Narrator:_tick_generational(context)
    if not self.features.flavor then return end
    local gs = self.engine.game_state
    local clock = gs.clock or {}
    local summary = Flavor.get_generational_summary(gs)
    if summary then
        self:_emit_beat({
            template_id = "summary_generation",
            text = summary.text,
            display_hint = summary.display_hint,
            priority = summary.priority,
            tags = summary.tags or {"summary"},
        }, clock)
    end
end

--------------------------------------------------------------------------------
-- Beat Emission
--------------------------------------------------------------------------------

function Narrator:_emit_beat(beat, clock)
    local priority = math.floor((beat.priority or 50) * self.priority_scale)
    local display_hint = self.display_hint_override or beat.display_hint or "toast"

    -- Memory check (skip for chain beats)
    if not beat.chain_id then
        if not Memory.should_emit(self.state.memory, beat.template_id or "unknown", {}, clock, priority) then
            return
        end
    end

    -- Record in memory
    Memory.record(self.state.memory, beat.template_id or "unknown", {}, clock,
        beat.cooldown_days or (priority > 70 and 60 or 30))

    -- Track chain thread
    if beat.chain_id then
        if Memory.is_thread_active(self.state.memory, beat.chain_id) then
            Memory.advance_thread(self.state.memory, beat.chain_id, clock)
        end
    end

    -- Build payload
    local payload = {
        id = (beat.template_id or "beat") .. "_" .. (clock.total_days or 0),
        channel = self.channel,
        type = beat.chain_id and "chain" or "event",
        priority = priority,
        text = beat.text,
        display_hint = display_hint,
        tags = beat.tags or {},
        chain_id = beat.chain_id,
        stage_id = beat.stage_id,
        timestamp = clock.total_days or 0,
    }

    -- Emit on engine event bus (tagged with channel)
    self.engine:emit("NARRATIVE_BEAT", payload)
    self.engine:push_ui_event("NARRATIVE_BEAT", payload)

    -- Chain advancement event
    if beat.chain_id and beat.stage_id then
        self.engine:emit("NARRATIVE_CHAIN_ADVANCED", {
            chain_id = beat.chain_id,
            stage = beat.stage_id,
            channel = self.channel,
        })
    end

    -- Add to own queue
    table.insert(self.state.queue, payload)
    while #self.state.queue > 50 do table.remove(self.state.queue, 1) end
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

function Narrator:_build_vars(gs)
    local clock = gs.clock or {}
    local month_names = {
        "First Dawn", "Deep Frost", "High Bloom", "Mist Rise",
        "Sun Peak", "Gold Harvest", "Leaf Fall", "Red Dusk",
        "Pale Wind", "Iron Shadow", "Star Night", "Final Cold"
    }
    return {
        heir_name = gs.current_heir and gs.current_heir.name or "the heir",
        lineage_name = gs.lineage_name or "the bloodline",
        region = self:_get_region_name(),
        year = tostring(clock.year or 0),
        month = month_names[clock.month or 1] or "this month",
        generation = tostring(clock.generation or 0),
    }
end

function Narrator:_get_region_name()
    local req = { label = "the realm" }
    self.engine:emit("GET_GEOGRAPHY_DATA", req)
    return req.label or "the realm"
end

--- Get and clear this narrator's beat queue.
function Narrator:pop_beats()
    local beats = self.state.queue
    self.state.queue = {}
    return beats
end

--- Peek at the queue without clearing.
function Narrator:peek_beats()
    return self.state.queue
end

--- Get active story arcs for this narrator.
function Narrator:get_active_arcs()
    return Chains.get_active_summaries(self.state.active_chains)
end

--- Manually inject a beat into this narrator.
function Narrator:inject(text, opts)
    opts = opts or {}
    local clock = self.engine.game_state.clock or {}
    self:_emit_beat({
        template_id = opts.template_id or "custom_" .. (clock.total_days or 0),
        text = text,
        display_hint = opts.display_hint or "panel",
        priority = opts.priority or 60,
        tags = opts.tags or {"custom"},
    }, clock)
end

--- Serialize this narrator's state.
function Narrator:serialize()
    return {
        channel = self.channel,
        active_chains = self.state.active_chains,
        memory = self.state.memory,
        queue = self.state.queue,
    }
end

--- Restore this narrator's state.
function Narrator:deserialize(data)
    if not data then return end
    self.state.active_chains = data.active_chains or {}
    self.state.memory = data.memory or Memory.create()
    self.state.queue = data.queue or {}
end

return Narrator
