-- Dark Legacy — Next-Gen Tease System
-- Generates 1-2 forward-looking hooks shown on Generation Advance,
-- creating immediate reason to press CONTINUE.
-- Differs from foreshadowing: teases hint at WORLD-level upcoming events,
-- not current heir vulnerabilities.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")
local narratives = require("dredwork_world.config.tease_narratives")

local Tease = {}

--- Pick a random entry from a pool (string array).
---@param pool table array of strings
---@return string
local function pick(pool)
    if not pool or #pool == 0 then return "" end
    return pool[rng.range(1, #pool)]
end

--- Generate tease lines for the generation advance screen.
--- Returns up to 2 forward-looking hooks about what the WORLD is about to do.
---@param context table { world_state, factions, cultural_memory, heir_genome, heir_personality, generation, bloodline_dream, mutation_pressure }
---@return table array of { text, color_key, icon_hint }
function Tease.generate(context)
    local candidates = {} -- { priority, text, color_key, icon_hint }

    local ws = context.world_state
    local factions = context.factions
    local cm = context.cultural_memory
    local genome = context.heir_genome
    local generation = context.generation or 1

    -- 1. Imminent condition: world trending toward plague/war/famine
    --    (no active condition of that type, but ambient pressure or era suggests it)
    if ws then
        local condition_types = { "plague", "war", "famine" }
        for _, ctype in ipairs(condition_types) do
            if not ws:has_condition(ctype) then
                -- Check if era ambient pressure includes this type
                local era = ws:get_era()
                if era and era.ambient_pressure then
                    for _, ap in ipairs(era.ambient_pressure) do
                        if ap.type == ctype and ap.intensity >= 0.3 then
                            local pool = narratives.imminent_condition[ctype]
                            if pool then
                                candidates[#candidates + 1] = {
                                    priority = 10,
                                    text = pick(pool),
                                    color_key = "dim_gold",
                                    icon_hint = "condition",
                                }
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    -- 2. Faction tension: hostile faction with power > 70
    if factions then
        local active = factions:get_active()
        for _, f in ipairs(active) do
            if f:is_hostile() and (f.power or 0) > 70 then
                local text = pick(narratives.faction_tension)
                text = text:gsub("{faction_name}", f.name or "A rival house")
                candidates[#candidates + 1] = {
                    priority = 9,
                    text = text,
                    color_key = "dim_gold",
                    icon_hint = "faction",
                }
                break -- only one faction tease
            end
        end
    end

    -- 3. Dream deadline: bloodline dream expires in 1-2 gens
    local dream = context.bloodline_dream
    if dream and dream.status == "active" and dream.deadline_generation then
        local gens_left = dream.deadline_generation - generation
        if gens_left >= 1 and gens_left <= 2 then
            candidates[#candidates + 1] = {
                priority = 8,
                text = pick(narratives.dream_deadline),
                color_key = "dim_gold",
                icon_hint = "dream",
            }
        end
    end

    -- 4. Crucible approaching: gap nearing trigger (within 2 gens)
    if ws then
        local last_crucible = ws.last_crucible_gen or 0
        local gap = generation - last_crucible
        -- Crucible triggers at gap 7-10, so tease at gap 5-8
        if gap >= 5 and gap <= 8 and generation >= 5 then
            candidates[#candidates + 1] = {
                priority = 7,
                text = pick(narratives.crucible_approaching),
                color_key = "dim_gold",
                icon_hint = "crucible",
            }
        end
    end

    -- 5. Trait collapse: any category average dropping below 30
    if genome then
        local categories = {
            { key = "physical" },
            { key = "mental" },
            { key = "social" },
            { key = "creative" },
        }
        for _, cat in ipairs(categories) do
            local traits = genome:get_category(cat.key)
            local sum, count = 0, 0
            for _, t in ipairs(traits) do
                sum = sum + (t:get_value() or 50)
                count = count + 1
            end
            if count > 0 and (sum / count) < 30 then
                local text = narratives.trait_collapse[cat.key]
                if text then
                    candidates[#candidates + 1] = {
                        priority = 6,
                        text = text,
                        color_key = "dim_gold",
                        icon_hint = "trait",
                    }
                end
                break -- only one collapse tease
            end
        end
    end

    -- 6. Rising power: 3+ category averages above 65
    if genome then
        local above_count = 0
        local cat_keys = { "physical", "mental", "social", "creative" }
        for _, cat_key in ipairs(cat_keys) do
            local traits = genome:get_category(cat_key)
            local sum, count = 0, 0
            for _, t in ipairs(traits) do
                sum = sum + (t:get_value() or 50)
                count = count + 1
            end
            if count > 0 and (sum / count) > 65 then
                above_count = above_count + 1
            end
        end
        if above_count >= 3 then
            candidates[#candidates + 1] = {
                priority = 5,
                text = pick(narratives.rising_power),
                color_key = "dim_gold",
                icon_hint = "power",
            }
        end
    end

    -- 7. Era threshold: close to era transition
    if ws then
        local era = ws:get_era()
        if era and era.min_generations then
            local gens_in = ws.generations_in_era or 0
            local remaining = era.min_generations - gens_in
            if remaining >= 0 and remaining <= 3 then
                candidates[#candidates + 1] = {
                    priority = 4,
                    text = pick(narratives.era_threshold),
                    color_key = "dim_gold",
                    icon_hint = "era",
                }
            end
        end
    end

    -- 8. Mutation spike: pressure > 60
    local pressure = context.mutation_pressure
    local pressure_val = 0
    if type(pressure) == "table" then
        pressure_val = pressure.value or 0
    elseif type(pressure) == "number" then
        pressure_val = pressure
    end
    if pressure_val > 60 then
        candidates[#candidates + 1] = {
            priority = 3,
            text = pick(narratives.mutation_spike),
            color_key = "dim_gold",
            icon_hint = "mutation",
        }
    end

    -- 9. Taboo forming: cultural memory stress high (4+ taboos)
    if cm and cm.taboos and #cm.taboos >= 4 then
        candidates[#candidates + 1] = {
            priority = 2,
            text = pick(narratives.taboo_forming),
            color_key = "dim_gold",
            icon_hint = "taboo",
        }
    end

    -- 10. Rival emergence: strongest faction gaining power for 3+ gens
    if factions then
        local active = factions:get_active()
        local strongest = nil
        local strongest_power = 0
        for _, f in ipairs(active) do
            if (f.power or 0) > strongest_power then
                strongest_power = f.power
                strongest = f
            end
        end
        if strongest and strongest.status == "rising" and strongest_power > 65 then
            candidates[#candidates + 1] = {
                priority = 1,
                text = pick(narratives.rival_emergence),
                color_key = "dim_gold",
                icon_hint = "faction",
            }
        end
    end

    -- Sort by priority (highest first) and pick top 2
    table.sort(candidates, function(a, b) return a.priority > b.priority end)

    local result = {}
    for i = 1, math.min(2, #candidates) do
        result[#result + 1] = {
            text = candidates[i].text,
            color_key = candidates[i].color_key,
            icon_hint = candidates[i].icon_hint,
        }
    end

    return result
end

return Tease
