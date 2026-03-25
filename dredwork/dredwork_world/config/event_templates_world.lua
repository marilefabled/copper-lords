-- Dark Legacy — World Event Templates
-- Events triggered by world conditions, eras, and random chance.
-- Loads sub-files from config/events/world_*.lua and merges them.

local templates = {}

local sub_files = {
    "dredwork_world.config.events.world_plague",
    "dredwork_world.config.events.world_famine",
    "dredwork_world.config.events.world_war",
    "dredwork_world.config.events.world_mystical",
    "dredwork_world.config.events.world_prosperity",
    "dredwork_world.config.events.world_discovery",
    "dredwork_world.config.events.world_era_specific",
    "dredwork_world.config.events.world_multistat",
    "dredwork_world.config.events.world_estate",
    "dredwork_world.config.events.world_dialogue",
    "dredwork_world.config.events.world_body_and_bone",
    "dredwork_world.config.events.world_hidden_mind",
    "dredwork_world.config.events.world_scarcity",
    "dredwork_world.config.events.world_morality_faith",
    "dredwork_world.config.events.world_late_game",
}

for _, mod_name in ipairs(sub_files) do
    local ok, events = pcall(require, mod_name)
    if ok and type(events) == "table" then
        for _, event in ipairs(events) do
            templates[#templates + 1] = event
        end
    else
        print("Warning: failed to load event sub-file " .. mod_name .. ": " .. tostring(events))
    end
end

return templates
