"""Original enemy + boss sprite sheets (procedural skeletal renderer). Rows = animations."""
import math, sys, os, random
sys.path.insert(0, os.path.dirname(__file__))
from artlib import *

def shards(d, c, t, color, count, seed, size=9, spread=70, k=1.0):
    rng = random.Random(seed)
    for i in range(count):
        a = rng.uniform(0, 2 * math.pi); sp = rng.uniform(0.4, 1.0) * spread * t
        x = c[0] + math.cos(a) * sp; y = c[1] + math.sin(a) * sp * 0.8 + 30 * t * t
        r = rng.uniform(0.5, 1.0) * size * (1 - 0.5 * t)
        rot = rng.uniform(0, 6.28)
        pts = [((x + math.cos(rot + j * 2.1) * r * (1 if j else 1.6)) * k, (y + math.sin(rot + j * 2.1) * r) * k) for j in range(3)]
        d.polygon(pts, fill=color + (int(255 * (1 - t)),))

def finish(img, soft, crisp, fs, k, tint=0.0, br=5.0):
    img = Image.alpha_composite(img, blur(soft, br * k))
    img = Image.alpha_composite(img, crisp)
    return tint_white(downsample(img, (fs, fs)), tint)

# =========================================================== CRAWLER (160)
def crawler(tl=0.0, bob=0.0, lunge=0.0, mouth=0.2, sx=1.0, sy=1.0, tint=0.0, dead=0.0, blink=False, ko=False):
    fs, ss = 160, 3; k = ss
    img = new(fs * ss, fs * ss); d = ImageDraw.Draw(img); soft = new(fs * ss, fs * ss); sd = ImageDraw.Draw(soft)
    crisp = new(fs * ss, fs * ss); cd = ImageDraw.Draw(crisp)
    P = lambda p: (p[0] * k, p[1] * k)
    OUT = (14, 10, 28); SH = (62, 46, 96); SHL = (112, 86, 168); SHD = (40, 28, 66); CR = (206, 84, 255)
    cx, cy = 78 + lunge, 112 - bob + (14 * dead)
    gy = 142
    for side, col in ((1, shade(SHD, 0.8)), (0, SHD)):
        for i in range(3):
            hxp = cx - 24 + i * 20 + (4 if side else 0)
            ph = tl + i * 2.1 + (math.pi if side else 0)
            fx = hxp + 4 + 13 * math.sin(ph); lift = 11 * max(0.0, math.cos(ph))
            if dead > 0: fx = hxp + (i - 1) * 10; lift = 0
            foot = (fx, gy - lift); hip = (hxp, cy + 8 * sy)
            knee = ((hip[0] + foot[0]) / 2 + 6, min(hip[1], foot[1]) - 12)
            ocap(d, P(hip), P(knee), 7 * k, col, OUT, 2.2 * k); ocap(d, P(knee), P(foot), 5.5 * k, col, OUT, 2.2 * k)
            d.ellipse([P((foot[0] - 3, foot[1] - 3))[0], P((foot[0] - 3, foot[1] - 3))[1], P((foot[0] + 3, foot[1] + 3))[0], P((foot[0] + 3, foot[1] + 3))[1]], fill=SHL)
    rx, ry = 42 * sx, 30 * sy
    opoly(d, [P((cx - rx, cy + 12 * sy)), P((cx - rx * 0.8, cy - ry * 0.6)), P((cx - rx * 0.2, cy - ry)), P((cx + rx * 0.5, cy - ry * 0.9)),
              P((cx + rx * 0.95, cy - ry * 0.2)), P((cx + rx, cy + 12 * sy)), P((cx + rx * 0.5, cy + 17 * sy)), P((cx - rx * 0.6, cy + 17 * sy))], SH, OUT, 2.8 * k)
    d.polygon([P((cx - rx * 0.7, cy - ry * 0.4)), P((cx - rx * 0.2, cy - ry * 0.9)), P((cx + rx * 0.5, cy - ry * 0.8)), P((cx - rx * 0.1, cy - ry * 0.45))], fill=SHL)
    for j in range(3):
        px = cx - rx * 0.55 + j * rx * 0.5
        d.line([P((px, cy - ry * 0.25)), P((px + 6, cy + 12 * sy))], fill=SHD, width=int(2 * k))
    for j, (sxo, h) in enumerate([(-0.55, 22), (-0.25, 30), (0.05, 26), (0.32, 19)]):
        bx = cx + rx * sxo; by = cy - ry * (0.85 - 0.1 * j * 0.3)
        tri = [P((bx - 7, by + 4)), P((bx + 1 - 2 * j, by - h * sy)), P((bx + 8, by + 4))]
        opoly(d, tri, CR, OUT, 1.8 * k); d.polygon([P((bx - 2, by + 2)), P((bx + 1 - 2 * j, by - h * sy + 5)), P((bx + 2, by + 2))], fill=(240, 170, 255))
        sd.polygon([P((bx - 5, by + 2)), P((bx - 2 * j, by - h * sy)), P((bx + 6, by + 2))], fill=CR + (160,))
    ex, ey = cx + rx * 0.62, cy - 6 * sy
    for (ox, oy, r) in ((0, 0, 6.2), (-11, -5, 4.6)):
        ex2, ey2 = ex + ox, ey + oy
        if blink or ko:
            cd.line([P((ex2 - r, ey2 - r)), P((ex2 + r, ey2 + r))], fill=(255, 120, 90, 255), width=int(2 * k))
            if ko: cd.line([P((ex2 + r, ey2 - r)), P((ex2 - r, ey2 + r))], fill=(255, 120, 90, 255), width=int(2 * k))
        else:
            sd.ellipse([P((ex2 - r * 2, ey2 - r * 2))[0], P((ex2 - r * 2, ey2 - r * 2))[1], P((ex2 + r * 2, ey2 + r * 2))[0], P((ex2 + r * 2, ey2 + r * 2))[1]], fill=(255, 80, 50, 200))
            cd.ellipse([P((ex2 - r, ey2 - r))[0], P((ex2 - r, ey2 - r))[1], P((ex2 + r, ey2 + r))[0], P((ex2 + r, ey2 + r))[1]], fill=(255, 112, 70, 255))
            cd.ellipse([P((ex2 - r * 0.4, ey2 - r * 0.5))[0], P((ex2 - r * 0.4, ey2 - r * 0.5))[1], P((ex2 + r * 0.3, ey2 + r * 0.1))[0], P((ex2 + r * 0.3, ey2 + r * 0.1))[1]], fill=(255, 245, 200, 255))
    mx, my = cx + rx * 0.95, cy + 8 * sy
    for sgn in (-1, 1):
        a = 0.25 + mouth * 0.9
        tip = (mx + 12 * math.cos(a), my + sgn * 12 * math.sin(a) + 4)
        opoly(d, [P((mx - 4, my + sgn * 1)), P((mx + 6, my + sgn * 8 * (0.4 + mouth))), P(tip)], (230, 214, 255), OUT, 1.6 * k)
    img = finish(img, soft, crisp, fs, k, tint, 4)
    if dead > 0:
        sh = new(fs * ss, fs * ss); shd = ImageDraw.Draw(sh)
        shards(shd, (cx * k / k, (cy - 4)), dead, CR, 10, 3, 9, 70, k)
        arr = np.array(img).astype(np.float32); arr[..., 3] *= max(0.0, 1 - dead * 1.15)
        img = Image.fromarray(arr.astype(np.uint8), "RGBA")
        img = Image.alpha_composite(img, downsample(sh, (fs, fs)))
    return img

