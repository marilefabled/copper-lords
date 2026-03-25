-- dredwork Agency — Multi-Step Plans
-- Entities don't just pick single actions — they build 2-3 step plans and execute them.
-- Plans adapt when steps fail. Completed plans create narrative arcs.

local RNG = require("dredwork_core.rng")

local Plans = {}

--- Plan templates: multi-step strategies entities can pursue.
local PLAN_TEMPLATES = {
    coup = {
        id = "coup", label = "Seize Power",
        steps = { "scheme", "bribe", "raid" },
        requires_goals = { "gain_power", "avenge_grudge" },
        min_personality = { PER_BLD = 50, PER_CRM = 40 },
    },
    alliance = {
        id = "alliance", label = "Build Alliance",
        steps = { "gift", "visit_ally", "propose_marriage" },
        requires_goals = { "build_loyalty", "find_mate" },
        min_personality = { PER_LOY = 45 },
    },
    fortification = {
        id = "fortification", label = "Strengthen Defenses",
        steps = { "earn_gold", "fortify", "train_troops" },
        requires_goals = { "survive", "protect_family" },
        min_personality = {},
    },
    knowledge = {
        id = "knowledge", label = "Pursuit of Knowledge",
        steps = { "research", "research", "build_monument" },
        requires_goals = { "seek_knowledge", "build_legacy" },
        min_personality = { PER_CUR = 50 },
    },
    revenge = {
        id = "revenge", label = "Vendetta",
        steps = { "scheme", "scheme", "raid" },
        requires_goals = { "avenge_grudge" },
        min_personality = { PER_CRM = 40 },
    },
    piety = {
        id = "piety", label = "Devotion",
        steps = { "pray", "gift", "pray" },
        requires_goals = { "serve_faith" },
        min_personality = {},
    },
    wealth = {
        id = "wealth", label = "Accumulate Wealth",
        steps = { "earn_gold", "trade", "earn_gold" },
        requires_goals = { "accumulate", "gain_power" },
        min_personality = {},
    },
    subversion = {
        id = "subversion", label = "Undermine From Within",
        steps = { "scheme", "extort", "bribe" },
        requires_goals = { "undermine", "accumulate" },
        min_personality = { PER_OBS = 50 },
    },
}

--- Select a plan for an entity based on goals and personality.
function Plans.select_plan(entity)
    local agenda = entity.components.agenda
    local personality = entity.components.personality or {}
    if not agenda or not agenda.goals then return nil end

    -- Build goal set
    local goal_set = {}
    for _, g in ipairs(agenda.goals) do goal_set[g.id] = g.priority end

    local candidates = {}
    for _, template in pairs(PLAN_TEMPLATES) do
        -- Check if any required goal matches
        local goal_match = false
        local total_priority = 0
        for _, req_goal in ipairs(template.requires_goals) do
            if goal_set[req_goal] then
                goal_match = true
                total_priority = total_priority + (goal_set[req_goal] or 0)
            end
        end
        if not goal_match then goto continue end

        -- Check personality minimums
        local personality_ok = true
        for axis, min_val in pairs(template.min_personality) do
            local val = personality[axis]
            if type(val) == "table" then val = val.value end
            if (val or 50) < min_val then personality_ok = false; break end
        end
        if not personality_ok then goto continue end

        table.insert(candidates, { template = template, score = total_priority + RNG.range(-10, 10) })
        ::continue::
    end

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b) return a.score > b.score end)
    return candidates[1].template
end

--- Create an active plan instance from a template.
function Plans.create(template)
    return {
        template_id = template.id,
        label = template.label,
        steps = {},
        current_step = 1,
        status = "active",  -- active, completed, failed, abandoned
        started_day = 0,
    }
end

--- Advance a plan by one step. Returns the action to execute, or nil if plan is done.
function Plans.advance(plan, template)
    if plan.status ~= "active" then return nil end
    if plan.current_step > #template.steps then
        plan.status = "completed"
        return nil
    end

    local action_id = template.steps[plan.current_step]
    table.insert(plan.steps, { step = plan.current_step, action = action_id, status = "executing" })
    plan.current_step = plan.current_step + 1
    return action_id
end

--- Mark the last step as succeeded or failed.
function Plans.report_step(plan, success)
    if #plan.steps == 0 then return end
    local last = plan.steps[#plan.steps]
    last.status = success and "succeeded" or "failed"

    -- If a step fails, plan may be abandoned (personality dependent)
    if not success and RNG.chance(0.3) then
        plan.status = "abandoned"
    end
end

--- Is the plan still active?
function Plans.is_active(plan)
    return plan and plan.status == "active"
end

--- Get plan templates (for UI/debug).
function Plans.get_templates()
    return PLAN_TEMPLATES
end

return Plans
