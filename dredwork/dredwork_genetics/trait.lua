local Math = require("dredwork_core.math")
-- Dark Legacy — Trait Module
-- Defines a single trait: create, clone, get/set value.
-- A trait is one of the 70 attributes in the taxonomy (Physical, Mental, Social, Creative).

local Trait = {}
Trait.__index = Trait

-- specialized scales for sensible narrative one-word descriptions
local DESCRIPTOR_SCALES = {
    standard = {
        { max = 15, label = "Wretched" },
        { max = 30, label = "Meager" },
        { max = 45, label = "Mediocre" },
        { max = 60, label = "Capable" },
        { max = 75, label = "Potent" },
        { max = 89, label = "Exalted" },
        { max = 100, label = "Legendary" },
    },
    pigment = {
        { max = 15, label = "Ghostly" },
        { max = 30, label = "Pale" },
        { max = 45, label = "Muted" },
        { max = 60, label = "Vivid" },
        { max = 75, label = "Deep" },
        { max = 89, label = "Dark" },
        { max = 100, label = "Abyssal" },
    },
    magnitude = {
        { max = 15, label = "Diminutive" },
        { max = 30, label = "Slight" },
        { max = 45, label = "Compact" },
        { max = 60, label = "Average" },
        { max = 75, label = "Imposing" },
        { max = 89, label = "Massive" },
        { max = 100, label = "Titanic" },
    },
    texture = {
        { max = 15, label = "Straight" },
        { max = 30, label = "Silky" },
        { max = 45, label = "Wavy" },
        { max = 60, label = "Flowing" },
        { max = 75, label = "Curly" },
        { max = 89, label = "Coiled" },
        { max = 100, label = "Coily" },
    },
    angularity = {
        { max = 15, label = "Soft" },
        { max = 30, label = "Rounded" },
        { max = 45, label = "Defined" },
        { max = 60, label = "Balanced" },
        { max = 75, label = "Angular" },
        { max = 89, label = "Sharp" },
        { max = 100, label = "Razor-Sharp" },
    },
    intensity = {
        { max = 15, label = "Faint" },
        { max = 30, label = "Low" },
        { max = 45, label = "Subtle" },
        { max = 60, label = "Notable" },
        { max = 75, label = "High" },
        { max = 89, label = "Extreme" },
        { max = 100, label = "Absolute" },
    }
}

--- Create a new trait.
---@param params table { id, value, category, visibility, inheritance_mode, scale }
---   id: string              e.g. "PHY_STR"
---   value: number           0-100 integer
---   category: string        "physical" | "mental" | "social" | "creative"
---   visibility: string      "visible" | "hinted" | "hidden"
---   inheritance_mode: string "blended" | "dominant_recessive"
---   scale: string           "standard" | "pigment" | "magnitude" | "texture" | "angularity" | "intensity"
---@return table Trait instance
function Trait.new(params)
    if not params.id then
        params.id = "UNKNOWN"
        print("Warning: Trait.new() called without id, defaulting to UNKNOWN")
    end
    if not params.category then
        params.category = "physical"
        print("Warning: Trait.new() called without category for " .. params.id .. ", defaulting to physical")
    end

    local self = setmetatable({}, Trait)
    self.id = params.id
    self.value = math.floor(Math.clamp(params.value or 50, 0, 100))
    self.category = params.category
    self.visibility = params.visibility or "hidden"
    self.inheritance_mode = params.inheritance_mode or "blended"
    self.scale = params.scale or "standard"
    self.name = params.name or params.id
    self.description = params.description or ""

    -- For dominant/recessive traits: alleles
    -- Each allele: { value = number, dominant = boolean }
    if self.inheritance_mode == "dominant_recessive" then
        self.alleles = params.alleles or {
            { value = self.value, dominant = true },
            { value = self.value, dominant = false },
        }
    end

    return self
end

--- Clone this trait (deep copy, independent of original).
---@return table Trait new independent copy
function Trait:clone()
    local copy = Trait.new({
        id = self.id,
        value = self.value,
        category = self.category,
        visibility = self.visibility,
        inheritance_mode = self.inheritance_mode,
        scale = self.scale,
        name = self.name,
        description = self.description,
    })
    if self.alleles then
        copy.alleles = {
            { value = self.alleles[1].value, dominant = self.alleles[1].dominant },
            { value = self.alleles[2].value, dominant = self.alleles[2].dominant },
        }
    end
    return copy
end

--- Get the expressed value of this trait.
---@return number 0-100
function Trait:get_value()
    if self.inheritance_mode == "dominant_recessive" and self.alleles then
        local a1, a2 = self.alleles[1], self.alleles[2]
        if a1.dominant or a2.dominant then
            -- Express dominant allele value
            if a1.dominant and a2.dominant then
                return math.floor((a1.value + a2.value) / 2)
            elseif a1.dominant then
                return a1.value
            else
                return a2.value
            end
        else
            -- Both recessive: average
            return math.floor((a1.value + a2.value) / 2)
        end
    end
    return self.value
end

--- Set the base value (clamped 0-100).
---@param v number
function Trait:set_value(v)
    self.value = math.floor(Math.clamp(v, 0, 100))
end

--- Get the hinted descriptor string for this trait's current value.
---@return string
function Trait:get_descriptor()
    local v = self:get_value()
    local scale = DESCRIPTOR_SCALES[self.scale] or DESCRIPTOR_SCALES.standard
    for _, d in ipairs(scale) do
        if v <= d.max then return d.label end
    end
    return scale[#scale].label
end

return Trait