def crawler_rows():
    idle = [crawler(tl=0.5, bob=1.2 * math.sin(i * math.pi / 2), blink=(i == 3), mouth=0.15 + 0.1 * math.sin(i * math.pi / 2)) for i in range(4)]
    move = [crawler(tl=i * 2 * math.pi / 6, bob=2.5 * abs(math.sin(i * math.pi / 6 * 2))) for i in range(6)]
    att = [crawler(lunge=l, mouth=m, sy=s, sx=sxx, tl=0.5) for l, m, s, sxx in
           [(-8, 0.1, 1.08, 0.94), (-12, 0.0, 1.1, 0.92), (6, 1.0, 0.95, 1.05), (16, 1.2, 0.9, 1.1), (8, 0.7, 0.96, 1.03), (0, 0.3, 1.0, 1.0)]]
    hurt = [crawler(tint=0.7, sx=1.1, sy=0.88, lunge=-6, ko=True), crawler(tint=0.3, sx=1.05, sy=0.94, lunge=-4, ko=True), crawler(tint=0.0, lunge=-2)]
    dead = [crawler(dead=t, ko=True, tint=max(0, 0.5 - t), sy=1 - t * 0.35) for t in (0.0, 0.15, 0.32, 0.5, 0.72, 0.95)]
    return [idle, move, att, hurt, dead], (160, 160)

