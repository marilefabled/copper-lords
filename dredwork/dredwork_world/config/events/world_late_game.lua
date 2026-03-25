-- Bloodweight — World Events: Late-Game Escalation
-- Events that only fire in the back half of a dynasty (gen 40+).
-- These reflect the accumulated weight of history pressing down on the bloodline.
return {
    -- ═══════════════════════════════════════════════════════
    -- THE THINNING (gen 40+) — genetic diversity narrows
    -- ═══════════════════════════════════════════════════════
    {
        id = "the_thinning",
        title = "The Thinning",
        narrative = "The healers have noticed a pattern. The children grow more alike with each generation. Fingers the same length. Eyes the same depth. The blood is narrowing — and what narrows, breaks.",
        chance = 0.50,
        cooldown = 12,
        requires_generation_min = 40,
        once_per_run = true,
        options = {
            {
                label = "Seek outside blood",
                description = "Find mates from distant lands. Dilute the concentration before it kills.",
                consequences = {
                    cultural_memory_shift = { physical = -3, social = 3 },
                    lineage_power_shift = -5,
                    mutation_pressure_reduction = 15,
                    narrative = "Distant marriages were arranged. The children born were strange and healthy. The bloodline widened, and the old patterns thinned.",
                },
            },
            {
                label = "Embrace the purity",
                description = "The narrowing is refinement. The bloodline is becoming what it was always meant to be.",
                requires = { axis = "PER_OBS", min = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 2, mental = 2 },
                    lineage_power_shift = 5,
                    narrative = "The heir chose purity over safety. The children grew sharper, more precise, more fragile. A blade honed too thin cuts both ways.",
                },
            },
            {
                label = "Consult the scholars",
                description = "If the blood is failing, let the learned find a solution.",
                requires_resources = { type = "lore", min = 10 },
                stat_check = {
                    primary = { trait = "MEN_INT", weight = 1.0 },
                    secondary = { trait = "MEN_ANA", weight = 0.5 },
                    difficulty = 55,
                },
                consequences = {
                    resource_change = { type = "lore", delta = -10, reason = "Genetic research" },
                    mutation_pressure_reduction = 10,
                    cultural_memory_shift = { mental = 3 },
                    narrative = "The scholars studied the bloodline's records, generation by generation. Their recommendations were implemented. The worst of the narrowing was arrested — for now.",
                },
                consequences_fail = {
                    resource_change = { type = "lore", delta = -10, reason = "Fruitless research" },
                    narrative = "The scholars studied and debated and produced nothing useful. The lore was spent. The blood continued to narrow.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- THE OLD DEBT (gen 50+) — consequences of ancient choices
    -- ═══════════════════════════════════════════════════════
    {
        id = "the_old_debt",
        title = "The Old Debt",
        narrative = "A document has surfaced — a contract signed generations ago, promising payment that was never rendered. The creditors have waited patiently. Their patience has ended.",
        chance = 0.45,
        cooldown = 15,
        requires_generation_min = 50,
        once_per_run = true,
        options = {
            {
                label = "Honor the debt",
                description = "The ancestors promised. The bloodline pays. Even when the cost is staggering.",
                consequences = {
                    resource_change = {
                        { type = "gold", delta = -20, reason = "Ancestral debt repaid" },
                        { type = "grain", delta = -10, reason = "Provisions surrendered to creditors" },
                    },
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    moral_act = { act_id = "honoring_oath", description = "Honored an ancestral debt generations overdue" },
                    narrative = "The vaults were opened. The debt was paid, coin by coin, bushel by bushel. The creditors left satisfied. The family left hollow.",
                },
            },
            {
                label = "Dispute the contract",
                description = "The document is old. The signatories are dust. Challenge its validity.",
                stat_check = {
                    primary = { trait = "SOC_ELO", weight = 1.0 },
                    secondary = { trait = "MEN_ANA", weight = 0.5 },
                    difficulty = 60,
                },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = -3 } },
                    lineage_power_shift = 8,
                    cultural_memory_shift = { social = 2, mental = 2 },
                    narrative = "The heir spoke before the assembled creditors and dismantled the contract clause by clause. The debt was declared void. The family breathed.",
                },
                consequences_fail = {
                    disposition_changes = { { faction_id = "all", delta = -10 } },
                    lineage_power_shift = -8,
                    resource_change = { type = "gold", delta = -25, reason = "Failed dispute — debt plus penalties" },
                    narrative = "The argument collapsed. The contract was upheld, and the penalties for the challenge were added to the sum. The family paid more than it ever owed.",
                },
            },
            {
                label = "Destroy the evidence",
                description = "The contract is paper. Paper burns.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    moral_act = { act_id = "cruelty", description = "Destroyed evidence of an ancestral debt and silenced the creditors" },
                    disposition_changes = { { faction_id = "all", delta = -8 } },
                    lineage_power_shift = 5,
                    narrative = "The document burned. The messengers were paid to forget. But somewhere, a copy existed. It always does.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- THE WEIGHT DESCENDS (gen 60+) — the bloodline buckles
    -- ═══════════════════════════════════════════════════════
    {
        id = "the_weight_descends",
        title = "The Weight Descends",
        narrative = "The heir wakes screaming. Every ancestor's face, every choice made and unmade, presses down like a millstone. The weight of sixty generations is not a metaphor. It is a physical thing, and it is crushing.",
        chance = 0.55,
        cooldown = 15,
        requires_generation_min = 60,
        once_per_run = true,
        options = {
            {
                label = "Endure it",
                description = "The bloodline has survived worse. Bear the weight. Carry it forward.",
                stat_check = {
                    primary = { trait = "MEN_WIL", weight = 1.0 },
                    secondary = { trait = "PHY_END", weight = 0.5 },
                    difficulty = 55,
                },
                consequences = {
                    cultural_memory_shift = { mental = 3, physical = 2 },
                    lineage_power_shift = 10,
                    narrative = "The heir stood under the weight of every ancestor and did not break. The bloodline endured — not because it was strong, but because it refused to fall.",
                },
                consequences_fail = {
                    cultural_memory_shift = { mental = -3, physical = -2 },
                    lineage_power_shift = -5,
                    narrative = "The weight was too much. The heir buckled. Something in the bloodline cracked — not visibly, but deep, where the roots grow.",
                },
            },
            {
                label = "Let something go",
                description = "The weight is memory. Release some of it. Forget deliberately.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    cultural_memory_shift = { physical = -4, mental = -4, social = -4, creative = -4 },
                    mutation_pressure_reduction = 10,
                    lineage_power_shift = -8,
                    narrative = "The heir sat in silence and let the oldest memories go. Names faded. Faces dissolved. The weight lifted, and something precious was lost.",
                },
            },
            {
                label = "Channel it into rage",
                description = "If the weight will not lift, then let it fuel destruction.",
                requires = { axis = "PER_BLD", min = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 5, social = -3 },
                    lineage_power_shift = 5,
                    moral_act = { act_id = "ruthless_order", description = "Channeled ancestral anguish into violent ambition" },
                    narrative = "The heir screamed back at the dead. The rage became purpose. The purpose became action. The world trembled.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- THE FINAL CLAIM (gen 75+) — legacy at stake
    -- ═══════════════════════════════════════════════════════
    {
        id = "the_final_claim",
        title = "The Final Claim",
        narrative = "A rival house has produced documentation claiming the bloodline's earliest holdings were stolen. If the claim is upheld, seventy-five generations of history become seventy-five generations of theft.",
        chance = 0.50,
        cooldown = 20,
        requires_generation_min = 75,
        once_per_run = true,
        options = {
            {
                label = "Defend the legacy in court",
                description = "Bring every record, every witness, every ancestor's name. The bloodline's history will speak for itself.",
                stat_check = {
                    primary = { trait = "SOC_INF", weight = 1.0 },
                    secondary = { trait = "MEN_INT", weight = 0.5 },
                    tertiary = { trait = "SOC_ELO", weight = 0.3 },
                    difficulty = 60,
                },
                consequences = {
                    lineage_power_shift = 15,
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    cultural_memory_shift = { social = 4, mental = 2 },
                    narrative = "The bloodline's history was laid bare, generation by generation. The claim was dismissed. The rival retreated. Seventy-five generations stood vindicated.",
                },
                consequences_fail = {
                    lineage_power_shift = -15,
                    disposition_changes = { { faction_id = "all", delta = -10 } },
                    narrative = "The defense crumbled. The court ruled against the bloodline. The holdings remain — laws move slowly — but the family's legitimacy has been questioned, and the question will not be forgotten.",
                },
            },
            {
                label = "Pay for silence",
                description = "Gold makes problems disappear. Even seventy-five-generation-old problems.",
                requires_resources = { type = "gold", min = 30 },
                consequences = {
                    resource_change = { type = "gold", delta = -30, reason = "Silencing the claimants" },
                    narrative = "The claimants were bought. The documents were sealed. The truth — whatever it was — was buried under gold.",
                },
            },
            {
                label = "Seize the rival's holdings",
                description = "The best defense is to remove the accuser entirely.",
                requires = { axis = "PER_CRM", min = 55 },
                stat_check = {
                    primary = { trait = "PHY_STR", weight = 1.0 },
                    secondary = { trait = "SOC_INF", weight = 0.5 },
                    difficulty = 55,
                },
                consequences = {
                    resource_change = {
                        { type = "gold", delta = 15, reason = "Seized rival assets" },
                        { type = "steel", delta = 8, reason = "Captured armory" },
                    },
                    disposition_changes = { { faction_id = "all", delta = -12 } },
                    lineage_power_shift = 10,
                    moral_act = { act_id = "cruelty", description = "Destroyed a rival house rather than face their legal claim" },
                    narrative = "The rival house was broken. Their documents burned. Their children scattered. The bloodline's claim stood unchallenged — by the dead, at least.",
                },
                consequences_fail = {
                    lineage_power_shift = -10,
                    disposition_changes = { { faction_id = "all", delta = -15 } },
                    add_condition = { type = "war", intensity = 0.6, duration = 3 },
                    moral_act = { act_id = "cruelty", description = "Failed to destroy a rival house, provoking open war" },
                    narrative = "The assault failed. The rival survived and rallied allies. The bloodline's aggression became evidence of guilt, and the war that followed was fought under that shadow.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- BLOOD MEMORY CRISIS (gen 45+) — cultural memory degrades
    -- ═══════════════════════════════════════════════════════
    {
        id = "blood_memory_crisis",
        title = "The Forgetting",
        narrative = "The elders can no longer remember which ancestor introduced the family's traditions. The children ask why things are done a certain way, and no one can answer. The bloodline is forgetting itself.",
        chance = 0.45,
        cooldown = 10,
        requires_generation_min = 45,
        options = {
            {
                label = "Commission a family history",
                description = "Hire scholars to trace every generation, every choice, every consequence.",
                requires_resources = { type = "lore", min = 8 },
                consequences = {
                    resource_change = { type = "lore", delta = -8, reason = "Commissioning family history" },
                    cultural_memory_shift = { mental = 3, creative = 2 },
                    lineage_power_shift = 5,
                    narrative = "The scholars wrote it all down. Every name, every choice. The children learned who they were, and the forgetting paused.",
                },
            },
            {
                label = "Forge new traditions",
                description = "The old ways are dust. Create new ones. The bloodline is not a museum.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 4, social = 2 },
                    narrative = "The old traditions were swept away and replaced with new rituals, new stories, new reasons. Whether they were better was beside the point — they were alive.",
                },
            },
            {
                label = "Let the forgetting come",
                description = "Memory is weight. Let the dead stay dead.",
                consequences = {
                    cultural_memory_shift = { physical = -2, mental = -2, social = -2, creative = -2 },
                    mutation_pressure_reduction = 5,
                    narrative = "The family stopped trying to remember. The old stories faded. The weight lifted — but so did something irreplaceable.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- THE LAST STAND (gen 80+) — existential threat
    -- ═══════════════════════════════════════════════════════
    {
        id = "the_last_stand",
        title = "The Last Stand",
        narrative = "Everything converges. The enemies at the gate. The plague in the streets. The famine in the stores. The heir looks out at the ruins of eighty generations and knows this is the moment the bloodline either endures forever or ends in a single night.",
        chance = 0.50,
        cooldown = 20,
        requires_generation_min = 80,
        once_per_run = true,
        options = {
            {
                label = "Rally everything",
                description = "Every resource, every ally, every scrap of strength the bloodline has left. All of it. Now.",
                stat_check = {
                    primary = { trait = "MEN_WIL", weight = 1.0 },
                    secondary = { trait = "SOC_INF", weight = 0.6 },
                    tertiary = { trait = "PHY_END", weight = 0.4 },
                    difficulty = 65,
                },
                consequences = {
                    resource_change = {
                        { type = "gold", delta = -15, reason = "Desperate mobilization" },
                        { type = "steel", delta = -10, reason = "Arming the final defense" },
                    },
                    lineage_power_shift = 20,
                    disposition_changes = { { faction_id = "all", delta = 10 } },
                    cultural_memory_shift = { physical = 3, mental = 3, social = 3 },
                    narrative = "The bloodline stood. Everything was spent — gold, steel, pride, fear. And when the dust settled, the family was still standing. Diminished. Exhausted. Alive.",
                },
                consequences_fail = {
                    resource_change = {
                        { type = "gold", delta = -15, reason = "Failed mobilization" },
                        { type = "steel", delta = -10, reason = "Lost armaments" },
                    },
                    lineage_power_shift = -20,
                    cultural_memory_shift = { physical = -3, social = -3 },
                    narrative = "The bloodline rallied and fell short. The resources were gone. The allies scattered. What remained was a family too stubborn to die but too weak to live.",
                },
            },
            {
                label = "Sacrifice the holdings",
                description = "Burn it all. The land, the estates, the legacy. Let the family survive even if nothing else does.",
                consequences = {
                    resource_change = {
                        { type = "gold", delta = -10, reason = "Abandoned holdings" },
                    },
                    lineage_power_shift = -15,
                    cultural_memory_shift = { physical = -2, social = -4 },
                    mutation_pressure_reduction = 8,
                    narrative = "The family fled. The holdings burned behind them. Everything the ancestors built became ash and memory. But the blood survived.",
                },
            },
            {
                label = "Accept the end with dignity",
                description = "If this is the end, let it be recorded that the bloodline did not beg.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    lineage_power_shift = 5,
                    moral_act = { act_id = "sacrifice", description = "Faced extinction with dignity rather than desperation" },
                    narrative = "The heir sat in the great hall and waited. When the end came — if it came — it would find the bloodline seated, composed, and unafraid. Some things are worth more than survival.",
                },
            },
        },
    },
}
