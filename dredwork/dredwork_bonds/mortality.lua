local ShadowCareer = require("dredwork_bonds.career")
local ShadowBonds = require("dredwork_bonds.bonds")
local ShadowYear = require("dredwork_bonds.year")
local ShadowBody = require("dredwork_bonds.body")
local ShadowExpectations = require("dredwork_bonds.expectations")

local ShadowMortality = {}

local function current_age(game_state)
    local setup = game_state and game_state.shadow_setup or nil
    if not setup then
        return nil
    end
    return (setup.start_age or 0) + math.max(0, (game_state.generation or 1) - 1)
end

local function strongest_bond_name(game_state)
    local detail = ShadowBonds.detail_snapshot(game_state)
    local best = detail and detail.strongest or nil
    return best and best.name or "no one"
end

local function build_paragraphs(game_state, world, ending)
    local age = current_age(game_state) or (game_state and game_state.generation or 1)
    local heir = game_state and game_state.heir_name or "Unknown"
    local setup = game_state and game_state.shadow_setup or {}
    local career = ShadowCareer.snapshot(game_state)
    local shadow = ShadowYear.snapshot(game_state)
    local body = ShadowBody.snapshot(game_state)
    local detail = ShadowBonds.detail_snapshot(game_state)
    local bond_name = strongest_bond_name(game_state)
    local fracture_name = detail and detail.rival and detail.rival.name or "no declared enemy"
    local dependent_name = detail and detail.dependent and detail.dependent.name or "no dependent"
    local world_name = world and world.world_state and world.world_state.get_world_name and world.world_state:get_world_name() or "the realm"
    local burden = string.lower(setup.burden_label or "an old burden")
    local vice = string.lower(setup.vice_label or "no admitted vice")
    local faith = string.lower(setup.faith_label or "no visible creed")

    local paragraphs = {
        heir .. " reached age " .. tostring(age) .. " in " .. tostring(world_name) .. " and met the end called " .. string.lower(ending.title) .. ". The life had been narrowed for years by " .. burden .. ", and the narrowing finally held.",
        "By the end they were known as " .. string.lower(career.title or "a worker") .. ". Health stood " .. string.lower(shadow.health_label or "unknown") .. ", stress stood " .. string.lower(shadow.stress_label or "unknown") .. ", the body stood " .. string.lower(body.wound_label or "unknown") .. ", and the most faithful name remaining nearby was " .. bond_name .. ".",
        "The record closes with " .. vice .. " at one shoulder and " .. faith .. " at the other. The nearest fracture was " .. fracture_name .. ", the heaviest need was " .. dependent_name .. ", and whatever survives of this life will do so as rumor, scar, caution, or prayer.",
    }
    return paragraphs
end

function ShadowMortality.evaluate(game_state, world)
    if not game_state or not game_state.shadow_setup then
        return nil
    end

    local age = current_age(game_state) or 20
    local setup = game_state.shadow_setup or {}
    local shadow = ShadowYear.snapshot(game_state)
    local career = ShadowCareer.snapshot(game_state)
    local detail = ShadowBonds.detail_snapshot(game_state)
    local bonds = detail.bonds or {}
    local body = ShadowBody.snapshot(game_state)
    local top_bond = bonds[1]

    local ending = nil

    if shadow.health <= 8 and shadow.stress >= 84 then
        ending = {
            cause = "collapse",
            title = "The Body Gives Its Final Answer",
            summary = "The strain between flesh and will finally broke open.",
        }
    elseif body.illness_load >= 54 and shadow.health <= 18 then
        ending = {
            cause = "illness",
            title = "The Fever Outlasts the Name",
            summary = "Sickness finished what want, work, and worry had been preparing for years.",
        }
    elseif body.wound_load >= 56 and shadow.health <= 24 then
        ending = {
            cause = "wounds",
            title = "Too Much of the Body Is Already Spoken For",
            summary = "Old damage and new damage finally agreed to close the account together.",
        }
    elseif body.compulsion_load >= 68 and shadow.stress >= 72 then
        ending = {
            cause = "ruinous_habit",
            title = "The Habit Learns to Sign Your Name",
            summary = "The ruling hunger grew patient, then thorough, then absolute.",
        }
    elseif shadow.stress >= 96 then
        ending = {
            cause = "mind_breaks",
            title = "The Mind Leaves First",
            summary = "The life could no longer be carried intact from one day to the next.",
        }
    elseif (setup.burden == "wanted" and shadow.notoriety >= 74) or (shadow.notoriety >= 90 and shadow.standing <= 34) then
        ending = {
            cause = "prison",
            title = "Taken in Chains",
            summary = "The city finally decided the protagonist belonged to it more as an example than a citizen.",
        }
    elseif shadow.notoriety >= 82 and shadow.bonds <= 20 and (setup.burden == "wanted" or setup.vice == "drink") then
        ending = {
            cause = "exile",
            title = "Driven Beyond the Roads",
            summary = "Too many doors closed at once. The life continued somewhere else, outside the map that mattered.",
        }
    elseif shadow.bonds <= 6 and shadow.stress >= 78 then
        ending = {
            cause = "vanished",
            title = "The Record Loses the Trail",
            summary = "Too few hands remained to hold the life in place. One season it was present. The next it was rumor.",
        }
    elseif detail.dependent and (detail.dependent.dependency or 0) >= 82 and shadow.health <= 24 then
        ending = {
            cause = "sacrificed",
            title = "Spent Keeping Someone Else Alive",
            summary = "The life narrowed around one needed person until nothing outside that need could endure.",
        }
    elseif detail.rival and detail.rival.status == "Hostile" and (detail.rival.leverage or 0) >= 72 and shadow.standing <= 26 then
        ending = {
            cause = "betrayed",
            title = "A Known Enemy Finally Finds the Opening",
            summary = "The feud outlived caution and finally chose the season of payment.",
        }
    elseif ShadowExpectations.grievance_count(game_state, 60) >= 2 then
        ending = {
            cause = "broken_contracts",
            title = "Every Promise Comes Due at Once",
            summary = "Too many bonds carried grievances too long. The web of broken contracts collapsed inward.",
        }
    elseif age >= 68 then
        ending = {
            cause = "natural_frailty",
            title = "The Years Collect Their Debt",
            summary = "The body reached the place where endurance becomes memory.",
        }
    elseif age >= 56 and shadow.health <= 22 then
        ending = {
            cause = "wasting",
            title = "Worn Through",
            summary = "Too many hard years fed on too little flesh.",
        }
    elseif career.stability <= 8 and top_bond and top_bond.status == "Hostile" then
        ending = {
            cause = "scandal",
            title = "The Name Becomes Unusable",
            summary = "Work, trust, and shelter all failed under the same story.",
        }
    end

    if not ending then
        return nil
    end

    ending.age = age
    ending.paragraphs = build_paragraphs(game_state, world, ending)
    ending.record_lines = {
        "Career ended at " .. (career.title or "Unknown") .. ".",
        "Health " .. (shadow.health_label or "Unknown") .. " | Stress " .. (shadow.stress_label or "Unknown") .. " | Bonds " .. (shadow.bonds_label or "Unknown") .. ".",
        "Standing " .. (shadow.standing_label or "Unknown") .. " | Notoriety " .. (shadow.notoriety_label or "Unknown") .. ".",
        "Wounds " .. (body.wound_label or "Unknown") .. " | Illness " .. (body.illness_label or "Unknown") .. " | Habit " .. (body.compulsion_label or "Unknown") .. ".",
    }
    return ending
end

return ShadowMortality