# =========================================================== DRONE (160)
def drone(bob=0.0, tilt=0.0, flame=1.0, charge=0.0, cannon=0.0, tint=0.0, dmg=0.0, boom=0.0, spin=0.0, rot=0.0):
    fs, ss = 160, 3; k = ss
    img = new(fs * ss, fs * ss); d = ImageDraw.Draw(img); soft = new(fs * ss, fs * ss); sd = ImageDraw.Draw(soft)
    crisp = new(fs * ss, fs * ss); cd = ImageDraw.Draw(crisp)
    P = lambda p: (p[0] * k, p[1] * k)
    OUT = (12, 16, 30); ST = (104, 124, 158); STL = (170, 190, 220); STD = (58, 70, 100)
    cx, cy = 80, 78 + bob
    for sgn in (-1, 1):  # thrusters
        tx = cx + sgn * 34 - 0
        fl = 12 + 12 * flame
        sd.polygon([P((tx - 5, cy + 22)), P((tx + 5, cy + 22)), P((tx, cy + 22 + fl * 1.5))], fill=(90, 210, 255, 220))
        cd.polygon([P((tx - 3.5, cy + 22)), P((tx + 3.5, cy + 22)), P((tx, cy + 22 + fl))], fill=(200, 245, 255, 255))
        ocap(d, P((tx, cy + 4)), P((tx, cy + 20)), 11 * k / k, STD, OUT, 2.2 * k)
        d.rectangle([P((tx - 6, cy + 17)), P((tx + 6, cy + 22))], fill=STD)
    ocap(d, P((cx - 30, cy + 2)), P((cx + 30, cy + 2)), 9, STD, OUT, 2.2 * k)
    oell(d, [P((cx - 28, cy - 26))[0], P((cx - 28, cy - 26))[1], P((cx + 28, cy + 28))[0], P((cx + 28, cy + 28))[1]], ST, OUT, 3 * k)
    d.pieslice([P((cx - 28, cy - 26))[0], P((cx - 28, cy - 26))[1], P((cx + 28, cy + 28))[0], P((cx + 28, cy + 28))[1]], 190, 330, fill=STL)
    d.arc([P((cx - 22, cy - 20))[0], P((cx - 22, cy - 20))[1], P((cx + 22, cy + 22))[0], P((cx + 22, cy + 22))[1]], 20, 160, fill=STD, width=int(3 * k))
    for a in (-0.9, 0.0, 0.9):
        capsule(d, P((cx - 24, cy + 10 + 5 * a)), P((cx - 12, cy + 12 + 5 * a)), 2 * k, STD)
    ocap(d, P((cx, cy - 26)), P((cx - 6, cy - 44)), 3 * k, STD, OUT, 1.6 * k)
    cd.ellipse([P((cx - 9, cy - 48))[0], P((cx - 9, cy - 48))[1], P((cx - 3, cy - 42))[0], P((cx - 3, cy - 42))[1]], fill=(255, 80, 80, 255))
    ocap(d, P((cx + 18, cy + 6)), P((cx + 28 + cannon * 8, cy + 6)), 7 * k / k * 1.0, STD, OUT, 2 * k)
    ex, ey = cx + 8, cy - 2
    r = 13
    oell(d, [P((ex - r, ey - r))[0], P((ex - r, ey - r))[1], P((ex + r, ey + r))[0], P((ex + r, ey + r))[1]], (30, 36, 56), OUT, 2.2 * k)
    gr = r * (0.55 + 0.35 * charge)
    sd.ellipse([P((ex - gr * 2.1, ey - gr * 2.1))[0], P((ex - gr * 2.1, ey - gr * 2.1))[1], P((ex + gr * 2.1, ey + gr * 2.1))[0], P((ex + gr * 2.1, ey + gr * 2.1))[1]], fill=(255, 60, 50, int(140 + 90 * charge)))
    cd.ellipse([P((ex - gr, ey - gr))[0], P((ex - gr, ey - gr))[1], P((ex + gr, ey + gr))[0], P((ex + gr, ey + gr))[1]], fill=(255, 76, 64, 255))
    cd.ellipse([P((ex - gr * 0.45, ey - gr * 0.5))[0], P((ex - gr * 0.45, ey - gr * 0.5))[1], P((ex + gr * 0.2, ey + gr * 0.1))[0], P((ex + gr * 0.2, ey + gr * 0.1))[1]], fill=(255, 230, 200, 255))
    for i in range(3):  # rotor ring
        a = spin + i * 2.09
        rx = cx + 34 * math.cos(a); ry = cy - 28 + 4 * math.sin(a)
        cd.ellipse([P((rx - 2.5, ry - 1.5))[0], P((rx - 2.5, ry - 1.5))[1], P((rx + 2.5, ry + 1.5))[0], P((rx + 2.5, ry + 1.5))[1]], fill=(190, 230, 255, 190))
    img = finish(img, soft, crisp, fs, k, tint, 4)
    if abs(rot) > 0.01: img = img.rotate(-rot, resample=Image.BICUBIC, center=(80, 80))
    if dmg > 0:
        s2 = new(fs * ss, fs * ss); dd = ImageDraw.Draw(s2)
        rng = random.Random(5)
        for _ in range(6):
            x, y = cx + rng.uniform(-20, 20), cy + rng.uniform(-18, 18)
            dd.line([P((x, y)), P((x + rng.uniform(-9, 9), y + rng.uniform(-9, 9)))], fill=(255, 230, 120, int(255 * dmg)), width=int(2 * k))
        img = Image.alpha_composite(img, downsample(s2, (fs, fs)))
    if boom > 0:
        s2 = new(fs * ss, fs * ss); dd = ImageDraw.Draw(s2)
        R = 14 + 52 * boom
        dd.ellipse([P((80 - R, 80 - R))[0], P((80 - R, 80 - R))[1], P((80 + R, 80 + R))[0], P((80 + R, 80 + R))[1]], fill=(255, 150, 40, int(230 * (1 - boom * 0.8))))
        R2 = R * 0.6
        dd.ellipse([P((80 - R2, 80 - R2))[0], P((80 - R2, 80 - R2))[1], P((80 + R2, 80 + R2))[0], P((80 + R2, 80 + R2))[1]], fill=(255, 240, 180, int(255 * (1 - boom))))
        shards(dd, (80, 80), boom, (255, 190, 80), 12, 8, 7, 62, k)
        s2 = blur(s2, 2)
        arr = np.array(img).astype(np.float32); arr[..., 3] *= max(0.0, 1 - boom * 1.4); img = Image.fromarray(arr.astype(np.uint8), "RGBA")
        img = Image.alpha_composite(img, downsample(s2, (fs, fs)))
    return img

