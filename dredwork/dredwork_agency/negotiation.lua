-- dredwork Agency — Inter-Entity Negotiation
-- Entities propose deals to each other. Acceptance depends on personality, needs, and memory.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Negotiation = {}

--- Proposal types.
local PROPOSAL_TYPES = {
    alliance   = { label = "Form Alliance",     base_accept = 0.4 },
    trade      = { label = "Trade Agreement",   base_accept = 0.5 },
    marriage   = { label = "Marriage Pact",      base_accept = 0.3 },
    conspiracy = { label = "Join Conspiracy",    base_accept = 0.2 },
    tribute    = { label = "Pay Tribute",        base_accept = 0.1 },
    protection = { label = "Protection Pact",    base_accept = 0.4 },
    betrayal   = { label = "Betray Mutual Ally", base_accept = 0.15 },
    support    = { label = "Support My Claim",   base_accept = 0.25 },
}

--- Create a proposal.
function Negotiation.create_proposal(proposer_id, target_id, proposal_type, offer, day)
    local ptype = PROPOSAL_TYPES[proposal_type]
    return {
        id = proposal_type .. "_" .. proposer_id .. "_" .. (day or 0),
        type = proposal_type,
        label = ptype and ptype.label or proposal_type,
        proposer_id = proposer_id,
        target_id = target_id,
        offer = offer or {},    -- what the proposer gives
        demand = {},            -- what the proposer wants (filled by caller)
        day = day or 0,
        status = "pending",     -- pending, accepted, rejected, expired
    }
end

--- Evaluate whether an entity would accept a proposal.
---@param target table entity receiving the proposal
---@param proposer table entity making the proposal
---@param proposal table the proposal
---@return boolean accepted
---@return number score (how much they wanted it)
---@return string reason
function Negotiation.evaluate(target, proposer, proposal)
    local ptype = PROPOSAL_TYPES[proposal.type]
    if not ptype then return false, 0, "unknown proposal type" end

    local score = ptype.base_accept * 100
    local target_p = target.components.personality or {}
    local target_mem = target.components.memory

    -- Personality modifiers
    local loy = target_p.PER_LOY or 50
    local bld = target_p.PER_BLD or 50
    local crm = target_p.PER_CRM or 50
    local obs = target_p.PER_OBS or 50
    if type(loy) == "table" then loy = loy.value or 50 end
    if type(bld) == "table" then bld = bld.value or 50 end
    if type(crm) == "table" then crm = crm.value or 50 end
    if type(obs) == "table" then obs = obs.value or 50 end

    -- Loyal entities accept alliances more easily
    if proposal.type == "alliance" or proposal.type == "support" then
        score = score + (loy - 50) * 0.5
    end

    -- Cruel entities accept conspiracies and betrayals more easily
    if proposal.type == "conspiracy" or proposal.type == "betrayal" then
        score = score + (crm - 50) * 0.5
        score = score - (loy - 50) * 0.3  -- loyal entities resist betrayal
    end

    -- Bold entities resist tribute demands
    if proposal.type == "tribute" then
        score = score - (bld - 50) * 0.4
    end

    -- Memory: grudges against proposer reduce acceptance
    if target_mem then
        local MemLib = require("dredwork_agency.memory")
        local has_grudge, intensity = MemLib.has_grudge(target_mem, proposer.id)
        if has_grudge then
            score = score - intensity * 0.5
        end
        -- Debts to proposer increase acceptance
        local has_debt, weight = MemLib.has_debt(target_mem, proposer.id)
        if has_debt then
            score = score + weight * 0.3
        end
    end

    -- Needs: unmet needs make relevant proposals more attractive
    local target_needs = target.components.needs
    if target_needs then
        if proposal.type == "protection" and target_needs.safety < 30 then
            score = score + 20
        end
        if proposal.type == "alliance" and target_needs.belonging < 30 then
            score = score + 15
        end
        if proposal.type == "trade" and target_needs.comfort < 30 then
            score = score + 10
        end
    end

    -- Random variance
    score = score + RNG.range(-10, 10)

    local accepted = score > 50
    local reason = accepted and "terms acceptable" or "terms unfavorable"
    if score < 20 then reason = "deeply opposed" end
    if score > 80 then reason = "enthusiastically agreed" end

    return accepted, math.floor(score), reason
end

--- Get available proposal types.
function Negotiation.get_types()
    return PROPOSAL_TYPES
end

return Negotiation
