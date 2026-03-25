
<script lang="ts">
    interface Props {
        id: number;
        status: string;
    }

    let { id, status }: Props = $props();

    function hash(n: number, salt: number): number {
        let h = ((n * 2654435761 + salt * 2246822519) >>> 0) % 1000;
        return h;
    }

    function pick(salt: number, max: number): number {
        return hash(id, salt) % max;
    }

    // More face variety
    const faces = [
        "M 22,50 Q 22,18 50,18 Q 78,18 78,50 Q 78,82 50,88 Q 22,82 22,50",
        "M 26,28 L 74,28 L 76,75 Q 50,92 24,75 Z",
        "M 32,18 Q 50,14 68,18 L 78,68 Q 50,88 22,68 Z",
        "M 50,16 Q 80,22 78,55 Q 76,85 50,90 Q 24,85 22,55 Q 20,22 50,16",
        "M 28,24 Q 50,16 72,24 Q 80,45 76,70 Q 50,90 24,70 Q 20,45 28,24",
    ];

    const eyes = [
        { shape: 'circle', r: 4 },
        { shape: 'circle', r: 6, pupil: 2 },
        { shape: 'slit', w: 8, h: 3 },
        { shape: 'circle', r: 5, pupil: 3 },
        { shape: 'dot', r: 2 },
    ];

    const mouths = [
        "M 38,70 Q 50,77 62,70",
        "M 38,75 Q 50,68 62,75",
        "M 40,72 L 60,72",
        "M 42,71 Q 50,74 58,71",
        "M 38,73 Q 44,70 50,73 Q 56,70 62,73",
    ];

    const noses = [
        "M 50,52 L 47,60 L 53,60",
        "M 50,54 L 50,62",
        "M 48,58 Q 50,62 52,58",
        "",
    ];

    const colors = ["#d4af37", "#c0c0c0", "#cd7f32", "#8fbc8f", "#b0c4de", "#deb887", "#bc8f8f"];
    const scarColors = ["#8b0000", "#4a4a4a", "#2f4f4f"];

    let faceIdx = $derived(pick(1, faces.length));
    let eyeIdx = $derived(pick(2, eyes.length));
    let mouthIdx = $derived(pick(3, mouths.length));
    let noseIdx = $derived(pick(4, noses.length));
    let colorIdx = $derived(pick(5, colors.length));
    let hairType = $derived(pick(6, 6));
    let hasScar = $derived(pick(7, 5) === 0);
    let scarIdx = $derived(pick(8, scarColors.length));

    let mainColor = $derived(status === 'jailed' ? '#444' : colors[colorIdx]);
</script>

<svg viewBox="0 0 100 100" class="portrait" class:jailed={status === 'jailed'}>
    <defs>
        <radialGradient id="bg-{id}" cx="50%" cy="40%" r="50%">
            <stop offset="0%" stop-color="#1a1a22" />
            <stop offset="100%" stop-color="#0a0a0f" />
        </radialGradient>
    </defs>

    <circle cx="50" cy="50" r="46" fill="url(#bg-{id})" stroke={mainColor} stroke-width="1.5" opacity="0.8" />

    <!-- Face -->
    <path d={faces[faceIdx]} fill="#161620" stroke={mainColor} stroke-width="1.2" />

    <!-- Eyes -->
    <g fill={mainColor}>
        {#if eyes[eyeIdx].shape === 'circle'}
            <circle cx="37" cy="44" r={eyes[eyeIdx].r} />
            <circle cx="63" cy="44" r={eyes[eyeIdx].r} />
            {#if eyes[eyeIdx].pupil}
                <circle cx="37" cy="44" r={eyes[eyeIdx].pupil} fill="#0a0a0f" />
                <circle cx="63" cy="44" r={eyes[eyeIdx].pupil} fill="#0a0a0f" />
            {/if}
        {:else if eyes[eyeIdx].shape === 'slit'}
            <ellipse cx="37" cy="44" rx={eyes[eyeIdx].w! / 2} ry={eyes[eyeIdx].h! / 2} />
            <ellipse cx="63" cy="44" rx={eyes[eyeIdx].w! / 2} ry={eyes[eyeIdx].h! / 2} />
        {:else}
            <circle cx="37" cy="44" r={eyes[eyeIdx].r} />
            <circle cx="63" cy="44" r={eyes[eyeIdx].r} />
        {/if}
    </g>

    <!-- Nose -->
    {#if noses[noseIdx]}
        <path d={noses[noseIdx]} fill="none" stroke={mainColor} stroke-width="1" opacity="0.5" />
    {/if}

    <!-- Mouth -->
    <path d={mouths[mouthIdx]} fill="none" stroke={mainColor} stroke-width="1.5" stroke-linecap="round" />

    <!-- Hair/Hat -->
    {#if hairType === 0}
        <path d="M 28,24 Q 38,8 62,10 Q 72,12 72,24" fill="none" stroke={mainColor} stroke-width="3" />
    {:else if hairType === 1}
        <rect x="24" y="13" width="52" height="8" rx="2" fill={mainColor} opacity="0.7" />
    {:else if hairType === 2}
        <path d="M 30,22 Q 35,10 50,8 Q 65,10 70,22" fill={mainColor} opacity="0.4" />
    {:else if hairType === 3}
        <circle cx="50" cy="14" r="8" fill="none" stroke={mainColor} stroke-width="1.5" />
    {:else if hairType === 4}
        <path d="M 24,28 Q 24,8 50,8 Q 76,8 76,28" fill="none" stroke={mainColor} stroke-width="2" />
        <line x1="50" y1="8" x2="50" y2="3" stroke={mainColor} stroke-width="1.5" />
    {/if}

    <!-- Scar (rare) -->
    {#if hasScar}
        <line x1="28" y1="38" x2="42" y2="56" stroke={scarColors[scarIdx]} stroke-width="1.5" opacity="0.6" />
    {/if}

    <!-- Jail bars -->
    {#if status === 'jailed'}
        <g stroke="#5a1111" stroke-width="2.5" opacity="0.7">
            <line x1="20" y1="8" x2="20" y2="92" />
            <line x1="38" y1="8" x2="38" y2="92" />
            <line x1="56" y1="8" x2="56" y2="92" />
            <line x1="74" y1="8" x2="74" y2="92" />
        </g>
    {/if}
</svg>

<style>
    .portrait {
        width: 100%;
        height: auto;
        display: block;
    }
    .jailed {
        filter: grayscale(0.8) brightness(0.7);
    }
</style>
