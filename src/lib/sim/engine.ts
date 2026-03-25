
import { LuaFactory } from 'wasmoon';

const luaFiles = import.meta.glob('../../../dredwork/**/*.lua', { query: '?raw', eager: true });
const copperLordsLua = import.meta.glob('./copperlords.lua', { query: '?raw', eager: true });

export interface GameState {
    coins: number;
    day: number;
    grifters: any[];
    districts: any[];
    game_over: boolean;
    game_over_reason: string;
    win: boolean;
    win_target: number;
    shop: {
        items: any[];
        hire_pool: any[];
    };
}

// Wasmoon returns Lua tables as Map-like objects. Convert to plain JS.
function luaToJS(val: any): any {
    if (val === null || val === undefined) return val;
    if (typeof val === 'function') return undefined;
    if (typeof val !== 'object') return val;
    if (typeof val.get === 'function' && typeof val.has === 'function') {
        const result: any[] = [];
        let i = 1;
        while (val.has(i)) {
            result.push(luaToJS(val.get(i)));
            i++;
        }
        if (result.length > 0) {
            const obj: any = {};
            let hasStringKeys = false;
            if (typeof val.forEach === 'function') {
                val.forEach((v: any, k: any) => {
                    if (typeof k === 'string') {
                        obj[k] = luaToJS(v);
                        hasStringKeys = true;
                    }
                });
            }
            if (hasStringKeys) {
                for (let j = 0; j < result.length; j++) obj[j + 1] = result[j];
                return obj;
            }
            return result;
        }
        const obj: any = {};
        if (typeof val.forEach === 'function') {
            val.forEach((v: any, k: any) => { obj[k] = luaToJS(v); });
        }
        return obj;
    }
    if (Array.isArray(val)) return val.map(luaToJS);
    if (val.constructor === Object) {
        const out: any = {};
        for (const k of Object.keys(val)) out[k] = luaToJS(val[k]);
        return out;
    }
    return val;
}

export class SimulationEngine {
    private factory: LuaFactory;
    private lua: any;

    constructor() {
        // Give Lua 32MB initial / 128MB max instead of the default 16MB.
        // The incremental GC can't keep WASM heap tidy enough with the default
        // allocation; bumping the ceiling prevents heap-exhaustion corruption.
        const mem = new WebAssembly.Memory({ initial: 512, maximum: 2048 });
        this.factory = new LuaFactory(undefined, mem);
    }

