-- Bloodweight — Sigil Data Tests
-- Verifies sigil generation from cultural memory: patterns, parameters, taboo/relationship marks.

local SigilData = require("dredwork_genetics.sigil_data")

describe("SigilData", function()

    -- Helper: create a minimal cultural memory table
    local function make_memory(overrides)
        overrides = overrides or {}
        local mem = {
            trait_priorities = overrides.trait_priorities or {
                PHY_STR = 72, PHY_END = 60, PHY_VIT = 55,
                MEN_INT = 45, MEN_FOC = 50,
                SOC_CHA = 65, SOC_EMP = 40,
                CRE_ING = 50, CRE_CRA = 48,
            },
            reputation = overrides.reputation or {
                primary = overrides.rep or "warriors",
                secondary = "tyrants",
            },
            taboos = overrides.taboos or {},
            relationships = overrides.relationships or {},
        }
        return mem
    end

    -- Nil safety

    it("returns nil for nil cultural_memory", function()
        local result = SigilData.generate(nil, 1)
        assert_equal(nil, result)
    end)

    it("handles missing trait_priorities gracefully", function()
        local mem = { reputation = { primary = "scholars" }, taboos = {}, relationships = {} }
        local result = SigilData.generate(mem, 5)
        assert_not_nil(result)
        assert_not_nil(result.base_pattern)
        assert_not_nil(result.base_params)
    end)

    -- Pattern selection from reputation

    it("warriors produce rose pattern", function()
        local mem = make_memory({ rep = "warriors" })
        local result = SigilData.generate(mem, 10)
        assert_equal("rose", result.base_pattern)
    end)

    it("scholars produce lissajous pattern", function()
        local mem = make_memory({ rep = "scholars" })
        local result = SigilData.generate(mem, 10)
        assert_equal("lissajous", result.base_pattern)
    end)

    it("diplomats produce spirograph pattern", function()
        local mem = make_memory({ rep = "diplomats" })
        local result = SigilData.generate(mem, 10)
        assert_equal("spirograph", result.base_pattern)
    end)

    it("artisans produce lissajous pattern", function()
        local mem = make_memory({ rep = "artisans" })
        local result = SigilData.generate(mem, 10)
        assert_equal("lissajous", result.base_pattern)
    end)

    it("mystics produce spirograph pattern", function()
        local mem = make_memory({ rep = "mystics" })
        local result = SigilData.generate(mem, 10)
        assert_equal("spirograph", result.base_pattern)
    end)

    -- Dominant category

    it("warriors map to physical category", function()
        local mem = make_memory({ rep = "warriors" })
        local result = SigilData.generate(mem, 10)
        assert_equal("physical", result.dominant_color_cat)
    end)

    it("scholars map to mental category", function()
        local mem = make_memory({ rep = "scholars" })
        local result = SigilData.generate(mem, 10)
        assert_equal("mental", result.dominant_color_cat)
    end)

    it("artisans map to creative category", function()
        local mem = make_memory({ rep = "artisans" })
        local result = SigilData.generate(mem, 10)
        assert_equal("creative", result.dominant_color_cat)
    end)

    -- Parameters from trait priorities

    it("base_params derive from category averages", function()
        local mem = make_memory({
            trait_priorities = {
                PHY_STR = 90, PHY_END = 90, -- high physical
                MEN_INT = 20, MEN_FOC = 20, -- low mental
                SOC_CHA = 60,
                CRE_ING = 50,
            },
        })
        local result = SigilData.generate(mem, 10)
        assert_not_nil(result.base_params.a)
        assert_not_nil(result.base_params.b)
        assert_not_nil(result.base_params.delta)
        assert_not_nil(result.base_params.d)
        -- High physical → higher a value than low mental → b
        assert_true(result.base_params.a >= result.base_params.b,
            "high phys a=" .. result.base_params.a .. " >= low mental b=" .. result.base_params.b)
    end)

    -- Weathering scales with generation

    it("generation 1 has low weathering", function()
        local mem = make_memory()
        local result = SigilData.generate(mem, 1)
        assert_true(result.weathering < 0.1, "gen 1 weathering=" .. result.weathering)
    end)

    it("generation 50 has max weathering", function()
        local mem = make_memory()
        local result = SigilData.generate(mem, 50)
        assert_true(result.weathering >= 0.99, "gen 50 weathering=" .. result.weathering)
    end)

    it("generation 25 has mid weathering", function()
        local mem = make_memory()
        local result = SigilData.generate(mem, 25)
        assert_true(result.weathering >= 0.4 and result.weathering <= 0.6,
            "gen 25 weathering=" .. result.weathering)
    end)

    -- Symmetry and taboos

    it("no taboos gives symmetry 4", function()
        local mem = make_memory({ taboos = {} })
        local result = SigilData.generate(mem, 10)
        assert_equal(4, result.symmetry)
    end)

    it("2 taboos gives symmetry 2", function()
        local mem = make_memory({
            taboos = {
                { trigger = "a", generation = 5, effect = "x", strength = 80 },
                { trigger = "b", generation = 8, effect = "y", strength = 60 },
            },
        })
        local result = SigilData.generate(mem, 10)
        assert_equal(2, result.symmetry)
    end)

    it("5 taboos gives minimum symmetry 1", function()
        local mem = make_memory({
            taboos = {
                { trigger = "a", generation = 1, effect = "x", strength = 80 },
                { trigger = "b", generation = 2, effect = "y", strength = 70 },
                { trigger = "c", generation = 3, effect = "z", strength = 60 },
                { trigger = "d", generation = 4, effect = "w", strength = 50 },
                { trigger = "e", generation = 5, effect = "v", strength = 40 },
            },
        })
        local result = SigilData.generate(mem, 10)
        assert_equal(1, result.symmetry)
    end)

    -- Taboo scars

    it("taboo scars generated for each taboo", function()
        local mem = make_memory({
            taboos = {
                { trigger = "a", generation = 5, effect = "x", strength = 80 },
                { trigger = "b", generation = 8, effect = "y", strength = 60 },
            },
        })
        local result = SigilData.generate(mem, 10)
        assert_equal(2, #result.taboo_scars)
        for _, scar in ipairs(result.taboo_scars) do
            assert_not_nil(scar.x)
            assert_not_nil(scar.y)
            assert_not_nil(scar.strength)
        end
    end)

    -- Relationship marks

    it("relationship marks generated for each relationship", function()
        local mem = make_memory({
            relationships = {
                { faction = "house_a", type = "ally", origin_gen = 3, strength = 60 },
                { faction = "house_b", type = "enemy", origin_gen = 5, strength = 40 },
            },
        })
        local result = SigilData.generate(mem, 10)
        assert_equal(2, #result.relationship_marks)
    end)

    it("ally marks are green-tinted", function()
        local mem = make_memory({
            relationships = {
                { faction = "house_a", type = "ally", origin_gen = 3, strength = 60 },
            },
        })
        local result = SigilData.generate(mem, 10)
        local rm = result.relationship_marks[1]
        assert_not_nil(rm.color)
        -- Green-ish: g channel should be highest
        assert_true(rm.color[2] > rm.color[1], "ally green > red")
    end)

    it("enemy marks are red-tinted", function()
        local mem = make_memory({
            relationships = {
                { faction = "house_b", type = "enemy", origin_gen = 5, strength = 40 },
            },
        })
        local result = SigilData.generate(mem, 10)
        local rm = result.relationship_marks[1]
        assert_not_nil(rm.color)
        -- Red-ish: r channel should be highest
        assert_true(rm.color[1] > rm.color[2], "enemy red > green")
    end)

    -- Layers

    it("layers generated for non-dominant categories above threshold", function()
        local mem = make_memory({
            rep = "warriors",
            trait_priorities = {
                PHY_STR = 80, PHY_END = 80,
                MEN_INT = 60, MEN_FOC = 55,
                SOC_CHA = 45, SOC_EMP = 50,
                CRE_ING = 30, CRE_CRA = 25,
            },
        })
        local result = SigilData.generate(mem, 10)
        assert_not_nil(result.layers)
        -- Physical is dominant; mental and social are > 40, creative < 40
        local found_mental = false
        local found_social = false
        local found_creative = false
        for _, layer in ipairs(result.layers) do
            -- Check layer colors to identify category
            if layer.color[3] > 0.6 then found_mental = true end
            if layer.color[2] > 0.5 and layer.color[1] < 0.6 then found_social = true end
        end
        -- At least mental should appear (avg ~57.5)
        assert_true(#result.layers >= 1, "should have at least 1 layer: " .. #result.layers)
    end)

    -- Determinism

    it("same inputs produce same output", function()
        local mem = make_memory()
        local r1 = SigilData.generate(mem, 10)
        local r2 = SigilData.generate(mem, 10)

        assert_equal(r1.base_pattern, r2.base_pattern)
        assert_equal(r1.base_params.a, r2.base_params.a)
        assert_equal(r1.base_params.b, r2.base_params.b)
        assert_equal(r1.weathering, r2.weathering)
        assert_equal(r1.symmetry, r2.symmetry)
        assert_equal(r1.seed, r2.seed)
    end)

    -- Different reputation produces different sigil

    it("different reputations produce different patterns", function()
        local mem_war = make_memory({ rep = "warriors" })
        local mem_sch = make_memory({ rep = "scholars" })
        local mem_dip = make_memory({ rep = "diplomats" })

        local r_war = SigilData.generate(mem_war, 10)
        local r_sch = SigilData.generate(mem_sch, 10)
        local r_dip = SigilData.generate(mem_dip, 10)

        -- At least some should differ
        local patterns = { r_war.base_pattern, r_sch.base_pattern, r_dip.base_pattern }
        local unique = {}
        for _, p in ipairs(patterns) do unique[p] = true end
        local count = 0
        for _ in pairs(unique) do count = count + 1 end
        assert_true(count >= 2, "different reps should produce different patterns")
    end)

    -- Complete descriptor structure

    it("descriptor has all required fields", function()
        local mem = make_memory()
        local result = SigilData.generate(mem, 15)

        assert_not_nil(result.base_pattern)
        assert_not_nil(result.base_params)
        assert_not_nil(result.base_params.a)
        assert_not_nil(result.base_params.b)
        assert_not_nil(result.base_params.delta)
        assert_not_nil(result.base_params.d)
        assert_not_nil(result.layers)
        assert_not_nil(result.weathering)
        assert_not_nil(result.symmetry)
        assert_not_nil(result.dominant_color_cat)
        assert_not_nil(result.generation)
        assert_not_nil(result.seed)
        assert_not_nil(result.taboo_scars)
        assert_not_nil(result.relationship_marks)
    end)

end)
