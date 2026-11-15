"""Procedural hand-built skeletal animation renderer for the hero, KAI 'the Shadow Runner'."""
import math, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from artlib import *

F = 192; S = 3; GROUND = 176
OUT = (16, 20, 38); SUIT = (40, 58, 108); SUIT_L = (78, 108, 182); SUIT_D = (26, 36, 72)
TEAL = (70, 232, 244); SKIN = (246, 208, 176); SCARF = (255, 134, 46); SCARF_D = (196, 70, 28)
HOOD = (30, 42, 84); BOOT = (22, 28, 52); BLADE = (214, 255, 255)

def hero_frame(lean=0.15, head=0.0, legs=((0.1, 0.0), (-0.1, -0.1)), arms=((0.2, 0.8), (-0.3, 0.4)),
               hy=None, scarf=(-1.0, 0.3, 0.0, 5.0), sword=None, slash=None, tint=0.0, glow=0.0,
               fs=F, ss=S, ground_y=GROUND):
    k = ss * fs / 192.0  # pixels per design unit
    W = int(fs * ss)
    img = new(W, W); d = ImageDraw.Draw(img)
    soft = new(W, W); sd = ImageDraw.Draw(soft)
    crisp = new(W, W); cd = ImageDraw.Draw(crisp)
    P = lambda p: (p[0] * k, p[1] * k)
    L1 = 28.0
    hx = 96.0
    if hy is None:
        bottoms = [math.cos(th) * L1 + math.cos(sh) * L1 + 10 for th, sh in legs]
        hy = ground_y - max(bottoms)
    H = (hx, hy)
    u = (math.sin(lean), -math.cos(lean)); n = (math.cos(lean), math.sin(lean))
    Sh = (H[0] + u[0] * 40, H[1] + u[1] * 40)
    ow = 2.6 * k
    far = lambda c: shade(c, 0.72)

    # ---- scarf tail (behind everything)
    dx, dy, ph, amp = scarf
    ln = math.hypot(dx, dy); dx, dy = dx / ln, dy / ln
    N = (Sh[0] + u[0] * 5, Sh[1] + u[1] * 5)
    perp = (-dy, dx)
    def ribbon(length, phase, a, w0, col, dcol):
        pts = []
        for i in range(10):
            t = i / 9.0
            wob = math.sin(phase + t * 4.2) * a * t
            pts.append((N[0] + dx * length * t + perp[0] * wob, N[1] + dy * length * t + perp[1] * wob + 6 * t * t))
        for i in range(9):
            w = w0 * (1 - 0.7 * i / 9)
            capsule(d, P(pts[i]), P(pts[i + 1]), (w + 5) * k, dcol)
        for i in range(9):
            w = w0 * (1 - 0.7 * i / 9)
            capsule(d, P(pts[i]), P(pts[i + 1]), w * k, col)
        return pts
    ribbon(46, ph + 1.7, amp * 0.9, 9, shade(SCARF, 0.85), shade(SCARF_D, 0.8))
    ribbon(64, ph, amp, 11, SCARF, SCARF_D)

    # ---- sheathed sword on back
    if sword is None:
        a = (H[0] - n[0] * 11 + u[0] * 6, H[1] - n[1] * 11 + u[1] * 6)
        b = (Sh[0] - n[0] * 7 + u[0] * 15 - 3, Sh[1] - n[1] * 7 + u[1] * 15)
        ocap(d, P(a), P(b), 6 * k, (54, 60, 96), OUT, 2 * k)
        ocap(d, P(b), P((b[0] - 1, b[1] - 8)), 5 * k, SCARF_D, OUT, 1.6 * k)
        cd.ellipse([P((b[0] - 1 - 2.4, b[1] - 10.4))[0], P((b[0] - 1 - 2.4, b[1] - 10.4))[1],
                    P((b[0] - 1 + 2.4, b[1] - 5.6))[0], P((b[0] - 1 + 2.4, b[1] - 5.6))[1]], fill=TEAL + (255,))

    # ---- limbs
    def leg(th, sh, near):
        kn = fk(H, th, L1); an = fk(kn, sh, L1)
        c1, c2 = (SUIT, SUIT_D) if near else (far(SUIT), far(SUIT_D))
        ocap(d, P((H[0] + (2 if near else -2), H[1])), P(kn), 14 * k, c1, OUT, ow)
        ocap(d, P(kn), P(an), 12 * k, c2, OUT, ow)
        d.ellipse([P((kn[0] - 3.6, kn[1] - 3.6))[0], P((kn[0] - 3.6, kn[1] - 3.6))[1],
                   P((kn[0] + 3.6, kn[1] + 3.6))[0], P((kn[0] + 3.6, kn[1] + 3.6))[1]], fill=TEAL if near else far(TEAL))
        bt = (an[0] - 4, an[1] + 2); tt = (an[0] + 12, an[1] + 4.5)
        ocap(d, P(bt), P(tt), 11 * k, BOOT if near else far(BOOT), OUT, ow)
        capsule(d, P((bt[0] + 1, bt[1] + 5)), P((tt[0], tt[1] + 5)), 2.2 * k, TEAL if near else far(TEAL))
    def arm(ua, fa, near):
        sp = (Sh[0] - u[0] * 5 + n[0] * (4 if near else -3), Sh[1] - u[1] * 5 + n[1] * (4 if near else -3))
        el = fk(sp, ua, 21); hd = fk(el, fa, 20)
        c1, c2 = (SUIT_L, SUIT) if near else (far(SUIT_L), far(SUIT))
        ocap(d, P(sp), P(el), 11 * k, c1, OUT, ow)
        ocap(d, P(el), P(hd), 10 * k, c2, OUT, ow)
        capsule(d, P(fk(hd, fa, -6)), P(fk(hd, fa, -2)), 11.5 * k, TEAL if near else far(TEAL))
        oell(d, [P(hd)[0] - 6 * k, P(hd)[1] - 6 * k, P(hd)[0] + 6 * k, P(hd)[1] + 6 * k], SKIN if near else far(SKIN), OUT, 1.8 * k)
        return hd

    leg(legs[1][0], legs[1][1], False)
    arm(arms[1][0], arms[1][1], False)

    # ---- torso
    pts = [(H[0] - n[0] * 8, H[1] - n[1] * 8), (H[0] + n[0] * 9, H[1] + n[1] * 9),
           (Sh[0] + n[0] * 12 + u[0] * 2, Sh[1] + n[1] * 12 + u[1] * 2), (Sh[0] - n[0] * 11, Sh[1] - n[1] * 11)]
    opoly(d, [P(p) for p in pts], SUIT, OUT, ow)
    chest = [(H[0] + n[0] * 3 + u[0] * 14, H[1] + n[1] * 3 + u[1] * 14), (H[0] + n[0] * 9 + u[0] * 4, H[1] + n[1] * 9 + u[1] * 4),
             (Sh[0] + n[0] * 12, Sh[1] + n[1] * 12), (Sh[0] + n[0] * 3, Sh[1] + n[1] * 3)]
    d.polygon([P(p) for p in chest], fill=SUIT_L)
    belt0 = (H[0] - n[0] * 8 + u[0] * 5, H[1] - n[1] * 8 + u[1] * 5); belt1 = (H[0] + n[0] * 9 + u[0] * 5, H[1] + n[1] * 9 + u[1] * 5)
    ocap(d, P(belt0), P(belt1), 7 * k, SCARF, OUT, 1.6 * k)
    bc = (H[0] + n[0] * 3 + u[0] * 5, H[1] + n[1] * 3 + u[1] * 5)
    d.ellipse([P(bc)[0] - 3 * k, P(bc)[1] - 3 * k, P(bc)[0] + 3 * k, P(bc)[1] + 3 * k], fill=TEAL)
    em = (H[0] + u[0] * 26 + n[0] * 3, H[1] + u[1] * 26 + n[1] * 3)
    dia = [P((em[0], em[1] - 6)), P((em[0] + 4.5, em[1])), P((em[0], em[1] + 6)), P((em[0] - 4.5, em[1]))]
    sd.polygon(dia, fill=TEAL + (255,)); cd.polygon(dia, fill=(200, 255, 255, 255))

    # ---- scarf knot at neck
    d.ellipse([P(N)[0] - 11 * k, P(N)[1] - 6 * k, P(N)[0] + 11 * k, P(N)[1] + 8 * k], fill=SCARF_D)
    d.ellipse([P(N)[0] - 9.5 * k, P(N)[1] - 6 * k, P(N)[0] + 9.5 * k, P(N)[1] + 5 * k], fill=SCARF)

    # ---- head
    hu = (math.sin(lean + head), -math.cos(lean + head))
    C = (Sh[0] + hu[0] * 21, Sh[1] + hu[1] * 21)
    tip = (C[0] - 31 * math.cos(head) + dx * 6, C[1] + 6 + dy * 6 - 5)
    opoly(d, [P((C[0] - 10, C[1] - 15)), P((C[0] - 12, C[1] + 8)), P(tip)], HOOD, OUT, ow)
    oell(d, [P(C)[0] - 18.5 * k, P(C)[1] - 18.5 * k, P(C)[0] + 18.5 * k, P(C)[1] + 18.5 * k], HOOD, OUT, ow)
    fc = (C[0] + 7.5, C[1] + 2.5)
    oell(d, [P(fc)[0] - 11 * k, P(fc)[1] - 12.5 * k, P(fc)[0] + 11 * k, P(fc)[1] + 12.5 * k], SKIN, HOOD, 2.4 * k)
    d.pieslice([P(fc)[0] - 11 * k, P(fc)[1] - 12.5 * k, P(fc)[0] + 11 * k, P(fc)[1] + 12.5 * k], 30, 150, fill=shade(SKIN, 0.86))
    capsule(d, P((C[0] - 1, C[1] - 15)), P((C[0] + 13, C[1] - 10.5)), 4.2 * k, TEAL)
    ex, ey = C[0] + 11, C[1] - 1.5
    d.ellipse([P((ex - 4.4, ey - 5.4))[0], P((ex - 4.4, ey - 5.4))[1], P((ex + 4.4, ey + 5.4))[0], P((ex + 4.4, ey + 5.4))[1]], fill=(255, 255, 255, 255))
    d.ellipse([P((ex - 0.2, ey - 3.4))[0], P((ex - 0.2, ey - 3.4))[1], P((ex + 4.2, ey + 3.4))[0], P((ex + 4.2, ey + 3.4))[1]], fill=TEAL + (255,))
    d.ellipse([P((ex + 1.2, ey - 1.8))[0], P((ex + 1.2, ey - 1.8))[1], P((ex + 3.2, ey + 0.8))[0], P((ex + 3.2, ey + 0.8))[1]], fill=(255, 255, 255, 255))
    capsule(d, P((ex - 5, ey - 7.5)), P((ex + 5.5, ey - 6.2)), 2.4 * k, OUT)
    capsule(d, P((ex - 1, ey + 10)), P((ex + 4, ey + 9.4)), 1.8 * k, shade(SKIN, 0.55))
    d.polygon([P((ex + 7, ey + 2)), P((ex + 10.5, ey + 5)), P((ex + 6.5, ey + 5.4))], fill=shade(SKIN, 0.9))

    # ---- near limbs
    leg(legs[0][0], legs[0][1], True)
    hd = arm(arms[0][0], arms[0][1], True)

    # ---- sword
    if sword is not None:
        ang = sword
        v = (math.sin(ang), math.cos(ang))
        g0 = (hd[0] + v[0] * 2, hd[1] + v[1] * 2)
        hilt_end = (hd[0] + v[0] * 11, hd[1] + v[1] * 11)
        tipb = (hd[0] + v[0] * 54, hd[1] + v[1] * 54)
        pp = (-v[1], v[0])
        capsule(sd, P(hilt_end), P(tipb), (20 + 14 * glow) * k, TEAL + (150,))
        ocap(d, P(g0), P(hilt_end), 6 * k, SCARF_D, OUT, 1.6 * k)
        capsule(d, P((hilt_end[0] - pp[0] * 8, hilt_end[1] - pp[1] * 8)), P((hilt_end[0] + pp[0] * 8, hilt_end[1] + pp[1] * 8)), 4 * k, TEAL)
        bl = [P((hilt_end[0] + pp[0] * 4.5, hilt_end[1] + pp[1] * 4.5)), P((tipb[0] + pp[0] * 1.2, tipb[1] + pp[1] * 1.2)),
              P((tipb[0] + v[0] * 7, tipb[1] + v[1] * 7)), P((tipb[0] - pp[0] * 1.2, tipb[1] - pp[1] * 1.2)),
              P((hilt_end[0] - pp[0] * 4.5, hilt_end[1] - pp[1] * 4.5))]
        cd.polygon(bl, fill=TEAL + (255,))
        inner = [P((hilt_end[0] + pp[0] * 2.2, hilt_end[1] + pp[1] * 2.2)), P((tipb[0] + v[0] * 4, tipb[1] + v[1] * 4)),
                 P((hilt_end[0] - pp[0] * 2.2, hilt_end[1] - pp[1] * 2.2))]
        cd.polygon(inner, fill=BLADE + (255,))

    # ---- slash arc
    if slash:
        a0, a1, al = slash
        shp = (Sh[0] + u[0] * 4, Sh[1] + u[1] * 4)
        outer = []; inner = []
        steps = 18
        for i in range(steps + 1):
            t = i / steps
            a = a0 + (a1 - a0) * t
            rr = 60 + 3 * math.sin(math.pi * t)
            wd = 20 * math.sin(math.pi * t) ** 0.8 + 1
            outer.append(P((shp[0] + math.sin(a) * rr, shp[1] + math.cos(a) * rr)))
            inner.append(P((shp[0] + math.sin(a) * (rr - wd), shp[1] + math.cos(a) * (rr - wd))))
        poly = outer + inner[::-1]
        sd.polygon(poly, fill=TEAL + (int(200 * al),))
        cd.polygon(poly, fill=(220, 255, 255, int(235 * al)))

    img = Image.alpha_composite(img, blur(soft, 5.5 * k))
    if glow > 0:
        pass
    img = Image.alpha_composite(img, crisp)
    out = downsample(img, (fs, fs))
    return tint_white(out, tint)