    async init() {
        try {
            this.lua = await this.factory.createEngine();

            const fileEntries = Object.entries(luaFiles);
            for (const [path, content] of fileEntries) {
                let virtualPath = path.replace('../../../dredwork/', '');
                const moduleName = virtualPath.replace('.lua', '').replace(/\//g, '.').replace(/\.init$/, '');
                const luaContent = (content as any).default;
                if (!luaContent) continue;

                this.lua.global.set(`__lua_content_${moduleName.replace(/\./g, '_')}`, luaContent);
                await this.lua.doString(`
                    package.preload["${moduleName}"] = function()
                        local chunk, err = load(__lua_content_${moduleName.replace(/\./g, '_')}, "${virtualPath}")
                        if not chunk then error("Failed to load module ${moduleName}: " .. tostring(err)) end
                        return chunk()
                    end
                `);
            }

            const clContent = (copperLordsLua['./copperlords.lua'] as any).default;
            this.lua.global.set('__lua_content_copperlords', clContent);
            await this.lua.doString(`
                package.preload["copperlords"] = function()
                    local chunk, err = load(__lua_content_copperlords, "copperlords.lua")
                    if not chunk then error("Failed to load module copperlords: " .. tostring(err)) end
                    return chunk()
                end
            `);

            this.lua.global.set('__js_log_sink', (msg: string) => {
                console.log(`[LUA] ${msg}`);
            });

            await this.lua.doString(`
                local Engine = require("dredwork_engine")
                local CopperLords = require("copperlords")
                _G.engine = Engine.new({ seed = os.time(), log_sink = __js_log_sink })
                CopperLords.init(_G.engine)
                -- Run GC more aggressively to prevent WASM heap exhaustion
                collectgarbage("setpause", 100)
                collectgarbage("setstepmul", 400)
            `);

            // Precompile all hot-path functions once so doString never
            // recompiles them. Each tick only calls these named globals.
            await this.lua.doString(`
                local CL = require("copperlords")

                _G.__cl_step = function()
                    _G.engine:step()
                end

                _G.__cl_get_state = function()
                    local gs = _G.engine.game_state
                    local function copyMod(m)
                        if not m then return {} end
                        return {
                            win_chance=m.win_chance, suspicion=m.suspicion,
                            coins=m.coins, fatigue=m.fatigue, luck=m.luck,
                            bribe_discount=m.bribe_discount
                        }
                    end
                    local function copyGrifter(g)
                        local items = {}
                        for _, it in ipairs(g.items or {}) do
                            items[#items+1] = { id=it.id, name=it.name, mod=copyMod(it.mod) }
                        end
                        local traits = {}
                        for _, t in ipairs(g.traits or {}) do
                            traits[#traits+1] = { name=t.name, desc=t.desc, mod=copyMod(t.mod) }
                        end
                        return {
                            id=g.id, name=g.name, status=g.status,
                            stats={ sleight=g.stats.sleight, nerve=g.stats.nerve,
                                    read=g.stats.read, luck=g.stats.luck },
                            traits=traits, items=items,
                            fatigue=g.fatigue, suspicion=g.suspicion,
                            settings={ cheat=g.settings.cheat, hours=g.settings.hours },
                            location_id=g.location_id,
                            lifetime_coins=g.lifetime_coins or 0,
                            arrests=g.arrests or 0,
                            win_rate=g.win_rate or 0.5
                        }
                    end
                    local function copyDistrict(d)
                        return {
                            id=d.id, name=d.name, flavor=d.flavor,
                            wealth=d.wealth, law=d.law,
                            skill_avg=d.skill_avg, heat=d.heat
                        }
                    end
                    local grifters = {}
                    for _, g in ipairs(gs.grifters or {}) do
                        grifters[#grifters+1] = copyGrifter(g)
                    end
                    local districts = {}
                    for _, d in ipairs(gs.districts or {}) do
                        districts[#districts+1] = copyDistrict(d)
                    end
                    local shop_items = {}
                    for _, it in ipairs(gs.shop and gs.shop.items or {}) do
                        shop_items[#shop_items+1] = {
                            id=it.id, name=it.name, desc=it.desc,
                            cost=it.cost, sold=it.sold, mod=copyMod(it.mod)
                        }
                    end
                    local hire_pool = {}
                    for _, h in ipairs(gs.shop and gs.shop.hire_pool or {}) do
                        hire_pool[#hire_pool+1] = {
                            index=h.index, name=h.name,
                            hired=h.hired, cost=h.cost,
                            stats={ sleight=h.stats.sleight, nerve=h.stats.nerve,
                                    read=h.stats.read, luck=h.stats.luck },
                            trait=h.trait and { name=h.trait.name, desc=h.trait.desc } or {}
                        }
                    end
                    return {
                        coins=gs.coins, day=gs.day,
                        game_over=gs.game_over,
                        game_over_reason=gs.game_over_reason or "",
                        win=gs.win, win_target=gs.win_target,
                        grifters=grifters, districts=districts,
                        shop={ items=shop_items, hire_pool=hire_pool }
                    }
                end

                _G.__cl_get_events = function()
                    return _G.engine:pop_ui_events()
                end

                _G.__cl_set_setting = function(gid, key, val)
                    for _, g in ipairs(_G.engine.game_state.grifters) do
                        if g.id == gid then g.settings[key] = val; break end
                    end
                end

                _G.__cl_move = function(gid, did)
                    CL.move_grifter(_G.engine, gid, did)
                end

                _G.__cl_bribe = function(gid)
                    local ok, cost = CL.bribe_grifter(_G.engine, gid)
                    return ok and 1 or 0, cost or 0
                end

                _G.__cl_buy_item = function(iid, gid)
                    return CL.buy_item(_G.engine, iid, gid) and 1 or 0
                end

                _G.__cl_hire = function(idx)
                    return CL.hire_grifter(_G.engine, idx) and 1 or 0
                end

                _G.__cl_bribe_cost = function(gid)
                    return CL.get_bribe_cost(_G.engine, gid)
                end
            `);

        } catch (err) {
            console.error("Simulation Engine Init Error:", err);
            throw err;
        }
    }

    async step() {
        await this.lua.doString(`__cl_step()`);
        return this.getState();
    }

    async getState(): Promise<GameState> {
        const raw = await this.lua.doString(`return __cl_get_state()`);
        return luaToJS(raw) as GameState;
    }

    async setGrifterSetting(grifterId: number, key: string, value: any) {
        const luaVal = typeof value === 'string' ? `"${value}"` : value;
        await this.lua.doString(`__cl_set_setting(${grifterId}, "${key}", ${luaVal})`);
    }

    async moveGrifter(grifterId: number, districtId: string) {
        await this.lua.doString(`__cl_move(${grifterId}, "${districtId}")`);
    }

    async bribeGrifter(grifterId: number): Promise<{ success: boolean; cost: number }> {
        try {
            const result = await this.lua.doString(`
                local ok, cost = __cl_bribe(${grifterId})
                return { ok=ok, cost=cost }
            `);
            const r = luaToJS(result);
            return { success: r.ok === 1, cost: r.cost || 0 };
        } catch (err) {
            console.error("Bribe error:", err);
            return { success: false, cost: 0 };
        }
    }

    async buyItem(itemId: string, grifterId: number): Promise<boolean> {
        try {
            const result = await this.lua.doString(`return __cl_buy_item("${itemId}", ${grifterId})`);
            return result === 1;
        } catch (err) {
            console.error("Buy item error:", err);
            return false;
        }
    }

    async hireGrifter(hireIndex: number): Promise<boolean> {
        try {
            const result = await this.lua.doString(`return __cl_hire(${hireIndex})`);
            return result === 1;
        } catch (err) {
            console.error("Hire error:", err);
            return false;
        }
    }

    async getBribeCost(grifterId: number): Promise<number> {
        try {
            return await this.lua.doString(`return __cl_bribe_cost(${grifterId})`) || 0;
        } catch (err) {
            console.error("Get bribe cost error:", err);
            return 0;
        }
    }

    async getEvents() {
        try {
            const raw = await this.lua.doString(`return __cl_get_events()`);
            return luaToJS(raw);
        } catch (err) {
            console.error("Get events error:", err);
            return [];
        }
    }
}
