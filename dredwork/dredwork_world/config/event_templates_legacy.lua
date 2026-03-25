-- Dark Legacy — Legacy Event Templates
-- Events triggered by cultural memory state: taboos, blind spots, reputation, relationships.
-- These are the moments where the WEIGHT of history confronts the present.
-- Loads sub-files from config/events/legacy_*.lua and merges them.

local templates = {}

local sub_files = {
    "dredwork_world.config.events.legacy_taboo",
    "dredwork_world.config.events.legacy_blind_spot",
    "dredwork_world.config.events.legacy_reputation",
    "dredwork_world.config.events.legacy_relationship",
    "dredwork_world.config.events.legacy_milestone",
    "dredwork_world.config.events.legacy_rare",
    "dredwork_world.config.events.legacy_multistat",
    "dredwork_world.config.events.legacy_craft_and_ritual",
}

for _, mod_name in ipairs(sub_files) do
    local events = require(mod_name)
    for _, event in ipairs(events) do
        templates[#templates + 1] = event
    end
end

return templates
