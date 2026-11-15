"""Environment, props, pickups, UI art for Shadow Runner - original procedural artwork."""
import math, sys, os, random
sys.path.insert(0, os.path.dirname(__file__))
from artlib import *
from PIL import ImageFont

W, H = 1280, 720
FONT = os.path.join(os.path.dirname(__file__), "..", "assets", "fonts", "BigShoulders-Bold.ttf")

def save(img, out, name):
    img.save(os.path.join(out, name), optimize=True)

def jagged_building(d, x, w, top, base, col, rng, S, wrap_w, win_cols=None, rim=None, win_p=0.18):
    for ox in (0, -wrap_w, wrap_w):
        xx = x + ox
        if xx > wrap_w + w or xx + w < -w: continue
        pts = [(xx, base)]
        n = max(3, int(w / 28)); cur = top
        for i in range(n + 1):
            cur = top + rng.choice([0, 0, 6, 14, 30, 52]) if rng.random() < 0.6 else cur
            if i == 0 or i == n: cur = top + (rng.choice([0, 8]))
            pts.append((xx + w * i / n, cur))
        pts.append((xx + w, base))
        d.polygon([(p[0] * S, p[1] * S) for p in pts], fill=col + (255,))
        if rim is not None:
            d.line([(pts[1][0] * S, pts[1][1] * S)] + [(p[0] * S, p[1] * S) for p in pts[2:-1]], fill=rim + (255,), width=int(2 * S))
            d.line([((xx + w) * S, pts[-2][1] * S), ((xx + w) * S, base * S)], fill=rim + (160,), width=int(2 * S))
        if win_cols:
            for wy in range(int(top + 24), int(base - 20), 26):
                for wx in range(int(xx + 10), int(xx + w - 14), 20):
                    if rng.random() < win_p and wy > min(p[1] for p in pts[1:-1]) + 14:
                        c = rng.choice(win_cols)
                        d.rectangle([wx * S, wy * S, (wx + 9) * S, (wy + 13) * S], fill=c + (255,))
        if rng.random() < 0.5:
            ax = xx + w * rng.uniform(0.2, 0.8)
            d.line([(ax * S, top * S), ((ax + rng.uniform(-8, 8)) * S, (top - rng.uniform(20, 60)) * S)], fill=col + (255,), width=int(3 * S))

def bg_sky(out):
    S = 1
    img = vgrad(W, H, [(0, (9, 7, 32)), (0.3, (38, 20, 78)), (0.55, (112, 40, 112)), (0.78, (222, 96, 112)), (1, (255, 170, 118))])
    a = np.array(img).astype(np.float32)
    n1 = tile_noise(W, H, 6, 5, 1); n2 = tile_noise(W, H, 14, 9, 2); n3 = tile_noise(W, H, 26, 16, 3)
    cl = np.clip((n1 * 0.55 + n2 * 0.3 + n3 * 0.15 - 0.5) * 3.2, 0, 1) * np.clip(np.linspace(0.2, 1.1, H), 0, 1)[:, None]
    for c, col in enumerate((255, 120, 190)):
        a[..., c] = a[..., c] * (1 - cl * 0.45) + col * cl * 0.45
    img = Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")
    big = img.resize((W * 2, H * 2), Image.BICUBIC); d = ImageDraw.Draw(big)
    rng = random.Random(4)
    for _ in range(260):
        x, y = rng.uniform(0, W), rng.uniform(0, H * 0.55); r = rng.choice([0.8, 1, 1.4, 2])
        al = int(rng.uniform(90, 255) * (1 - y / (H * 0.6)))
        d.ellipse([(x - r) * 2, (y - r) * 2, (x + r) * 2, (y + r) * 2], fill=(255, 240, 255, max(30, al)))
    glow = new(W * 2, H * 2); gd = ImageDraw.Draw(glow)
    mx, my, mr = 880, 200, 100
    for rr, al in ((mr * 2.6, 40), (mr * 1.9, 60), (mr * 1.4, 90)):
        gd.ellipse([(mx - rr) * 2, (my - rr) * 2, (mx + rr) * 2, (my + rr) * 2], fill=(255, 150, 230, al))
    big = Image.alpha_composite(big, blur(glow, 40))
    d = ImageDraw.Draw(big)
    d.ellipse([(mx - mr) * 2, (my - mr) * 2, (mx + mr) * 2, (my + mr) * 2], fill=(250, 226, 240, 255))
    for (cx, cy, r, c) in [(-30, -20, 26, (226, 200, 224)), (28, 14, 34, (232, 208, 228)), (-6, 44, 18, (224, 198, 222)), (40, -42, 14, (228, 204, 226))]:
        d.ellipse([(mx + cx - r) * 2, (my + cy - r) * 2, (mx + cx + r) * 2, (my + cy + r) * 2], fill=c + (255,))
    # crescent shadow
    sh = new(W * 2, H * 2); sd = ImageDraw.Draw(sh)
    sd.ellipse([(mx - mr + 38) * 2, (my - mr - 8) * 2, (mx + mr + 38) * 2, (my + mr - 8) * 2], fill=(60, 30, 96, 130))
    mask = new(W * 2, H * 2); ImageDraw.Draw(mask).ellipse([(mx - mr) * 2, (my - mr) * 2, (mx + mr) * 2, (my + mr) * 2], fill=(255, 255, 255, 255))
    sh.putalpha(ImageChops_mul(sh.split()[3], mask.split()[3]))
    big = Image.alpha_composite(big, sh)
    # void rift
    rift = new(W * 2, H * 2); rd = ImageDraw.Draw(rift)
    pts = [(330, -10)]
    for i in range(14): pts.append((pts[-1][0] + rng.uniform(-22, 22), pts[-1][1] + rng.uniform(18, 34)))
    rd.line([(x * 2, y * 2) for x, y in pts], fill=(255, 90, 220, 255), width=14)
    big = Image.alpha_composite(big, blur(rift, 14))
    rd2 = ImageDraw.Draw(big); rd2.line([(x * 2, y * 2) for x, y in pts], fill=(255, 220, 250, 255), width=4)
    save(downsample(big, (W, H)).convert("RGB").convert("RGBA"), out, "bg_sky.png")

