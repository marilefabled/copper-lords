local Math = require("dredwork_core.math")
-- Dark Legacy — Rival Heir System
-- Each faction has a named heir with traits, personality, and history.
-- Rival heirs get personal: they appear in events, crucibles, and council.
-- They age, die, and are succeeded — just like the player's lineage.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local genetics = require("dredwork_genetics.init")
local FactionGenetics = require("dredwork_world.faction_genetics")

local RivalHeirs = {}

-- =========================================================================
-- Name generation (inlined to avoid Solar2D bridge dependency)
-- =========================================================================

local _prefixes = {
    "Ar", "Bel", "Cor", "Dra", "El", "Fen", "Gal", "Har", "Ir", "Jas",
    "Kal", "Lor", "Mor", "Ner", "Or", "Pal", "Rav", "Sal", "Thar",
    "Ul", "Val", "Wren", "Xan", "Yr", "Zel", "Ash", "Bry", "Cael", "Dorn",
    "Eld", "Fay", "Grim", "Hael", "Ith", "Jor", "Kael", "Lyc", "Mael", "Nyx",
}
local _middles = {
    "an", "en", "in", "on", "ar", "er", "ir", "or", "al", "el",
    "is", "os", "eth", "ith", "ael", "ra", "re", "ri", "la", "le",
}
local _suffixes = {
    "a", "e", "i", "o", "us", "is", "as", "es", "on", "an",
    "iel", "ael", "eth", "ith", "or", "ar", "en", "in", "yr", "ax",
}

