-- dredwork Career — What You Do To Survive
-- Your cover. Your income. Your place in the world.
-- The higher you climb, the more you have to lose when the truth comes out.
--
-- 6 occupations, 5 tiers each. Work actions at specific locations.
-- Career rank affects how NPCs treat you, what doors open, and how much you earn.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Career = {}
Career.__index = Career

local OCCUPATIONS = {
    laborer = {
        label = "Laborer",
        desc = "Honest work. Hard hands. Nobody looks twice at a laborer.",
        location = "market",     -- where you work
        titles = { "Hand", "Foreman's Runner", "Yard Boss", "Gang Chief", "Master of Stone" },
        base_income = 2,
        personality_bonus = { PER_BLD = 0.02 },  -- what grows from this work
        starting = { rank = 11, income = 12, stability = 45 },
    },
    scribe = {
        label = "Scribe",
        desc = "Letters. Ledgers. Secrets pass through your hands daily.",
        location = "court",
        titles = { "Copyist", "Clerk", "Record-Keeper", "Archivist", "Master of Accounts" },
        base_income = 3,
        personality_bonus = { PER_OBS = 0.02 },
        starting = { rank = 14, income = 14, stability = 47 },
    },
    soldier = {
        label = "Soldier",
        desc = "A blade for hire. Dangerous, respected, and expendable.",
        location = "barracks",
        titles = { "Blade for Hire", "Sergeant's Hand", "Captain's Dog", "Raid Leader", "War-Captain" },
        base_income = 3,
        personality_bonus = { PER_BLD = 0.03 },
        starting = { rank = 15, income = 13, stability = 36 },
    },
    courtier = {
        label = "Courtier",
        desc = "Whispers are currency. You trade in influence and proximity to power.",
        location = "court",
        titles = { "Attendant", "Whisper-Bearer", "House Favorite", "Chamber Voice", "Court Fixer" },
        base_income = 3,
        personality_bonus = { PER_LOY = 0.02 },
        starting = { rank = 13, income = 15, stability = 35 },
    },
    tinker = {
        label = "Tinker",
        desc = "You fix things. Useful. Invisible. People trust a tinker in their home.",
        location = "market",
        titles = { "Patcher", "Maker", "Workshop Hand", "Device-Smith", "Master Tinker" },
        base_income = 2,
        personality_bonus = { PER_CUR = 0.02 },
        starting = { rank = 12, income = 13, stability = 40 },
    },
    performer = {
        label = "Performer",
        desc = "Entertainment is access. Every hall, every feast — you're invited.",
        location = "tavern",
        titles = { "Player", "Room Favorite", "Salon Fixture", "House Entertainer", "Voice of the Season" },
        base_income = 1,
        personality_bonus = { PER_ADA = 0.02 },
        starting = { rank = 12, income = 12, stability = 34 },
    },
}

