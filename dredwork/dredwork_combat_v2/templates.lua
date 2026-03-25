-- Bloodweight — Combat Narrative Templates (v2)
-- Procedural fight prose in the Soul Teller voice.
-- Fragment pools with era overrides, personality color, terrain flavor.
-- Pure Lua, zero Solar2D dependencies.

local Templates = {}

-- ═══════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════

local function pick(pool, rng)
    if not pool or #pool == 0 then return nil end
    return pool[rng(#pool)]
end

local function sub(text, vars)
    if not text or not vars then return text or "" end
    return (text:gsub("{(%w+)}", function(key) return vars[key] or key end))
end

-- ═══════════════════════════════════════════════════════
-- SIZING UP — Pre-fight description
-- ═══════════════════════════════════════════════════════

local SIZING_UP = {
    -- By dominant stat
    power_high = {
        "{name} carried their weight forward. The kind of body that settles arguments before they start.",
        "{name} stood like something quarried, not born.",
        "There was a stillness to {name} that had nothing to do with calm. Mass at rest.",
    },
    speed_high = {
        "{name} moved before the challenge finished echoing.",
        "Something restless in {name}. The hips shifted before the eyes did.",
        "{name} had the build of someone who had outrun worse than this.",
    },
    cunning_high = {
        "{name} watched. Not the hands — the feet. The weight distribution. The tells.",
        "The way {name} tilted their head said they had already counted the exits.",
        "{name} smiled the way people smile when they know something you don't.",
    },
    grit_high = {
        "{name} had the look of someone who had been hit before and had opinions about it.",
        "Nothing about {name} suggested speed or cleverness. Everything suggested endurance.",
        "{name} bore the posture of a wall. Walls do not need to be fast.",
    },
    -- By body state
    wounded = {
        "{name} favored the left side. The old wound was speaking.",
        "The bandages under {name}'s shirt were fresh. Or fresh enough.",
    },
    sick = {
        "{name}'s breath came wrong. Something rattled where it shouldn't.",
        "The fever sheen on {name}'s skin caught the light like oil.",
    },
    scarred = {
        "The scars on {name} told a longer story than this fight would.",
        "{name}'s face was a map of prior miscalculations.",
    },
    -- By personality
    bold = {
        "{name} stepped forward first. Always forward.",
        "{name} grinned. It was not reassuring.",
    },
    cruel = {
        "Something in {name}'s eyes had nothing to do with the fight. It was older than that.",
        "{name} looked at {opponent} the way a child looks at a caught insect.",
    },
    volatile = {
        "{name}'s hands shook. Not from fear.",
        "The air around {name} felt like the moment before a dog bites.",
    },
    proud = {
        "{name} stood as if the ground owed them the courtesy of being level.",
        "{name} looked down. Not at {opponent} specifically — at everything.",
    },
    adaptive = {
        "{name} shifted stance twice before the first exchange. Reading. Adjusting.",
        "{name} waited. The kind of waiting that is actually preparation.",
    },
    loyal = {
        "{name} fought like someone with people to go home to.",
        "There was reluctance in {name}'s posture. Duty without appetite.",
    },
    -- Nemesis-specific
    nemesis = {
        "{name} and {opponent} knew each other's rhythms. This was not their first conversation in this language.",
        "Generations of hatred stood behind {name}. The bloodline was watching.",
        "This was personal. The kind of personal that outlives the participants.",
    },
}

-- ═══════════════════════════════════════════════════════
-- TERRAIN INTRODUCTIONS
-- ═══════════════════════════════════════════════════════

local TERRAIN_INTROS = {
    border_stones = {
        "The border stones stood as witnesses. They had seen this before.",
        "Neutral ground. The kind of neutrality that means both sides bleed equally.",
    },
    courtyard = {
        "The courtyard walls enclosed the violence like a frame encloses a portrait.",
        "Home ground. The stones knew {name}'s footsteps.",
    },
    throne_room = {
        "The throne room was not built for this. The acoustics made every impact louder than it deserved.",
        "Under the eyes of the court. Every blow a political statement.",
    },
    pit = {
        "The pit smelled of old copper and sawdust. The stains on the walls were not decorative.",
        "No rules down here. The pit had one law: the last one standing climbs out.",
    },
    battlefield = {
        "The battle raged around them. This was a private matter conducted in public chaos.",
        "Smoke and screaming. Somewhere in the noise, two people who hated each other found space to prove it.",
    },
    wilderness = {
        "The ground was uneven, the footing treacherous. Nature does not referee.",
        "No witnesses but the crows. They had the patience to wait for the outcome.",
    },
}

-- ═══════════════════════════════════════════════════════
-- ATTACK FRAGMENTS — by move ID
-- ═══════════════════════════════════════════════════════

local ATTACK_FRAGMENTS = {
    strike = {
        "A straight blow from {name}.",
        "{name} swung with the full weight of their shoulder.",
        "Short, direct. {name} committed nothing beyond the fist.",
        "{name}'s arm snapped forward. Economy of violence.",
    },
    counter = {
        "{name} read it. Moved inside the arc.",
        "{name} let {opponent} commit, then made them pay for it.",
        "The counter came from patience. {name} had been waiting for exactly this.",
        "{name} turned {opponent}'s momentum into a lesson.",
    },
    feint = {
        "{name} showed the left. Delivered the right.",
        "A false opening. {name} sold it with their whole body.",
        "{name} twitched — not a real attack. The real one was already in flight.",
    },
    grab = {
        "{name} closed the distance and got hold of something.",
        "Hands on cloth, on skin. {name} hauled {opponent} close.",
        "{name} lunged for the grip. Fighting like the old way — bodies, not technique.",
    },
    dodge = {
        "{name} wasn't there when it arrived.",
        "A lean. A turn of the hip. {name} made it look like geometry.",
        "{name} gave ground. Not retreat — relocation.",
    },
    shove = {
        "{name} drove forward with the shoulder.",
        "Not a punch. A statement of mass. {name} pushed {opponent} back.",
        "{name} put both hands on {opponent}'s chest and shoved like they were clearing rubble.",
    },
    clinch = {
        "{name} wrapped up. Buying time the expensive way.",
        "Arms tangled. Neither could swing. {name} held on like a drowning swimmer.",
        "{name} buried their head in {opponent}'s shoulder. Survival, not strategy.",
    },
    dirty = {
        "{name}'s thumb found the eye socket.",
        "Dust. Spit. Something {name} picked up off the ground. None of it was honorable.",
        "{name} fought the way the desperate fight — without the luxury of rules.",
    },
    lunge = {
        "{name} threw everything into a single forward motion.",
        "A committed charge. {name} was either ending this or ending themselves.",
        "{name} launched forward like a man who had decided the distance was the enemy.",
        "Full extension. {name} left nothing in reserve.",
    },
    brace = {
        "{name} planted both feet and lowered the center of gravity.",
        "{name} stopped moving. Let the world come to them.",
        "A defensive crouch. {name} was daring {opponent} to try.",
    },
    gouge = {
        "{name}'s fingers found soft tissue and dug in.",
        "Not a punch — a violation. {name} went for the face.",
        "{name} fought like an animal. The part of an animal that has stopped caring about survival.",
    },
    headbutt = {
        "Forehead to bridge of nose. The old arithmetic.",
        "{name}'s skull met {opponent}'s face at speed. Both saw stars.",
        "A headbutt. Inelegant. Effective. {name} paid for it too.",
    },
    taunt = {
        "{name} said something. The words didn't carry, but the tone did.",
        "{name} laughed. In the middle of a fight. The disrespect was the weapon.",
        "A gesture. Not obscene — worse. Dismissive. {name} wanted {opponent} angry.",
        "{name} spat at {opponent}'s feet and waited for the reaction.",
    },
    disarm = {
        "{name}'s hand shot for the wrist. The weapon, not the wielder.",
        "A twist. A wrench. {name} went for the grip, not the man.",
        "{name} caught the weapon arm and redirected. Steel clattered on stone.",
    },
}

-- Era-specific attack overrides (supplement the base pool)
local ERA_ATTACK_OVERRIDES = {
    ancient = {
        strike = {
            "{name} swung like someone who had learned to fight from watching storms.",
            "A raw blow. The ancient world had no word for technique — only for damage.",
            "{name} hit with the patience of geology. Slow. Inevitable.",
        },
        grab = {
            "{name} grappled like a beast. Technique was centuries away from being invented.",
            "Hands on flesh. The oldest form of argument.",
            "{name} seized hold the way predators do — with everything.",
        },
        headbutt = {
            "{name} used the oldest weapon. The skull remembers what the hands forget.",
            "Forehead to bone. The ancient arithmetic.",
            "Before blades, before tools, there was this. {name} proved it still worked.",
        },
    },
    iron = {
        strike = {
            "Trained. Drilled. {name}'s form was a product of ten thousand repetitions.",
            "{name} struck with military precision. The iron age forged soldiers, not brawlers.",
            "A disciplined blow. The drill sergeant would have approved.",
        },
        counter = {
            "{name} parried like a soldier — by the book, and the book was written in blood.",
            "Textbook counter. The iron age valued doctrine over inspiration.",
            "{name} turned the attack aside the way recruits are taught. Efficiently.",
        },
        disarm = {
            "{name} executed a disarm that belonged in a training manual.",
            "A practiced twist. The weapon left {opponent}'s hand by procedure, not luck.",
            "{name} stripped the weapon with the precision of a drill.",
        },
    },
    dark = {
        dirty = {
            "{name} fought like someone with nothing left to lose. Honor was a luxury of the fed.",
            "Rules were for eras that could afford them. {name} could not.",
            "Dirt, spit, nails. The dark age's contribution to martial philosophy.",
        },
        clinch = {
            "{name} held on. In the dark era, holding on was a form of victory.",
            "They tangled like two drowning things. The dark age produced survivors, not victors.",
            "{name} clung. In lean times, even fighting is rationed.",
        },
        gouge = {
            "The dark era produced fighters, not fencers. {name} proved it.",
            "{name} went for the eyes. The dark age stripped combat to its essentials.",
            "Nothing pretty. Nothing clean. {name} fought the way the starving eat.",
        },
    },
    arcane = {
        feint = {
            "{name} moved like smoke. The arcane era valued deception over force.",
            "A false opening that would have fooled a mirror. The arcane school taught lies first.",
            "{name} showed something that wasn't there. The arcane era's favorite trick.",
        },
        taunt = {
            "The words {name} used were old. Older than the feud. They cut deeper than steel.",
            "{name} spoke in the arcane tongue. The syllables were weapons in themselves.",
            "A phrase calculated to wound. The arcane era weaponized language.",
        },
        counter = {
            "{name} read the attack like reading a text. The counter was academic.",
            "Analysis. Prediction. Exploitation. {name} fought with their mind first.",
            "{name} countered as if they'd seen the attack before — in a book, probably.",
        },
    },
    gilded = {
        strike = {
            "{name}'s form was exquisite. The gilded era demanded beauty even in violence.",
            "An elegant blow. In the gilded age, even brutality wore silk.",
            "{name} struck with flourish. The spectators mattered as much as the opponent.",
        },
        feint = {
            "A feint worthy of the salon. {name} had been trained by masters of the art.",
            "Deception as performance. {name} made the lie look better than the truth.",
            "A false move so refined it deserved applause. The gilded age in miniature.",
        },
        disarm = {
            "{name} removed the weapon with a flourish. The gallery would have applauded.",
            "A technical disarm that was also, somehow, a compliment. The gilded way.",
            "{name} stripped the blade with the courtesy of a dancing partner.",
        },
    },
    twilight = {
        lunge = {
            "{name} lunged as if the world was ending. In the twilight era, it was.",
            "All forward. No reserve. The twilight demands total investment.",
            "{name} threw themselves at {opponent} like a final argument.",
        },
        headbutt = {
            "No ceremony. No art. {name} used what was left. The twilight strips everything to bone.",
            "The last era has no time for technique. {name} used their skull.",
            "Raw. Desperate. The twilight reduced all combat to its original currency.",
        },
        strike = {
            "{name} hit like someone who understood that this might be the last fight anyone remembers.",
            "A blow that carried the weight of finality. The twilight era's signature.",
            "{name} swung as if time was running out. In the twilight, it always is.",
        },
    },
}

-- ═══════════════════════════════════════════════════════
-- IMPACT FRAGMENTS — what happened when it landed (or didn't)
-- ═══════════════════════════════════════════════════════

local IMPACT_FRAGMENTS = {
    hit_clean = {
        "It landed clean. The sound was worse than the sight.",
        "Solid contact. The kind you feel in your own teeth watching.",
        "It connected. Something gave.",
        "A clean hit. The debt was paid in bone.",
    },
    hit_glancing = {
        "It caught the edge. Enough to count, not enough to finish.",
        "Glancing. {opponent} turned with it — instinct, not skill.",
        "Partial contact. The interest, not the principal.",
    },
    miss = {
        "Air. {name} hit nothing but their own exhaustion.",
        "It went wide. The miss cost more than a hit would have.",
        "Empty space where {opponent} used to be.",
    },
    blocked = {
        "{opponent} caught it on the forearm. It would bruise tomorrow. If there was a tomorrow.",
        "Blocked. {opponent} absorbed it the way foundations absorb earthquakes.",
        "{opponent} took it on the shoulder. The price of not being fast enough to avoid it entirely.",
    },
    countered = {
        "{opponent} was already moving. The counter arrived before the attack finished.",
        "Read. Punished. {opponent} turned {name}'s aggression into a receipt.",
        "{opponent} stepped inside the arc and made {name} regret the commitment.",
    },
}

-- ═══════════════════════════════════════════════════════
-- REACTION FRAGMENTS — defender response after impact
-- ═══════════════════════════════════════════════════════

local REACTION_FRAGMENTS = {
    stagger = {
        "{opponent} staggered. Caught the fall before it became a collapse.",
        "The knees bent wrong. {opponent} stayed up through pure stubbornness.",
        "{opponent} lurched. The ground was suddenly less reliable than it had been.",
    },
    absorb = {
        "{opponent} took it. Didn't flinch. The kind of endurance that is its own threat.",
        "No reaction. {opponent} absorbed it like the cost of doing business.",
    },
    buckle = {
        "{opponent}'s legs betrayed them for half a second. Long enough.",
        "Something cracked or shifted. {opponent} folded at the middle before recovering.",
    },
    reel = {
        "{opponent} went back three steps. Each one a negotiation with gravity.",
        "The blow sent {opponent} reeling. The wall caught what the legs couldn't.",
    },
    reset = {
        "{opponent} shook it off. Circled. Reset.",
        "A step back. A breath. {opponent} was still in this.",
    },
}

-- ═══════════════════════════════════════════════════════
-- FATIGUE FRAGMENTS
-- ═══════════════════════════════════════════════════════

local FATIGUE_FRAGMENTS = {
    "Both breathed like bellows now. The body's invoice was coming due.",
    "{name}'s arms hung heavier. Exhaustion is the great equalizer.",
    "The movements slowed. What began as combat was becoming endurance.",
    "Sweat and blood made the same color in the dirt.",
    "{name}'s guard dropped an inch. In a fight, an inch is a mile.",
    "The tank was empty. {name} was running on something older than stamina.",
    "Neither could maintain the pace. The body has its own accounting.",
    "Ragged breathing. The fight was entering its final audit.",
}

-- ═══════════════════════════════════════════════════════
-- FINISH FRAGMENTS — by margin and stakes
-- ═══════════════════════════════════════════════════════

local FINISH_FRAGMENTS = {
    -- Winner descriptions
    winner_dominant = {
        "It wasn't close. {winner} dismantled {loser} with the efficiency of a foreclosure.",
        "{winner} stood over {loser}. The verdict was not in question.",
        "A comprehensive accounting. {winner} collected every debt.",
    },
    winner_narrow = {
        "{winner} won. Barely. The kind of victory that feels like a warning.",
        "It could have gone either way. It went {winner}'s way — this time.",
        "{winner} prevailed by the thinnest margin the bloodline had ever witnessed.",
    },
    -- Loser descriptions
    loser_collapse = {
        "{loser} went down and stayed down. The ground received them like an old friend.",
        "{loser} fell the way empires do — slowly, then all at once.",
        "{loser} collapsed. The body's final assessment was unanimous.",
    },
    loser_retreat = {
        "{loser} yielded. Wise, perhaps. The alternative was the floor.",
        "{loser} stepped back and raised a hand. The fight was over. The humiliation was not.",
    },
    draw = {
        "Neither fell. Neither won. The bloodlines watched and drew no conclusions.",
        "They separated by mutual exhaustion. No winner. No lesson. Just damage.",
        "A draw. The worst outcome — all the cost, none of the closure.",
    },
    -- Stakes-specific finishes
    blood_finish = {
        "{loser} did not get up. The blood pooled in the silence that followed.",
        "It ended the way blood feuds end — with blood. {loser} paid the final premium.",
    },
    trial_finish = {
        "The gods — or whatever passes for gods in {realm} — had spoken. {winner} was judged righteous.",
        "The trial was over. {winner} stood vindicated. Whether justice was served was a question for theologians.",
    },
    honor_finish = {
        "First blood was drawn. The honor was satisfied, if not the hatred.",
        "The duel concluded according to the forms. {winner}'s honor was restored. The wound would heal. The grudge would not.",
    },
}

-- ═══════════════════════════════════════════════════════
-- ROUND BREAKS
-- ═══════════════════════════════════════════════════════

local ROUND_BREAKS = {
    "A pause. Both circled. The air between them was a negotiation.",
    "They separated. Measured each other again. Found new reasons to continue.",
    "A breath. Two. The next exchange would be different.",
    "The distance reopened. Both recalculated.",
    "A moment of stillness. The violence was reviewing its notes.",
    "They reset. The blood on the ground belonged to both of them now.",
}

-- ═══════════════════════════════════════════════════════
-- WEAPON PROSE
-- ═══════════════════════════════════════════════════════

local WEAPON_INTRO = {
    "{name} held {weapon}. The weight of it changed the mathematics.",
    "{weapon} caught the light in {name}'s grip. Named weapons carry their own expectations.",
    "{name} drew {weapon}. It had tasted blood before.",
}

local WEAPON_LOST = {
    "{loser_name}'s weapon clattered away. Bare hands now. The arithmetic shifted.",
    "{weapon} spun across the ground. {loser_name} was unarmed and recalculating.",
}

-- ═══════════════════════════════════════════════════════
-- PERSONALITY COLOR — extra flavor lines
-- ═══════════════════════════════════════════════════════

local PERSONALITY_COLOR = {
    bold   = { "No hesitation. {name} treated caution as a character flaw." },
    cruel  = { "There was enjoyment in {name}'s eyes. The fight was recreation." },
    volatile = { "{name} switched between fury and calm like weather." },
    proud  = { "{name} refused to acknowledge the pain. Pride is its own anesthetic." },
    adaptive = { "{name} adjusted. Every exchange taught them something." },
    loyal  = { "{name} fought for someone who wasn't here. That kind of fuel burns longer." },
}

-- ═══════════════════════════════════════════════════════
-- DEBUFF / SPECIAL MOVE PROSE
-- ═══════════════════════════════════════════════════════

local SPECIAL_PROSE = {
    taunt_success = {
        "{opponent}'s jaw tightened. The taunt landed deeper than any fist could.",
        "The words found their mark. {opponent}'s next move would be angry, not smart.",
    },
    disarm_success = {
        "The weapon left {opponent}'s hand. Not voluntarily.",
        "{opponent} reached for a weapon that was no longer there.",
    },
    headbutt_self = {
        "{name}'s vision swam. The headbutt cost both of them.",
        "Both heads rang. {name} paid the surcharge on their own attack.",
    },
    brace_absorb = {
        "{name} absorbed it. Planted and immovable. The damage was halved by sheer will.",
        "The brace held. {name} took the blow like a cornerstone takes the weather.",
    },
    relic_strike = {
        "{weapon} sang. Named weapons remember every fight they've been in.",
        "The relic bit deep. {weapon} earned its name again.",
    },
}

-- ═══════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════

--- Generate sizing-up beats for a combatant.
---@param combatant table Fighter data
---@param opponent table Other fighter
---@param rng function Seeded RNG
---@param era string|nil Current era
---@return table[] beats
function Templates.sizing_up(combatant, opponent, rng, era)
    local beats = {}
    local vars = { name = combatant.name, opponent = opponent.name }

    -- Pick by dominant stat
    local stats = { power = combatant.power or 50, speed = combatant.speed or 50,
                    cunning = combatant.cunning or 50, grit = combatant.grit or 50 }
    local best_stat, best_val = "power", 0
    for k, v in pairs(stats) do
        if v > best_val then best_stat = k; best_val = v end
    end
    local pool = SIZING_UP[best_stat .. "_high"]
    if pool then
        beats[#beats + 1] = {
            text = sub(pick(pool, rng), vars),
            delay = 1200, color = "parchment", intensity = 1,
        }
    end

    -- Body state or personality color
    local ptag = combatant.personality_tag
    local traits = combatant.traits or {}
    local color_pool = nil
    for _, t in ipairs(traits) do
        if SIZING_UP[t] then color_pool = SIZING_UP[t]; break end
    end
    if not color_pool and ptag and SIZING_UP[ptag] then
        color_pool = SIZING_UP[ptag]
    end
    if color_pool then
        beats[#beats + 1] = {
            text = sub(pick(color_pool, rng), vars),
            delay = 900, color = "ember", intensity = 1,
        }
    end

    -- Nemesis flavor
    if combatant.is_nemesis or opponent.is_nemesis then
        beats[#beats + 1] = {
            text = sub(pick(SIZING_UP.nemesis, rng), vars),
            delay = 1000, color = "blood", intensity = 2,
        }
    end

    return beats
end

--- Generate terrain intro beat.
---@param terrain string Terrain type
---@param combatant table Protagonist
---@param rng function Seeded RNG
---@return table|nil beat
function Templates.terrain_intro(terrain, combatant, rng)
    local pool = TERRAIN_INTROS[terrain]
    if not pool then return nil end
    return {
        text = sub(pick(pool, rng), { name = combatant.name }),
        delay = 1100, color = "parchment", intensity = 1,
    }
end

--- Generate weapon intro beat.
---@param combatant table Fighter with weapon/relic
---@param rng function Seeded RNG
---@return table|nil beat
function Templates.weapon_intro(combatant, rng)
    if not combatant.weapon and not combatant.relic then return nil end
    local wname = combatant.relic and combatant.relic.name or
                  (combatant.weapon and combatant.weapon.label or "a weapon")
    return {
        text = sub(pick(WEAPON_INTRO, rng), { name = combatant.name, weapon = wname }),
        delay = 1000, color = "ember", intensity = 1,
    }
end

--- Generate attack + impact + reaction beats for an exchange.
---@param attacker table Combatant
---@param defender table Combatant
---@param move_id string Attack move used
---@param outcome string "hit"|"miss"|"blocked"|"countered"
---@param damage number Damage dealt
---@param rng function Seeded RNG
---@param era string|nil Current era
---@return table[] beats
function Templates.attack_beat(attacker, defender, move_id, outcome, damage, rng, era)
    local beats = {}
    local vars = { name = attacker.name, opponent = defender.name }

    -- Attack fragment (prefer era-specific, fall back to base)
    local atk_pool = ATTACK_FRAGMENTS[move_id] or ATTACK_FRAGMENTS.strike
    if era and ERA_ATTACK_OVERRIDES[era] and ERA_ATTACK_OVERRIDES[era][move_id] then
        -- 40% chance to use era-specific fragment
        if rng(10) <= 4 then
            atk_pool = ERA_ATTACK_OVERRIDES[era][move_id]
        end
    end
    beats[#beats + 1] = {
        text = sub(pick(atk_pool, rng), vars),
        delay = 700, color = "parchment", intensity = 1,
    }

    -- Impact fragment
    local impact_key = outcome == "hit" and (damage >= 12 and "hit_clean" or "hit_glancing")
                       or outcome
    local impact_pool = IMPACT_FRAGMENTS[impact_key] or IMPACT_FRAGMENTS.miss
    local impact_color = damage >= 14 and "blood" or (damage >= 8 and "ember" or "parchment")
    beats[#beats + 1] = {
        text = sub(pick(impact_pool, rng), vars),
        delay = damage >= 12 and 500 or 350,
        color = impact_color,
        vfx = damage >= 16 and "shake" or nil,
        intensity = damage >= 14 and 3 or (damage >= 8 and 2 or 1),
    }

    -- Reaction fragment (skip on miss)
    if outcome ~= "miss" and damage > 0 then
        local react_key = damage >= 14 and "buckle"
                         or damage >= 10 and "stagger"
                         or damage >= 6 and "reel"
                         or "absorb"
        -- Low damage on block = reset
        if outcome == "blocked" then react_key = "reset" end

        local react_pool = REACTION_FRAGMENTS[react_key] or REACTION_FRAGMENTS.reset
        beats[#beats + 1] = {
            text = sub(pick(react_pool, rng), { name = defender.name, opponent = attacker.name }),
            delay = damage >= 12 and 900 or 650,
            color = "parchment", intensity = 1,
        }
    end

    -- Relic weapon flavor (10% chance on hit with relic)
    if outcome == "hit" and attacker.relic and rng(10) == 1 then
        local wname = attacker.relic.name
        beats[#beats + 1] = {
            text = sub(pick(SPECIAL_PROSE.relic_strike, rng), { weapon = wname }),
            delay = 600, color = "ember", intensity = 2,
        }
    end

    return beats
end

--- Generate special move prose (taunt, disarm, headbutt self-damage, brace absorb).
---@param move_id string
---@param attacker table
---@param defender table
---@param rng function
---@return table|nil beat
function Templates.special_beat(move_id, attacker, defender, rng)
    local vars = { name = attacker.name, opponent = defender.name }

    if move_id == "taunt" and SPECIAL_PROSE.taunt_success then
        return {
            text = sub(pick(SPECIAL_PROSE.taunt_success, rng), vars),
            delay = 800, color = "ember", intensity = 1,
        }
    elseif move_id == "disarm" and SPECIAL_PROSE.disarm_success then
        local wname = defender.weapon and defender.weapon.label or "the weapon"
        return {
            text = sub(pick(SPECIAL_PROSE.disarm_success, rng), { opponent = defender.name, weapon = wname }),
            delay = 800, color = "ember", intensity = 2,
        }
    elseif move_id == "headbutt" and SPECIAL_PROSE.headbutt_self then
        return {
            text = sub(pick(SPECIAL_PROSE.headbutt_self, rng), vars),
            delay = 600, color = "ember", intensity = 1,
        }
    elseif move_id == "brace" and SPECIAL_PROSE.brace_absorb then
        return {
            text = sub(pick(SPECIAL_PROSE.brace_absorb, rng), vars),
            delay = 700, color = "parchment", intensity = 1,
        }
    end
    return nil
end

--- Generate fatigue beat.
---@param combatant table
---@param rng function
---@return table beat
function Templates.fatigue_beat(combatant, rng)
    return {
        text = sub(pick(FATIGUE_FRAGMENTS, rng), { name = combatant.name }),
        delay = 1000, color = "ember", intensity = 1,
    }
end

--- Generate round break beat.
---@param round number
---@param rng function
---@return table beat
function Templates.round_break(round, rng)
    return {
        text = pick(ROUND_BREAKS, rng),
        delay = 1400, color = "parchment", intensity = 1,
    }
end

--- Generate fight conclusion beats.
---@param winner table|nil Winner combatant (nil = draw)
---@param loser table|nil Loser combatant
---@param margin string "dominant"|"narrow"|"draw"
---@param stakes table|nil Stakes context
---@param rng function
---@return table[] beats
function Templates.finish_beat(winner, loser, margin, stakes, rng)
    local beats = {}
    local stakes_type = stakes and stakes.type or "honor"

    if margin == "draw" then
        beats[#beats + 1] = {
            text = pick(FINISH_FRAGMENTS.draw, rng),
            delay = 1400, color = "parchment", intensity = 2,
        }
        return beats
    end

    local realm = "Caldemyr"
    pcall(function()
        local wid = require("dredwork_world.config.world_identity")
        if wid and wid.world_name then realm = wid.world_name end
    end)
    local vars = { winner = winner and winner.name or "?", loser = loser and loser.name or "?", realm = realm }

    -- Winner line
    local win_pool = margin == "dominant" and FINISH_FRAGMENTS.winner_dominant or FINISH_FRAGMENTS.winner_narrow
    beats[#beats + 1] = {
        text = sub(pick(win_pool, rng), vars),
        delay = 1200, color = margin == "dominant" and "blood" or "ember",
        intensity = margin == "dominant" and 3 or 2,
    }

    -- Loser line
    local lose_pool = margin == "dominant" and FINISH_FRAGMENTS.loser_collapse or FINISH_FRAGMENTS.loser_retreat
    beats[#beats + 1] = {
        text = sub(pick(lose_pool, rng), vars),
        delay = 1000, color = "parchment", intensity = 1,
    }

    -- Stakes-specific finish
    local stakes_pool = FINISH_FRAGMENTS[stakes_type .. "_finish"]
    if stakes_pool then
        beats[#beats + 1] = {
            text = sub(pick(stakes_pool, rng), vars),
            delay = 1400, color = "blood", intensity = 2,
        }
    end

    -- Personality coda (winner's personality colors the ending)
    if winner and winner.personality_tag and PERSONALITY_COLOR[winner.personality_tag] then
        if rng(3) == 1 then  -- 33% chance for extra flavor
            beats[#beats + 1] = {
                text = sub(pick(PERSONALITY_COLOR[winner.personality_tag], rng), { name = winner.name }),
                delay = 900, color = "parchment", intensity = 1,
            }
        end
    end

    return beats
end

--- Generate disarm prose.
---@param loser_name string Fighter who lost the weapon
---@param weapon table Weapon that was lost
---@param rng function
---@return table beat
function Templates.weapon_lost_beat(loser_name, weapon, rng)
    local wname = weapon and weapon.label or "the weapon"
    return {
        text = sub(pick(WEAPON_LOST, rng), { loser_name = loser_name, weapon = wname }),
        delay = 900, color = "ember", intensity = 2,
    }
end

return Templates