local function _gen_name()
    local name = _prefixes[rng.range(1, #_prefixes)]
    if rng.chance(0.6) then
        name = name .. _middles[rng.range(1, #_middles)]
    end
    name = name .. _suffixes[rng.range(1, #_suffixes)]
    return name
end

-- =========================================================================
-- Rival Heir: one named NPC per faction
-- =========================================================================

--- Generate a rival heir for a faction.
---@param faction table Faction instance
---@param generation number current generation
---@param predecessor table|nil existing rival_heir for breeding
---@return table rival_heir
function RivalHeirs.generate(faction, generation, predecessor)
    local genome, personality
    local axes = { "PER_BLD", "PER_CRM", "PER_OBS", "PER_LOY", "PER_CUR", "PER_VOL", "PER_PRI", "PER_ADA" }

    if predecessor and predecessor.genome then
        -- Succession: BREED the next heir
        -- 1. Create a "Mate" from the faction's genetic baseline
        local mate_baseline = FactionGenetics.get_mate_baseline(faction)
        -- FIX: Use correct constructor for Genome
        local mate_traits_table = {}
        for id, val in pairs(mate_baseline) do
            mate_traits_table[id] = { value = val }
        end
        local mate_genome = genetics.Genome.from_table({ traits = mate_traits_table })
        local mate_personality = genetics.Personality.new() -- random personality for mate

        -- 2. Breed the successor
        local predecessor_traits = {}
        for id, val in pairs(predecessor.genome) do
            predecessor_traits[id] = { value = val }
        end
        local predecessor_genome = genetics.Genome.from_table({ traits = predecessor_traits })
        local predecessor_personality = genetics.Personality.from_table(predecessor.personality)
        
        local child_genome = genetics.Inheritance.breed(
            predecessor_genome,
            mate_genome
        )
        
        -- Succession personality: drift from predecessor
        local child_personality = genetics.Personality.from_table(predecessor.personality)
        -- Small random drift for each axis
        for _, axis in ipairs(axes) do
            local current = child_personality:get_axis(axis) or 50
            child_personality.axes[axis] = Math.clamp(current + rng.range(-10, 10), 0, 100)
        end
        
        -- 3. Apply Faction Bias (drift toward house specialty)
        local dominant_cat = faction:get_dominant_category()
        local cat_prefix = ({ physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE" })[dominant_cat]
        for id, trait in pairs(child_genome.traits) do
            if id:sub(1, 3) == cat_prefix then
                trait:set_value(math.min(100, trait:get_value() + rng.range(2, 8)))
            end
        end

        -- Store as flat traits for the next generation's predecessor logic
        genome = {}
        for id, trait in pairs(child_genome.traits) do
            genome[id] = trait:get_value()
        end
        personality = child_personality:to_table()
    else
        -- Initial Generation: Create fresh
        -- Derive personality from faction personality (biased, not identical)
        personality = {}
        for _, axis in ipairs(axes) do
            local base = faction.personality and faction.personality[axis] or 50
            personality[axis] = Math.clamp(base + rng.range(-15, 15), 0, 100)
        end

        -- Derive dominant trait from faction category
        local dominant_cat = faction:get_dominant_category()
        local best_score = faction.category_scores[dominant_cat] or 50

        -- Generate trait strengths
        local traits = {}
        local averages = FactionGenetics.get_mate_baseline(faction)
        for id, val in pairs(averages) do
            traits[id] = val
        end
        
        local cat_traits = {
            physical = { "PHY_STR", "PHY_END", "PHY_VIT", "PHY_AGI" },
            mental = { "MEN_INT", "MEN_WIL", "MEN_FOC", "MEN_ANA" },
            social = { "SOC_CHA", "SOC_ELO", "SOC_INM", "SOC_NEG" },
            creative = { "CRE_ING", "CRE_CRA", "CRE_VIS", "CRE_EXP" },
        }
        local pool = cat_traits[dominant_cat] or cat_traits.physical
        for _, trait_id in ipairs(pool) do
            traits[trait_id] = math.floor(best_score * 0.8 + rng.range(-10, 10))
            traits[trait_id] = Math.clamp(traits[trait_id], 20, 95)
        end
        genome = traits
    end

    -- Attitude toward player (derived from faction disposition + personality)
    local attitude = RivalHeirs._compute_attitude(faction.disposition, personality)

    return {
        name = _gen_name(),
        faction_id = faction.id,
        faction_name = faction.name,
        generation_born = generation,
        generation_died = nil,
        personality = personality,
        genome = genome, 
        dominant_category = faction:get_dominant_category(),
        attitude = attitude,        -- "hostile", "wary", "neutral", "respectful", "devoted"
        rivalry_score = 0,          -- accumulates from interactions (-100 to 100)
        history = {},               -- array of { generation, event, description }
        alive = true,
        resources = {
            gold = rng.range(20, 60),
            steel = rng.range(10, 40),
            lore = rng.range(5, 30)
        }
    }
end

--- Compute attitude string from disposition and personality.
---@param disposition number faction disposition (-100 to 100)
---@param personality table personality axes
---@return string attitude
function RivalHeirs._compute_attitude(disposition, personality)
    local cruelty = personality.PER_CRM or 50
    local pride = personality.PER_PRI or 50
    local loyalty = personality.PER_LOY or 50

    -- Hostile rivals are more dangerous, friendly ones more useful
    local score = disposition
    -- Cruel heirs are meaner at any disposition level
    score = score - (cruelty - 50) * 0.3
    -- Proud heirs take offense more easily
    score = score - (pride - 50) * 0.2
    -- Loyal heirs follow their faction's lead more closely
    score = score + (loyalty - 50) * 0.1

    if score <= -50 then return "hostile"
    elseif score <= -15 then return "wary"
    elseif score <= 25 then return "neutral"
    elseif score <= 60 then return "respectful"
    else return "devoted"
    end
end

--- Update a rival heir's attitude based on current faction state.
---@param rival table rival_heir
---@param faction table Faction instance
function RivalHeirs.update_attitude(rival, faction)
    if not rival.alive then return end
    rival.attitude = RivalHeirs._compute_attitude(faction.disposition, rival.personality)
end

--- Record an interaction between player heir and rival heir.
---@param rival table rival_heir
---@param generation number
---@param event_type string short descriptor ("insult", "duel", "alliance", "betrayal", etc.)
---@param description string narrative text
---@param rivalry_delta number change to rivalry_score
function RivalHeirs.record_interaction(rival, generation, event_type, description, rivalry_delta)
    rival.history[#rival.history + 1] = {
        generation = generation,
        event = event_type,
        description = description,
    }
    rival.rivalry_score = Math.clamp(rival.rivalry_score + (rivalry_delta or 0), -100, 100)
end

--- Check if a rival heir dies this generation (aging + danger).
--- Rival heirs last 2-4 generations on average.
---@param rival table rival_heir
---@param generation number current generation
---@param faction table Faction instance
---@return boolean died
---@return string|nil cause
function RivalHeirs.check_death(rival, generation, faction)
    if not rival.alive then return false, nil end

    local age = generation - rival.generation_born
    if age < 1 then return false, nil end

    -- Base death chance increases with age
    local death_chance = 0
    if age >= 4 then
        death_chance = 0.6
    elseif age >= 3 then
        death_chance = 0.35
    elseif age >= 2 then
        death_chance = 0.15
    elseif age >= 1 then
        death_chance = 0.05
    end

    -- Hostile disposition + low power = more dangerous life
    if faction.disposition <= -40 then
        death_chance = death_chance + 0.1
    end
    if faction.power <= 30 then
        death_chance = death_chance + 0.1
    end

    if rng.chance(death_chance) then
        rival.alive = false
        rival.generation_died = generation

        -- Determine cause
        local causes = {
            "fell in battle",
            "succumbed to illness",
            "was assassinated",
            "died of old age",
            "perished in a failed gambit",
        }
        if faction.power <= 30 then
            causes[#causes + 1] = "was overthrown by rivals within " .. faction.name
        end
        if faction.disposition <= -50 then
            causes[#causes + 1] = "died leading a campaign against your bloodline"
        end
        local cause = causes[rng.range(1, #causes)]
        return true, cause
    end

    return false, nil
end

--- Get a narrative description of a rival heir.
---@param rival table rival_heir
---@return string
function RivalHeirs.describe(rival)
    if not rival then return "" end

    local attitude_desc = {
        hostile = "burns with hatred for your bloodline",
        wary = "watches your bloodline with suspicion",
        neutral = "regards your bloodline with cool indifference",
        respectful = "holds a grudging respect for your bloodline",
        devoted = "considers your bloodline a trusted ally",
    }

    local pers_desc = ""
    local p = rival.personality
    if p.PER_CRM >= 70 then
        pers_desc = "cruel and calculating"
    elseif p.PER_BLD >= 70 then
        pers_desc = "bold and reckless"
    elseif p.PER_CUR >= 70 then
        pers_desc = "endlessly curious"
    elseif p.PER_PRI >= 70 then
        pers_desc = "consumed by pride"
    elseif p.PER_LOY >= 70 then
        pers_desc = "fiercely loyal to their house"
    elseif p.PER_VOL >= 70 then
        pers_desc = "volatile and unpredictable"
    elseif p.PER_OBS >= 70 then
        pers_desc = "single-minded in pursuit"
    else
        pers_desc = "measured and deliberate"
    end

    local att = attitude_desc[rival.attitude] or "regards your bloodline with indifference"

    return rival.name .. " of " .. rival.faction_name .. ", " ..
        pers_desc .. ", " .. att .. "."
end

--- Get a short label for UI display.
---@param rival table rival_heir
---@return string
function RivalHeirs.get_label(rival)
    if not rival then return "" end
    return rival.name .. " of " .. rival.faction_name
end

-- =========================================================================
-- Rival Heir Manager: manages all rival heirs across factions
-- =========================================================================

local RivalHeirManager = {}
RivalHeirManager.__index = RivalHeirManager

--- Create a new manager.
---@return table RivalHeirManager
function RivalHeirManager.new()
    local self = setmetatable({}, RivalHeirManager)
    self.heirs = {}       -- { [faction_id] = rival_heir }
    self.graveyard = {}   -- array of dead rivals (for history/echoes)
    return self
end

--- Ensure every active faction has a living heir. Generate replacements for dead/missing.
---@param factions table FactionManager
---@param generation number current generation
---@param context table|nil world context for strategy logic
---@return table array of { event = "succession"|"new", rival, faction, cause }
function RivalHeirManager:tick(factions, generation, context)
    local events = {}

    for _, faction in ipairs(factions:get_active()) do
        local existing = self.heirs[faction.id]

        if existing and existing.alive then
            -- 1. Check for death
            local died, cause = RivalHeirs.check_death(existing, generation, faction)
            if died then
                self.graveyard[#self.graveyard + 1] = existing
                while #self.graveyard > 20 do table.remove(self.graveyard, 1) end
                -- Generate successor (Succession BREEDING)
                local successor = RivalHeirs.generate(faction, generation, existing)
                -- Inherit some rivalry from predecessor
                successor.rivalry_score = math.floor(existing.rivalry_score * 0.5)
                if #existing.history > 0 then
                    successor.history[#successor.history + 1] = {
                        generation = generation,
                        event = "inherited_grudge",
                        description = successor.name .. " remembers what was done to " .. existing.name .. ".",
                    }
                end
                self.heirs[faction.id] = successor
                events[#events + 1] = {
                    event = "succession",
                    rival = successor,
                    predecessor = existing,
                    faction = faction,
                    cause = cause,
                }
            else
                -- 2. Rival Strategy: Active moves against/with player
                self:_execute_rival_strategy(existing, faction, generation, context)
                -- Update attitude
                RivalHeirs.update_attitude(existing, faction)
            end
        elseif existing and not existing.alive then
            -- Dead heir needs replacement (succession)
            self.graveyard[#self.graveyard + 1] = existing
            while #self.graveyard > 20 do table.remove(self.graveyard, 1) end
            local successor = RivalHeirs.generate(faction, generation, existing)
            successor.rivalry_score = math.floor(existing.rivalry_score * 0.5)
            -- Inherit grudge if predecessor had history
            if #existing.history > 0 then
                successor.history[#successor.history + 1] = {
                    generation = generation,
                    event = "inherited_grudge",
                    description = successor.name .. " remembers what was done to " .. existing.name .. ".",
                }
            end
            self.heirs[faction.id] = successor
            events[#events + 1] = {
                event = "succession",
                rival = successor,
                predecessor = existing,
                faction = faction,
                cause = "predecessor fell",
            }
        elseif not existing then
            -- No heir at all — generate fresh
            local heir = RivalHeirs.generate(faction, generation)
            self.heirs[faction.id] = heir
            events[#events + 1] = {
                event = "new",
                rival = heir,
                faction = faction,
            }
        end
    end

    return events
end

--- Internal: Execute active moves for a rival heir based on their personality and resources.
function RivalHeirManager:_execute_rival_strategy(rival, faction, generation, context)
    if not rival or not rival.alive then return end
    
    -- Accumulate passive resources
    rival.resources = rival.resources or { gold = 10, steel = 5, lore = 2 }
    rival.resources.gold = rival.resources.gold + math.floor(faction.power / 10)
    rival.resources.steel = rival.resources.steel + (rival.dominant_category == "physical" and 3 or 1)
    rival.resources.lore = rival.resources.lore + (rival.dominant_category == "mental" and 2 or 0)

    -- Strategy based on attitude
    if rival.attitude == "hostile" and rng.chance(0.25) then
        -- Aggressive move: sabotage player power
        if rival.resources.steel >= 15 then
            rival.resources.steel = rival.resources.steel - 15
            if context and context.lineage_power then
                local LP = require("dredwork_world.lineage_power")
                LP.shift(context.lineage_power, -5)
                local desc = rival.name .. " funded a border raid against your holdings."
                rival.history[#rival.history + 1] = {
                    generation = generation,
                    event = "raid",
                    description = desc,
                }
                if context.world_state then
                    context.world_state:add_chronicle(desc)
                end
                -- Damage a holding
                if context.holdings and rng.chance(0.3) then
                    local damage_text = context.holdings:damage_random_domain()
                    if damage_text and context.world_state then
                        context.world_state:add_chronicle(damage_text)
                    end
                end
            end
        end
    elseif rival.attitude == "wary" and rng.chance(0.15) then
        -- Diplomatic pressure: demand tribute
        if context and context.resources and context.resources.gold >= 20 then
            context.resources:change("gold", -10, "Tribute to " .. rival.name)
            local desc = rival.name .. " demanded a tribute to maintain the fragile peace."
            rival.history[#rival.history + 1] = {
                generation = generation,
                event = "tribute",
                description = desc,
            }
            if context.world_state then
                context.world_state:add_chronicle(desc)
            end
        end
    elseif rival.attitude == "devoted" and rng.chance(0.20) then
        -- Supportive move: gift resources
        if rival.resources.gold >= 20 then
            rival.resources.gold = rival.resources.gold - 20
            if context and context.resources then
                context.resources:change("gold", 10, rival.name .. "'s tribute")
                local desc = rival.name .. " sent a chest of gold to reaffirm your alliance."
                rival.history[#rival.history + 1] = {
                    generation = generation,
                    event = "gift",
                    description = desc,
                }
                if context.world_state then
                    context.world_state:add_chronicle(desc)
                end
            end
        end
    end
end

--- Get the rival heir for a faction.
---@param faction_id string
---@return table|nil rival_heir
function RivalHeirManager:get(faction_id)
    return self.heirs[faction_id]
end

--- Get all living rival heirs.
---@return table array of rival_heir
function RivalHeirManager:get_all_living()
    local result = {}
    for _, rival in pairs(self.heirs) do
        if rival.alive then
            result[#result + 1] = rival
        end
    end
    return result
end

--- Get the most hostile living rival.
---@return table|nil rival_heir
function RivalHeirManager:get_nemesis()
    local worst, worst_score = nil, 999
    for _, rival in pairs(self.heirs) do
        if rival.alive and rival.rivalry_score < worst_score then
            worst = rival
            worst_score = rival.rivalry_score
        end
    end
    return worst
end

--- Get the friendliest living rival.
---@return table|nil rival_heir
function RivalHeirManager:get_closest_ally()
    local best, best_score = nil, -999
    for _, rival in pairs(self.heirs) do
        if rival.alive and rival.rivalry_score > best_score then
            best = rival
            best_score = rival.rivalry_score
        end
    end
    return best
end

--- Get rivals that match a filter.
---@param filter table { attitude, min_rivalry, max_rivalry, faction_id, dominant_category }
---@return table array of rival_heir
function RivalHeirManager:find(filter)
    local result = {}
    for _, rival in pairs(self.heirs) do
        if rival.alive then
            local match = true
            if filter.attitude and rival.attitude ~= filter.attitude then match = false end
            if filter.min_rivalry and rival.rivalry_score < filter.min_rivalry then match = false end
            if filter.max_rivalry and rival.rivalry_score > filter.max_rivalry then match = false end
            if filter.faction_id and rival.faction_id ~= filter.faction_id then match = false end
            if filter.dominant_category and rival.dominant_category ~= filter.dominant_category then match = false end
            if match then result[#result + 1] = rival end
        end
    end
    return result
end

--- Get dead rivals from the graveyard.
---@param max number|nil max entries (default 10)
---@return table array of rival_heir (most recent first)
function RivalHeirManager:get_graveyard(max)
    max = max or 10
    local result = {}
    local start = math.max(1, #self.graveyard - max + 1)
    for i = #self.graveyard, start, -1 do
        result[#result + 1] = self.graveyard[i]
    end
    return result
end

--- Serialize.
---@return table
function RivalHeirManager:to_table()
    local data = { heirs = {}, graveyard = {} }
    for fid, rival in pairs(self.heirs) do
        data.heirs[fid] = rival
    end
    for _, dead in ipairs(self.graveyard) do
        data.graveyard[#data.graveyard + 1] = dead
    end
    return data
end

--- Restore from saved data.
---@param data table
---@return table RivalHeirManager
function RivalHeirManager.from_table(data)
    local self = setmetatable({}, RivalHeirManager)
    self.heirs = data.heirs or {}
    self.graveyard = data.graveyard or {}
    return self
end

return {
    RivalHeirs = RivalHeirs,
    RivalHeirManager = RivalHeirManager,
}
