-- The Ripple — Character Bridge
-- Court, rivals, marriage, decisions, biography, ledger → world systems.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Bridge = {}

function Bridge.wire(engine)

    --------------------------------------------------------------------------
    -- COURT → WORLD
    --------------------------------------------------------------------------

    engine:on("COURT_BETRAYAL", function(ctx)
        local gs = engine.game_state
        -- Rivals smell weakness
        if gs.rivals then
            for _, house in ipairs(gs.rivals.houses or {}) do
                if house.heir and house.heir.attitude == "hostile" then
                    house.resources.steel = (house.resources.steel or 0) + 10
                end
            end
        end
        -- Unrest rises
        if gs.politics then
            gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) + 5, 0, 100)
        end
        -- Crime sees opportunity
        if gs.underworld then
            gs.underworld.global_corruption = Math.clamp((gs.underworld.global_corruption or 0) + 3, 0, 100)
        end
        -- Culture: betrayal pushes toward distrust (tradition)
        local culture = engine:get_module("culture")
        if culture then culture:shift("CUL_TRD", 1) end
    end)

    engine:on("COURT_DEATH", function(ctx)
        local member = ctx and ctx.member
        if not member then return end
        local gs = engine.game_state

        if member.role == "general" then
            if gs.military then
                for _, unit in ipairs(gs.military.units or {}) do
                    unit.morale = Math.clamp((unit.morale or 50) - 10, 0, 100)
                end
            end
        end
        if member.role == "priest" then
            if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
                gs.religion.active_faith.attributes.zeal = Math.clamp(
                    (gs.religion.active_faith.attributes.zeal or 50) - 5, 0, 100)
            end
        end
        -- Competent members become minor legends
        if member.competence and member.competence > 70 then
            local heritage = engine:get_module("heritage")
            if heritage then
                heritage:record_legend(
                    { name = member.name, id = member.id },
                    "served the house with distinction",
                    Math.clamp(member.competence - 30, 10, 50)
                )
            end
        end
        -- Death of any court member affects home atmosphere
        if gs.home and gs.home.attributes then
            gs.home.attributes.comfort = Math.clamp((gs.home.attributes.comfort or 50) - 3, 0, 100)
        end
    end)

    engine:on("COURT_BOON", function(ctx)
        local gs = engine.game_state
        if gs.home and gs.home.attributes then
            gs.home.attributes.comfort = Math.clamp((gs.home.attributes.comfort or 50) + 3, 0, 100)
        end
        if gs.strife then
            gs.strife.global_tension = Math.clamp((gs.strife.global_tension or 0) - 2, 0, 100)
        end
    end)

    --------------------------------------------------------------------------
    -- RIVALS → WORLD
    --------------------------------------------------------------------------

    engine:on("RIVAL_ACTION", function(ctx)
        if not ctx then return end
        local gs = engine.game_state

        if ctx.type == "rival_raid" then
            if gs.military then
                for _, unit in ipairs(gs.military.units or {}) do
                    unit.morale = Math.clamp((unit.morale or 50) + 5, 0, 100)
                end
            end
            if gs.home and gs.home.attributes then
                gs.home.attributes.condition = Math.clamp(
                    (gs.home.attributes.condition or 50) - RNG.range(5, 15), 0, 100)
            end
            if gs.strife then
                gs.strife.global_tension = Math.clamp((gs.strife.global_tension or 0) + 10, 0, 100)
            end
            local rumor = engine:get_module("rumor")
            if rumor then
                rumor:inject(gs, {
                    origin_type = "rival", subject = ctx.house or "a rival house",
                    text = "Raiders struck from " .. (ctx.house or "beyond the border") .. ". The people demand protection.",
                    heat = 75, tags = { danger = true, shame = true },
                })
            end
            -- Raid damages local animal populations (livestock killed)
            if gs.animals and gs.animals.regional_populations then
                local req_geo = { current_region_id = nil }
                engine:emit("GET_GEOGRAPHY_DATA", req_geo)
                local region = req_geo.current_region_id
                if region and gs.animals.regional_populations[region] then
                    for species, pop in pairs(gs.animals.regional_populations[region]) do
                        pop.density = Math.clamp((pop.density or 0) - 5, 0, 100)
                    end
                end
            end

        elseif ctx.type == "rival_gift" then
            local culture = engine:get_module("culture")
            if culture then culture:shift("CUL_COL", 1) end

        elseif ctx.type == "rival_demand" then
            if gs.politics then
                gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) + 3, 0, 100)
            end
        end
    end)

    engine:on("RIVAL_DEATH", function(ctx)
        local gs = engine.game_state
        if gs.underworld then
            gs.underworld.global_corruption = Math.clamp(
                (gs.underworld.global_corruption or 0) + RNG.range(2, 5), 0, 100)
        end
        local rumor = engine:get_module("rumor")
        if rumor and ctx then
            rumor:inject(gs, {
                origin_type = "rival", subject = ctx.house or "a rival house",
                text = (ctx.heir or "A rival leader") .. " has fallen. The balance of power shifts.",
                heat = 60, tags = { danger = true },
            })
        end
    end)

    engine:on("RIVAL_SUCCESSION", function(ctx)
        local culture = engine:get_module("culture")
        if culture and RNG.chance(0.3) then
            culture:shift("CUL_TRD", RNG.range(-2, 2))
        end
    end)

    -- Inter-rival conflict affects the player's world
    engine:on("RIVAL_CONFLICT", function(ctx)
        if not ctx then return end
        local gs = engine.game_state

        -- Nearby wars increase strife and unrest
        if gs.strife then
            gs.strife.global_tension = Math.clamp((gs.strife.global_tension or 0) + 5, 0, 100)
        end
        if gs.politics then
            gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) + 2, 0, 100)
        end
        -- Inject rumor
        local rumor = engine:get_module("rumor")
        if rumor then
            rumor:inject(gs, {
                origin_type = "rival", subject = ctx.aggressor or "?",
                text = ctx.text or "Two rival houses clash.",
                heat = 60, tags = { danger = true },
            })
        end
        -- Culture shifts martial from witnessing conflict
        local culture = engine:get_module("culture")
        if culture then culture:shift("CUL_MAR", 1) end
    end)

    -- Fallen house: major power shift
    engine:on("RIVAL_FALLEN", function(ctx)
        if not ctx then return end
        local gs = engine.game_state

        -- Power vacuum
        if gs.underworld then
            gs.underworld.global_corruption = Math.clamp((gs.underworld.global_corruption or 0) + 8, 0, 100)
        end
        -- Culture: witnessing a house fall reinforces tradition and hierarchy
        local culture = engine:get_module("culture")
        if culture then
            culture:shift("CUL_TRD", 2)
            culture:shift("CUL_HIE", 2)
        end
        -- Heritage: major event becomes a legend
        local heritage = engine:get_module("heritage")
        if heritage then
            heritage:record_legend(
                { name = ctx.conqueror or "a conqueror", id = "conqueror_" .. (gs.clock and gs.clock.total_days or 0) },
                "destroyed " .. (ctx.house or "a rival house"),
                RNG.range(50, 80))
        end
        -- Rumor wave
        local rumor = engine:get_module("rumor")
        if rumor then
            rumor:inject(gs, {
                origin_type = "rival", subject = ctx.house or "a fallen house",
                text = ctx.text or "A great house has fallen.",
                heat = 85, tags = { danger = true, fear = true },
            })
        end
    end)

    --------------------------------------------------------------------------
    -- MARRIAGE → WORLD
    --------------------------------------------------------------------------

    engine:on("MARRIAGE_PERFORMED", function(ctx)
        if not ctx then return end
        local gs = engine.game_state

        local rumor = engine:get_module("rumor")
        if rumor then
            rumor:inject(gs, {
                origin_type = "marriage", subject = ctx.heir_name or "the heir",
                text = "A marriage unites houses. Celebrations echo through the land.",
                heat = 50, tags = { praise = true, prestige = true },
            })
        end
        engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = 5 })

        if (ctx.compatibility or 0) > 70 and gs.home and gs.home.attributes then
            gs.home.attributes.comfort = Math.clamp((gs.home.attributes.comfort or 50) + 5, 0, 100)
        end
        if ctx.marriage_type == "forced" and gs.politics then
            gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) + 8, 0, 100)
        end
        if ctx.marriage_type == "love" then
            local culture = engine:get_module("culture")
            if culture then culture:shift("CUL_TRD", -2) end
        end
        if ctx.marriage_type == "forbidden" then
            local culture = engine:get_module("culture")
            if culture then culture:shift("CUL_TRD", 5) end
            if gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes then
                gs.religion.active_faith.attributes.zeal = Math.clamp(
                    (gs.religion.active_faith.attributes.zeal or 50) + 5, 0, 100)
            end
        end

        -- Marriage affects bonds between houses (strife reduction if inter-regional)
        if gs.strife then
            gs.strife.global_tension = Math.clamp((gs.strife.global_tension or 0) - 3, 0, 100)
        end
    end)

    --------------------------------------------------------------------------
    -- DECISIONS → WORLD
    --------------------------------------------------------------------------

    engine:on("DECISION_RESOLVED", function(ctx)
        if not ctx then return end
        local gs = engine.game_state

        if ctx.resisted then
            if gs.court then
                for _, member in ipairs(gs.court.members or {}) do
                    if member.status == "active" then
                        if member.loyalty > 60 then
                            member.loyalty = Math.clamp(member.loyalty + 1, 0, 100)
                        else
                            member.loyalty = Math.clamp(member.loyalty - 1, 0, 100)
                        end
                    end
                end
            end
        end

        local option = ctx.option
        if option and option.tags then
            for _, tag in ipairs(option.tags) do
                if tag == "warfare" and gs.military then
                    for _, unit in ipairs(gs.military.units or {}) do
                        unit.morale = Math.clamp((unit.morale or 50) + 5, 0, 100)
                    end
                end
                if tag == "retreat" and gs.military then
                    for _, unit in ipairs(gs.military.units or {}) do
                        unit.morale = Math.clamp((unit.morale or 50) - 8, 0, 100)
                    end
                end
                if tag == "cruel_act" and gs.justice then
                    gs.justice.terror_score = Math.clamp((gs.justice.terror_score or 0) + 3, 0, 100)
                end
                if tag == "merciful_act" then
                    if gs.justice then
                        gs.justice.terror_score = Math.clamp((gs.justice.terror_score or 0) - 5, 0, 100)
                    end
                    if gs.underworld then
                        gs.underworld.global_corruption = Math.clamp(
                            (gs.underworld.global_corruption or 0) + 2, 0, 100)
                    end
                end
                if tag == "espionage" then
                    local rumor = engine:get_module("rumor")
                    if rumor then
                        rumor:inject(gs, {
                            origin_type = "decision", subject = gs.lineage_name or "the ruler",
                            text = "Whispers suggest covert operations are underway.",
                            heat = 40, tags = { scandal = true },
                        })
                    end
                end
            end
        end
    end)

    --------------------------------------------------------------------------
    -- BIOGRAPHY → WORLD
    --------------------------------------------------------------------------

    engine:on("WILD_ATTRIBUTE_DETECTED", function(ctx)
        if not ctx or not ctx.attributes then return end
        local gs = engine.game_state

        for _, wa in ipairs(ctx.attributes) do
            if wa.category == "physical" and gs.rivals then
                for _, house in ipairs(gs.rivals.houses or {}) do
                    if house.heir and house.heir.attitude == "wary" then
                        house.disposition = Math.clamp(house.disposition + 3, -100, 100)
                    end
                end
            end
            if wa.category == "social" and gs.court then
                for _, member in ipairs(gs.court.members or {}) do
                    if member.status == "active" then
                        member.loyalty = Math.clamp(member.loyalty + 3, 0, 100)
                    end
                end
            end
            if wa.category == "mental" then
                local tech = engine:get_module("technology")
                if tech then
                    for _, f in ipairs({"warfare","industry","infrastructure","medicine","agriculture"}) do
                        tech:boost_field(f, 2)
                    end
                end
            end
            if wa.category == "creative" then
                local heritage = engine:get_module("heritage")
                if heritage and ctx.heir_name then
                    heritage:record_legend(
                        { name = ctx.heir_name, id = "wild_" .. wa.id },
                        "was recognized as a " .. wa.label, wa.bonus * 2)
                end
            end
        end

        local rumor = engine:get_module("rumor")
        if rumor and #ctx.attributes > 0 then
            local wa = ctx.attributes[1]
            rumor:inject(gs, {
                origin_type = "biography", subject = ctx.heir_name or "the heir",
                text = (ctx.heir_name or "The heir") .. " is spoken of as a " .. wa.label .. ".",
                heat = 55, tags = { praise = true, prestige = true },
            })
        end
    end)

    --------------------------------------------------------------------------
    -- LEDGER → WORLD
    --------------------------------------------------------------------------

    engine:on("LEDGER_CLOSED", function(ctx)
        if not ctx then return end
        local gs = engine.game_state

        if ctx.tier == "Legendary" or ctx.tier == "Exalted" then
            local heritage = engine:get_module("heritage")
            if heritage then
                heritage:record_legend(
                    { name = ctx.heir_name or "the predecessor", id = "ledger_" .. (gs.clock and gs.clock.generation or 0) },
                    "ruled with " .. (ctx.tier == "Legendary" and "legendary" or "exalted") .. " impact",
                    ctx.tier == "Legendary" and 90 or 70)
            end
            engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = ctx.tier == "Legendary" and 15 or 8 })
        end

        if ctx.tier == "Wretched" or ctx.tier == "Accursed" then
            if gs.rivals then
                for _, house in ipairs(gs.rivals.houses or {}) do
                    house.disposition = Math.clamp(house.disposition - 10, -100, 100)
                end
            end
            engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = ctx.tier == "Accursed" and -20 or -10 })
            if gs.court then
                for _, member in ipairs(gs.court.members or {}) do
                    if member.status == "active" then
                        member.loyalty = Math.clamp(member.loyalty - 10, 0, 100)
                    end
                end
            end
        end
    end)
end

return Bridge
