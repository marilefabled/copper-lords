-- Dark Legacy — Heir Biography & Wild Attributes
-- Auto-generated biography from top traits + personality + era.
-- Wild attributes = emergent descriptors from trait combinations.
-- Pure Lua, zero Solar2D dependencies.

local trait_definitions = require("dredwork_genetics.config.trait_definitions")
local rng = require("dredwork_core.rng")

local HeirBiography = {}

--- Wild attribute definitions.
--- Each requires specific trait/personality thresholds and grants category bonuses.
HeirBiography.wild_attributes = {
    {
        id = "berserker", label = "BERSERKER",
        requires = { PHY_STR = { min = 75 }, PHY_END = { min = 60 } },
        requires_personality = { PER_VOL = { min = 65 } },
        effect = { physical = 10 },
        flavor = "A bad investment in restraint. Pays dividends in wreckage.",
    },
    {
        id = "silver_tongue", label = "SILVER TONGUE",
        requires = { SOC_ELO = { min = 75 }, SOC_CHA = { min = 65 } },
        effect = { social = 10 },
        flavor = "Renegotiates any contract mid-sentence. The words are the weapon.",
    },
    {
        id = "iron_mind", label = "IRON MIND",
        requires = { MEN_WIL = { min = 75 }, MEN_FOC = { min = 65 } },
        effect = { mental = 10 },
        flavor = "The ledger does not tremble. The pen does not waver.",
    },
    {
        id = "prodigy", label = "PRODIGY",
        requires = { MEN_INT = { min = 80 }, MEN_LRN = { min = 70 } },
        effect = { mental = 12 },
        flavor = "Read the fine print before they could walk. Born knowing the terms.",
    },
    {
        id = "shadow", label = "SHADOW",
        requires = { SOC_DEC = { min = 70 }, MEN_CUN = { min = 65 } },
        requires_personality = { PER_CRM = { min = 55 } },
        effect = { social = 8, mental = 5 },
        flavor = "The unsigned clause. The debt you didn't know you owed.",
    },
    {
        id = "visionary", label = "VISIONARY",
        requires = { CRE_VIS = { min = 75 }, MEN_ABS = { min = 65 } },
        requires_personality = { PER_CUR = { min = 60 } },
        effect = { creative = 10 },
        flavor = "Sees the bottom line three generations out. Builds accordingly.",
    },
    {
        id = "titan", label = "TITAN",
        requires = { PHY_STR = { min = 80 }, PHY_END = { min = 75 }, PHY_VIT = { min = 70 } },
        effect = { physical = 15 },
        flavor = "The bloodline's principal asset, walking. A mountain on the balance sheet.",
    },
    {
        id = "diplomat", label = "BORN DIPLOMAT",
        requires = { SOC_NEG = { min = 70 }, SOC_AWR = { min = 65 }, SOC_EMP = { min = 60 } },
        effect = { social = 12 },
        flavor = "Restructures alliances the way water finds cracks. Effortless.",
    },
    {
        id = "survivor", label = "SURVIVOR",
        requires = { PHY_VIT = { min = 70 }, PHY_IMM = { min = 65 } },
        requires_personality = { PER_ADA = { min = 60 } },
        effect = { physical = 8 },
        flavor = "The account that refuses to close. Death sends the notice; they return it.",
    },
    {
        id = "mastermind", label = "MASTERMIND",
        requires = { MEN_STR = { min = 70 }, MEN_ANA = { min = 65 }, MEN_CUN = { min = 60 } },
        effect = { mental = 12 },
        flavor = "Ledgers within ledgers. Every outcome was in the margin notes.",
    },
    {
        id = "artisan_supreme", label = "MASTER ARTISAN",
        requires = { CRE_CRA = { min = 75 }, CRE_AES = { min = 65 } },
        effect = { creative = 12 },
        flavor = "Creates things the ledger cannot price. That terrifies the Soul Teller.",
    },
    {
        id = "zealot", label = "ZEALOT",
        requires = { MEN_WIL = { min = 70 } },
        requires_personality = { PER_OBS = { min = 75 }, PER_LOY = { min = 65 } },
        effect = { mental = 5, physical = 5 },
        flavor = "The tithe is absolute. Conviction compounds beyond reason.",
    },
    {
        id = "wildcard", label = "WILDCARD",
        requires = {},
        requires_personality = { PER_VOL = { min = 80 }, PER_ADA = { min = 70 } },
        effect = { social = 5, creative = 5 },
        flavor = "The variable the actuary cannot account for.",
    },
    {
        id = "stoic", label = "THE STOIC",
        requires = { MEN_COM = { min = 75 } },
        requires_personality = { PER_VOL = { max = 30 } },
        effect = { mental = 8 },
        flavor = "A flat line on every chart. The calm that outlasts the crisis.",
    },
    {
        id = "natural_leader", label = "NATURAL LEADER",
        requires = { SOC_LEA = { min = 75 }, SOC_CHA = { min = 65 } },
        requires_personality = { PER_BLD = { min = 55 } },
        effect = { social = 10, physical = 5 },
        flavor = "Others sign over authority without being asked. Born to hold the seal.",
    },
}

