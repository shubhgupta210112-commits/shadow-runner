"""Original synthesized audio for Shadow Runner (numpy). All sounds are generated from scratch -> CC0."""
import sys, os, wave, math
import numpy as np

SR = 22050
rng = np.random.RandomState(7)

def T(d): return np.arange(int(SR * d)) / SR
def env_exp(t, k): return np.exp(-t * k)
def adsr(n, a=0.01, d=0.1, s=0.7, r=0.1):
    e = np.ones(n); na, nd, nr = int(a * SR), int(d * SR), int(r * SR)
    e[:na] = np.linspace(0, 1, max(na, 1))
    e[na:na + nd] = np.linspace(1, s, max(nd, 1))[:max(0, min(nd, n - na))]
    e[na + nd:] = s
    if nr > 0: e[-nr:] *= np.linspace(1, 0, nr)
    return e
def osc(f, t, kind="sine"):
    ph = 2 * np.pi * np.cumsum(np.broadcast_to(f, t.shape)) / SR
    if kind == "sine": return np.sin(ph)
    if kind == "saw": return 2 * ((ph / (2 * np.pi)) % 1) - 1
    if kind == "square": return np.sign(np.sin(ph))
    if kind == "tri": return 2 * np.abs(2 * ((ph / (2 * np.pi)) % 1) - 1) - 1
