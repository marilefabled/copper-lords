-- Dark Legacy — Run Summary Generator
-- Generates shareable text-based run summary cards.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local RunSummary = {}

-- Headline templates based on generation count and cause
local headlines = {
    long_plague = {
        "The {lineage} dynasty endured {generations} generations before the plague turned their halls to tombs.",
        "After {generations} generations of defiance, the {lineage} bloodline was finally consumed by the sickness.",
    },
    long_war = {
        "The {lineage} dynasty stood as a monolith for {generations} generations before falling at the spear-point of fate.",
        "{generations} generations of {lineage} blood, spilled at last in a war that would not end.",
    },
    long_famine = {
        "The {lineage} dynasty starved after {generations} generations of endurance. The earth simply forgot them.",
    },
    long_generic = {
        "The {lineage} dynasty endured {generations} generations, a golden thread through the dark tapestry of history.",
        "For {generations} generations, the {lineage} name was a prayer and a curse. Now, it is only a memory.",
    },
    short_plague = {
        "The {lineage} bloodline was but a spark, snuffed by the first breath of plague.",
    },
    short_war = {
        "The {lineage} bloodline was cut down before it could take root. War claims even the youngest names.",
    },
    short_generic = {
        "The {lineage} dynasty fell before its story could truly begin.",
        "{gen_phrase}. A name written in water, fading into the silence of the waste.",
    },
    medium_generic = {
        "The {lineage} dynasty endured {generations} generations. They were the architects of their own legend.",
        "{generations} generations of the {lineage} bloodline — a saga of bone, iron, and will.",
    },
}

local function sub(template, vars)
    local result = template
    for k, v in pairs(vars) do
        result = result:gsub("{" .. k .. "}", tostring(v))
    end
    return result
end

local function pick(pool)
    if not pool or #pool == 0 then return "" end
    return pool[rng.range(1, #pool)]
end

--- Generate a run summary from run data.
---@param run_data table from RunTracker.get_run()
---@return table { headline, stats, notable_heirs, epitaph_chain, full_text }
function RunSummary.generate(run_data)
    if not run_data then
        return { headline = "No data.", stats = {}, notable_heirs = {}, epitaph_chain = "", full_text = "No data." }
    end

    local generations = run_data.final_generation or run_data.current_generation or 1
    local lineage = run_data.lineage_name or "Unknown"
    local cause = run_data.cause_of_death or "natural_frailty"
    local gen_phrase = generations == 1 and "1 generation" or (tostring(generations) .. " generations")
    local vars = { lineage = lineage, generations = tostring(generations), gen_phrase = gen_phrase }

    -- Pick headline based on length and cause
    local pool_key
    if generations >= 20 then
        if cause == "plague" then pool_key = "long_plague"
        elseif cause == "killed_in_war" then pool_key = "long_war"
        elseif cause == "starvation" then pool_key = "long_famine"
        else pool_key = "long_generic" end
    elseif generations <= 5 then
        if cause == "plague" then pool_key = "short_plague"
        elseif cause == "killed_in_war" then pool_key = "short_war"
        else pool_key = "short_generic" end
    else
        pool_key = "medium_generic"
    end

    local headline = sub(pick(headlines[pool_key] or headlines.medium_generic), vars)

    -- Stats
    local milestones = run_data.milestones or {}
    local legends = run_data.legends or {}
    local heirs = run_data.heirs or {}
    local conditions_survived = run_data.conditions_survived or {}

    local stats = {
        generations = generations,
        heirs_total = #heirs,
        legends_earned = #legends,
        milestones_achieved = #milestones,
        taboos_formed = run_data.taboo_count or 0,
        conditions_survived = #conditions_survived,
        start_era = run_data.start_era or "unknown",
        final_era = run_data.final_era or "unknown",
        final_reputation = run_data.final_reputation or "unknown",
        cause_of_death = cause,
    }

    -- Notable heirs (those with legends, sorted by generation)
    local notable = {}
    for _, heir in ipairs(heirs) do
        if heir.legend then
            notable[#notable + 1] = {
                name = heir.name,
                generation = heir.generation,
                legend = heir.legend,
                epitaph = heir.epitaph,
            }
        end
    end
    -- Keep top 5 for longer summaries
    while #notable > 5 do
        table.remove(notable, 1) -- remove oldest
    end

    -- Epitaph chain (condensed)
    local epitaph_parts = {}
    for _, heir in ipairs(heirs) do
        if heir.epitaph then
            epitaph_parts[#epitaph_parts + 1] = heir.epitaph
        end
    end
    -- Keep last 10 for more story context
    while #epitaph_parts > 10 do
        table.remove(epitaph_parts, 1)
    end
    local epitaph_chain = table.concat(epitaph_parts, " ")

    -- Build full text summary
    local lines = {}
    lines[#lines + 1] = "─── THE FALL OF HOUSE " .. lineage:upper() .. " ───"
    lines[#lines + 1] = ""
    lines[#lines + 1] = headline
    lines[#lines + 1] = ""
    lines[#lines + 1] = "▣ DYNASTIC RECORD"
    lines[#lines + 1] = "  • Generations Endured: " .. generations
    lines[#lines + 1] = "  • Heirs Ascended: " .. #heirs
    lines[#lines + 1] = "  • Milestones Claimed: " .. #milestones
    lines[#lines + 1] = "  • Final Reputation: " .. (stats.final_reputation or "unknown"):upper()
    lines[#lines + 1] = "  • Final Era: " .. (stats.final_era or "unknown"):upper()
    lines[#lines + 1] = "  • Extinction Cause: " .. (cause or "unknown"):gsub("_", " "):upper()

    if #notable > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "▣ LEGENDS OF THE BLOOD"
        for _, n in ipairs(notable) do
            local legend_str = type(n.legend) == "table" and n.legend.title or tostring(n.legend)
            lines[#lines + 1] = "  • Gen " .. (n.generation or "?") .. " | " .. (n.name or "?") .. ": " .. legend_str
        end
    end

    if epitaph_chain ~= "" then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "▣ ANCESTRAL ECHOES"
        lines[#lines + 1] = "  \"" .. epitaph_chain .. "\""
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Bloodweight — An Accounting of Sorts"

    local full_text = table.concat(lines, "\n")

    return {
        headline = headline,
        stats = stats,
        notable_heirs = notable,
        epitaph_chain = epitaph_chain,
        full_text = full_text,
    }
end

return RunSummary
