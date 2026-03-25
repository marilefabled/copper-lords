-- The Ripple — Sports Bridge
-- Sports ↔ religion, crime, strife, rivals, culture, military, heritage, court.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    engine:on("MATCH_COMPLETED", function(ctx)
        local gs = engine.game_state

        -- SPORTS → STRIFE: Matches reduce regional tension (bread and circuses)
        if gs.strife then
            gs.strife.global_tension = Math.clamp((gs.strife.global_tension or 0) - 3, 0, 100)
        end

        -- SPORTS → RELIGION: Religious festivals often coincide with games
        -- High zeal + match = increased fervor (the faithful see victory as divine favor)
        if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
            local zeal = gs.religion.active_faith.attributes.zeal or 50
            if zeal > 60 and RNG.chance(0.3) then
                gs.religion.active_faith.attributes.zeal = Math.clamp(zeal + 1, 0, 100)
                local rumor = engine:get_module("rumor")
                if rumor then
                    rumor:inject(gs, {
                        origin_type = "sports",
                        subject = "the faithful",
                        text = "The priests declare the victory a sign of divine favor.",
                        heat = 30, tags = { praise = true },
                    })
                end
            end
        end

        -- SPORTS → CRIME: Match fixing and gambling
        if gs.underworld and gs.underworld.global_corruption > 20 then
            if RNG.chance(0.15) then
                gs.underworld.total_shadow_wealth = (gs.underworld.total_shadow_wealth or 0) + RNG.range(10, 30)
                -- Gambling scandals can create rumors
                if RNG.chance(0.3) then
                    local rumor = engine:get_module("rumor")
                    if rumor then
                        rumor:inject(gs, {
                            origin_type = "crime",
                            subject = "the underworld",
                            text = "Whispers of match-fixing circulate through the gambling dens.",
                            heat = 45, tags = { scandal = true },
                        })
                    end
                end
            end
        end

        -- SPORTS → CULTURE: Victories shift cultural martial pride
        local culture = engine:get_module("culture")
        if culture then
            culture:shift("CUL_MAR", 1)  -- sporting culture is martial culture
        end
    end)

    engine:on("SPORTS_VICTORY", function(ctx)
        local gs = engine.game_state

        -- SPORTS → COURT: Victory celebrations boost court morale
        if gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" then
                    member.loyalty = Math.clamp(member.loyalty + 1, 0, 100)
                end
            end
        end

        -- SPORTS → RIVALS: Rival houses notice public celebrations
        if gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude == "respectful" then
                    house.disposition = Math.clamp(house.disposition + 1, -100, 100)
                end
                -- Hostile rivals resent the public joy
                if house.heir and house.heir.attitude == "hostile" then
                    house.disposition = Math.clamp(house.disposition - 1, -100, 100)
                end
            end
        end

        -- SPORTS → HERITAGE: Exceptional victories can become legends
        if RNG.chance(0.1) then
            local heritage = engine:get_module("heritage")
            if heritage then
                heritage:record_legend(
                    { name = "a champion", id = "sports_" .. (gs.clock and gs.clock.total_days or 0) },
                    "achieved a legendary athletic victory",
                    RNG.range(20, 40))
            end
        end

        -- SPORTS → MILITARY: Athletic culture produces better soldiers
        if gs.military and RNG.chance(0.2) then
            for _, unit in ipairs(gs.military.units or {}) do
                unit.morale = Math.clamp((unit.morale or 50) + 2, 0, 100)
            end
        end
    end)
end

return Bridge