def ImageChops_mul(a, b):
    from PIL import ImageChops
    return ImageChops.multiply(a, b)

def bg_far(out):
    S = 2; img = new(W * S, H * S); d = ImageDraw.Draw(img); rng = random.Random(11)
    x = -40
    while x < W:
        w = rng.randint(70, 150); h = rng.randint(150, 330)
        jagged_building(d, x, w, H - h - 20, H, (92, 54, 128), rng, S, W)
        x += w * rng.uniform(0.6, 1.0)
    img = downsample(img, (W, H))
    fog = vgrad(W, H, [(0, (255, 140, 160)), (1, (255, 140, 160))]); a = np.array(fog); ys = np.linspace(0, 1, H)
    a[..., 3] = (np.clip((ys - 0.45) * 1.5, 0, 0.78) * 255).astype(np.uint8)[:, None]
    fog = Image.fromarray(a, "RGBA")
    fog.putalpha(ImageChops_mul(fog.split()[3], img.split()[3]))
    save(Image.alpha_composite(img, fog), out, "bg_far.png")

def bg_mid(out):
    S = 2; img = new(W * S, H * S); d = ImageDraw.Draw(img); rng = random.Random(23)
    x = 10
    while x < W + 20:
        w = rng.randint(120, 230); h = rng.randint(220, 470)
        jagged_building(d, x, w, H - h, H + 10, (46, 30, 82), rng, S, W, win_cols=[(255, 196, 110), (255, 150, 90), (110, 220, 255), (255, 110, 200)], rim=(170, 110, 230), win_p=0.15)
        x += w + rng.randint(-20, 30)
    # leaning fallen tower
    d.polygon([(640 * S, (H) * S), (700 * S, H * S), (900 * S, 250 * S), (860 * S, 232 * S)], fill=(38, 24, 70, 255))
    img = downsample(img, (W, H))
    shade_ = vgrad(W, H, [(0, (255, 120, 140)), (1, (255, 120, 140))]); a = np.array(shade_); ys = np.linspace(0, 1, H)
    a[..., 3] = (np.clip((ys - 0.55) * 1.2, 0, 0.5) * 255).astype(np.uint8)[:, None]
    f = Image.fromarray(a, "RGBA"); f.putalpha(ImageChops_mul(f.split()[3], img.split()[3]))
    save(Image.alpha_composite(img, f), out, "bg_mid.png")

