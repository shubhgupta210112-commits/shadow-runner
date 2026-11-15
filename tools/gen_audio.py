"""Synthesise every sound in SHADOW RUNNER (original chiptune/ambient audio).

SFX -> assets/audio/sfx/*.wav     Music + ambience -> assets/audio/music|ambient/*.ogg
Run:  python3 tools/gen_audio.py     (needs numpy, scipy, ffmpeg with libvorbis)
"""
import math
import os
import random
import subprocess
import tempfile
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'audio')
RNG = np.random.default_rng(42)


def hz(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def t_arr(dur):
    return np.arange(int(SR * dur)) / SR


def osc(kind, freq, dur, duty=0.5):
    """freq may be scalar or array (len = samples)."""
    t = t_arr(dur)
    if np.isscalar(freq):
        ph = (t * freq) % 1.0
    else:
        f = np.resize(freq, len(t))
        ph = (np.cumsum(f) / SR) % 1.0
    if kind == 'sq':
        return np.where(ph < duty, 1.0, -1.0)
    if kind == 'tri':
        return 4 * np.abs(ph - 0.5) - 1
    if kind == 'saw':
        return 2 * ph - 1
    if kind == 'sin':
        return np.sin(ph * math.tau)
    if kind == 'noise':
        return RNG.uniform(-1, 1, len(t))
    raise ValueError(kind)


def env(n, a=0.005, d=0.05, s=0.6, r=0.05):
    """ADSR over n samples (a,d,r in seconds)."""
    e = np.ones(n)
    ai, di, ri = int(a * SR), int(d * SR), int(r * SR)
    ai = min(ai, n)
    if ai > 0:
        e[:ai] = np.linspace(0, 1, ai)
    di = min(di, max(0, n - ai))
    if di > 0:
        e[ai:ai + di] = np.linspace(1, s, di)
    e[ai + di:] = s
    ri = min(ri, n)
    if ri > 0:
        e[n - ri:] *= np.linspace(1, 0, ri)
    return e


def decay_env(n, k=6.0):
    return np.exp(-np.linspace(0, k, n))


def lp(x, cutoff, order=2):
    sos = butter(order, cutoff / (SR / 2), btype='low', output='sos')
    return sosfilt(sos, x)


def hp(x, cutoff, order=2):
    sos = butter(order, cutoff / (SR / 2), btype='high', output='sos')
    return sosfilt(sos, x)


def sweep(f0, f1, dur, curve=1.0):
    t = np.linspace(0, 1, int(SR * dur)) ** curve
    return f0 + (f1 - f0) * t


def norm(x, peak=0.9):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


def write_wav(path, x):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    wavfile.write(path, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))


