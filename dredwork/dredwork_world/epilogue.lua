-- Dark Legacy — Epilogue Engine
-- Generates post-extinction world narrative.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local ok_templates, templates = pcall(require, "dredwork_world.config.epilogue_templates")
if not ok_templates then templates = { openings = {}, faction_echoes = {}, cultural_residue = {}, closers = {} } end

local Epilogue = {}

-- Internal: pick random from pool
local function pick(pool)
    if not pool or #pool == 0 then return nil end
    return pool[rng.range(1, #pool)]
end

-- Internal: substitute template variables
local function sub(text, vars)
    if not text then return "" end
    return text:gsub("{([%w_]+)}", function(key)
        return vars[key] or ("{" .. key .. "}")
    end)
end

--- Determine the tone of the epilogue.
---@param run_data table { final_generation, cause_of_death, final_reputation }
---@return string tone: "tragic", "epic", "ironic", "forgotten"
function Epilogue.determine_tone(run_data)
    local gen = run_data.final_generation or run_data.current_generation or 1
    local cause = run_data.cause_of_death or "natural_frailty"
    local rep = run_data.final_reputation or "unknown"

    -- Short run (< 5 gens) = tragic
    if gen < 5 then return "tragic" end

    -- Long run (> 30 gens) = epic
    if gen > 30 then return "epic" end

    -- Died to own strength traits = ironic
    local ironic_causes = { madness = true, heir_death = true }
    if ironic_causes[cause] and gen > 10 then return "ironic" end

    -- Low reputation / short-medium run = forgotten
    if rep == "unknown" or gen < 10 then return "forgotten" end

    -- Default: epic for mid-range successful runs
    return "epic"
end

--- Generate a full epilogue.
---@param run_data table run tracker data
---@param world_state table|nil WorldState (for faction info)
---@param cultural_memory table|nil CulturalMemory
---@return table { paragraphs = {string...}, tone = string }
function Epilogue.generate(run_data, world_state, cultural_memory)
    run_data = run_data or {}

    local tone = Epilogue.determine_tone(run_data)
    local lineage = run_data.lineage_name or "the bloodline"
    local gen = run_data.final_generation or run_data.current_generation or 1
    local cause = run_data.cause_of_death or "natural_frailty"

    -- Map cause to closer category
    local cause_cat = cause
    if cause == "starvation" then cause_cat = "famine"
    elseif cause == "killed_in_war" or cause == "war_casualty" then cause_cat = "war"
    elseif cause == "no_children" then cause_cat = "no_children"
    end

    -- Era name for templates
    local era_names = {
        ancient = "the Age of Myth", iron = "the Iron Age",
        dark = "the Rotting Years", arcane = "the Age of Arcana",
        gilded = "the Gilded Era", twilight = "the Twilight",
    }
    local era_key = run_data.final_era or "ancient"
    local era_name = era_names[era_key] or era_key

    local vars = {
        lineage_name = lineage,
        generation = tostring(gen),
        era_name = era_name,
    }

    local paragraphs = {}

    -- 1. Opening
    local opening_pool = templates.openings[tone] or templates.openings.tragic or {}
    local opening = pick(opening_pool)
    if opening then
        paragraphs[#paragraphs + 1] = sub(opening, vars)
    end

    -- 2. Faction echo (strongest allied or enemy faction)
    if world_state and world_state.factions then
        pcall(function()
            local factions = world_state.factions
            local active = factions:get_active()
            if active and #active > 0 then
                -- Find most extreme disposition faction
                local best = active[1]
                local best_abs = math.abs(best.disposition)
                for i = 2, #active do
                    local abs_d = math.abs(active[i].disposition)
                    if abs_d > best_abs then
                        best = active[i]
                        best_abs = abs_d
                    end
                end

                local disp_type = "neutral"
                if best.disposition >= 30 then disp_type = "ally"
                elseif best.disposition <= -30 then disp_type = "enemy"
                end

                vars.faction_name = best.name or "a rival house"
                local pool = templates.faction_echoes[disp_type] or templates.faction_echoes.neutral or {}
                local echo = pick(pool)
                if echo then
                    paragraphs[#paragraphs + 1] = sub(echo, vars)
                end
            end
        end)
    end

    -- 3. Cultural residue
    local residue_key = "milestones" -- default
    if cultural_memory then
        if cultural_memory.taboos and #cultural_memory.taboos >= 2 then
            residue_key = "taboos"
        end
    end
    if run_data.legends and #run_data.legends > 0 then
        residue_key = "legends"
    end

    local residue_pool = templates.cultural_residue[residue_key] or {}
    local residue = pick(residue_pool)
    if residue then
        paragraphs[#paragraphs + 1] = sub(residue, vars)
    end

    -- 4. Closer
    local closer_pool = templates.closers[cause_cat] or templates.closers.natural_frailty or {}
    local closer = pick(closer_pool)
    if closer then
        paragraphs[#paragraphs + 1] = sub(closer, vars)
    end

    return {
        paragraphs = paragraphs,
        tone = tone,
    }
end

return Epilogue
