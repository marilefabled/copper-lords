-- Dark Legacy — Holdings (Territorial Reality)
-- Represents the physical domains, castles, and resources owned by the lineage.
-- Holdings provide passive income/power and act as visceral stakes during wars or famines.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Holdings = {}
Holdings.__index = Holdings

-- ═══════════════════════════════════════════════════════
-- SPECIALIZATIONS
-- Organic specialties that develop over time based on
-- cultural memory and deliberate investment.
-- ═══════════════════════════════════════════════════════

Holdings.SPECIALTIES = {
    -- Physical
    war_college = {
        id = "war_college",
        label = "War College",
        category = "physical",
        affinity = { "fortress", "outpost" },
        yield_bonus = { steel = 2 },
        nurture = { trait = "PHY_STR", bonus = 3, description = "Trained from birth in the war college." },
    },
    granary_complex = {
        id = "granary_complex",
        label = "Granary Complex",
        category = "physical",
        affinity = { "farm", "village" },
        yield_bonus = { grain = 3 },
        nurture = { trait = "PHY_VIT", bonus = 2, description = "Never knew hunger, raised among overflowing stores." },
    },
    -- Mental
    scriptorium = {
        id = "scriptorium",
        label = "Scriptorium",
        category = "mental",
        affinity = { "library", "temple" },
        yield_bonus = { lore = 3 },
        nurture = { trait = "MEN_INT", bonus = 3, description = "Raised among scholars and illuminated texts." },
    },
    observatory = {
        id = "observatory",
        label = "Observatory",
        category = "mental",
        affinity = { "library", "outpost" },
        yield_bonus = { lore = 2 },
        nurture = { trait = "MEN_ANA", bonus = 3, description = "Taught to read the sky and the patterns beneath it." },
    },
    -- Social
    diplomatic_quarter = {
        id = "diplomatic_quarter",
        label = "Diplomatic Quarter",
        category = "social",
        affinity = { "city", "market", "port" },
        yield_bonus = { gold = 3 },
        nurture = { trait = "SOC_INF", bonus = 3, description = "Grew up among ambassadors and deal-makers." },
    },
    pilgrim_hospice = {
        id = "pilgrim_hospice",
        label = "Pilgrim Hospice",
        category = "social",
        affinity = { "temple", "village" },
        yield_bonus = { grain = 1, gold = 1 },
        nurture = { trait = "SOC_EMP", bonus = 3, description = "Raised among pilgrims and their stories of devotion." },
    },
    -- Creative
    artisan_guild = {
        id = "artisan_guild",
        label = "Artisan Guild",
        category = "creative",
        affinity = { "city", "market", "village" },
        yield_bonus = { gold = 2 },
        nurture = { trait = "CRE_INN", bonus = 3, description = "Apprenticed to the guild masters before they could walk." },
    },
    forge_works = {
        id = "forge_works",
        label = "Forge Works",
        category = "creative",
        affinity = { "mine", "fortress" },
        yield_bonus = { steel = 3 },
        nurture = { trait = "CRE_FLV", bonus = 2, description = "Shaped by the rhythms of hammer and flame." },
    },
}

-- Map categories to specialty pools for organic development
Holdings.CATEGORY_SPECIALTIES = {
    physical = { "war_college", "granary_complex" },
    mental   = { "scriptorium", "observatory" },
    social   = { "diplomatic_quarter", "pilgrim_hospice" },
    creative = { "artisan_guild", "forge_works" },
}

--- Create a new Holdings manager.
---@param custom_config table|nil optional overrides
---@return table Holdings instance
function Holdings.new(custom_config)
    local self = setmetatable({}, Holdings)
    self.domains = {} -- array of holding objects
    
    local seat_name = "The Ancestral Keep"
    local seat_type = "fortress"
    if custom_config and custom_config.estate then
        seat_name = custom_config.estate.name or seat_name
        seat_type = custom_config.estate.type or seat_type
    end

    -- Start with the Ancestral Seat
    self:add_domain({
        id = "ancestral_seat",
        name = seat_name,
        type = seat_type,
        size = 3,
        description = "The stone heart of the family."
    })
    return self
end

-- ═══════════════════════════════════════════════════════
-- PROCEDURAL SETTLEMENT NAMES
-- Compound names: [prefix] + [suffix], era-flavored.
-- ═══════════════════════════════════════════════════════

