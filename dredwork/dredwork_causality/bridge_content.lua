-- The Ripple — Content Bridge
-- Wires the expanded data content (8 culture axes, 10 biomes, 10 tech fields,
-- 13 heritage types, 20 species) into active simulation connections.
-- This is where the "thickness" of interconnection lives.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    --------------------------------------------------------------------------
    -- CULTURE AXES → SYSTEMS (the 5 new axes)
    --------------------------------------------------------------------------

    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.culture or not gs.culture.axes then return end
        local axes = gs.culture.axes

        -- CUL_FAI (Mysticism) → Religion + Technology
        local faith_val = axes.CUL_FAI or 50
        if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
            -- High mysticism feeds zeal slowly
            if faith_val > 65 then
                gs.religion.active_faith.attributes.zeal = Math.clamp(
                    (gs.religion.active_faith.attributes.zeal or 50) + 0.2, 0, 100)
            end
            -- Low mysticism (rationalism) boosts tolerance
            if faith_val < 35 then
                gs.religion.active_faith.attributes.tolerance = Math.clamp(
                    (gs.religion.active_faith.attributes.tolerance or 50) + 0.2, 0, 100)
            end
        end

        -- CUL_HON (Honor) → Crime + Court
        local honor_val = axes.CUL_HON or 50
        if honor_val > 65 then
            -- High honor culture suppresses corruption
            if gs.underworld then
                gs.underworld.global_corruption = Math.clamp(
                    (gs.underworld.global_corruption or 0) - 0.3, 0, 100)
            end
            -- High honor raises betrayal cost (loyalty baseline rises)
            if gs.court then
                for _, member in ipairs(gs.court.members or {}) do
                    if member.status == "active" and member.loyalty > 40 then
                        member.loyalty = Math.clamp(member.loyalty + 0.1, 0, 100)
                    end
                end
            end
        elseif honor_val < 35 then
            -- Low honor (pragmatism) enables corruption but enables espionage
            if gs.underworld then
                gs.underworld.global_corruption = Math.clamp(
                    (gs.underworld.global_corruption or 0) + 0.2, 0, 100)
            end
        end

        -- CUL_OPN (Openness) → Strife + Economy + Rumor
        local open_val = axes.CUL_OPN or 50
        if open_val > 65 then
            -- Cosmopolitan culture reduces strife from migration
            if gs.strife then
                gs.strife.global_tension = Math.clamp(
                    (gs.strife.global_tension or 0) - 0.3, 0, 100)
            end
        elseif open_val < 35 then
            -- Insular culture increases strife from outsiders
            if gs.strife then
                gs.strife.global_tension = Math.clamp(
                    (gs.strife.global_tension or 0) + 0.2, 0, 100)
            end
        end

        -- CUL_AUS (Austerity) → Economy + Home + Religion
        local aus_val = axes.CUL_AUS or 50
        if aus_val > 65 and gs.home and gs.home.attributes then
            -- Austere culture: lower comfort expectations, but less gold drain
            -- (People don't mind a sparse home)
            gs.home.attributes.comfort = Math.clamp(
                (gs.home.attributes.comfort or 50) - 0.1, 0, 100)
        elseif aus_val < 35 then
            -- Indulgent culture: higher expectations, drains gold
            if gs.resources then
                gs.resources.gold = gs.resources.gold - 0.5
            end
        end

        -- CUL_HIE (Hierarchy) → Politics + Court + Succession
        local hier_val = axes.CUL_HIE or 50
        if hier_val > 65 and gs.politics then
            -- Hierarchical culture supports monarchy, boosts legitimacy
            if gs.politics.active_system_id == "monarchy" then
                gs.politics.legitimacy = Math.clamp(
                    (gs.politics.legitimacy or 50) + 0.1, 0, 100)
            end
        elseif hier_val < 35 and gs.politics then
            -- Egalitarian culture supports meritocracy
            if gs.politics.active_system_id == "meritocracy" then
                gs.politics.legitimacy = Math.clamp(
                    (gs.politics.legitimacy or 50) + 0.1, 0, 100)
            end
            -- Egalitarian culture resists monarchy
            if gs.politics.active_system_id == "monarchy" then
                gs.politics.unrest = Math.clamp(
                    (gs.politics.unrest or 0) + 0.1, 0, 100)
            end
        end
    end)

    --------------------------------------------------------------------------
    -- BIOME PROPERTIES → SYSTEMS
    --------------------------------------------------------------------------

    -- Monthly: biome properties affect peril, animals, military
    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        local req_geo = { disease_risk = 0.05, wildlife_growth = 1.0, military_attrition = 1.0,
                          food_base = 50, construction_mod = 1.0, biome_tags = {} }
        engine:emit("GET_GEOGRAPHY_DATA", req_geo)

        -- Disease risk → spontaneous peril generation
        if req_geo.disease_risk > 0 and RNG.chance(req_geo.disease_risk * 0.3) then
            local peril = engine:get_module("peril")
            if peril and gs.perils and #(gs.perils.active or {}) < 3 then
                local types = req_geo.disease_risk > 0.1 and {"plague", "consumption"} or {"consumption"}
                peril:trigger(RNG.pick(types), req_geo.current_region_id)
            end
        end

        -- Wildlife growth modifier → animal reproduction
        if gs.animals and gs.animals.regional_populations then
            local region = req_geo.current_region_id
            if region and gs.animals.regional_populations[region] then
                for _, pop in pairs(gs.animals.regional_populations[region]) do
                    -- Biome growth modifier applied as a slow density drift
                    if req_geo.wildlife_growth > 1.0 then
                        pop.density = Math.clamp((pop.density or 0) + 0.1 * (req_geo.wildlife_growth - 1.0), 0, 100)
                    elseif req_geo.wildlife_growth < 1.0 then
                        pop.density = Math.clamp((pop.density or 0) - 0.05 * (1.0 - req_geo.wildlife_growth), 0, 100)
                    end
                end
            end
        end

        -- Construction mod → home repair rate
        if gs.home and gs.home.attributes and req_geo.construction_mod ~= 1.0 then
            local condition = gs.home.attributes.condition or 50
            if condition < 80 then
                -- Better construction mod = faster natural repair
                local repair = (req_geo.construction_mod - 1.0) * 0.5
                gs.home.attributes.condition = Math.clamp(condition + repair, 0, 100)
            end
        end

        -- Biome tags → specific effects
        if req_geo.biome_tags then
            local tags = {}
            for _, t in ipairs(req_geo.biome_tags) do tags[t] = true end

            -- "crime_prone" biome increases corruption
            if tags.crime_prone and gs.underworld then
                gs.underworld.global_corruption = Math.clamp(
                    (gs.underworld.global_corruption or 0) + 0.2, 0, 100)
            end

            -- "defensible" biome gives military morale bonus
            if tags.defensible and gs.military then
                for _, unit in ipairs(gs.military.units or {}) do
                    if unit.location_id == req_geo.current_region_id then
                        unit.morale = Math.clamp((unit.morale or 50) + 0.2, 0, 100)
                    end
                end
            end

            -- "trade_route" biome boosts economy
            if tags.trade_route and gs.resources then
                gs.resources.gold = gs.resources.gold + 0.3
            end

            -- "mineral_rich" biome feeds metallurgy
            if tags.mineral_rich then
                local tech = engine:get_module("technology")
                if tech and gs.technology and gs.technology.fields and gs.technology.fields.metallurgy then
                    gs.technology.fields.metallurgy.progress = (gs.technology.fields.metallurgy.progress or 0) + 0.1
                end
            end

            -- "spiritual" biome feeds theology
            if tags.spiritual then
                local tech = engine:get_module("technology")
                if tech and gs.technology and gs.technology.fields and gs.technology.fields.theology then
                    gs.technology.fields.theology.progress = (gs.technology.fields.theology.progress or 0) + 0.1
                end
            end

            -- "naval" biome feeds navigation
            if tags.naval then
                local tech = engine:get_module("technology")
                if tech and gs.technology and gs.technology.fields and gs.technology.fields.navigation then
                    gs.technology.fields.navigation.progress = (gs.technology.fields.navigation.progress or 0) + 0.1
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    -- TECHNOLOGY FIELDS → SYSTEMS (the 6 new fields)
    --------------------------------------------------------------------------

    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.technology or not gs.technology.fields then return end
        local fields = gs.technology.fields

        -- Agriculture → food supply in all markets
        local agri = fields.agriculture
        if agri and (agri.level or 1) >= 2 then
            if gs.markets then
                for _, market in pairs(gs.markets) do
                    if market.supply then
                        market.supply.food = Math.clamp(
                            (market.supply.food or 50) + (agri.level - 1) * 0.2, 0, 200)
                    end
                end
            end
        end

        -- Governance → corruption reduction + legitimacy
        local gov = fields.governance
        if gov and (gov.level or 1) >= 2 then
            if gs.underworld then
                gs.underworld.global_corruption = Math.clamp(
                    (gs.underworld.global_corruption or 0) - (gov.level - 1) * 0.1, 0, 100)
            end
            if gs.politics then
                gs.politics.legitimacy = Math.clamp(
                    (gs.politics.legitimacy or 50) + (gov.level - 1) * 0.05, 0, 100)
            end
        end

        -- Espionage → crime detection (reduces crime success indirectly via security)
        local esp = fields.espionage
        if esp and (esp.level or 1) >= 2 and gs.underworld then
            -- Each espionage level makes it harder for crime to operate
            for _, org in ipairs(gs.underworld.organizations or {}) do
                org.heat = Math.clamp((org.heat or 0) + (esp.level - 1) * 0.1, 0, 100)
            end
        end

        -- Theology → religious tolerance
        local theo = fields.theology
        if theo and (theo.level or 1) >= 2 then
            if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
                gs.religion.active_faith.attributes.tolerance = Math.clamp(
                    (gs.religion.active_faith.attributes.tolerance or 50) + (theo.level - 1) * 0.1, 0, 100)
            end
        end

        -- Metallurgy → military unit strength and great work durability
        local met = fields.metallurgy
        if met and (met.level or 1) >= 2 then
            -- Great works decay slower
            if gs.history and gs.history.great_works then
                for _, work in ipairs(gs.history.great_works) do
                    if work.is_active and work.condition then
                        work.condition = Math.clamp(work.condition + (met.level - 1) * 0.05, 0, 100)
                    end
                end
            end
        end

        -- Navigation → travel and trade
        local nav = fields.navigation
        if nav and (nav.level or 1) >= 2 then
            -- Trade bonus
            if gs.resources then
                gs.resources.gold = gs.resources.gold + (nav.level - 1) * 0.1
            end
        end
    end)

    --------------------------------------------------------------------------
    -- HERITAGE IMPACTS → SYSTEMS (using the specific impact fields)
    --------------------------------------------------------------------------

    -- Yearly: active great works apply their specific impacts
    engine:on("NEW_YEAR", function(clock)
        local gs = engine.game_state
        if not gs.history or not gs.history.great_works then return end

        for _, work in ipairs(gs.history.great_works) do
            if not work.is_active or (work.condition or 0) < 20 then goto continue end
            local impact = work.impact or {}
            local factor = (work.condition or 100) / 100

            -- Military power from fortresses
            if impact.military_power and gs.military then
                gs.military.total_power = math.floor(
                    (gs.military.total_power or 0) + impact.military_power * factor)
            end

            -- Food supply from aqueducts
            if impact.food_supply and gs.markets then
                for _, market in pairs(gs.markets) do
                    if market.supply then
                        market.supply.food = Math.clamp(
                            (market.supply.food or 50) + impact.food_supply * factor, 0, 200)
                    end
                end
            end

            -- Corruption reduction from codexes
            if impact.corruption_reduction and gs.underworld then
                gs.underworld.global_corruption = Math.clamp(
                    (gs.underworld.global_corruption or 0) - impact.corruption_reduction * factor, 0, 100)
            end

            -- Zeal from temples/relics
            if impact.zeal and gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
                gs.religion.active_faith.attributes.zeal = Math.clamp(
                    (gs.religion.active_faith.attributes.zeal or 50) + impact.zeal * factor * 0.1, 0, 100)
            end

            -- Gold income from trade networks
            if impact.gold_income and gs.resources then
                gs.resources.gold = gs.resources.gold + impact.gold_income * factor * (1/12)
            end

            -- Research bonus from academies/libraries
            if impact.research_bonus and gs.technology and gs.technology.fields then
                for _, field in pairs(gs.technology.fields) do
                    field.progress = (field.progress or 0) + impact.research_bonus * factor * 0.05
                end
            end

            -- Unrest reduction from arenas
            if impact.unrest and gs.politics then
                gs.politics.unrest = Math.clamp(
                    (gs.politics.unrest or 0) + impact.unrest * factor * 0.1, 0, 100)
            end

            -- Order from treaties/codexes
            if impact.order and gs.politics then
                gs.politics.order = Math.clamp(
                    (gs.politics.order or 50) + impact.order * factor * 0.05, 0, 100)
            end

            -- Culture axis shifts from heritage
            for axis_id, delta in pairs(impact) do
                if axis_id:match("^CUL_") and gs.culture and gs.culture.axes then
                    gs.culture.axes[axis_id] = Math.clamp(
                        (gs.culture.axes[axis_id] or 50) + delta * factor * 0.1, 0, 100)
                end
            end

            ::continue::
        end
    end)

    --------------------------------------------------------------------------
    -- ANIMAL PROPERTIES → SYSTEMS (food value, military bonus, disease, pest control)
    --------------------------------------------------------------------------

    local AnimalSpecies = nil
    pcall(function() AnimalSpecies = require("dredwork_animals.species") end)

    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.animals or not gs.animals.regional_populations or not AnimalSpecies then return end

        local req_geo = { current_region_id = nil }
        engine:emit("GET_GEOGRAPHY_DATA", req_geo)
        local region = req_geo.current_region_id
        if not region then return end
        local pops = gs.animals.regional_populations[region]
        if not pops then return end

        for species_key, pop in pairs(pops) do
            local def = AnimalSpecies[species_key]
            if not def then goto continue end
            local density = pop.density or 0

            -- Food value: huntable wildlife supplements food supply
            if def.food_value and density > 15 then
                if gs.markets and gs.markets[region] and gs.markets[region].supply then
                    gs.markets[region].supply.food = Math.clamp(
                        (gs.markets[region].supply.food or 50) + def.food_value * density * 0.005, 0, 200)
                end
            end

            -- Military bonus: war animals boost military
            if def.military_bonus and density > 10 and gs.military then
                for _, unit in ipairs(gs.military.units or {}) do
                    if unit.location_id == region then
                        unit.morale = Math.clamp((unit.morale or 50) + def.military_bonus * 0.01, 0, 100)
                    end
                end
            end

            -- Disease carrier: pests with disease_carrier increase peril risk
            if def.disease_carrier and density > 40 then
                local peril = engine:get_module("peril")
                if peril and RNG.chance(density * 0.0005) then
                    if gs.perils and #(gs.perils.active or {}) < 3 then
                        peril:trigger("plague", region)
                    end
                end
            end

            -- Pest control: species that hunt pests reduce pest density
            if def.pest_control and def.pest_control > 0 then
                -- Reduce rat density in the same region
                if pops.rats then
                    pops.rats.density = Math.clamp(
                        (pops.rats.density or 0) - def.pest_control * density * 0.001, 0, 100)
                end
            end

            -- Comfort bonus: certain species boost home comfort
            if def.comfort_bonus and def.comfort_bonus > 0 and gs.home and gs.home.attributes then
                -- Only from pets (checked in animals init), but wildlife near home affects mood
                if def.category == "wildlife" and density > 30 and def.danger < 20 then
                    gs.home.attributes.comfort = Math.clamp(
                        (gs.home.attributes.comfort or 50) + 0.1, 0, 100)
                end
            end

            -- Prestige bonus from exotic pets
            if def.prestige_bonus and def.category == "pet" then
                engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = def.prestige_bonus * 0.01 })
            end

            ::continue::
        end
    end)
end

return Bridge