def drone_rows():
    idle = [drone(bob=3 * math.sin(i * math.pi / 2), flame=0.6 + 0.4 * (i % 2), spin=i * 1.1, rot=2 * math.sin(i * math.pi / 2)) for i in range(4)]
    move = [drone(bob=2 * math.sin(i * math.pi / 3), flame=1.0, tilt=0, rot=9, spin=i * 1.5) for i in range(6)]
    att = [drone(charge=c, cannon=cn, flame=0.7, rot=r, spin=i * 1.2) for i, (c, cn, r) in enumerate([(0.0, 0, 0), (0.35, 0, -3), (0.7, 0, -5), (1.0, 0, -5), (1.0, 1, 4), (0.3, 0.3, 1)])]
    hurt = [drone(tint=0.7, dmg=1, rot=-12, charge=0.0), drone(tint=0.3, dmg=0.7, rot=10), drone(dmg=0.4, rot=-4)]
    dead = [drone(dmg=1, tint=0.5, rot=15), drone(dmg=1, rot=-20, bob=4), drone(boom=0.15, rot=25), drone(boom=0.4, rot=30), drone(boom=0.7, rot=30), drone(boom=1.0, rot=30)]
    return [idle, move, att, hurt, dead], (160, 160)

# =========================================================== BRUTE (224)
def brute(lean=0.35, legs=((0.15, -0.1), (-0.2, -0.15)), arms=((0.3, 0.2), (0.1, 0.1)), tint=0.0, glow=0.7, shock=0.0,
          head=0.0, hy=None, dead=0.0, sink=0.0, eye=1.0):
    fs, ss = 224, 3; k = ss; GY = 206
    img = new(fs * ss, fs * ss); d = ImageDraw.Draw(img); soft = new(fs * ss, fs * ss); sd = ImageDraw.Draw(soft)
    crisp = new(fs * ss, fs * ss); cd = ImageDraw.Draw(crisp)
    P = lambda p: (p[0] * k, p[1] * k)
    OUT = (14, 8, 24); BODY = (56, 36, 78); BL = (96, 66, 128); BD = (36, 22, 54); CRK = (255, 140, 40)
    L = 34.0
    if hy is None:
        hy = GY - max(math.cos(a) * L + math.cos(b) * L + 8 for a, b in legs) + sink
    H = (108.0, hy); u = (math.sin(lean), -math.cos(lean)); n = (math.cos(lean), math.sin(lean))
    Sh = (H[0] + u[0] * 58, H[1] + u[1] * 58); ow = 3 * k
    far = lambda c: shade(c, 0.7)
    def leg(th, sh, near):
        kn = fk(H, th, L); an = fk(kn, sh, L)
        ocap(d, P((H[0] + (3 if near else -3), H[1])), P(kn), 26 * k, BODY if near else far(BODY), OUT, ow)
        ocap(d, P(kn), P(an), 21 * k, BD if near else far(BD), OUT, ow)
        ocap(d, P((an[0] - 6, an[1] + 3)), P((an[0] + 14, an[1] + 6)), 17 * k, BODY if near else far(BODY), OUT, ow)
    def arm(ua, fa, near):
        sp = (Sh[0] - u[0] * 8 + n[0] * (6 if near else -6), Sh[1] - u[1] * 8)
        el = fk(sp, ua, 40); hd = fk(el, fa, 40)
        ocap(d, P(sp), P(el), 24 * k, BL if near else far(BL), OUT, ow)
        ocap(d, P(el), P(hd), 22 * k, BODY if near else far(BODY), OUT, ow)
        oell(d, [P(hd)[0] - 17 * k, P(hd)[1] - 17 * k, P(hd)[0] + 17 * k, P(hd)[1] + 17 * k], BD if near else far(BD), OUT, ow)
        sd.ellipse([P(hd)[0] - 14 * k, P(hd)[1] - 14 * k, P(hd)[0] + 14 * k, P(hd)[1] + 14 * k], fill=CRK + (int(90 * glow),))
        for q in (-0.4, 0.2): capsule(cd, P((hd[0] + q * 18 - 1, hd[1] - 6)), P((hd[0] + q * 18 + 2, hd[1] + 7)), 1.8 * k, CRK + (int(255 * glow),))
        return hd
    leg(legs[1][0], legs[1][1], False); arm(arms[1][0], arms[1][1], False)
    pts = [(H[0] - n[0] * 22, H[1] - n[1] * 22), (H[0] + n[0] * 22, H[1] + n[1] * 22), (Sh[0] + n[0] * 38, Sh[1] + n[1] * 38),
           (Sh[0] + u[0] * 10, Sh[1] + u[1] * 10), (Sh[0] - n[0] * 36, Sh[1] - n[1] * 36)]
    opoly(d, [P(p) for p in pts], BODY, OUT, ow)
    d.polygon([P((H[0] + n[0] * 4 + u[0] * 22, H[1] + n[1] * 4 + u[1] * 22)), P((H[0] + n[0] * 20 + u[0] * 6, H[1] + n[1] * 20 + u[1] * 6)),
               P((Sh[0] + n[0] * 36, Sh[1] + n[1] * 36)), P((Sh[0] + n[0] * 4, Sh[1] + n[1] * 4))], fill=BL)
    cr = [(0.1, 0.25), (0.22, 0.38), (0.12, 0.5), (0.28, 0.62), (0.18, 0.78)]
    cp = [P((H[0] + u[0] * 58 * b + n[0] * 36 * (a - 0.1) * 1.0, H[1] + u[1] * 58 * b + n[1] * 36 * (a - 0.1))) for a, b in cr]
    sd.line(cp, fill=CRK + (int(210 * glow),), width=int(7 * k)); cd.line(cp, fill=(255, 210, 120, int(255 * glow)), width=int(2.2 * k))
    HC = (Sh[0] + n[0] * 22 + u[0] * 6, Sh[1] + n[1] * 22 + u[1] * 6 + 2)
    HC = (HC[0] + math.sin(head) * 4, HC[1])
    for sgn in (-1,):
        horn = [P((HC[0] - 4, HC[1] - 14)), P((HC[0] - 22, HC[1] - 44)), P((HC[0] - 12, HC[1] - 12))]
        opoly(d, horn, (222, 206, 236), OUT, 2 * k)
    oell(d, [P(HC)[0] - 19 * k, P(HC)[1] - 17 * k, P(HC)[0] + 19 * k, P(HC)[1] + 17 * k], BL, OUT, ow)
    opoly(d, [P((HC[0] + 4, HC[1] - 16)), P((HC[0] + 18, HC[1] - 40)), P((HC[0] + 14, HC[1] - 12))], (222, 206, 236), OUT, 2 * k)
    ex, ey = HC[0] + 10, HC[1] - 2
    sd.ellipse([P((ex - 12, ey - 8))[0], P((ex - 12, ey - 8))[1], P((ex + 10, ey + 8))[0], P((ex + 10, ey + 8))[1]], fill=CRK + (int(210 * eye),))
    cd.polygon([P((ex - 8, ey - 5 * eye)), P((ex + 8, ey - 1)), P((ex + 5, ey + 5 * eye)), P((ex - 7, ey + 2))], fill=(255, 220, 130, 255))
    mw = HC[0] + 6; d.polygon([P((mw, HC[1] + 8)), P((mw + 14, HC[1] + 6)), P((mw + 12, HC[1] + 13)), P((mw + 2, HC[1] + 13))], fill=OUT)
    for q in range(3): d.polygon([P((mw + 2 + q * 4, HC[1] + 8)), P((mw + 4 + q * 4, HC[1] + 12)), P((mw + 6 + q * 4, HC[1] + 8))], fill=(240, 232, 250))
    leg(legs[0][0], legs[0][1], True)
    hd = arm(arms[0][0], arms[0][1], True)
    img = finish(img, soft, crisp, fs, k, tint, 5)
    if shock > 0:
        s2 = new(fs * ss, fs * ss); dd = ImageDraw.Draw(s2)
        R = 20 + 80 * shock
        dd.ellipse([P((hd[0] - R, GY - R * 0.28))[0], P((hd[0] - R, GY - R * 0.28))[1], P((hd[0] + R, GY + R * 0.18))[0], P((hd[0] + R, GY + R * 0.18))[1]], outline=(255, 200, 120, int(230 * (1 - shock * 0.6))), width=int(5 * k))
        img = Image.alpha_composite(img, downsample(blur(s2, 1.5), (fs, fs)))
    if dead > 0:
        sh = new(fs * ss, fs * ss); shd = ImageDraw.Draw(sh)
        shards(shd, (112, 150), dead, CRK, 16, 11, 12, 86, k)
        arr = np.array(img).astype(np.float32); arr[..., 3] *= max(0.0, 1 - max(0, dead - 0.35) * 1.5); img = Image.fromarray(arr.astype(np.uint8), "RGBA")
        img = Image.alpha_composite(img, downsample(sh, (fs, fs)))
    return img