local NAME_PREFIXES = {
    farm = {
        ancient = { "Ash", "Black", "Stone", "Rust", "Bone", "Thorn", "Red", "Dry", "Salt", "Dust" },
        iron    = { "Iron", "Forge", "Coal", "Grey", "Hard", "Steel", "Slag", "Cinder", "Cold", "Hammer" },
        dark    = { "Rot", "Shade", "Blight", "Pale", "Worm", "Hag", "Murk", "Hollow", "Grim", "Dusk" },
        arcane  = { "Star", "Rune", "Glimmer", "Spell", "Moon", "Whisper", "Mist", "Silver", "Veil", "Wyrd" },
        gilded  = { "Gold", "Crown", "Silk", "Ivory", "Rose", "Pearl", "Bright", "High", "Noble", "Fair" },
        twilight = { "Ash", "Last", "Ember", "Fading", "Dusk", "Quiet", "Still", "Dim", "Fallen", "End" },
    },
    village = {
        ancient = { "Grey", "Dusk", "Stone", "Mire", "Bog", "Cairn", "Flint", "Barrow", "Crag", "Fen" },
        iron    = { "Iron", "Anvil", "Forge", "Cinder", "Smelt", "Pit", "Coal", "Black", "Rust", "Nail" },
        dark    = { "Shade", "Rot", "Wither", "Corpse", "Blight", "Husk", "Gall", "Tallow", "Char", "Pox" },
        arcane  = { "Spell", "Ether", "Crystal", "Loom", "Rune", "Sigil", "Phantom", "Wisp", "Shimmer", "Echo" },
        gilded  = { "Crown", "Silver", "Marble", "Gilt", "Laurel", "Banner", "Court", "Crest", "Haven", "Grace" },
        twilight = { "Ember", "Ruin", "Haze", "Dwindl", "Wraith", "Pale", "Wane", "Sorrow", "Still", "Vesper" },
    },
    mine = {
        ancient = { "Deep", "Dark", "Stone", "Ore", "Bone", "Root", "Under", "Black", "Pit", "Vein" },
        iron    = { "Iron", "Coal", "Slag", "Forge", "Seam", "Smelt", "Shaft", "Copper", "Tin", "Lead" },
        dark    = { "Rot", "Worm", "Grave", "Blight", "Hollow", "Bile", "Murk", "Dread", "Grim", "Foul" },
        arcane  = { "Crystal", "Rune", "Star", "Gem", "Moon", "Glint", "Lode", "Prism", "Arc", "Aether" },
        gilded  = { "Gold", "Silver", "Jewel", "Rich", "Bright", "Noble", "Crown", "Royal", "Grand", "Pure" },
        twilight = { "Dust", "Ash", "Spent", "Last", "Dim", "Ember", "Fading", "End", "Husk", "Void" },
    },
    outpost = {
        ancient = { "Far", "Cold", "Lone", "Edge", "Wind", "Watch", "Bleak", "Stark", "Border", "Waste" },
        iron    = { "Iron", "Steel", "Bolt", "Shield", "Spear", "Fort", "Guard", "Tower", "Pike", "Wall" },
        dark    = { "Dread", "Shadow", "Bane", "Doom", "Skull", "Wrath", "Gore", "Spite", "Grim", "Hex" },
        arcane  = { "Ward", "Seal", "Beacon", "Sigil", "Rune", "Veil", "Glyph", "Phase", "Flux", "Rift" },
        gilded  = { "Crown", "Banner", "Gold", "Triumph", "Glory", "Honor", "Crest", "Eagle", "Lion", "Virtue" },
        twilight = { "Last", "End", "Fade", "Final", "Dusk", "Wane", "Silence", "Pale", "Ember", "Rest" },
    },
    fortress = {
        ancient = { "Stone", "Blood", "Bone", "Crag", "Iron", "Dark", "Black", "Thunder", "Grim", "Wolf" },
        iron    = { "Steel", "Forge", "Anvil", "War", "Shield", "Hammer", "Iron", "Battle", "Siege", "Bolt" },
        dark    = { "Dread", "Shadow", "Death", "Bane", "Doom", "Wrath", "Terror", "Grave", "Skull", "Night" },
        arcane  = { "Spell", "Star", "Moon", "Rune", "Ward", "Crystal", "Arcane", "Mystic", "Spirit", "Void" },
        gilded  = { "Crown", "Gold", "Royal", "Grand", "Lion", "Eagle", "Throne", "Sovereign", "High", "Noble" },
        twilight = { "Last", "Ember", "Ruin", "Fallen", "Ash", "Silence", "End", "Final", "Wane", "Dusk" },
    },
}

