-- dredwork Narrative — Tomorrow Teasers
-- The last thing you see before dawn. A hint of what's coming.
-- Generated from simulation state — things the player hasn't seen yet.
-- "You dream of a door you've never opened."

local RNG = require("dredwork_core.rng")

local Tomorrow = {}

--- Generate a teaser for what tomorrow might bring.
---@param entity table focal entity
---@param gs table game_state
---@return string teaser text
function Tomorrow.generate(entity, gs)
    local pool = {}

    -- CLAIM-BASED teasers
    if gs.claim and gs.claim.type then
        if gs.claim.suspicion > 50 then
            table.insert(pool, { weight = 3, text = "Somewhere, someone writes your name on a list." })
            table.insert(pool, { weight = 3, text = "You dream of footsteps. Following." })
        end
        if gs.claim.suspicion > 70 then
            table.insert(pool, { weight = 4, text = "In the ruling house, a door closes. Your name was spoken behind it." })
        end
        if gs.claim.status == "whispered" then
            table.insert(pool, { weight = 3, text = "The whispers are growing louder. You can almost hear them." })
        end
        if gs.claim.status == "hidden" then
            table.insert(pool, { weight = 2, text = "Your secret sleeps beside you. It will wake when you do." })
        end
    end

    -- RIVAL-BASED teasers
    if gs.rivals and gs.rivals.houses then
        for _, house in ipairs(gs.rivals.houses) do
            if house.heir and house.heir.attitude == "hostile" and house.resources.steel > 20 then
                table.insert(pool, { weight = 3, text = "Beyond the walls, " .. house.name .. " sharpens something." })
                break
            end
        end
    end

    -- COURT-BASED teasers
    if gs.court and gs.court.members then
        for _, member in ipairs(gs.court.members) do
            if member.status == "active" and member.loyalty < 30 then
                table.insert(pool, { weight = 2, text = "Someone in the court lies awake tonight. Planning." })
                break
            end
        end
    end

    -- PERIL-BASED teasers
    if gs.perils and gs.perils.active and #gs.perils.active > 0 then
        table.insert(pool, { weight = 3, text = "The sickness doesn't sleep. It grows in the dark." })
    end

    -- ECONOMY teasers
    if gs.markets then
        for _, market in pairs(gs.markets) do
            if market.prices and market.prices.food and market.prices.food > 15 then
                table.insert(pool, { weight = 2, text = "Tomorrow, the bread will cost more. It always does." })
                break
            end
        end
    end

    -- MOOD-BASED teasers (from the entity's emotional state)
    local mood = entity and entity.components.mood
    if mood == "desperate" then
        table.insert(pool, { weight = 2, text = "Tomorrow might be better. You don't believe that, but you think it." })
    elseif mood == "determined" then
        table.insert(pool, { weight = 2, text = "Tomorrow, you move. The plan is ready." })
    elseif mood == "hopeful" then
        table.insert(pool, { weight = 2, text = "Something good is coming. You can feel it. Almost." })
    end

    -- GENERIC / ATMOSPHERIC teasers (always available as fallback)
    table.insert(pool, { weight = 1, text = "You dream of a door you've never opened." })
    table.insert(pool, { weight = 1, text = "Tomorrow. Whatever it brings, you'll face it." })
    table.insert(pool, { weight = 1, text = "The world turns. You turn with it." })
    table.insert(pool, { weight = 1, text = "Dawn will come. It always does. The question is what it brings with it." })
    table.insert(pool, { weight = 1, text = "Sleep takes you. For a few hours, you belong to no one." })
    table.insert(pool, { weight = 1, text = "In the space between today and tomorrow, anything is possible." })

    -- Weighted pick
    return RNG.weighted_pick(pool, function(item) return item.weight end).text
end

return Tomorrow
