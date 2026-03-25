-- Dark Legacy — Personal Event Templates
-- Auto-resolve events driven by heir personality axes.
-- The player sees the result, not the choice. This is the autonomous resolution mechanic.
-- Loads sub-files from config/events/personal_*.lua and merges them.

local templates = {}

local sub_files = {
    "dredwork_world.config.events.personal_boldness",
    "dredwork_world.config.events.personal_cruelty",
    "dredwork_world.config.events.personal_obsession",
    "dredwork_world.config.events.personal_loyalty",
    "dredwork_world.config.events.personal_curiosity",
    "dredwork_world.config.events.personal_volatility",
    "dredwork_world.config.events.personal_pride",
    "dredwork_world.config.events.personal_adaptability",
    "dredwork_world.config.events.personal_multistat",
    "dredwork_world.config.events.personal_life",
}

for _, mod_name in ipairs(sub_files) do
    local events = require(mod_name)
    for _, event in ipairs(events) do
        templates[#templates + 1] = event
    end
end

return templates
