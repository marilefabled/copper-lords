## **GDD — “Copper Lords” (working title)**

**Theme:** Micromanagement  
**Object:** Coin  
**Engine:** SvelteKit \+ Dredwork Lua Modules (sim backend, web UI frontend)

---

# **1\. Core Loop (tight, jam-ready)**

**Player fantasy:** Crime boss optimizing small agents in a probabilistic economy.

### **Loop**

1. Assign grifters → districts / schedules  
2. Tune behavior → sliders (cheat %, hours, aggression)  
3. Simulation runs (ticks or bursts)  
4. Coins flow → wins/losses, theft, penalties  
5. Events → jail, suspicion, rival interference  
6. Spend coins → upgrades / new hires  
7. Repeat with increasing systemic pressure

---

# **2\. Core Systems**

## **2.1 Coin Economy (the backbone)**

Each interaction \= **coin flip duel**

Grifter A vs Target B  
→ Flip resolution (biased by stats \+ modifiers)  
→ Winner gains coin, loser loses coin

### **Base Probability**

* Default: 50/50  
* Modified by:  
  * Skill (Sleight, Nerve, Read)  
  * Equipment (weighted coin, marked coin)  
  * Fatigue  
  * Suspicion level  
  * District modifiers

### **Key Insight**

You are not managing money.  
You are managing **probability distribution over time**.

---

## **2.2 Grifter Unit Model**

Each employee is a **state machine \+ stat container**

### **Stats (minimal but expressive)**

* **Sleight** → bias coin  
* **Nerve** → avoid detection  
* **Read** → counter opponent bias  
* **Luck** → small passive modifier (rare stat)

### **Hidden Stats (from your Dredwork modules)**

* Personality → risk tolerance  
* Bonds → synergy/penalties between workers  
* Condition → fatigue / injury

---

## **2.3 Micromanagement Layer (core differentiator)**

Each unit has **player-tunable controls**

### **Sliders**

* **Cheat Intensity (0–100%)**  
  * ↑ win rate  
  * ↑ suspicion exponentially  
* **Work Hours**  
  * ↑ coin throughput  
  * ↑ fatigue → ↓ stats  
* **Risk Profile**  
  * Aggressive: targets high coin holders  
  * Passive: safe grinding

### **Toggles**

* Use special item (weighted coin ON/OFF)  
* Avoid law-heavy zones  
* Partner mode (team flips)

---

## **2.4 Suspicion / Law System**

Every district tracks **heat**

* Individual suspicion → per grifter  
* District suspicion → global pressure

### **Outcomes**

* Low → nothing  
* Medium → reduced odds (people wary)  
* High → **arrest event**

### **Jail**

* Unit removed for X time  
* Optional: bribe system (coin sink)

---

## **2.5 District System (simple but strategic)**

Map \= small set (3–5 districts max for jam)

Each district defines:

* Base wealth (coins in circulation)  
* Law presence  
* NPC skill average  
* Special modifier (e.g. “rigged tables”)

---

# **3\. Simulation Model (Agentic-Friendly)**

## **3.1 Tick Structure**

Use **discrete ticks** (fast-forward capable)

Tick:  
  For each grifter:  
    Choose target  
    Resolve encounter  
    Update stats (fatigue, suspicion)  
    Trigger events

Run:

* Realtime (slow tick)  
* Burst (simulate 1 day instantly)

---

## **3.2 Encounter Resolution**

base \= 0.5

modifier \=  
  \+ (sleight \- opponent\_read) \* k1  
  \+ (luck delta) \* k2  
  \+ (equipment bonus)  
  \- (fatigue penalty)  
  \- (district suspicion penalty)

roll → win / loss

---

## **3.3 Emergence Hooks (important for Dredwork identity)**

* Grifter develops tendencies:  
  * “Always cheats too hard”  
  * “Lucky streaks”  
* Rival NPCs appear (anti-grifters)  
* Micro-stories:  
  * “Caught cheating a priest”  
  * “Runs a table in secret”