def brute_rows():
    idle = [brute(lean=0.34 + 0.03 * math.sin(i * math.pi / 2), arms=((0.35 + 0.05 * math.sin(i * math.pi / 2), 0.2), (0.1, 0.0)), glow=0.55 + 0.25 * math.sin(i * math.pi / 2 + 1)) for i in range(4)]
    def stride(p):
        th = 0.6 * math.sin(p); return (th, th - 0.2 - 0.6 * max(0, math.cos(p)))
    move = [brute(lean=0.4, legs=(stride(i * math.pi / 3), stride(i * math.pi / 3 + math.pi)), arms=((-0.5 * math.sin(i * math.pi / 3), 0.3), (0.5 * math.sin(i * math.pi / 3), 0.2))) for i in range(6)]
    up = [(0.3, 0.2), (2.0, 2.4), (2.9, 3.0), (3.1, 3.14)]
    att = []
    for i, (a, b) in enumerate([(0.3, 0.2), (1.6, 2.2), (2.8, 3.1), (3.1, 3.14), (0.5, 0.4), (0.4, 0.3)]):
        att.append(brute(lean=[0.3, 0.05, -0.15, -0.2, 0.5, 0.45][i], arms=((a, b), (a * 0.9, b)),
                         legs=((0.2, -0.1), (-0.2, -0.15)) if i < 4 else ((0.5, -0.4), (-0.4, -0.5)), glow=1.0, shock=[0, 0, 0, 0, 0.25, 0.8][i]))
    hurt = [brute(tint=0.7, lean=-0.05, arms=((-0.6, -0.5), (-0.8, -0.3)), head=-0.4), brute(tint=0.3, lean=0.05), brute(lean=0.25)]
    dead = [brute(lean=l, legs=lg, tint=t, dead=dd, glow=gl, sink=s, arms=((0.3, 0.1), (0.2, 0.1)), eye=e)
            for l, lg, t, dd, gl, s, e in [(0.2, ((0.2, -0.1), (-0.2, -0.15)), 0.6, 0.0, 1.0, 0, 1), (0.3, ((0.4, -0.7), (-0.2, -0.5)), 0.3, 0.1, 0.9, 6, 0.8),
                                           (0.5, ((0.8, -1.0), (0.2, -0.9)), 0.0, 0.25, 0.7, 16, 0.5), (0.7, ((1.0, -1.2), (0.4, -1.1)), 0, 0.45, 0.5, 24, 0.2),
                                           (0.8, ((1.1, -1.3), (0.5, -1.2)), 0, 0.7, 0.3, 28, 0.1), (0.8, ((1.1, -1.3), (0.5, -1.2)), 0, 0.95, 0.1, 30, 0.1)]]
    return [idle, move, att, hurt, dead], (224, 224)

