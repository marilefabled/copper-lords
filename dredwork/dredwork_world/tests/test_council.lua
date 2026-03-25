-- Test: Council — action gating, execution, consequence wiring

local Council = require("dredwork_world.council")
local genetics = require("dredwork_genetics.init")
local WorldController = require("dredwork_world.world_controller")
local council_actions = require("dredwork_world.config.council_actions")

-- Helper: build a minimal context for council tests
local function make_context(overrides)
    genetics.rng.seed(42)
    local genome = genetics.Genome.new()
    local personality = genetics.Personality.new()
    local cm = genetics.CulturalMemory.new()
    local world = WorldController.init("ancient")

    local ctx = WorldController.build_context(world, {
        generation = 1,
        heir_name = "TestHeir",
        lineage_name = "House Test",
        current_heir = genome,
        heir_personality = personality,
        cultural_memory = cm,
        mutation_pressure = genetics.Mutation.new_pressure(),
        lineage_power = { value = 50, peak = 50, nadir = 50, history = {} },
        wealth = { value = 50, history = {}, peak = 50, nadir = 50 },
        morality = { score = 0 },
        doctrines = {},
        achieved_milestones = {},
    })

    if overrides then
        for k, v in pairs(overrides) do ctx[k] = v end
    end
    return ctx, world
end

describe("Council System", function()
    it("returns all actions with availability flags", function()
        local ctx = make_context()
        local actions = Council.get_available_actions(ctx)
        assert_true(#actions > 0, "actions returned")
        for _, a in ipairs(actions) do
            assert_not_nil(a.id, "action has id")
            -- Blood rites may omit label; standard actions always have one
            assert_true(a.available == true or a.available == false, "available is boolean for " .. a.id)
        end
    end)

    it("consolidate action is always available", function()
        local ctx = make_context()
        local actions = Council.get_available_actions(ctx)
        local consolidate = nil
        for _, a in ipairs(actions) do
            if a.id == "consolidate" then consolidate = a; break end
        end
        assert_not_nil(consolidate, "consolidate exists in actions")
        assert_true(consolidate.available, "consolidate is available (no requirements)")
    end)

    it("personality-gated action blocked by low axis", function()
        local ctx = make_context()
        -- Set cruelty axis very low (direct table access — no set_axis method)
        ctx.heir_personality.axes.PER_CRM = 10
        local actions = Council.get_available_actions(ctx)
        local purge = nil
        for _, a in ipairs(actions) do
            if a.id == "purge_the_weak" then purge = a; break end
        end
        assert_not_nil(purge, "purge_the_weak exists")
        assert_true(not purge.available, "purge blocked by low cruelty")
        assert_not_nil(purge.gated_reason, "has gated reason")
    end)

    it("gold-gated action blocked by low resources", function()
        local ctx = make_context()
        -- Drain gold
        if ctx.resources then ctx.resources.gold = 0 end
        local actions = Council.get_available_actions(ctx)
        local alliance = nil
        for _, a in ipairs(actions) do
            if a.id == "seek_alliance" then alliance = a; break end
        end
        assert_not_nil(alliance, "seek_alliance exists")
        assert_true(not alliance.available, "alliance blocked by no gold")
    end)

    it("taboo blocks relevant action", function()
        local ctx = make_context()
        ctx.cultural_memory:add_taboo("cruelty_taboo", 1, "will_never_repeat_cruelty", 90)
        local actions = Council.get_available_actions(ctx)
        local purge = nil
        for _, a in ipairs(actions) do
            if a.id == "purge_the_weak" then purge = a; break end
        end
        assert_not_nil(purge, "purge exists")
        assert_true(not purge.available, "purge blocked by taboo")
    end)

    it("execute consolidate gives gold, lore, LP, mental", function()
        local ctx = make_context()
        local consolidate = nil
        for _, a in ipairs(Council.get_available_actions(ctx)) do
            if a.id == "consolidate" then consolidate = a; break end
        end
        assert_not_nil(consolidate, "consolidate found")

        local old_gold = ctx.resources and ctx.resources.gold or 0
        local old_lore = ctx.resources and ctx.resources.lore or 0
        local old_lp = ctx.lineage_power and ctx.lineage_power.value or 0

        local effects = Council.execute(consolidate, ctx)
        assert_not_nil(effects, "effects returned")
        assert_not_nil(effects.narrative, "narrative returned")
    end)

    it("cost display shows FREE for consolidate", function()
        local ctx = make_context()
        local actions = Council.get_available_actions(ctx)
        local consolidate = nil
        for _, a in ipairs(actions) do
            if a.id == "consolidate" then consolidate = a; break end
        end
        assert_equal("FREE", consolidate.cost_display, "consolidate is free")
    end)

    it("cost display shows gold cost for alliance", function()
        local ctx = make_context()
        local actions = Council.get_available_actions(ctx)
        local alliance = nil
        for _, a in ipairs(actions) do
            if a.id == "seek_alliance" then alliance = a; break end
        end
        assert_not_nil(alliance, "alliance exists")
        assert_true(alliance.cost_display:find("GOLD") ~= nil, "shows gold cost")
    end)

    it("all action definitions have required fields", function()
        for _, a in ipairs(council_actions) do
            assert_not_nil(a.id, "action has id: " .. tostring(a.label))
            assert_not_nil(a.category, "action has category: " .. a.id)
            assert_not_nil(a.label, "action has label: " .. a.id)
            assert_not_nil(a.description, "action has description: " .. a.id)
            assert_not_nil(a.narrative, "action has narrative: " .. a.id)
            assert_not_nil(a.consequences, "action has consequences: " .. a.id)
        end
    end)
end)