def bg_near(out):
    S = 2; img = new(W * S, H * S); d = ImageDraw.Draw(img); rng = random.Random(37)
    for x in (80, 330, 600, 860, 1130):
        w = rng.randint(46, 72); top = rng.randint(250, 400)
        for ox in (0, -W):
            xx = x + ox
            pts = [(xx, H), (xx, top + 20), (xx + w * 0.3, top), (xx + w * 0.5, top + 26), (xx + w * 0.8, top + 6), (xx + w, top + 30), (xx + w, H)]
            d.polygon([(p[0] * S, p[1] * S) for p in pts], fill=(20, 14, 38, 255))
            d.line([((xx + w) * S, (top + 30) * S), ((xx + w) * S, H * S)], fill=(80, 220, 240, 120), width=int(2 * S))
            for yy in range(int(top + 60), H, 70): d.line([(xx * S, yy * S), ((xx + w) * S, yy * S)], fill=(34, 24, 58, 255), width=int(3 * S))
    for (x0, x1) in ((80, 330), (600, 860), (1130, 1360)):
        for ox in (0, -W):
            pts = []
            for i in range(21):
                t = i / 20; pts.append(((x0 + (x1 - x0) * t + ox) * S, (300 + 80 * math.sin(math.pi * t) + 6 * math.sin(t * 20)) * S))
            d.line(pts, fill=(14, 10, 28, 255), width=int(4 * S))
    save(downsample(img, (W, H)), out, "bg_near.png")

def fog(out):
    n = tile_noise(W, 360, 8, 4, 91) * 0.6 + tile_noise(W, 360, 18, 8, 92) * 0.4
    a = np.zeros((360, W, 4), np.uint8); a[..., 0], a[..., 1], a[..., 2] = 220, 190, 255
    ys = np.linspace(0, 1, 360)[:, None]
    a[..., 3] = (np.clip((n - 0.35) * 2.2, 0, 1) * np.sin(ys * math.pi) * 120).astype(np.uint8)
    save(Image.fromarray(a, "RGBA"), out, "fog.png")

def vignette(out):
    y, x = np.mgrid[0:360, 0:640].astype(np.float32)
    r = np.sqrt(((x - 320) / 320) ** 2 + ((y - 180) / 180) ** 2)
    a = np.zeros((360, 640, 4), np.uint8); a[..., 0], a[..., 1], a[..., 2] = 6, 2, 20
    a[..., 3] = (np.clip((r - 0.55) / 0.85, 0, 1) ** 1.6 * 200).astype(np.uint8)
    save(Image.fromarray(a, "RGBA").resize((1280, 720), Image.BICUBIC), out, "vignette.png")

# ------------------------------------------------------------------ tiles
def ground_top(out):
    S = 4; w, h = 128, 48; img = new(w * S, h * S); d = ImageDraw.Draw(img); rng = random.Random(5)
    d.rectangle([0, 0, w * S, h * S], fill=(54, 46, 86, 255))
    d.rectangle([0, 0, w * S, 14 * S], fill=(124, 112, 168, 255))
    d.rectangle([0, 11 * S, w * S, 14 * S], fill=(88, 76, 128, 255))
    for i in range(4):
        x = i * 32 + 2
        d.line([(x * S, 18 * S), (x * S, h * S)], fill=(38, 32, 64, 255), width=3 * S)
    d.line([(0, 28 * S), (w * S, 28 * S)], fill=(38, 32, 64, 255), width=3 * S)
    for _ in range(14):
        x = rng.uniform(4, 124); y = rng.uniform(18, 44)
        d.ellipse([(x - 3) * S, (y - 2) * S, (x + 3) * S, (y + 2) * S], fill=(72, 62, 108, 255))
    d.rectangle([0, 0, w * S, 3 * S], fill=(120, 240, 250, 255))
    img = downsample(img, (w, h)); g = new(w, h); ImageDraw.Draw(g).rectangle([0, 0, w, 6], fill=(90, 230, 250, 110))
    img = Image.alpha_composite(img, blur(g, 2)); save(img, out, "ground_top.png")

