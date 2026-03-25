# Dredwork Shadow

`dredwork_bonds/` is the pure-Lua life-simulation engine for `Shadow of Lineage`.

It plays the same architectural role for the spinoff that `dredwork_genetics/` and
`dredwork_world/` play for Bloodweight:

- `dredwork_genetics/` handles heredity and personality structure.
- `dredwork_world/` handles dynasty-scale world simulation.
- `dredwork_bonds/` handles one-life simulation: setup, bonds, claim, body, career,
  possessions, yearly turns, and mortality.

## Design Rules

- Keep this package engine-facing and UI-agnostic.
- Avoid direct Defold/Solar2D display dependencies.
- Let the front end consume snapshots and actions instead of embedding life logic.
- Prefer interconnected state changes over isolated feature flags.

## Current Modules

- `setup.lua` — protagonist setup, biased identity rolls, and core cast seeding
- `life.lua` — opening-state application from setup choices
- `body.lua` — wounds, illness, habit, aging pressure
- `career.lua` — calling/career state and rank progression
- `bonds.lua` — named bond actors, drift, agendas, and relationship detail
- `claim.lua` — denied-branch legitimacy, proof, grievance, exposure, usurper risk
- `possessions.lua` — items, places, held people, and ownership pressure
- `events.lua` — Shadow-specific event families and fallout
- `year.lua` — yearly planning, resolution, interlocks, and loop tension
- `mortality.lua` — ending evaluation and final-life framing
- `aftermath.lua` — post-death legacy: ghost weight, reputation echo, possession inheritance, next-life seeding

## Body Damage Arcs

The body system tracks three severity pools (wounds, illnesses, compulsions) plus:

- **Scars** — Wounds above severity 50 leave permanent marks that worsen with age and never heal. Scars contribute to combined wound load for mortality and label thresholds.
- **Convalescence** — When combined wound + scar + illness load exceeds 60, the body is convalescing. This flag is available for the UI and yearly action gating.
- **Relapse risk** — Compulsions that reach severity 40+ leave a relapse marker. If the compulsion is later relieved to zero but stress remains high (62+), the compulsion returns at 25% of its peak.
- **Aging pressure** — After age 40, wound and illness recovery rates decrease. After 55, recovery slows further.

## Aftermath System

When a life ends, `aftermath.lua` compiles a full legacy record:

- **Ghost weight** (0-100) — How much the world remembers. Driven by standing, notoriety, claim legitimacy, career rank, cause of death, and age.
- **Reputation echo** — Claim status, final career, and a rumor about how the branch was remembered.
- **Inheritable possessions** — Yielding items and all places pass forward.
- **Surviving bonds** — Non-hostile bonds are captured; close ones (closeness >= 30) become "MEMORY OF" bonds for the next life.
- **Next-life seed** — Claim bonuses, starting notoriety/standing, and bond memories for continuity across lives.

## Test Suite

146 unit tests across 9 test files in `dredwork_bonds/tests/`. Run from project root:

```
lua dredwork_bonds/tests/run_all.lua
```

## Integration

For now, `defold/defold_bridge/` exposes thin compatibility shims so the current
Defold UI can keep requiring the old paths while the engine split settles. New
simulation work should target `dredwork_bonds/` first.
