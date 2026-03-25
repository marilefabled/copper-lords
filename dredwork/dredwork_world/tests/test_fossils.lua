-- Dark Legacy — Trait Fossils Tests

local Genome = require("dredwork_genetics.genome")
local TraitFossils = require("dredwork_world.trait_fossils")
local rng = require("dredwork_core.rng")

describe("Trait Fossils System", function()
    rng.seed(42)

    it("should track peak values for traits", function()
        local peaks = {}
        local genome = Genome.new()
        genome:set_value("PHY_STR", 85)

        TraitFossils.update_peaks(peaks, genome, 1, "Kael")
        assert_not_nil(peaks.PHY_STR, "Should track PHY_STR peak")
        assert_equal(85, peaks.PHY_STR.value, "Peak value should be 85")
        assert_equal(1, peaks.PHY_STR.generation, "Peak generation should be 1")
        assert_equal("Kael", peaks.PHY_STR.heir_name, "Peak heir should be Kael")
    end)

    it("should update peak only when new value is higher", function()
        local peaks = { PHY_STR = { value = 85, generation = 1, heir_name = "Kael" } }
        local genome = Genome.new()
        genome:set_value("PHY_STR", 70)

        TraitFossils.update_peaks(peaks, genome, 2, "Mira")
        assert_equal(85, peaks.PHY_STR.value, "Peak should not decrease")
        assert_equal("Kael", peaks.PHY_STR.heir_name, "Peak heir should remain Kael")
    end)

    it("should detect fossils when trait drops 25+ from peak of 75+", function()
        local peaks = { PHY_STR = { value = 90, generation = 3, heir_name = "Kael" } }
        local genome = Genome.new()
        genome:set_value("PHY_STR", 55)

        local fossils = TraitFossils.detect(peaks, genome)
        assert_equal(1, #fossils, "Should detect 1 fossil")
        assert_equal("PHY_STR", fossils[1].trait_id, "Fossil should be PHY_STR")
        assert_equal(90, fossils[1].peak_value, "Peak value should be 90")
        assert_equal(55, fossils[1].current_value, "Current value should be 55")
        assert_equal(35, fossils[1].gap, "Gap should be 35")
    end)

    it("should not detect fossil if peak below 75", function()
        local peaks = { PHY_STR = { value = 70, generation = 3, heir_name = "Kael" } }
        local genome = Genome.new()
        genome:set_value("PHY_STR", 40)

        local fossils = TraitFossils.detect(peaks, genome)
        assert_equal(0, #fossils, "Should not detect fossil for sub-75 peak")
    end)

    it("should not detect fossil if gap under 25", function()
        local peaks = { PHY_STR = { value = 80, generation = 3, heir_name = "Kael" } }
        local genome = Genome.new()
        genome:set_value("PHY_STR", 60)

        local fossils = TraitFossils.detect(peaks, genome)
        assert_equal(0, #fossils, "Should not detect fossil for sub-25 gap")
    end)

    it("should detect restoration when current within 10 of peak", function()
        local peaks = { PHY_STR = { value = 90, generation = 3, heir_name = "Kael" } }
        local genome = Genome.new()
        genome:set_value("PHY_STR", 82)

        local prev_fossils = {
            { trait_id = "PHY_STR", trait_name = "Strength", peak_value = 90,
              peak_heir = "Kael", current_value = 55, gap = 35 }
        }

        local restorations = TraitFossils.check_restorations(peaks, genome, prev_fossils)
        assert_equal(1, #restorations, "Should detect 1 restoration")
        assert_equal("Kael", restorations[1].peak_heir, "Restoration should reference Kael")
    end)

    it("should sort fossils by gap descending", function()
        local peaks = {
            PHY_STR = { value = 90, generation = 3, heir_name = "Kael" },
            MEN_INT = { value = 95, generation = 5, heir_name = "Mira" },
        }
        local genome = Genome.new()
        genome:set_value("PHY_STR", 60)
        genome:set_value("MEN_INT", 40)

        local fossils = TraitFossils.detect(peaks, genome)
        assert_true(#fossils >= 2, "Should detect 2 fossils")
        assert_true(fossils[1].gap >= fossils[2].gap, "Should sort by gap descending")
    end)

    it("should generate narrative text for fossil", function()
        local fossil = {
            trait_id = "PHY_STR",
            trait_name = "Strength",
            peak_value = 90,
            peak_heir = "Kael",
            current_value = 55,
            gap = 35,
        }
        local narrative = TraitFossils.get_narrative(fossil)
        assert_not_nil(narrative, "Should generate narrative")
        assert_true(#narrative > 0, "Narrative should not be empty")
    end)

    it("should handle nil inputs gracefully", function()
        local fossils = TraitFossils.detect(nil, nil)
        assert_equal(0, #fossils, "Should return empty for nil inputs")

        local restorations = TraitFossils.check_restorations(nil, nil, nil)
        assert_equal(0, #restorations, "Should return empty for nil inputs")
    end)
end)
