local Math = require("dredwork_core.math")
local ShadowCareer = require("dredwork_bonds.career")
local ShadowBonds = require("dredwork_bonds.bonds")
local ShadowBody = require("dredwork_bonds.body")
local ShadowClaim = require("dredwork_bonds.claim")
local ShadowPossessions = require("dredwork_bonds.possessions")
local ShadowYear = require("dredwork_bonds.year")

local ShadowAftermath = {}


local function current_age(game_state)
    local setup = game_state and game_state.shadow_setup or nil
    if not setup then
        return 20
    end
    return (setup.start_age or 20) + math.max(0, (game_state.generation or 1) - 1)
end

local function surviving_bonds(game_state)
    local detail = ShadowBonds.detail_snapshot(game_state)
    local survivors = {}
    for _, bond in ipairs(detail.bonds or {}) do
        if bond.status ~= "Hostile" then
            survivors[#survivors + 1] = {
                name = bond.name,
                role = bond.role,
                category = bond.category,
                status = bond.status,
                closeness = bond.closeness,
                strain = bond.strain,
                arc = bond.arc,
            }
        end
    end
    return survivors
end

local function inheritable_possessions(game_state)
    local snap = ShadowPossessions.snapshot(game_state)
    local passed = {}
    for _, entry in ipairs(snap.entries or {}) do
        if entry.kind == "item" and (entry.yield or 0) >= 1 then
            passed[#passed + 1] = {
                id = entry.id,
                label = entry.label,
                kind = entry.kind,
                weight = entry.weight,
                yield = entry.yield,
                note = "Inherited from a shadow life.",
            }
        elseif entry.kind == "place" then
            passed[#passed + 1] = {
                id = entry.id,
                label = entry.label,
                kind = entry.kind,
                weight = entry.weight,
                yield = entry.yield,
                note = "Left behind by one who could not hold it.",
            }
        end
    end
    return passed
end

local function reputation_echo(game_state, ending)
    local claim = ShadowClaim.snapshot(game_state)
    local career = ShadowCareer.snapshot(game_state)
    local shadow = ShadowYear.snapshot(game_state)
    local cause = ending and ending.cause or "unknown"

    local echo = {
        claim_status = claim and claim.status or "BROKEN BRANCH",
        claim_house = claim and claim.house_name or "Unknown",
        legitimacy = claim and claim.legitimacy or 0,
        proof = claim and claim.proof or 0,
        exposure = claim and claim.exposure or 0,
        final_title = career and career.title or "UNFORMED",
        final_rank = career and career.rank or 0,
        standing = shadow.standing or 0,
        notoriety = shadow.notoriety or 0,
        cause_of_death = cause,
    }

    if echo.claim_status == "ASSERTED CLAIM" then
        echo.weight = "heavy"
        echo.rumor = "The denied branch was named aloud before the end came. The claim survives in public memory."
    elseif echo.claim_status == "LIVING WHISPER" then
        echo.weight = "lingering"
        echo.rumor = "Whispers of the old branch outlived the one who carried them."
    else
        echo.weight = "fading"
        echo.rumor = "The denied branch died as it lived — unacknowledged."
    end

    return echo
end

local function ghost_weight(game_state, ending)
    local shadow = ShadowYear.snapshot(game_state)
    local body = ShadowBody.snapshot(game_state)
    local claim = ShadowClaim.snapshot(game_state)
    local career = ShadowCareer.snapshot(game_state)

    local weight = 0

    weight = weight + math.floor((shadow.standing or 0) * 0.3)
    weight = weight + math.floor((shadow.notoriety or 0) * 0.4)
    weight = weight + math.floor((claim and claim.legitimacy or 0) * 0.25)
    weight = weight + math.floor((claim and claim.proof or 0) * 0.15)
    weight = weight + math.floor((career and career.rank or 0) * 0.2)

    if ending and ending.cause == "betrayed" then
        weight = weight + 15
    elseif ending and ending.cause == "scandal" then
        weight = weight + 10
    elseif ending and ending.cause == "sacrificed" then
        weight = weight + 12
    end

    local age = current_age(game_state)
    if age <= 25 then
        weight = weight + 8
    elseif age >= 60 then
        weight = weight - 5
    end

    return Math.clamp(weight, 0, 100)
end

