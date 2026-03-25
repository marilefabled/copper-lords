
<script lang="ts">
    import { onMount } from 'svelte';
    import { fade, fly, slide, scale } from 'svelte/transition';
    import { gameState, gameEvents, initGame, stepGame, updateGrifterSetting, moveGrifter, bribeGrifter, buyItem, hireGrifter } from '$lib/stores/game';
    import Portrait from '$lib/components/Portrait.svelte';
    import { audio } from '$lib/utils/audio';

    let phase: 'splash' | 'title' | 'playing' | 'gameover' = $state('splash');
    let loading = $state(false);
    let autoStep = $state(false);
    let autoStepInterval: any;
    let screenShake = $state(false);
    let coinFlash = $state(false);
    let ticking = $state(false);
    let activeTab: 'grifters' | 'shop' | 'log' = $state('grifters');
    let shopSubTab: 'hire' | 'items' = $state('hire');
    let selectedGrifterForItem = $state<number | null>(null);

    // Splash state
    let splashLine1 = $state(false);
    let splashLine2 = $state(false);
    let splashLine3 = $state(false);
    let splashLine4 = $state(false);
    let splashFading = $state(false);

    onMount(() => {
        setTimeout(() => { if (phase === 'splash') splashLine1 = true; }, 400);
        setTimeout(() => { if (phase === 'splash') splashLine2 = true; }, 1400);
        setTimeout(() => { if (phase === 'splash') splashLine3 = true; }, 2400);
        setTimeout(() => { if (phase === 'splash') splashLine4 = true; }, 3400);
        setTimeout(() => {
            if (phase !== 'splash') return;
            splashFading = true;
            setTimeout(() => { if (phase === 'splash') phase = 'title'; }, 500);
        }, 5200);
    });

    function skipSplash() {
        splashFading = true;
        setTimeout(() => { if (phase === 'splash') phase = 'title'; }, 300);
    }

    async function startGame() {
        audio.init();
        loading = true;
        await initGame();
        loading = false;
        phase = 'playing';
    }

    function toggleAutoStep() {
        audio.init();
        autoStep = !autoStep;
        if (autoStep) {
            autoStepInterval = setInterval(handleStep, 1200);
        } else {
            clearInterval(autoStepInterval);
        }
    }

    async function handleStep() {
        if (ticking) return;
        ticking = true;
        try {
            audio.init();
            const prevCoins = $gameState?.coins ?? 0;
            const prevEventCount = $gameEvents.length;
            await stepGame();

            if ($gameState?.game_over) {
                autoStep = false;
                clearInterval(autoStepInterval);
                phase = 'gameover';
                if ($gameState.win) audio.playWin();
                else audio.playLose();
                return;
            }

            // Sound only for NEW events from this tick
            const evts = $gameEvents;
            let hasArrest = false;
            let hasEvent = false;
            let netPositive = false;
            for (let i = prevEventCount; i < evts.length; i++) {
                const e = evts[i];
                if (!e) continue;
                if (e.name === 'ARREST') hasArrest = true;
                if (e.name === 'EVENT') hasEvent = true;
                if (e.name === 'DAY_SUMMARY' && e.data?.net > 0) netPositive = true;
            }
            if (hasArrest) { audio.playArrest(); triggerShake(); }
            else if (hasEvent) audio.playEvent();
            else if (netPositive) audio.playCoin(true);
            else audio.playCoin(false);

            // Coin flash
            if ($gameState && $gameState.coins !== prevCoins) {
                coinFlash = true;
                setTimeout(() => coinFlash = false, 300);
            }
        } finally {
            ticking = false;
        }
    }

    function triggerShake() {
        screenShake = true;
        setTimeout(() => screenShake = false, 400);
    }

    function handleSettingChange(grifterId: number, key: string, value: number) {
        updateGrifterSetting(grifterId, key, value);
    }

    async function handleMove(grifterId: number, districtId: string) {
        audio.init();
        await moveGrifter(grifterId, districtId);
    }

    async function handleBribe(grifterId: number) {
        audio.init();
        const result = await bribeGrifter(grifterId);
        if (result.success) {
            audio.playBribe();
        }
    }

    async function handleBuyItem(itemId: string, grifterId: number) {
        audio.init();
        const ok = await buyItem(itemId, grifterId);
        if (ok) {
            audio.playBuy();
            selectedGrifterForItem = null;
        }
    }

    async function handleHire(hireIndex: number) {
        audio.init();
        const ok = await hireGrifter(hireIndex);
        if (ok) audio.playHire();
    }

    function getBribeCost(grifter: any): number {
        const base = 60;
        return base + ((grifter.arrests || 0) * 30);
    }

    function getDistrictName(id: string): string {
        const d = $gameState?.districts?.find((d: any) => d.id === id);
        return d?.name || id;
    }

    function formatEvent(event: any): string {
        if (!event?.data) return '';
        const d = event.data;
        switch (event.name) {
            case 'DAY_SUMMARY': {
                const net = d.net >= 0 ? `+${d.net}c` : `${d.net}c`;
                const sus = d.suspicion_delta > 0 ? ` | sus +${d.suspicion_delta}%` : '';
                return `${d.grifter} in ${d.district}: ${d.wins}W/${d.losses}L (${net})${sus}`;
            }
            case 'ARREST': return `${d.grifter} ARRESTED in ${d.district}!`;
            case 'RELEASED': return `${d.grifter} released from jail`;
            case 'EVENT': return `${d.title}: ${d.text}`;
            case 'BRIBE': return `${d.grifter} bribed out for ${d.cost}c`;
            case 'HIRED': return `${d.grifter} hired for ${d.cost}c`;
            case 'ITEM_BOUGHT': return `${d.grifter} equipped ${d.item}`;
            case 'GRIFTER_MOVED': return `${d.grifter} moved to ${d.to}`;
            case 'SUSPICION_SPIKE': return `${d.grifter}: suspicion spiked +${d.amount}%!`;
            default: return JSON.stringify(d);
        }
    }

    // Restart
    async function restart() {
        phase = 'title';
        gameEvents.set([]);
        autoStep = false;
        clearInterval(autoStepInterval);
    }