--- Check which wild attributes an heir qualifies for.
---@param genome table Genome
---@param personality table|nil Personality
---@return table array of { id, label, effect, flavor }
function HeirBiography.get_wild_attributes(genome, personality)
    local result = {}

    for _, wa in ipairs(HeirBiography.wild_attributes) do
        local qualifies = true

        -- Check trait requirements
        for trait_id, req in pairs(wa.requires) do
            local val = genome:get_value(trait_id) or 0
            if req.min and val < req.min then qualifies = false; break end
            if req.max and val > req.max then qualifies = false; break end
        end

        -- Check personality requirements
        if qualifies and wa.requires_personality and personality then
            for axis_id, req in pairs(wa.requires_personality) do
                local val = personality:get_axis(axis_id) or 50
                if req.min and val < req.min then qualifies = false; break end
                if req.max and val > req.max then qualifies = false; break end
            end
        elseif qualifies and wa.requires_personality and not personality then
            qualifies = false
        end

        if qualifies then
            result[#result + 1] = {
                id = wa.id,
                label = wa.label,
                effect = wa.effect,
                flavor = wa.flavor,
            }
        end
    end

    return result
end

--- Convert wild attributes to stat_check bonuses (keyed by category).
---@param wild_attrs table array from get_wild_attributes
---@return table { physical = N, mental = N, social = N, creative = N }
function HeirBiography.wild_bonuses(wild_attrs)
    local bonuses = { physical = 0, mental = 0, social = 0, creative = 0 }
    for _, wa in ipairs(wild_attrs) do
        for cat, bonus in pairs(wa.effect) do
            bonuses[cat] = bonuses[cat] + bonus
        end
    end
    return bonuses
end

