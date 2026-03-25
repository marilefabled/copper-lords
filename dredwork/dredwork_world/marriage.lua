-- Dark Legacy — Marriage Type Resolver
-- Determines the narrative context and constraints of each generation's union.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local ok_narr, marriage_narratives = pcall(require, "dredwork_world.config.marriage_narratives")
if not ok_narr then marriage_narratives = {} end

local Marriage = {}

-- Internal: check compatibility between heir personality and a mate
local function _calculate_compatibility(heir_personality, mate_personality)
    if not heir_personality or not mate_personality then return 50 end
    local axes = { "PER_BLD", "PER_CRM", "PER_OBS", "PER_LOY", "PER_CUR", "PER_VOL", "PER_PRI", "PER_ADA" }
    local score = 0
    local count = 0
    for _, axis in ipairs(axes) do
        local a = heir_personality:get_axis(axis) or 50
        local b = mate_personality:get_axis(axis) or 50
        local diff = math.abs(a - b)
        score = score + (100 - diff)
        count = count + 1
    end
    return count > 0 and math.floor(score / count) or 50
end

-- Internal: pick a random narrative from a pool
local function _pick(pool)
    if not pool or #pool == 0 then return "" end
    return pool[rng.range(1, #pool)]
end

--- Resolve the type of marriage for this generation's matchmaking.
-- Checked in priority order: forced, love, arranged, forbidden, free.
---@param heir_personality table Personality instance
---@param mate table { personality, faction_id, compatibility }
---@param cultural_memory table CulturalMemory instance
---@param faction table|nil Faction instance of the mate's house
---@param era string|nil current era key
---@param generation number current generation
---@return table { type, narrative, player_chooses, compatibility }
function Marriage.resolve_type(heir_personality, mate, cultural_memory, faction, era, generation)
    local mate_personality = mate and mate.personality or nil
    local compatibility = mate and mate.compatibility or _calculate_compatibility(heir_personality, mate_personality)
    local faction_id = mate and mate.faction_id or nil

    -- 1. FORCED — hostile faction with high power demands political marriage
    if faction and faction.disposition and faction.disposition < -20 and faction.power and faction.power > 70 then
        local narr = marriage_narratives.forced or {}
        return {
            type = "forced",
            narrative = _pick(narr.intro),
            player_chooses = false,
            compatibility = compatibility,
        }
    end

    -- 2. LOVE — high compatibility + loyal + volatile heir chooses autonomously
    local loyalty = heir_personality and (heir_personality:get_axis("PER_LOY") or 50) or 50
    local volatility = heir_personality and (heir_personality:get_axis("PER_VOL") or 50) or 50
    if compatibility > 80 and loyalty > 65 and volatility > 50 then
        local narr = marriage_narratives.love or {}
        return {
            type = "love",
            narrative = _pick(narr.intro),
            player_chooses = false,
            compatibility = compatibility,
        }
    end

    -- 3. FORBIDDEN — taboo against mate's faction OR very low compatibility
    if faction_id and cultural_memory then
        local taboo_effect = "will_never_ally_with_" .. faction_id
        if cultural_memory:is_taboo(taboo_effect) then
            local narr = marriage_narratives.forbidden or {}
            return {
                type = "forbidden",
                narrative = _pick(narr.intro),
                player_chooses = true,
                compatibility = compatibility,
            }
        end
    end
    if compatibility < 30 then
        local narr = marriage_narratives.forbidden or {}
        return {
            type = "forbidden",
            narrative = _pick(narr.intro),
            player_chooses = true,
            compatibility = compatibility,
        }
    end

    -- 4. ARRANGED — existing relationship with mate's faction
    if faction_id and cultural_memory and cultural_memory.relationships then
        for _, rel in ipairs(cultural_memory.relationships) do
            if rel.faction == faction_id and (rel.type == "ally" or rel.type == "neutral") then
                local narr = marriage_narratives.arranged or {}
                return {
                    type = "arranged",
                    narrative = _pick(narr.intro),
                    player_chooses = true,
                    compatibility = compatibility,
                }
            end
        end
    end

    -- 5. FREE — default
    local narr = marriage_narratives.free or {}
    return {
        type = "free",
        narrative = _pick(narr.intro),
        player_chooses = true,
        compatibility = compatibility,
    }
end

--- Get the transition card quote for a marriage type.
---@param marriage_type string
---@return string
function Marriage.get_transition_quote(marriage_type)
    local narr = marriage_narratives[marriage_type] or marriage_narratives.free or {}
    return _pick(narr.transition_quote)
end

--- Get the offspring header for a marriage type.
---@param marriage_type string
---@return string
function Marriage.get_offspring_header(marriage_type)
    local narr = marriage_narratives[marriage_type] or marriage_narratives.free or {}
    return _pick(narr.offspring_header)
end

return Marriage
