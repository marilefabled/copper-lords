-- dredwork Duel — Combat Resolver
-- Pure combat logic: simultaneous 5-step resolution with stances, posture, momentum.
-- Ported from 5 Steps Ahead. No UI, no AI — just resolution.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Resolver = {}

local function hasTrait(traits, name)
    for _, t in ipairs(traits or {}) do if t == name then return true end end
    return false
end

local function shallowcopy(t)
    local out = {}; for k, v in pairs(t) do out[k] = v end; return out
end

--- Create a new fighter state.
function Resolver.new_fighter(name, hp)
    return {
        name = name,
        maxHp = hp or 20,
        hp = hp or 20,
        posture = 0,
        postureMax = 8,
        stance = "Neutral",
        momentum = 0,
        flags = { offBalanceNext = false, brokenAdvantage = false, pendingAdvantage = false },
    }
end

local function clone_fighter(unit)
    return {
        name = unit.name, maxHp = unit.maxHp, hp = unit.hp,
        posture = unit.posture, postureMax = unit.postureMax,
        stance = unit.stance, momentum = unit.momentum,
        flags = {
            offBalanceNext = unit.flags.offBalanceNext,
            brokenAdvantage = unit.flags.brokenAdvantage,
            pendingAdvantage = unit.flags.pendingAdvantage,
        },
    }
end

local function damage_with_momentum(attacker, base)
    local dmg = base or 0
    if attacker.momentum > 0 then dmg = dmg + attacker.momentum end
    if attacker.flags.brokenAdvantage then dmg = dmg + 1 end
    return math.max(0, dmg)
end

local function apply_posture(unit, amount)
    unit.posture = Math.clamp((unit.posture or 0) + (amount or 0), 0, unit.postureMax)
    if unit.posture >= unit.postureMax then
        unit.posture = 0
        unit.flags.offBalanceNext = true
        unit.stance = "Pressured"
        return true
    end
    return false
end

local function strike_hits(striker, defenderMove, defenderEffects)
    if defenderMove.category == "Defense" then
        if defenderMove.tags and defenderMove.tags.parry then
            if striker.category == "Strike" and not (striker.tags and (striker.tags.low or striker.tags.heavy)) then
                defenderEffects.counter = true
                return false, "parried"
            end
        end
        if defenderMove.block and striker.height and defenderMove.block[striker.height] then
            return false, "blocked"
        end
        if defenderMove.id == "guard_low" and striker.id == "stomp" then
            return false, "blocked"
        end
    elseif defenderMove.category == "Evasion" then
        if defenderMove.tags and defenderMove.tags.duck and (striker.height == "high" or striker.height == "mid") then
            return false, "evaded"
        end
        if defenderMove.tags and defenderMove.tags.sidestep and striker.id ~= "stomp" and striker.id ~= "clinch_attempt" then
            return false, "evaded"
        end
        if defenderMove.tags and defenderMove.tags.retreat and striker.id ~= "advance" and striker.id ~= "clinch_attempt" then
            return false, "evaded"
        end
    end
    return true, "hit"
end

local function strike_profile(unit, moveDef, wasOffBalance)
    local out = { damage = moveDef.damage or 0, posture = moveDef.posture or 0 }
    if moveDef.category ~= "Strike" and moveDef.id ~= "clinch_attempt" then return out end
    if unit.stance == "Aggressive" then out.posture = out.posture + 1
    elseif unit.stance == "Pressured" then out.damage = math.max(0, out.damage - 1) end
    if wasOffBalance then out.damage = math.max(0, out.damage - 1); out.posture = math.max(0, out.posture - 1) end
    return out
end

local function apply_mitigation(unit, dmg, posture)
    if unit.stance == "Defensive" then
        if dmg > 0 then dmg = dmg - 1 end
        if posture > 0 then posture = posture - 1 end
    end
    return math.max(0, dmg), math.max(0, posture)
end