# ---------------------------------------------------------------- pose generators
def a_idle(i, n=8):
    t = 2 * math.pi * i / n; b = math.sin(t)
    return dict(lean=0.07 + 0.02 * b, head=0.03 * b,
                legs=((0.15 + 0.03 * b, -0.04 - 0.05 * b), (-0.18 - 0.03 * b, -0.12 - 0.05 * b)),
                arms=((0.22 + 0.06 * b, 0.95 + 0.06 * b), (-0.22 - 0.05 * b, 0.45)),
                scarf=(-0.9, 0.55 + 0.1 * b, t, 4.5))

def a_run(i, n=10):
    p = 2 * math.pi * i / n
    def leg(q):
        th = 0.95 * math.sin(q); bend = 0.28 + 1.0 * max(0.0, math.cos(q))
        return (th, th - bend)
    return dict(lean=0.27, head=-0.05, legs=(leg(p), leg(p + math.pi)),
                arms=((-0.95 * math.sin(p), -0.95 * math.sin(p) + 1.15), (0.95 * math.sin(p), 0.95 * math.sin(p) + 1.15)),
                scarf=(-1.0, 0.05, -p * 1.0, 8.0))

def a_jump(i):
    P = [dict(lean=0.5, legs=((0.75, -0.95), (0.55, -0.85)), arms=((-0.5, -0.3), (-0.65, -0.25)), scarf=(-0.7, 0.6, 0.0, 3)),
         dict(lean=0.1, legs=((0.15, 0.0), (-0.15, -0.1)), arms=((2.5, 2.7), (2.1, 2.5)), scarf=(-0.4, 0.9, 0.5, 4)),
         dict(lean=0.05, hy=108, legs=((0.75, -0.65), (-0.2, -0.95)), arms=((2.7, 2.9), (2.3, 2.7)), scarf=(-0.3, 0.95, 1.0, 5)),
         dict(lean=0.0, hy=102, legs=((0.95, -0.85), (0.25, -1.05)), arms=((2.3, 2.5), (1.95, 2.25)), scarf=(-0.35, 0.9, 1.5, 6)),
         dict(lean=-0.04, hy=98, legs=((0.85, -0.55), (-0.1, -0.75)), arms=((1.7, 2.0), (1.3, 1.7)), scarf=(-0.8, 0.6, 2.0, 6)),
         dict(lean=0.0, hy=100, legs=((0.55, -0.25), (-0.3, -0.5)), arms=((1.3, 1.3), (0.95, 1.1)), scarf=(-0.8, -0.3, 2.5, 6))]
    return P[i]

