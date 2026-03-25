-- dredwork Biography — Module Entry
-- Wild attributes (emergent hero archetypes) and biography generation.
-- Ported from Bloodweight's heir_biography.lua, adapted for event bus.

local RNG = require("dredwork_core.rng")

local Biography = {}
Biography.__index = Biography

--- Wild attribute definitions: trait/personality thresholds → emergent archetype.
local WILD_ATTRIBUTES = {
    { id = "berserker",     label = "Berserker",     category = "physical", bonus = 10,
      requires = { { trait = "PHY_STR", min = 75 }, { trait = "PHY_END", min = 60 }, { axis = "PER_VOL", min = 65 } } },
    { id = "titan",         label = "Titan",         category = "physical", bonus = 15,
      requires = { { trait = "PHY_STR", min = 80 }, { trait = "PHY_END", min = 75 }, { trait = "PHY_VIT", min = 70 } } },
    { id = "silver_tongue", label = "Silver Tongue",  category = "social",   bonus = 10,
      requires = { { trait = "SOC_ELO", min = 75 }, { trait = "SOC_CHA", min = 65 } } },
    { id = "iron_mind",     label = "Iron Mind",      category = "mental",   bonus = 10,
      requires = { { trait = "MEN_WIL", min = 75 }, { trait = "MEN_FOC", min = 65 } } },
    { id = "prodigy",       label = "Prodigy",        category = "mental",   bonus = 12,
      requires = { { trait = "MEN_INT", min = 80 }, { trait = "MEN_LRN", min = 70 } } },
    { id = "shadow",        label = "Shadow",         category = "social",   bonus = 10,
      requires = { { trait = "SOC_DEC", min = 75 }, { axis = "PER_OBS", min = 65 } } },
    { id = "wall",          label = "The Wall",       category = "physical", bonus = 12,
      requires = { { trait = "PHY_END", min = 80 }, { trait = "PHY_VIT", min = 70 }, { axis = "PER_LOY", min = 60 } } },
    { id = "firebrand",     label = "Firebrand",      category = "social",   bonus = 10,
      requires = { { trait = "SOC_CHA", min = 70 }, { axis = "PER_BLD", min = 70 }, { axis = "PER_VOL", min = 60 } } },
    { id = "schemer",       label = "Schemer",        category = "mental",   bonus = 10,
      requires = { { trait = "MEN_INT", min = 65 }, { trait = "SOC_DEC", min = 65 }, { axis = "PER_CUR", min = 60 } } },
    { id = "artisan",       label = "Master Artisan",  category = "creative", bonus = 10,
      requires = { { trait = "CRE_CRA", min = 75 }, { trait = "CRE_INN", min = 60 } } },
    { id = "visionary",     label = "Visionary",      category = "creative", bonus = 12,
      requires = { { trait = "CRE_VIS", min = 80 }, { trait = "MEN_INT", min = 65 } } },
    { id = "survivor",      label = "Survivor",       category = "physical", bonus = 8,
      requires = { { trait = "PHY_VIT", min = 70 }, { trait = "PHY_END", min = 60 }, { axis = "PER_ADA", min = 60 } } },
    { id = "paragon",       label = "Paragon",        category = "social",   bonus = 15,
      requires = { { trait = "SOC_CHA", min = 75 }, { trait = "SOC_EMP", min = 70 }, { axis = "PER_LOY", min = 70 } } },
}

function Biography.init(engine)
    local self = setmetatable({}, Biography)
    self.engine = engine

    engine.game_state.biography = {
        wild_attributes = {},  -- current heir's active wild attributes
        biography_text = "",
    }

    -- Expose biography data
    engine:on("GET_BIOGRAPHY_DATA", function(req)
        req.wild_attributes = self.engine.game_state.biography.wild_attributes
        req.biography_text = self.engine.game_state.biography.biography_text
    end)

    -- Recalculate on generation change
    engine:on("ADVANCE_GENERATION", function(context)
        self:recalculate(self.engine.game_state)
    end)

    return self
