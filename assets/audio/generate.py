#!/usr/bin/env python3
"""Generate a simple looping 8-bit chiptune BGM for RAMEN-YA.

Square-wave melody + pulse bass + kick/hat, all in C-major pentatonic so it
stays consonant on an endless loop. Mono 22050 Hz 16-bit WAV (~0.6 MB).
Regenerate with:  python3 assets/audio/generate.py
"""
import numpy as np
import wave
import os

SR = 22050
BPM = 132
BEAT = 60.0 / BPM
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bgm.wav")
np.random.seed(7)


def tone(midi, dur, vol=0.2, duty=0.5):
    n = int(SR * dur)
    if midi is None:
        return np.zeros(n)
    freq = 440.0 * 2 ** ((midi - 69) / 12.0)
    t = np.arange(n) / SR
    ph = (t * freq) % 1.0
    w = np.where(ph < duty, 1.0, -1.0) * vol
    env = np.ones(n)
    a, r = int(0.004 * SR), int(0.03 * SR)
    if a > 0:
        env[:a] = np.linspace(0, 1, a)
    if r > 0:
        env[-r:] = np.linspace(1, 0, r)
    env *= np.linspace(1.0, 0.72, n)          # slight pluck decay
    return w * env


def kick(dur=0.12, vol=0.5):
    n = int(SR * dur)
    t = np.arange(n) / SR
    freq = 120 * np.exp(-26 * t) + 46
    ph = 2 * np.pi * np.cumsum(freq) / SR
    return np.sin(ph) * vol * np.exp(-17 * t)


def hat(dur=0.03, vol=0.07):
    n = int(SR * dur)
    t = np.arange(n) / SR
    return (np.random.rand(n) * 2 - 1) * vol * np.exp(-120 * t)


# --- melody: 8 bars, one note per quarter (C-major pentatonic) ---
MEL = [
    64, 67, 69, 67,      # E G A G
    69, 72, 69, 67,      # A C5 A G
    67, 69, 67, 64,      # G A G E
    62, 64, 60, None,    # D E C  -
    64, 67, 72, 69,      # E G C5 A
    69, 67, 64, 62,      # A G E D
    67, 64, 62, 64,      # G E D E
    60, None, 60, None,  # C  -  C  -
]
melody = np.concatenate([tone(m, BEAT, 0.22) for m in MEL])

# --- bass: pulsing root–root–fifth–root per bar ---
ROOTS = [48, 45, 43, 48, 48, 45, 43, 43]      # C A G C C A G G (low)
bass = np.concatenate([
    tone(q, BEAT, 0.17, 0.5)
    for r in ROOTS for q in (r, r, r + 7, r)
])

# --- drums: kick on beats 1 & 3, hat on every off-beat ---
perc = []
seg_n = int(SR * BEAT)
for _bar in range(8):
    for q in range(4):
        seg = np.zeros(seg_n)
        if q in (0, 2):
            k = kick()
            seg[:len(k)] += k[:seg_n]
        h = hat()
        mid = seg_n // 2
        seg[mid:mid + len(h)] += h[:seg_n - mid]
        perc.append(seg)
perc = np.concatenate(perc)

# --- mix + normalise ---
L = min(len(melody), len(bass), len(perc))
mix = melody[:L] + bass[:L] + perc[:L]
mix = mix / (np.max(np.abs(mix)) + 1e-6) * 0.9
pcm = (mix * 32767).astype("<i2")

with wave.open(OUT, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())

print("wrote", OUT, "frames:", L, "dur: %.2fs" % (L / SR), "size: %.0fKB" % (len(pcm) * 2 / 1024))


# ---- one-shot 8-bit sword-hit SFX (assets/audio/hit.wav) ------------
def sfx_hit():
    dur = 0.16
    n = int(SR * dur)
    t = np.arange(n) / SR
    # slash: noise burst with a fast decay
    noise = (np.random.rand(n) * 2 - 1) * np.exp(-34.0 * t) * 0.55
    # clang: square blip falling in pitch
    freq = np.linspace(680.0, 170.0, n)
    sq = np.sign(np.sin(2 * np.pi * np.cumsum(freq) / SR)) * np.exp(-26.0 * t) * 0.4
    mix = noise + sq
    mix = mix / (np.max(np.abs(mix)) + 1e-6) * 0.92
    return (mix * 32767).astype("<i2")


HIT_OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hit.wav")
_hit = sfx_hit()
with wave.open(HIT_OUT, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(_hit.tobytes())
print("wrote", HIT_OUT, "dur: %.2fs" % (len(_hit) / SR))
