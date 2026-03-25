-- dredwork Signals — Module Entry
-- Translates simulation state into human-readable observations.
-- The player never sees numbers. They see the world through their character's eyes.
-- How much they notice depends on WHO THEY ARE — personality, role, and experience.
--
-- Three clarity levels:
--   clear  — you understand exactly what it means
--   vague  — you notice something but can't place it
--   missed — it happened but you never see it (that's the point)

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local MoodLib = require("dredwork_agency.mood")
local Affinity = require("dredwork_signals.affinity")
local ClarityLib = require("dredwork_signals.clarity")
local SignalChains = require("dredwork_signals.chains")
local Readable = require("dredwork_signals.readable")
local Verification = require("dredwork_signals.verification")

local Signals = {}
Signals.__index = Signals

function Signals.init(engine)
    local self = setmetatable({}, Signals)
    self.engine = engine

    engine.game_state.signals = {
        active = {},
        history = {},
        pending_verifications = {},
    }

    engine:on("NEW_DAY", function(clock)
        self:generate(self.engine.game_state, clock)
        self:tick_readable(self.engine.game_state, clock)
    end)

    -- Train affinity when player performs interactions
    engine:on("INTERACTION_PERFORMED", function(ctx)
        if not ctx then return end
        local entities = engine:get_module("entities")
        if not entities then return end
        local focal = entities:get_focus()
        if focal and focal.components.signal_affinity and ctx.actor_id == focal.id then
            Affinity.train_from_interaction(focal.components.signal_affinity, ctx.category or "")
        end
    end)

    -- Train affinity when player moves to a location
    engine:on("ENTITY_MOVED_LOCAL", function(ctx)
        if not ctx then return end
        local entities = engine:get_module("entities")
        if not entities then return end
        local focal = entities:get_focus()
        if not focal or ctx.entity_id ~= focal.id then return end
        if focal.components.signal_affinity then
            local loc = engine:get_module("locations")
            if loc then
                local location = loc:get_location(ctx.to)
                if location then
                    Affinity.train_from_location(focal.components.signal_affinity, location.type)
                end
            end
        end
    end)

    -- Monthly: decay unused affinity, expire old verifications
    engine:on("NEW_MONTH", function(clock)
        local entities = engine:get_module("entities")
        if not entities then return end
        local focal = entities:get_focus()
        if focal and focal.components.signal_affinity then
            Affinity.decay(focal.components.signal_affinity)
        end
        local day = clock and clock.total_days or 0
        local pending = self.engine.game_state.signals.pending_verifications
        for i = #pending, 1, -1 do
            if Verification.is_expired(pending[i], day) then table.remove(pending, i) end
        end
    end)

    engine:on("GET_SIGNALS", function(req)
        req.signals = self.engine.game_state.signals.active
        req.pending_verifications = self.engine.game_state.signals.pending_verifications
    end)

    return self
end

--------------------------------------------------------------------------------
-- Signal Generation
--------------------------------------------------------------------------------

function Signals:generate(gs, clock)
    local entities = self.engine:get_module("entities")
    if not entities then return end
    local focal = entities:get_focus()
    if not focal or not focal.alive then return end
    local day = clock and clock.total_days or 0

    -- Initialize affinity if missing
    if not focal.components.signal_affinity then
        local role = nil
        local roles_mod = self.engine:get_module("roles")
        if roles_mod then
            local held = roles_mod:get_entity_roles(focal.id)
            if #held > 0 then role = held[1].role_id end
        end
        focal.components.signal_affinity = Affinity.create(focal.components.personality, role)
    end

    local aff = focal.components.signal_affinity
    local signals = {}
    local pending = gs.signals.pending_verifications

    local function try_signal(domain, severity, format_arg, extra)
        local clarity, score = Affinity.get_clarity(aff, domain)
        if clarity == "missed" then return end

        local text = ClarityLib.get_text(domain, severity, clarity, format_arg)
        local signal = {
            type = clarity == "clear" and "observed" or "vague",
            clarity = clarity,
            category = domain,
            severity = severity,
            text = text,
            score = math.floor(score),
            day = day,
            verifiable = clarity == "vague",
        }
        if extra then for k, v in pairs(extra) do signal[k] = v end end
        table.insert(signals, signal)

        if clarity == "vague" then
            table.insert(pending, Verification.create(signal, day))
            while #pending > 8 do table.remove(pending, 1) end
        end
    end

    -- ECONOMY
    if gs.markets then
        for rid, m in pairs(gs.markets) do
            local f = m.prices and m.prices.food or 5
            if f > 12 then try_signal("economy", f > 18 and "critical" or "warning", rid)
            elseif f < 4 then try_signal("economy", "positive", rid) end
        end
    end

    -- POLITICS
    if gs.politics then
        local u = gs.politics.unrest or 0
        local l = gs.politics.legitimacy or 50
        if u > 60 then try_signal("politics", "critical") elseif u > 35 then try_signal("politics", "warning") end
        if l < 30 then try_signal("politics", "warning") elseif l > 80 then try_signal("politics", "positive") end
    end

    -- MILITARY
    if gs.military then
        if (gs.military.total_power or 0) < 50 then try_signal("military", "warning") end
        for _, unit in ipairs(gs.military.units or {}) do
            if (unit.morale or 50) < 30 then try_signal("military", "warning"); break end
        end
    end

    -- COURT LOYALTY
    if gs.court and gs.court.members then
        for _, m in ipairs(gs.court.members) do
            if m.status ~= "active" then goto s1 end
            if m.loyalty < 25 then try_signal("loyalty", "critical", m.name, { entity_id = m.entity_id })
            elseif m.loyalty < 40 then try_signal("loyalty", "warning", m.name, { entity_id = m.entity_id })
            elseif m.loyalty > 85 then try_signal("loyalty", "positive", m.name, { entity_id = m.entity_id }) end
            ::s1::
        end
    end

    -- RIVALS
    if gs.rivals and gs.rivals.houses then
        for _, h in ipairs(gs.rivals.houses) do
            if h.status ~= "active" or not h.heir then goto s2 end
            if h.heir.attitude == "hostile" then
                try_signal("rivals", (h.resources.steel or 0) > 25 and "critical" or "warning", h.name)
            elseif h.heir.attitude == "devoted" then
                try_signal("rivals", "positive", h.name)
            end
            ::s2::
        end
    end

    -- CRIME
    if gs.underworld and (gs.underworld.global_corruption or 0) > 40 then try_signal("crime", "warning") end

    -- RELIGION
    if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
        if (gs.religion.active_faith.attributes.zeal or 50) > 75 then try_signal("religion", "warning") end
        if (gs.religion.active_faith.attributes.tolerance or 50) < 25 then try_signal("religion", "warning") end
    end

    -- PERIL
    if gs.perils and gs.perils.active then
        for _, p in ipairs(gs.perils.active) do
            try_signal("peril", p.category == "disease" and "critical" or "warning")
        end
    end

    -- NATURE
    if gs.animals and gs.animals.regional_populations then
        for _, pops in pairs(gs.animals.regional_populations) do
            for sp, pop in pairs(pops) do
                if pop.density > 50 and sp ~= "rats" then try_signal("nature", "warning"); goto done_nature end
            end
        end
        ::done_nature::
    end

    -- HOME
    if gs.home and gs.home.attributes then
        if (gs.home.attributes.condition or 50) < 30 then try_signal("domestic", "warning") end
        if (gs.home.attributes.comfort or 50) > 80 then try_signal("domestic", "positive") end
    end

    -- SELF (always visible — you always feel your own body)
    local needs = focal.components.needs
    if needs then
        if (needs.safety or 50) < 20 then try_signal("self", "critical") end
        if (needs.belonging or 50) < 20 then try_signal("self", "warning") end
        if (needs.purpose or 50) < 20 then try_signal("self", "warning") end
    end

    -- SECRETS
    if focal.components.secrets and focal.components.secrets.known then
        for _, secret in ipairs(focal.components.secrets.known) do
            if RNG.chance(0.15) then
                local subject = entities:get(secret.subject_id)
                if subject and subject.alive then
                    try_signal("secrets", "warning", subject.name, { entity_id = secret.subject_id })
                end
            end
        end
    end

    -- Limit to 4 signals per day (prioritize critical, then highest score)
    table.sort(signals, function(a, b)
        local a_crit = a.severity == "critical" and 100 or 0
        local b_crit = b.severity == "critical" and 100 or 0
        return (a_crit + (a.score or 0)) > (b_crit + (b.score or 0))
    end)
    while #signals > 4 do table.remove(signals) end

    gs.signals.active = signals
    for _, s in ipairs(signals) do table.insert(gs.signals.history, s) end
    while #gs.signals.history > 30 do table.remove(gs.signals.history, 1) end

    -- Emit for narrative
    for _, signal in ipairs(signals) do
        self.engine:emit("SIGNAL_OBSERVED", signal)
        self.engine:push_ui_event("NARRATIVE_BEAT", {
            channel = "whispers",
            text = signal.text,
            priority = signal.severity == "critical" and 65 or (signal.severity == "positive" and 35 or 50),
            display_hint = signal.clarity == "vague" and "signal_vague" or "signal",
            tags = { "signal", signal.category, signal.clarity },
            timestamp = day,
        })
    end
end

--------------------------------------------------------------------------------
-- Verification API
--------------------------------------------------------------------------------

function Signals:verify(verification_index, method)
    local gs = self.engine.game_state
    local pending = gs.signals.pending_verifications
    local v = pending[verification_index]
    if not v then return false, "Nothing to verify." end

    local entities = self.engine:get_module("entities")
    local focal = entities and entities:get_focus()
    local affinity_score = 50
    if focal and focal.components.signal_affinity and v.signal and v.signal.category then
        affinity_score = focal.components.signal_affinity[v.signal.category] or 30
    end

    local success, text = Verification.attempt(v, method, affinity_score)
    local chain_signal = nil

    if v.status ~= "unverified" then
        table.remove(pending, verification_index)
        if v.status == "verified_true" and focal then
            -- Train affinity
            if focal.components.signal_affinity then
                Affinity.train(focal.components.signal_affinity, v.signal.category, 3)
            end

            -- TRY CHAIN: verified signal may open a deeper thread
            local day = gs.clock and gs.clock.total_days or 0
            chain_signal = SignalChains.try_chain(v.signal, focal, day)

            if chain_signal then
                -- Add chain signal to active and emit
                table.insert(gs.signals.active, chain_signal)
                table.insert(gs.signals.history, chain_signal)

                -- If vague, add to pending verifications
                if chain_signal.verifiable then
                    table.insert(pending, Verification.create(chain_signal, day))
                end

                -- Emit the chain signal as a narrative beat
                self.engine:emit("SIGNAL_CHAIN_OPENED", chain_signal)
                self.engine:push_ui_event("NARRATIVE_BEAT", {
                    channel = "whispers",
                    text = chain_signal.text,
                    priority = chain_signal.severity == "critical" and 70 or 55,
                    display_hint = chain_signal.clarity == "vague" and "signal_vague" or "signal",
                    tags = { "signal", "chain", chain_signal.category, chain_signal.clarity },
                    timestamp = day,
                })

                text = text .. "\n\nBut that's not all — " .. chain_signal.text
            end
        end
    end

    return success, text, chain_signal
end

--------------------------------------------------------------------------------
-- Bidirectional: NPCs read the focal entity
--------------------------------------------------------------------------------

function Signals:tick_readable(gs, clock)
    local entities = self.engine:get_module("entities")
    if not entities then return end
    local focal = entities:get_focus()
    if not focal or not focal.alive then return end
    local day = clock and clock.total_days or 0

    -- Check nearby entities (same location) for readers
    local nearby = {}
    local focal_loc = focal.components.location and focal.components.location.region_id
    if focal_loc then nearby = entities:find_at_location(focal_loc) end

    for _, reader in ipairs(nearby) do
        if reader.id == focal.id or not reader.alive then goto skip_reader end
        if not reader.components.personality then goto skip_reader end

        -- Low probability per entity per day
        if not RNG.chance(0.08) then goto skip_reader end

        local signal = Readable.npc_reads_you(reader, focal)
        if signal then
            -- The NPC noticed something about you
            Readable.react_to_reading(reader, signal, self.engine)

            -- Emit as narrative (the player feels the gaze)
            self.engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = signal.text,
                priority = signal.severity == "critical" and 60 or 45,
                display_hint = "signal",
                tags = { "signal", "readable", signal.what },
                timestamp = day,
            })
        end

        ::skip_reader::
    end
end

function Signals:get_pending() return self.engine.game_state.signals.pending_verifications end
function Signals:get_active() return self.engine.game_state.signals.active end

function Signals:serialize() return self.engine.game_state.signals end
function Signals:deserialize(data) self.engine.game_state.signals = data end

return Signals
