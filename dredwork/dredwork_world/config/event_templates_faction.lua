-- Dark Legacy — Faction Event Templates
-- Events triggered by faction disposition thresholds.
-- Loads sub-files from config/events/faction_*.lua and merges them.

local templates = {}

local sub_files = {
    "dredwork_world.config.events.faction_positive",
    "dredwork_world.config.events.faction_negative",
    "dredwork_world.config.events.faction_neutral",
    "dredwork_world.config.events.faction_power",
    "dredwork_world.config.events.faction_specific",
    "dredwork_world.config.events.faction_autonomous",
    "dredwork_world.config.events.faction_multistat",
    "dredwork_world.config.events.faction_rival",
    "dredwork_world.config.events.faction_social_depth",
    "dredwork_world.config.events.faction_ambition_events",
    "dredwork_world.config.events.nemesis_events",
}

for _, mod_name in ipairs(sub_files) do
    local events = require(mod_name)
    for _, event in ipairs(events) do
        templates[#templates + 1] = event
    end
end

return templates
