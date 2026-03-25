-- Dark Legacy — Cross-Run Echoes
-- References past dynasties in new runs for narrative continuity.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local ok_templates, templates = pcall(require, "dredwork_world.config.cross_run_templates")
if not ok_templates then templates = { whispers = {}, faction_memories = {}, ghost_events = {} } end

local CrossRun = {}

-- Internal state
local _past_runs = nil
local _last_reference_gen = 0
local MIN_GAP = 5 -- min generations between cross-run references

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

--- Initialize cross-run system with past run history.
-- Call once at start of a new run.
---@param records table|nil records data (unused currently, for future PB awareness)
---@param run_history table|nil array of past run summaries from RunTracker
function CrossRun.init(records, run_history)
    _past_runs = {}
    _last_reference_gen = 0

    if not run_history then return end

    -- Filter to completed or abandoned runs with data
    for _, run in ipairs(run_history) do
        if (run.status == "complete" or run.status == "abandoned") and run.lineage_name and run.generations then
            _past_runs[#_past_runs + 1] = {
                lineage_name = run.lineage_name,
                generations = run.generations,
                final_reputation = run.final_reputation or "unknown",
                final_era = run.final_era or "ancient",
                start_era = run.start_era or "ancient",
                was_abandoned = run.status == "abandoned",
            }
        end
    end
end

--- Get an atmospheric whisper referencing a past dynasty.
-- Rate-limited: max 1 per MIN_GAP generations.
---@param current_era string|nil current era key
---@param generation number current generation
---@return string|nil whisper text or nil
function CrossRun.get_whisper(current_era, generation)
    if not _past_runs or #_past_runs == 0 then return nil end
    if generation and generation - _last_reference_gen < MIN_GAP then return nil end

    local run = pick(_past_runs)
    if not run then return nil end

    local vars = {
        past_lineage = run.lineage_name,
        past_gens = tostring(run.generations),
        past_reputation = run.final_reputation,
        past_faction = "the old powers", -- generic
    }

    local text = pick(templates.whispers)
    if not text then return nil end

    if generation then _last_reference_gen = generation end
    return sub(text, vars)
end

--- Get a faction-memory reference about a past dynasty.
---@param faction_id string|nil current faction being interacted with
---@return string|nil memory text or nil
function CrossRun.get_faction_memory(faction_id)
    if not _past_runs or #_past_runs == 0 then return nil end

    local run = pick(_past_runs)
    if not run then return nil end

    local vars = {
        past_lineage = run.lineage_name,
        past_gens = tostring(run.generations),
        past_reputation = run.final_reputation,
        past_faction = faction_id or "this house",
    }

    local text = pick(templates.faction_memories)
    if not text then return nil end

    return sub(text, vars)
end

--- Get a ghost event referencing a past dynasty milestone/death.
-- Rate-limited: max once per 10 generations.
---@param generation number current generation
---@param era string|nil current era
---@return table|nil event table (type="legacy") or nil
function CrossRun.get_ghost_event(generation, era)
    if not _past_runs or #_past_runs == 0 then return nil end
    if not generation then return nil end
    -- More restrictive rate limit for events
    if generation - _last_reference_gen < 10 then return nil end

    -- 30% chance to generate
    if not rng.chance(0.3) then return nil end

    local run = pick(_past_runs)
    if not run then return nil end

    local event_template = pick(templates.ghost_events)
    if not event_template then return nil end

    local vars = {
        past_lineage = run.lineage_name,
        past_gens = tostring(run.generations),
        past_reputation = run.final_reputation,
    }

    -- Build event
    local event = {
        id = "ghost_" .. generation,
        title = sub(event_template.title, vars),
        narrative = sub(event_template.narrative, vars),
        type = "legacy",
        pool = "legacy",
        options = {},
    }

    if event_template.options then
        for _, opt in ipairs(event_template.options) do
            event.options[#event.options + 1] = {
                label = opt.label,
                consequences = opt.consequences,
            }
        end
    end

    _last_reference_gen = generation
    return event
end

--- Get shadow lineage seeds from abandoned past runs.
-- Abandoned bloodlines are restless — they haunt the next world as stronger shadow houses.
---@return table array of { name, power, reason } or empty
function CrossRun.get_abandoned_shadows()
    if not _past_runs then return {} end
    local shadows = {}
    for _, run in ipairs(_past_runs) do
        if run.was_abandoned and run.generations and run.generations >= 3 then
            shadows[#shadows + 1] = {
                name = run.lineage_name,
                power = math.min(70, 30 + run.generations * 2), -- more gens = stronger ghost
                reason = "The abandoned " .. run.lineage_name .. " bloodline refuses to stay dead.",
            }
        end
    end
    return shadows
end

--- Reset rate limiting (for testing).
function CrossRun._reset()
    _last_reference_gen = 0
end

--- Reset all module-level state (call during new game initialization).
function CrossRun.reset()
    _past_runs = nil
    _last_reference_gen = 0
end

return CrossRun
