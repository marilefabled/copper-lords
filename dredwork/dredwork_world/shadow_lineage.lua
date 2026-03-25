local Math = require("dredwork_core.math")
-- Dark Legacy — Shadow Lineages (Cadet Branches)
-- Tracks siblings who defected to form their own rogue houses.
-- They evolve in the background and eventually emerge as full Rival Factions.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local ShadowLineages = {}
ShadowLineages.__index = ShadowLineages

--- Create a new Shadow Lineages manager.
---@return table
function ShadowLineages.new()
    local self = setmetatable({}, ShadowLineages)
    self.branches = {} -- array of { id, name, founder_name, founder_genome, generation_founded, power, category }
    return self
end

--- A sibling leaves the court to found a cadet branch.
---@param sibling table court member object
---@param current_generation number
---@param reliquary table|nil Reliquary to steal from
---@param reason string|nil "betrayal", "elopement", "exile", "ambition"
function ShadowLineages:found_branch(sibling, current_generation, reliquary, reason)
    reason = reason or "ambition"
    local power_base = sibling.competence or 50
    
    local stolen_relics = {}
    if reliquary and #reliquary.artifacts > 0 and (reason == "betrayal" or rng.chance(0.4)) then
        local relic = reliquary:get_random()
        if relic then
            stolen_relics[#stolen_relics + 1] = relic
            reliquary:lose_artifact(relic.id)
        end
    end

    local branch = {
        id = "shadow_" .. tostring(rng.range(10000, 99999)),
        name = "The " .. sibling.name .. " Branch",
        founder_name = sibling.name,
        founder_traits = sibling.traits or {},
        stolen_relics = stolen_relics,
        generation_founded = current_generation,
        founding_reason = reason,
        power = math.floor(power_base / 2),
        status = "hidden",
        region_id = nil, -- Assigned below
        history = {
            "Founded by " .. sibling.name .. " in Gen " .. current_generation .. " following a " .. reason .. "."
        },
        divergence_score = 0,
        unique_mutation = nil -- "The Mark"
    }

    -- Assign a geographic base
    local ok, geo = pcall(require, "dredwork_world.geography")
    if ok and geo then
        local possible = { "gray_wastes", "iron_hills", "low_veldt" }
        branch.region_id = possible[rng.range(1, #possible)]
        table.insert(branch.history, "They established a base in " .. geo.get_region(branch.region_id).name .. ".")
    end

    -- Determine "The Mark" based on the reason
    if reason == "betrayal" then
        branch.unique_mutation = "Void-Eyes" -- Narrative mark for traitors
    elseif reason == "elopement" then
        branch.unique_mutation = "Fair-Blood"
    elseif reason == "exile" then
        branch.unique_mutation = "Stone-Skin"
    end

    -- Cap active (non-emerged) branches at 5 to prevent unbounded growth
    local active_count = 0
    for _, b in ipairs(self.branches) do
        if b.status ~= "emerged" then active_count = active_count + 1 end
    end
    if active_count >= 5 then
        -- Replace the weakest active branch
        local weakest_idx, weakest_power = nil, math.huge
        for i, b in ipairs(self.branches) do
            if b.status ~= "emerged" and b.power < weakest_power then
                weakest_idx = i
                weakest_power = b.power
            end
        end
        if weakest_idx and branch.power >= weakest_power then
            table.remove(self.branches, weakest_idx)
        else
            return branch -- Too weak to displace existing branches
        end
    end

    self.branches[#self.branches + 1] = branch
    return branch
end

--- Tick the hidden branches. They grow in power, mutate, and build a hidden history.
function ShadowLineages:tick(current_generation, world_context)
    local events = {}
    
    for _, branch in ipairs(self.branches) do
        if branch.status == "hidden" then
            local age = current_generation - branch.generation_founded
            branch.power = branch.power + rng.range(2, 8)
            branch.divergence_score = branch.divergence_score + 1
            
            -- Hidden History Generation (Data for the AI)
            if rng.chance(0.3) then
                local hidden_feats = {
                    "Survived a famine in the Gray Wastes.",
                    "Subjugated a minor barbarian tribe.",
                    "Built a hidden fortress in the Iron Pass.",
                    "Forged a pact with the Whispering Shadows.",
                    "Shed the last of their loyalty to the main branch."
                }
                table.insert(branch.history, hidden_feats[rng.range(1, #hidden_feats)])
            end

            -- Genetic Divergence: Traits drift away from the founder
            if branch.founder_traits then
                for tid, val in pairs(branch.founder_traits) do
                    local drift = rng.range(-8, 8)
                    branch.founder_traits[tid] = Math.clamp(val + drift, 0, 100)
                end
            end
            
            -- Emergence check
            if branch.power >= 80 and age >= 3 then
                branch.status = "emerged"
                
                local new_faction_def = {
                    id = branch.id,
                    name = branch.name,
                    motto = "The blood endures in us alone.",
                    archetype_id = "cadet_branch",
                    category_scores = { physical = 50, mental = 50, social = 50, creative = 50 },
                    personality = { PER_BLD = 70, PER_CRM = 70, PER_PRI = 90, PER_ADA = 30 },
                    reputation = { primary = "usurpers", secondary = "exiles" },
                    power = 70,
                    status = "active",
                    disposition = -80, -- Extreme hatred
                    shadow_history = branch.history, -- Pass the hidden history
                    the_mark = branch.unique_mutation
                }
                
                if world_context.factions then
                    local faction_mod = require("dredwork_world.faction")
                    local new_fac = faction_mod.Faction.new(new_faction_def)
                    -- Seed categories from drifted traits
                    for tid, val in pairs(branch.founder_traits) do
                        local prefix = tid:sub(1, 3)
                        local cat = ({ PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" })[prefix]
                        if cat then new_fac.category_scores[cat] = math.max(new_fac.category_scores[cat], val) end
                    end
                    table.insert(world_context.factions.factions, new_fac)
                    
                    if world_context.rival_heirs then
                        local RivalHeirs = require("dredwork_world.rival_heirs").RivalHeirs
                        local heir = RivalHeirs.generate(new_fac, current_generation)
                        for tid, val in pairs(branch.founder_traits) do heir.genome[tid] = val end
                        -- Apply The Mark to the heir's appearance narrative
                        heir.appearance_override = "They bear " .. (branch.unique_mutation or "the ancestral look") .. "."
                        world_context.rival_heirs.heirs[new_fac.id] = heir
                    end
                end
                
                local relic_str = ""
                if #branch.stolen_relics > 0 then
                    relic_str = " They wield the stolen " .. branch.stolen_relics[1].name .. "."
                end

                events[#events + 1] = {
                    type = "cadet_emergence",
                    text = "A shadow lineage emerges! The descendants of " .. branch.founder_name .. " have returned as " .. branch.name .. " to reclaim their birthright." .. relic_str,
                    faction_id = branch.id,
                    mark = branch.unique_mutation,
                    history = branch.history
                }
            end
        end
    end
    
    -- Prune emerged branches that have been converted to factions
    for i = #self.branches, 1, -1 do
        if self.branches[i].status == "emerged" and self.branches[i].emerged_gen and (current_generation - self.branches[i].emerged_gen) > 5 then
            table.remove(self.branches, i)
        end
    end

    return events
end

function ShadowLineages:to_table()
    return { branches = self.branches }
end

function ShadowLineages.from_table(data)
    local self = ShadowLineages.new()
    self.branches = data and data.branches or {}
    return self
end

return ShadowLineages
