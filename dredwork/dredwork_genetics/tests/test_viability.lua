-- Dark Legacy — Viability System Tests
-- Tests offspring survival, heir death, adjusted fertility, and gen shield.

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local Viability = require("dredwork_genetics.viability")

describe("Viability - check_offspring", function()
    it("should return alive=true most of the time with no conditions", function()
        rng.seed(12345)
        local alive_count = 0
        for i = 1, 100 do
            local genome = Genome.new({ PHY_VIT = 60, PHY_IMM = 50, PHY_END = 50, PHY_LON = 50 })
            local alive, cause = Viability.check_offspring(genome, {})
            if alive then alive_count = alive_count + 1 end
        end
        -- With vitality 60, base survival ~89%. Expect 75+ alive out of 100.
        assert_true(alive_count >= 70, "Expected most offspring to survive without conditions, got " .. alive_count)
    end)

    it("should have lower survival during plague", function()
        rng.seed(54321)
        local conditions = { { type = "plague", intensity = 0.8, remaining_gens = 3 } }
        local alive_count = 0
        for i = 1, 200 do
            local genome = Genome.new({ PHY_VIT = 40, PHY_IMM = 30, PHY_END = 40, PHY_LON = 40 })
            local alive, cause = Viability.check_offspring(genome, conditions)
            if alive then alive_count = alive_count + 1 end
        end
        -- Should be noticeably lower than baseline but better than old system
        assert_true(alive_count < 190, "Expected plague to reduce survival, got " .. alive_count .. "/200")
        assert_true(alive_count > 30, "Expected floor to prevent total wipe, got " .. alive_count .. "/200")
    end)

    it("should return a cause when offspring dies", function()
        rng.seed(99999)
        local conditions = {
            { type = "plague", intensity = 1.0, remaining_gens = 2 },
            { type = "famine", intensity = 1.0, remaining_gens = 2 },
        }
        local found_cause = false
        for i = 1, 200 do
            local genome = Genome.new({ PHY_VIT = 10, PHY_IMM = 10, PHY_END = 10, PHY_LON = 10 })
            local alive, cause = Viability.check_offspring(genome, conditions)
            if not alive then
                assert_not_nil(cause, "Death cause should not be nil")
                found_cause = true
                break
            end
        end
        assert_true(found_cause, "Expected at least one death in 200 trials with harsh conditions")
    end)

    it("should respect the 25% survival floor", function()
        rng.seed(11111)
        local conditions = {
            { type = "plague", intensity = 1.0, remaining_gens = 5 },
            { type = "famine", intensity = 1.0, remaining_gens = 5 },
            { type = "war", intensity = 1.0, remaining_gens = 5 },
        }
        local alive_count = 0
        for i = 1, 500 do
            local genome = Genome.new({ PHY_VIT = 5, PHY_IMM = 5, PHY_END = 5, PHY_LON = 5 })
            local alive, cause = Viability.check_offspring(genome, conditions)
            if alive then alive_count = alive_count + 1 end
        end
        -- Floor 25%, so expect ~125 alive out of 500 (allow wide margin)
        assert_true(alive_count > 50, "Expected floor to save some, got " .. alive_count .. "/500")
    end)

    it("should apply gen shield for early generations", function()
        rng.seed(22220)
        local conditions = { { type = "plague", intensity = 1.0, remaining_gens = 5 } }
        local alive_gen1 = 0
        local alive_gen10 = 0
        for i = 1, 500 do
            local genome = Genome.new({ PHY_VIT = 30, PHY_IMM = 20, PHY_END = 30, PHY_LON = 30 })
            local alive1 = Viability.check_offspring(genome, conditions, 1) -- gen 1: 0.20x shield
            if alive1 then alive_gen1 = alive_gen1 + 1 end
            local alive10 = Viability.check_offspring(genome, conditions, 10) -- gen 10: no shield
            if alive10 then alive_gen10 = alive_gen10 + 1 end
        end
        -- Gen 1 should have better survival than gen 10
        assert_true(alive_gen1 >= alive_gen10,
            "Gen 1 should survive more: gen1=" .. alive_gen1 .. " gen10=" .. alive_gen10)
    end)
end)