def a_fall(i):
    f = math.sin(i * math.pi / 2)
    return dict(lean=-0.06, head=-0.05, hy=100, legs=((0.38 + 0.12 * f, 0.1), (-0.36 - 0.1 * f, -0.05)),
                arms=((2.55 + 0.12 * f, 2.75), (2.05 - 0.12 * f, 2.4)), scarf=(-0.15, -1.0, i * 1.3, 5))

def a_land(i):
    c = [1.0, 0.78, 0.4, 0.12][i]
    return dict(lean=0.55 * c + 0.05, head=-0.1 * c,
                legs=((0.8 * c + 0.06, -1.0 * c), (0.55 * c - 0.1, -0.9 * c - 0.04)),
                arms=((0.9 * c + 0.2, 1.2 * c + 0.3), (-0.4 * c, -0.1)), scarf=(-0.5 - 0.3 * c, 0.8, i * 0.8, 5))

SA = [-2.3, -3.25, -4.2, -4.95, -5.55, -5.95]
def a_attack(i):
    sa = SA[i]
    lean = [-0.12, 0.05, 0.28, 0.42, 0.4, 0.3][i]
    legs = [((-0.25, -0.55), (0.35, -0.2)), ((0.25, -0.35), (-0.3, -0.6)), ((0.8, -0.2), (-0.75, -0.85)),
            ((0.95, 0.05), (-0.85, -1.0)), ((0.9, 0.0), (-0.8, -0.95)), ((0.7, -0.1), (-0.65, -0.8))][i]
    slashes = [None, (-2.7, -3.5, 0.55), (-3.4, -4.5, 0.95), (-4.2, -5.3, 1.0), (-5.0, -5.9, 0.7), (-5.6, -6.1, 0.3)][i]
    return dict(lean=lean, legs=legs, arms=((sa, sa * 0.98), (-1.1 - 0.2 * (i > 1), -0.7)), sword=sa, slash=slashes,
                scarf=(-1.0, 0.1, i * 0.9, 7), glow=1.0 if i in (2, 3) else 0.3)

