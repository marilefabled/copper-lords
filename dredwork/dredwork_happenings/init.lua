-- dredwork Happenings — Module Entry
-- Things that happen TO you. The world acting on the player.
-- Options are gated by what you've perceived through signals.
-- A stranger knocks. A body is found. A letter arrives. A fire starts.
-- What you CAN DO about it depends on what you NOTICED.
--
-- Happenings bridge the gap between passive signals and active decisions.
-- They're the game loop: Signal → Happening → Response → Consequence.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local Affinity = require("dredwork_signals.affinity")

local Happenings = {}
Happenings.__index = Happenings

function Happenings.init(engine)
    local self = setmetatable({}, Happenings)
    self.engine = engine
    self.catalog = require("dredwork_happenings.catalog")

    engine.game_state.happenings = {
        current = nil,      -- the active happening awaiting response
        history = {},       -- past happenings and how they were resolved
        cooldowns = {},     -- happening_id → earliest_eligible_day
    }

    -- Generate happenings based on world state (checked each time slot / day)
    engine:on("NEW_DAY", function(clock)
        self:try_generate(self.engine.game_state, clock)
    end)

    -- Query handler
    engine:on("GET_HAPPENING", function(req)
        req.happening = self.engine.game_state.happenings.current
    end)

    -- Injection point: other modules can push happenings directly
    engine:on("HAPPENING_INJECT", function(ctx)
        if not ctx or not ctx.happening_def then return end
        local gs = self.engine.game_state
        if gs.happenings.current then return end  -- don't override active happening

        local entities_mod = engine:get_module("entities")
        local focal = entities_mod and entities_mod:get_focus()
        if not focal then return end

        local aff = focal.components.signal_affinity or {}
        local day = gs.clock and gs.clock.total_days or 0
        self:_present(ctx.happening_def, gs, focal, aff, day)
    end)

    return self
end

--------------------------------------------------------------------------------
-- Generation
--------------------------------------------------------------------------------

function Happenings:try_generate(gs, clock)
    -- Don't generate if one is already pending
    if gs.happenings.current then return end

    local day = clock and clock.total_days or 0
    local entities = self.engine:get_module("entities")
    if not entities then return end
    local focal = entities:get_focus()
    if not focal or not focal.alive then return end

    -- Get focal entity's signal affinity for option gating
    local aff = focal.components.signal_affinity or {}

    -- Get current location for context
    local loc_type = nil
    local locations = self.engine:get_module("locations")
    if locations then
        local loc = locations:get_entity_location(focal.id)
        if loc then loc_type = loc.type end
    end

    -- Try each happening in the catalog against current conditions
    local candidates = {}
    for _, happening_def in ipairs(self.catalog) do
        -- Cooldown check
        if gs.happenings.cooldowns[happening_def.id] and day < gs.happenings.cooldowns[happening_def.id] then
            goto skip
        end

        -- Condition check
        if happening_def.condition and not happening_def.condition(gs, focal, loc_type) then
            goto skip
        end

        -- Probability gate
        if not RNG.chance(happening_def.chance or 0.05) then
            goto skip
        end

        table.insert(candidates, happening_def)
        ::skip::
    end

    if #candidates == 0 then return end

    -- Pick one
    local def = RNG.pick(candidates)
    self:_present(def, gs, focal, aff, day)
end

--- Build and present a happening.
function Happenings:_present(def, gs, focal, aff, day)
    -- Build the happening instance
    local happening = {
        id = def.id,
        title = def.title,
        text = type(def.text) == "table" and RNG.pick(def.text) or def.text,
        category = def.category,
        options = {},
        day = day,
    }

    -- Build options — filter by signal affinity
    for _, opt_def in ipairs(def.options) do
        local available = true
        local reason = nil

        -- Signal affinity gate: you can only choose this if you noticed enough
        if opt_def.requires_affinity then
            local domain = opt_def.requires_affinity.domain
            local min_score = opt_def.requires_affinity.min or 40
            local player_score = aff[domain] or 0

            if player_score < min_score then
                available = false
                reason = "You haven't noticed enough about " .. domain .. " to see this option."
            end
        end

        -- Personality gate
        if opt_def.requires_personality and available then
            local p = focal.components.personality or {}
            for axis, min_val in pairs(opt_def.requires_personality) do
                local val = p[axis] or 50
                if type(val) == "table" then val = val.value or 50 end
                if val < min_val then
                    available = false
                    reason = "Your character wouldn't consider this."
                    break
                end
            end
        end

        -- Location gate
        if opt_def.requires_location and available then
            local loc = opt_def.requires_location
            if type(loc) == "string" then
                local locations_mod = self.engine:get_module("locations")
                if locations_mod then
                    local current = locations_mod:get_entity_location(focal.id)
                    if not current or current.type ~= loc then
                        available = false
                    end
                end
            end
        end

        -- Wealth gate
        if opt_def.requires_gold and available then
            local pw = focal.components.personal_wealth
            if not pw or pw.gold < opt_def.requires_gold then
                available = false
                reason = "You can't afford this."
            end
        end

        -- Claim gate: some options only available if your claim is known/hidden
        if opt_def.requires_claim_status and available then
            local claim_status = gs.claim and gs.claim.status or "hidden"
            if claim_status ~= opt_def.requires_claim_status then
                available = false
            end
        end

        local option = {
            id = opt_def.id,
            label = opt_def.label,
            description = opt_def.description,
            available = available,
            unavailable_reason = reason,
            consequences = opt_def.consequences,
            tags = opt_def.tags or {},
        }

        table.insert(happening.options, option)
    end

    -- Store as current happening
    gs.happenings.current = happening

    -- Set cooldown
    gs.happenings.cooldowns[def.id] = day + (def.cooldown_days or 30)

    -- Emit
    self.engine:emit("HAPPENING_PRESENTED", happening)
    self.engine:push_ui_event("HAPPENING_PRESENTED", happening)
    self.engine.log:info("Happening: %s", happening.title)
