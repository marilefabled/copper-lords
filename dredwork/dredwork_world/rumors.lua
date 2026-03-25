-- Dark Legacy — Rumors & Gossip System
-- Generates rumors from faction relation shifts, world events, and heir actions.
-- Some true (foreshadow events), some false (misinformation).
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Rumors = {}
Rumors.__index = Rumors

--- Create a new rumors tracker.
---@return table Rumors instance
function Rumors.new()
    local self = setmetatable({}, Rumors)
    self.active = {}
    self.expired = {}
    return self
end

--- Generate rumors for this generation based on world state.
---@param context table { faction_relations, factions, world_state, heir_personality, generation }
---@return table array of new rumors generated
function Rumors:generate(context)
    local new_rumors = {}
    local generation = context.generation or 0

    -- 1. Faction-relation-driven rumors
    if context.faction_relations then
        local tense_pairs = context.faction_relations:get_pairs_by_state("hostile")
        for _, pair in ipairs(tense_pairs) do
            if rng.chance(0.3) then
                local fa = context.factions and context.factions:get(pair.faction_a)
                local fb = context.factions and context.factions:get(pair.faction_b)
                if fa and fb then
                    new_rumors[#new_rumors + 1] = self:_create_rumor({
                        text = fa.name .. " musters soldiers on the border with " .. fb.name .. ".",
                        source_faction = pair.faction_a,
                        target_faction = pair.faction_b,
                        generation = generation,
                        reliability = 0.7,
                        category = "faction_tension",
                    })
                end
            end
        end

        local allied_pairs = context.faction_relations:get_pairs_by_state("allied")
        for _, pair in ipairs(allied_pairs) do
            if rng.chance(0.2) then
                local fa = context.factions and context.factions:get(pair.faction_a)
                local fb = context.factions and context.factions:get(pair.faction_b)
                if fa and fb then
                    new_rumors[#new_rumors + 1] = self:_create_rumor({
                        text = "A secret pact between " .. fa.name .. " and " .. fb.name .. " grows stronger.",
                        source_faction = pair.faction_a,
                        target_faction = pair.faction_b,
                        generation = generation,
                        reliability = 0.6,
                        category = "faction_alliance",
                    })
                end
            end
        end

        -- Rumors from autonomous faction events
        for _, evt in ipairs(context.faction_relations.events_log or {}) do
            local fa = context.factions and context.factions:get(evt.faction_a)
            local fb = context.factions and context.factions:get(evt.faction_b)
            if fa and fb then
                new_rumors[#new_rumors + 1] = self:_create_rumor({
                    text = fa.name .. " and " .. fb.name .. " " .. (evt.description or "stir"),
                    source_faction = evt.faction_a,
                    target_faction = evt.faction_b,
                    generation = generation,
                    reliability = 0.85,
                    category = "faction_event",
                })
            end
        end
    end

    -- 2. World-condition-driven rumors
    if context.world_state then
        local conditions = context.world_state.conditions or {}
        for _, cond in ipairs(conditions) do
            if cond.remaining_gens and cond.remaining_gens <= 1 and rng.chance(0.4) then
                new_rumors[#new_rumors + 1] = self:_create_rumor({
                    text = "The " .. cond.type .. " may be coming to an end.",
                    generation = generation,
                    reliability = 0.5,
                    category = "world_condition",
                })
            end
        end

        -- Rare false rumors
        if rng.chance(0.1) then
            local false_conditions = { "plague", "war", "famine" }
            local false_type = false_conditions[rng.range(1, #false_conditions)]
            if not context.world_state:has_condition(false_type) then
                new_rumors[#new_rumors + 1] = self:_create_rumor({
                    text = "Whispers of " .. false_type .. " spread from the eastern reaches.",
                    generation = generation,
                    reliability = 0.2,
                    category = "false_alarm",
                })
            end
        end
    end

    -- 3. Faction power shift rumors
    if context.factions then
        local active = context.factions:get_active()
        for _, f in ipairs(active) do
            if f.power >= 80 and rng.chance(0.3) then
                new_rumors[#new_rumors + 1] = self:_create_rumor({
                    text = f.name .. " grows dangerously powerful. Some speak of empire.",
                    source_faction = f.id,
                    generation = generation,
                    reliability = 0.8,
                    category = "faction_power",
                })
            elseif f.power <= 20 and rng.chance(0.3) then
                new_rumors[#new_rumors + 1] = self:_create_rumor({
                    text = f.name .. " teeters on the edge of collapse.",
                    source_faction = f.id,
                    generation = generation,
                    reliability = 0.75,
                    category = "faction_weakness",
                })
            end
        end
    end

    -- 4. Heir-driven rumors
    if context.heir_genome then
        if (context.heir_genome:get_value("PHY_STR") or 50) >= 80 and rng.chance(0.25) then
            new_rumors[#new_rumors + 1] = self:_create_rumor({
                text = "Tales of the heir's impossible strength are spreading through the taverns.",
                generation = generation,
                reliability = 0.9,
                category = "heir_action",
            })
        end
        if (context.heir_genome:get_value("MEN_INT") or 50) >= 80 and rng.chance(0.25) then
            new_rumors[#new_rumors + 1] = self:_create_rumor({
                text = "The realm whispers of the heir's unnatural intellect. Some call it a gift, others a curse.",
                generation = generation,
                reliability = 0.9,
                category = "heir_action",
            })
        end
        if (context.heir_genome:get_value("MEN_COM") or 50) <= 25 and rng.chance(0.25) then
            new_rumors[#new_rumors + 1] = self:_create_rumor({
                text = "Whispers of madness follow the heir's every step.",
                generation = generation,
                reliability = 0.6,
                category = "heir_action",
            })
        end
    end

    -- Add to active, cap at 5 active rumors
    for _, r in ipairs(new_rumors) do
        self.active[#self.active + 1] = r
    end
    self:_prune(generation)

    return new_rumors
end

--- Get active rumors for display.
---@param max number|nil max rumors to return (default 3)
---@param heir_perception number|nil heir's MEN_PER value for reliability hints
---@return table array of { text, reliability_hint, category }
function Rumors:get_display(max, heir_perception)
    max = max or 3
    local result = {}
    local count = 0
    for i = #self.active, 1, -1 do
        if count >= max then break end
        local r = self.active[i]
        local hint = nil
        if heir_perception and heir_perception >= 70 then
            if r.reliability >= 0.7 then
                hint = "likely true"
            elseif r.reliability <= 0.3 then
                hint = "dubious"
            end
        end
        result[#result + 1] = {
            text = r.text,
            reliability_hint = hint,
            category = r.category,
        }
        count = count + 1
    end
    return result
end

--- Get active rumors (convenience for scene display).
---@param generation number|nil current generation (used for pruning)
---@return table array of rumor objects
function Rumors:get_active(generation)
    if generation then self:_prune(generation) end
    return self.active
end

--- Get rumors involving a specific faction.
---@param faction_id string
---@return table array of rumor objects
function Rumors:get_for_faction(faction_id)
    local result = {}
    for _, r in ipairs(self.active) do
        if r.source_faction == faction_id or r.target_faction == faction_id then
            result[#result + 1] = r
        end
    end
    return result
end

--- Tick: expire old rumors.
---@param generation number
function Rumors:tick(generation)
    self:_prune(generation)
end

--- Serialize to plain table.
---@return table
function Rumors:to_table()
    return {
        active = self.active,
    }
end

--- Restore from saved table.
---@param data table
---@return table Rumors
function Rumors.from_table(data)
    local self = setmetatable({}, Rumors)
    self.active = data and data.active or {}
    self.expired = {}
    return self
end

-- =========================================================================
-- Internal helpers
-- =========================================================================

function Rumors:_create_rumor(data)
    return {
        text = data.text or "",
        source_faction = data.source_faction,
        target_faction = data.target_faction,
        generation = data.generation or 0,
        reliability = data.reliability or 0.5,
        category = data.category or "general",
        revealed = false,
    }
end

function Rumors:_prune(generation)
    -- Remove rumors older than 3 generations, cap at 5
    local live = {}
    for _, r in ipairs(self.active) do
        if (generation - r.generation) < 3 then
            live[#live + 1] = r
        end
    end
    -- Keep most recent 5
    while #live > 5 do
        table.remove(live, 1)
    end
    self.active = live
end

return Rumors