def noise(n): return rng.uniform(-1, 1, n)
def lp(x, n): return np.convolve(x, np.ones(n) / n, "same") if n > 1 else x
def norm(x, peak=0.85): return x / max(1e-6, np.max(np.abs(x))) * peak
def save(path, x):
    x = np.clip(x, -1, 1); data = (x * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
def midi(n): return 440.0 * 2 ** ((n - 69) / 12.0)

# ---------------------------------------------------------------- SFX
def jump():
    t = T(0.22); f = 260 + 700 * t / 0.22; return norm(osc(f, t, "square") * 0.5 * env_exp(t, 9) + osc(f * 2, t) * 0.3 * env_exp(t, 12), 0.6)
def land():
    t = T(0.18); return norm(lp(noise(len(t)), 40) * env_exp(t, 24) + osc(90 - 40 * t / 0.18, t) * env_exp(t, 18), 0.7)
def crystal():
    t = T(0.45); x = osc(1318, t) * env_exp(t, 7) + osc(1975, np.arange(len(t)) / SR) * 0.7 * np.where(t > 0.07, env_exp(t - 0.07, 7), 0) + osc(2637, t) * 0.25 * env_exp(t, 10)
    return norm(x, 0.6)
def sword():
    t = T(0.2); f = 900 - 600 * t / 0.2; return norm(lp(noise(len(t)), 6) * np.sin(np.pi * t / 0.2) ** 0.8 * 0.9 + osc(f, t, "saw") * 0.15 * env_exp(t, 12), 0.6)
def hit():
    t = T(0.16); return norm(noise(len(t)) * env_exp(t, 28) * 0.8 + osc(180 - 100 * t / 0.16, t, "square") * env_exp(t, 20) * 0.6, 0.75)
def enemy_die():
    t = T(0.5); f = 420 * np.exp(-t * 3); return norm(osc(f, t, "saw") * env_exp(t, 5) * 0.6 + noise(len(t)) * env_exp(t, 10) * 0.4, 0.7)
def hurt():
    t = T(0.35); f = 520 - 380 * t / 0.35; return norm(osc(f, t, "saw") * env_exp(t, 7) * 0.7 + osc(f * 0.5, t, "square") * env_exp(t, 9) * 0.3, 0.7)
def mixin(x, s, sig):
    s = int(s)
    e = min(len(x), s + len(sig))
    if e > s: x[s:e] += sig[:e - s]
def health():
    x = np.zeros(int(SR * 0.6))
    for i, nt in enumerate((72, 76, 79, 84)):
        tt = T(0.4); mixin(x, i * 0.08 * SR, osc(midi(nt), tt, "tri") * env_exp(tt, 6))
    return norm(x, 0.55)
def checkpoint():
    t = T(0.8); x = osc(midi(79), t) * env_exp(t, 4) + osc(midi(86), t) * 0.5 * env_exp(t, 3) + osc(midi(91), t) * 0.3 * env_exp(t, 3); return norm(x, 0.55)
def ui_click():
    t = T(0.08); return norm(osc(660, t, "square") * env_exp(t, 40) * 0.5 + osc(990, t) * env_exp(t, 50) * 0.4, 0.5)
def ui_hover():
    t = T(0.05); return norm(osc(900, t) * env_exp(t, 60), 0.25)
def boss_warn():
    t = T(0.6); x = osc(220, t, "square") * (np.sin(2 * np.pi * 7 * t) > 0) * 0.4 + osc(110, t, "saw") * 0.3; return norm(x * adsr(len(t), 0.01, 0.1, 0.8, 0.2), 0.6)
def boss_slam():
    t = T(0.9); return norm(lp(noise(len(t)), 90) * env_exp(t, 4.5) * 1.5 + osc(52 * np.exp(-t * 2), t) * env_exp(t, 3.5), 0.95)
def boss_orb():
    t = T(0.35); f = 1200 * np.exp(-t * 4) + 200; return norm(osc(f, t, "saw") * env_exp(t, 6) * 0.6 + osc(f * 1.5, t, "sine") * env_exp(t, 8) * 0.4, 0.65)
def boss_intro():
    d = 4.0; t = T(d); sw = np.linspace(0, 1, len(t))
    x = lp(noise(len(t)), 120) * 2.2 * sw ** 2
    for f in (55, 82.4, 110, 164.8):
        x += osc(f * (1 + 0.01 * np.sin(2 * np.pi * 0.7 * t)), t, "saw") * 0.18 * sw
    x += osc(40, t) * 0.5 * np.where(t > 2.6, env_exp(t - 2.6, 1.2), 0)
    x += lp(noise(len(t)), 20) * np.where(t > 2.6, env_exp(t - 2.6, 3), 0) * 0.8
    return norm(x * adsr(len(t), 0.5, 0.2, 1.0, 0.8), 0.9)
def victory():
    x = np.zeros(int(SR * 2.6)); t0 = 0.0
    for nt, dur in ((69, 0.18), (72, 0.18), (76, 0.18), (81, 0.5), (79, 0.18), (84, 1.2)):
        tt = T(dur + 0.4)
        mixin(x, t0 * SR, (osc(midi(nt), tt, "square") * 0.25 + osc(midi(nt), tt, "tri") * 0.4) * env_exp(tt, 2.8))
        t0 += dur
    return norm(x, 0.7)
def defeat():
    x = np.zeros(int(SR * 2.2))
    for i, nt in enumerate((69, 67, 64, 57)):
        tt = T(1.2); mixin(x, i * 0.35 * SR, (osc(midi(nt), tt, "saw") * 0.3 + osc(midi(nt - 12), tt) * 0.4) * env_exp(tt, 2.5))
    return norm(lp(x, 4), 0.7)
def ambience():
    d = 10.0; t = T(d); w = lp(noise(len(t)), 60) * (0.6 + 0.4 * np.sin(2 * np.pi * t / d * 2 + 1)) * 1.4
    w += lp(noise(len(t)), 25) * 0.3 * (0.5 + 0.5 * np.sin(2 * np.pi * t / d * 3))
    w += osc(55, t) * 0.12 + osc(82.4, t) * 0.07 * (0.5 + 0.5 * np.sin(2 * np.pi * t / d))
    x = norm(w, 0.5); fade = int(0.5 * SR); x[:fade] = x[:fade] * np.linspace(0, 1, fade) + x[-fade:] * np.linspace(1, 0, fade) * 0; return x

# ---------------------------------------------------------------- MUSIC
def track(bpm, bars, chords, bass_pat, arp_pat, drums, pad=0.5, arp_oct=12, lead=None, arp_kind="tri", swing=0.0, vol_bass=0.6):
    beat = 60.0 / bpm; N = int(bars * 4 * beat * SR); tail = int(2 * SR); buf = np.zeros(N + tail)
    def add(sig, s, g=1.0):
        s = int(s * SR); e = min(len(buf), s + len(sig)); buf[s:e] += sig[:e - s] * g
    for b in range(bars):
        root, quality = chords[b % len(chords)]
        tri = [root, root + (3 if quality == "m" else 4), root + 7]
        t0 = b * 4 * beat
        tt = T(4 * beat + 1.2); padsig = sum(osc(midi(n + 12) * (1 + 0.003 * k), tt, "saw") for n in tri for k in (-1, 1)) * 0.06
        add(lp(padsig, 8) * adsr(len(tt), 1.2, 0.5, 0.7, 1.2) * pad, t0)
        for i, st in enumerate(bass_pat):
            if st is None: continue
            tb = T(beat * 0.5); f = midi(root - 12 + st)
            add((osc(f, tb, "saw") * 0.5 + osc(f, tb, "sine") * 0.6) * adsr(len(tb), 0.005, 0.08, 0.6, 0.08) * vol_bass, t0 + i * beat * 0.5)
        for i, st in enumerate(arp_pat):
            if st is None: continue
            na = tri[st % 3] + arp_oct + 12 * (st // 3); tb = T(beat * 0.9); f = midi(na)
            add(osc(f, tb, arp_kind) * env_exp(tb, 5.5) * 0.28 + osc(f * 2, tb) * env_exp(tb, 8) * 0.08, t0 + i * beat * 0.5 + (swing * beat * 0.25 if i % 2 else 0))
        if lead:
            for i, st in enumerate(lead[b % len(lead)]):
                if st is None: continue
                tb = T(beat * 1.4); f = midi(root + 12 + st)
                add((osc(f * (1 + 0.004 * np.sin(2 * np.pi * 5 * tb)), tb, "square") * 0.14 + osc(f, tb, "tri") * 0.2) * adsr(len(tb), 0.01, 0.2, 0.6, 0.4), t0 + i * beat)
        for i in range(8):
            ts = t0 + i * beat * 0.5
            if "k" in drums and i in drums["k"]:
                tk = T(0.25); add(osc(120 * np.exp(-tk * 22) + 40, tk) * env_exp(tk, 10) * 0.9, ts)
            if "s" in drums and i in drums["s"]:
                tk = T(0.2); add((lp(noise(len(tk)), 2) * 0.5 + osc(190, tk) * 0.3) * env_exp(tk, 18), ts)
            if "h" in drums and i in drums["h"]:
                tk = T(0.06); add((noise(len(tk)) - lp(noise(len(tk)), 6)) * env_exp(tk, 60) * 0.35, ts)
    out = buf[:N].copy(); out[:min(tail, N)] += buf[N:N + min(tail, N)]
    return norm(out, 0.7)

def run(outdir):
    S = {"jump": jump, "land": land, "crystal": crystal, "sword": sword, "hit": hit, "enemy_die": enemy_die, "hurt": hurt, "health": health,
         "checkpoint": checkpoint, "ui_click": ui_click, "ui_hover": ui_hover, "boss_warn": boss_warn, "boss_slam": boss_slam, "boss_orb": boss_orb,
         "boss_intro": boss_intro, "victory": victory, "defeat": defeat, "ambience": ambience}
    for k, f in S.items(): save(os.path.join(outdir, k + ".wav"), f())
    Am, F_, C_, G_ = (57, "m"), (53, "M"), (60, "M"), (55, "M")
    save(os.path.join(outdir, "music_menu.wav"), track(78, 8, [Am, F_, C_, G_], [0, None, None, None, 7, None, None, None], [0, 1, 2, 4, 3, 2, 1, 2], {"h": [2, 6]}, pad=0.9, arp_oct=12, lead=[[0, None, 7, None], [None, 5, None, 3]], vol_bass=0.5))
    save(os.path.join(outdir, "music_level.wav"), track(118, 8, [Am, F_, C_, G_], [0, 0, None, 0, 7, None, 0, 5], [0, 2, 1, 2, 3, 2, 1, 2], {"k": [0, 4], "s": [2, 6], "h": [1, 3, 5, 7]}, pad=0.5, arp_oct=12, lead=[[0, None, 3, 7], [5, None, 3, None], [7, 4, None, 0], [None, 2, 7, None]], swing=0.2))
    D_, E_ = (50, "m"), (52, "M")
    save(os.path.join(outdir, "music_boss.wav"), track(144, 8, [Am, F_, D_, E_], [0, 0, 12, 0, 0, 12, 7, 0], [0, 2, 4, 2, 3, 5, 4, 2], {"k": [0, 3, 4, 7], "s": [2, 6], "h": [0, 1, 2, 3, 4, 5, 6, 7]}, pad=0.55, arp_oct=12, arp_kind="saw", lead=[[0, 3, 7, 3], [5, 3, 0, 3], [2, 5, 9, 5], [4, 8, 11, 8]], vol_bass=0.75))

if __name__ == "__main__":
    run(sys.argv[1]); print("audio done")
