
class AudioManager {
    private ctx: AudioContext | null = null;

    init() {
        if (!this.ctx) {
            this.ctx = new AudioContext();
        }
        if (this.ctx.state === 'suspended') {
            this.ctx.resume();
        }
    }

    private playTone(type: OscillatorType, freqStart: number, freqEnd: number, duration: number, volume: number = 0.1) {
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = type;
        osc.frequency.setValueAtTime(freqStart, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(Math.max(freqEnd, 20), this.ctx.currentTime + duration);
        gain.gain.setValueAtTime(volume, this.ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + duration);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + duration);
    }

    playCoin(win: boolean) {
        if (win) {
            this.playTone('sine', 660, 1320, 0.12, 0.08);
        } else {
            this.playTone('sine', 330, 165, 0.15, 0.05);
        }
    }

    playArrest() {
        if (!this.ctx) return;
        // Two-tone alarm
        this.playTone('sawtooth', 180, 90, 0.3, 0.12);
        setTimeout(() => this.playTone('sawtooth', 140, 70, 0.3, 0.10), 150);
    }

    playEvent() {
        this.playTone('triangle', 440, 880, 0.2, 0.06);
    }

    playBribe() {
        if (!this.ctx) return;
        this.playTone('sine', 330, 660, 0.1, 0.08);
        setTimeout(() => this.playTone('sine', 660, 1320, 0.15, 0.06), 100);
    }

    playHire() {
        if (!this.ctx) return;
        this.playTone('triangle', 440, 660, 0.1, 0.07);
        setTimeout(() => this.playTone('triangle', 660, 880, 0.1, 0.07), 100);
        setTimeout(() => this.playTone('triangle', 880, 1100, 0.15, 0.06), 200);
    }

    playBuy() {
        this.playTone('sine', 880, 440, 0.15, 0.06);
    }

    playWin() {
        if (!this.ctx) return;
        [440, 554, 659, 880].forEach((f, i) => {
            setTimeout(() => this.playTone('sine', f, f * 1.5, 0.3, 0.08), i * 150);
        });
    }

    playLose() {
        if (!this.ctx) return;
        [440, 370, 311, 220].forEach((f, i) => {
            setTimeout(() => this.playTone('sawtooth', f, f * 0.5, 0.4, 0.06), i * 200);
        });
    }
}

export const audio = new AudioManager();