end

--------------------------------------------------------------------------------
-- Response
--------------------------------------------------------------------------------

--- Player responds to the current happening.
---@param option_id string which option they chose
---@return table result { success, text, consequences }
function Happenings:respond(option_id)
    local gs = self.engine.game_state
    local happening = gs.happenings.current
    if not happening then return { success = false, text = "Nothing to respond to." } end

    -- Find the option
    local option = nil
    for _, opt in ipairs(happening.options) do
        if opt.id == option_id then option = opt; break end
    end
    if not option then return { success = false, text = "Unknown option." } end
    if not option.available then return { success = false, text = option.unavailable_reason or "Not available." } end

    -- Apply consequences
    local result_text = self:_apply_consequences(option.consequences or {}, gs)

    -- Record in history
    table.insert(gs.happenings.history, {
        happening_id = happening.id,
        title = happening.title,
        option_chosen = option_id,
        option_label = option.label,
        day = happening.day,
        result = result_text,
    })
    while #gs.happenings.history > 20 do table.remove(gs.happenings.history, 1) end

    -- Clear current
    gs.happenings.current = nil

    -- Emit
    self.engine:emit("HAPPENING_RESOLVED", {
        happening_id = happening.id,
        option_id = option_id,
        text = result_text,
    })
    self.engine:push_ui_event("HAPPENING_RESOLVED", {
        text = result_text,
    })

    return { success = true, text = result_text }
end

--- Apply consequence list.
function Happenings:_apply_consequences(consequences, gs)
    local texts = {}
    local entities = self.engine:get_module("entities")
    local focal = entities and entities:get_focus()

    for _, c in ipairs(consequences) do
        if c.type == "text" then
            table.insert(texts, c.value)

        elseif c.type == "gold" and focal and focal.components.personal_wealth then
            local WealthLib = require("dredwork_agency.wealth")
            WealthLib.change(focal.components.personal_wealth, c.delta, c.reason or "happening")

        elseif c.type == "need" and focal and focal.components.needs then
            focal.components.needs[c.need] = Math.clamp((focal.components.needs[c.need] or 50) + c.delta, 0, 100)

        elseif c.type == "suspicion" and gs.claim then
            gs.claim.suspicion = Math.clamp((gs.claim.suspicion or 0) + c.delta, 0, 100)

        elseif c.type == "relationship" and entities and focal then
            -- Find a relevant entity
            if c.target == "random_nearby" then
                local nearby = entities:find_at_location(focal.components.location and focal.components.location.region_id or "")
                if #nearby > 1 then
                    local other = nearby[1].id == focal.id and nearby[2] or nearby[1]
                    entities:shift_relationship(focal.id, other.id, c.rel_type or "trust", c.delta or 5)
                end
            end

        elseif c.type == "rumor" then
            local rumor = self.engine:get_module("rumor")
            if rumor then
                rumor:inject(gs, {
                    origin_type = "happening", subject = c.subject or "someone",
                    text = c.rumor_text or "Something happened.", heat = c.heat or 40,
                    tags = c.tags or {},
                })
            end

        elseif c.type == "item" and focal then
            local inv = self.engine:get_module("inventory")
            if inv then
                local Inv = require("dredwork_inventory")
                local item = Inv.create_item(c.item_spec)
                inv:give(focal.id, item)
            end

        elseif c.type == "affinity_train" and focal and focal.components.signal_affinity then
            Affinity.train(focal.components.signal_affinity, c.domain, c.amount or 2)

        elseif c.type == "legitimacy" then
            self.engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = c.delta })
        end
    end

    return table.concat(texts, " ")
end

function Happenings:get_current() return self.engine.game_state.happenings.current end
function Happenings:get_history() return self.engine.game_state.happenings.history end

function Happenings:serialize() return self.engine.game_state.happenings end
function Happenings:deserialize(data) self.engine.game_state.happenings = data end

return Happenings
