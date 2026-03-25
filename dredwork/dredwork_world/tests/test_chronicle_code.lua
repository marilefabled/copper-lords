-- Tests for Chronicle Code (dynasty code encoding/decoding)
local ChronicleCode = require("dredwork_world.chronicle_code")

-- Sample run data (mimics RunTracker output)
local function make_sample_run()
    return {
        id = 1,
        lineage_name = "House Dredwick",
        start_era = "ancient",
        final_era = "iron",
        final_generation = 12,
        current_generation = 12,
        cause_of_death = "plague",
        final_reputation = "warriors",
        conditions_survived = { "plague", "war" },
        taboo_count = 3,
        heirs = {
            {
                name = "Aldric",
                generation = 1,
                era = "ancient",
                reputation = "warriors",
                legend = { title = "The Butcher" },
                epitaph = "Where others hesitated, Aldric moved.",
                black_sheep = false,
            },
            {
                name = "Maren",
                generation = 5,
                era = "ancient",
                reputation = "warriors",
                legend = nil,
                epitaph = "Maren carried the weight with quiet fury.",
                black_sheep = false,
            },
            {
                name = "Thessa",
                generation = 12,
                era = "iron",
                reputation = "warriors",
                legend = { title = "The Cursed" },
                epitaph = "The plague took what strength could not protect.",
                black_sheep = true,
            },
        },
        chronicle = {
            { text = "Generation 1. Aldric ruled with an iron hand.", generation = 1 },
            { text = "Generation 5. Maren bore the weight.", generation = 5 },
            { text = "Generation 12. Thessa watched the plague.", generation = 12 },
        },
        milestones = {
            { id = "iron_bloodline", generation = 10, title = "Iron Bloodline" },
            { id = "endured_plague", generation = 8, title = "Endured the Plague" },
        },
        legends = {
            { title = "The Butcher", category = "feared", generation = 1, heir_name = "Aldric" },
            { title = "The Cursed", category = "tragic", generation = 12, heir_name = "Thessa" },
        },
        crucibles = {
            { trial_id = "trial_of_fire", generation = 7, outcome = "triumph", heir_name = "Maren" },
        },
        chains = {
            { chain_id = "plague_origin", generation = 9, stages_completed = 3, title = "Origins of the Plague" },
        },
    }
end

