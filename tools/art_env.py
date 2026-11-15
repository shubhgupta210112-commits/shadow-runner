"""Tiles, decor, parallax backgrounds, UI icons, logo and light textures."""
import math
import random
from pxlib import *

P = PAL
TS = 16


# ================================================================ TILES
def _speckle(px, rng, base, cols, density):
    for y in range(TS):
        for x in range(TS):
            px[x, y] = base
            if rng.random() < density:
                px[x, y] = rng.choice(cols)


def make_tile(theme, kind, var):
    rng = random.Random(hash((theme, kind, var)) & 0xffff)
    im = Image.new('RGBA', (TS, TS), (0, 0, 0, 0))
    px = im.load()
    if theme == 0:  # forest earth
        _speckle(px, rng, P['dirt1'], [P['dirt0'], P['dirt2'], P['dirt2']], 0.28)
        for _ in range(2 + var):
            x, y = rng.randrange(1, 14), rng.randrange(4, 14)
            px[x, y] = P['dirt3']
            px[x + 1, y] = P['dirt2']
        # roots
        if var == 1:
            for i in range(5):
                px[3 + i, 8 + (i % 2)] = P['dirt0']
        if kind in ('top', 'tl', 'tr'):
            for x in range(TS):
                depth = 4 + (1 if rng.random() < 0.5 else 0) + (1 if (x + var) % 5 == 0 else 0)
                for y in range(depth):
                    px[x, y] = P['grass1'] if y > 0 else P['grass2']
                    if y == 0 and rng.random() < 0.4:
                        px[x, y] = P['grass3']
                    if y >= depth - 1:
                        px[x, y] = P['grass0']
                # a darker band under grass
                px[x, depth] = P['dirt0']
    else:  # ancient stone
        for y in range(TS):
            for x in range(TS):
                row = y // 8
                off = 8 if row else 0
                bx = (x + off) % 16
                c = P['stone1']
                if rng.random() < 0.18:
                    c = P['stone2'] if rng.random() < 0.5 else P['stone0']
                if y % 8 == 7 or bx == 15:
                    c = P['stone0']
                elif y % 8 == 0:
                    c = P['stone2']
                px[x, y] = c
        if var == 2:
            for x in range(3, 9):
                px[x, 4] = P['grass1']
        if kind in ('top', 'tl', 'tr'):
            for x in range(TS):
                px[x, 0] = P['stone3']
                if rng.random() < 0.45:
                    px[x, 1] = P['grass2']
                    px[x, 0] = P['grass1']
                if rng.random() < 0.15:
                    px[x, 2] = P['grass0']
    # shape cuts
    def clear(x, y):
        px[x, y] = (0, 0, 0, 0)
    if kind == 'tl':
        for (x, y) in ((0, 0), (1, 0), (0, 1)):
            clear(x, y)
        for y in range(2, TS):
            px[0, y] = shade(px[0, y], -0.35)
    if kind == 'tr':
        for (x, y) in ((15, 0), (14, 0), (15, 1)):
            clear(x, y)
        for y in range(2, TS):
            px[15, y] = shade(px[15, y], -0.35)
    if kind == 'l':
        for y in range(TS):
            px[0, y] = shade(px[0, y], -0.4)
            px[1, y] = shade(px[1, y], -0.15)
    if kind == 'r':
        for y in range(TS):
            px[15, y] = shade(px[15, y], -0.4)
            px[14, y] = shade(px[14, y], -0.15)
    if kind == 'bot':
        for x in range(TS):
            px[x, 15] = shade(px[x, 15], -0.45)
            px[x, 14] = shade(px[x, 14], -0.2)
            if rng.random() < 0.35:
                clear(x, 15)
    return im


def tile_atlas():
    kinds = [('top', 0), ('top', 1), ('top', 2), ('tl', 0), ('tr', 0),
             ('mid', 0), ('mid', 1), ('mid', 2), ('l', 0), ('r', 0), ('bot', 0)]
    out = Image.new('RGBA', (TS * len(kinds), TS * 2), (0, 0, 0, 0))
    for theme in range(2):
        for i, (k, v) in enumerate(kinds):
            out.alpha_composite(make_tile(theme, k, v), (i * TS, theme * TS))
    return out