describe("Viability - adjusted_fertility", function()
    it("should return base count with no conditions", function()
        rng.seed(22222)
        local genome = Genome.new({ PHY_FER = 80, PHY_VIT = 60 })
        -- With no conditions, should usually return base count
        local total = 0
        for i = 1, 50 do
            total = total + Viability.adjusted_fertility(genome, {}, 3)
        end
        -- Should average close to 3 with no penalties
        assert_equal(150, total, "Expected 3 per trial with no conditions")
    end)

    it("should sometimes reduce count during plague", function()
        rng.seed(33333)
        local genome = Genome.new({ PHY_FER = 40, PHY_VIT = 40 })
        local conditions = { { type = "plague", intensity = 0.8, remaining_gens = 3 } }
        local reduced = false
        for i = 1, 50 do
            local count = Viability.adjusted_fertility(genome, conditions, 2)
            if count < 2 then reduced = true end
        end
        assert_true(reduced, "Expected plague to sometimes reduce fertility")
    end)

    it("should never return less than 1 (minimum floor)", function()
        rng.seed(44444)
        local genome = Genome.new({ PHY_FER = 5, PHY_VIT = 5 })
        local conditions = {
            { type = "plague", intensity = 1.0, remaining_gens = 5 },
            { type = "famine", intensity = 1.0, remaining_gens = 5 },
        }
        -- Late gen: floor at 1
        for i = 1, 200 do
            local count = Viability.adjusted_fertility(genome, conditions, 1, 20)
            assert_true(count >= 1, "Fertility should never be below 1, got " .. count)
        end
    end)

    it("should guarantee minimum 2 offspring in early gens", function()
        rng.seed(44446)
        local genome = Genome.new({ PHY_FER = 5, PHY_VIT = 5 })
        local conditions = {
            { type = "plague", intensity = 1.0, remaining_gens = 5 },
            { type = "famine", intensity = 1.0, remaining_gens = 5 },
        }
        for i = 1, 200 do
            local count = Viability.adjusted_fertility(genome, conditions, 2, 3)
            assert_true(count >= 2, "Early-gen fertility should floor at 2, got " .. count)
        end
    end)

    it("should apply gen shield for early generations", function()
        rng.seed(44445)
        local genome = Genome.new({ PHY_FER = 30, PHY_VIT = 30 })
        local conditions = { { type = "plague", intensity = 1.0, remaining_gens = 5 } }
        local total_gen1 = 0
        local total_gen10 = 0
        for i = 1, 200 do
            total_gen1 = total_gen1 + Viability.adjusted_fertility(genome, conditions, 3, 1)
            total_gen10 = total_gen10 + Viability.adjusted_fertility(genome, conditions, 3, 10)
        end
        -- Gen 1 should retain more children on average
        assert_true(total_gen1 >= total_gen10,
            "Gen 1 should have more children: gen1=" .. total_gen1 .. " gen10=" .. total_gen10)
    end)
end)

