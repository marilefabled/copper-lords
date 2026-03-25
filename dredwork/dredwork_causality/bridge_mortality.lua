-- The Ripple — Mortality Bridge
-- Heir death and succession cascade through every system.
-- This is the most impactful single event in the simulation.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    --------------------------------------------------------------------------
    -- HEIR DEATH → EVERYTHING
    --------------------------------------------------------------------------

    engine:on("HEIR_DIED", function(ctx)
        if not ctx then return end
        local gs = engine.game_state

        -- POLITICS: legitimacy crisis
        if gs.politics then
            gs.politics.legitimacy = Math.clamp((gs.politics.legitimacy or 50) - 20, 0, 100)
            gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) + 15, 0, 100)
        end

        -- RIVALS: all rivals recalculate — death is opportunity
        if gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                -- Hostile rivals see weakness
                if house.heir and house.heir.attitude == "hostile" then
                    house.disposition = Math.clamp(house.disposition - 10, -100, 100)
                    house.resources.steel = (house.resources.steel or 0) + 20
                end
                -- Wary rivals become bolder
                if house.heir and house.heir.attitude == "wary" then
                    house.disposition = Math.clamp(house.disposition - 5, -100, 100)
                end
                -- Devoted rivals mourn
                if house.heir and house.heir.attitude == "devoted" then
                    house.disposition = Math.clamp(house.disposition + 5, -100, 100)
                end
            end
        end

        -- COURT: loyalty crisis — everyone's loyalty drops, some see opportunity
        if gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" then
                    local drop = RNG.range(5, 15)
                    member.loyalty = Math.clamp(member.loyalty - drop, 0, 100)
                end
            end
        end

        -- MILITARY: morale shock
        if gs.military then
            for _, unit in ipairs(gs.military.units or {}) do
                unit.morale = Math.clamp((unit.morale or 50) - 15, 0, 100)
            end
        end

        -- CRIME: power vacuum = corruption surge
        if gs.underworld then
            gs.underworld.global_corruption = Math.clamp(
                (gs.underworld.global_corruption or 0) + 10, 0, 100)
        end

        -- ECONOMY: markets panic
        if gs.markets then
            for _, market in pairs(gs.markets) do
                if market.prices then
                    for good, price in pairs(market.prices) do
                        market.prices[good] = price * 1.2 -- panic inflation
                    end
                end
            end
        end

        -- RELIGION: death can strengthen faith or weaken it
        if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
            local zeal = gs.religion.active_faith.attributes.zeal or 50
            if zeal > 60 then
                -- High zeal: "the gods have spoken" — zeal rises further
                gs.religion.active_faith.attributes.zeal = Math.clamp(zeal + 5, 0, 100)
            else
                -- Low zeal: crisis of faith
                gs.religion.active_faith.attributes.zeal = Math.clamp(zeal - 5, 0, 100)
                gs.religion.diversity = Math.clamp((gs.religion.diversity or 10) + 5, 0, 100)
            end
        end

        -- CULTURE: death pushes toward tradition (conservatism in crisis)
        local culture = engine:get_module("culture")
        if culture then
            culture:shift("CUL_TRD", 3)
            -- Assassination deaths push toward honor culture
            if ctx.cause == "assassination" then
                culture:shift("CUL_HON", 5)
            end
            -- Battle deaths push toward martial culture
            if ctx.cause == "battle" then
                culture:shift("CUL_MAR", 5)
            end
        end

        -- STRIFE: succession uncertainty creates tension everywhere
        if gs.strife then
            gs.strife.global_tension = Math.clamp(
                (gs.strife.global_tension or 0) + 15, 0, 100)
        end

        -- HOME: grief reduces comfort
        if gs.home and gs.home.attributes then
            gs.home.attributes.comfort = Math.clamp(
                (gs.home.attributes.comfort or 50) - 10, 0, 100)
        end

        -- RUMOR: death generates massive rumor wave
        local rumor = engine:get_module("rumor")
        if rumor then
            rumor:inject(gs, {
                origin_type = "mortality",
                subject = ctx.heir_name or "the ruler",
                text = (ctx.heir_name or "The ruler") .. " is dead. The realm holds its breath.",
                heat = 100,
                tags = { danger = true, fear = true },
            })
            -- Cause-specific rumors
            if ctx.cause == "assassination" then
                rumor:inject(gs, {
                    origin_type = "mortality",
                    subject = "the court",
                    text = "Murder most foul. The assassins' identity is unknown — or is it?",
                    heat = 90,
                    tags = { scandal = true, danger = true },
                })
            end
        end

        -- HERITAGE: dead heirs can become legends (if they earned it)
        -- (Handled by ledger closure → The Ripple's bridge_characters)

        -- CONQUEST: occupied territories see opportunity to rebel
        if gs.empire and gs.empire.territories then
            for _, territory in ipairs(gs.empire.territories) do
                territory.resistance = Math.clamp(
                    (territory.resistance or 0) + 20, 0, 100)
            end
        end

        -- PUNISHMENT: prisoners may attempt escape during chaos
        if gs.justice and gs.justice.prisoners then
            for i = #gs.justice.prisoners, 1, -1 do
                if RNG.chance(0.15) then
                    table.remove(gs.justice.prisoners, i)
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    -- SUCCESSION → WORLD RESET
    --------------------------------------------------------------------------

    engine:on("SUCCESSION_COMPLETE", function(ctx)
        if not ctx then return end
        local gs = engine.game_state

        -- New heir announcement rumor
        local rumor = engine:get_module("rumor")
        if rumor then
            rumor:inject(gs, {
                origin_type = "succession",
                subject = ctx.heir_name or "the new ruler",
                text = (ctx.heir_name or "A new ruler") .. " ascends. The realm watches and waits.",
                heat = 80,
                tags = { prestige = true },
            })
        end

        -- Rivals reassess the new heir
        if gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.alive then
                    -- Disposition drifts back toward neutral (fresh start)
                    house.disposition = Math.clamp(
                        house.disposition + (0 - house.disposition) * 0.3, -100, 100)
                end
            end
        end

        -- Court loyalty partially recovers (hope for new leadership)
        if gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" then
                    member.loyalty = Math.clamp(member.loyalty + RNG.range(3, 10), 0, 100)
                end
            end
        end

        -- Unrest settles slightly (new ruler = new chance)
        if gs.politics then
            gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) - 10, 0, 100)
        end

        -- If heir is young (< 18), regency affects everything
        if (ctx.heir_age or 20) < 18 then
            -- Regency: court members gain power, rivals grow bolder
            if gs.court then
                for _, member in ipairs(gs.court.members or {}) do
                    if member.status == "active" then
                        member.competence = Math.clamp(member.competence + 5, 0, 100)
                        -- But also more ambitious
                        member.loyalty = Math.clamp(member.loyalty - 5, 0, 100)
                    end
                end
            end
        end

        -- Strife cools slightly
        if gs.strife then
            gs.strife.global_tension = Math.clamp(
                (gs.strife.global_tension or 0) - 5, 0, 100)
        end
    end)

    --------------------------------------------------------------------------
    -- SUCCESSION CRISIS → ESCALATION
    --------------------------------------------------------------------------

    engine:on("SUCCESSION_CRISIS", function(ctx)
        local gs = engine.game_state

        -- All rivals see maximum opportunity
        if gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                house.disposition = Math.clamp(house.disposition - 15, -100, 100)
                house.resources.steel = (house.resources.steel or 0) + 30
            end
        end

        -- Unrest spikes
        if gs.politics then
            gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) + 30, 0, 100)
            gs.politics.legitimacy = Math.clamp((gs.politics.legitimacy or 50) - 30, 0, 100)
        end

        -- Crime thrives
        if gs.underworld then
            gs.underworld.global_corruption = Math.clamp(
                (gs.underworld.global_corruption or 0) + 20, 0, 100)
        end
    end)

    --------------------------------------------------------------------------
    -- CHILD BORN → WORLD
    --------------------------------------------------------------------------

    engine:on("CHILD_BORN", function(ctx)
        local gs = engine.game_state

        -- Birth improves legitimacy (the line continues)
        engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = 3 })

        -- Court celebrates
        if gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" then
                    member.loyalty = Math.clamp(member.loyalty + 2, 0, 100)
                end
            end
        end

        -- Home comfort boost (new life)
        if gs.home and gs.home.attributes then
            gs.home.attributes.comfort = Math.clamp(
                (gs.home.attributes.comfort or 50) + 3, 0, 100)
        end

        -- Devoted rivals send gifts
        if gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude == "devoted" and RNG.chance(0.5) then
                    local econ = engine:get_module("economy")
                    if econ then econ:change_wealth(RNG.range(10, 25)) end
                end
            end
        end

        -- Inject celebration rumor
        local rumor = engine:get_module("rumor")
        if rumor and ctx then
            rumor:inject(gs, {
                origin_type = "birth",
                subject = ctx.parent_name or "the house",
                text = ctx.text or "An heir is born.",
                heat = 45,
                tags = { praise = true, prestige = true },
            })
        end
    end)

    --------------------------------------------------------------------------
    -- CHILD DEATH → WORLD
    --------------------------------------------------------------------------

    engine:on("CHILD_DIED", function(ctx)
        local gs = engine.game_state

        -- Grief
        if gs.home and gs.home.attributes then
            gs.home.attributes.comfort = Math.clamp(
                (gs.home.attributes.comfort or 50) - 8, 0, 100)
        end

        -- Court mourns
        if gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" then
                    member.loyalty = Math.clamp(member.loyalty + 1, 0, 100)
                end
            end
        end

        -- Religious response
        if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
            local zeal = gs.religion.active_faith.attributes.zeal or 50
            if zeal > 50 then
                gs.religion.active_faith.attributes.zeal = Math.clamp(zeal + 3, 0, 100)
            end
        end

        -- Inject mourning rumor
        local rumor = engine:get_module("rumor")
        if rumor and ctx then
            rumor:inject(gs, {
                origin_type = "mortality",
                subject = ctx.child and ctx.child.name or "a child",
                text = ctx.text or "A child of the house has died.",
                heat = 40,
                tags = { fear = true },
            })
        end
    end)
end

return Bridge