These feed your **AI chronicler payload**

---

# **4\. UI / UX (SvelteKit structure)**

## **4.1 Layout**

### **Main Screen (Management)**

* List of grifters (cards)  
* Coin total (top)  
* District overview

### **Grifter Zoom Panel (core micromanagement)**

* Stats  
* Sliders (cheat, hours, risk)  
* Current status  
* Recent log

### **Map View (lightweight)**

* Click district → assign units

---

## **4.2 UI Philosophy**

* **Everything adjustable \= visible**  
* Sliders are the game  
* Feedback must be immediate:  
  * % win rate estimate  
  * Risk warnings

---

# **5\. Progression**

## **5.1 Upgrades (coin sinks)**

### **Boss-level upgrades**

* Unlock more grifters (cap starts at 2–3)  
* District access  
* Bribe efficiency

### **Item upgrades**

* Weighted coin (flat bias)  
* Marked coin (info advantage)  
* Gloves (reduce suspicion)

---

## **5.2 Difficulty Scaling**

* Law ramps over time  
* NPCs get smarter (Read stat increases)  
* Coin economy tightens

---

# **6\. Failure / Win States**

### **Loss**

* All grifters jailed  
* Coin \= 0 and no recovery path

### **Win (jam-friendly)**

* Reach X coins before collapse  
* Or survive X days

---

# **7\. Architecture (SvelteKit \+ Agentic AI)**

## **7.1 Separation**

### **Frontend (SvelteKit)**

* UI  
* Input (sliders, assignments)  
* Visualization

### **Simulation Layer**

* Your Lua modules (compiled or ported)  
* Runs tick system

### **Bridge**

* JSON state snapshots

UI → sends config  
Sim → runs ticks  
Sim → returns state  
UI → renders

---

## **7.2 State Shape (simplified)**

{  
  "coins": 120,  
  "time": 42,  
  "grifters": \[  
    {  
      "id": 1,  
      "stats": { "sleight": 3, "nerve": 2, "read": 1 },  
      "fatigue": 0.2,  
      "suspicion": 0.4,  
      "settings": {  
        "cheat": 0.7,  
        "hours": 0.8,  
        "risk": "high"  
      },  
      "status": "active"  
    }  
  \],  
  "districts": \[...\]  
}

---

## **7.3 Agentic Hooks**

You can plug AI into:

### **1\. Run Summary**

* “Day 12: Finch pushed too far, arrested after cheating streak”

### **2\. Character Drift**

* Generate traits dynamically

### **3\. Event Text**

* Flavor without hardcoding

---

# **8\. Gameplay Gaps (patched)**

## **Gap 1: “Just flipping coins isn’t enough”**

**Fix:** Add layered modifiers

* Read vs Sleight counterplay  
* District variation  
* Equipment tradeoffs

---

## **Gap 2: “Micromanagement could feel fake”**

**Fix:** Sliders must:

* Show predicted impact  
* Have nonlinear consequences

---

## **Gap 3: “No tension”**

**Fix:** Suspicion curve is exponential  
→ pushing advantage always risks collapse

---

## **Gap 4: “No player expression”**

**Fix:** Multiple viable builds:

* Low cheat, long game  
* High cheat, burst profit  
* Info-based (Read stacking)

---

# **9\. Jam Scope (strict)**

### **Must-have**

* 2–3 grifters  
* 2 districts  
* Sliders working  
* Coin economy functional  
* Jail system

### **Nice-to-have**

* Items  
* AI narrative  
* Map visuals

---

# **10\. Naming \+ Positioning (itch-ready)**

* **Copper Lords**  
* **The Coin Syndicate**  
* **Odds & Empire**  
* **Flipstreet**

Tag it as:

“A probabilistic crime sim about managing people, not outcomes.”

---

If needed, next step can be:

* exact SvelteKit folder structure  
* tick engine skeleton  
* UI component breakdown (stores, derived state, etc.)  
* or direct Lua ↔ JS bridge implementation plan

