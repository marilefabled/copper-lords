-- dredwork Home — Module Entry
-- Detailed simulation of a dwelling: upkeep, environment, and social impact.

local Home = {}
Home.__index = Home

function Home.init(engine)
    local self = setmetatable({}, Home)
    self.engine = engine

    self.logic = require("dredwork_home.logic")

    -- Expose home data via event bus (queried by Genetics for nurture)
    engine:on("GET_HOME_DATA", function(req)
        local home = engine.game_state.home
        if home then
            req.comfort = home.attributes and home.attributes.comfort or 50
            req.condition = home.attributes and home.attributes.condition or 50
            req.type = home.type
        end
    end)

    -- Monthly upkeep
    engine:on("NEW_MONTH", function(clock)
        if engine.game_state.home then
            local req_geo = { modifier = 1.0 }
            engine:emit("GET_UPKEEP_MODIFIER", req_geo)

            local req_env = { comfort_delta = 0, decay_delta = 0 }
            engine:emit("GET_HOME_ENVIRONMENT_MOD", req_env)

            -- Query economy for resources via event bus
            local req_econ = { gold = 0 }
            engine:emit("GET_ECONOMIC_DATA", req_econ)

            self.logic.tick(engine.game_state.home, { gold = req_econ.gold }, req_geo.modifier / 12, req_env)
        end
    end)

    -- Generational summary
    engine:on("ADVANCE_GENERATION", function(context)
        -- (Optional generation summary)
    end)

    return self
end

--- Establish a home for the current lineage.
function Home:establish(type_key)
    self.engine.game_state.home = self.logic.create(type_key)
    return self.engine.game_state.home
end

--- Get modifiers for other systems (e.g., stress reduction from comfort).
function Home:get_modifiers()
    if not self.engine.game_state.home then return 0 end
    return self.logic.get_environment_modifier(self.engine.game_state.home)
end

function Home:serialize()
    return self.engine.game_state.home or {}
end

function Home:deserialize(data)
    self.engine.game_state.home = data
end

return Home
