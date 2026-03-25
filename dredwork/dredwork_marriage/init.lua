-- dredwork Marriage — Module Entry
-- Compatibility calculation and marriage type resolution.
-- Ported from Bloodweight's marriage.lua, adapted for event bus.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Marriage = {}
Marriage.__index = Marriage

--- Personality axes used for compatibility.
local PERSONALITY_AXES = { "PER_BLD", "PER_CRM", "PER_OBS", "PER_LOY", "PER_CUR", "PER_VOL", "PER_PRI", "PER_ADA" }

function Marriage.init(engine)
    local self = setmetatable({}, Marriage)
    self.engine = engine

    engine.game_state.marriages = {
        history = {},
    }

    -- Expose marriage data
    engine:on("GET_MARRIAGE_DATA", function(req)
        req.history = self.engine.game_state.marriages.history
    end)

    return self
end

--------------------------------------------------------------------------------
-- Compatibility
--------------------------------------------------------------------------------

--- Calculate personality compatibility between two characters.
---@param personality_a table { PER_BLD = n, PER_CRM = n, ... }
---@param personality_b table same format
---@return number compatibility 0-100 (higher = more compatible)
function Marriage.calculate_compatibility(personality_a, personality_b)
    if not personality_a or not personality_b then return 50 end

    local total_diff = 0
    local count = 0

    for _, axis in ipairs(PERSONALITY_AXES) do
        local a = personality_a[axis] or 50
        local b = personality_b[axis] or 50
        total_diff = total_diff + math.abs(a - b)
        count = count + 1
    end

    if count == 0 then return 50 end
    local avg_diff = total_diff / count
    return Math.clamp(math.floor(100 - avg_diff), 0, 100)
end

--------------------------------------------------------------------------------
-- Marriage Type Resolution
--------------------------------------------------------------------------------

--- Resolve what type of marriage this would be.
---@param params table {
---   heir_personality: table,
---   mate_personality: table,
---   mate_house: table|nil (rival house, if political marriage),
---   is_taboo: boolean|nil,
--- }
---@return table { type, compatibility, narrative_key, is_player_choice }
function Marriage:resolve_type(params)
    local heir_p = params.heir_personality or {}
    local mate_p = params.mate_personality or {}
    local mate_house = params.mate_house
    local is_taboo = params.is_taboo or false

    local compatibility = Marriage.calculate_compatibility(heir_p, mate_p)

    -- 1. FORCED — Hostile powerful house demands political marriage
    if mate_house and (mate_house.disposition or 0) < -20 and (mate_house.power or 0) > 70 then
        return {
            type = "forced",
            compatibility = compatibility,
            narrative_key = "forced",
            is_player_choice = false,
            text = string.format("A political marriage is demanded by %s. There is no refusing.", mate_house.name),
        }
    end

    -- 2. LOVE — High compatibility + loyal + volatile heir
    local loyalty = heir_p.PER_LOY or 50
    local volatility = heir_p.PER_VOL or 50
    if compatibility > 80 and loyalty > 65 and volatility > 50 then
        return {
            type = "love",
            compatibility = compatibility,
            narrative_key = "love",
            is_player_choice = false,
            text = "The heart chooses its own. This union is born of love, not strategy.",
        }
    end

    -- 3. FORBIDDEN — Taboo or very low compatibility
    if is_taboo or compatibility < 30 then
        return {
            type = "forbidden",
            compatibility = compatibility,
            narrative_key = "forbidden",
            is_player_choice = true,
            text = "This match is considered forbidden. To pursue it is to defy tradition.",
        }
    end

    -- 4. ARRANGED — Existing alliance or neutral relationship
    if mate_house and (mate_house.disposition or 0) > -10 then
        return {
            type = "arranged",
            compatibility = compatibility,
            narrative_key = "arranged",
            is_player_choice = true,
            text = string.format("An arranged marriage with %s. A sensible match, if not a passionate one.", mate_house.name),
        }
    end

    -- 5. FREE — Default
    return {
        type = "free",
        compatibility = compatibility,
        narrative_key = "free",
        is_player_choice = true,
        text = "The choice of partner falls to the house. Choose wisely.",
    }
end

--------------------------------------------------------------------------------
-- Execute a Marriage
--------------------------------------------------------------------------------

--- Perform a marriage, applying consequences.
---@param params table { heir, mate, mate_house, marriage_type_result }
function Marriage:perform(params)
    local gs = self.engine.game_state
    local result = params.marriage_type_result
    local mate = params.mate
    local mate_house = params.mate_house

    -- Record in history
    table.insert(gs.marriages.history, {
        day = gs.clock and gs.clock.total_days or 0,
        type = result.type,
        heir_name = params.heir and params.heir.name or "?",
        mate_name = mate and mate.name or "?",
        house = mate_house and mate_house.name or nil,
        compatibility = result.compatibility,
    })

    -- Political consequences
    if mate_house then
        local rivals = self.engine:get_module("rivals")
        if rivals then
            -- Marriage improves disposition
            local delta = result.type == "forced" and 5 or 15
            rivals:change_disposition(mate_house.id, delta)
        end
    end

    -- Add spouse to court
    local court = self.engine:get_module("court")
    if court and mate then
        court:add_member({
            name = mate.name or "Spouse",
            role = "spouse",
            loyalty = Math.clamp(result.compatibility, 30, 95),
            competence = RNG.range(30, 70),
            genome = mate.genome,
        })
    end

    -- Emit event
    local event = {
        type = "marriage",
        marriage_type = result.type,
        compatibility = result.compatibility,
        text = result.text,
        heir_name = params.heir and params.heir.name,
        mate_name = mate and mate.name,
    }
    self.engine:emit("MARRIAGE_PERFORMED", event)
    self.engine:push_ui_event("MARRIAGE_PERFORMED", event)

    self.engine.log:info("Marriage: %s marriage performed (compatibility: %d).", result.type, result.compatibility)
end

function Marriage:serialize() return self.engine.game_state.marriages end
function Marriage:deserialize(data) self.engine.game_state.marriages = data end

return Marriage
