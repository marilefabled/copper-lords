local Math = require("dredwork_core.math")
-- Dark Legacy — Interactive Warfare (Campaign State)
-- Tracks multi-generational wars, requiring generals and logistics.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Campaign = {}
Campaign.__index = Campaign

function Campaign.new()
    local self = setmetatable({}, Campaign)
    self.active = false
    self.target_faction_id = nil
    self.general_name = nil
    self.general_competence = 50
    self.war_score = 50 -- 0 = defeat, 100 = victory
    self.duration_gens = 0
    self.current_pass_id = nil -- Geographic barrier
    self.logistics_burden = 1.0 -- Multiplier
    return self
end

--- Start a new campaign.
function Campaign:start(target_id, pass_id)
    self.active = true
    self.target_faction_id = target_id
    self.war_score = 50
    self.duration_gens = 0
    self.general_name = nil
    self.general_competence = 50
    self.current_pass_id = pass_id
    self.logistics_burden = 1.0
    
    if pass_id then
        local ok, geo = pcall(require, "dredwork_world.geography")
        if ok and geo then
            local pass = geo.get_pass(pass_id)
            if pass then
                self.logistics_burden = 1.0 + (pass.difficulty * 0.5)
            end
        end
    end
end

--- Assign a general from the court.
function Campaign:assign_general(member)
    if not member then
        self.general_name = nil
        self.general_competence = 20 -- Unled army is weak
    else
        self.general_name = member.name
        self.general_competence = member.competence or 50
    end
end

--- Tick the campaign each generation.
---@param resources table
---@return table result { active, status (victory|defeat|ongoing), events }
function Campaign:tick(resources)
    if not self.active then return { active = false, status = "none", events = {} } end
    
    self.duration_gens = self.duration_gens + 1
    local events = {}
    local steel_drain = math.floor(15 * (self.logistics_burden or 1.0))
    local grain_drain = math.floor(10 * (self.logistics_burden or 1.0))
    
    -- Consume logistics
    local logistics_ok = true
    if resources then
        if resources.steel < steel_drain then
            logistics_ok = false
            events[#events + 1] = "The army marched without enough steel. Casualties were horrendous."
            self.war_score = self.war_score - 15
        else
            resources:change("steel", -steel_drain, "War Campaign")
        end
        if resources.grain < grain_drain then
            logistics_ok = false
            events[#events + 1] = "The army marched on empty stomachs. Morale collapsed."
            self.war_score = self.war_score - 10
        else
            resources:change("grain", -grain_drain, "War Campaign")
        end
    end
    
    -- Geographic barrier impact (The Pass)
    if self.current_pass_id and logistics_ok then
        local ok, geo = pcall(require, "dredwork_world.geography")
        if ok and geo then
            local pass = geo.get_pass(self.current_pass_id)
            if pass then
                local bypass_chance = (self.general_competence / 100) * (1 - pass.difficulty)
                if rng.chance(bypass_chance) then
                    self.war_score = self.war_score + 20
                    events[#events + 1] = "General " .. (self.general_name or "Unknown") .. " has successfully navigated " .. pass.name .. ", striking the heart of the enemy!"
                    self.current_pass_id = nil -- Pass overcome
                    self.logistics_burden = 1.0 -- Burden lifted
                else
                    self.war_score = self.war_score - (pass.difficulty * 15)
                    events[#events + 1] = "The army remains bogged down in " .. pass.name .. ". The terrain is as deadly as the enemy."
                end
            end
        end
    end

    -- General's impact (standard)
    if not self.current_pass_id then
        if self.general_name then
            if self.general_competence >= 70 then
                self.war_score = self.war_score + 15
                events[#events + 1] = "General " .. self.general_name .. " won a brilliant victory."
            elseif self.general_competence <= 30 then
                self.war_score = self.war_score - 15
                events[#events + 1] = "General " .. self.general_name .. " led the forces into a slaughter."
            else
                self.war_score = self.war_score + rng.range(-5, 10)
            end
        else
            self.war_score = self.war_score - 20
            events[#events + 1] = "Without a designated general, the campaign was a chaotic mess."
        end
    end
    
    -- Clamp war_score before status check
    self.war_score = Math.clamp(self.war_score, 0, 100)

    -- Check conditions
    local status = "ongoing"
    if self.war_score >= 100 then
        status = "victory"
        self.active = false
        events[#events + 1] = "The enemy forces broke. The campaign is a total victory."
    elseif self.war_score <= 0 then
        status = "defeat"
        self.active = false
        events[#events + 1] = "Our forces were crushed. The campaign is a catastrophic defeat."
    elseif self.duration_gens >= 5 then
        status = "stalemate"
        self.active = false
        events[#events + 1] = "The war ground to a halt. A bitter stalemate."
    end
    
    return {
        active = self.active,
        status = status,
        events = events
    }
end

function Campaign:to_table()
    return {
        active = self.active,
        target_faction_id = self.target_faction_id,
        general_name = self.general_name,
        general_competence = self.general_competence,
        war_score = self.war_score,
        duration_gens = self.duration_gens,
        current_pass_id = self.current_pass_id,
        logistics_burden = self.logistics_burden
    }
end

function Campaign.from_table(data)
    local self = Campaign.new()
    if data then
        self.active = data.active
        self.target_faction_id = data.target_faction_id
        self.general_name = data.general_name
        self.general_competence = data.general_competence
        self.war_score = data.war_score
        self.duration_gens = data.duration_gens
        self.current_pass_id = data.current_pass_id
        self.logistics_burden = data.logistics_burden or 1.0
    end
    return self
end

return Campaign
