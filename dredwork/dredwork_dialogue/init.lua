-- dredwork Dialogue — Module Entry
-- Interconnects speaker personality (Genetics) and world gossip (Rumors).

local Dialogue = {}
Dialogue.__index = Dialogue

function Dialogue.init(engine)
    local self = setmetatable({}, Dialogue)
    self.engine = engine
    
    self.logic = require("dredwork_dialogue.logic")

    -- 1. Register a Service
    -- Other modules can now call engine:get_module("dialogue"):greet(speaker)
    -- Or we can add a generic service getter to the engine later.

    -- 2. Listen for events
    engine:on("CONVERSATION_STARTED", function(ctx)
        self:on_conversation(ctx)
    end)

    return self
end

--- Get a personality-appropriate greeting for a speaker.
---@param speaker table Character data
function Dialogue:greet(speaker)
    local ctx = { historical_reference = nil }
    self.engine:emit("GET_DIALOGUE_CONTEXT", ctx)
    return self.logic.get_greeting(speaker, ctx)
end

--- Get a comment about a subject, fueled by world reputation and social bonds.
---@param speaker table Character data (needs id)
---@param subject_name string
function Dialogue:comment_on(speaker, subject_name)
    -- 1. Query the Rumor module for reputation
    local rumor_mod = self.engine:get_module("rumor")
    local reputation = nil
    if rumor_mod then
        reputation = rumor_mod:get_reputation(self.engine.game_state, subject_name)
    end
    
    -- 2. Query the Bonds module for social relationship
    local bonds_mod = self.engine:get_module("bonds")
    local relationship_kind = "neutral"
    
    if bonds_mod and speaker.id then
        -- Find the subject's id if it's a person
        local target_id = self.engine.game_state:find_person_id_by_name(subject_name)
        if target_id then
            local bond = bonds_mod:get_bond(speaker.id, target_id)
            relationship_kind = bond and bond.kind or "neutral"
        end
    end
    
    return self.logic.get_contextual_comment(subject_name, reputation, relationship_kind)
end

function Dialogue:serialize() return {} end
function Dialogue:deserialize(data) end

return Dialogue
