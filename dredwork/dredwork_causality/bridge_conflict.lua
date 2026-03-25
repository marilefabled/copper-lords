-- The Ripple — Conflict Bridge
-- Military, conquest, peril, crime, punishment ↔ characters, economy, culture, strife.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    --------------------------------------------------------------------------
    -- PERIL → CHARACTERS
    --------------------------------------------------------------------------

    -- Disease outbreaks can kill court members and rival heirs
    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.perils or not gs.perils.active then return end

        local has_disease = false
        local has_disaster = false
        for _, p in ipairs(gs.perils.active) do
            if p.category == "disease" then has_disease = true end
            if p.category == "disaster" then has_disaster = true end
        end

        -- Plague kills court members
        if has_disease and gs.court then
            for i = #gs.court.members, 1, -1 do
                local member = gs.court.members[i]
                if member.status == "active" and RNG.chance(0.02) then
                    member.status = "dead"
                    table.remove(gs.court.members, i)
                    engine:emit("COURT_DEATH", {
                        type = "court_death", member = member,
                        text = member.name .. " has succumbed to the plague.",
                    })
                    engine:push_ui_event("COURT_DEATH", { text = member.name .. " has succumbed to the plague." })
                end
            end
        end

        -- Plague weakens rival houses too
        if has_disease and gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                house.power = Math.clamp(house.power - 1, 10, 100)
                house.resources.gold = math.max(0, (house.resources.gold or 0) - 3)
            end
        end

        -- Disasters damage rival holdings too (shared geography)
        if has_disaster and gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                house.resources.gold = math.max(0, (house.resources.gold or 0) - 5)
            end
        end

        -- Famine affects rival resources
        if gs.markets and gs.rivals then
            for _, market in pairs(gs.markets) do
                if market.prices and market.prices.food and market.prices.food > 18 then
                    for _, house in ipairs(gs.rivals.houses or {}) do
                        house.resources.gold = math.max(0, (house.resources.gold or 0) - 3)
                    end
                    break
                end
            end
        end

        -- Active peril shifts culture toward tradition (fear → conservatism)
        if (has_disease or has_disaster) then
            local culture = engine:get_module("culture")
            if culture then culture:shift("CUL_TRD", 0.5) end
        end
    end)

    --------------------------------------------------------------------------
    -- MILITARY → CHARACTERS & RIVALS
    --------------------------------------------------------------------------

    -- Yearly: military strength affects rival behavior and court confidence
    engine:on("NEW_YEAR", function(clock)
        local gs = engine.game_state
        local req_mil = { total_power = 0 }
        engine:emit("GET_MILITARY_DATA", req_mil)

        -- Weak military emboldens rivals
        if req_mil.total_power < 50 and gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                house.disposition = Math.clamp(house.disposition - 2, -100, 100)
            end
        elseif req_mil.total_power > 300 and gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude ~= "hostile" then
                    house.disposition = Math.clamp(house.disposition + 1, -100, 100)
                end
            end
        end

        -- Strong military boosts court confidence
        if req_mil.total_power > 200 and gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" and member.role == "general" then
                    member.loyalty = Math.clamp(member.loyalty + 2, 0, 100)
                end
            end
        end

        -- Conquest affects all rival dispositions
        if gs.empire and gs.empire.territories then
            local count = #gs.empire.territories
            if count > 0 and gs.rivals then
                for _, house in ipairs(gs.rivals.houses or {}) do
                    house.disposition = Math.clamp(house.disposition - count, -100, 100)
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    -- CRIME → CHARACTERS & STRIFE
    --------------------------------------------------------------------------

    engine:on("CRIMINAL_SENTENCED", function(ctx)
        local gs = engine.game_state

        -- High-profile sentencing boosts legitimacy if justice is harsh
        if gs.justice and gs.justice.terror_score > 30 then
            engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = 1 })
        end

        -- Crime crackdowns reduce hostile rival resources
        if gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude == "hostile" then
                    house.resources.steel = math.max(0, (house.resources.steel or 0) - 2)
                end
            end
        end

        -- Visible justice reduces strife
        if gs.strife then
            gs.strife.global_tension = Math.clamp((gs.strife.global_tension or 0) - 1, 0, 100)
        end

        -- But harsh justice creates cultural backlash
        if gs.justice and gs.justice.terror_score > 60 then
            local culture = engine:get_module("culture")
            if culture then culture:shift("CUL_TRD", 0.5) end
        end
    end)

    --------------------------------------------------------------------------
    -- PUNISHMENT → RIVALS & RELIGION
    --------------------------------------------------------------------------

    -- Yearly: high terror has wider effects
    engine:on("NEW_YEAR", function(clock)
        local gs = engine.game_state
        if not gs.justice then return end
        local terror = gs.justice.terror_score or 0

        -- High terror deters rival aggression
        if terror > 50 and gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude == "wary" then
                    house.disposition = Math.clamp(house.disposition + 2, -100, 100)
                end
            end
        end

        -- Religious extremists approve of harsh punishment, moderates recoil
        if terror > 40 and gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
            local zeal = gs.religion.active_faith.attributes.zeal or 50
            if zeal > 60 then
                -- Zealots approve
                gs.religion.active_faith.attributes.zeal = Math.clamp(zeal + 1, 0, 100)
            else
                -- Moderates recoil
                gs.religion.diversity = Math.clamp((gs.religion.diversity or 10) + 1, 0, 100)
            end
        end
    end)

    --------------------------------------------------------------------------
    -- CONQUEST → CULTURE, STRIFE, RELIGION
    --------------------------------------------------------------------------

    -- Monthly: occupied territories bleed into the conqueror's culture
    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.empire or not gs.empire.territories then return end

        for _, territory in ipairs(gs.empire.territories) do
            -- Conquered regions push culture toward collectivism (empire-building)
            if RNG.chance(0.05) then
                local culture = engine:get_module("culture")
                if culture then culture:shift("CUL_COL", 0.5) end
            end

            -- High resistance generates strife
            if (territory.resistance or 0) > 40 and gs.strife then
                gs.strife.global_tension = Math.clamp(
                    (gs.strife.global_tension or 0) + 0.5, 0, 100)
            end
        end
    end)
end

return Bridge
