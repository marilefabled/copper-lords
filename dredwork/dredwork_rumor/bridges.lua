-- dredwork_rumor/bridges.lua
-- Adapter functions that convert events from other dredwork modules
-- into rumor specs. Each bridge is optional — only wire what you use.

local Rumor = require("dredwork_rumor.rumor")
local Network = require("dredwork_rumor.network")

local Bridges = {}

--[[
    Combat → Rumor
    After a fight resolves, inject the outcome as a rumor.
    combat_result: from dredwork_combat.Combat.resolve()
    context: { generation, location }
]]
function Bridges.from_combat(game_state, combat_result, context)
    if not game_state or not combat_result or not combat_result.result then return nil end
    local r = combat_result.result
    context = context or {}

    local subject = r.winner or r.loser or "someone"
    local text, tags, severity

    if r.margin == "draw" then
        text = subject .. " fought to a standstill. Neither could finish it."
        tags = { "violence" }
        severity = 2
    elseif r.margin == "dominant" then
        text = r.winner .. " destroyed " .. r.loser .. ". It wasn't close."
        tags = { "violence", "skill" }
        severity = 4
    else
        text = r.winner .. " beat " .. r.loser .. ". It could have gone either way."
        tags = { "violence" }
        severity = 3
    end

    return Network.inject(game_state, {
        origin_type = "combat",
        origin_id = (r.winner or "unknown") .. "_vs_" .. (r.loser or "unknown"),
        generation = context.generation or (game_state.generation or 1),
        subject = subject,
        text = text,
        tags = tags,
        severity = severity,
        heat = r.margin == "dominant" and 75 or 55,
    })
end

--[[
    Bond Secret → Rumor
    When a bond acts in secret, the action can leak.
    secret_event: from dredwork_bonds.secrets.generate()
]]
function Bridges.from_secret(game_state, secret_event, context)
    if not game_state or not secret_event then return nil end
    context = context or {}

    local hostile = secret_event.hostile
    local text = secret_event.bond_name .. (hostile
        and " moved against the protagonist in private."
        or " did something quiet that the protagonist didn't ask for.")

    return Network.inject(game_state, {
        origin_type = "secret",
        origin_id = secret_event.id or "unknown_secret",
        generation = context.generation or (game_state.generation or 1),
        subject = game_state.heir_name or "the protagonist",
        text = text,
        tags = hostile and { "betrayal" } or { "loyalty" },
        severity = hostile and 3 or 2,
        heat = hostile and 50 or 30,
    })
end

--[[
    Bond Collusion → Rumor
    When two bonds conspire, the conspiracy itself becomes a rumor.
    collusion_event: from dredwork_bonds.collusion.generate()
]]
function Bridges.from_collusion(game_state, collusion_event, context)
    if not game_state or not collusion_event then return nil end
    context = context or {}

    local names = collusion_event.bond_names or { "someone", "someone else" }
    local text = names[1] .. " and " .. names[2] .. " have been seen speaking about " .. (game_state.heir_name or "the protagonist") .. " in terms that sound rehearsed."

    return Network.inject(game_state, {
        origin_type = "collusion",
        origin_id = collusion_event.id or "unknown_collusion",
        generation = context.generation or (game_state.generation or 1),
        subject = game_state.heir_name or "the protagonist",
        text = text,
        tags = { "conspiracy" },
        severity = 3,
        heat = 60,
    })
end

--[[
    Claim Event → Rumor
    Claim hunter arrivals generate rumors about the bloodline.
    claim_event: from dredwork_bonds.claim_hunter.generate()
]]
function Bridges.from_claim(game_state, claim_event, context)
    if not game_state or not claim_event then return nil end
    context = context or {}

    local text = "Someone has been asking about " .. (game_state.heir_name or "the protagonist") .. "'s bloodline. The questions did not sound idle."

    return Network.inject(game_state, {
        origin_type = "claim",
        origin_id = claim_event.id or "unknown_claim",
        generation = context.generation or (game_state.generation or 1),
        subject = game_state.heir_name or "the protagonist",
        text = text,
        tags = { "bloodline", "danger" },
        severity = 3,
        heat = 55,
    })
end

--[[
    Year Action → Rumor
    Major year outcomes (triumphs, disasters) can become rumors.
    action_result: from dredwork_bonds.year.resolve()
]]
function Bridges.from_year_result(game_state, action_result, context)
    if not game_state or not action_result then return nil end
    context = context or {}

    local quality = action_result.stat_check_quality
    if quality ~= "triumph" and quality ~= "disaster" then
        return nil -- only notable outcomes generate rumors
    end

    local subject = game_state.heir_name or "the protagonist"
    local text, tags, severity, heat

    if quality == "triumph" then
        text = subject .. " succeeded publicly and impressively at " .. string.lower(action_result.title or "something") .. "."
        tags = { "skill", "courage" }
        severity = 3
        heat = 50
    else
        text = subject .. " failed badly at " .. string.lower(action_result.title or "something") .. ". People noticed."
        tags = { "shame" }
        severity = 3
        heat = 60
    end

    return Network.inject(game_state, {
        origin_type = "year",
        origin_id = action_result.title or "year_action",
        generation = context.generation or (game_state.generation or 1),
        subject = subject,
        text = text,
        tags = tags,
        severity = severity,
        heat = heat,
    })
end

--[[
    Morality Act → Rumor
    Extreme moral acts generate rumors.
    act: string (e.g. "cruelty", "sacrifice", "exploitation")
]]
function Bridges.from_morality(game_state, act, context)
    if not game_state or not act then return nil end
    context = context or {}

    local ACT_SPECS = {
        cruelty = { text = "%s did something cruel and efficient.", tags = { "cruelty" }, severity = 3, heat = 55 },
        sacrifice = { text = "%s gave up something real for someone who may not have deserved it.", tags = { "honor", "generosity" }, severity = 3, heat = 45 },
        exploitation = { text = "%s profited from someone else's hunger.", tags = { "shame", "cruelty" }, severity = 3, heat = 50 },
        honoring_oath = { text = "%s kept a promise at visible cost.", tags = { "honor" }, severity = 2, heat = 40 },
    }

    local spec = ACT_SPECS[act]
    if not spec then return nil end

    local subject = game_state.heir_name or "the protagonist"
    return Network.inject(game_state, {
        origin_type = "morality",
        origin_id = act,
        generation = context.generation or (game_state.generation or 1),
        subject = subject,
        text = string.format(spec.text, subject),
        tags = spec.tags,
        severity = spec.severity,
        heat = spec.heat,
    })
end

return Bridges