local NAME_SUFFIXES = {
    farm    = { "field", "soil", "furrow", "harvest", "stead", "acre", "meadow", "row", "yield", "patch", "hollow", "grange" },
    village = { "hollow", "water", "mere", "well", "gate", "haven", "wick", "ton", "ford", "moor", "vale", "thorpe" },
    mine    = { "vein", "mouth", "shaft", "deep", "pit", "delve", "bore", "reach", "seam", "drift", "crag", "gulch" },
    outpost = { "watch", "ward", "mark", "sight", "guard", "post", "reach", "keep", "stand", "point", "ridge", "spire" },
    fortress = { "hold", "keep", "spire", "bastion", "citadel", "rock", "tower", "wall", "gate", "crown", "peak", "mount" },
}

--- Generate a procedural settlement name.
---@param holding_type string farm/village/mine/outpost/fortress
---@param era_key string|nil current era key (defaults to "ancient")
---@return string
function Holdings.generate_name(holding_type, era_key)
    era_key = era_key or "ancient"
    local htype = holding_type or "village"

    local prefix_pool = NAME_PREFIXES[htype] and NAME_PREFIXES[htype][era_key]
    if not prefix_pool then
        prefix_pool = NAME_PREFIXES[htype] and NAME_PREFIXES[htype]["ancient"] or { "Grey" }
    end
    local suffix_pool = NAME_SUFFIXES[htype] or { "hold" }

    local prefix = prefix_pool[rng.range(1, #prefix_pool)]
    local suffix = suffix_pool[rng.range(1, #suffix_pool)]
    return prefix .. suffix
end

--- Add a new domain to the lineage.
---@param def table { id, name, type (fortress, mine, port, temple, village), size (1-5), description }
function Holdings:add_domain(def)
    self.domains[#self.domains + 1] = {
        id = def.id or ("dom_" .. rng.range(1000, 9999)),
        name = def.name or "Unknown Holding",
        type = def.type or "village",
        size = def.size or 1,
        description = def.description or "A stretch of land claimed by the blood.",
        status = "active", -- active, besieged, ruined
        specialty = def.specialty or nil,
    }
end

--- Lose a domain (conquered, given away, destroyed).
---@return table|nil the lost domain, or nil if none left (or only the seat left)
function Holdings:lose_domain()
    -- Prioritize losing non-ancestral seats first
    local expendable = {}
    for i, dom in ipairs(self.domains) do
        if dom.id ~= "ancestral_seat" then
            expendable[#expendable + 1] = i
        end
    end
    
    if #expendable > 0 then
        local idx = expendable[rng.range(1, #expendable)]
        local lost = self.domains[idx]
        table.remove(self.domains, idx)
        return lost
    elseif #self.domains > 0 then
        -- Lose the seat (extreme fail state)
        local lost = self.domains[1]
        table.remove(self.domains, 1)
        return lost
    end
    return nil
end

--- Get the total yields generated by all holdings per generation.
---@return table { grain, steel, lore, gold }
function Holdings:get_yields()
    local yields = { grain = 0, steel = 0, lore = 0, gold = 0 }
    
    for _, dom in ipairs(self.domains) do
        if dom.status == "active" then
            if dom.type == "mine" then
                yields.steel = yields.steel + (dom.size * 2)
            elseif dom.type == "port" or dom.type == "village" then
                yields.grain = yields.grain + (dom.size * 2)
                yields.gold = yields.gold + math.floor(dom.size / 2)
            elseif dom.type == "fortress" then
                yields.steel = yields.steel + dom.size
            elseif dom.type == "temple" or dom.type == "library" then
                yields.lore = yields.lore + (dom.size * 2)
            elseif dom.type == "city" or dom.type == "market" then
                yields.gold = yields.gold + (dom.size * 3)
            else
                yields.gold = yields.gold + dom.size
            end

            -- Specialty yield bonuses
            if dom.specialty then
                local spec = Holdings.SPECIALTIES[dom.specialty]
                if spec and spec.yield_bonus then
                    for res_type, amount in pairs(spec.yield_bonus) do
                        yields[res_type] = (yields[res_type] or 0) + amount
                    end
                end
            end
        end
    end
    return yields
end

--- Get a random active holding (for events).
---@return table|nil
function Holdings:get_random()
    local active = {}
    for _, dom in ipairs(self.domains) do
        if dom.status == "active" then active[#active + 1] = dom end
    end
    if #active == 0 then return nil end
    return active[rng.range(1, #active)]
end

--- Damage a random active domain by reducing its size.
--- Domains that reach size 0 become "ruined" rather than removed.
--- The ancestral seat is damaged last and can never be fully ruined.
---@return string|nil narrative of the damage, or nil if no domains
function Holdings:damage_random_domain()
    if #self.domains == 0 then return nil end

    -- Prefer damaging non-seat active domains first
    local targets = {}
    local seat_idx = nil
    for i, dom in ipairs(self.domains) do
        if dom.status == "active" then
            if dom.id == "ancestral_seat" then
                seat_idx = i
            else
                targets[#targets + 1] = i
            end
        end
    end

    -- Fall back to ancestral seat if nothing else is active
    if #targets == 0 and seat_idx then
        targets[#targets + 1] = seat_idx
    end

    if #targets == 0 then return nil end

    local idx = targets[rng.range(1, #targets)]
    local d = self.domains[idx]
    d.size = math.max(0, d.size - 1)

    local text = "The " .. d.name .. " was damaged in the chaos."

    if d.size == 0 then
        if d.id == "ancestral_seat" then
            -- The seat can never be fully destroyed — clamp at size 1
            d.size = 1
            text = "The " .. d.name .. " was ravaged, but its foundations endure."
        else
            d.status = "ruined"
            if d.specialty then
                local spec = Holdings.SPECIALTIES[d.specialty]
                local spec_name = spec and spec.label or d.specialty
                text = "The " .. d.name .. " lies in ruins. Its " .. spec_name .. " is lost."
                d.specialty = nil
            else
                text = "The " .. d.name .. " lies in ruins. It may yet be restored."
            end
        end
    end
    return text
end

--- Tick specialization development for all domains.
--- Specialties develop organically based on cultural memory priorities.
---@param cultural_memory table { physical, mental, social, creative } category scores
---@return table array of { domain_name, specialty_label, event } narratives
function Holdings:tick_specialization(cultural_memory)
    local narratives = {}
    if not cultural_memory then return narratives end

    for _, dom in ipairs(self.domains) do
        if dom.status == "active" and not dom.specialty then
            -- Organic development: 15% base chance per gen, boosted by cultural memory
            -- Find the dominant cultural category
            local best_cat, best_val = nil, -1
            for _, cat in ipairs({ "physical", "mental", "social", "creative" }) do
                local val = cultural_memory[cat] or 0
                if val > best_val then
                    best_cat = cat
                    best_val = val
                end
            end

            if best_cat and best_val >= 20 then
                -- Chance scales with cultural memory dominance (15% at 20, 35% at 60+)
                local chance = 0.15 + math.min(0.20, (best_val - 20) * 0.005)
                if rng.chance(chance) then
                    -- Pick a specialty from the dominant category
                    local pool = Holdings.CATEGORY_SPECIALTIES[best_cat]
                    if pool and #pool > 0 then
                        -- Prefer specialties with domain type affinity
                        local affinity_matches = {}
                        local any_matches = {}
                        for _, spec_id in ipairs(pool) do
                            local spec = Holdings.SPECIALTIES[spec_id]
                            if spec then
                                any_matches[#any_matches + 1] = spec_id
                                if spec.affinity then
                                    for _, aff_type in ipairs(spec.affinity) do
                                        if aff_type == dom.type then
                                            affinity_matches[#affinity_matches + 1] = spec_id
                                            break
                                        end
                                    end
                                end
                            end
                        end

                        local chosen_pool = #affinity_matches > 0 and affinity_matches or any_matches
                        if #chosen_pool > 0 then
                            local chosen_id = chosen_pool[rng.range(1, #chosen_pool)]
                            local spec = Holdings.SPECIALTIES[chosen_id]
                            if spec then
                                dom.specialty = chosen_id
                                narratives[#narratives + 1] = {
                                    domain_name = dom.name,
                                    specialty_label = spec.label,
                                    event = "developed",
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return narratives
end

--- Deliberately specialize a domain (via council action).
---@param domain_id string
---@param specialty_id string
---@return boolean success
---@return string|nil narrative
function Holdings:set_specialty(domain_id, specialty_id)
    local spec = Holdings.SPECIALTIES[specialty_id]
    if not spec then return false, nil end

    for _, dom in ipairs(self.domains) do
        if dom.id == domain_id and dom.status == "active" then
            local old = dom.specialty
            dom.specialty = specialty_id
            if old then
                return true, dom.name .. " was refocused from " .. (Holdings.SPECIALTIES[old] and Holdings.SPECIALTIES[old].label or old) .. " to " .. spec.label .. "."
            else
                return true, dom.name .. " was developed into a " .. spec.label .. "."
            end
        end
    end
    return false, nil
end

--- Restore a ruined domain back to active status with size 1.
---@param domain_id string
---@return boolean success
function Holdings:restore_domain(domain_id)
    for _, dom in ipairs(self.domains) do
        if dom.id == domain_id and dom.status == "ruined" then
            dom.status = "active"
            dom.size = 1
            return true
        end
    end
    return false
end

--- Compute nurture modifiers based on held domains.
--- More land = more stability/resources for raising children.
---@return table array of { trait, bonus, description }
function Holdings:compute_nurture_modifiers()
    local mods = {}
    local active_count = 0
    local has_temple = false
    local has_library = false
    local has_fortress = false
    local total_size = 0

    for _, dom in ipairs(self.domains) do
        if dom.status == "active" then
            active_count = active_count + 1
            total_size = total_size + (dom.size or 1)
            if dom.type == "temple" then has_temple = true end
            if dom.type == "library" then has_library = true end
            if dom.type == "fortress" then has_fortress = true end
        end
    end

    -- Landed stability: 3+ domains = children raised in security
    if active_count >= 3 then
        mods[#mods + 1] = {
            trait = "SOC_AWR",
            bonus = 2,
            description = "Raised across a vast estate.",
        }
    end

    -- Large holdings: total size 10+ = material abundance
    if total_size >= 10 then
        mods[#mods + 1] = {
            trait = "PHY_VIT",
            bonus = 2,
            description = "Well-fed and sheltered in prosperous lands.",
        }
    end

    -- Temple: spiritual upbringing + longevity
    if has_temple then
        mods[#mods + 1] = {
            trait = "MEN_WIL",
            bonus = 2,
            description = "Raised in the shadow of the family temple.",
        }
        mods[#mods + 1] = {
            trait = "PHY_LON",
            bonus = 2,
            description = "Temple healers tend to the bloodline's young.",
        }
    end

    -- Library: intellectual upbringing + teaching
    if has_library then
        mods[#mods + 1] = {
            trait = "MEN_INT",
            bonus = 2,
            description = "The family library shaped their mind.",
        }
        mods[#mods + 1] = {
            trait = "SOC_TEA",
            bonus = 2,
            description = "Scholars taught the art of instruction itself.",
        }
    end

    -- Fortress: martial upbringing + bone density
    if has_fortress and active_count >= 2 then
        mods[#mods + 1] = {
            trait = "PHY_END",
            bonus = 2,
            description = "Trained on the walls of the ancestral keep.",
        }
        mods[#mods + 1] = {
            trait = "PHY_LUN",
            bonus = 2,
            description = "Mountain air and marching drills built strong lungs.",
        }
    end

    -- Specialty nurture: each specialized domain contributes its unique bonus
    for _, dom in ipairs(self.domains) do
        if dom.status == "active" and dom.specialty then
            local spec = Holdings.SPECIALTIES[dom.specialty]
            if spec and spec.nurture then
                mods[#mods + 1] = {
                    trait = spec.nurture.trait,
                    bonus = spec.nurture.bonus,
                    description = spec.nurture.description,
                }
            end
        end
    end

    -- Landless penalty
    if active_count == 0 then
        mods[#mods + 1] = {
            trait = "PHY_VIT",
            bonus = -3,
            description = "Born to a landless bloodline, malnourished and rootless.",
        }
    end

    return mods
end

--- Serialize to plain table.
---@return table
function Holdings:to_table()
    local copied = {}
    for _, dom in ipairs(self.domains) do
        local d = {}
        for k, v in pairs(dom) do d[k] = v end
        copied[#copied + 1] = d
    end
    return { domains = copied }
end

--- Restore from saved table.
---@param data table
---@return table Holdings
function Holdings.from_table(data)
    local self = setmetatable({}, Holdings)
    local src = data and data.domains or {}
    local copied = {}
    for _, dom in ipairs(src) do
        local d = {}
        for k, v in pairs(dom) do d[k] = v end
        copied[#copied + 1] = d
    end
    self.domains = copied
    if #self.domains == 0 then
        -- Fallback if empty but restoring
        self:add_domain({ id = "ancestral_seat", name = "The Ancestral Keep", type = "fortress", size = 3 })
    end
    return self
end

return Holdings