def ground_body(out):
    S = 3; w, h = 128, 128; img = new(w * S, h * S); d = ImageDraw.Draw(img); rng = random.Random(8)
    d.rectangle([0, 0, w * S, h * S], fill=(30, 24, 52, 255))
    for row in range(4):
        off = 32 if row % 2 else 0
        for cx in range(-1, 3):
            x0 = cx * 64 + off; y0 = row * 32
            c = (rng.randint(44, 62), rng.randint(36, 52), rng.randint(76, 104))
            for ox in (0, 128, -128):
                d.rectangle([(x0 + ox + 2) * S, (y0 + 2) * S, (x0 + ox + 62) * S, (y0 + 30) * S], fill=c + (255,))
                d.rectangle([(x0 + ox + 2) * S, (y0 + 2) * S, (x0 + ox + 62) * S, (y0 + 6) * S], fill=shade(c, 1.25) + (255,))
    for _ in range(9):
        x = rng.uniform(0, 128); y = rng.uniform(0, 128)
        for ox in (0, -128, 128):
            d.ellipse([(x + ox - 6) * S, (y - 3) * S, (x + ox + 6) * S, (y + 3) * S], fill=(60, 120, 140, 70))
    save(downsample(img, (w, h)), out, "ground_body.png")

def plat_float(out):
    S = 4; w, h = 128, 56; img = new(w * S, h * S); d = ImageDraw.Draw(img)
    d.rectangle([0, 6 * S, w * S, 40 * S], fill=(66, 60, 104, 255))
    d.rectangle([0, 6 * S, w * S, 14 * S], fill=(136, 126, 188, 255))
    d.rectangle([0, 30 * S, w * S, 40 * S], fill=(44, 38, 74, 255))
    d.rectangle([0, 6 * S, w * S, 8 * S], fill=(130, 240, 250, 255))
    for x in (16, 48, 80, 112): d.ellipse([(x - 3) * S, 20 * S, (x + 3) * S, 26 * S], fill=(30, 26, 54, 255))
    d.rectangle([0, 40 * S, w * S, 44 * S], fill=(90, 230, 250, 255))
    img = downsample(img, (w, h)); g = new(w, h); ImageDraw.Draw(g).rectangle([0, 40, w, 46], fill=(90, 230, 250, 200))
    save(Image.alpha_composite(blur(g, 3.2), img), out, "plat_float.png")

def plat_move(out):
    S = 4; w, h = 160, 56; img = new(w * S, h * S); d = ImageDraw.Draw(img)
    d.rounded_rectangle([4 * S, 6 * S, (w - 4) * S, 40 * S], radius=6 * S, fill=(70, 60, 98, 255))
    d.rectangle([4 * S, 6 * S, (w - 4) * S, 14 * S], fill=(150, 130, 186, 255))
    for i in range(10):
        x = 10 + i * 14
        d.polygon([(x * S, 26 * S), ((x + 8) * S, 26 * S), ((x + 14) * S, 36 * S), ((x + 6) * S, 36 * S)], fill=(255, 190, 40, 255))
    d.rectangle([4 * S, 6 * S, (w - 4) * S, 8 * S], fill=(255, 210, 90, 255))
    for cx in (34, 126):
        d.ellipse([(cx - 11) * S, 38 * S, (cx + 11) * S, 52 * S], fill=(255, 150, 60, 255))
    img = downsample(img, (w, h)); g = new(w, h); gd = ImageDraw.Draw(g)
    for cx in (34, 126): gd.ellipse([cx - 14, 38, cx + 14, 56], fill=(255, 160, 60, 200))
    save(Image.alpha_composite(blur(g, 4), img), out, "plat_move.png")

def spikes(out):
    S = 4; w, h = 64, 44; img = new(w * S, h * S); d = ImageDraw.Draw(img)
    d.rectangle([0, 36 * S, w * S, h * S], fill=(40, 34, 66, 255))
    for i in range(4):
        x = i * 16
        d.polygon([((x + 1) * S, 38 * S), ((x + 8) * S, 2 * S), ((x + 15) * S, 38 * S)], fill=(186, 192, 220, 255), outline=(20, 16, 36, 255), width=2 * S)
        d.polygon([((x + 8) * S, 2 * S), ((x + 15) * S, 38 * S), ((x + 9) * S, 38 * S)], fill=(120, 126, 160, 255))
        d.polygon([((x + 6.2) * S, 12 * S), ((x + 8) * S, 2 * S), ((x + 9.8) * S, 12 * S)], fill=(255, 80, 70, 255))
    save(downsample(img, (w, h)), out, "spikes.png")