-- Work action flavor text per occupation
local WORK_TEXTS = {
    laborer = {
        triumph = {
            "The foreman watches you work. Nods slowly. You've earned something today — not just coin.",
            "Your hands know the stone now. The rhythm is second nature. People notice competence.",
        },
        success = {
            "A day's work. Honest. Your back aches but the coin is real.",
            "You haul, you lift, you build. The work doesn't care who your father was.",
        },
        failure = {
            "A beam slips. Crashes. Nobody hurt, but the foreman marks it. You feel the mark.",
            "The day drags. Your mind is elsewhere. The work suffers. So does the pay.",
        },
        disaster = {
            "Something breaks. Something expensive. The foreman's face says everything. Don't come tomorrow.",
            "An injury. Not serious, but enough. You limp home with half-pay and a reminder.",
        },
    },
    scribe = {
        triumph = {
            "You find a discrepancy in the accounts that saves someone important a fortune. They remember your name.",
            "Your hand is steady. Your eye is sharp. The archivist calls your work 'exemplary.' That word opens doors.",
        },
        success = {
            "Ink and parchment. The scratch of the quill. The hours vanish into letters.",
            "You copy, you file, you organize. The work is quiet. The knowledge is not.",
        },
        failure = {
            "A transcription error. Small but visible. You catch it. Barely.",
            "The records blur. Your focus slips. The correction takes twice as long as the original.",
        },
        disaster = {
            "An important document, ruined. Ink spilled. The look on the clerk's face — you won't sleep tonight.",
            "Someone noticed the error before you did. That's worse. That's how you lose a position.",
        },
    },
    soldier = {
        triumph = {
            "You disarm three in practice. The sergeant stops to watch. 'Where did you learn that?'",
            "A real skirmish at the border. You held the line. The captain makes a point of learning your name.",
        },
        success = {
            "Drill. Patrol. The weight of the blade is familiar now. You're getting good at this.",
            "Guard duty. Nothing happens. That's a successful day — the kind where nobody dies.",
        },
        failure = {
            "You're slow. The blow lands. Practice blade, but it still hurts. The lesson hurts more.",
            "Missed your post. The sergeant has words. The words have consequences.",
        },
        disaster = {
            "A real fight. You hesitate. Someone else pays for it. Not dead, but close. That's on you.",
            "Insubordination. You didn't mean it that way, but meaning doesn't matter. Discipline does.",
        },
    },
    courtier = {
        triumph = {
            "A whisper in the right ear at the right time. The whole room shifts. You shifted it.",
            "They invite you to the inner table. Not because of your name. Because of what you know.",
        },
        success = {
            "You listen. You smile. You remember everything. The court is a game and you're learning the rules.",
            "An introduction here. A compliment there. The web grows. Slowly. That's how webs grow.",
        },
        failure = {
            "You misjudge a tone. Say the wrong thing to the wrong person. The silence after is instructive.",
            "Someone else gets the introduction you needed. Timing. It's always timing.",
        },
        disaster = {
            "You're frozen out. The inner circle closes. Whatever you said, it was the wrong thing. Loudly.",
            "A rumor starts. About you. You don't know who started it, but you know why.",
        },
    },
    tinker = {
        triumph = {
            "You fix something nobody else could. The mechanism clicks. The owner's face — that's payment beyond coin.",
            "A commission from someone important. Your reputation grows one repaired lock at a time.",
        },
        success = {
            "Mend, patch, repair. The work is honest and the results are visible. That's more than most can say.",
            "A morning of small fixes. A clock, a hinge, a buckle. Each one a tiny restoration of order.",
        },
        failure = {
            "The mechanism breaks again. Worse than before. The customer isn't happy. You aren't either.",
            "Parts cost more than the job pays. You eat the loss. It tastes like copper.",
        },
        disaster = {
            "Something you fixed fails at the worst moment. Nobody's hurt. But the word spreads. That word is expensive.",
            "A fire. Small. From your forge. Contained, but the neighbors saw. Trust is fragile.",
        },
    },
    performer = {
        triumph = {
            "The room is silent. Not bored — captivated. When you finish, the applause is real. Someone wants to book you.",
            "A private performance for someone who matters. By the end, they're leaning forward. You have a patron.",
        },
        success = {
            "The crowd claps. Some of them mean it. The coin is decent. The evening is warm.",
            "You play. You sing. You tell the story. The tavern forgets its troubles for an hour.",
        },
        failure = {
            "The crowd is restless. You lose the room. The innkeeper doesn't say anything. That's worse.",
            "A bad night. Wrong song for the wrong crowd. The tips are thin.",
        },
        disaster = {
            "They throw things. Not aggressively — dismissively. That's the cruelest audience.",
            "A patron demands something you can't deliver. The refusal costs you the venue.",
        },
    },
}

function Career.init(engine)
    local self = setmetatable({}, Career)
    self.engine = engine

    engine.game_state.career = engine.game_state.career or {
        occupation = nil,       -- string key
        rank = 0,               -- 0-100
        income = 0,             -- quality of earnings
        stability = 0,          -- job security
        title = "Unknown",
        total_work_days = 0,
        last_work_day = 0,
        initialized = false,
    }

    -- Monthly salary payment
    engine:on("NEW_MONTH", function(clock)
        self:pay_monthly(engine.game_state, clock)
    end)

    return self
end

--- Set up the player's starting career.
function Career:setup(occupation_key)
    local gs = self.engine.game_state
    local occ = OCCUPATIONS[occupation_key]
    if not occ then return end

    gs.career.occupation = occupation_key
    gs.career.rank = occ.starting.rank
    gs.career.income = occ.starting.income
    gs.career.stability = occ.starting.stability
    gs.career.title = self:_get_title(occupation_key, occ.starting.rank)
    gs.career.initialized = true
end

