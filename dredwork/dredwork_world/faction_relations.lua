local Math = require("dredwork_core.math")
-- Dark Legacy — Inter-Faction Relations Matrix
-- Tracks disposition between all faction pairs. Drives autonomous faction events.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local FactionRelations = {}
FactionRelations.__index = FactionRelations

--- Create a new faction relations matrix from active factions.
---@param factions table array of faction objects (or FactionManager)
---@return table FactionRelations instance
function FactionRelations.new(factions)
    local self = setmetatable({}, FactionRelations)
    self.relations = {}  -- keyed by "id_a:id_b" (alphabetically sorted)
    self.events_log = {} -- recent autonomous events for display

    -- Initialize from faction list
    local faction_list = factions
    if factions.get_all then
        faction_list = factions:get_all()
    end

    for i = 1, #faction_list do
        for j = i + 1, #faction_list do
            local a = faction_list[i]
            local b = faction_list[j]
            local key = FactionRelations._make_key(a.id, b.id)
            -- Seed initial disposition from personality similarity
            local base = FactionRelations._seed_disposition(a, b)
            self.relations[key] = {
                disposition = base,
                history = {},
            }
        end
    end

    return self
end

--- Get the relation between two factions.
---@param faction_a_id string
---@param faction_b_id string
---@return table|nil { disposition, history }
function FactionRelations:get(faction_a_id, faction_b_id)
    local key = FactionRelations._make_key(faction_a_id, faction_b_id)
    return self.relations[key]
end

--- Get disposition between two factions (convenience).
---@param faction_a_id string
---@param faction_b_id string
---@return number disposition (-100 to 100), 0 if unknown
function FactionRelations:get_disposition(faction_a_id, faction_b_id)
    local rel = self:get(faction_a_id, faction_b_id)
    return rel and rel.disposition or 0
end