def saw(out):
    S = 3; n = 120; img = new(n * S, n * S); d = ImageDraw.Draw(img); c = n * S / 2
    pts = []
    for i in range(24):
        a0 = i * 2 * math.pi / 24
        for da, rr in ((0, 40), (0.45, 58), (0.85, 40)):
            a = a0 + da * 2 * math.pi / 24; pts.append((c + math.cos(a) * rr * S, c + math.sin(a) * rr * S))
    d.polygon(pts, fill=(190, 196, 224, 255), outline=(20, 16, 36, 255), width=3 * S)
    d.ellipse([c - 34 * S, c - 34 * S, c + 34 * S, c + 34 * S], fill=(120, 126, 160, 255), outline=(20, 16, 36, 255), width=3 * S)
    for i in range(6):
        a = i * math.pi / 3
        d.ellipse([c + math.cos(a) * 22 * S - 5 * S, c + math.sin(a) * 22 * S - 5 * S, c + math.cos(a) * 22 * S + 5 * S, c + math.sin(a) * 22 * S + 5 * S], fill=(30, 26, 52, 255))
    d.ellipse([c - 10 * S, c - 10 * S, c + 10 * S, c + 10 * S], fill=(255, 90, 70, 255), outline=(20, 16, 36, 255), width=2 * S)
    save(downsample(img, (n, n)), out, "saw.png")

def crystal(out, name, base, light, dark):
    S = 4; w, h = 64, 84; img = new(w * S, h * S); d = ImageDraw.Draw(img)
    P = lambda pts: [(x * S, y * S) for x, y in pts]
    out_pts = [(32, 3), (52, 24), (46, 72), (32, 82), (18, 72), (12, 24)]
    d.polygon(P(out_pts), fill=(14, 12, 34, 255)); 
    d.polygon(P([(32, 7), (49, 25), (44, 69), (32, 78), (20, 69), (15, 25)]), fill=base + (255,))
    d.polygon(P([(32, 7), (49, 25), (32, 34)]), fill=light + (255,)); d.polygon(P([(32, 7), (15, 25), (32, 34)]), fill=shade(light, 0.8) + (255,))
    d.polygon(P([(49, 25), (44, 69), (32, 78), (32, 34)]), fill=dark + (255,)); d.polygon(P([(15, 25), (20, 69), (32, 78), (32, 34)]), fill=shade(base, 0.9) + (255,))
    d.polygon(P([(24, 30), (29, 28), (27, 54), (23, 50)]), fill=(255, 255, 255, 200))
    save(downsample(img, (w, h)), out, name)

def heart(out):
    S = 4; n = 64; img = new(n * S, n * S); d = ImageDraw.Draw(img); c = n * S / 2
    d.ellipse([4 * S, 4 * S, 60 * S, 60 * S], fill=(14, 40, 30, 255)); d.ellipse([7 * S, 7 * S, 57 * S, 57 * S], fill=(40, 200, 130, 255))
    d.ellipse([10 * S, 10 * S, 54 * S, 50 * S], fill=(90, 240, 170, 255))
    d.rectangle([27 * S, 16 * S, 37 * S, 48 * S], fill=(255, 255, 255, 255)); d.rectangle([16 * S, 27 * S, 48 * S, 37 * S], fill=(255, 255, 255, 255))
    d.ellipse([14 * S, 10 * S, 30 * S, 22 * S], fill=(255, 255, 255, 110))
    save(downsample(img, (n, n)), out, "heart.png")

def beacon(out):
    for name, on in (("beacon_off.png", False), ("beacon_on.png", True)):
        S = 4; w, h = 72, 170; img = new(w * S, h * S); d = ImageDraw.Draw(img)
        d.polygon([(26 * S, h * S), (46 * S, h * S), (42 * S, 60 * S), (30 * S, 60 * S)], fill=(52, 46, 84, 255), outline=(14, 12, 34, 255), width=3 * S)
        d.rectangle([14 * S, (h - 14) * S, 58 * S, h * S], fill=(40, 34, 70, 255), outline=(14, 12, 34, 255), width=3 * S)
        d.ellipse([16 * S, 22 * S, 56 * S, 62 * S], fill=((70, 240, 255, 255) if on else (70, 70, 100, 255)), outline=(14, 12, 34, 255), width=3 * S)
        if on:
            d.ellipse([26 * S, 28 * S, 40 * S, 42 * S], fill=(255, 255, 255, 255))
            d.polygon([(36 * S, 4 * S), (50 * S, 30 * S), (22 * S, 30 * S)], fill=(255, 150, 60, 230))
        else:
            d.polygon([(36 * S, 12 * S), (46 * S, 30 * S), (26 * S, 30 * S)], fill=(80, 80, 110, 255))
        img = downsample(img, (w, h))
        if on:
            g = new(w, h); ImageDraw.Draw(g).ellipse([6, 12, 66, 72], fill=(70, 240, 255, 180)); img = Image.alpha_composite(blur(g, 8), img)
        save(img, out, name)