end

--------------------------------------------------------------------------------
-- Wild Attribute Detection
--------------------------------------------------------------------------------

--- Detect wild attributes for a character.
---@param get_trait function(trait_id) → number
---@param get_axis function(axis_id) → number
---@return table array of matched wild attribute definitions
function Biography.detect_wild_attributes(get_trait, get_axis)
    local matched = {}

    for _, wa in ipairs(WILD_ATTRIBUTES) do
        local all_met = true
        for _, req in ipairs(wa.requires) do
            local val
            if req.trait then
                val = get_trait(req.trait) or 0
            elseif req.axis then
                val = get_axis(req.axis) or 0
            end
            if not val or val < (req.min or 0) then
                all_met = false
                break
            end
        end
        if all_met then
            table.insert(matched, {
                id = wa.id,
                label = wa.label,
                category = wa.category,
                bonus = wa.bonus,
            })
        end
    end

    return matched
end

--------------------------------------------------------------------------------
-- Biography Generation
--------------------------------------------------------------------------------

--- Generate a biography for the current heir.
function Biography:recalculate(gs)
    local heir = gs.current_heir
    if not heir then return end

    -- Build trait/axis accessors
    local function get_trait(id)
        if heir.traits and heir.traits[id] then
            local t = heir.traits[id]
            return type(t) == "table" and t.value or t
        end
        if heir[id] then return heir[id] end
        return 50
    end

    local function get_axis(id)
        return get_trait(id)
    end

    -- Detect wild attributes
    local wilds = Biography.detect_wild_attributes(get_trait, get_axis)
    gs.biography.wild_attributes = wilds

    -- Generate biography text
    local lines = {}
    local name = heir.name or "The heir"

    -- Physical line
    local str = get_trait("PHY_STR")
    local end_val = get_trait("PHY_END")
    if str > 70 and end_val > 60 then
        table.insert(lines, name .. " is powerfully built, with the frame of a warrior.")
    elseif str < 35 then
        table.insert(lines, name .. " is slight of frame, more scholar than soldier.")
    else
        table.insert(lines, name .. " carries themselves with quiet physical confidence.")
    end

    -- Mental line
    local int = get_trait("MEN_INT")
    local wil = get_trait("MEN_WIL")
    if int > 70 then
        table.insert(lines, "A keen mind burns behind their eyes — few puzzles escape their grasp.")
    elseif wil > 70 then
        table.insert(lines, "What they lack in brilliance, they make up for in iron determination.")
    end

    -- Social line
    local cha = get_trait("SOC_CHA")
    local emp = get_trait("SOC_EMP")
    if cha > 70 and emp > 60 then
        table.insert(lines, "People are drawn to " .. name .. " — their warmth is genuine, their presence magnetic.")
    elseif cha > 70 and emp < 40 then
        table.insert(lines, name .. " commands attention, though some say their charm masks a cold heart.")
    end

    -- Wild attributes
    for _, wa in ipairs(wilds) do
        table.insert(lines, string.format("They bear the mark of the %s — a rare and formidable gift.", wa.label))
    end

    gs.biography.biography_text = table.concat(lines, " ")

    -- Emit for narrative
    if #wilds > 0 then
        self.engine:emit("WILD_ATTRIBUTE_DETECTED", { heir_name = name, attributes = wilds })
    end
end

--- Get category bonuses from wild attributes (for stat checks).
function Biography:get_category_bonuses()
    local bonuses = { physical = 0, mental = 0, social = 0, creative = 0 }
    for _, wa in ipairs(self.engine.game_state.biography.wild_attributes) do
        bonuses[wa.category] = (bonuses[wa.category] or 0) + wa.bonus
    end
    return bonuses
end

function Biography:serialize() return self.engine.game_state.biography end
function Biography:deserialize(data) self.engine.game_state.biography = data end

return Biography