--- Generate a 2-3 sentence biography for an heir.
--- Generate a full biography sentence-by-sentence.
---@param genome table Genome
---@param personality table|nil Personality
---@param era_name string current era name
---@param heir_name string
---@param context table|nil WorldContext
---@return string biography text
function HeirBiography.generate(genome, personality, era_name, heir_name, context)
    heir_name = heir_name or "the heir"
    era_name = era_name or "this age"

    local sentences = {}

    -- 1. Physical descriptor from top physical trait
    local phys_desc = HeirBiography._physical_line(genome, heir_name, personality)
    if phys_desc then sentences[#sentences + 1] = phys_desc end

    -- 2. Education-driven descriptor
    if genome and genome.mastery_tags then
        local edu_line = HeirBiography._education_line(genome, heir_name)
        if edu_line then sentences[#sentences + 1] = edu_line end
    end

    -- 2c. Relic/Artifact context
    if context and context.reliquary and #context.reliquary.artifacts > 0 then
        local art = context.reliquary.artifacts[1] -- mention the primary/first relic
        sentences[#sentences + 1] = heir_name .. " wields " .. art.name .. ", a relic of the ancestors."
    end

    -- 2d. Holding/Estate context
    if context and context.holdings and #context.holdings.domains > 0 then
        local dom = context.holdings.domains[1] -- mention the seat
        sentences[#sentences + 1] = "They rule from " .. dom.name .. ", the heart of the estate."
    end

    -- 2b. Personality-driven descriptor
    if personality then
        local pers_desc = HeirBiography._personality_line(personality, heir_name)
        if pers_desc then sentences[#sentences + 1] = pers_desc end
    end

    -- 3. Era context
    local world_name = context and context.world_state and context.world_state.get_world_name and context.world_state:get_world_name() or "Caldemyr"
    local era_desc = HeirBiography._era_line(era_name, heir_name, world_name)
    if era_desc then sentences[#sentences + 1] = era_desc end

    if #sentences == 0 then
        return heir_name .. " bears the weight of the bloodline."
    end

    return table.concat(sentences, " ")
end

--- Get personality behavioral descriptions (for personality panel).
---@param personality table Personality instance
---@return table array of { axis_id, axis_name, description }
function HeirBiography.get_personality_descriptions(personality)
    if not personality then return {} end

    local personality_maps = require("dredwork_genetics.config.personality_maps")
    local result = {}

    local descriptors = {
        PER_BLD = {
            [1] = "Refuses to sign anything without reading it twice. Paralyzed by risk.",
            [2] = "Counts the cost before moving. Caution over conviction.",
            [3] = "Spends when the odds are right. Neither reckless nor frozen.",
            [4] = "Signs blind. Bets the estate on instinct. The ledger weeps.",
        },
        PER_CRM = {
            [1] = "Forgives debts others would kill over. Mercy to a fault.",
            [2] = "Balances the books with a steady hand. Pragmatic, not cruel.",
            [3] = "Collects what is owed, even when the debtor bleeds.",
            [4] = "Forecloses without blinking. Mercy is an expense they refuse.",
        },
        PER_OBS = {
            [1] = "Closes the ledger mid-entry. Nothing holds. Nothing compels.",
            [2] = "Follows a thread when interested, but drops it easily.",
            [3] = "Once an account is opened, they pursue it to the margin.",
            [4] = "One line in the ledger, circled in red. Everything else burns.",
        },
        PER_LOY = {
            [1] = "Sells loyalty like a commodity. Bonds are temporary instruments.",
            [2] = "Loyal when the terms are favorable. Practical about allegiance.",
            [3] = "Stands by blood and bond through every downturn.",
            [4] = "The bloodline is the only currency. Would burn for it.",
        },
        PER_CUR = {
            [1] = "Accepts the balance as written. The old terms suffice.",
            [2] = "Glances at sealed records. Might open one, if prompted.",
            [3] = "Opens every archived ledger. Must know what was tallied.",
            [4] = "Breaks the seal on forbidden accounts without hesitation.",
        },
        PER_VOL = {
            [1] = "A flat line on the chart. The ink never trembles.",
            [2] = "Steady hand under pressure. The balance rarely shifts.",
            [3] = "The margins swing. Passion bleeds into every entry.",
            [4] = "A margin call waiting to happen. The balance swings wildly.",
        },
        PER_PRI = {
            [1] = "Works the margins. Never claims credit. The signature is small.",
            [2] = "Quiet confidence. Lets the balance sheet speak.",
            [3] = "The family name is stamped on every page. Demands recognition.",
            [4] = "The name is the only asset. Legacy above solvency.",
        },
        PER_ADA = {
            [1] = "Rigid terms, rigid structure. Will not renegotiate, even when breaking.",
            [2] = "Set in the old contracts, but can amend when forced.",
            [3] = "Restructures with relative ease. Survives the audit.",
            [4] = "Becomes whatever the situation demands. No fixed terms.",
        },
    }

    for _, axis in ipairs(personality_maps.axes) do
        local val = personality:get_axis(axis.id) or 50
        local tier = math.floor(val / 25) + 1
        if tier > 4 then tier = 4 end
        if tier < 1 then tier = 1 end

        local desc_table = descriptors[axis.id]
        local desc = desc_table and desc_table[tier] or ""

        result[#result + 1] = {
            axis_id = axis.id,
            axis_name = axis.name,
            description = desc,
        }
    end

    return result
end

-- =========================================================================
-- Internal: biography sentence generators
-- =========================================================================

--- Get a physical summary of the heir.
---@param genome table Genome
---@param heir_name string
---@param personality table|nil
---@return string physical summary
function HeirBiography.get_physical_summary(genome, heir_name, personality)
    return HeirBiography._physical_line(genome, heir_name or "the heir", personality)
end

--- Get a mental summary of the heir.
---@param genome table Genome
---@param heir_name string
---@param personality table|nil
---@return string mental summary
function HeirBiography.get_mental_summary(genome, heir_name, personality)
    return HeirBiography._mental_line(genome, heir_name or "the heir", personality)
end

--- Get a social summary of the heir.
---@param genome table Genome
---@param heir_name string
---@param personality table|nil
---@return string social summary
function HeirBiography.get_social_summary(genome, heir_name, personality)
    return HeirBiography._social_line(genome, heir_name or "the heir", personality)
end

--- Get a creative summary of the heir.
---@param genome table Genome
---@param heir_name string
---@param personality table|nil
---@return string creative summary
function HeirBiography.get_creative_summary(genome, heir_name, personality)
    return HeirBiography._creative_line(genome, heir_name or "the heir", personality)
end

--- Get category-appropriate summary for the heir.
---@param genome table Genome
---@param heir_name string
---@param personality table|nil
---@param category string "physical"|"mental"|"social"|"creative"
---@return string summary
function HeirBiography.get_category_summary(genome, heir_name, personality, category)
    local dispatch = {
        physical = HeirBiography.get_physical_summary,
        mental   = HeirBiography.get_mental_summary,
        social   = HeirBiography.get_social_summary,
        creative = HeirBiography.get_creative_summary,
    }
    local fn = dispatch[category] or dispatch.physical
    return fn(genome, heir_name, personality)
end

--- Get a summary of the heir's education mastery.
---@param heir table Genome
---@return string mastery text
function HeirBiography.get_education_text(heir)
    if not heir.mastery_tags then return "No specific mastery." end
    local tags = {}
    if heir.mastery_tags.MASTER_WARRIOR then tags[#tags + 1] = "MASTER WARRIOR" end
    if heir.mastery_tags.MASTER_SCHOLAR then tags[#tags + 1] = "MASTER SCHOLAR" end
    if heir.mastery_tags.MASTER_SPY then tags[#tags + 1] = "MASTER SPY" end
    if heir.mastery_tags.MASTER_MYSTIC then tags[#tags + 1] = "MASTER MYSTIC" end
    if heir.mastery_tags.MASTER_DIPLOMAT then tags[#tags + 1] = "MASTER DIPLOMAT" end

    if #tags == 0 then return "Incomplete education." end
    return table.concat(tags, " / ")
end

--- Get a summary of the heir's impact.
---@param ledger_entry table from HeirLedger
---@return string impact text
function HeirBiography.get_impact_text(ledger_entry)
    if not ledger_entry then return "Their entry in the ledger remains unwritten." end

    local parts = {}
    parts[#parts + 1] = string.format("Impact Rating: %s (%d)", ledger_entry.impact_rating, ledger_entry.impact_score)

    local best_cat, best_val = nil, 0
    local categories = {
        cultural_shift = "rewriting the cultural terms",
        reputation = "building the family's credit",
        alliances = "brokering new alliances",
        conditions = "weathering the collection",
        traits = "refining the bloodline's deposits",
        dream_progress = "pursuing the bloodline dream",
        wealth_impact = "managing the treasury",
        morality = "the moral balance of their account",
    }

    for cat, label in pairs(categories) do
        local val = ledger_entry[cat] or 50
        if val > best_val then best_cat, best_val = cat, val end
    end

    if best_cat and best_val > 60 then
        parts[#parts + 1] = "The Soul Teller notes their principal contribution: " .. categories[best_cat] .. "."
    elseif best_cat and best_val < 40 then
        parts[#parts + 1] = "The ledger records a deficit in " .. categories[best_cat] .. "."
    else
        parts[#parts + 1] = "They held the balance. Steady. Unremarkable. The Soul Teller barely looked up."
    end

    return table.concat(parts, "\n")
end

--- Get a summary of the heir's life event.
---@param life_event table from Crucible.run()
---@return string life event text
function HeirBiography.get_life_event_text(life_event)
    if not life_event then return nil end

    local outcome = life_event.outcome or "undetermined"
    local chronic = life_event.chronicle_text or ""

    return string.format("LIFE MOMENT: %s\n%s", outcome:upper(), chronic)
end

--- Generate an evocative summary for a rival heir.
---@param rival table rival heir object
---@return string summary text
function HeirBiography.generate_rival(rival)
    if not rival then return "" end
    
    local attitude_desc = {
        hostile = "an outstanding debt that grows with interest",
        wary = "a creditor watching from the next page of the ledger",
        neutral = "an adjacent entry in the Soul Teller's books",
        respectful = "a rival who knows the weight of your account",
        devoted = "the co-signer your bloodline never deserved",
    }

    local resource_line = ""
    if rival.resources then
        if rival.resources.steel > 40 then
            resource_line = " Their vaults ring with the currency of violence."
        elseif rival.resources.lore > 30 then
            resource_line = " They hold records that should have been burned."
        elseif rival.resources.gold > 60 then
            resource_line = " Their coin buys the loyalty of half the realm."
        end
    end

    local status = rival.alive and "Living" or "Fallen"
    local desc = string.format("%s of %s, %s. %s carries themselves with %s.",
        rival.name, rival.faction_name, attitude_desc[rival.attitude] or "a mysterious presence",
        rival.name, HeirBiography._personality_line(rival.personality, rival.name) or "deliberate intent")

    return desc .. resource_line
end

--- Compute the average value across visible/hinted traits in a category.
--- Only counts traits the player can actually see, so the summary matches
--- what's displayed on the trait tab.
---@param genome table Genome instance
---@param category string "physical"|"mental"|"social"|"creative"
---@return number average (0-100)
function HeirBiography._category_average(genome, category)
    if not genome.get_category then return 50 end
    local traits = genome:get_category(category)
    if not traits or #traits == 0 then return 50 end
    local sum, count = 0, 0
    for _, t in ipairs(traits) do
        local vis = t.visibility or "visible"
        if vis == "visible" or vis == "hinted" then
            sum = sum + (t:get_value() or 50)
            count = count + 1
        end
    end
    if count == 0 then return 50 end
    return math.floor(sum / count)
end

function HeirBiography._physical_line(genome, name, personality)
    local str = genome:get_value("PHY_STR") or 50
    local hgt = genome:get_value("PHY_HGT") or 50
    local bld = genome:get_value("PHY_BLD") or 50
    local skn = genome:get_value("PHY_SKN") or 50
    local hai = genome:get_value("PHY_HAI") or 50
    local eye = genome:get_value("PHY_EYE") or 50
    local htx = genome:get_value("PHY_HTX") or 50
    local fsh = genome:get_value("PHY_FSH") or 50

    -- 1. Silhouette & Presence
    local silhouette = "of unremarkable stature"
    if hgt >= 80 then
        if bld >= 75 then silhouette = "a towering, monolithic presence"
        elseif bld <= 25 then silhouette = "a gaunt, elongated shadow"
        else silhouette = "a tall and imposing figure" end
    elseif hgt <= 30 then
        if bld >= 75 then silhouette = "a short, broad-shouldered slab of muscle"
        elseif bld <= 25 then silhouette = "a small, bird-like form"
        else silhouette = "a person of compact, efficient build" end
    else
        if bld >= 80 then silhouette = "a stout, thick-set individual"
        elseif bld <= 20 then silhouette = "a whip-thin, wiry figure"
        else silhouette = "a person of balanced proportions" end
    end

    -- 2. Ancestral Coloring (thresholds match trait_summaries: 0-19, 20-39, 40-64, 65-84, 85+)
    local skn_desc = "bronze"
    if skn >= 85 then skn_desc = "deep obsidian"
    elseif skn >= 65 then skn_desc = "weathered olive"
    elseif skn >= 40 then skn_desc = "bronze"
    elseif skn >= 20 then skn_desc = "pale, marble-like"
    else skn_desc = "ghostly, porcelain"
    end

    local hai_color = "copper"
    if hai >= 85 then hai_color = "midnight-black"
    elseif hai >= 65 then hai_color = "dark chestnut"
    elseif hai >= 40 then hai_color = "copper"
    elseif hai >= 20 then hai_color = "platinum-blonde"
    else hai_color = "blood-red"
    end

    local htx_desc = "wavy"
    if htx >= 85 then htx_desc = "tightly coiled"
    elseif htx >= 65 then htx_desc = "curly"
    elseif htx >= 40 then htx_desc = "wavy"
    elseif htx >= 20 then htx_desc = "flowing"
    else htx_desc = "silky straight"
    end

    local eye_desc = "grey"
    if eye >= 85 then eye_desc = "piercing violet"
    elseif eye >= 65 then eye_desc = "amber"
    elseif eye >= 40 then eye_desc = "mist-grey"
    elseif eye >= 20 then eye_desc = "icy blue"
    else eye_desc = "sharp emerald"
    end

    -- 3. Features & Countenance (thresholds match trait_summaries)
    local features = "angular"
    if fsh >= 85 then features = "razor-sharp, hawk-like"
    elseif fsh >= 65 then features = "sharp"
    elseif fsh >= 40 then features = "angular"
    elseif fsh >= 20 then features = "defined"
    else features = "soft, rounded"
    end

    local gaze = "a neutral expression"
    if personality then
        local cruelty = personality:get_axis("PER_CRM") or 50
        local pride = personality:get_axis("PER_PRI") or 50
        local curiosity = personality:get_axis("PER_CUR") or 50
        local volatility = personality:get_axis("PER_VOL") or 50

        if cruelty >= 75 then gaze = "a cold, calculating stare"
        elseif pride >= 75 then gaze = "a look of quiet, unearned disdain"
        elseif curiosity >= 75 then gaze = "a restlessly searching expression"
        elseif volatility >= 75 then gaze = "the erratic focus of a storm"
        elseif cruelty <= 25 then gaze = "a surprisingly soft, empathetic gaze"
        end
    end

    local data = {
        name = name,
        silhouette = silhouette,
        skin = skn_desc,
        hair_text = htx_desc .. " " .. hai_color,
        features = features,
        eyes = eye_desc,
        gaze = gaze
    }

    local templates = {
        "{name} is {silhouette}, with {skin} skin and {hair_text} hair. Their {features} features are punctuated by {eyes} eyes that carry {gaze}.",
        "A {silhouette} with {skin} skin, {name} is marked by {hair_text} hair and {features} features. In their {eyes} eyes, one sees {gaze}.",
        "{name} carries the bloodline as {silhouette}. With {hair_text} hair and {skin} skin, they meet the world with {eyes} eyes and {gaze}.",
    }
    local t = templates[rng.range(1, #templates)]
    
    return t:gsub("{(%w+_?%w*)}", function(k) return tostring(data[k] or k) end)
end

function HeirBiography._mental_line(genome, name, personality)
    local int = genome:get_value("MEN_INT") or 50
    local wil = genome:get_value("MEN_WIL") or 50
    local foc = genome:get_value("MEN_FOC") or 50
    local cun = genome:get_value("MEN_CUN") or 50
    local abs = genome:get_value("MEN_ABS") or 50
    local mem = genome:get_value("MEN_MEM") or 50
    local lrn = genome:get_value("MEN_LRN") or 50
    local pat = genome:get_value("MEN_PAT") or 50

    -- Use full category average so the frame reflects the whole mind
    local avg = HeirBiography._category_average(genome, "mental")

    -- Intellect frame — thresholds aligned to descriptor tiers:
    -- Potent starts at 61, Exalted at 76. An average above Capable = strong mind.
    local mind_frame = "an unremarkable intellect"
    if avg >= 76 then mind_frame = "a mind that borders on the inhuman"
    elseif avg >= 61 then mind_frame = "a sharp, penetrating intellect"
    elseif avg >= 46 then mind_frame = "a serviceable, if unexceptional, intellect"
    elseif avg >= 31 then mind_frame = "a dull, plodding intellect"
    else mind_frame = "a mind clouded and slow"
    end

    -- Willpower
    local will_desc = ""
    if wil >= 80 then will_desc = "Their will is iron — once set, nothing bends it."
    elseif wil >= 65 then will_desc = "They possess a stubborn resolve."
    elseif wil <= 25 then will_desc = "Their will crumbles under the slightest pressure."
    elseif wil <= 40 then will_desc = "They are easily swayed, easily broken."
    end

    -- Secondary mental texture
    local texture = ""
    if cun >= 75 and foc >= 65 then texture = "A schemer who misses nothing."
    elseif abs >= 75 then texture = "They see patterns where others see chaos."
    elseif mem >= 80 then texture = "They forget nothing — grudges least of all."
    elseif lrn >= 75 then texture = "They devour knowledge like a starving animal."
    elseif pat >= 75 then texture = "Patience defines them. They wait. They endure."
    elseif cun >= 70 then texture = "Cunning runs through every thought."
    elseif foc <= 25 then texture = "Scattered. Distracted. Dangerous in their inattention."
    elseif mem <= 25 then texture = "Their memory is a sieve — names, faces, promises, all lost."
    end

    -- Personality color
    local gaze = ""
    if personality then
        local obs = (type(personality.get_axis) == "function" and personality:get_axis("PER_OBS")) or 50
        local cur = (type(personality.get_axis) == "function" and personality:get_axis("PER_CUR")) or 50
        if obs >= 75 then gaze = "Behind their eyes, nothing escapes notice."
        elseif cur >= 75 then gaze = "Every mystery is a wound they must open."
        elseif obs <= 25 then gaze = "They walk through the world half-blind to its workings."
        end
    end

    local parts = {}
    parts[#parts + 1] = string.format("%s possesses %s.", name, mind_frame)
    -- Add contrast connector when core intellect is weak but specific strengths shine
    local mind_low = avg <= 45
    if will_desc ~= "" then
        if mind_low and (wil >= 65) then will_desc = "Yet " .. will_desc:sub(1,1):lower() .. will_desc:sub(2) end
        parts[#parts + 1] = will_desc
    end
    if texture ~= "" then
        if mind_low and will_desc == "" then texture = "Yet " .. texture:sub(1,1):lower() .. texture:sub(2) end
        parts[#parts + 1] = texture
    end
    if gaze ~= "" then parts[#parts + 1] = gaze end

    return table.concat(parts, " ")
end

function HeirBiography._social_line(genome, name, personality)
    local cha = genome:get_value("SOC_CHA") or 50
    local elo = genome:get_value("SOC_ELO") or 50
    local lea = genome:get_value("SOC_LEA") or 50
    local dec = genome:get_value("SOC_DEC") or 50
    local emp = genome:get_value("SOC_EMP") or 50
    local inf = genome:get_value("SOC_INF") or 50
    local tru = genome:get_value("SOC_TRU") or 50
    local hum = genome:get_value("SOC_HUM") or 50

    -- Use full category average so the frame reflects the whole social profile
    local avg = HeirBiography._category_average(genome, "social")

    -- Social presence — thresholds aligned to descriptor tiers
    local presence = "no particular social bearing"
    if avg >= 76 then presence = "a presence that commands rooms without speaking"
    elseif avg >= 61 then presence = "a natural magnetism that draws others close"
    elseif avg >= 46 then presence = "a passable, if unremarkable, social instinct"
    elseif avg >= 31 then presence = "an awkward, forgettable presence"
    else presence = "a repulsive, alienating aura"
    end

    -- Communication style
    local voice = ""
    if elo >= 80 and dec >= 65 then voice = "Their words are silk over a blade."
    elseif elo >= 75 then voice = "When they speak, others listen."
    elseif dec >= 75 then voice = "Every sentence is a half-truth, carefully placed."
    elseif elo <= 25 then voice = "They struggle to string words together."
    end

    -- Leadership & empathy texture
    local texture = ""
    if lea >= 80 then texture = "Born to command. Others follow without knowing why."
    elseif emp >= 75 and tru >= 65 then texture = "They carry the burdens of others as their own."
    elseif emp <= 25 then texture = "The suffering of others does not register."
    elseif inf >= 75 then texture = "They reshape the world through quiet manipulation."
    elseif hum >= 75 then texture = "Their laughter disarms even enemies."
    elseif tru <= 25 then texture = "They trust no one. Not even blood."
    elseif lea <= 25 then texture = "They shrink from authority like a beaten dog."
    end

    -- Personality color
    local manner = ""
    if personality then
        local loy = (type(personality.get_axis) == "function" and personality:get_axis("PER_LOY")) or 50
        local pri = (type(personality.get_axis) == "function" and personality:get_axis("PER_PRI")) or 50
        if loy >= 80 then manner = "Loyalty is their religion."
        elseif pri >= 80 then manner = "They carry themselves as if the world owes them tribute."
        elseif loy <= 20 then manner = "Bonds mean nothing to them."
        end
    end

    local parts = {}
    parts[#parts + 1] = string.format("%s carries %s.", name, presence)
    -- Add contrast connector when social average is weak but specific talents shine
    local social_low = avg <= 45
    if voice ~= "" then
        if social_low then voice = "Yet " .. voice:sub(1,1):lower() .. voice:sub(2) end
        parts[#parts + 1] = voice
    end
    if texture ~= "" then
        if social_low and voice == "" then texture = "Yet " .. texture:sub(1,1):lower() .. texture:sub(2) end
        parts[#parts + 1] = texture
    end
    if manner ~= "" then parts[#parts + 1] = manner end

    return table.concat(parts, " ")
end

function HeirBiography._creative_line(genome, name, personality)
    local vis = genome:get_value("CRE_VIS") or 50
    local cra = genome:get_value("CRE_CRA") or 50
    local mus = genome:get_value("CRE_MUS") or 50
    local rit = genome:get_value("CRE_RIT") or 50
    local sym = genome:get_value("CRE_SYM") or 50
    local arc = genome:get_value("CRE_ARC") or 50
    local nar = genome:get_value("CRE_NAR") or 50
    local imp = genome:get_value("CRE_IMP") or 50

    -- Use full category average so the frame reflects the whole creative profile
    local avg = HeirBiography._category_average(genome, "creative")

    -- Creative core — thresholds aligned to descriptor tiers
    local core = "creatively unremarkable"
    if avg >= 76 then core = "a visionary who sees what has not yet been built"
    elseif avg >= 61 then core = "a mind alive with invention"
    elseif avg >= 46 then core = "a competent but uninspired creator"
    elseif avg >= 31 then core = "a practical soul with no spark of inspiration"
    else core = "utterly devoid of imagination"
    end

    -- Craft & making
    local hands = ""
    if cra >= 80 then hands = "Their hands shape raw material into lasting work."
    elseif cra >= 65 and arc >= 60 then hands = "They build things meant to outlast their maker."
    elseif mus >= 75 then hands = "Music lives in them — rhythm, melody, the architecture of sound."
    elseif cra <= 25 then hands = "They have no feel for craft. Tools rebel in their grip."
    end

    -- Symbolic & ritual depth
    local depth = ""
    if rit >= 75 and sym >= 65 then depth = "They understand the old ceremonies, the weight of symbol and rite."
    elseif sym >= 75 then depth = "They speak in symbols — every gesture carries meaning."
    elseif nar >= 75 then depth = "A born storyteller. History bends to their telling."
    elseif rit >= 70 then depth = "Ritual grounds them. Without ceremony, they are lost."
    elseif imp >= 75 then depth = "They improvise with terrifying confidence."
    elseif arc >= 75 then depth = "Stone and space obey their eye. A builder of monuments."
    end

    -- Personality color
    local spark = ""
    if personality then
        local ada = (type(personality.get_axis) == "function" and personality:get_axis("PER_ADA")) or 50
        local cur = (type(personality.get_axis) == "function" and personality:get_axis("PER_CUR")) or 50
        if ada >= 75 and cur >= 65 then spark = "Creation is their answer to chaos."
        elseif cur >= 80 then spark = "Every surface is a canvas. Every silence, a song waiting."
        elseif ada <= 25 then spark = "They cling to tradition, unable to innovate."
        end
    end

    local parts = {}
    parts[#parts + 1] = string.format("%s is %s.", name, core)
    -- Add contrast connector when creative average is weak but specific talents shine
    local core_low = avg <= 45
    if hands ~= "" then
        if core_low then hands = "Yet " .. hands:sub(1,1):lower() .. hands:sub(2) end
        parts[#parts + 1] = hands
    end
    if depth ~= "" then
        if core_low and hands == "" then depth = "Yet " .. depth:sub(1,1):lower() .. depth:sub(2) end
        parts[#parts + 1] = depth
    end
    if spark ~= "" then parts[#parts + 1] = spark end

    return table.concat(parts, " ")
end

function HeirBiography._education_line(genome, name)
    if not genome.mastery_tags then return nil end

    local tags = {}
    if genome.mastery_tags.MASTER_WARRIOR then tags[#tags + 1] = "the brutal arithmetic of the Flaying Floor" end
    if genome.mastery_tags.MASTER_SCHOLAR then tags[#tags + 1] = "the cold tallies of the Counting House" end
    if genome.mastery_tags.MASTER_SPY then tags[#tags + 1] = "the cooked books of the Back-Ledger" end
    if genome.mastery_tags.MASTER_MYSTIC then tags[#tags + 1] = "the forbidden margins of the Margin Notes" end
    if genome.mastery_tags.MASTER_DIPLOMAT then tags[#tags + 1] = "the indentured courtesies of the Debtor's Walk" end

    if #tags == 0 then return nil end

    return string.format("Schooled in %s, %s carries the marks of their education into adulthood.",
        table.concat(tags, " and "), name)
end

function HeirBiography._personality_line(personality, name)
    local function _get(axis)
        return (type(personality.get_axis) == "function" and personality:get_axis(axis)) or (personality.axes and personality.axes[axis]) or personality[axis] or 50
    end
    local boldness = _get("PER_BLD")
    local cruelty = _get("PER_CRM")
    local loyalty = _get("PER_LOY")
    local curiosity = _get("PER_CUR")

    if cruelty >= 75 then
        return name .. " collects debts in flesh. The ledger knows no mercy."
    elseif loyalty >= 80 then
        return name .. " would bankrupt the treasury defending the bloodline."
    elseif boldness >= 75 then
        return name .. " signs blind, bets heavy, and deals with the terms later."
    elseif curiosity >= 75 then
        return name .. " opens every sealed record — especially the ones marked forbidden."
    elseif cruelty <= 25 then
        return name .. " forgives debts others would kill over. Some call it weakness."
    elseif boldness <= 25 then
        return name .. " reads every clause twice. Moves only on certainty."
    end

    return nil
end

function HeirBiography._era_line(era_key, name, world_name)
    local wn = world_name or "Caldemyr"
    local era_contexts = {
        ancient  = "Born when the ledger was first opened, {name} knows a world where debts are still young.",
        iron     = "Born to the sound of tithes paid in steel, {name} knows no currency but blood.",
        dark     = "Born when the collectors came for everything, {name} learned to survive before learning to breathe.",
        arcane   = "Born when the margins erode and the ink bleeds between worlds, {name} carries power they cannot price.",
        gilded   = "Born into the gilt lie of prosperity, {name} knows the sharp games behind the golden veneer.",
        twilight = "Born as the final audit begins, {name} carries the weight of a closing account.",
    }
    local desc = era_contexts[era_key] or era_contexts.ancient
    return desc:gsub("{name}", name):gsub("Caldemyr", wn)
end

return HeirBiography