def a_damage(i):
    return dict(lean=[-0.38, -0.5, -0.42, -0.2][i], head=-0.3, legs=((-0.3, -0.6), (0.5, 0.0)),
                arms=((-1.0 - 0.3 * (i % 2), -1.25), (-1.7, -1.4)), scarf=(1.0, -0.3, i * 2.0, 6),
                tint=[0.6, 0.38, 0.18, 0.0][i])

def a_victory(i):
    if i == 0:
        return dict(lean=0.4, legs=((0.7, -0.95), (0.5, -0.85)), arms=((-0.4, -0.2), (-0.5, -0.1)), scarf=(-0.7, 0.6, 0.0, 3))
    if i == 1:
        return dict(lean=0.0, hy=104, legs=((0.7, -0.5), (-0.25, -0.7)), arms=((2.6, 2.4), (2.2, 2.6)), sword=2.2, scarf=(-0.3, 0.9, 1.0, 5), glow=0.6)
    if i == 2:
        return dict(lean=-0.05, hy=96, legs=((0.8, -0.4), (-0.1, -0.6)), arms=((2.5, 2.2), (2.0, 2.5)), sword=2.0, scarf=(-0.5, 0.7, 2.0, 6), glow=1.0)
    if i == 3:
        return dict(lean=0.3, legs=((0.55, -0.7), (0.3, -0.65)), arms=((2.4, 2.1), (0.6, -0.5)), sword=2.0, scarf=(-0.9, 0.3, 3.0, 5), glow=0.7)
    return dict(lean=0.0 if i == 5 else 0.05, head=0.05, legs=((0.18, -0.05), (-0.2, -0.12)),
                arms=((2.4, 2.1), (0.6, -0.5)), sword=2.0 + 0.06 * (i - 4), scarf=(-0.9, 0.5, i * 1.5, 5 + (i - 4) * 2), glow=1.0)

ANIMS = [("idle", 8, a_idle), ("run", 10, a_run), ("jump", 6, a_jump), ("fall", 4, a_fall),
         ("land", 4, a_land), ("attack", 6, a_attack), ("damage", 4, a_damage), ("victory", 6, a_victory)]

def build(outdir):
    rows = []
    for name, cnt, fn in ANIMS:
        rows.append([hero_frame(**fn(i)) for i in range(cnt)])
    sheet = make_sheet(rows, (F, F), 10)
    sheet.save(os.path.join(outdir, "hero_sheet.png"), optimize=True)
    # portrait key-art (high-res victory/idle pose)
    big = hero_frame(**dict(a_attack(3), tint=0.0), fs=F, ss=10)
    bb = big.getbbox(); big = big.crop(bb)
    big.save(os.path.join(outdir, "hero_portrait.png"), optimize=True)
    return rows

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    rows = build(out)
    print("hero done", [len(r) for r in rows])