def lamp(out):
    S = 4; w, h = 96, 230; img = new(w * S, h * S); d = ImageDraw.Draw(img)
    d.polygon([(42 * S, h * S), (54 * S, h * S), (51 * S, 40 * S), (45 * S, 40 * S)], fill=(40, 34, 64, 255), outline=(12, 10, 28, 255), width=2 * S)
    d.rectangle([34 * S, (h - 12) * S, 62 * S, h * S], fill=(40, 34, 64, 255), outline=(12, 10, 28, 255), width=2 * S)
    d.arc([48 * S, 14 * S, 90 * S, 54 * S], 180, 300, fill=(40, 34, 64, 255), width=5 * S)
    d.rounded_rectangle([34 * S, 20 * S, 64 * S, 40 * S], radius=6 * S, fill=(255, 214, 130, 255), outline=(12, 10, 28, 255), width=3 * S)
    img = downsample(img, (w, h)); g = new(w, h); ImageDraw.Draw(g).ellipse([14, 4, 84, 58], fill=(255, 190, 90, 200)); save(Image.alpha_composite(blur(g, 8), img), out, "lamp.png")

def pillar(out):
    S = 3; w, h = 140, 300; img = new(w * S, h * S); d = ImageDraw.Draw(img); rng = random.Random(2)
    pts = [(24, h), (24, 70), (36, 52), (52, 66), (66, 34), (84, 58), (100, 46), (116, h * 0 + 74), (116, h)]
    d.polygon([(x * S, y * S) for x, y in pts], fill=(58, 50, 90, 255), outline=(14, 10, 30, 255), width=3 * S)
    d.polygon([(70 * S, 36 * S), (116 * S, 74 * S), (116 * S, h * S), (70 * S, h * S)], fill=(40, 34, 66, 255))
    for y in range(110, h, 46): d.rectangle([24 * S, y * S, 116 * S, (y + 8) * S], fill=(78, 68, 114, 255))
    for _ in range(5):
        x = rng.uniform(30, 110); y = rng.uniform(90, 280); d.line([(x * S, y * S), ((x + rng.uniform(-8, 8)) * S, (y + 24) * S)], fill=(24, 18, 44, 255), width=2 * S)
    d.rectangle([14 * S, (h - 20) * S, 126 * S, h * S], fill=(48, 40, 78, 255), outline=(14, 10, 30, 255), width=3 * S)
    d.line([(30 * S, 72 * S), (22 * S, 20 * S)], fill=(150, 90, 70, 255), width=3 * S); d.line([(40 * S, 56 * S), (46 * S, 10 * S)], fill=(150, 90, 70, 255), width=3 * S)
    save(downsample(img, (w, h)), out, "pillar.png")

def crate(out):
    S = 4; n = 100; img = new(n * S, n * S); d = ImageDraw.Draw(img)
    d.rectangle([4 * S, 4 * S, 96 * S, 96 * S], fill=(96, 70, 80, 255), outline=(14, 10, 30, 255), width=3 * S)
    for i in range(3): d.rectangle([12 * S, (14 + i * 28) * S, 88 * S, (28 + i * 28) * S], fill=(120, 90, 100, 255))
    d.line([(8 * S, 8 * S), (92 * S, 92 * S)], fill=(60, 44, 56, 255), width=5 * S); d.line([(92 * S, 8 * S), (8 * S, 92 * S)], fill=(60, 44, 56, 255), width=5 * S)
    d.rectangle([40 * S, 40 * S, 60 * S, 60 * S], fill=(90, 230, 250, 255), outline=(14, 10, 30, 255), width=2 * S)
    save(downsample(img, (n, n)), out, "crate.png")

def portal(out):
    S = 2; n = 256; img = new(n * S, n * S); d = ImageDraw.Draw(img); c = n * S / 2
    for i, (r, col, wd) in enumerate([(120, (255, 90, 220), 10), (96, (150, 110, 255), 8), (72, (90, 230, 250), 6), (46, (230, 250, 255), 5)]):
        pts = []
        for j in range(64):
            a = j * math.pi * 2 / 64; rr = r + 8 * math.sin(a * (3 + i) + i)
            pts.append((c + math.cos(a) * rr * S, c + math.sin(a) * rr * S * 0.98))
        d.line(pts + [pts[0]], fill=col + (255,), width=wd * S, joint="curve")
    d.ellipse([c - 30 * S, c - 30 * S, c + 30 * S, c + 30 * S], fill=(255, 255, 255, 255))
    img = downsample(img, (n, n)); save(Image.alpha_composite(blur(img, 6), img), out, "portal.png")