def to_ogg(x, path, q=4):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        w = os.path.join(td, 'a.wav')
        wavfile.write(w, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', w, '-c:a', 'libvorbis', '-q:a', str(q), path], check=True)


def echo(x, delay, fb=0.35, mix=0.35, taps=4):
    d = int(delay * SR)
    out = x.copy()
    cur = x
    for i in range(taps):
        cur = np.concatenate([np.zeros(d), cur])[:len(x)] * fb
        out = out + cur * mix
    return out


def reverb(x, mix=0.18):
    out = x.copy()
    for dly, g in ((0.029, 0.5), (0.037, 0.4), (0.053, 0.33), (0.071, 0.25)):
        d = int(dly * SR)
        out[d:] += x[:-d] * g * mix * 2
    return out


# =============================================================== SFX
def sfx():
    S = {}
    n = lambda d: int(SR * d)

    s = osc('sq', sweep(280, 620, 0.17), 0.17, 0.4) * env(n(0.17), 0.002, 0.04, 0.5, 0.06) * 0.7
    S['jump'] = s

    s = lp(osc('noise', 0, 0.09), 900) * decay_env(n(0.09), 5) * 1.0 + osc('sin', sweep(120, 60, 0.09), 0.09) * decay_env(n(0.09), 4) * 0.6
    S['land'] = s

    a = osc('sq', 988, 0.06, 0.25) * env(n(0.06), 0.001, 0.02, 0.8, 0.01)
    b = osc('sq', 1319, 0.14, 0.25) * env(n(0.14), 0.001, 0.03, 0.7, 0.08)
    S['coin'] = np.concatenate([a, b]) * 0.55

    notes = [76, 80, 83, 88, 92]
    parts = []
    for i, m in enumerate(notes):
        d = 0.07 if i < 4 else 0.3
        parts.append((osc('tri', hz(m), d) + 0.4 * osc('sin', hz(m + 12), d)) * env(n(d), 0.002, 0.05, 0.6, 0.06 if i < 4 else 0.2))
    S['shard'] = np.concatenate(parts) * 0.6

    parts = [osc('sq', hz(m), 0.09, 0.5) * env(n(0.09), 0.002, 0.03, 0.7, 0.03) for m in (72, 76, 79, 84)]
    S['heal'] = np.concatenate(parts) * 0.5

    s = osc('saw', sweep(420, 90, 0.34), 0.34) * env(n(0.34), 0.002, 0.1, 0.5, 0.1) * 0.6
    s += lp(osc('noise', 0, 0.34), 2500) * decay_env(n(0.34), 5) * 0.5
    S['hurt'] = s

    s = osc('sq', sweep(1000, 380, 0.15), 0.15, 0.3) * env(n(0.15), 0.001, 0.04, 0.5, 0.06) * 0.55
    s += hp(osc('noise', 0, 0.15), 3000) * decay_env(n(0.15), 7) * 0.25
    S['shoot'] = s

    s = osc('sq', sweep(500, 90, 0.22), 0.22, 0.5) * decay_env(n(0.22), 4) * 0.6
    s += lp(osc('noise', 0, 0.22), 4000) * decay_env(n(0.22), 6) * 0.5
    S['enemy_die'] = s

    s = osc('sin', sweep(220, 70, 0.14), 0.14) * decay_env(n(0.14), 5) * 0.9
    s += hp(osc('noise', 0, 0.03), 2000) * decay_env(n(0.03), 3) * 0.4 if False else 0
    c = np.zeros(n(0.14))
    c[:n(0.03)] = hp(osc('noise', 0, 0.03), 2000) * decay_env(n(0.03), 3) * 0.4
    S['stomp'] = s + c

    parts = [osc('tri', hz(m), 0.12) * env(n(0.12), 0.003, 0.05, 0.6, 0.08) for m in (69, 76, 81)]
    parts.append((osc('tri', hz(88), 0.5) + 0.3 * osc('sin', hz(100), 0.5)) * env(n(0.5), 0.003, 0.2, 0.4, 0.3))
    S['checkpoint'] = reverb(np.concatenate(parts) * 0.6, 0.35)

    s = osc('sq', sweep(160, 70, 0.12), 0.12, 0.5) * decay_env(n(0.12), 4) * 0.7
    s += lp(osc('noise', 0, 0.12), 1800) * decay_env(n(0.12), 6) * 0.6
    s2 = osc('sq', sweep(300, 220, 0.1), 0.1, 0.25) * decay_env(n(0.1), 4) * 0.4
    S['lever'] = np.concatenate([s, s2])

    s = lp(osc('noise', 0, 1.1), 700) * env(n(1.1), 0.05, 0.3, 0.7, 0.4) * 0.9
    s += osc('saw', sweep(60, 110, 1.1), 1.1) * env(n(1.1), 0.05, 0.3, 0.5, 0.4) * 0.3
    S['gate'] = s

    S['ui_move'] = osc('sq', 660, 0.045, 0.25) * env(n(0.045), 0.001, 0.01, 0.8, 0.02) * 0.4
    S['ui_select'] = np.concatenate([osc('sq', 784, 0.05, 0.5), osc('sq', 1175, 0.11, 0.5)]) * 0.45 * np.concatenate([env(n(0.05), 0.001, 0.01, 0.9, 0.01), env(n(0.11), 0.001, 0.03, 0.7, 0.06)])
    S['ui_back'] = np.concatenate([osc('sq', 523, 0.05, 0.5), osc('sq', 392, 0.1, 0.5)]) * 0.4 * np.concatenate([env(n(0.05), 0.001, 0.01, 0.9, 0.01), env(n(0.1), 0.001, 0.03, 0.7, 0.06)])
    S['ui_pause'] = osc('tri', sweep(440, 880, 0.12), 0.12) * env(n(0.12), 0.003, 0.04, 0.6, 0.05) * 0.6

    # spore pop
    s = osc('sin', sweep(500, 220, 0.2, 0.6), 0.2) * decay_env(n(0.2), 4) * 0.7
    s += lp(osc('noise', 0, 0.2), 1500) * decay_env(n(0.2), 8) * 0.3
    S['spore'] = s

    # boss
    d = 1.1
    vib = 1 + 0.03 * np.sin(t_arr(d) * math.tau * 18)
    s = osc('saw', sweep(95, 50, d) * vib, d) * env(n(d), 0.03, 0.3, 0.7, 0.4) * 0.6
    s += lp(osc('noise', 0, d), 1200) * env(n(d), 0.02, 0.3, 0.6, 0.4) * 0.5
    S['boss_roar'] = lp(s, 2200)
    s = osc('sin', sweep(200, 50, 0.2), 0.2) * decay_env(n(0.2), 4) * 0.9 + lp(osc('noise', 0, 0.2), 3000) * decay_env(n(0.2), 7) * 0.7
    S['boss_hit'] = s
    d = 0.7
    s = lp(osc('noise', 0, d), 500) * decay_env(n(d), 4) * 1.2 + osc('sin', sweep(90, 30, d), d) * decay_env(n(d), 3.5) * 1.0
    S['boss_slam'] = s
    d = 0.5
    s = lp(osc('noise', 0, d), 1800) * env(n(d), 0.3, 0.1, 0.6, 0.1) * 0.8 + osc('saw', sweep(70, 140, d), d) * env(n(d), 0.3, 0.1, 0.6, 0.1) * 0.3
    S['boss_charge'] = s
    d = 2.2
    s = lp(osc('noise', 0, d), 2500) * decay_env(n(d), 2.5) * 1.0
    s += osc('saw', sweep(240, 30, d), d) * decay_env(n(d), 2.5) * 0.6
    s += osc('sq', sweep(900, 100, d, 0.5), d, 0.5) * decay_env(n(d), 5) * 0.3
    S['boss_defeat'] = reverb(s, 0.3)

    # jingles
    mel = [(69, .14), (72, .14), (76, .14), (81, .28), (79, .14), (84, .5)]
    parts = [(osc('sq', hz(m), d, 0.25) * 0.5 + osc('tri', hz(m - 12), d) * 0.5) * env(n(d), 0.003, 0.05, 0.7, 0.06) for m, d in mel]
    j = np.concatenate(parts)
    S['victory'] = reverb(j * 0.7, 0.4)
    mel = [(69, .22), (66, .22), (62, .22), (57, .7)]
    parts = [(osc('sq', hz(m), d, 0.5) * 0.4 + osc('tri', hz(m - 12), d) * 0.6) * env(n(d), 0.003, 0.08, 0.7, 0.1) for m, d in mel]
    S['game_over'] = reverb(np.concatenate(parts) * 0.7, 0.4)
    # respawn whoosh
    d = 0.4
    s = hp(osc('noise', 0, d), 1500) * env(n(d), 0.15, 0.1, 0.5, 0.15) * 0.4 + osc('sin', sweep(300, 900, d), d) * env(n(d), 0.1, 0.1, 0.5, 0.2) * 0.4
    S['respawn'] = s
    return S


# =============================================================== MUSIC
class Track:
    def __init__(self, bpm, bars, beats=4):
        self.bpm = bpm
        self.spb = 60.0 / bpm
        self.bars = bars
        self.beats = beats
        self.len = int(self.spb * beats * bars * SR)
        self.buf = {k: np.zeros(self.len + SR * 3) for k in ('bass', 'arp', 'pad', 'lead', 'drum', 'bell')}

    def pos(self, bar, beat):
        return int((bar * self.beats + beat) * self.spb * SR)

    def note(self, layer, kind, midi, bar, beat, dur_beats, vol=0.3, duty=0.5, a=0.004, d=0.05, s=0.6, r=0.05, vib=0.0):
        dur = dur_beats * self.spb
        f = hz(midi)
        if vib:
            f = f * (1 + vib * np.sin(t_arr(dur) * math.tau * 5.5))
        x = osc(kind, f, dur + 0.05, duty)
        x = x * env(len(x), a, d, s, r) * vol
        p = self.pos(bar, beat)
        self.buf[layer][p:p + len(x)] += x[:len(self.buf[layer]) - p]

    def drum(self, kind, bar, beat, vol=0.5):
        p = self.pos(bar, beat)
        if kind == 'kick':
            x = osc('sin', sweep(150, 45, 0.18), 0.18) * decay_env(int(SR * 0.18), 5) * vol * 1.4
        elif kind == 'snare':
            x = hp(osc('noise', 0, 0.16), 1500) * decay_env(int(SR * 0.16), 7) * vol
            body = osc('sin', sweep(220, 150, 0.1), 0.1) * decay_env(int(SR * 0.1), 6) * vol * 0.5
            x[:len(body)] += body
        elif kind == 'hat':
            x = hp(osc('noise', 0, 0.05), 6000) * decay_env(int(SR * 0.05), 7) * vol * 0.5
        elif kind == 'ohat':
            x = hp(osc('noise', 0, 0.18), 5500) * decay_env(int(SR * 0.18), 4) * vol * 0.4
        else:
            return
        self.buf['drum'][p:p + len(x)] += x[:len(self.buf['drum']) - p]

    def mix(self, gains, loop_tail=True):
        out = np.zeros_like(self.buf['bass'])
        for k, g in gains.items():
            out += self.buf[k] * g
        body = out[:self.len]
        tail = out[self.len:self.len + SR * 3]
        # fold the reverb/echo tail back into the loop start for a seamless loop
        body[:len(tail)] += tail[:len(body)]
        return body


def chord_tones(root, quality):
    return {'m': [0, 3, 7], 'M': [0, 4, 7], '7': [0, 4, 7, 10], 'm7': [0, 3, 7, 10]}[quality] and \
        [root + i for i in {'m': [0, 3, 7], 'M': [0, 4, 7], '7': [0, 4, 7, 10], 'm7': [0, 3, 7, 10]}[quality]]


def music_level():
    rng = random.Random(11)
    T = Track(112, 16)
    prog = [(57, 'm'), (53, 'M'), (48, 'M'), (55, 'M')] * 2 + [(57, 'm'), (53, 'M'), (55, 'M'), (52, 'M')] + [(57, 'm'), (53, 'M'), (55, 'M'), (64, 'M')]
    scale = [57, 59, 60, 62, 64, 65, 67, 69, 71, 72, 74, 76]
    for bar, (root, q) in enumerate(prog):
        tones = [root + i for i in {'m': [0, 3, 7], 'M': [0, 4, 7]}[q]]
        # pad
        for tn in tones:
            T.note('pad', 'sin', tn + 12, bar, 0, 4, 0.10, a=0.3, d=0.5, s=0.7, r=0.8)
        # bass: root eighths with octave jumps
        for i in range(8):
            m = root - 12 + (12 if i % 4 == 3 else 0)
            T.note('bass', 'tri', m, bar, i * 0.5, 0.45, 0.42, a=0.003, d=0.06, s=0.6, r=0.04)
        # arpeggio 16ths
        pat = [0, 1, 2, 1, 0, 2, 1, 2] * 2
        for i in range(16):
            m = tones[pat[i] % 3] + 24
            T.note('arp', 'sq', m, bar, i * 0.25, 0.22, 0.08, duty=0.25, a=0.002, d=0.04, s=0.4, r=0.03)
        # drums
        T.drum('kick', bar, 0, 0.8)
        T.drum('kick', bar, 2, 0.7)
        if bar % 2 == 1:
            T.drum('kick', bar, 3.5, 0.5)
        T.drum('snare', bar, 1, 0.55)
        T.drum('snare', bar, 3, 0.55)
        for i in range(8):
            T.drum('hat' if i % 2 else 'ohat' if i == 6 else 'hat', bar, i * 0.5, 0.35 if i % 2 else 0.5)
        # lead from bar 4
        if bar >= 4:
            rhythm = rng.choice([[0, 1.5, 2, 3], [0, 0.5, 1, 2.5], [0.5, 1.5, 2, 3.5], [0, 1, 2, 2.5, 3]])
            idx = rng.randrange(3, 8)
            for b in rhythm:
                step = rng.choice((-2, -1, 1, 2, 0))
                idx = max(1, min(len(scale) - 1, idx + step))
                m = scale[idx] + 12 if q == 'm' or True else scale[idx]
                T.note('lead', 'sq', m, bar, b, 0.9 if b % 2 == 0 else 0.45, 0.16, duty=0.5, a=0.005, d=0.08, s=0.6, r=0.1, vib=0.006)
    mixed = T.mix({'bass': 1.0, 'arp': 1.0, 'pad': 1.0, 'lead': 1.0, 'drum': 0.9})
    return norm(reverb(echo(mixed, T.spb * 0.75, 0.3, 0.12), 0.15), 0.85)


def music_boss():
    rng = random.Random(23)
    T = Track(150, 16)
    prog = [(50, 'm'), (46, 'M'), (48, 'M'), (45, 'M')] * 4
    scale = [62, 64, 65, 67, 69, 70, 72, 74, 76, 77]
    for bar, (root, q) in enumerate(prog):
        tones = [root + i for i in {'m': [0, 3, 7], 'M': [0, 4, 7]}[q]]
        for tn in tones:
            T.note('pad', 'saw', tn + 12, bar, 0, 4, 0.045, a=0.1, d=0.5, s=0.7, r=0.3)
        for i in range(16):
            m = root - 12 + (7 if i % 8 == 6 else 0)
            T.note('bass', 'sq', m, bar, i * 0.25, 0.2, 0.2, duty=0.4, a=0.002, d=0.04, s=0.5, r=0.03)
        pat = [0, 2, 1, 2, 0, 2, 1, 0]
        for i in range(16):
            m = tones[pat[i % 8] % 3] + 24
            T.note('arp', 'sq', m, bar, i * 0.25, 0.2, 0.07, duty=0.125, a=0.002, d=0.03, s=0.4, r=0.03)
        for b in (0, 0.75, 1.5, 2, 2.75, 3.5):
            T.drum('kick', bar, b, 0.9)
        T.drum('snare', bar, 1, 0.7)
        T.drum('snare', bar, 3, 0.7)
        for i in range(8):
            T.drum('hat', bar, i * 0.5, 0.5)
        if bar >= 2:
            rhythm = rng.choice([[0, 0.75, 1.5, 2, 2.75, 3.5], [0, 0.5, 1, 1.5, 2, 3], [0, 1, 1.75, 2.5, 3.25]])
            idx = rng.randrange(2, 7)
            for b in rhythm:
                idx = max(0, min(len(scale) - 1, idx + rng.choice((-2, -1, 1, 2))))
                T.note('lead', 'sq', scale[idx], bar, b, 0.6, 0.15, duty=0.25, a=0.003, d=0.06, s=0.6, r=0.06, vib=0.008)
                if b == 0 and bar % 4 == 3:
                    T.note('lead', 'sq', scale[idx] + 6, bar, b, 0.6, 0.06, duty=0.25)
    mixed = T.mix({'bass': 1.0, 'arp': 1.0, 'pad': 1.0, 'lead': 1.0, 'drum': 1.0})
    return norm(reverb(echo(mixed, T.spb * 0.75, 0.25, 0.1), 0.12), 0.85)


def music_menu():
    rng = random.Random(5)
    T = Track(76, 8)
    prog = [(57, 'm'), (53, 'M'), (48, 'M'), (55, 'M'), (57, 'm'), (53, 'M'), (55, 'M'), (52, 'M')]
    scale = [69, 71, 72, 74, 76, 77, 79, 81]
    for bar, (root, q) in enumerate(prog):
        tones = [root + i for i in {'m': [0, 3, 7], 'M': [0, 4, 7]}[q]]
        for tn in tones:
            T.note('pad', 'tri', tn, bar, 0, 4, 0.16, a=0.6, d=0.8, s=0.8, r=1.0)
            T.note('pad', 'sin', tn + 12, bar, 0, 4, 0.1, a=0.8, d=0.8, s=0.8, r=1.0)
        T.note('bass', 'sin', root - 12, bar, 0, 3.8, 0.4, a=0.05, d=0.3, s=0.8, r=0.5)
        for i in range(8):
            m = tones[(i * 2) % 3] + 24
            T.note('arp', 'sin', m, bar, i * 0.5, 0.8, 0.1, a=0.004, d=0.2, s=0.2, r=0.3)
        if bar >= 2:
            for b in rng.sample([0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5], 3):
                T.note('bell', 'sin', rng.choice(scale), bar, b, 1.2, 0.18, a=0.003, d=0.4, s=0.1, r=0.5)
                T.note('bell', 'sin', rng.choice(scale) + 12, bar, b, 0.8, 0.05, a=0.003, d=0.3, s=0.1, r=0.4)
    mixed = T.mix({'bass': 1.0, 'arp': 1.0, 'pad': 1.0, 'bell': 1.0, 'lead': 1.0, 'drum': 1.0})
    return norm(reverb(echo(mixed, T.spb * 0.75, 0.4, 0.2), 0.3), 0.8)


# =============================================================== AMBIENT
def seamless(x, fade):
    f = int(fade * SR)
    head, tail = x[:f], x[-f:]
    w = np.linspace(0, 1, f)
    blended = head * w + tail * (1 - w)
    return np.concatenate([blended, x[f:-f]])


def ambient_wind(dur=12.0):
    n = int(SR * (dur + 2))
    x = RNG.uniform(-1, 1, n)
    x = lp(x, 500, 2)
    t = np.arange(n) / SR
    lfo = 0.5 + 0.5 * np.sin(t * math.tau / 6.0 + 1.0) * np.sin(t * math.tau / 4.1)
    x = x * (0.25 + 0.75 * lfo)
    x = x + 0.4 * lp(RNG.uniform(-1, 1, n), 1800, 2) * (0.2 + 0.8 * (0.5 + 0.5 * np.sin(t * math.tau / 9.0)))
    return norm(seamless(x, 1.0), 0.6)


def ambient_night(dur=12.0):
    n = int(SR * (dur + 2))
    x = np.zeros(n)
    rng = random.Random(77)
    for _ in range(int(dur * 2.2)):
        p = rng.randrange(0, n - SR // 2)
        f = rng.choice((3800, 4200, 4600, 5200))
        for k in range(rng.choice((2, 3, 4))):
            q = p + k * int(0.07 * SR)
            c = osc('sin', f, 0.04) * env(int(SR * 0.04), 0.004, 0.01, 0.8, 0.015) * 0.5
            x[q:q + len(c)] += c[:n - q]
    # distant owl-like low hoots
    for _ in range(2):
        p = rng.randrange(0, n - SR * 2)
        for k, f in enumerate((330, 280)):
            q = p + k * int(0.3 * SR)
            c = osc('sin', f, 0.28) * env(int(SR * 0.28), 0.04, 0.1, 0.6, 0.1) * 0.35
            x[q:q + len(c)] += c[:n - q]
    x += lp(RNG.uniform(-1, 1, n), 300) * 0.12
    return norm(seamless(x, 1.0), 0.5)


def main():
    for name, x in sfx().items():
        write_wav(os.path.join(OUT, 'sfx', name + '.wav'), norm(x, 0.85))
    to_ogg(music_menu(), os.path.join(OUT, 'music', 'menu_theme.ogg'))
    to_ogg(music_level(), os.path.join(OUT, 'music', 'forest_theme.ogg'))
    to_ogg(music_boss(), os.path.join(OUT, 'music', 'boss_theme.ogg'))
    to_ogg(ambient_wind(), os.path.join(OUT, 'ambient', 'wind.ogg'), 2)
    to_ogg(ambient_night(), os.path.join(OUT, 'ambient', 'night.ogg'), 2)
    print('audio done')


if __name__ == '__main__':
    main()
