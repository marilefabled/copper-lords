-- Dark Legacy — Ancestor Echoes Tests

local Genome = require("dredwork_genetics.genome")
local Echoes = require("dredwork_world.echoes")
local rng = require("dredwork_core.rng")

describe("Ancestor Echoes System", function()
    rng.seed(42)

    it("should create a compact snapshot of visible/hinted traits", function()
        local genome = Genome.new()
        local snapshot = Echoes.snapshot(genome, "Kael", 5)

        assert_not_nil(snapshot, "Should create snapshot")
        assert_equal("Kael", snapshot.name, "Name should be Kael")
        assert_equal(5, snapshot.generation, "Generation should be 5")
        assert_true(#snapshot.traits > 0, "Should have trait entries")
        -- Should only have visible + hinted (47 traits), not all 75
        assert_true(#snapshot.traits <= 47, "Should not include hidden traits")
    end)

    it("should detect echo when 5+ traits overlap above 60 within ±10", function()
        -- Build ancestor with known high traits
        local ancestor_genome = Genome.new()
        ancestor_genome:set_value("PHY_STR", 80)
        ancestor_genome:set_value("PHY_END", 75)
        ancestor_genome:set_value("PHY_VIT", 85)
        ancestor_genome:set_value("PHY_AGI", 70)
        ancestor_genome:set_value("MEN_INT", 78)
        ancestor_genome:set_value("MEN_FOC", 72)

        local ancestor_snap = Echoes.snapshot(ancestor_genome, "Kael", 3)

        -- Build current heir with similar traits
        local current = Genome.new()
        current:set_value("PHY_STR", 82)
        current:set_value("PHY_END", 73)
        current:set_value("PHY_VIT", 83)
        current:set_value("PHY_AGI", 68)
        current:set_value("MEN_INT", 80)
        current:set_value("MEN_FOC", 74)

        local echo = Echoes.detect(current, { ancestor_snap }, 5)
        assert_not_nil(echo, "Should detect echo")
        assert_equal("Kael", echo.ancestor_name, "Echo should reference Kael")
        assert_true(echo.overlap_count >= 5, "Should have 5+ overlapping traits")
        assert_not_nil(echo.narrative, "Echo should have narrative")
    end)

    it("should not detect echo with fewer than min_overlap traits", function()
        -- Create genomes with controlled low values to avoid accidental overlap
        local ancestor_genome = Genome.new()
        -- Set only 2 traits high, everything else low
        local all_traits = ancestor_genome.traits or {}
        for id, trait in pairs(all_traits) do
            trait:set_value(30) -- Below 60, won't count as overlap
        end
        ancestor_genome:set_value("PHY_STR", 80)
        ancestor_genome:set_value("PHY_END", 75)

        local ancestor_snap = Echoes.snapshot(ancestor_genome, "Mira", 2)

        local current = Genome.new()
        for id, trait in pairs(current.traits or {}) do
            trait:set_value(30) -- Below 60
        end
        current:set_value("PHY_STR", 82)
        current:set_value("PHY_END", 73)

        local echo = Echoes.detect(current, { ancestor_snap }, 5)
        assert_nil(echo, "Should not detect echo with only 2 matches")
    end)

    it("should not match traits below 60", function()
        local ancestor_genome = Genome.new()
        ancestor_genome:set_value("PHY_STR", 50)
        ancestor_genome:set_value("PHY_END", 45)
        ancestor_genome:set_value("PHY_VIT", 55)
        ancestor_genome:set_value("PHY_AGI", 48)
        ancestor_genome:set_value("MEN_INT", 52)
        ancestor_genome:set_value("MEN_FOC", 47)

        local ancestor_snap = Echoes.snapshot(ancestor_genome, "Dull", 2)

        local current = Genome.new()
        current:set_value("PHY_STR", 51)
        current:set_value("PHY_END", 46)
        current:set_value("PHY_VIT", 56)
        current:set_value("PHY_AGI", 49)
        current:set_value("MEN_INT", 53)
        current:set_value("MEN_FOC", 48)

        local echo = Echoes.detect(current, { ancestor_snap }, 5)
        assert_nil(echo, "Should not detect echo for sub-60 traits")
    end)

    it("should pick the best match among multiple ancestors", function()
        local snap1 = {
            name = "Weak", generation = 2,
            traits = {
                { id = "PHY_STR", value = 65 },
                { id = "PHY_END", value = 65 },
                { id = "PHY_VIT", value = 65 },
                { id = "PHY_AGI", value = 65 },
                { id = "MEN_INT", value = 65 },
            },
        }
        local snap2 = {
            name = "Strong", generation = 4,
            traits = {
                { id = "PHY_STR", value = 80 },
                { id = "PHY_END", value = 80 },
                { id = "PHY_VIT", value = 80 },
                { id = "PHY_AGI", value = 80 },
                { id = "MEN_INT", value = 80 },
                { id = "MEN_FOC", value = 80 },
            },
        }

        local current = Genome.new()
        current:set_value("PHY_STR", 82)
        current:set_value("PHY_END", 78)
        current:set_value("PHY_VIT", 83)
        current:set_value("PHY_AGI", 79)
        current:set_value("MEN_INT", 81)
        current:set_value("MEN_FOC", 78)

        local echo = Echoes.detect(current, { snap1, snap2 }, 5)
        assert_not_nil(echo, "Should detect echo")
        assert_equal("Strong", echo.ancestor_name, "Should pick the stronger match")
    end)

    it("should filter ancestors by generation gap", function()
        local snaps = {
            { name = "Ancient", generation = 1, traits = {} },
            { name = "MidRange", generation = 5, traits = {} },
            { name = "Recent", generation = 8, traits = {} },
            { name = "TooRecent", generation = 9, traits = {} },
        }

        -- At gen 10: gen 1 (gap 9 >= 3 ✓), gen 5 (gap 5 >= 3 ✓),
        -- gen 8 (gap 2 < 3 ✗), gen 9 (gap 1 < 3 ✗)
        local filtered = Echoes.filter_eligible(snaps, 10)
        assert_equal(2, #filtered, "Should filter out ancestors within 2 generations")
    end)

    it("should trim snapshots to max count", function()
        local snaps = {}
        for i = 1, 25 do
            snaps[i] = { name = "Heir" .. i, generation = i, traits = {} }
        end

        Echoes.trim(snaps, 20)
        assert_equal(20, #snaps, "Should trim to 20")
        assert_equal("Heir6", snaps[1].name, "Should remove oldest entries")
    end)

    it("should generate narrative for echo", function()
        local echo = {
            ancestor_name = "Kael",
            ancestor_generation = 3,
            overlap_count = 6,
        }
        local narrative = Echoes.get_narrative(echo)
        assert_not_nil(narrative, "Should generate narrative")
        assert_true(#narrative > 0, "Narrative should not be empty")
    end)

    it("should handle nil inputs gracefully", function()
        local snap = Echoes.snapshot(nil, "Test", 1)
        assert_nil(snap, "Should return nil for nil genome")

        local echo = Echoes.detect(nil, nil)
        assert_nil(echo, "Should return nil for nil inputs")
    end)
end)