# =========================================================== VOID GUARDIAN (320)
def guardian(bob=0.0, fl=(70, 190), fr=(250, 190), core=0.5, halo=0.0, tint=0.0, crack=0.0, dead=0.0, charge=0.0, ring=0.0, visor=1.0):
    fs, ss = 320, 2; k = ss
    img = new(fs * ss, fs * ss); d = ImageDraw.Draw(img); soft = new(fs * ss, fs * ss); sd = ImageDraw.Draw(soft)
    crisp = new(fs * ss, fs * ss); cd = ImageDraw.Draw(crisp)
    P = lambda p: (p[0] * k, p[1] * k + 0)
    OUT = (12, 6, 26); AR = (50, 40, 88); ARL = (110, 92, 178); ARD = (30, 22, 58); MG = (255, 70, 210); VO = (180, 110, 255)
    cx = 160; by = bob
    # halo
    hc = (cx, 114 + by)
    for r_, wdt, al in ((102, 5, 170), (88, 2.5, 120)):
        sd.ellipse([P((hc[0] - r_, hc[1] - r_))[0], P((hc[0] - r_, hc[1] - r_))[1], P((hc[0] + r_, hc[1] + r_))[0], P((hc[0] + r_, hc[1] + r_))[1]], outline=VO + (al,), width=int((wdt + 3) * k))
        d.ellipse([P((hc[0] - r_, hc[1] - r_))[0], P((hc[0] - r_, hc[1] - r_))[1], P((hc[0] + r_, hc[1] + r_))[0], P((hc[0] + r_, hc[1] + r_))[1]], outline=(130, 90, 220, 255), width=int(wdt * k))
    for i in range(12):
        a = halo + i * math.pi / 6
        p0 = (hc[0] + math.cos(a) * 88, hc[1] + math.sin(a) * 88); p1 = (hc[0] + math.cos(a) * 108, hc[1] + math.sin(a) * 108)
        capsule(cd, P(p0), P(p1), 4 * k, MG + (255,)); sd.line([P(p0), P(p1)], fill=MG + (200,), width=int(9 * k))
    # robe/tail
    tail = [(cx - 48, 205 + by), (cx + 48, 205 + by), (cx + 34, 250 + by), (cx + 16, 292 + by), (cx, 306 + by), (cx - 16, 292 + by), (cx - 34, 250 + by)]
    opoly(d, [P(p) for p in tail], ARD, OUT, 3 * k)
    for off in (-22, 0, 22): capsule(d, P((cx + off, 215 + by)), P((cx + off * 0.2, 290 + by)), 3 * k, (80, 50, 140))
    sd.polygon([P((cx - 20, 230 + by)), P((cx + 20, 230 + by)), P((cx, 300 + by))], fill=VO + (90,))
    # arms (connected energy + armor)
    for sgn, f in ((-1, fl), (1, fr)):
        sp = (cx + sgn * 88, 140 + by)
        mid = ((sp[0] + f[0]) / 2, (sp[1] + f[1]) / 2 + 12)
        ocap(d, P(sp), P(mid), 30 * k / k * 1.0, ARL if sgn > 0 else shade(ARL, 0.85), OUT, 3 * k)
        ocap(d, P(mid), P(f), 28 * k / k * 1.0, AR, OUT, 3 * k)
        sd.line([P(sp), P(mid), P(f)], fill=VO + (140,), width=int(12 * k))
        oell(d, [P(f)[0] - 34 * k, P(f)[1] - 32 * k, P(f)[0] + 34 * k, P(f)[1] + 32 * k], AR, OUT, 3.2 * k)
        for q in range(3):
            capsule(d, P((f[0] - 18 + q * 18, f[1] + 2)), P((f[0] - 18 + q * 18, f[1] + 22)), 12 * k / k * 1.0, ARL if q != 1 else shade(ARL, 1.1))
        sd.ellipse([P((f[0] - 38, f[1] - 36))[0], P((f[0] - 38, f[1] - 36))[1], P((f[0] + 38, f[1] + 36))[0], P((f[0] + 38, f[1] + 36))[1]], fill=MG + (int(60 + 120 * charge),))
        cd.line([P((f[0] - 16, f[1] - 14)), P((f[0] + 16, f[1] - 14))], fill=MG + (255,), width=int(3 * k))
    # torso
    tor = [(cx - 64, 118 + by), (cx + 64, 118 + by), (cx + 46, 214 + by), (cx - 46, 214 + by)]
    opoly(d, [P(p) for p in tor], AR, OUT, 3.5 * k)
    d.polygon([P((cx - 56, 122 + by)), P((cx + 8, 122 + by)), P((cx - 8, 208 + by)), P((cx - 40, 208 + by))], fill=ARL)
    d.polygon([P((cx - 30, 118 + by)), P((cx + 30, 118 + by)), P((cx + 20, 134 + by)), P((cx - 20, 134 + by))], fill=ARD)
    capsule(d, P((cx - 40, 205 + by)), P((cx + 40, 205 + by)), 8 * k / k * 1.0, MG + (255,))
    # core
    cc = (cx, 166 + by); cr = 17 + 4 * core
    sd.ellipse([P((cc[0] - cr * 2.6, cc[1] - cr * 2.6))[0], P((cc[0] - cr * 2.6, cc[1] - cr * 2.6))[1], P((cc[0] + cr * 2.6, cc[1] + cr * 2.6))[0], P((cc[0] + cr * 2.6, cc[1] + cr * 2.6))[1]], fill=VO + (int(120 + 130 * core),))
    d.ellipse([P((cc[0] - 22, cc[1] - 22))[0], P((cc[0] - 22, cc[1] - 22))[1], P((cc[0] + 22, cc[1] + 22))[0], P((cc[0] + 22, cc[1] + 22))[1]], fill=OUT)
    cd.ellipse([P((cc[0] - cr, cc[1] - cr))[0], P((cc[0] - cr, cc[1] - cr))[1], P((cc[0] + cr, cc[1] + cr))[0], P((cc[0] + cr, cc[1] + cr))[1]], fill=VO + (255,))
    cd.ellipse([P((cc[0] - cr * 0.55, cc[1] - cr * 0.55))[0], P((cc[0] - cr * 0.55, cc[1] - cr * 0.55))[1], P((cc[0] + cr * 0.55, cc[1] + cr * 0.55))[0], P((cc[0] + cr * 0.55, cc[1] + cr * 0.55))[1]], fill=(245, 230, 255, 255))
    if charge > 0:
        R = 26 + 50 * charge
        sd.ellipse([P((cx - R, 205 + by - R * 0.4))[0], P((cx - R, 205 + by - R * 0.4))[1], P((cx + R, 205 + by + R * 0.4 + R * 0.6))[0], P((cx + R, 205 + by + R * 0.4 + R * 0.6))[1]], fill=MG + (int(70 * charge),))
    # pauldrons
    for sgn in (-1, 1):
        px = cx + sgn * 80
        opoly(d, [P((px - sgn * 30, 108 + by)), P((px + sgn * 26, 112 + by)), P((px + sgn * 44, 142 + by)), P((px - sgn * 14, 152 + by))], ARL if sgn > 0 else shade(ARL, 0.9), OUT, 3 * k)
        opoly(d, [P((px + sgn * 8, 108 + by)), P((px + sgn * 24, 70 + by)), P((px + sgn * 30, 114 + by))], (200, 180, 255), OUT, 2.5 * k)
        capsule(cd, P((px - sgn * 14, 126 + by)), P((px + sgn * 30, 130 + by)), 3 * k, MG + (255,))
    # head
    hdc = (cx, 86 + by)
    for sgn in (-1, 1):
        horn = [P((hdc[0] + sgn * 22, hdc[1] - 22)), P((hdc[0] + sgn * 56, hdc[1] - 58)), P((hdc[0] + sgn * 50, hdc[1] - 14)), P((hdc[0] + sgn * 30, hdc[1] - 6))]
        opoly(d, horn, (210, 190, 250), OUT, 2.8 * k)
    helm = [(hdc[0] - 36, hdc[1] - 18), (hdc[0] - 22, hdc[1] - 38), (hdc[0] + 22, hdc[1] - 38), (hdc[0] + 36, hdc[1] - 18), (hdc[0] + 30, hdc[1] + 26), (hdc[0], hdc[1] + 40), (hdc[0] - 30, hdc[1] + 26)]
    opoly(d, [P(p) for p in helm], AR, OUT, 3.5 * k)
    d.polygon([P((hdc[0] - 30, hdc[1] - 20)), P((hdc[0] - 16, hdc[1] - 34)), P((hdc[0] + 6, hdc[1] - 34)), P((hdc[0] - 6, hdc[1] - 14))], fill=ARL)
    crest = [(hdc[0] - 5, hdc[1] - 38), (hdc[0], hdc[1] - 66), (hdc[0] + 5, hdc[1] - 38)]
    opoly(d, [P(p) for p in crest], MG, OUT, 2.5 * k)
    vis = [P((hdc[0] - 28, hdc[1] - 2)), P((hdc[0] + 28, hdc[1] - 2)), P((hdc[0] + 20, hdc[1] + 12)), P((hdc[0] - 20, hdc[1] + 12))]
    d.polygon(vis, fill=OUT)
    sd.polygon([(x - 0, y) for x, y in vis], fill=MG + (int(220 * visor),))
    cd.polygon([P((hdc[0] - 24, hdc[1] + 1)), P((hdc[0] + 24, hdc[1] + 1)), P((hdc[0] + 17, hdc[1] + 8)), P((hdc[0] - 17, hdc[1] + 8))], fill=(255, 140, 235, int(255 * visor)))
    capsule(d, P((hdc[0] - 6, hdc[1] + 18)), P((hdc[0] + 6, hdc[1] + 18)), 3 * k, ARD)
    if crack > 0:
        rng = random.Random(21)
        for _ in range(int(3 + 9 * crack)):
            x, y = cx + rng.uniform(-50, 50), 120 + by + rng.uniform(0, 90)
            pts = [(x, y)]
            for __ in range(3): pts.append((pts[-1][0] + rng.uniform(-14, 14), pts[-1][1] + rng.uniform(4, 16)))
            cd.line([P(p) for p in pts], fill=(255, 190, 255, 255), width=int(2.4 * k)); sd.line([P(p) for p in pts], fill=MG + (230,), width=int(6 * k))
    img = finish(img, soft, crisp, fs, k, tint, 7)
    if ring > 0:
        s2 = new(fs * ss, fs * ss); dd = ImageDraw.Draw(s2)
        R = 40 + 130 * ring
        dd.ellipse([P((cx - R, 166 - R))[0], P((cx - R, 166 - R))[1], P((cx + R, 166 + R))[0], P((cx + R, 166 + R))[1]], outline=(255, 220, 255, int(240 * (1 - ring))), width=int(8 * k))
        img = Image.alpha_composite(img, downsample(blur(s2, 2), (fs, fs)))
    if dead > 0:
        sh = new(fs * ss, fs * ss); shd = ImageDraw.Draw(sh)
        shards(shd, (cx, 170), dead, (190, 130, 255), 26, 4, 15, 150, k)
        shards(shd, (cx, 150), dead, MG, 16, 9, 10, 130, k)
        arr = np.array(img).astype(np.float32); arr[..., 3] *= max(0.0, 1 - max(0, dead - 0.4) * 1.7); img = Image.fromarray(arr.astype(np.uint8), "RGBA")
        img = Image.alpha_composite(img, downsample(sh, (fs, fs)))
    return img