--- Shift disposition between two factions.
---@param faction_a_id string
---@param faction_b_id string
---@param delta number
---@param reason string
---@param generation number
function FactionRelations:shift(faction_a_id, faction_b_id, delta, reason, generation)
    local key = FactionRelations._make_key(faction_a_id, faction_b_id)
    local rel = self.relations[key]
    if not rel then
        rel = { disposition = 0, history = {} }
        self.relations[key] = rel
    end

    rel.disposition = Math.clamp(rel.disposition + delta, -100, 100)

    -- Search recent history (last 5 entries) for same generation and reason
    local match = nil
    for i = #rel.history, math.max(1, #rel.history - 4), -1 do
        local entry = rel.history[i]
        if entry.generation == generation and entry.reason == reason then
            match = entry
            break
        end
    end

    if match then
        match.delta = match.delta + delta
    else
        rel.history[#rel.history + 1] = {
            delta = delta,
            reason = reason,
            generation = generation,
        }
    end

    -- Keep history manageable
    if #rel.history > 20 then
        local trimmed = {}
        for i = #rel.history - 19, #rel.history do
            trimmed[#trimmed + 1] = rel.history[i]
        end
        rel.history = trimmed
    end
end

--- Tick all relations: decay toward 0, check thresholds for autonomous events.
---@param generation number
---@param factions table FactionManager (for faction names)
---@param rumors table|nil Rumors instance
---@return table autonomous_events array of { type, faction_a, faction_b, description }
function FactionRelations:tick(generation, factions, rumors)
    local autonomous_events = {}

    for key, rel in pairs(self.relations) do
        local old_disp = rel.disposition
        local a_id, b_id = key:match("^(.+):(.+)$")

        -- Base decay rate
        local decay_rate = 0.98 -- 2% decay toward 0

        -- Rumor influence on decay
        if rumors then
            for _, r in ipairs(rumors:get_active(generation)) do
                if (r.source_faction == a_id and r.target_faction == b_id) or
                   (r.source_faction == b_id and r.target_faction == a_id) then
                    if r.category == "faction_tension" then
                        -- Tension rumors accelerate negative drift / resist positive recovery
                        if rel.disposition > 0 then decay_rate = 0.95 -- faster decay of friendship
                        else decay_rate = 1.02 -- actually grows more hostile
                        end
                    elseif r.category == "faction_alliance" then
                        -- Alliance rumors resist negative decay
                        if rel.disposition < 0 then decay_rate = 0.95 -- faster recovery toward neutral
                        else decay_rate = 1.01 -- slightly strengthens friendship
                        end
                    end
                end
            end
        end

        -- Apply decay/drift
        if rel.disposition > 0 then
            rel.disposition = rel.disposition * decay_rate
            if rel.disposition < 0.5 then rel.disposition = 0 end
        elseif rel.disposition < 0 then
            rel.disposition = rel.disposition * decay_rate
            if rel.disposition > -0.5 then rel.disposition = 0 end
        end
        
        -- Cap at [-100, 100] in case of drift growth
        rel.disposition = Math.clamp(rel.disposition, -100, 100)

        -- Check threshold crossings for autonomous events
        local a_id, b_id = key:match("^(.+):(.+)$")

        -- Alliance formed
        if rel.disposition > 60 and old_disp <= 60 then
            autonomous_events[#autonomous_events + 1] = {
                type = "faction_alliance_formed",
                faction_a = a_id,
                faction_b = b_id,
                description = "have formed an alliance",
            }
        end

        -- War declared
        if rel.disposition < -60 and old_disp >= -60 then
            autonomous_events[#autonomous_events + 1] = {
                type = "faction_war_declared",
                faction_a = a_id,
                faction_b = b_id,
                description = "have gone to war",
            }
        end

        -- Inter-Faction Warfare Simulation (Phase 1)
        if factions and rel.disposition < -60 then
            local fa = factions:get(a_id)
            local fb = factions:get(b_id)

            if fa and fb and fa.status ~= "fallen" and fb.status ~= "fallen" then
                -- War logic: stronger house often wins, but RNG matters
                local a_strength = (fa.power or 50) + rng.range(-15, 15)
                local b_strength = (fb.power or 50) + rng.range(-15, 15)

                if a_strength > b_strength then
                    -- House A wins a skirmish
                    local shift = rng.range(2, 6)
                    fa:shift_power(shift)
                    fb:shift_power(-shift - 2) -- Loser loses more
                    -- Wealth transfer (plunder)
                    fa.power = math.min(100, fa.power) -- already capped in shift_power
                    autonomous_events[#autonomous_events + 1] = {
                        type = "faction_skirmish",
                        faction_a = a_id,
                        faction_b = b_id,
                        description = "defeated " .. fb.name .. " in a bloody skirmish",
                    }
                else
                    -- House B wins a skirmish
                    local shift = rng.range(2, 6)
                    fb:shift_power(shift)
                    fa:shift_power(-shift - 2)
                    autonomous_events[#autonomous_events + 1] = {
                        type = "faction_skirmish",
                        faction_a = b_id,
                        faction_b = a_id,
                        description = "defeated " .. fa.name .. " in a bloody skirmish",
                    }
                end
            end
        end

        -- Rumor-worthy shift (crossing ±40)
        if (rel.disposition > 40 and old_disp <= 40) or
           (rel.disposition < -40 and old_disp >= -40) then
            autonomous_events[#autonomous_events + 1] = {
                type = "faction_tension_shift",
                faction_a = a_id,
                faction_b = b_id,
                description = rel.disposition > 0 and "grow closer" or "grow hostile",
            }
        end

        -- Active war/alliance effects: power shifts
        if factions then
            local fa = factions.get and factions:get(a_id)
            local fb = factions.get and factions:get(b_id)

            if fa and fb then
                if rel.disposition < -60 then
                    -- War: stronger faction gains, weaker loses
                    if fa.power > fb.power then
                        fa:shift_power(rng.range(0, 2))
                        fb:shift_power(-rng.range(1, 3))
                    else
                        fb:shift_power(rng.range(0, 2))
                        fa:shift_power(-rng.range(1, 3))
                    end
                elseif rel.disposition > 60 then
                    -- Alliance: both gain slight power
                    fa:shift_power(rng.range(0, 1))
                    fb:shift_power(rng.range(0, 1))
                end
            end
        end
    end

    -- Store recent events for rumor generation
    self.events_log = autonomous_events

    return autonomous_events
end

--- Get all faction pairs in a particular state.
---@param state string "allied" | "hostile" | "war" | "neutral"
---@return table array of { faction_a, faction_b, disposition }
function FactionRelations:get_pairs_by_state(state)
    local results = {}
    for key, rel in pairs(self.relations) do
        local a_id, b_id = key:match("^(.+):(.+)$")
        local match = false
        if state == "allied" and rel.disposition > 60 then match = true
        elseif state == "hostile" and rel.disposition < -40 then match = true
        elseif state == "war" and rel.disposition < -60 then match = true
        elseif state == "neutral" and math.abs(rel.disposition) <= 40 then match = true
        end
        if match then
            results[#results + 1] = {
                faction_a = a_id,
                faction_b = b_id,
                disposition = rel.disposition,
            }
        end
    end
    return results
end

--- Get the most tense (extreme disposition) faction pair.
---@return string|nil faction_a_id, string|nil faction_b_id, number disposition
function FactionRelations:get_most_tense()
    local best_key, best_abs = nil, 0
    for key, rel in pairs(self.relations) do
        local abs_d = math.abs(rel.disposition)
        if abs_d > best_abs then
            best_key = key
            best_abs = abs_d
        end
    end
    if not best_key then return nil, nil, 0 end
    local a_id, b_id = best_key:match("^(.+):(.+)$")
    return a_id, b_id, self.relations[best_key].disposition
end

--- Serialize to plain table.
---@return table
function FactionRelations:to_table()
    local result = {}
    for key, rel in pairs(self.relations) do
        result[key] = {
            disposition = rel.disposition,
            history = rel.history,
        }
    end
    return result
end

--- Restore from saved table.
---@param data table
---@return table FactionRelations
function FactionRelations.from_table(data)
    local self = setmetatable({}, FactionRelations)
    self.relations = {}
    self.events_log = {}
    if data then
        for key, rel in pairs(data) do
            self.relations[key] = {
                disposition = rel.disposition or 0,
                history = rel.history or {},
            }
        end
    end
    return self
end

-- =========================================================================
-- Internal helpers
-- =========================================================================

--- Make a canonical key for a faction pair (alphabetically sorted).
function FactionRelations._make_key(id_a, id_b)
    if id_a < id_b then
        return id_a .. ":" .. id_b
    else
        return id_b .. ":" .. id_a
    end
end

--- Seed initial disposition from personality similarity.
function FactionRelations._seed_disposition(faction_a, faction_b)
    local axes = { "PER_BLD", "PER_CRM", "PER_LOY", "PER_PRI" }
    local similarity = 0
    local count = 0
    for _, axis in ipairs(axes) do
        local va = faction_a.personality and faction_a.personality[axis] or 50
        local vb = faction_b.personality and faction_b.personality[axis] or 50
        similarity = similarity + (100 - math.abs(va - vb))
        count = count + 1
    end
    if count == 0 then return 0 end
    -- Map 0-100 similarity to -30..+30 range
    local avg = similarity / count
    return math.floor((avg - 50) * 0.6) + rng.range(-10, 10)
end

return FactionRelations
