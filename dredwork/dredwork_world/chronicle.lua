-- Dark Legacy — Chronicle / Narrative System
-- Generates personality-tinted and reputation-tinted narrative text.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")
local narrative_tables = require("dredwork_world.config.narrative_tables")

-- Undercurrent integration (pcall-wrapped)
local ok_uc, Undercurrent = pcall(require, "dredwork_world.undercurrent")
if not ok_uc then Undercurrent = nil end

-- Cross-run integration (pcall-wrapped)
local ok_cr, CrossRun = pcall(require, "dredwork_world.cross_run")
if not ok_cr then CrossRun = nil end

local Chronicle = {}

--- Generate a subtle footnote about the origin of an event.
---@param origin table { type, heir_name, gen, detail }
---@return string atmospheric whisper
function Chronicle.get_causality_whisper(origin)
    if not origin then return "" end

    local heir = origin.heir_name or "an ancestor"
    local gen = tostring(origin.gen or "?")
    local detail = origin.detail

    -- Use detail-specific templates when available for richer causality
    if detail then
        local detailed_templates = {
            "A consequence of {detail} — {heir_name}, Gen {gen}.",
            "The ghost of {heir_name}'s {detail} haunts the blood.",
            "Rooted in {detail}, the deeds of {heir_name}.",
            "{detail}. The weight of Gen {gen} endures.",
        }
        local template = detailed_templates[rng.range(1, #detailed_templates)]
        return template:gsub("{heir_name}", heir)
                       :gsub("{gen}", gen)
                       :gsub("{detail}", tostring(detail))
    end

    local templates = {
        "A legacy of {heir_name} (Gen {gen}).",
        "The ghost of {heir_name}'s choice remains.",
        "Rooted in the deeds of {heir_name}.",
        "The weight of the past: Gen {gen}.",
        "A shadow cast by {heir_name} long ago.",
    }

    local template = templates[rng.range(1, #templates)]
    return template:gsub("{heir_name}", heir)
                   :gsub("{gen}", gen)
end

--- Generate a generation opening line based on heir personality.
---@param heir_name string
---@param generation number
---@param personality table Personality instance
---@param world_name string|nil
---@param era string|nil current era key (ancient, iron, dark, arcane, gilded, twilight)
---@return string
function Chronicle.generation_opening(heir_name, generation, personality, world_name, era)
    -- Find the most extreme personality axis
    local most_extreme_axis = nil
    local most_extreme_val = 0
    local most_extreme_dir = "high" -- high or low

    for _, axis_id in ipairs({
        "PER_CRM", "PER_BLD", "PER_VOL", "PER_OBS",
        "PER_PRI", "PER_CUR", "PER_LOY", "PER_ADA"
    }) do
        local val = personality:get_axis(axis_id)
        local dist_from_center = math.abs(val - 50)
        if dist_from_center > most_extreme_val then
            most_extreme_val = dist_from_center
            most_extreme_axis = axis_id
            most_extreme_dir = val >= 50 and "high" or "low"
        end
    end

    -- Look up opening line pool — try era-specific first, then base
    local pool = nil
    if most_extreme_axis and most_extreme_val >= 20 then
        local base_key = most_extreme_axis .. "_" .. most_extreme_dir
        -- Era-specific pool (50% chance when available, for variety)
        if era and narrative_tables.era_openings and rng.chance(0.5) then
            local era_key = base_key .. "_" .. era
            pool = narrative_tables.era_openings[era_key]
        end
        -- Fall back to base personality pool
        if not pool or #pool == 0 then
            pool = narrative_tables.openings[base_key]
        end
    end

    -- Fallback to generic pool
    if not pool or #pool == 0 then
        pool = narrative_tables.openings.generic
    end

    local template = pool[rng.range(1, #pool)]
    local result = template:gsub("{heir_name}", heir_name)
        :gsub("{generation}", tostring(generation))
        :gsub("{world_name}", world_name or "Caldemyr")

    -- 20% chance to include a cross-run reference
    if CrossRun and rng.chance(0.2) then
        local ok_w, whisper = pcall(CrossRun.get_whisper, nil, generation)
        if ok_w and whisper then
            result = result .. " " .. whisper
        end
    end

    return result
end

--- Generate a generation closing line based on reputation.
---@param reputation table { primary, secondary }
---@param era string|nil current era key
---@return string
function Chronicle.generation_closing(reputation, era)
    local primary = reputation.primary or "unknown"

    -- Try era-specific closing first (50% chance when available)
    local pool = nil
    if era and narrative_tables.era_closings and rng.chance(0.5) then
        local era_key = primary .. "_" .. era
        pool = narrative_tables.era_closings[era_key]
        -- Also try generic era closing
        if (not pool or #pool == 0) then
            pool = narrative_tables.era_closings["generic_" .. era]
        end
    end

    -- Fall back to base reputation pool
    if not pool or #pool == 0 then
        pool = narrative_tables.closings[primary]
    end

    if not pool or #pool == 0 then
        pool = narrative_tables.closings.generic
    end

    return pool[rng.range(1, #pool)]
end

--- Generate a generation closing with optional undercurrent appendage.
---@param reputation table { primary, secondary }
---@param undercurrents table|nil array from Undercurrent.detect()
---@return string
function Chronicle.generation_closing_with_undercurrent(reputation, undercurrents)
    local base = Chronicle.generation_closing(reputation)
    if undercurrents and #undercurrents > 0 then
        -- Find strongest undercurrent at murmur or roar level
        for _, u in ipairs(undercurrents) do
            if u.severity == "murmur" or u.severity == "roar" then
                base = base .. " " .. u.narrative
                break
            end
        end
    end
    return base
end

--- Generate a full generation chronicle entry.
---@param params table { heir_name, generation, personality, reputation, events, genome, context, era_name }
---@return string
function Chronicle.generate_entry(params)
    local parts = {}

    local world_name = "Caldemyr"
    if params.context and params.context.world_state then
        local ws = params.context.world_state
        world_name = (ws.get_world_name and ws:get_world_name()) or ws.world_name_override or "Caldemyr"
    end

    -- Opening
    parts[#parts + 1] = Chronicle.generation_opening(
        params.heir_name,
        params.generation,
        params.personality,
        world_name,
        params.era_name
    )

    -- Biography (Physical + Education + Relic + Holding)
    if params.genome and params.personality then
        local HeirBiography = require("dredwork_world.heir_biography")
        local bio = HeirBiography.generate(
            params.genome, params.personality, 
            params.era_name or "this age", 
            params.heir_name, params.context
        )
        if bio then parts[#parts + 1] = bio end
    end

    -- Event narratives
    if params.events and #params.events > 0 then
        -- Add a transition if we have a lot of events
        if #params.events > 2 then
            parts[#parts + 1] = "The years were marked by significant shifts in the realm."
        end
        for _, event_narrative in ipairs(params.events) do
            if event_narrative and event_narrative ~= "" then
                parts[#parts + 1] = event_narrative
            end
        end
    end

    -- Closing
    local rep = params.reputation or { primary = "generic" }
    local closing = Chronicle.generation_closing(rep, params.era_name)
    -- Substitute heir name in closing if template uses it
    closing = closing:gsub("{heir_name}", params.heir_name or "the heir")
    parts[#parts + 1] = closing

    return table.concat(parts, "\n\n")
end

--- Substitute template variables in text.
---@param text string
---@param vars table
---@return string
function Chronicle.substitute(text, vars)
    if not text then return "" end
    return text:gsub("{([%w_]+)}", function(key)
        return vars[key] or ("{" .. key .. "}")
    end)
end

--- Generate a full readable narrative from all chronicle entries.
--- Groups entries by era and adds era headers and generation markers.
---@param entries table array of { text, generation, heir_name, era }
---@param lineage_name string the family name
---@return string the full story
function Chronicle.generate_full_narrative(entries, lineage_name)
    if not entries or #entries == 0 then
        return "The chronicle is empty. The story has yet to be written."
    end

    local parts = {}
    local current_era = nil
    local era_labels = {
        ancient = "THE AGE OF MYTH",
        iron = "THE IRON AGE",
        dark = "THE ROTTING YEARS",
        arcane = "THE AGE OF ARCANA",
        gilded = "THE GILDED ERA",
        twilight = "THE TWILIGHT",
    }

    -- Opening
    parts[#parts + 1] = "THE CHRONICLE OF " .. (lineage_name or "THE BLOODLINE"):upper()
    parts[#parts + 1] = ""

    for _, entry in ipairs(entries) do
        -- Era header when era changes
        local era = entry.era or "ancient"
        if era ~= current_era then
            current_era = era
            parts[#parts + 1] = ""
            parts[#parts + 1] = "--- " .. (era_labels[era] or era:upper()) .. " ---"
            parts[#parts + 1] = ""
        end

        -- Generation marker
        local gen_label = "Generation " .. (entry.generation or "?")
        if entry.heir_name then
            gen_label = gen_label .. " — " .. entry.heir_name
        end
        parts[#parts + 1] = gen_label
        parts[#parts + 1] = entry.text or ""
        parts[#parts + 1] = ""
    end

    return table.concat(parts, "\n")
end

--- Summarize a run from its chronicle entries.
---@param entries table array of chronicle entries
---@return table { generations, eras_seen, final_era, heir_count }
function Chronicle.summarize(entries)
    local eras = {}
    local max_gen = 0
    local heirs = {}

    for _, entry in ipairs(entries) do
        if entry.generation and entry.generation > max_gen then
            max_gen = entry.generation
        end
        if entry.era then
            eras[entry.era] = true
        end
        if entry.heir_name then
            heirs[entry.heir_name] = true
        end
    end

    local era_list = {}
    for era in pairs(eras) do
        era_list[#era_list + 1] = era
    end

    local heir_count = 0
    for _ in pairs(heirs) do
        heir_count = heir_count + 1
    end

    return {
        generations = max_gen,
        eras_seen = era_list,
        final_era = entries[#entries] and entries[#entries].era or "ancient",
        heir_count = heir_count,
    }
end

return Chronicle