def guardian_rows():
    idle = [guardian(bob=5 * math.sin(i * math.pi / 3), fl=(72, 192 + 6 * math.sin(i * math.pi / 3 + 1)), fr=(248, 192 + 6 * math.sin(i * math.pi / 3 + 2)),
                     core=0.5 + 0.4 * math.sin(i * math.pi / 3), halo=i * 0.12) for i in range(6)]
    slam = []
    ys = [150, 100, 52, 36, 260, 276, 220, 190]; xs = [248, 252, 256, 256, 256, 256, 252, 248]
    for i in range(8):
        slam.append(guardian(fr=(xs[i], ys[i]), fl=(72, 192 - (i < 4) * 10), core=0.5 + 0.4 * (i in (3, 4)), halo=i * 0.2, bob=[0, -4, -8, -10, 6, 4, 2, 0][i],
                             ring=(0.0 if i < 4 else [0.2, 0.5, 0.8, 0.0][i - 4] if i < 8 else 0), charge=0.5 if i in (2, 3) else 0.0))
    cast = []
    for i in range(8):
        c = [0.1, 0.3, 0.6, 0.9, 1.0, 1.0, 0.5, 0.1][i]
        cast.append(guardian(fl=(100 - 40 * c, 170 - 18 * c), fr=(220 + 40 * c, 170 - 18 * c), core=0.4 + 0.6 * c, halo=i * 0.5, charge=c, bob=-4 * c, visor=1.0))
    hurt = [guardian(tint=0.6, bob=-6, crack=0.3, fl=(60, 200), fr=(260, 200), core=1.0), guardian(tint=0.3, bob=4, crack=0.3), guardian(bob=-2, crack=0.3)]
    dead = [guardian(tint=0.4, crack=0.3, bob=-4), guardian(crack=0.6, core=1.0, bob=-8, tint=0.2),
            guardian(crack=0.9, core=1.0, bob=-10, dead=0.1, fl=(60, 210), fr=(260, 210), ring=0.2), guardian(crack=1, core=1.0, bob=-6, dead=0.28, fl=(50, 240), fr=(270, 240), halo=2),
            guardian(crack=1, core=1.0, bob=0, dead=0.45, fl=(40, 270), fr=(280, 270), ring=0.5), guardian(crack=1, core=1.0, bob=6, dead=0.62, fl=(30, 290), fr=(290, 290)),
            guardian(crack=1, core=1.0, bob=12, dead=0.82, fl=(30, 300), fr=(290, 300), ring=0.8), guardian(crack=1, core=1.0, bob=18, dead=1.0, fl=(30, 300), fr=(290, 300))]
    return [idle, slam, cast, hurt, dead], (320, 320)

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    for name, fn, cols in (("crawler", crawler_rows, 6), ("drone", drone_rows, 6), ("brute", brute_rows, 6), ("guardian", guardian_rows, 8)):
        rows, F = fn()
        sheet = make_sheet(rows, F, cols)
        sheet.save(os.path.join(out, name + "_sheet.png"), optimize=True)
        print(name, sheet.size, [len(r) for r in rows])