--- Perform a work action. Returns { quality, text, gold_earned, rank_change }.
function Career:work(gs)
    local career = gs.career
    if not career.initialized then return nil end

    local occ = OCCUPATIONS[career.occupation]
    if not occ then return nil end

    local day = gs.clock and gs.clock.total_days or 0

    -- Can't work twice in one day
    if career.last_work_day == day then
        return { quality = "none", text = "You've already worked today. Rest.", gold_earned = 0 }
    end

    -- Determine quality (weighted by rank and stability)
    local roll = RNG.range(1, 100)
    local bonus = math.floor(career.rank * 0.15 + career.stability * 0.1)
    local adjusted = roll + bonus
    local quality
    if adjusted > 90 then quality = "triumph"
    elseif adjusted > 45 then quality = "success"
    elseif adjusted > 20 then quality = "failure"
    else quality = "disaster" end

    -- Apply career progression
    local delta_rank, delta_income, delta_stability = 0, 0, 0
    if quality == "triumph" then
        delta_rank = RNG.range(5, 8); delta_income = RNG.range(4, 7); delta_stability = RNG.range(1, 3)
    elseif quality == "success" then
        delta_rank = RNG.range(2, 5); delta_income = RNG.range(1, 4); delta_stability = RNG.range(0, 2)
    elseif quality == "failure" then
        delta_rank = RNG.range(0, 2); delta_income = RNG.range(-2, 0); delta_stability = RNG.range(-3, -1)
    else -- disaster
        delta_rank = RNG.range(-3, -1); delta_income = RNG.range(-5, -2); delta_stability = RNG.range(-6, -3)
    end

    local old_title = career.title
    career.rank = Math.clamp(career.rank + delta_rank, 0, 100)
    career.income = Math.clamp(career.income + delta_income, 0, 100)
    career.stability = Math.clamp(career.stability + delta_stability, 0, 100)
    career.title = self:_get_title(career.occupation, career.rank)
    career.total_work_days = career.total_work_days + 1
    career.last_work_day = day

    -- Gold earned
    local base = occ.base_income or 3
    local gold = 0
    if quality == "triumph" then gold = base + RNG.range(2, 5)
    elseif quality == "success" then gold = base + RNG.range(0, 2)
    elseif quality == "failure" then gold = math.max(1, base - 1)
    else gold = 0 end

    -- Apply gold to personal wealth
    local entities = self.engine:get_module("entities")
    local focal = entities and entities:get_focus()
    if focal and focal.components.personal_wealth and gold > 0 then
        local WealthLib = require("dredwork_agency.wealth")
        WealthLib.change(focal.components.personal_wealth, gold, "day's work as " .. career.title)
    end

    -- Personality growth from work
    if focal and focal.components.personality and occ.personality_bonus then
        for trait, rate in pairs(occ.personality_bonus) do
            local val = focal.components.personality[trait]
            if type(val) == "number" then
                focal.components.personality[trait] = Math.clamp(val + rate, 0, 100)
            elseif type(val) == "table" and val.value then
                val.value = Math.clamp(val.value + rate, 0, 100)
            end
        end
    end

    -- Get flavor text
    local texts = WORK_TEXTS[career.occupation] and WORK_TEXTS[career.occupation][quality]
    local text = texts and RNG.pick(texts) or ("You work. " .. quality .. ".")

    -- Title promotion event
    local promoted = career.title ~= old_title and career.rank > (career.rank - delta_rank)
    if promoted then
        text = text .. "\n\nYou are " .. career.title .. " now."
        self.engine:push_ui_event("NARRATIVE_BEAT", {
            channel = "whispers",
            text = "The work names you differently now: " .. career.title .. ".",
            priority = 70,
            display_hint = "pattern",
            tags = { "career", "promotion" },
            timestamp = day,
        })
        self.engine:emit("CAREER_PROMOTED", {
            occupation = career.occupation,
            old_title = old_title,
            new_title = career.title,
            rank = career.rank,
        })
    end

    -- Emit for other systems
    self.engine:emit("WORK_PERFORMED", {
        occupation = career.occupation,
        quality = quality,
        gold = gold,
        rank = career.rank,
    })

    return {
        quality = quality,
        text = text,
        gold_earned = gold,
        rank_change = delta_rank,
        promoted = promoted,
    }
end

--- Monthly salary based on career income level.
function Career:pay_monthly(gs, clock)
    local career = gs.career
    if not career.initialized then return end

    local entities = self.engine:get_module("entities")
    local focal = entities and entities:get_focus()
    if not focal or not focal.components.personal_wealth then return end

    -- Monthly stipend based on income score (not per-day work)
    local monthly = math.floor(career.income * 0.15)
    if monthly > 0 then
        local WealthLib = require("dredwork_agency.wealth")
        WealthLib.change(focal.components.personal_wealth, monthly, "monthly earnings as " .. career.title)
    end
end

--- Get career tier (1-5) from rank.
function Career:get_tier(gs)
    gs = gs or self.engine.game_state
    local rank = gs.career.rank or 0
    if rank >= 82 then return 5
    elseif rank >= 66 then return 4
    elseif rank >= 50 then return 3
    elseif rank >= 34 then return 2
    elseif rank >= 20 then return 1
    end
    return 0  -- unformed
end

function Career:get_occupation_def(key)
    return OCCUPATIONS[key or (self.engine.game_state.career and self.engine.game_state.career.occupation)]
end

function Career:get_all_occupations()
    return OCCUPATIONS
end

function Career:get_work_location(gs)
    gs = gs or self.engine.game_state
    local occ = OCCUPATIONS[gs.career.occupation]
    return occ and occ.location
end

function Career:_get_title(occupation_key, rank)
    local occ = OCCUPATIONS[occupation_key]
    if not occ then return "Unknown" end
    if rank < 20 then return "Unformed" end
    if rank >= 82 then return occ.titles[5]
    elseif rank >= 66 then return occ.titles[4]
    elseif rank >= 50 then return occ.titles[3]
    elseif rank >= 34 then return occ.titles[2]
    end
    return occ.titles[1]
end

function Career:serialize() return self.engine.game_state.career end
function Career:deserialize(data) self.engine.game_state.career = data end

return Career
