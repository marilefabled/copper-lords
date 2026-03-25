-- dredwork Crime — Module Entry
-- High-level management of criminal syndicates, corruption, and shadow economy.

local Crime = {}
Crime.__index = Crime

function Crime.init(engine)
    local self = setmetatable({}, Crime)
    self.engine = engine

    self.logic = require("dredwork_crime.logic")

    -- Initialize underworld state
    engine.game_state.underworld = {
        organizations = {},
        global_corruption = 0, -- 0 to 100
        total_shadow_wealth = 0
    }

    -- Expose corruption data via event bus (other modules query this)
    engine:on("GET_CORRUPTION_DATA", function(req)
        req.global_corruption = self.engine.game_state.underworld.global_corruption
        req.total_shadow_wealth = self.engine.game_state.underworld.total_shadow_wealth
    end)

    -- INTERCONNECTION: Politics query for corruption impact on unrest
    engine:on("GET_POLITICAL_UNREST_MOD", function(req)
        local corruption = self.engine.game_state.underworld.global_corruption
        if corruption > 20 then
            req.unrest_delta = (req.unrest_delta or 0) + (corruption * 0.2)
        end
    end)

    -- Tick underworld per generation
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick(context.game_state)
    end)

    return self
end

--- Spawn a new criminal organization.
function Crime:spawn_syndicate(type_key, region_id)
    local org = self.logic.create_org(type_key, region_id)
    table.insert(self.engine.game_state.underworld.organizations, org)
    return org
end

--- Run an operation for an organization.
function Crime:execute_op(org_index, op_key)
    local org = self.engine.game_state.underworld.organizations[org_index]
    if not org then return nil end

    -- Query for regional security context
    local req_sec = { region_id = org.location_id, security_score = 20 }
    self.engine:emit("GET_REGIONAL_SECURITY", req_sec)

    -- Query political unrest via event bus (decoupled from Politics)
    local req_pol = { unrest = 0 }
    self.engine:emit("GET_POLITICAL_UNREST_MOD", req_pol)
    local unrest_bonus = math.floor((req_pol.unrest or 0) / 5)

    local result = self.logic.run_operation(org, op_key, {
        regional_security = math.max(0, req_sec.security_score - unrest_bonus)
    })

    if not result then return nil end

    -- Apply results
    if result.success then
        org.wealth = org.wealth + result.reward
        self.engine.game_state.underworld.global_corruption = math.min(100, self.engine.game_state.underworld.global_corruption + result.corruption_gain)

        -- Large rewards spawn rumors
        if result.reward > 50 then
            local rumor_module = self.engine:get_module("rumor")
            if rumor_module then
                rumor_module:inject(self.engine.game_state, {
                    origin_type = "crime",
                    subject = org.label,
                    text = "A massive heist was reported. Wealth has shifted in the shadows.",
                    heat = 80,
                    tags = { wealth = true, scandal = true }
                })
            end
        end
    else
        org.wealth = math.max(0, org.wealth - (result.loss or 0))

        -- Failed heists lead to sentencing
        if (result.heat_gain or 0) > 5 then
            self.engine:emit("CRIMINAL_SENTENCED", {
                person_id = org.label .. "_thug",
                years = 25
            })
        end
    end
    org.heat = math.min(100, org.heat + (result.heat_gain or 0))

    return result
end

--- Step the underworld.
function Crime:tick(game_state)
    for _, org in ipairs(game_state.underworld.organizations) do
        self.logic.tick(org)
    end
end

function Crime:serialize() return self.engine.game_state.underworld end
function Crime:deserialize(data) self.engine.game_state.underworld = data end

return Crime