# ================================================================ DECOR
def _blades(d, x0, base_y, n, hmax, rng, cols):
    for i in range(n):
        x = x0 + i * 2 + rng.randrange(0, 2)
        h = rng.randrange(max(2, hmax // 2), hmax + 1)
        lean = rng.choice((-1, 0, 1))
        d.line([(x, base_y), (x + lean, base_y - h)], fill=rng.choice(cols))


def decor_set():
    rng = random.Random(7)
    D = {}
    g = [P['grass1'], P['grass2'], P['grass3']]

    for name, (w, h, n, hm) in {'grass_a': (10, 7, 4, 6), 'grass_b': (14, 9, 6, 8), 'grass_c': (8, 5, 3, 4)}.items():
        im, d = new(w, h)
        _blades(d, 1, h - 1, n, hm, rng, g)
        D[name] = im

    im, d = new(10, 14)
    d.line([(5, 13), (5, 5)], fill=P['grass1'])
    d.line([(5, 10), (8, 8)], fill=P['grass1'])
    d.ellipse([3, 1, 7, 5], fill=P['cyan'])
    d.point((5, 3), fill=P['white'])
    D['flower'] = auto_outline(im)

    im, d = new(10, 10)
    d.rectangle([4, 5, 5, 9], fill=P['night4'])
    d.pieslice([0, 0, 9, 8], 180, 360, fill=P['teal'])
    d.point((3, 3), fill=P['cyan'])
    d.point((6, 2), fill=P['cyan'])
    D['mush_s'] = finish_(im)

    im, d = new(18, 16)
    d.rectangle([7, 8, 10, 15], fill=P['night4'])
    d.pieslice([0, 0, 17, 14], 180, 360, fill=P['mag1'])
    for (x, y) in ((4, 4), (9, 2), (13, 5), (7, 6)):
        d.rectangle([x, y, x + 1, y], fill=P['mag3'])
    D['mush_l'] = finish_(im)

    im, d = new(16, 12)
    for a in (-60, -30, 0, 30, 60):
        r = math.radians(a)
        d.line([(8, 11), (8 + math.sin(r) * 9, 11 - math.cos(r) * 9)], fill=P['grass1'], width=2)
        d.line([(8, 11), (8 + math.sin(r) * 9, 10 - math.cos(r) * 9)], fill=P['grass2'], width=1)
    D['fern'] = auto_outline(im)

    im, d = new(12, 8)
    d.ellipse([0, 1, 11, 8], fill=P['stone1'])
    d.ellipse([2, 1, 8, 4], fill=P['stone2'])
    D['rock'] = finish_(im)

    im, d = new(10, 30)
    d.line([(5, 0), (4, 12), (6, 22), (5, 29)], fill=P['grass0'], width=2)
    for (x, y) in ((3, 8), (7, 14), (3, 20), (7, 26)):
        d.ellipse([x - 2, y - 1, x + 2, y + 2], fill=P['grass1'])
    D['vine'] = auto_outline(im)

    im, d = new(8, 20)
    d.line([(4, 0), (3, 8), (5, 14), (3, 19)], fill=P['dirt2'], width=2)
    D['root'] = auto_outline(im)

    im, d = new(12, 16)
    d.polygon([(6, 0), (10, 8), (6, 15), (2, 8)], fill=P['cyan_d'])
    d.polygon([(6, 0), (10, 8), (6, 8)], fill=P['cyan'])
    d.polygon([(1, 15), (3, 9), (5, 15)], fill=P['teal'])
    D['crystal'] = finish_(im)

    im, d = new(30, 16)
    d.ellipse([0, 6, 15, 15], fill=P['grass0'])
    d.ellipse([8, 2, 24, 15], fill=P['grass1'])
    d.ellipse([16, 6, 29, 15], fill=P['grass0'])
    for _ in range(14):
        d.point((rng.randrange(3, 27), rng.randrange(3, 12)), fill=P['grass2'])
    for (x, y) in ((6, 8), (20, 6), (14, 4)):
        d.point((x, y), fill=P['mag3'])
    D['bush'] = auto_outline(im)

    im, d = new(14, 48)
    d.rectangle([6, 14, 7, 47], fill=P['stone1'])
    d.rectangle([4, 44, 9, 47], fill=P['stone0'])
    d.rectangle([2, 8, 11, 14], fill=P['stone2'])
    d.rectangle([4, 9, 9, 13], fill=P['gold2'])
    d.rectangle([5, 10, 8, 12], fill=P['gold3'])
    d.polygon([(2, 8), (11, 8), (7, 3)], fill=P['stone1'])
    D['lantern'] = finish_(im)

    im, d = new(18, 24)
    d.rectangle([8, 12, 10, 23], fill=P['dirt2'])
    d.rectangle([1, 2, 16, 12], fill=P['dirt3'])
    d.rectangle([1, 2, 16, 3], fill=P['gold0'])
    d.polygon([(4, 7), (11, 7), (11, 5), (14, 8), (11, 11), (11, 9), (4, 9)], fill=P['gold2'])
    D['sign'] = finish_(im)

    im, d = new(20, 64)
    d.rectangle([3, 10, 16, 63], fill=P['stone1'])
    d.rectangle([3, 10, 6, 63], fill=P['stone2'])
    d.rectangle([14, 10, 16, 63], fill=P['stone0'])
    d.polygon([(3, 10), (16, 10), (14, 4), (10, 7), (7, 2), (5, 6)], fill=P['stone1'])
    for y in range(18, 60, 10):
        d.line([(5, y), (14, y + 1)], fill=P['stone0'])
    d.rectangle([2, 58, 17, 63], fill=P['stone0'])
    for (x, y) in ((4, 14), (6, 30), (12, 44)):
        d.rectangle([x, y, x + 2, y + 1], fill=P['grass1'])
        d.point((x + 1, y + 2), fill=P['grass0'])
    d.rectangle([9, 24, 10, 27], fill=P['cyan_d'])
    D['pillar'] = finish_(im)

    D['tree_a'] = tree_sprite(56, 190, 11, 1)
    D['tree_b'] = tree_sprite(44, 150, 12, 2)
    return D


def finish_(im):
    return auto_outline(rimlight(im, 0.25, 0.3))


def tree_sprite(w, h, seed, kind):
    rng = random.Random(seed)
    im, d = new(w, h)
    cx = w // 2
    tw = 10 if kind == 1 else 8
    # trunk with flared base
    d.polygon([(cx - tw // 2, h - 1), (cx - tw // 2 + 1, h * 0.35), (cx + tw // 2 - 1, h * 0.35), (cx + tw // 2, h - 1)],
              fill=P['dirt0'])
    d.polygon([(cx - tw // 2 - 8, h - 1), (cx - tw // 2 + 1, h - 22), (cx + tw // 2 - 1, h - 22), (cx + tw // 2 + 8, h - 1)],
              fill=P['dirt0'])
    d.line([(cx - 2, h - 2), (cx - 2, h * 0.4)], fill=P['dirt1'], width=1)
    # branches
    for i in range(5):
        by = h * 0.3 + i * h * 0.1
        s = -1 if i % 2 else 1
        d.line([(cx, by), (cx + s * rng.randrange(10, w // 2 - 2), by - rng.randrange(8, 20))], fill=P['dirt0'], width=3)
    # canopy blobs
    for _ in range(14):
        bx = cx + rng.randrange(-w // 2 + 8, w // 2 - 8)
        by = rng.randrange(6, int(h * 0.38))
        r = rng.randrange(7, 13)
        col = rng.choice([P['grass0'], P['grass0'], P['grass1']])
        d.ellipse([bx - r, by - r // 2, bx + r, by + r // 2 + 2], fill=col)
    for _ in range(26):
        bx = cx + rng.randrange(-w // 2 + 6, w // 2 - 6)
        by = rng.randrange(8, int(h * 0.38))
        d.point((bx, by), fill=P['grass2'])
    for _ in range(5):
        d.point((cx + rng.randrange(-w // 2 + 8, w // 2 - 8), rng.randrange(int(h * 0.1), int(h * 0.4))), fill=P['cyan'])
    return auto_outline(rimlight(im, 0.15, 0.2))


# ================================================================ BACKGROUNDS
def lerp_arr(a, b, t):
    return a + (b - a) * t


def bg_sky(W=640, H=360):
    a = np.zeros((H, W, 4), np.uint8)
    top = np.array(PAL['void'][:3], float)
    mid = np.array(PAL['night1'][:3], float)
    low = np.array([70, 52, 120], float)
    hor = np.array([44, 120, 140], float)
    for y in range(H):
        t = y / (H - 1)
        if t < 0.55:
            c = lerp_arr(top, mid, t / 0.55)
        elif t < 0.85:
            c = lerp_arr(mid, low, (t - 0.55) / 0.3)
        else:
            c = lerp_arr(low, hor, (t - 0.85) / 0.15)
        a[y, :, :3] = c
        a[y, :, 3] = 255
    im = Image.fromarray(a, 'RGBA')
    d = ImageDraw.Draw(im)
    rng = random.Random(3)
    for _ in range(170):
        x, y = rng.randrange(W), rng.randrange(int(H * 0.7))
        b = rng.random()
        c = (234, 244, 255, 255) if b > 0.85 else (138, 121, 201, 255)
        d.point((x, y), fill=c)
        if b > 0.96:
            d.point((x + 1, y), fill=c)
            d.point((x, y + 1), fill=c)
    # dither bands for painterly sky
    arr = np.array(im)
    for y in range(0, H, 1):
        if y % 24 in (0, 1) and y > 40:
            arr[y, ::2, :3] = np.clip(arr[y, ::2, :3].astype(int) + 6, 0, 255)
    im = Image.fromarray(arr, 'RGBA')
    d = ImageDraw.Draw(im)
    # moon with halo
    mx, my, mr = 470, 90, 34
    halo = glow_blob(220, (140, 200, 255), 2.2, 120)
    im.alpha_composite(halo, (mx - 110, my - 110))
    d.ellipse([mx - mr, my - mr, mx + mr, my + mr], fill=PAL['moon'])
    d.ellipse([mx - mr + 7, my - mr + 4, mx + mr + 7, my + mr + 4], fill=(30, 26, 70, 255))  # crescent cut
    # redraw crescent properly: lit part only
    cres = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cres)
    cd.ellipse([mx - mr, my - mr, mx + mr, my + mr], fill=PAL['moon'])
    cd.ellipse([mx - mr + 14, my - mr - 4, mx + mr + 14, my + mr - 4], fill=(0, 0, 0, 0))
    base = np.array(im)
    # cheap approach: re-render halo + crescent on clean sky copy
    im2 = Image.fromarray(np.array(Image.fromarray(a, 'RGBA')), 'RGBA')
    d2 = ImageDraw.Draw(im2)
    rng = random.Random(3)
    for _ in range(170):
        x, y = rng.randrange(W), rng.randrange(int(H * 0.7))
        b = rng.random()
        c = (234, 244, 255, 255) if b > 0.85 else (138, 121, 201, 255)
        d2.point((x, y), fill=c)
        if b > 0.96:
            d2.point((x + 1, y), fill=c)
            d2.point((x, y + 1), fill=c)
    im2.alpha_composite(halo, (mx - 110, my - 110))
    # crescent as mask difference
    m = Image.new('L', (W, H), 0)
    md = ImageDraw.Draw(m)
    md.ellipse([mx - mr, my - mr, mx + mr, my + mr], fill=255)
    md.ellipse([mx - mr + 13, my - mr - 3, mx + mr + 13, my + mr - 3], fill=0)
    moon = Image.new('RGBA', (W, H), PAL['moon'])
    im2.paste(moon, (0, 0), m)
    return im2


def bg_mountains(W=1280, H=360, seed=1, top=170, amp=70, col=(34, 28, 69), rim=(90, 75, 150), cyc=2):
    prof = periodic_noise(W, H, cyc, seed, 4, 0.55)
    a = np.zeros((H, W, 4), np.uint8)
    for x in range(W):
        y0 = int(top + (1 - prof[x]) * amp)
        for y in range(y0, H):
            t = (y - y0) / max(1, H - y0)
            c = np.array(col) * (1 - 0.35 * t) + np.array([20, 70, 100]) * 0.35 * (t ** 2)
            a[y, x, :3] = c
            a[y, x, 3] = 255
        a[y0, x, :3] = rim
        a[y0, x, 3] = 255
        if y0 + 1 < H:
            a[y0 + 1, x, :3] = (np.array(rim) * 0.6 + np.array(col) * 0.4)
    # dither-fade bottom to transparent
    for y in range(H - 70, H):
        t = (y - (H - 70)) / 70
        mask = (np.indices((1, W))[1][0] + y) % 2 == 0
        thresh = int(t * 4)
        a[y, :, 3] = np.where((np.arange(W) + y * 3) % 4 < (4 - thresh), 255, 0)
    return Image.fromarray(a, 'RGBA')


def pine(d, x, base_y, h, w, col, rim):
    tiers = max(3, h // 14)
    for i in range(tiers):
        ty = base_y - h + i * (h // tiers) * 0.8
        tw = w * (0.35 + 0.65 * (i + 1) / tiers)
        bot = ty + (h / tiers) * 1.6
        d.polygon([(x, ty), (x - tw / 2, bot), (x + tw / 2, bot)], fill=col)
        d.line([(x, ty), (x - tw / 2, bot)], fill=rim)
    d.rectangle([x - 1, base_y - 6, x + 1, base_y], fill=col)


def bg_forest(W=1280, H=360, seed=5, base=330, hmin=60, hmax=130, col=(18, 17, 42), rim=(58, 47, 107), count=34, glow=True):
    im, d = new(W, H)
    rng = random.Random(seed)
    # ground hill silhouette
    prof = periodic_noise(W, H, 3, seed + 9, 3, 0.5)
    for x in range(W):
        y0 = int(base - 14 * prof[x])
        d.line([(x, y0), (x, H)], fill=col + (255,))
    for _ in range(count):
        x = rng.randrange(W)
        h = rng.randrange(hmin, hmax)
        w = int(h * 0.5)
        yb = base - int(14 * prof[x % W]) + 4
        for off in (-W, 0, W):
            pine(d, x + off, yb, h, w, col + (255,), rim + (255,))
    # glowing window ruins
    if glow:
        for _ in range(4):
            x = rng.randrange(60, W - 60)
            h = rng.randrange(50, 90)
            yb = base - int(14 * prof[x % W]) + 4
            d.rectangle([x - 7, yb - h, x + 7, yb], fill=col + (255,))
            d.polygon([(x - 9, yb - h), (x + 9, yb - h), (x, yb - h - 10)], fill=col + (255,))
            d.rectangle([x - 2, yb - h + 12, x + 1, yb - h + 18], fill=(255, 209, 102, 255))
    return im


def bg_near(W=1280, H=360, seed=8):
    im, d = new(W, H)
    rng = random.Random(seed)
    col = (13, 12, 30, 255)
    rim = (42, 34, 82, 255)
    for i in range(7):
        x = int((i + 0.5) * W / 7 + rng.randrange(-30, 30))
        w = rng.randrange(14, 26)
        for off in (-W, 0, W):
            xx = x + off
            d.polygon([(xx - w // 2 - 6, H), (xx - w // 2 + 2, 120), (xx + w // 2 - 2, 120), (xx + w // 2 + 6, H)], fill=col)
            d.line([(xx - w // 2 + 2, 120), (xx - w // 2 - 6, H)], fill=rim)
            for _ in range(4):
                by = rng.randrange(120, 260)
                s = rng.choice((-1, 1))
                d.line([(xx, by), (xx + s * rng.randrange(20, 40), by - rng.randrange(10, 30))], fill=col, width=4)
            for _ in range(9):
                bx, by = xx + rng.randrange(-34, 34), rng.randrange(70, 150)
                r = rng.randrange(8, 15)
                d.ellipse([bx - r, by - r // 2, bx + r, by + r // 2], fill=col)
    # glow mushrooms/crystals at feet
    for _ in range(26):
        x = rng.randrange(W)
        y = H - rng.randrange(0, 20)
        c = rng.choice([(47, 191, 174, 255), (165, 47, 181, 255), (127, 247, 255, 255)])
        for off in (-W, 0, W):
            d.rectangle([x + off, y - 2, x + off + 1, y], fill=c)
    return im


def bg_fog(W=1280, H=360):
    a = np.zeros((H, W, 4), np.uint8)
    prof = periodic_noise(W, H, 6, 21, 3, 0.6)
    for x in range(W):
        for y in range(H - 120, H):
            t = (y - (H - 120)) / 120
            a[y, x, :3] = (110, 130, 190)
            a[y, x, 3] = int(70 * (t ** 1.5) * (0.5 + prof[x]))
    return Image.fromarray(a, 'RGBA')


# ================================================================ UI
def ui_icons():
    from art_entities import heart_pick, coin, shard
    out = {}
    h, d = new(16, 16)
    d.ellipse([1, 3, 8, 10], fill=PAL['ember1'])
    d.ellipse([7, 3, 14, 10], fill=PAL['ember1'])
    d.polygon([(1, 8), (14, 8), (8, 15)], fill=PAL['ember1'])
    d.rectangle([3, 4, 4, 5], fill=PAL['ember3'])
    out['heart_full'] = auto_outline(rimlight(h, 0.3, 0.3))
    h, d = new(16, 16)
    d.ellipse([1, 3, 8, 10], fill=PAL['night1'])
    d.ellipse([7, 3, 14, 10], fill=PAL['night1'])
    d.polygon([(1, 8), (14, 8), (8, 15)], fill=PAL['night1'])
    out['heart_empty'] = auto_outline(h)
    out['coin_icon'] = coin(0)
    out['shard_icon'] = shard(0)
    return out


def make_logo(font_path):
    from PIL import ImageFont
    f1 = ImageFont.truetype(font_path, 40)
    f2 = ImageFont.truetype(font_path, 40)
    W, H = 500, 120
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))

    def text_mask(txt, font):
        m = Image.new('L', (W, H), 0)
        md = ImageDraw.Draw(m)
        md.fontmode = '1'
        bb = md.textbbox((0, 0), txt, font=font)
        md.text(((W - (bb[2] - bb[0])) // 2 - bb[0], 0), txt, font=font, fill=255)
        return m

    def paint(mask, y_off, c_top, c_bot):
        arr = np.zeros((H, W, 4), np.uint8)
        mm = np.array(mask) > 0
        ys = np.nonzero(mm.any(axis=1))[0]
        y0, y1 = ys.min(), ys.max()
        for y in range(H):
            t = np.clip((y - y0) / max(1, y1 - y0), 0, 1)
            c = np.array(c_top) * (1 - t) + np.array(c_bot) * t
            arr[y, :, :3] = c
        arr[..., 3] = mm * 255
        layer = Image.fromarray(arr, 'RGBA')
        return layer

    m1 = text_mask('SHADOW', f1)
    m2 = text_mask('RUNNER', f2)
    # shift second line down
    m2 = ImageChops_offset(m2, 0, 52)
    m1 = ImageChops_offset(m1, 0, 6)
    both = np.maximum(np.array(m1), np.array(m2))
    # drop shadow (ember) and outline
    sh = np.zeros((H, W, 4), np.uint8)
    smask = np.roll(np.roll(both, 3, axis=0), 3, axis=1) > 0
    sh[smask] = PAL['ember0']
    im.alpha_composite(Image.fromarray(sh, 'RGBA'))
    l1 = paint(Image.fromarray(np.array(m1)), 0, (234, 244, 255), (127, 247, 255))
    l2 = paint(Image.fromarray(np.array(m2)), 0, (255, 217, 168), (255, 107, 74))
    im.alpha_composite(l1)
    im.alpha_composite(l2)
    im = outline(im, PAL['void'], diag=True)
    return im


def ImageChops_offset(mask, dx, dy):
    a = np.array(mask)
    a = np.roll(a, dy, axis=0)
    a = np.roll(a, dx, axis=1)
    return Image.fromarray(a)


def make_icon():
    from art_player import draw_player
    base = Image.new('RGBA', (128, 128), (11, 10, 26, 255))
    g = glow_blob(128, (127, 247, 255), 2.0, 130)
    base.alpha_composite(g)
    p = draw_player(legs=None)
    p = p.crop((8, 0, 40, 32)).resize((96, 96), Image.NEAREST)
    base.alpha_composite(p, (16, 20))
    return base


def light_tex(size=128, power=1.6):
    a = np.zeros((size, size, 4), np.uint8)
    yy, xx = np.mgrid[0:size, 0:size]
    d = np.sqrt((xx - size / 2 + 0.5) ** 2 + (yy - size / 2 + 0.5) ** 2) / (size / 2)
    v = np.clip(1 - d, 0, 1) ** power
    a[..., :3] = (v[..., None] * 255).astype(np.uint8)
    a[..., 3] = 255
    return Image.fromarray(a, 'RGBA')


def particle_tex(kind):
    if kind == 'dot':
        im, d = new(4, 4)
        d.rectangle([1, 1, 2, 2], fill=(255, 255, 255, 255))
        d.point((0, 1), fill=(255, 255, 255, 120))
        d.point((3, 2), fill=(255, 255, 255, 120))
        d.point((1, 0), fill=(255, 255, 255, 120))
        d.point((2, 3), fill=(255, 255, 255, 120))
        return im
    im, d = new(2, 2, (255, 255, 255, 255))
    return im