local function pair_outcome(aMoveId, bMoveId, ctx, moves, bTraits)
    local aMove = shallowcopy(moves[aMoveId] or {}); aMove.id = aMoveId
    local bMove = shallowcopy(moves[bMoveId] or {}); bMove.id = bMoveId

    local result = {
        a = { damage = 0, posture = 0, blocked = false, evaded = false, landed = false },
        b = { damage = 0, posture = 0, blocked = false, evaded = false, landed = false },
        text = {},
    }
    local function addText(s) result.text[#result.text + 1] = s end

    local aOB = ctx.a.flags.offBalanceNext; local bOB = ctx.b.flags.offBalanceNext
    ctx.a.flags.offBalanceNext = false; ctx.b.flags.offBalanceNext = false
    if aOB and ctx.a.stance == "Off-Balance" then ctx.a.stance = "Neutral" end
    if bOB and ctx.b.stance == "Off-Balance" then ctx.b.stance = "Neutral" end
    if aOB then addText(ctx.a.name .. " is off-balance.") end
    if bOB then addText(ctx.b.name .. " is off-balance.") end

    local aAtk = strike_profile(ctx.a, aMove, aOB)
    local bAtk = strike_profile(ctx.b, bMove, bOB)
    local aDefFx, bDefFx = {}, {}

    local aHits, aTag = false, nil; local bHits, bTag = false, nil
    if aMove.category == "Strike" then aHits, aTag = strike_hits(aMove, bMove, bDefFx) end
    if bMove.category == "Strike" then bHits, bTag = strike_hits(bMove, aMove, aDefFx) end

    -- Clinch interactions
    if aMove.id == "clinch_attempt" and (bMove.category == "Defense" or bMove.category == "Evasion") then
        result.b.posture = result.b.posture + 1; addText(ctx.a.name .. " pressures a clinch.")
    end
    if bMove.id == "clinch_attempt" and (aMove.category == "Defense" or aMove.category == "Evasion") then
        result.a.posture = result.a.posture + 1; addText(ctx.b.name .. " pressures a clinch.")
    end

    -- Feint vs defense
    if aMove.id == "feint" and (bMove.id == "parry" or bMove.id == "guard_high" or bMove.id == "guard_low") then
        result.b.posture = result.b.posture + 2; addText(ctx.a.name .. "'s feint draws out defense.")
    end
    if bMove.id == "feint" and (aMove.id == "parry" or aMove.id == "guard_high" or aMove.id == "guard_low") then
        result.a.posture = result.a.posture + 2; addText(ctx.b.name .. "'s feint draws out defense.")
    end

    -- Delay vs parry
    if aMove.id == "delay" and bMove.id == "parry" then result.b.posture = result.b.posture + 1; addText(ctx.a.name .. "'s delay wastes parry timing.") end
    if bMove.id == "delay" and aMove.id == "parry" then result.a.posture = result.a.posture + 1; addText(ctx.b.name .. "'s delay wastes parry timing.") end

    -- Bait vs strike
    if aMove.id == "bait" and bMove.category == "Strike" then result.b.posture = result.b.posture + 1; addText(ctx.a.name .. "'s bait destabilizes the attack.") end
    if bMove.id == "bait" and aMove.category == "Strike" then result.a.posture = result.a.posture + 1; addText(ctx.b.name .. "'s bait destabilizes the attack.") end

    -- Resolve strikes
    if aMove.category == "Strike" then
        if aTag == "blocked" then result.b.blocked = true; addText(ctx.b.name .. " blocks " .. aMove.name .. ".")
        elseif aTag == "evaded" then result.b.evaded = true; addText(ctx.b.name .. " evades " .. aMove.name .. ".")
        elseif aTag == "parried" then
            result.a.posture = result.a.posture + 2; result.a.damage = result.a.damage + 1
            addText(ctx.b.name .. " parries " .. aMove.name .. ".")
            if hasTrait(bTraits, "Counter Specialist") then result.a.posture = result.a.posture + 1 end
        else
            result.b.landed = true
            result.b.damage = result.b.damage + damage_with_momentum(ctx.a, aAtk.damage)
            result.b.posture = result.b.posture + aAtk.posture
            addText(ctx.a.name .. " lands " .. aMove.name .. ".")
            if ctx.a.flags.brokenAdvantage then addText(ctx.a.name .. " cashes in posture-break advantage."); ctx.a.flags.brokenAdvantage = false end
        end
    end
    if bMove.category == "Strike" then
        if bTag == "blocked" then result.a.blocked = true; addText(ctx.a.name .. " blocks " .. bMove.name .. ".")
        elseif bTag == "evaded" then result.a.evaded = true; addText(ctx.a.name .. " evades " .. bMove.name .. ".")
        elseif bTag == "parried" then
            result.b.posture = result.b.posture + 2; result.b.damage = result.b.damage + 1
            addText(ctx.a.name .. " parries " .. bMove.name .. ".")
        else
            result.a.landed = true
            result.a.damage = result.a.damage + damage_with_momentum(ctx.b, bAtk.damage)
            result.a.posture = result.a.posture + bAtk.posture
            addText(ctx.b.name .. " lands " .. bMove.name .. ".")
            if ctx.b.flags.brokenAdvantage then addText(ctx.b.name .. " cashes in posture-break advantage."); ctx.b.flags.brokenAdvantage = false end
        end
    end

    -- Stomp crushes low kick
    if aMove.id == "stomp" and bMove.id == "low_kick" and aHits then ctx.b.flags.offBalanceNext = true; ctx.b.stance = "Off-Balance"; addText("Heavy strike crushes low attack.") end
    if bMove.id == "stomp" and aMove.id == "low_kick" and bHits then ctx.a.flags.offBalanceNext = true; ctx.a.stance = "Off-Balance"; addText("Heavy strike crushes low attack.") end

    -- Advance vs disruption
    if aMove.id == "advance" and bMove.category == "Disruption" then result.b.posture = result.b.posture + 1; addText(ctx.a.name .. "'s advance shrugs off disruption.") end
    if bMove.id == "advance" and aMove.category == "Disruption" then result.a.posture = result.a.posture + 1; addText(ctx.b.name .. "'s advance shrugs off disruption.") end

    -- Retreat bleeds pressure
    if aMove.id == "retreat" and bMove.category == "Strike" then result.a.posture = math.max(0, result.a.posture - 1) end
    if bMove.id == "retreat" and aMove.category == "Strike" then result.b.posture = math.max(0, result.b.posture - 1) end

    -- Mitigation
    result.a.damage, result.a.posture = apply_mitigation(ctx.a, result.a.damage, result.a.posture)
    result.b.damage, result.b.posture = apply_mitigation(ctx.b, result.b.damage, result.b.posture)

    -- Stance from move
    if aMove.setsStance then ctx.a.stance = aMove.setsStance end
    if bMove.setsStance then ctx.b.stance = bMove.setsStance end

    return result
end

--- Resolve a full 5-step duel round.
---@param args table { a_plan, b_plan, a_unit, b_unit, moves, b_traits }
---@return table events array + finalState
function Resolver.resolve_round(args)
    local moves = args.moves
    local bTraits = args.b_traits or {}
    local aSim = clone_fighter(args.a_unit)
    local bSim = clone_fighter(args.b_unit)
    local events = {}

    for i = 1, 5 do
        local entry = pair_outcome(args.a_plan[i], args.b_plan[i], { a = aSim, b = bSim }, moves, bTraits)

        aSim.hp = Math.clamp(aSim.hp - entry.a.damage, 0, aSim.maxHp)
        bSim.hp = Math.clamp(bSim.hp - entry.b.damage, 0, bSim.maxHp)

        local aBreak = apply_posture(aSim, entry.a.posture)
        local bBreak = apply_posture(bSim, entry.b.posture)

        if aBreak then table.insert(entry.text, aSim.name .. " posture breaks!"); bSim.flags.pendingAdvantage = true end
        if bBreak then table.insert(entry.text, bSim.name .. " posture breaks!"); aSim.flags.pendingAdvantage = true end

        -- Momentum tracking
        local aLanded = (moves[args.a_plan[i]] or {}).category == "Strike" and entry.b.landed
        local bLanded = (moves[args.b_plan[i]] or {}).category == "Strike" and entry.a.landed

        if aLanded then aSim.momentum = Math.clamp(aSim.momentum + 1, 0, 2)
        elseif (moves[args.a_plan[i]] or {}).category == "Strike" then aSim.momentum = 0 end

        if bLanded and hasTrait(bTraits, "Momentum Fighter") then bSim.momentum = Math.clamp(bSim.momentum + 1, 0, 2)
        elseif (moves[args.b_plan[i]] or {}).category == "Strike" then bSim.momentum = 0 end

        events[i] = {
            slot = i,
            a_move = args.a_plan[i], b_move = args.b_plan[i],
            result = entry,
            snapshot = {
                a_hp = aSim.hp, b_hp = bSim.hp,
                a_posture = aSim.posture, b_posture = bSim.posture,
                a_stance = aSim.stance, b_stance = bSim.stance,
            },
        }
    end

    -- Transfer pending advantage
    aSim.flags.brokenAdvantage = aSim.flags.pendingAdvantage; aSim.flags.pendingAdvantage = false
    bSim.flags.brokenAdvantage = bSim.flags.pendingAdvantage; bSim.flags.pendingAdvantage = false

    events.final_state = { a = aSim, b = bSim }
    return events
end

return Resolver
