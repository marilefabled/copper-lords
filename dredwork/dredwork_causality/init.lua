-- dredwork Causality — "The Ripple"
-- The connective tissue of the simulation. Every action echoes.
--
-- Structured as a collection of bridge files, each wiring a domain of
-- cross-module consequences. Adding a new bridge = adding a new file.
--
-- Design: Theme-agnostic. Events describe WHAT happened, not WHY.
-- The Ripple maps structural consequences, not narrative flavor.
-- This module owns NO game_state. It only listens and emits.

local Causality = {}
Causality.__index = Causality

function Causality.init(engine)
    local self = setmetatable({}, Causality)
    self.engine = engine

    -- Load all bridge files. Each receives the engine and wires its own listeners.
    local bridges = {
        require("dredwork_causality.bridge_characters"),   -- court, rivals, marriage, decisions, biography, ledger → world
        require("dredwork_causality.bridge_animals"),       -- animals ↔ religion, strife, crime, court, military, home
        require("dredwork_causality.bridge_sports"),        -- sports ↔ religion, crime, strife, rivals, culture, military, heritage
        require("dredwork_causality.bridge_religion"),      -- religion ↔ crime, punishment, marriage, court, conquest, home
        require("dredwork_causality.bridge_conflict"),      -- military, conquest, peril, crime ↔ characters, economy, culture
        require("dredwork_causality.bridge_domestic"),      -- home, technology, geography, heritage ↔ characters, economy
        require("dredwork_causality.bridge_content"),       -- expanded data: 8 culture axes, 10 biomes, 10 tech fields, heritage impacts, animal properties
        require("dredwork_causality.bridge_mortality"),     -- heir death, succession, birth, child death → everything
        require("dredwork_causality.bridge_duel"),          -- duel outcomes → court, rivals, politics, heritage, rumor, strife
        require("dredwork_causality.bridge_personal"),      -- encounters, items, mood, wealth, inner voice → narrative, needs
        require("dredwork_causality.bridge_narrative"),     -- echoes, approaches, patterns, arcs → reputation, rumors, memory, biography
        require("dredwork_causality.bridge_agency"),        -- NPC autonomous actions → happenings, suspicion, narrative pressure
        require("dredwork_causality.bridge_consequence"),  -- state-pair juxtaposition, memory echoes, world voice
    }

    for _, bridge in ipairs(bridges) do
        bridge.wire(engine)
    end

    return self
end

function Causality:serialize() return {} end
function Causality:deserialize(data) end

return Causality
