-- dredwork Sports — Genetics Adapter
-- Bridges the genetics system with sports recruitment.
-- Translates genome traits into athletic stats.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Adapter = {}

--- Map genome trait values to athletic stats.
---@param genome table flat genome { PHY_STR = n, PHY_END = n, ... } or trait objects
---@return table { skill, fitness, speed, power, technique, mental }
function Adapter.genome_to_stats(genome)
    local function get(id)
        local v = genome[id]
        if type(v) == "table" then return v.value or 50 end
        return v or 50
    end

    return {
        skill     = Math.clamp(math.floor((get("PHY_DEX") + get("MEN_FOC")) / 2), 0, 100),
        fitness   = Math.clamp(math.floor((get("PHY_END") + get("PHY_VIT")) / 2), 0, 100),
        speed     = Math.clamp(math.floor((get("PHY_SPD") + get("PHY_DEX")) / 2), 0, 100),
        power     = Math.clamp(math.floor((get("PHY_STR") + get("PHY_END")) / 2), 0, 100),
        technique = Math.clamp(math.floor((get("MEN_FOC") + get("CRE_CRA")) / 2), 0, 100),
        mental    = Math.clamp(math.floor((get("MEN_WIL") + get("PER_BLD")) / 2), 0, 100),
    }
end

--- Generate an athlete for a team, optionally using the genetics module.
---@param team table team object (may have .faction_personality for bias)
---@return table athlete { name, age, skill, fitness, speed, power, technique, mental, morale }
function Adapter.generate_athlete(team)
    -- Base random stats with team bias
    local base = {
        PHY_STR = RNG.range(35, 75),
        PHY_END = RNG.range(35, 75),
        PHY_DEX = RNG.range(35, 75),
        PHY_SPD = RNG.range(35, 75),
        PHY_VIT = RNG.range(40, 80),
        MEN_FOC = RNG.range(30, 70),
        MEN_WIL = RNG.range(30, 70),
        CRE_CRA = RNG.range(20, 60),
        PER_BLD = RNG.range(30, 70),
    }

    -- Team personality bias (if available)
    if team and team.specialty then
        if team.specialty == "physical" then
            base.PHY_STR = base.PHY_STR + RNG.range(5, 15)
            base.PHY_END = base.PHY_END + RNG.range(5, 15)
        elseif team.specialty == "technical" then
            base.MEN_FOC = base.MEN_FOC + RNG.range(5, 15)
            base.CRE_CRA = base.CRE_CRA + RNG.range(5, 15)
        elseif team.specialty == "speed" then
            base.PHY_SPD = base.PHY_SPD + RNG.range(5, 15)
            base.PHY_DEX = base.PHY_DEX + RNG.range(5, 15)
        end
    end

    local stats = Adapter.genome_to_stats(base)

    return {
        name = "Athlete #" .. RNG.range(100, 999),
        age = RNG.range(18, 28),
        skill = stats.skill,
        fitness = stats.fitness,
        speed = stats.speed,
        power = stats.power,
        technique = stats.technique,
        mental = stats.mental,
        morale = RNG.range(50, 80),
        genome = base,
    }
end

return Adapter
