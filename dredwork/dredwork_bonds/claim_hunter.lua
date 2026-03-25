local Math = require("dredwork_core.math")
local ShadowClaim = require("dredwork_bonds.claim")

local ShadowClaimHunter = {}


local ESCALATION_TIERS = {
    { threshold = 38, id = "curious_stranger", title = "A Curious Stranger", description = "Someone is asking about your family. Not loudly. Not yet." },
    { threshold = 52, id = "genealogist", title = "The Genealogist", description = "A studious figure arrives with old records and questions that feel rehearsed." },
    { threshold = 56, id = "rival_claimant", title = "A Rival Claimant", description = "Someone else says they own your bloodline's name — and they have witnesses." },
    { threshold = 64, id = "house_agent", title = "The House Agent", description = "A representative of the denied house arrives with leverage and a short timeline." },
    { threshold = 72, id = "extortionist", title = "The Extortionist", description = "Your claim has become currency. Someone is selling it to the highest bidder." },
    { threshold = 80, id = "assassins_question", title = "The Assassin's Question", description = "A professional arrives with one question: is the claim worth more alive or buried?" },
}

local function get_claim_state(game_state)
    if not game_state or not game_state.shadow_claim then return nil end
    return game_state.shadow_claim
end

local function combined_pressure(claim)
    if not claim then return 0 end
    return math.max(claim.exposure or 0, claim.usurper_risk or 0)
end

function ShadowClaimHunter.generate(game_state, generation)
    if not game_state then return {} end
    local claim = get_claim_state(game_state)
    if not claim or not claim.initialized then return {} end

    game_state.shadow_claim_hunter = game_state.shadow_claim_hunter or {}
    local hunter_state = game_state.shadow_claim_hunter
    hunter_state.seen = hunter_state.seen or {}
    local last_gen = hunter_state.last_hunt_generation or 0
    generation = generation or (game_state.generation or 1)

    if generation - last_gen < 2 then
        return {}
    end

    local pressure = combined_pressure(claim)
    local events = {}

    for _, tier in ipairs(ESCALATION_TIERS) do
        if pressure >= tier.threshold and not hunter_state.seen[tier.id] then
            hunter_state.seen[tier.id] = true
            hunter_state.last_hunt_generation = generation

            local event = {
                id = "claim_hunt:" .. tier.id,
                title = tier.title,
                description = tier.description,
                source = "claim_hunter",
                options = {
                    {
                        id = tier.id .. "_face",
                        label = "Face it directly",
                        description = "Meet the threat head-on.",
                        success = {
                            narrative = "You stood your ground. The claim holds, but the cost was not nothing.",
                            effects = {
                                claim = { exposure = 6, legitimacy = 4, usurper_risk = -4 },
                                shadow = { stress = 4, standing = 2, notoriety = 3 },
                            },
                        },
                        failure = {
                            narrative = "The confrontation went badly. Your name is louder now, and not in the way you needed.",
                            effects = {
                                claim = { exposure = 10, usurper_risk = 6, grievance = 4 },
                                shadow = { stress = 6, standing = -2, notoriety = 5 },
                            },
                        },
                    },
                    {
                        id = tier.id .. "_hide",
                        label = "Go quiet and let it pass",
                        description = "Deny everything. Become forgettable.",
                        success = {
                            narrative = "The danger moved on. But it knows your face now.",
                            effects = {
                                claim = { exposure = -4, usurper_risk = -2, ambition = -4 },
                                shadow = { stress = 2 },
                            },
                        },
                        failure = {
                            narrative = "Hiding proved you had something to hide.",
                            effects = {
                                claim = { exposure = 4, usurper_risk = 4 },
                                shadow = { stress = 5, notoriety = 2 },
                            },
                        },
                    },
                },
            }
            events[#events + 1] = event
            break
        end
    end

    return events
end

return ShadowClaimHunter