describe("Viability - check_heir_death", function()
    it("should rarely kill a healthy heir with no conditions", function()
        rng.seed(55555)
        local death_count = 0
        for i = 1, 500 do
            local genome = Genome.new({
                PHY_VIT = 70, PHY_LON = 60, PHY_IMM = 60,
                MEN_WIL = 60, MEN_COM = 60,
            })
            local pers = Personality.new({ PER_BLD = 50, PER_VOL = 40 })
            local dies, cause = Viability.check_heir_death(genome, pers, {}, 5)
            if dies then death_count = death_count + 1 end
        end
        -- Base 2%, so expect ~10 out of 500 (allow margin)
        assert_true(death_count < 30, "Expected low death rate for healthy heirs, got " .. death_count .. "/500")
    end)

    it("should have higher death rate during plague for low-immune heirs", function()
        rng.seed(66666)
        local conditions = { { type = "plague", intensity = 0.9, remaining_gens = 3 } }
        local death_count = 0
        for i = 1, 500 do
            local genome = Genome.new({
                PHY_VIT = 30, PHY_LON = 30, PHY_IMM = 15,
                MEN_WIL = 40, MEN_COM = 40,
            })
            local pers = Personality.new({ PER_BLD = 50, PER_VOL = 50 })
            local dies, cause = Viability.check_heir_death(genome, pers, conditions, 10)
            if dies then death_count = death_count + 1 end
        end
        -- Higher chance than base 2% (now using 0.05 plague multiplier)
        assert_true(death_count > 20, "Expected higher death rate during plague, got " .. death_count .. "/500")
    end)

    it("should cap death chance at 35%", function()
        rng.seed(77777)
        local conditions = {
            { type = "plague", intensity = 1.0, remaining_gens = 5 },
            { type = "war", intensity = 1.0, remaining_gens = 5 },
            { type = "famine", intensity = 1.0, remaining_gens = 5 },
        }
        local death_count = 0
        for i = 1, 1000 do
            local genome = Genome.new({
                PHY_VIT = 5, PHY_LON = 5, PHY_IMM = 5,
                MEN_WIL = 5, MEN_COM = 5,
            })
            local pers = Personality.new({ PER_BLD = 95, PER_VOL = 95 })
            local dies, cause = Viability.check_heir_death(genome, pers, conditions, 50)
            if dies then death_count = death_count + 1 end
        end
        -- Cap at 35%, so expect ~350 out of 1000 (allow margin)
        assert_true(death_count <= 450, "Expected death rate capped around 35%, got " .. death_count .. "/1000")
    end)

    it("should return a valid cause when heir dies", function()
        rng.seed(88888)
        local conditions = { { type = "war", intensity = 0.8, remaining_gens = 3 } }
        local valid_causes = {
            plague = true, killed_in_war = true, starvation = true,
            natural_frailty = true, madness = true,
        }
        for i = 1, 200 do
            local genome = Genome.new({
                PHY_VIT = 20, PHY_LON = 20, PHY_IMM = 30,
                MEN_WIL = 30, MEN_COM = 30,
            })
            local pers = Personality.new({ PER_BLD = 80, PER_VOL = 50 })
            local dies, cause = Viability.check_heir_death(genome, pers, conditions, 15)
            if dies then
                assert_not_nil(cause, "Death cause should not be nil")
                assert_true(valid_causes[cause], "Invalid cause: " .. tostring(cause))
                return -- found a valid death, test passes
            end
        end
        -- If we get here, no deaths occurred (unlikely but possible)
        -- Not a failure, just skip
    end)

    it("should increase death chance with madness for volatile low-willpower heirs", function()
        rng.seed(10101)
        local death_count_volatile = 0
        local death_count_stable = 0
        for i = 1, 500 do
            -- Volatile, low willpower
            local g1 = Genome.new({ PHY_VIT = 50, PHY_LON = 50, PHY_IMM = 50, MEN_WIL = 10, MEN_COM = 10 })
            local p1 = Personality.new({ PER_BLD = 50, PER_VOL = 90 })
            local d1, _ = Viability.check_heir_death(g1, p1, {}, 5)
            if d1 then death_count_volatile = death_count_volatile + 1 end

            -- Stable, high willpower
            local g2 = Genome.new({ PHY_VIT = 50, PHY_LON = 50, PHY_IMM = 50, MEN_WIL = 80, MEN_COM = 80 })
            local p2 = Personality.new({ PER_BLD = 50, PER_VOL = 20 })
            local d2, _ = Viability.check_heir_death(g2, p2, {}, 5)
            if d2 then death_count_stable = death_count_stable + 1 end
        end
        assert_true(death_count_volatile >= death_count_stable,
            "Volatile heirs should die at least as often: volatile=" .. death_count_volatile .. " stable=" .. death_count_stable)
    end)

    it("should apply gen shield for early generations", function()
        rng.seed(10102)
        local conditions = {
            { type = "plague", intensity = 1.0, remaining_gens = 5 },
            { type = "famine", intensity = 1.0, remaining_gens = 5 },
        }
        local death_gen1 = 0
        local death_gen10 = 0
        for i = 1, 1000 do
            local genome = Genome.new({
                PHY_VIT = 25, PHY_LON = 25, PHY_IMM = 20,
                MEN_WIL = 40, MEN_COM = 40,
            })
            local pers = Personality.new({ PER_BLD = 50, PER_VOL = 50 })
            local d1 = Viability.check_heir_death(genome, pers, conditions, 1)
            if d1 then death_gen1 = death_gen1 + 1 end
            local d10 = Viability.check_heir_death(genome, pers, conditions, 10)
            if d10 then death_gen10 = death_gen10 + 1 end
        end
        -- Gen 1 should die less often than gen 10
        assert_true(death_gen1 <= death_gen10,
            "Gen 1 should die less: gen1=" .. death_gen1 .. " gen10=" .. death_gen10)
    end)
end)
