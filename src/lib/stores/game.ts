
import { writable } from 'svelte/store';
import { SimulationEngine, type GameState } from '../sim/engine';

export const gameState = writable<GameState | null>(null);
export const gameEvents = writable<any[]>([]);

let engine: SimulationEngine;
let stepping = false;

export async function initGame() {
    engine = new SimulationEngine();
    await engine.init();
    const state = await engine.getState();
    gameState.set(state);
}

export async function stepGame() {
    if (!engine || stepping) return;
    stepping = true;
    try {
        const { state, events } = await engine.tick();
        gameState.set(state);
        if (events.length > 0) {
            gameEvents.update(old => [...old, ...events].slice(-50));
        }
    } finally {
        stepping = false;
    }
}

// Debounced setting update — writes to Lua immediately but only
// refreshes JS state once after the user stops dragging.
let settingTimer: any = null;

export async function updateGrifterSetting(grifterId: number, key: string, value: any) {
    if (!engine) return;

    // Write to Lua immediately
    await engine.setGrifterSetting(grifterId, key, value);

    // Optimistic local update so the slider doesn't fight
    gameState.update(gs => {
        if (!gs) return gs;
        const g = gs.grifters.find((g: any) => g.id === grifterId);
        if (g) g.settings[key] = value;
        return gs;
    });

    // Debounce full Lua→JS sync
    clearTimeout(settingTimer);
    settingTimer = setTimeout(async () => {
        if (!engine) return;
        const state = await engine.getState();
        gameState.set(state);
    }, 200);
}

export async function moveGrifter(grifterId: number, districtId: string) {
    if (!engine) return;
    // moveGrifter now returns state inline — no second getState() call
    const state = await engine.moveGrifter(grifterId, districtId);
    gameState.set(state);
}

export async function bribeGrifter(grifterId: number) {
    if (!engine) return { success: false, cost: 0 };
    const { success, cost, state } = await engine.bribeGrifter(grifterId);
    gameState.set(state);
    return { success, cost };
}

export async function buyItem(itemId: string, grifterId: number) {
    if (!engine) return false;
    const { ok, state } = await engine.buyItem(itemId, grifterId);
    gameState.set(state);
    return ok;
}

export async function hireGrifter(hireIndex: number) {
    if (!engine) return false;
    const { ok, state } = await engine.hireGrifter(hireIndex);
    gameState.set(state);
    return ok;
}

export async function getBribeCost(grifterId: number) {
    if (!engine) return 0;
    return engine.getBribeCost(grifterId);
}