function ShadowAftermath.compile(game_state, world, ending)
    if not game_state or not game_state.shadow_setup then
        return nil
    end

    local age = current_age(game_state)
    local setup = game_state.shadow_setup or {}
    local career = ShadowCareer.snapshot(game_state)
    local shadow = ShadowYear.snapshot(game_state)
    local body = ShadowBody.snapshot(game_state)
    local claim = ShadowClaim.snapshot(game_state)
    local bonds = surviving_bonds(game_state)
    local possessions = inheritable_possessions(game_state)
    local echo = reputation_echo(game_state, ending)
    local weight = ghost_weight(game_state, ending)

    return {
        heir_name = game_state.heir_name or "Unknown",
        lineage_name = game_state.lineage_name or "Unknown",
        age_at_death = age,
        years_lived = age - (setup.start_age or 16),

        cause = ending and ending.cause or "unknown",
        title = ending and ending.title or "The Record Closes",

        occupation = setup.occupation_label or setup.calling_label or "Unknown",
        final_title = career.title,
        final_rank = career.rank,

        burden = setup.burden_label or "Unknown",
        vice = setup.vice_label or "Unknown",
        faith = setup.faith_label or "Unknown",
        creed = setup.creed or "",

        claim_status = claim and claim.status or "BROKEN BRANCH",
        claim_house = claim and claim.house_name or "Unknown",

        health = shadow.health,
        stress = shadow.stress,
        standing = shadow.standing,
        notoriety = shadow.notoriety,

        wound_label = body.wound_label,
        illness_label = body.illness_label,
        compulsion_label = body.compulsion_label,
        scar_load = body.scar_load or 0,

        surviving_bonds = bonds,
        surviving_bond_count = #bonds,
        inheritable_possessions = possessions,

        echo = echo,
        ghost_weight = weight,

        legacy_lines = ShadowAftermath.legacy_lines(game_state, ending, echo, weight),
    }
end

function ShadowAftermath.legacy_lines(game_state, ending, echo, weight)
    local lines = {}
    local heir = game_state and game_state.heir_name or "Unknown"
    local setup = game_state and game_state.shadow_setup or {}

    if weight >= 60 then
        lines[#lines + 1] = heir .. " left a weight that the world will carry whether it wants to or not."
    elseif weight >= 35 then
        lines[#lines + 1] = heir .. " left enough behind to be remembered by those who had reason to."
    else
        lines[#lines + 1] = heir .. " passed without disturbing the record more than weather disturbs stone."
    end

    if echo.claim_status == "ASSERTED CLAIM" then
        lines[#lines + 1] = "The claim to " .. echo.claim_house .. " is now public knowledge. Someone will have to answer it."
    elseif echo.claim_status == "LIVING WHISPER" then
        lines[#lines + 1] = "The whisper of the old branch survives. Whether anyone picks it up is another life's problem."
    end

    local bonds = surviving_bonds(game_state)
    if #bonds >= 3 then
        lines[#lines + 1] = tostring(#bonds) .. " ties outlived the life. Some of them will remember the shape of the absence."
    elseif #bonds == 0 then
        lines[#lines + 1] = "No bond survived intact. The life closed without witness."
    end

    local possessions = inheritable_possessions(game_state)
    if #possessions >= 1 then
        lines[#lines + 1] = tostring(#possessions) .. " possessions remain unclaimed."
    end

    if ending and ending.cause == "betrayed" then
        lines[#lines + 1] = "The betrayal will be remembered longer than the life it ended."
    elseif ending and ending.cause == "sacrificed" then
        lines[#lines + 1] = "The sacrifice will be spoken of as either devotion or waste, depending on who inherits the story."
    end

    return lines
end

function ShadowAftermath.seed_next_life(aftermath)
    if not aftermath then
        return nil
    end

    local seed = {
        previous_name = aftermath.heir_name,
        previous_house = aftermath.claim_house,
        previous_claim_status = aftermath.claim_status,
        ghost_weight = aftermath.ghost_weight,
        inheritable_possessions = aftermath.inheritable_possessions,
        surviving_bonds = {},
    }

    for _, bond in ipairs(aftermath.surviving_bonds or {}) do
        if bond.closeness >= 30 then
            seed.surviving_bonds[#seed.surviving_bonds + 1] = {
                name = bond.name,
                role = "MEMORY OF " .. bond.role,
                category = bond.category,
                status = bond.status,
                legacy_closeness = math.floor(bond.closeness * 0.4),
            }
        end
    end

    if aftermath.echo.claim_status == "ASSERTED CLAIM" then
        seed.claim_bonus = { legitimacy = 12, proof = 8, ambition = 6 }
    elseif aftermath.echo.claim_status == "LIVING WHISPER" then
        seed.claim_bonus = { legitimacy = 4, proof = 4 }
    end

    if aftermath.ghost_weight >= 50 then
        seed.starting_notoriety = math.floor(aftermath.ghost_weight * 0.2)
        seed.starting_standing = math.floor(aftermath.ghost_weight * 0.15)
    end

    return seed
end

return ShadowAftermath
