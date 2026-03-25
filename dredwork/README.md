# dredwork

Decoupled game engine modules by [adarkfable](https://adarkfable.com).

Pure Lua 5.1 game systems — no engine dependencies. Built for [Bloodweight](https://bloodweight.com), usable anywhere.

## Modules

| Module | Language | Description |
|---|---|---|
| `dredwork_genetics/` | Lua 5.1 | 75-trait genetic engine — inheritance, crossover, mutation, personality (8 axes), viability, cultural memory |
| `dredwork_world/` | Lua 5.1 | World simulation — 20+ subsystems: factions, events, council, religion, culture, holdings, resources, rivals, chronicles |
| `dredwork_bonds/` | Lua 5.1 | Life simulation engine — relationships, careers, mortality, secrets, possessions (legacy, not active) |
| `dredwork_combat_v2/` | Lua 5.1 | Dueling/trial combat engine — moves, templates, arena simulation (legacy, not active) |
| `dredwork-editor/` | Node.js | Config-driven text editor for Lua game files — web UI, live color preview, add-entry templates |

## Philosophy

- **Pure logic.** No UI, no engine, no framework. These run in any Lua 5.1 environment.
- **Seedable randomness.** All systemic outcomes are deterministic given the same seed via the `rng` wrapper.
- **Decoupled.** Modules never `require` display/rendering libraries. The bridge layer is your problem.

## Tests

```bash
# Genetics tests
lua dredwork_genetics/tests/run_tests.lua

# World tests
lua dredwork_world/tests/run_all.lua
```

## License

MIT
