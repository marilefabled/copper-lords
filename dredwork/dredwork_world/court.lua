-- Dark Legacy — The Court (Extended Family & Retainers)
-- Expands scope beyond the singular Heir to include siblings, spouses, and key figures.
-- These characters can plot, provide bonuses, or become liabilities.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Court = {}
Court.__index = Court

--- Create a new Court.
---@return table Court instance
function Court.new()
    local self = setmetatable({}, Court)
    self.members = {} -- array of court members
    return self
end

--- Add a member to the court.
---@param member table { id, name, role (sibling, spouse, advisor), loyalty (0-100), competence (0-100), traits={} }
function Court:add_member(member)
    self.members[#self.members + 1] = {
        id = member.id or ("crt_" .. rng.range(10000, 99999)),
        name = member.name or "Nameless Courtier",
        role = member.role or "advisor",
        loyalty = member.loyalty or rng.range(30, 80),
        competence = member.competence or rng.range(30, 80),
        traits = member.traits or {}, -- minimal trait list (e.g., { PHY_STR = 60 })
        status = "active", -- active, exiled, dead
    }
end

--- Generate siblings for the current heir.
---@param count number
function Court:generate_siblings(count)
    for i = 1, count do
        self:add_member({
            name = "Sibling " .. i, -- We will hook into name_generator later
            role = "sibling",
            loyalty = rng.range(20, 90), -- Siblings can be deeply loyal or fiercely jealous
            competence = rng.range(40, 80),
        })
    end
end

--- Tick the court. Calculates betrayal chances, loyalty shifts, and passive benefits.
---@param lineage_power number
---@param wealth number
---@param context table|nil WorldContext for defection logic
---@return table array of court events/consequences
function Court:tick(lineage_power, wealth, context)
    local events = {}
    local to_remove = {}
    
    for i, member in ipairs(self.members) do
        if member.status == "active" then
            -- High power/wealth buys loyalty; low power breeds treason
            if lineage_power < 30 or wealth < 30 then
                member.loyalty = member.loyalty - rng.range(2, 8)
            else
                member.loyalty = math.min(100, member.loyalty + rng.range(1, 4))
            end
            
            -- Betrayal check
            if member.loyalty < 20 and rng.chance(0.20) then
                if member.role == "sibling" and context and context.shadow_lineages and rng.chance(0.7) then
                    -- Found a shadow lineage instead of joining a rival house
                    local reason = "betrayal"
                    if rng.chance(0.3) then reason = "elopement" end
                    local branch = context.shadow_lineages:found_branch(member, context.generation, context.reliquary, reason)
                    
                    local text = member.name .. " has left the court in a fury, vowing to forge a true legacy. A shadow lineage has been born."
                    if reason == "elopement" then
                        text = member.name .. " has fled into the night with a lover from a rival house. They have founded a new line in the shadows."
                    end

                    events[#events + 1] = {
                        type = "cadet_founding",
                        member_name = member.name,
                        role = member.role,
                        reason = reason,
                        text = text,
                        consequence = { 
                            lineage_power_delta = -15, 
                        }
                    }
                else
                    local faction_dest = "a rival house"
                    local target_id = nil
                    
                    -- If we have faction relations, find the player's worst enemy to defect to
                    if context and context.faction_relations then
                        local worst_disp = 100
                        for _, f in ipairs(context.factions:get_all()) do
                            local disp = context.faction_relations:get_disposition(f.id, "player")
                            if disp < worst_disp then
                                worst_disp = disp
                                faction_dest = f.name
                                target_id = f.id
                            end
                        end
                    end

                    events[#events + 1] = {
                        type = "court_betrayal",
                        member_name = member.name,
                        role = member.role,
                        text = member.name .. " (" .. member.role .. ") has betrayed the bloodline, defecting to " .. faction_dest .. " with our secrets!",
                        consequence = { 
                            lineage_power_delta = -10, 
                            wealth_delta = -5, 
                            lose_lore = 3,
                            faction_id = target_id,
                            faction_power_delta = 5 -- The enemy house gains from your traitor
                        }
                    }
                end
                member.status = "exiled"
                member._processed = true
                -- Clear from campaign if they were the general
                if context and context.campaign and context.campaign.general_name == member.name then
                    context.campaign:assign_general(nil)
                end
            elseif member.status == "exiled" and member.role == "sibling" and not member._processed and rng.chance(0.5) then
                 -- An exiled sibling might found a branch if they haven't already
                 if context and context.shadow_lineages then
                    context.shadow_lineages:found_branch(member, context.generation, context.reliquary, "exile")
                 end
            elseif member.loyalty > 80 and rng.chance(0.20) then
                -- Great boon
                events[#events + 1] = {
                    type = "court_boon",
                    member_name = member.name,
                    role = member.role,
                    text = member.name .. " (" .. member.role .. ") secured a great advantage for the family.",
                    consequence = { lineage_power_delta = 5, wealth_delta = 5, gain_gold = 10 }
                }
            end
            
            -- Natural death chance for older members (abstracted per gen)
            if member.role ~= "spouse" and not member._processed and rng.chance(0.3) then
                 member.status = "dead"
                 events[#events + 1] = {
                     type = "court_death",
                     member_name = member.name,
                     role = member.role,
                     text = member.name .. " (" .. member.role .. ") passed away.",
                 }
                 -- Clear from campaign if they were the general
                 if context and context.campaign and context.campaign.general_name == member.name then
                     context.campaign:assign_general(nil)
                 end
            end
        end
        
        if member.status ~= "active" then
            to_remove[#to_remove + 1] = i
        end
    end
    
    -- Cleanup dead/exiled
    for i = #to_remove, 1, -1 do
        table.remove(self.members, to_remove[i])
    end
    
    return events
end

--- Clear all members (e.g., at the start of a new generation, keeping only the spouse if needed).
function Court:clear_for_new_generation()
    local survivors = {}
    for _, member in ipairs(self.members) do
        -- Advisors might survive, siblings might stay on as elders, but for now we clear to reset
        if member.role == "elder" then
            survivors[#survivors + 1] = member
        end
    end
    self.members = survivors
end

--- Serialize to plain table.
---@return table
function Court:to_table()
    return { members = self.members }
end

--- Restore from saved table.
---@param data table
---@return table Court
function Court.from_table(data)
    local self = setmetatable({}, Court)
    self.members = data and data.members or {}
    return self
end

return Court
