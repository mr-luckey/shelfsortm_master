"""Generate snappy game SFX + quieter pleasant BGM (no delay-friendly short clips)."""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import wave

SR = 44100
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def write_wav(name: str, samples: np.ndarray) -> None:
    data = np.clip(samples.astype(np.float64), -1.0, 1.0)
    pcm = (data * 32767.0).astype(np.int16)
    path = OUT / name
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"wrote {path.name} ({len(pcm) / SR * 1000:.0f}ms)")


def env(n: int, attack: float, release: float) -> np.ndarray:
    a = max(1, int(SR * attack))
    r = max(1, int(SR * release))
    e = np.ones(n, dtype=np.float64)
    e[:a] = np.linspace(0.0, 1.0, a, endpoint=False)
    if r < n:
        e[-r:] *= np.linspace(1.0, 0.0, r)
    return e


def sine(freq: float, dur: float, vol: float, attack=0.002, release=0.05) -> np.ndarray:
    n = max(1, int(SR * dur))
    t = np.arange(n) / SR
    return np.sin(2 * math.pi * freq * t) * vol * env(n, attack, release)


def noise_burst(dur: float, vol: float, attack=0.001, release=0.04) -> np.ndarray:
    n = max(1, int(SR * dur))
    rng = np.random.default_rng(42)
    x = rng.normal(0.0, 1.0, n)
    # light lowpass
    y = np.zeros(n)
    a = 0.22
    for i in range(1, n):
        y[i] = y[i - 1] + a * (x[i] - y[i - 1])
    return y * vol * env(n, attack, release)


def overlay(base: np.ndarray, add: np.ndarray, at: float = 0.0) -> np.ndarray:
    start = int(SR * at)
    n = max(len(base), start + len(add))
    out = np.zeros(n, dtype=np.float64)
    out[: len(base)] += base
    out[start : start + len(add)] += add
    return out


def gen_tap() -> np.ndarray:
    """Very short UI click (~35ms) — crisp, no laggy tail."""
    click = noise_burst(0.018, 0.35, 0.0005, 0.014)
    tick = sine(1400, 0.028, 0.18, 0.0005, 0.022)
    return overlay(click, tick, 0.0)


def gen_place() -> np.ndarray:
    """Classic soft product put / plastic-wood 'thock' like match-sort games."""
    # transient pop
    pop = noise_burst(0.025, 0.45, 0.0004, 0.02)
    # body thock
    body = sine(210, 0.09, 0.42, 0.001, 0.07)
    body2 = sine(140, 0.11, 0.22, 0.003, 0.08)
    # tiny bright tip (product surface)
    tip = sine(980, 0.035, 0.12, 0.0005, 0.03)
    out = overlay(pop, body, 0.0)
    out = overlay(out, body2, 0.008)
    out = overlay(out, tip, 0.002)
    peak = np.max(np.abs(out)) or 1.0
    return out / peak * 0.85


def gen_match() -> np.ndarray:
    a = sine(659.25, 0.09, 0.28, 0.002, 0.07)
    b = sine(830.61, 0.11, 0.22, 0.002, 0.09)
    c = sine(1046.5, 0.14, 0.16, 0.002, 0.11)
    return overlay(overlay(a, b, 0.05), c, 0.10)


def gen_combo() -> np.ndarray:
    out = np.zeros(1)
    for i, f in enumerate([523.25, 659.25, 783.99, 987.77]):
        out = overlay(out, sine(f, 0.1, 0.22 - i * 0.02, 0.002, 0.08), i * 0.04)
    return out


def gen_win() -> np.ndarray:
    out = np.zeros(1)
    for i, f in enumerate([392.0, 523.25, 659.25, 783.99]):
        out = overlay(out, sine(f, 0.16, 0.2, 0.005, 0.12), i * 0.09)
    return out


def gen_invalid() -> np.ndarray:
    return overlay(sine(160, 0.1, 0.28, 0.002, 0.08), sine(120, 0.12, 0.18, 0.004, 0.09), 0.02)


def gen_whoosh() -> np.ndarray:
    n = int(SR * 0.18)
    t = np.arange(n) / SR
    x = noise_burst(0.18, 0.28, 0.01, 0.08)
    return x * (0.3 + 0.7 * (1 - t / 0.18))


def gen_bgm() -> np.ndarray:
    """Soft quiet lo-fi pluck loop (~20s), low volume friendly under SFX."""
    dur = 20.0
    n = int(SR * dur)
    out = np.zeros(n, dtype=np.float64)
    # gentle arpeggio motif in C major pentatonic
    motif = [261.63, 293.66, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66]
    step = 0.5  # seconds per note
    t0 = 0.0
    while t0 < dur - 0.6:
        for f in motif:
            if t0 >= dur - 0.4:
                break
            # soft pluck = sine + quiet octave, long release
            note = sine(f, 0.55, 0.09, 0.01, 0.45)
            note = overlay(note, sine(f * 2, 0.4, 0.025, 0.01, 0.35), 0.0)
            out = overlay(out, note, t0)
            t0 += step
        t0 += 0.25  # breath between phrases

    if len(out) < n:
        tmp = np.zeros(n, dtype=np.float64)
        tmp[: len(out)] = out
        out = tmp
    else:
        out = out[:n]

    # very soft pad underneath
    t = np.arange(n) / SR
    pad = 0.035 * np.sin(2 * math.pi * 130.81 * t)
    pad += 0.025 * np.sin(2 * math.pi * 196.0 * t)
    pad *= 0.5 + 0.5 * np.sin(2 * math.pi * 0.05 * t)
    out += pad * env(n, 1.2, 1.2)

    # loop crossfade
    cross = int(SR * 0.5)
    fade_in = np.linspace(0, 1, cross)
    fade_out = np.linspace(1, 0, cross)
    head = out[:cross].copy()
    out[:cross] = head * fade_in + out[-cross:] * fade_out

    peak = np.max(np.abs(out)) or 1.0
    return out / peak * 0.22  # keep music soft


def gen_praise(freqs: tuple[float, float]) -> np.ndarray:
    a, b = freqs
    return overlay(sine(a, 0.12, 0.2, 0.004, 0.09), sine(b, 0.16, 0.16, 0.006, 0.12), 0.05)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav("sfx_tap.wav", gen_tap())
    write_wav("sfx_place.wav", gen_place())
    write_wav("sfx_match.wav", gen_match())
    write_wav("sfx_combo.wav", gen_combo())
    write_wav("sfx_win.wav", gen_win())
    write_wav("sfx_invalid.wav", gen_invalid())
    write_wav("sfx_whoosh.wav", gen_whoosh())
    write_wav("sfx_pick.wav", gen_tap())
    write_wav("bgm_calm_loop.wav", gen_bgm())
    pairs = [
        (523.25, 659.25),
        (587.33, 739.99),
        (659.25, 830.61),
        (698.46, 880.0),
        (783.99, 987.77),
    ]
    names = [
        "voice_nice.wav",
        "voice_great.wav",
        "voice_awesome.wav",
        "voice_perfect.wav",
        "voice_amazing.wav",
    ]
    for name, pair in zip(names, pairs):
        write_wav(name, gen_praise(pair))


if __name__ == "__main__":
    main()
