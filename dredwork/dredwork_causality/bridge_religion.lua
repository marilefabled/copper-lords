-- The Ripple — Religion Bridge
-- Religion ↔ crime, punishment, marriage, court, conquest, home, strife, technology, animals.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    -- Monthly: religion affects many systems at a slow drip
    engine:on("NEW_MONTH", function(clock)
        local gs = engine.game_state
        if not gs.religion or not gs.religion.active_faith then return end
        local faith = gs.religion.active_faith
        local attrs = faith.attributes or {}
        local zeal = attrs.zeal or 50
        local tolerance = attrs.tolerance or 50

        -- RELIGION → CRIME: Low tolerance drives underground worship → corruption
        if tolerance < 30 and gs.underworld then
            gs.underworld.global_corruption = Math.clamp(
                (gs.underworld.global_corruption or 0) + 0.3, 0, 100)
        end

        -- RELIGION → PUNISHMENT: High zeal demands harsher justice
        if zeal > 70 and gs.justice then
            gs.justice.terror_score = Math.clamp(
                (gs.justice.terror_score or 0) + 0.2, 0, 100)
        end

        -- RELIGION → HOME: Religious observance affects household rhythm
        if zeal > 60 and gs.home and gs.home.attributes then
            -- High zeal creates sense of purpose → comfort
            gs.home.attributes.comfort = Math.clamp(
                (gs.home.attributes.comfort or 50) + 0.3, 0, 100)
        end

        -- RELIGION → COURT: Zealous priests in court push religious agenda
        if gs.court and zeal > 65 then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" and member.role == "priest" then
                    -- Priest loyalty tied to how much the ruler respects faith
                    -- (Low tolerance from ruler = priest loyalty drops)
                    if tolerance > 60 then
                        member.loyalty = Math.clamp(member.loyalty + 0.5, 0, 100)
                    else
                        member.loyalty = Math.clamp(member.loyalty - 0.5, 0, 100)
                    end
                end
            end
        end

        -- RELIGION → STRIFE: Religious diversity + low tolerance = sectarian tension
        local diversity = gs.religion.diversity or 10
        if diversity > 40 and tolerance < 40 then
            if gs.strife then
                gs.strife.global_tension = Math.clamp(
                    (gs.strife.global_tension or 0) + 1, 0, 100)
            end
        end

        -- RELIGION → TECHNOLOGY: Extreme zeal suppresses research
        if zeal > 80 then
            local tech = engine:get_module("technology")
            if tech and gs.technology and gs.technology.fields then
                for _, field in pairs(gs.technology.fields) do
                    -- Very slow suppression — cumulative over months
                    if field.progress then
                        field.progress = math.max(0, (field.progress or 0) - 0.1)
                    end
                end
            end
        end
    end)

    -- RELIGION → CONQUEST: Conquering a region with a different dominant faith
    -- creates religious tension in the conquered territory
    engine:on("NEW_YEAR", function(clock)
        local gs = engine.game_state
        if not gs.empire or not gs.empire.territories then return end
        if not gs.religion then return end

        for _, territory in ipairs(gs.empire.territories) do
            -- Occupied regions build resentment influenced by religious difference
            if territory.resistance and gs.religion.diversity > 30 then
                territory.resistance = Math.clamp(
                    territory.resistance + 1, 0, 100)
            end
        end
    end)

    -- RELIGION → ANIMALS: Faith shift affects sacred animal treatment
    -- (Handled in animals module already, but add reverse: animal crisis affects faith)
    -- If sacred animals are thriving beyond control, it's a sign — or a plague
    engine:on("ADVANCE_GENERATION", function(context)
        local gs = engine.game_state
        if not gs.religion or not gs.religion.active_faith then return end
        if not gs.animals or not gs.animals.regional_populations then return end

        local sacred = gs.religion.active_faith.sacred_species
        if not sacred then return end

        local total_sacred = 0
        for _, pops in pairs(gs.animals.regional_populations) do
            if pops[sacred] then
                total_sacred = total_sacred + (pops[sacred].density or 0)
            end
        end

        -- Sacred animals completely gone = faith crisis
        if total_sacred == 0 then
            if gs.religion.active_faith.attributes then
                gs.religion.active_faith.attributes.zeal = Math.clamp(
                    (gs.religion.active_faith.attributes.zeal or 50) - 10, 0, 100)
            end
            gs.religion.diversity = Math.clamp((gs.religion.diversity or 10) + 10, 0, 100)

            local rumor = engine:get_module("rumor")
            if rumor then
                rumor:inject(gs, {
                    origin_type = "religion",
                    subject = "the faithful",
                    text = "The sacred " .. sacred .. " have vanished. The priests see this as an omen.",
                    heat = 65, tags = { fear = true },
                })
            end
        end
    end)
end

return Bridge