</script>

<svelte:head>
    <title>Copper Lords</title>
    <meta name="description" content="A probabilistic crime sim about managing people, not outcomes." />
</svelte:head>

<div class="crt">
<div class="scanlines"></div>
<div class="app" class:shake={screenShake}>

{#if phase === 'splash'}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div class="splash-screen" class:splash-fading={splashFading} onclick={skipSplash}>
        <div class="splash-glow"></div>
        <div class="splash-brand">
            {#if splashLine1}
                <p class="splash-studio" class:splash-visible={splashLine1}>adarkfable</p>
            {/if}
            {#if splashLine2}
                <p class="splash-or" class:splash-visible={splashLine2}>or</p>
            {/if}
            {#if splashLine3}
                <p class="splash-tale" class:splash-visible={splashLine3}>a cautionary tale</p>
            {/if}
            {#if splashLine4}
                <div class="splash-divider" class:splash-visible={splashLine4}></div>
                <p class="splash-presents" class:splash-visible={splashLine4}>presents</p>
            {/if}
        </div>
    </div>

{:else if phase === 'title'}
    <div class="title-screen" in:fade={{ duration: 600 }}>
        <div class="title-bg">
            <div class="coin-symbol">&#x2B24;</div>
            <h1 class="game-title">COPPER<br/>LORDS</h1>
            <p class="tagline">A probabilistic crime sim about managing people, not outcomes.</p>
            <div class="title-details">
                <span>Manage grifters</span>
                <span class="dot">&middot;</span>
                <span>Rig the odds</span>
                <span class="dot">&middot;</span>
                <span>Own the city</span>
            </div>
            {#if loading}
                <div class="loading-text" in:fade>Waking the syndicate...</div>
            {:else}
                <button class="start-btn" onclick={startGame} in:scale={{ duration: 300 }}>
                    BEGIN
                </button>
            {/if}
            <div class="title-footer">
                <span>THEME: MICROMANAGEMENT</span>
                <span>ENGINE: DREDWORK</span>
            </div>
        </div>
    </div>

{:else if phase === 'gameover'}
    <div class="gameover-screen" in:fade={{ duration: 800 }}>
        <div class="gameover-content">
            <div class="gameover-icon">{$gameState?.win ? '&#x2655;' : '&#x2617;'}</div>
            <h1 class="gameover-title">{$gameState?.win ? 'VICTORY' : 'DOWNFALL'}</h1>
            <p class="gameover-reason">{$gameState?.game_over_reason}</p>
            <div class="gameover-stats">
                <div class="stat-block">
                    <span class="stat-val">{$gameState?.coins}</span>
                    <span class="stat-label">Copper</span>
                </div>
                <div class="stat-block">
                    <span class="stat-val">{$gameState?.day}</span>
                    <span class="stat-label">Days</span>
                </div>
                <div class="stat-block">
                    <span class="stat-val">{$gameState?.grifters?.length || 0}</span>
                    <span class="stat-label">Grifters</span>
                </div>
            </div>
            <button class="start-btn" onclick={restart}>PLAY AGAIN</button>
        </div>
    </div>

{:else if $gameState}
    <!-- ─── HEADER ────────────────────────────────────────────── -->
    <header in:fly={{ y: -30, duration: 400 }}>
        <div class="header-left">
            <div class="logo">COPPER LORDS</div>
            <div class="day-badge">DAY {$gameState.day}</div>
        </div>
        <div class="header-center">
            <div class="treasury" class:flash={coinFlash}>
                <span class="coin-icon-sm">&#x25C9;</span>
                <span class="coin-value">{$gameState.coins}</span>
                <span class="coin-target">/ {$gameState.win_target}</span>
            </div>
            <div class="progress-bar">
                <div class="progress-fill" style="width: {Math.min(100, ($gameState.coins / $gameState.win_target) * 100)}%"></div>
            </div>
        </div>
        <div class="header-right">
            <button class="btn" onclick={handleStep} disabled={autoStep || ticking}>TICK</button>
            <button class="btn" class:active={autoStep} onclick={toggleAutoStep}>
                {autoStep ? '■ STOP' : '▶ AUTO'}
            </button>
        </div>
    </header>

    <!-- ─── DISTRICTS ─────────────────────────────────────────── -->
    <section class="districts-bar">
        {#each $gameState.districts as district}
            <div class="district-chip">
                <div class="district-name">{district.name}</div>
                <div class="district-stats">
                    <span title="Wealth">&#x25C9; {district.wealth}</span>
                    <span title="Law">&#x2694; {district.law}</span>
                    <span title="NPC Skill">&#x2605; {Math.round(district.skill_avg * 10) / 10}</span>
                </div>
                <div class="heat-bar">
                    <div class="heat-fill" style="width: {district.heat}%; opacity: {0.4 + district.heat * 0.006}"></div>
                </div>
                <div class="district-flavor">{district.flavor}</div>
            </div>
        {/each}
    </section>

    <!-- ─── TABS ──────────────────────────────────────────────── -->
    <nav class="tabs">
        <button class="tab" class:active={activeTab === 'grifters'} onclick={() => activeTab = 'grifters'}>
            GRIFTERS ({$gameState.grifters.length})
        </button>
        <button class="tab" class:active={activeTab === 'shop'} onclick={() => activeTab = 'shop'}>
            BLACK MARKET
        </button>
        <button class="tab" class:active={activeTab === 'log'} onclick={() => activeTab = 'log'}>
            WIRE ({$gameEvents.length})
        </button>
    </nav>

    <main>
        <!-- ─── GRIFTERS TAB ─────────────────────────────────── -->
        {#if activeTab === 'grifters'}
            <div class="grifter-grid" in:fade={{ duration: 200 }}>
                {#each $gameState.grifters as grifter (grifter.id)}
                    <div class="grifter-card {grifter.status}" in:fly={{ y: 15, duration: 300 }}>
                        <div class="grifter-top">
                            <div class="portrait-wrap">
                                <Portrait id={grifter.id} status={grifter.status} />
                            </div>
                            <div class="grifter-header">
                                <div class="name-row">
                                    <h3>{grifter.name}</h3>
                                    <span class="status-badge {grifter.status}">{grifter.status.toUpperCase()}</span>
                                </div>
                                <div class="stat-row">
                                    <span title="Sleight">SLT {grifter.stats.sleight}</span>
                                    <span title="Nerve">NRV {grifter.stats.nerve}</span>
                                    <span title="Read">RD {grifter.stats.read}</span>
                                    {#if grifter.stats.luck > 0}<span title="Luck">LCK {grifter.stats.luck}</span>{/if}
                                </div>
                                <div class="trait-row">
                                    {#each grifter.traits || [] as trait}
                                        <span class="trait" title={trait.desc || JSON.stringify(trait.mod)}>{trait.name}</span>
                                    {/each}
                                    {#each grifter.items || [] as item}
                                        <span class="item-tag" title={item.name}>{item.name}</span>
                                    {/each}
                                </div>
                            </div>
                        </div>

                        <div class="meters-section">
                            <div class="meter-row">
                                <span class="meter-lbl">FTG</span>
                                <div class="meter"><div class="meter-fill fatigue" style="width: {grifter.fatigue * 100}%"></div></div>
                                <span class="meter-val">{Math.round(grifter.fatigue * 100)}%</span>
                            </div>
                            <div class="meter-row">
                                <span class="meter-lbl">SUS</span>
                                <div class="meter"><div class="meter-fill suspicion" style="width: {grifter.suspicion * 100}%"></div></div>
                                <span class="meter-val">{Math.round(grifter.suspicion * 100)}%</span>
                            </div>
                            {#if grifter.status === 'active' && grifter.win_rate !== undefined}
                                <div class="win-rate">
                                    Est. Win: <strong class:good={grifter.win_rate > 0.55} class:bad={grifter.win_rate < 0.45}>{Math.round(grifter.win_rate * 100)}%</strong>
                                </div>
                            {/if}
                        </div>

                        {#if grifter.status === 'active'}
                            <div class="controls-section" transition:slide={{ duration: 200 }}>
                                <div class="loc-row">
                                    <label>
                                        District:
                                        <select value={grifter.location_id} onchange={(e) => handleMove(grifter.id, e.currentTarget.value)}>
                                            {#each $gameState.districts as d}
                                                <option value={d.id}>{d.name}</option>
                                            {/each}
                                        </select>
                                    </label>
                                </div>
                                <div class="slider-row">
                                    <label>
                                        <span class="slider-label">Cheat <strong>{Math.round(grifter.settings.cheat * 100)}%</strong></span>
                                        <input type="range" min="0" max="1" step="0.05" value={grifter.settings.cheat}
                                            oninput={(e) => handleSettingChange(grifter.id, 'cheat', parseFloat(e.currentTarget.value))} />
                                    </label>
                                </div>
                                <div class="slider-row">
                                    <label>
                                        <span class="slider-label">Hours <strong>{Math.round(grifter.settings.hours * 100)}%</strong></span>
                                        <input type="range" min="0" max="1" step="0.05" value={grifter.settings.hours}
                                            oninput={(e) => handleSettingChange(grifter.id, 'hours', parseFloat(e.currentTarget.value))} />
                                    </label>
                                </div>
                            </div>
                        {:else if grifter.status === 'jailed'}
                            <div class="jail-section" transition:slide={{ duration: 200 }}>
                                <p class="jail-text">Awaiting release... (suspicion must reach 0)</p>
                                <button class="btn bribe-btn" onclick={() => handleBribe(grifter.id)}
                                    disabled={($gameState?.coins ?? 0) < getBribeCost(grifter)}>
                                    BRIBE OUT ({getBribeCost(grifter)}c)
                                </button>
                            </div>
                        {/if}

                        <div class="grifter-footer">
                            <span>Earned: {grifter.lifetime_coins || 0}c</span>
                            <span>Arrests: {grifter.arrests || 0}</span>
                        </div>
                    </div>
                {/each}
            </div>

        <!-- ─── SHOP TAB ─────────────────────────────────────── -->
        {:else if activeTab === 'shop'}
            <div class="shop" in:fade={{ duration: 200 }}>
                <nav class="shop-tabs">
                    <button class="tab sm" class:active={shopSubTab === 'hire'} onclick={() => shopSubTab = 'hire'}>HIRE</button>
                    <button class="tab sm" class:active={shopSubTab === 'items'} onclick={() => shopSubTab = 'items'}>EQUIPMENT</button>
                </nav>

                {#if shopSubTab === 'hire'}
                    <div class="shop-grid">
                        {#each $gameState.shop.hire_pool as hire}
                            <div class="shop-card" class:sold={hire.hired}>
                                <h4>{hire.name}</h4>
                                <div class="hire-stats">
                                    SLT {hire.stats.sleight} &middot; NRV {hire.stats.nerve} &middot; RD {hire.stats.read}
                                    {#if hire.stats.luck > 0} &middot; LCK {hire.stats.luck}{/if}
                                </div>
                                <span class="trait" title={hire.trait?.desc || ''}>{hire.trait?.name || '—'}</span>
                                {#if hire.hired}
                                    <div class="sold-tag">HIRED</div>
                                {:else}
                                    {@const canAfford = ($gameState?.coins ?? 0) >= hire.cost}
                                    <button class="btn buy-btn" onclick={() => handleHire(hire.index)}
                                        disabled={!canAfford}>
                                        HIRE ({hire.cost}c)
                                    </button>
                                    {#if !canAfford}
                                        <div class="cant-afford">Need {hire.cost - ($gameState?.coins ?? 0)} more copper</div>
                                    {/if}
                                {/if}
                            </div>
                        {/each}
                    </div>

                {:else}
                    <div class="shop-grid">
                        {#each $gameState.shop.items as item}
                            <div class="shop-card" class:sold={item.sold}>
                                <h4>{item.name}</h4>
                                <p class="item-desc">{item.desc}</p>
                                {#if item.sold}
                                    <div class="sold-tag">SOLD</div>
                                {:else}
                                    {@const canAfford = ($gameState?.coins ?? 0) >= item.cost}
                                    <div class="equip-select">
                                        <span class="equip-label">Equip to: <span class="cost-tag" class:too-expensive={!canAfford}>{item.cost}c</span></span>
                                        <div class="equip-buttons">
                                            {#each ($gameState.grifters || []).filter((g: any) => g.status === 'active') as g}
                                                <button class="btn sm" onclick={() => handleBuyItem(item.id, g.id)}
                                                    disabled={!canAfford}>
                                                    {g.name}
                                                </button>
                                            {/each}
                                        </div>
                                        {#if !canAfford}
                                            <div class="cant-afford">Need {item.cost - ($gameState?.coins ?? 0)} more</div>
                                        {/if}
                                    </div>
                                {/if}
                            </div>
                        {/each}
                    </div>
                {/if}
            </div>

        <!-- ─── LOG TAB ──────────────────────────────────────── -->
        {:else if activeTab === 'log'}
            <div class="event-log" in:fade={{ duration: 200 }}>
                {#each $gameEvents.slice().reverse() as event, i}
                    <div class="log-line {event.name?.toLowerCase()}" in:fly={{ x: -10, duration: 200, delay: Math.min(i * 30, 300) }}>
                        <span class="log-type">[{event.name}]</span>
                        <span class="log-msg">{formatEvent(event)}</span>
                        {#if (event.name === 'DAY_SUMMARY' || event.name === 'COIN_FLIP') && event.data?.flavor}
                            <span class="log-flavor">"{event.data.flavor}"</span>
                        {/if}
                    </div>
                {/each}
                {#if $gameEvents.length === 0}
                    <div class="log-empty">No events yet. Hit TICK to begin.</div>
                {/if}
            </div>
        {/if}
    </main>
{/if}

</div>
</div>

<style>
    /* ─── Splash Screen ─────────────────────────────────────────── */
    .splash-screen {
        position: fixed;
        inset: 0;
        background: #000;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        cursor: pointer;
        transition: opacity 0.4s ease-out;
    }
    .splash-fading { opacity: 0; }
    .splash-glow {
        position: absolute;
        width: 300px; height: 300px;
        border-radius: 50%;
        background: radial-gradient(circle, rgba(255,255,255,0.03) 0%, transparent 70%);
        pointer-events: none;
        animation: splashBreathe 4s ease-in-out infinite;
    }
    @keyframes splashBreathe {
        0%, 100% { transform: scale(1); opacity: 0.6; }
        50% { transform: scale(1.15); opacity: 1; }
    }
    .splash-brand {
        text-align: center;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 12px;
        position: relative;
        z-index: 1;
    }
    .splash-studio, .splash-or, .splash-tale, .splash-presents, .splash-divider {
        opacity: 0;
        transform: translateY(6px);
        transition: opacity 0.8s ease-out, transform 0.8s ease-out;
        margin: 0;
    }
    .splash-visible { opacity: 1; transform: translateY(0); }
    .splash-studio {
        font-size: 36px;
        color: #ffffff;
        letter-spacing: 8px;
        font-weight: normal;
        text-transform: lowercase;
        font-family: inherit;
        text-shadow: 0 0 30px rgba(255,255,255,0.1);
    }
    .splash-or {
        font-size: 13px;
        color: #555;
        letter-spacing: 6px;
    }
    .splash-tale {
        font-size: 28px;
        color: #888;
        letter-spacing: 3px;
        font-style: italic;
        font-weight: normal;
        text-transform: lowercase;
    }
    .splash-divider {
        width: 40px;
        height: 1px;
        background: linear-gradient(90deg, transparent, #444, transparent);
        margin: 8px 0;
    }
    .splash-presents {
        font-size: 14px;
        color: #555;
        letter-spacing: 6px;
        text-transform: lowercase;
    }

    /* ─── CRT / Scanline Effect ─────────────────────────────────── */
    .crt {
        position: relative;
        min-height: 100vh;
    }
    .scanlines {
        pointer-events: none;
        position: fixed;
        inset: 0;
        z-index: 9999;
        background: repeating-linear-gradient(
            0deg,
            transparent,
            transparent 2px,
            rgba(0, 0, 0, 0.08) 2px,
            rgba(0, 0, 0, 0.08) 4px
        );
    }

    :global(body) {
        background: #0a0a0f;
        color: #c8c8d0;
        font-family: 'Courier New', Courier, monospace;
        margin: 0;
        padding: 0;
        overflow-x: hidden;
    }

    .app {
        max-width: 1100px;
        margin: 0 auto;
        padding: 12px;
        transition: transform 0.05s;
    }
    .app.shake {
        animation: shake 0.4s ease-out;
    }
    @keyframes shake {
        0%, 100% { transform: translate(0); }
        20% { transform: translate(-3px, 2px); }
        40% { transform: translate(3px, -2px); }
        60% { transform: translate(-2px, 1px); }
        80% { transform: translate(2px, -1px); }
    }

    /* ─── Title Screen ──────────────────────────────────────────── */
    .title-screen {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        text-align: center;
    }
    .title-bg {
        padding: 60px 40px;
    }
    .coin-symbol {
        font-size: 48px;
        color: #b8860b;
        opacity: 0.3;
        margin-bottom: 10px;
    }
    .game-title {
        font-size: clamp(48px, 10vw, 80px);
        color: #daa520;
        letter-spacing: 8px;
        line-height: 0.95;
        margin: 0;
        text-shadow:
            0 0 40px rgba(218, 165, 32, 0.3),
            0 0 80px rgba(218, 165, 32, 0.1);
    }
    .tagline {
        color: #666;
        font-size: 14px;
        margin: 20px 0 30px;
        font-style: italic;
    }
    .title-details {
        color: #555;
        font-size: 12px;
        margin-bottom: 40px;
        letter-spacing: 2px;
    }
    .title-details .dot { margin: 0 8px; }
    .start-btn {
        background: transparent;
        color: #daa520;
        border: 2px solid #daa520;
        padding: 14px 50px;
        font-size: 18px;
        font-family: inherit;
        letter-spacing: 6px;
        cursor: pointer;
        transition: all 0.3s;
    }
    .start-btn:hover {
        background: #daa520;
        color: #0a0a0f;
        box-shadow: 0 0 30px rgba(218, 165, 32, 0.4);
    }
    .loading-text { color: #daa520; font-size: 14px; }
    .title-footer {
        margin-top: 60px;
        font-size: 10px;
        color: #333;
        letter-spacing: 3px;
        display: flex;
        justify-content: center;
        gap: 30px;
    }

    /* ─── Game Over ─────────────────────────────────────────────── */
    .gameover-screen {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 100vh;
        text-align: center;
    }
    .gameover-icon { font-size: 64px; color: #daa520; margin-bottom: 20px; }
    .gameover-title {
        font-size: 48px;
        letter-spacing: 8px;
        margin: 0;
        color: #daa520;
    }
    .gameover-reason {
        color: #888;
        font-size: 14px;
        margin: 20px 0 30px;
        max-width: 400px;
    }
    .gameover-stats {
        display: flex;
        gap: 40px;
        justify-content: center;
        margin-bottom: 40px;
    }
    .stat-block { display: flex; flex-direction: column; }
    .stat-val { font-size: 28px; color: #daa520; }
    .stat-label { font-size: 10px; color: #555; letter-spacing: 2px; margin-top: 4px; }

    /* ─── Header ────────────────────────────────────────────────── */
    header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 10px 16px;
        background: #111118;
        border: 1px solid #222;
        border-bottom: 2px solid #daa520;
        margin-bottom: 12px;
        position: sticky;
        top: 0;
        z-index: 100;
        gap: 12px;
        flex-wrap: wrap;
    }
    .header-left { display: flex; align-items: center; gap: 12px; }
    .logo {
        font-size: 14px;
        color: #daa520;
        letter-spacing: 4px;
        font-weight: bold;
    }
    .day-badge {
        font-size: 11px;
        color: #888;
        background: #1a1a22;
        padding: 2px 8px;
        border: 1px solid #333;
    }
    .header-center { flex: 1; max-width: 300px; }
    .treasury {
        display: flex;
        align-items: center;
        gap: 6px;
        font-size: 18px;
        transition: color 0.2s;
    }
    .treasury.flash { color: #ffd700; text-shadow: 0 0 10px rgba(255, 215, 0, 0.6); }
    .coin-icon-sm { color: #daa520; font-size: 14px; }
    .coin-value { color: #daa520; font-weight: bold; }
    .coin-target { color: #444; font-size: 12px; }
    .progress-bar {
        height: 3px;
        background: #1a1a22;
        margin-top: 4px;
        border-radius: 2px;
        overflow: hidden;
    }
    .progress-fill {
        height: 100%;
        background: linear-gradient(90deg, #daa520, #ffd700);
        transition: width 0.5s ease;
    }
    .header-right { display: flex; gap: 6px; }

    /* ─── Buttons ───────────────────────────────────────────────── */
    .btn {
        background: #1a1a22;
        color: #aaa;
        border: 1px solid #333;
        padding: 6px 14px;
        font-family: inherit;
        font-size: 11px;
        letter-spacing: 1px;
        cursor: pointer;
        transition: all 0.15s;
    }
    .btn:hover:not(:disabled) {
        border-color: #daa520;
        color: #daa520;
    }
    .btn.active {
        background: #daa520;
        color: #0a0a0f;
        border-color: #daa520;
    }
    .btn:disabled {
        opacity: 0.3;
        cursor: not-allowed;
    }
    .btn.sm { padding: 4px 8px; font-size: 10px; }

    /* ─── Districts Bar ─────────────────────────────────────────── */
    .districts-bar {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 8px;
        margin-bottom: 12px;
    }
    .district-chip {
        background: #111118;
        border: 1px solid #222;
        padding: 10px 12px;
        font-size: 11px;
    }
    .district-name {
        color: #daa520;
        font-weight: bold;
        font-size: 12px;
        margin-bottom: 4px;
    }
    .district-stats {
        display: flex;
        gap: 10px;
        color: #777;
        margin-bottom: 6px;
    }
    .heat-bar {
        height: 2px;
        background: #1a1a22;
        margin-bottom: 6px;
    }
    .heat-fill {
        height: 100%;
        background: #ff4422;
        transition: width 0.4s;
    }
    .district-flavor {
        color: #444;
        font-size: 10px;
        font-style: italic;
    }

    /* ─── Tabs ──────────────────────────────────────────────────── */
    .tabs {
        display: flex;
        gap: 0;
        margin-bottom: 12px;
        border-bottom: 1px solid #222;
    }
    .tab {
        background: transparent;
        color: #555;
        border: none;
        border-bottom: 2px solid transparent;
        padding: 8px 16px;
        font-family: inherit;
        font-size: 11px;
        letter-spacing: 2px;
        cursor: pointer;
        transition: all 0.15s;
    }
    .tab:hover { color: #999; }
    .tab.active {
        color: #daa520;
        border-bottom-color: #daa520;
    }

    /* ─── Grifter Grid ──────────────────────────────────────────── */
    .grifter-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
        gap: 10px;
    }
    .grifter-card {
        background: #111118;
        border: 1px solid #222;
        padding: 14px;
        transition: border-color 0.2s;
    }
    .grifter-card:hover { border-color: #333; }
    .grifter-card.jailed {
        border-color: #3a1111;
        background: #0f0a0a;
    }
    .grifter-top {
        display: flex;
        gap: 12px;
        margin-bottom: 10px;
    }
    .portrait-wrap { width: 60px; flex-shrink: 0; }
    .grifter-header { flex: 1; min-width: 0; }
    .name-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 4px;
    }
    .name-row h3 {
        margin: 0;
        font-size: 16px;
        color: #e0e0e0;
    }
    .status-badge {
        font-size: 9px;
        padding: 1px 6px;
        letter-spacing: 1px;
        border: 1px solid #333;
    }
    .status-badge.active { color: #4caf50; border-color: #2a4a2a; }
    .status-badge.jailed { color: #f44336; border-color: #4a2a2a; background: rgba(244, 67, 54, 0.1); }
    .stat-row {
        display: flex;
        gap: 8px;
        font-size: 10px;
        color: #666;
        margin-bottom: 4px;
    }
    .trait-row { display: flex; flex-wrap: wrap; gap: 4px; }
    .trait {
        font-size: 10px;
        padding: 1px 5px;
        color: #daa520;
        border: 1px solid #3a3520;
        background: rgba(218, 165, 32, 0.05);
    }
    .item-tag {
        font-size: 10px;
        padding: 1px 5px;
        color: #6aa0d0;
        border: 1px solid #2a3540;
        background: rgba(106, 160, 208, 0.05);
    }

    /* ─── Meters ────────────────────────────────────────────────── */
    .meters-section { margin-bottom: 8px; }
    .meter-row {
        display: flex;
        align-items: center;
        gap: 8px;
        margin-bottom: 4px;
    }
    .meter-lbl { font-size: 9px; color: #555; width: 24px; letter-spacing: 1px; }
    .meter {
        flex: 1;
        height: 6px;
        background: #1a1a22;
        border-radius: 3px;
        overflow: hidden;
    }
    .meter-fill {
        height: 100%;
        transition: width 0.4s ease;
        border-radius: 3px;
    }
    .meter-fill.fatigue { background: linear-gradient(90deg, #4caf50, #ff9800); }
    .meter-fill.suspicion { background: linear-gradient(90deg, #ff9800, #f44336); }
    .meter-val { font-size: 9px; color: #555; width: 28px; text-align: right; }
    .win-rate {
        font-size: 10px;
        color: #666;
        margin-top: 2px;
    }
    .win-rate .good { color: #4caf50; }
    .win-rate .bad { color: #f44336; }

    /* ─── Controls ──────────────────────────────────────────────── */
    .controls-section {
        border-top: 1px solid #1a1a22;
        padding-top: 10px;
    }
    .loc-row {
        margin-bottom: 8px;
        font-size: 11px;
    }
    .loc-row select {
        background: #0a0a0f;
        color: #daa520;
        border: 1px solid #333;
        padding: 3px 6px;
        font-family: inherit;
        font-size: 11px;
        margin-left: 6px;
    }
    .slider-row { margin-bottom: 6px; }
    .slider-row label { display: block; }
    .slider-label {
        display: flex;
        justify-content: space-between;
        font-size: 10px;
        color: #666;
        margin-bottom: 2px;
    }
    .slider-row input[type="range"] {
        width: 100%;
        height: 4px;
        accent-color: #daa520;
    }

    /* ─── Jail ──────────────────────────────────────────────────── */
    .jail-section {
        border-top: 1px solid #2a1515;
        padding-top: 10px;
        text-align: center;
    }
    .jail-text {
        font-size: 10px;
        color: #663333;
        font-style: italic;
        margin-bottom: 8px;
    }
    .bribe-btn { width: 100%; }

    /* ─── Footer ────────────────────────────────────────────────── */
    .grifter-footer {
        display: flex;
        justify-content: space-between;
        font-size: 9px;
        color: #444;
        margin-top: 8px;
        padding-top: 6px;
        border-top: 1px solid #1a1a22;
    }

    /* ─── Shop ──────────────────────────────────────────────────── */
    .shop-tabs {
        display: flex;
        gap: 4px;
        margin-bottom: 12px;
    }
    .shop-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
        gap: 10px;
    }
    .shop-card {
        background: #111118;
        border: 1px solid #222;
        padding: 14px;
    }
    .shop-card.sold { opacity: 0.4; }
    .shop-card h4 {
        color: #daa520;
        margin: 0 0 6px;
        font-size: 14px;
    }
    .hire-stats {
        font-size: 10px;
        color: #666;
        margin-bottom: 6px;
    }
    .item-desc {
        font-size: 11px;
        color: #777;
        margin: 0 0 10px;
    }
    .sold-tag {
        font-size: 10px;
        color: #555;
        letter-spacing: 2px;
        margin-top: 8px;
    }
    .buy-btn { width: 100%; margin-top: 8px; }
    .equip-select {
        margin-top: 8px;
        font-size: 10px;
        color: #666;
    }
    .equip-label { display: block; margin-bottom: 6px; }
    .cost-tag { color: #daa520; font-weight: bold; }
    .cost-tag.too-expensive { color: #f44336; }
    .equip-buttons {
        display: flex;
        flex-wrap: wrap;
        gap: 4px;
    }
    .cant-afford {
        font-size: 9px;
        color: #663333;
        margin-top: 4px;
        font-style: italic;
    }

    /* ─── Event Log ─────────────────────────────────────────────── */
    .event-log {
        background: #0a0a0f;
        border: 1px solid #1a1a22;
        padding: 12px;
        max-height: 500px;
        overflow-y: auto;
        font-size: 11px;
    }
    .log-line {
        padding: 4px 0;
        border-bottom: 1px solid #111118;
        line-height: 1.5;
    }
    .log-type {
        color: #333;
        font-size: 9px;
        margin-right: 6px;
    }
    .log-msg { color: #888; }
    .log-flavor {
        display: block;
        color: #444;
        font-style: italic;
        font-size: 10px;
        margin-top: 1px;
    }
    .log-line.day_summary .log-msg { color: #aaa; }
    .log-line.coin_flip .log-msg { color: #777; }
    .log-line.arrest { border-left: 2px solid #f44336; padding-left: 8px; }
    .log-line.arrest .log-msg { color: #f44336; font-weight: bold; }
    .log-line.released .log-msg { color: #4caf50; }
    .log-line.event { border-left: 2px solid #daa520; padding-left: 8px; }
    .log-line.event .log-msg { color: #daa520; }
    .log-line.bribe .log-msg { color: #9c27b0; }
    .log-line.hired .log-msg { color: #2196f3; }
    .log-line.suspicion_spike .log-msg { color: #ff9800; }
    .log-empty { color: #333; text-align: center; padding: 40px; }

    /* ─── Responsive ────────────────────────────────────────────── */
    @media (max-width: 600px) {
        header { flex-direction: column; gap: 8px; }
        .grifter-grid { grid-template-columns: 1fr; }
        .districts-bar { grid-template-columns: 1fr; }
    }
</style>
