-- The Ripple — Animals Bridge
-- Animals ↔ religion, strife, crime, court, military, home, economy, rumor, culture.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    -- Monthly: animals interact with everything
    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.animals then return end

        local req_geo = { current_region_id = nil }
        engine:emit("GET_GEOGRAPHY_DATA", req_geo)
        local current_region = req_geo.current_region_id
        if not current_region then return end

        local pops = gs.animals.regional_populations and gs.animals.regional_populations[current_region]
        if not pops then return end

        -- ANIMALS → STRIFE: Predator overpopulation creates fear-based bias
        for species, pop in pairs(pops) do
            if pop.density > 60 then
                local strife = engine:get_module("strife")
                if strife then
                    -- Dangerous wildlife creates a "siege mentality" that increases xenophobia
                    strife:set_regional_bias(current_region, "PER_BLD", 60, 0.02)
                end
            end
        end

        -- ANIMALS → RELIGION: Sacred animals at high density = religious fervor
        local req_rel = { sacred_species = nil }
        engine:emit("GET_RELIGION_DATA", req_rel)
        if req_rel.sacred_species and pops[req_rel.sacred_species] then
            local sacred_pop = pops[req_rel.sacred_species]
            if sacred_pop.density > 50 then
                -- Thriving sacred animals strengthen faith
                if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
                    gs.religion.active_faith.attributes.zeal = Math.clamp(
                        (gs.religion.active_faith.attributes.zeal or 50) + 0.5, 0, 100)
                end
            elseif sacred_pop.density < 10 then
                -- Sacred animals dying = crisis of faith OR zealous backlash
                if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
                    local zeal = gs.religion.active_faith.attributes.zeal or 50
                    if zeal > 60 then
                        -- High zeal: people blame outsiders
                        if gs.politics then
                            gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) + 3, 0, 100)
                        end
                    else
                        -- Low zeal: faith weakens
                        gs.religion.active_faith.attributes.zeal = Math.clamp(zeal - 2, 0, 100)
                    end
                end
            end
        end

        -- ANIMALS → CRIME: Pest infestations create black market for pest control
        local rats = pops.rats
        if rats and rats.density > 50 then
            if gs.underworld then
                gs.underworld.global_corruption = Math.clamp(
                    (gs.underworld.global_corruption or 0) + 0.5, 0, 100)
            end
        end

        -- ANIMALS → ECONOMY: Livestock density affects food supply
        local livestock_species = {"cattle", "sheep", "goats", "pigs"}
        for _, species in ipairs(livestock_species) do
            if pops[species] and pops[species].density > 30 then
                local market = gs.markets and gs.markets[current_region]
                if market and market.supply then
                    market.supply.food = Math.clamp((market.supply.food or 50) + 1, 0, 200)
                end
            end
        end

        -- ANIMALS → MILITARY: War animals affect unit effectiveness
        local horses = pops.horses
        if horses and horses.density > 20 and gs.military then
            for _, unit in ipairs(gs.military.units or {}) do
                if unit.location_id == current_region and unit.type == "cavalry" then
                    unit.morale = Math.clamp((unit.morale or 50) + 1, 0, 100)
                end
            end
        end
    end)

    -- Pet death affects the household
    engine:on("ADVANCE_GENERATION", function(context)
        local gs = engine.game_state
        if not gs.animals or not gs.animals.pets then return end

        for _, pet in ipairs(gs.animals.pets) do
            if pet.is_dead then
                -- Pet death reduces home comfort (grief)
                if gs.home and gs.home.attributes then
                    gs.home.attributes.comfort = Math.clamp(
                        (gs.home.attributes.comfort or 50) - 5, 0, 100)
                end
                -- Court mourns
                if gs.court then
                    for _, member in ipairs(gs.court.members or {}) do
                        if member.status == "active" and member.loyalty > 50 then
                            member.loyalty = Math.clamp(member.loyalty - 1, 0, 100)
                        end
                    end
                end
            end
        end
    end)
end

return Bridge