describe("Chronicle Code", function()
    it("should extract payload from run data", function()
        local run = make_sample_run()
        local payload = ChronicleCode.extract_payload(run)

        assert_not_nil(payload)
        assert_equal(4, payload.v)
        assert_equal("House Dredwick", payload.meta.name)
        assert_equal("ancient", payload.meta.start)
        assert_equal("iron", payload.meta.finish)
        assert_equal(12, payload.meta.gens)
        assert_equal("plague", payload.meta.extinct)
    end)

    it("should extract chapters with compact keys", function()
        local run = make_sample_run()
        local payload = ChronicleCode.extract_payload(run)

        assert_equal(3, #payload.chapters)
        assert_equal("Aldric", payload.chapters[1].heir.n)
        assert_equal(1, payload.chapters[1].g)
        assert_equal("The Butcher", payload.chapters[1].heir.l)
        assert_true(payload.chapters[3].heir.bs, "Thessa should be black sheep")
    end)

    it("should extract chronicle entries in chapters", function()
        local run = make_sample_run()
        local payload = ChronicleCode.extract_payload(run)

        assert_equal(1, #payload.chapters[1].events)
        assert_true(payload.chapters[1].events[1]:find("Aldric") ~= nil, "first entry should mention Aldric")
    end)

    it("should extract milestones, legends, standouts", function()
        local run = make_sample_run()
        local payload = ChronicleCode.extract_payload(run)

        assert_equal(2, #payload.legacy.milestones)
        assert_equal("Iron Bloodline", payload.legacy.milestones[1].t)

        assert_equal(2, #payload.legacy.legends)
        assert_equal("The Butcher", payload.legacy.legends[1].t)

        assert_true(#payload.so >= 2, "should have at least 2 standouts")
        assert_equal("Aldric", payload.so[1].n)
    end)

    it("should encode to a BWCH1: prefixed string", function()
        local run = make_sample_run()
        local code = ChronicleCode.encode(run)

        assert_not_nil(code)
        assert_true(code:sub(1, 6) == "BWCH1:", "code should start with BWCH1:")
        assert_true(#code > 50, "code should be substantial")
    end)

    it("should round-trip encode and decode", function()
        local run = make_sample_run()
        local code = ChronicleCode.encode(run)
        local decoded = ChronicleCode.decode(code)

        assert_not_nil(decoded)
        assert_equal("House Dredwick", decoded.meta.name)
        assert_equal(12, decoded.meta.gens)
        assert_equal("plague", decoded.meta.extinct)
        assert_equal(3, #decoded.chapters)
        assert_equal("Aldric", decoded.chapters[1].heir.n)
        assert_equal(1, #decoded.chapters[1].events)
        assert_equal(2, #decoded.legacy.milestones)
    end)

    it("should handle nil run data gracefully", function()
        local code = ChronicleCode.encode(nil)
        assert_nil(code, "nil run should produce nil code")

        local decoded = ChronicleCode.decode(nil)
        assert_nil(decoded, "nil code should produce nil payload")

        local decoded2 = ChronicleCode.decode("invalid_prefix:stuff")
        assert_nil(decoded2, "wrong prefix should produce nil")
    end)

    it("should handle empty run data", function()
        local run = {
            lineage_name = "Empty House",
            final_generation = 1,
        }
        local code = ChronicleCode.encode(run)
        assert_not_nil(code)

        local decoded = ChronicleCode.decode(code)
        assert_equal("Empty House", decoded.meta.name)
        assert_equal(0, #decoded.chapters)
    end)

    it("should handle legend as string (not table)", function()
        local run = make_sample_run()
        run.heirs[1].legend = "The Butcher"
        local payload = ChronicleCode.extract_payload(run)
        assert_equal("The Butcher", payload.chapters[1].heir.l)
    end)

    it("should produce a valid prompt with code inserted", function()
        local run = make_sample_run()
        local code = ChronicleCode.encode(run)
        local prompt = ChronicleCode.get_prompt(code)

        assert_true(prompt:find("BWCH1:") ~= nil, "prompt should contain the code")
        assert_true(prompt:find("THE SOUL TELLER") ~= nil, "prompt should contain writing instructions")
        assert_true(prompt:find("DYNASTY DATA") ~= nil, "prompt should have code section")
    end)

    it("should keep code size manageable for typical runs", function()
        local run = {
            lineage_name = "House Valkorin",
            start_era = "ancient",
            final_era = "twilight",
            final_generation = 50,
            cause_of_death = "plague",
            final_reputation = "tyrants",
            conditions_survived = { "plague", "war", "famine" },
            taboo_count = 8,
            heirs = {},
            chronicle = {},
            milestones = {},
            legends = {},
            crucibles = {},
            chains = {},
        }

        for i = 1, 50 do
            run.heirs[i] = {
                name = "Heir_" .. i,
                generation = i,
                era = "iron",
                reputation = "warriors",
                legend = (i % 5 == 0) and { title = "Legend_" .. i } or nil,
                epitaph = "Generation " .. i .. " walked a dark path.",
                black_sheep = (i % 12 == 0),
            }
        end

        for i = 1, 50 do
            run.chronicle[i] = "Generation " .. i .. ". The bloodline endured through storm and shadow."
        end

        for i = 1, 10 do
            run.milestones[i] = { id = "ms_" .. i, generation = i * 5, title = "Milestone " .. i }
        end

        for i = 1, 5 do
            run.legends[i] = { title = "Legend " .. i, category = "feared", generation = i * 10, heir_name = "Heir_" .. (i * 10) }
        end

        local code = ChronicleCode.encode(run)
        assert_not_nil(code)
        assert_true(#code < 15000, "code should be under 15KB, got " .. #code)
    end)
end)
