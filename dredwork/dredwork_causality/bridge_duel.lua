-- The Ripple — Duel Bridge
-- Duel outcomes cascade through court, rivals, politics, heritage, rumor, narrative.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    engine:on("DUEL_RESOLVED", function(ctx)
        if not ctx then return end
        local gs = engine.game_state

        -- POLITICS: Duels affect legitimacy
        if ctx.winner == "a" then
            -- Player/heir won
            engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = 5 })
            -- Culture shifts martial
            local culture = engine:get_module("culture")
            if culture then culture:shift("CUL_MAR", 2); culture:shift("CUL_HON", 2) end
        elseif ctx.winner == "b" then
            -- Player/heir lost
            engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = -5 })
        end

        -- COURT: Duel outcomes affect court morale
        if gs.court then
            for _, member in ipairs(gs.court.members or {}) do
                if member.status == "active" then
                    if ctx.winner == "a" then
                        member.loyalty = Math.clamp(member.loyalty + 2, 0, 100)
                    else
                        member.loyalty = Math.clamp(member.loyalty - 2, 0, 100)
                    end
                end
            end
        end

        -- MILITARY: Victories inspire troops
        if ctx.winner == "a" and gs.military then
            for _, unit in ipairs(gs.military.units or {}) do
                unit.morale = Math.clamp((unit.morale or 50) + 3, 0, 100)
            end
        end

        -- RIVALS: Duels shift rival perception
        if gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if ctx.winner == "a" then
                    -- Player victory intimidates
                    if house.heir and house.heir.attitude == "wary" then
                        house.disposition = Math.clamp(house.disposition + 3, -100, 100)
                    end
                    if house.heir and house.heir.attitude == "hostile" then
                        house.disposition = Math.clamp(house.disposition + 1, -100, 100)
                    end
                elseif ctx.winner == "b" then
                    -- Player defeat emboldens
                    if house.heir and house.heir.attitude == "hostile" then
                        house.disposition = Math.clamp(house.disposition - 5, -100, 100)
                        house.resources.steel = (house.resources.steel or 0) + 10
                    end
                end
            end
        end

        -- HERITAGE: Decisive victories become legends
        if ctx.winner ~= "draw" and ctx.rounds and ctx.rounds <= 3 then
            local heritage = engine:get_module("heritage")
            if heritage then
                heritage:record_legend(
                    { name = ctx.winner_name or "a champion", id = "duel_" .. (gs.clock and gs.clock.total_days or 0) },
                    "defeated " .. (ctx.loser_name or "a foe") .. " in single combat",
                    RNG.range(30, 60)
                )
            end
        end

        -- RUMOR: Duel outcomes generate rumors
        local rumor = engine:get_module("rumor")
        if rumor then
            local tags = ctx.winner == "a" and { praise = true, prestige = true } or { shame = true, danger = true }
            rumor:inject(gs, {
                origin_type = "duel",
                subject = ctx.winner_name or "a combatant",
                text = ctx.text or "A duel has been resolved.",
                heat = 65,
                tags = tags,
            })
        end

        -- STRIFE: Public duels reduce tension (controlled violence channels aggression)
        if gs.strife then
            gs.strife.global_tension = Math.clamp((gs.strife.global_tension or 0) - 3, 0, 100)
        end
    end)

    engine:on("DUEL_STARTED", function(ctx)
        -- Inject anticipation rumor
        local rumor = engine:get_module("rumor")
        if rumor and ctx then
            rumor:inject(engine.game_state, {
                origin_type = "duel",
                subject = ctx.a_name or "a combatant",
                text = ctx.text or "A duel has been announced.",
                heat = 50,
                tags = { prestige = true },
            })
        end
    end)
end

return Bridge
