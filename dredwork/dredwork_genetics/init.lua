-- dredwork Genetics — Module Entry
-- 75-trait genetic engine: inheritance, crossover, mutation, personality.

local Genetics = {}
Genetics.__index = Genetics

--- Initialize the module with the engine.
---@param engine table The central dredwork engine.
function Genetics.init(engine)
    local self = setmetatable({}, Genetics)
    self.engine = engine

    -- Sub-components
    self.trait = require("dredwork_genetics.trait")
    self.genome = require("dredwork_genetics.genome")
    self.personality = require("dredwork_genetics.personality")
    self.inheritance = require("dredwork_genetics.inheritance")
    self.mutation = require("dredwork_genetics.mutation")
    self.cultural_memory = require("dredwork_genetics.cultural_memory")
    self.serializer = require("dredwork_genetics.serializer")
    self.viability = require("dredwork_genetics.viability")

    -- Config data
    self.trait_definitions = require("dredwork_genetics.config.trait_definitions")
    self.personality_maps = require("dredwork_genetics.config.personality_maps")
    self.mutation_tables = require("dredwork_genetics.config.mutation_tables")
    self.cultural_thresholds = require("dredwork_genetics.config.cultural_thresholds")

    -- Register for engine events
    engine:on("ADVANCE_GENERATION", function(context)
        -- Update global genetic drift or population statistics
    end)

    return self
end

--- Create a new genome, applying cultural biases via the event bus.
---@param overrides table|nil
function Genetics:create_genome(overrides)
    local genome = self.genome.new(overrides)

    -- Assign Birthday
    local rng = require("dredwork_core.rng")
    genome.birth_month = rng.range(1, 12)
    genome.birth_day = rng.range(1, 30)

    -- Apply cultural personality biases via event bus
    if genome.traits then
        for trait_id, trait in pairs(genome.traits) do
            local req = { trait_id = trait_id, bias = 0 }
            self.engine:emit("BIAS_PERSONALITY_GENERATION", req)
            if req.bias ~= 0 then
                trait.value = trait.value + req.bias
            end
        end
    end

    return genome
end

--- Inherit genetics from parents.
---@param parent_a table Genome
---@param parent_b table Genome
---@return table child Genome
function Genetics:inherit(parent_a, parent_b)
    return self.inheritance.combine(parent_a, parent_b)
end

--- Apply mutations to a genome.
---@param genome table
---@param pressure table|number
function Genetics:mutate(genome, pressure)
    return self.mutation.apply(genome, pressure)
end

--- Serialize a genome to a flat string.
---@param genome table
function Genetics:serialize_genome(genome)
    return self.serializer.pack(genome)
end

--- Deserialize a genome from a flat string.
---@param data string
function Genetics:deserialize_genome(data)
    return self.serializer.unpack(data)
end

--- Standard module serialization (for global engine state).
function Genetics:serialize()
    return {
        -- cultural_memory = self.cultural_memory.export_global_state()
    }
end

--- Step genetics (Nurture/Development).
function Genetics:tick(game_state)
    if not game_state.current_heir or game_state.current_heir.is_dead then return end
    local heir = game_state.current_heir

    -- 1. Home impact via event bus (decoupled from Home module)
    local req_home = { comfort = 50, condition = 50 }
    self.engine:emit("GET_HOME_DATA", req_home)
    if req_home.comfort > 70 then
        heir:set_value("SOC_CHA", heir:get_value("SOC_CHA") + 1)
    elseif req_home.comfort < 30 then
        heir:set_value("PHY_END", heir:get_value("PHY_END") + 2)
    end

    -- 2. Cultural impact via event bus
    local req_culture = { axes = {} }
    self.engine:emit("GET_CULTURE_DATA", req_culture)
    local martial = req_culture.axes and req_culture.axes.CUL_MAR or 50
    if martial > 70 then
        heir:set_value("PHY_STR", heir:get_value("PHY_STR") + 1)
    end
end

--- Standard module serialization.
function Genetics:deserialize(data)
    -- if data.cultural_memory then self.cultural_memory.import_global_state(data.cultural_memory) end
end

return Genetics
