local Math = require("dredwork_core.math")
-- Dark Legacy — Inheritance & Crossover Engine
-- Handles breeding two genomes to produce a child genome.
-- Supports blended inheritance and dominant/recessive with allele passing.

local Trait = require("dredwork_genetics.trait")
local Genome = require("dredwork_genetics.genome")
local rng = require("dredwork_core.rng")
local trait_definitions = require("dredwork_genetics.config.trait_definitions")

local Inheritance = {}

-- Doctrine modifier lookup (set externally by GeneticsController before breeding)
Inheritance._doctrine_modifiers = nil

--- Breed two parent genomes to produce a child genome.
---@param parent_a table Genome
---@param parent_b table Genome
---@return table Genome child
function Inheritance.breed(parent_a, parent_b)
    local child_overrides = {}

    for _, def in ipairs(trait_definitions) do
        local id = def.id
        local ta = parent_a:get_trait(id)
        local tb = parent_b:get_trait(id)
        if ta and tb then
            if def.inheritance_mode == "blended" then
                child_overrides[id] = Inheritance._blend(ta, tb, id)
            else
                child_overrides[id] = Inheritance._dominant_recessive_value(ta, tb)
            end
        end
    end

    -- Create child with calculated values
    local child = Genome.new(child_overrides)

    -- For dominant/recessive traits, set up proper alleles on the child
    for _, def in ipairs(trait_definitions) do
        if def.inheritance_mode == "dominant_recessive" then
            local ta = parent_a:get_trait(def.id)
            local tb = parent_b:get_trait(def.id)
            if ta and tb then
                local child_trait = child:get_trait(def.id)
                if child_trait then
                    child_trait.alleles = Inheritance._pass_alleles(ta, tb)
                end
            end
        end
    end

    return child
end

--- Blended inheritance: weighted average + noise.
---@param ta table Trait from parent A
---@param tb table Trait from parent B
---@return number child value
function Inheritance._blend(ta, tb, trait_id)
    -- Random weight split
    local w = rng.random()
    local avg = ta:get_value() * w + tb:get_value() * (1 - w)
    local noise = rng.range(-5, 5)

    -- Apply doctrine inheritance bias if set
    if Inheritance._doctrine_modifiers and trait_id then
        local prefix = trait_id:sub(1, 3)
        local cat_key = ({ PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" })[prefix]
        if cat_key then
            local bias = Inheritance._doctrine_modifiers[cat_key .. "_inheritance_bias"] or 0
            noise = noise + bias * 0.1 -- Scale: +10 bias → +1 average per breed
        end
    end

    return math.floor(Math.clamp(avg + noise), 0, 100)
end

--- Dominant/recessive: pass one allele from each parent, express accordingly.
---@param ta table Trait from parent A (has alleles)
---@param tb table Trait from parent B (has alleles)
---@return number expressed child value
function Inheritance._dominant_recessive_value(ta, tb)
    local alleles = Inheritance._pass_alleles(ta, tb)
    local a1, a2 = alleles[1], alleles[2]

    if a1.dominant or a2.dominant then
        if a1.dominant and a2.dominant then
            return math.floor((a1.value + a2.value) / 2)
        elseif a1.dominant then
            return a1.value
        else
            return a2.value
        end
    else
        return math.floor((a1.value + a2.value) / 2)
    end
end

--- Pass one allele from each parent.
---@param ta table Trait from parent A
---@param tb table Trait from parent B
---@return table { allele_from_a, allele_from_b }
function Inheritance._pass_alleles(ta, tb)
    local a_alleles = ta.alleles or {
        { value = ta:get_value(), dominant = true },
        { value = ta:get_value(), dominant = false },
    }
    local b_alleles = tb.alleles or {
        { value = tb:get_value(), dominant = true },
        { value = tb:get_value(), dominant = false },
    }

    local from_a = a_alleles[rng.range(1, 2)]
    local from_b = b_alleles[rng.range(1, 2)]

    return {
        { value = from_a.value, dominant = from_a.dominant },
        { value = from_b.value, dominant = from_b.dominant },
    }
end

return Inheritance
