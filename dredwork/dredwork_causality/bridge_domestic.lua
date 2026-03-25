-- The Ripple — Domestic Bridge
-- Home, technology, geography, heritage ↔ characters, economy, culture, court, rivals.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    --------------------------------------------------------------------------
    -- HOME → CHARACTERS
    --------------------------------------------------------------------------

    -- Monthly: home condition affects court and heir
    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.home or not gs.home.attributes then return end

        local comfort = gs.home.attributes.comfort or 50
        local condition = gs.home.attributes.condition or 50

        -- Dilapidated home erodes court loyalty (embarrassment)
        if condition < 25 and gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" then
                    member.loyalty = Math.clamp(member.loyalty - 0.5, 0, 100)
                end
            end
        end

        -- Luxurious home attracts rivalry (envy)
        if comfort > 80 and gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude == "wary" then
                    -- Wealthy display invites covetousness
                    if RNG.chance(0.05) then
                        house.disposition = Math.clamp(house.disposition - 1, -100, 100)
                    end
                end
            end
        end

        -- Home comfort affects strife (comfortable people are less tense)
        if comfort > 60 and gs.strife then
            gs.strife.global_tension = Math.clamp(
                (gs.strife.global_tension or 0) - 0.3, 0, 100)
        end
    end)

    --------------------------------------------------------------------------
    -- TECHNOLOGY → CHARACTERS & WORLD
    --------------------------------------------------------------------------

    -- Generational: tech advancement has wide effects
    engine:on("ADVANCE_GENERATION", function(context)
        local gs = engine.game_state
        if not gs.technology or not gs.technology.fields then return end

        -- Medicine tech reduces peril severity
        local medicine = gs.technology.fields.medicine
        if medicine and (medicine.level or 0) >= 2 then
            if gs.perils and gs.perils.active then
                for _, p in ipairs(gs.perils.active) do
                    if p.category == "disease" then
                        p.severity = Math.clamp((p.severity or 50) - 10, 0, 100)
                    end
                end
            end
        end

        -- Agriculture tech improves food supply
        local agriculture = gs.technology.fields.agriculture
        if agriculture and (agriculture.level or 0) >= 2 then
            if gs.markets then
                for _, market in pairs(gs.markets) do
                    if market.supply then
                        market.supply.food = Math.clamp((market.supply.food or 50) + 5, 0, 200)
                    end
                end
            end
        end

        -- Infrastructure tech improves home condition recovery
        local infra = gs.technology.fields.infrastructure
        if infra and (infra.level or 0) >= 2 then
            if gs.home and gs.home.attributes then
                gs.home.attributes.condition = Math.clamp(
                    (gs.home.attributes.condition or 50) + 5, 0, 100)
            end
        end

        -- Advanced civilization intimidates weaker rivals
        for _, field in pairs(gs.technology.fields) do
            if field.level and field.level > 3 then
                if gs.rivals then
                    for _, house in ipairs(gs.rivals.houses or {}) do
                        if house.power < 50 then
                            house.power = Math.clamp(house.power - 2, 10, 100)
                        end
                    end
                end
                break
            end
        end
    end)

    --------------------------------------------------------------------------
    -- GEOGRAPHY → CHARACTERS (via climate stress)
    --------------------------------------------------------------------------

    -- Yearly: harsh geography affects court and animals
    engine:on("NEW_YEAR", function(clock)
        local gs = engine.game_state
        local req_geo = { biome = "temperate" }
        engine:emit("GET_GEOGRAPHY_DATA", req_geo)

        -- Harsh biomes create hardier but less loyal courts
        if req_geo.biome == "tundra" or req_geo.biome == "desert" then
            if gs.court then
                for _, member in ipairs(gs.court.members or {}) do
                    if member.status == "active" then
                        member.competence = Math.clamp(member.competence + 1, 0, 100)
                        member.loyalty = Math.clamp(member.loyalty - 1, 0, 100)
                    end
                end
            end
        end

        -- Tropical biomes breed more wildlife
        if req_geo.biome == "tropical" and gs.animals and gs.animals.regional_populations then
            local current = req_geo.current_region_id
            if current and gs.animals.regional_populations[current] then
                for _, pop in pairs(gs.animals.regional_populations[current]) do
                    pop.density = Math.clamp((pop.density or 10) + 2, 0, 100)
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    -- HERITAGE → CHARACTERS & CULTURE
    --------------------------------------------------------------------------

    -- Yearly: great works affect the world around them
    engine:on("NEW_YEAR", function(clock)
        local gs = engine.game_state
        if not gs.history then return end

        -- Active great works provide ongoing benefits
        local active_works = 0
        for _, work in ipairs(gs.history.great_works or {}) do
            if work.is_active and (work.condition or 0) > 30 then
                active_works = active_works + 1
            end
        end

        -- Many great works = cultural prestige = rival respect
        if active_works >= 3 and gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude ~= "hostile" then
                    house.disposition = Math.clamp(house.disposition + 1, -100, 100)
                end
            end
        end

        -- Great works attract visitors → reduce strife, boost economy
        if active_works >= 2 then
            if gs.strife then
                gs.strife.global_tension = Math.clamp(
                    (gs.strife.global_tension or 0) - 1, 0, 100)
            end
            local econ = engine:get_module("economy")
            if econ then econ:change_wealth(active_works * 3) end
        end

        -- Remembered legends shape culture (many legends = traditionalist culture)
        local remembered = 0
        for _, legend in ipairs(gs.history.legends or {}) do
            if legend.is_remembered then remembered = remembered + 1 end
        end
        if remembered >= 5 then
            local culture = engine:get_module("culture")
            if culture then culture:shift("CUL_TRD", 0.5) end
        end
    end)

    --------------------------------------------------------------------------
    -- RUMOR → CHARACTERS
    --------------------------------------------------------------------------

    -- Monthly: high-heat rumors affect court loyalty and rival perceptions
    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.rumor_network or not gs.rumor_network.rumors then return end

        local scandal_heat = 0
        local praise_heat = 0
        for _, r in pairs(gs.rumor_network.rumors) do
            if not r.dead then
                if r.tags and r.tags.scandal then scandal_heat = scandal_heat + (r.heat or 0) end
                if r.tags and r.tags.praise then praise_heat = praise_heat + (r.heat or 0) end
            end
        end

        -- High scandal weakens court loyalty
        if scandal_heat > 100 and gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" then
                    member.loyalty = Math.clamp(member.loyalty - 0.5, 0, 100)
                end
            end
        end

        -- High praise strengthens court loyalty
        if praise_heat > 100 and gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" then
                    member.loyalty = Math.clamp(member.loyalty + 0.3, 0, 100)
                end
            end
        end

        -- Scandal emboldens hostile rivals
        if scandal_heat > 150 and gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude == "hostile" then
                    house.resources.steel = (house.resources.steel or 0) + 2
                end
            end
        end
    end)
end

return Bridge