def misc(out):
    save(radial(128, (255, 255, 255), 2.2), out, "glow.png")
    save(radial(256, (255, 255, 255), 1.6), out, "light.png")
    save(radial(32, (255, 255, 255), 1.2), out, "particle.png")

def logo(out):
    f1 = ImageFont.truetype(FONT, 230); f2 = ImageFont.truetype(FONT, 150); f3 = ImageFont.truetype(FONT, 34)
    w, h = 1000, 380; S = 1; img = new(w, h); d = ImageDraw.Draw(img)
    def grad_text(txt, font, pos, c0, c1, ow=8):
        tl = new(w, h); td = ImageDraw.Draw(tl); td.text(pos, txt, font=font, fill=(255, 255, 255, 255), stroke_width=ow, stroke_fill=(14, 8, 34, 255))
        mask = new(w, h); ImageDraw.Draw(mask).text(pos, txt, font=font, fill=(255, 255, 255, 255))
        g = vgrad(w, h, [(0, c0), (0.55, c1), (1, shade(c1, 0.7))])
        g.putalpha(mask.split()[3]); return tl, g
    tl, g = grad_text("SHADOW", f1, (20, 0), (240, 255, 255), (70, 220, 255))
    gl = new(w, h); ImageDraw.Draw(gl).text((20, 0), "SHADOW", font=f1, fill=(70, 220, 255, 255), stroke_width=14, stroke_fill=(70, 220, 255, 255))
    img = Image.alpha_composite(img, blur(gl, 12)); img = Image.alpha_composite(img, tl); img = Image.alpha_composite(img, g)
    tl2, g2 = grad_text("RUNNER", f2, (230, 210), (255, 236, 150), (255, 120, 40))
    gl2 = new(w, h); ImageDraw.Draw(gl2).text((230, 210), "RUNNER", font=f2, fill=(255, 120, 40, 255), stroke_width=12, stroke_fill=(255, 120, 40, 255))
    img = Image.alpha_composite(img, blur(gl2, 10)); img = Image.alpha_composite(img, tl2); img = Image.alpha_composite(img, g2)
    d = ImageDraw.Draw(img)
    d.polygon([(10, 360), (980, 340), (990, 346), (14, 368)], fill=(255, 255, 255, 230))
    d.polygon([(10, 360), (120, 352), (14, 368)], fill=(70, 220, 255, 255))
    save(img, out, "logo.png")

def app_icon(out, portrait_path):
    n = 256; img = vgrad(n, n, [(0, (30, 14, 70)), (1, (210, 80, 120))]); d = ImageDraw.Draw(img)
    d.ellipse([130, 30, 230, 130], fill=(250, 226, 240, 255))
    por = Image.open(portrait_path).convert("RGBA"); r = por.crop((0, 0, por.width, int(por.height * 0.5)))
    r = r.resize((int(n * 0.9), int(n * 0.9 * r.height / r.width)), Image.LANCZOS)
    img = img.convert("RGBA"); img.alpha_composite(r, (int(n * 0.05), n - r.height + 10 if n - r.height + 10 > 0 else 0))
    save(img, out, "icon.png")

def run(root):
    A = os.path.join(root, "assets")
    bgd, env, eff, ui = [os.path.join(A, p) for p in ("backgrounds", "environments", "effects", "ui")]
    bg_sky(bgd); bg_far(bgd); bg_mid(bgd); bg_near(bgd); fog(bgd); vignette(ui)
    ground_top(env); ground_body(env); plat_float(env); plat_move(env); spikes(env); saw(env)
    crystal(env, "crystal.png", (50, 210, 240), (190, 250, 255), (30, 120, 190)); crystal(env, "crystal_gold.png", (255, 190, 50), (255, 240, 170), (200, 110, 30))
    heart(env); beacon(env); lamp(env); pillar(env); crate(env); portal(env); misc(eff)
    logo(ui); app_icon(os.path.join(root), os.path.join(A, "characters", "hero_portrait.png"))

if __name__ == "__main__":
    run(sys.argv[1])
    print("env done")
