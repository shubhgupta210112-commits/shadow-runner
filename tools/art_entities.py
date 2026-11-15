"""Enemies, boss, pickups, props and projectiles (all original, procedural)."""
import math
from pxlib import *
from art_player import OffsetDraw

P = PAL


def finish(im, hl=0.25, sh=0.3):
    return auto_outline(rimlight(im, hl, sh))


# ------------------------------------------------------------- MOSSLING
def mossling(step=0, squash=0, alert=False, dead=False):
    im, d = new(32, 24)
    bob = 1 if step in (1, 3) else 0
    top = 5 + squash * 4 + bob
    # legs
    for i, lx in enumerate((8, 12, 18, 22)):
        ph = (step + i) % 2
        d.rectangle([lx, 19 - ph, lx + 1, 22], fill=P['dirt0'])
    # shell
    d.ellipse([4, top, 28, 21], fill=P['grass1'])
    d.ellipse([6, top + 1, 26, 19], fill=P['grass0'])
    d.pieslice([4, top, 28, 21], 180, 360, fill=P['grass1'])
    # moss tufts and spots
    for (x, y) in ((9, top + 2), (14, top + 1), (19, top + 2), (23, top + 4)):
        d.rectangle([x, y, x + 2, y + 1], fill=P['grass2'])
        d.point((x + 1, y - 1), fill=P['grass3'])
    for (x, y) in ((12, top + 6), (20, top + 7)):
        d.point((x, y), fill=P['mag2'])
    # face
    d.ellipse([20, top + 5, 28, 19], fill=P['dirt1'])
    ec = P['gold2'] if not alert else P['ember1']
    d.rectangle([23, top + 8, 25, top + 10], fill=ec)
    d.point((24, top + 9), fill=P['white'])
    # horn nub
    d.polygon([(26, top + 4), (30, top + 1), (28, top + 7)], fill=P['stone2'])
    return finish(im)


# ------------------------------------------------------------- GLOOMWISP
def wisp(flap=0, dive=False):
    im, d = new(32, 32)
    cy = 14
    wy = [-5, -1, 3, 0][flap % 4]
    # wings
    for sx in (-1, 1):
        pts = [(16, cy), (16 + sx * 12, cy + wy - 3), (16 + sx * 14, cy + wy + 3), (16 + sx * 6, cy + 4)]
        d.polygon(pts, fill=P['mag1'])
        d.line([(16, cy), (16 + sx * 13, cy + wy)], fill=P['mag3'])
    # body (teardrop)
    d.ellipse([10, cy - 6, 22, cy + 6], fill=P['night2'])
    d.polygon([(11, cy + 3), (21, cy + 3), (16, cy + 16)], fill=P['night1'])
    d.polygon([(14, cy + 10), (18, cy + 10), (16, cy + 20 + (flap % 2) * 2)], fill=P['mag0'])
    # eye
    d.ellipse([12, cy - 3, 20, cy + 3], fill=P['void'])
    d.ellipse([14, cy - 2, 18, cy + 2], fill=P['ember1'] if dive else P['mag3'])
    d.point((16, cy), fill=P['white'])
    # ears
    d.polygon([(11, cy - 4), (9, cy - 10), (14, cy - 6)], fill=P['night2'])
    d.polygon([(21, cy - 4), (23, cy - 10), (18, cy - 6)], fill=P['night2'])
    return finish(im)


# ------------------------------------------------------------- SPORECAP
def sporecap(frame=0, shoot=-1):
    im, d = new(32, 32)
    squash = 1 if frame == 1 else 0
    if shoot >= 0:
        squash = [2, 0, -1][shoot]
    # stalk
    d.rectangle([12, 18 + squash, 19, 30], fill=P['night4'])
    d.rectangle([12, 18 + squash, 14, 30], fill=P['night3'])
    d.rectangle([11, 29, 20, 31], fill=P['dirt1'])
    # eyes in stalk
    d.rectangle([13, 22 + squash, 14, 24 + squash], fill=P['void'])
    d.rectangle([17, 22 + squash, 18, 24 + squash], fill=P['void'])
    d.point((14, 23 + squash), fill=P['ember2'])
    d.point((18, 23 + squash), fill=P['ember2'])
    # cap
    top = 4 + squash * 2
    d.pieslice([2, top, 29, 26 + squash], 180, 360, fill=P['mag1'])
    d.rectangle([2, top + 11 + squash, 29, top + 13 + squash], fill=P['mag0'])
    for (x, y) in ((8, top + 5), (16, top + 3), (22, top + 7), (12, top + 9)):
        d.ellipse([x, y, x + 3, y + 2], fill=P['mag3'])
    # glowing spore vent
    if shoot >= 1:
        d.ellipse([13, top - 1, 18, top + 3], fill=P['gold2'])
    return finish(im)


# ------------------------------------------------------------- BOSS: GLOOMHORN
def boss(pose='idle', t=0):
    """The Gloomhorn, a spectral stag. 96x80, faces right, feet at bottom."""
    W, H_ = 96, 96
    im, d0 = new(W, H_)
    d = OffsetDraw(d0, 0, 17)
    bob = round(math.sin(t * math.tau) * 1.2)
    crouch = 0
    head_dx, head_dy = 0, 0
    leg_ph = 0.0
    stunned = pose == 'stun'
    if pose == 'windup':
        crouch = 5 + (t > 0.5)
        head_dy = 4
    if pose == 'slam':
        crouch = -4 if t < 0.5 else 6
        head_dy = -3 if t < 0.5 else 5
    if pose == 'stun':
        crouch = 8
        head_dy = 8
        head_dx = 2
    if pose == 'run':
        leg_ph = t * math.tau
        bob = round(abs(math.sin(leg_ph)) * 2)
    body_y = 38 + crouch + bob
    fur = P['night1']
    fur_l = P['night2']
    # back legs / front legs
    def leg(x, phase, front):
        fx = x + 8 * math.sin(phase)
        lift = max(0.0, math.cos(phase)) * 8
        foot_y = 77 - lift
        knee = (x + 3 * (1 if front else -1) + 4 * math.sin(phase), (body_y + 14 + foot_y) / 2)
        col = fur if front else P['night0']
        d.line([(x, body_y + 8), knee, (fx, foot_y)], fill=col, width=7)
        d.rectangle([fx - 3, foot_y - 3, fx + 4, foot_y + 1], fill=P['stone0'])
    if pose == 'run':
        leg(28, leg_ph + math.pi, False)
        leg(62, leg_ph, False)
        leg(36, leg_ph, True)
        leg(70, leg_ph + math.pi, True)
    else:
        sp = 0 if pose not in ('slam',) else 0.6
        leg(28, 0.4 + sp, False)
        leg(62, -0.3, False)
        leg(36, 0.0, True)
        leg(70, 0.2 - sp, True)
    # body + hump
    d.ellipse([16, body_y - 6, 82, body_y + 24], fill=fur)
    d.ellipse([40, body_y - 14, 78, body_y + 6], fill=fur)
    d.ellipse([22, body_y - 3, 70, body_y + 10], fill=fur_l)
    # ribs glow
    for i in range(4):
        x = 34 + i * 7
        d.arc([x, body_y - 2, x + 10, body_y + 20], 280, 80, fill=P['mag2'], width=1)
    # tail wisps
    for i in range(3):
        a = math.sin(t * math.tau + i) * 3
        d.line([(18, body_y + 4), (8 - i * 3, body_y + 10 + a + i * 3), (3 - i * 3, body_y + 18 + i * 4)],
               fill=P['mag1'], width=2)
    # neck
    nx, ny = 76, body_y - 6
    d.polygon([(66, body_y - 12), (80, body_y - 18 + head_dy * 0.3), (88 + head_dx, ny - 10 + head_dy), (78, body_y + 10)], fill=fur)
    # head
    hx, hy = 82 + head_dx, ny - 16 + head_dy
    d.polygon([(hx - 6, hy), (hx + 8, hy - 2), (hx + 16, hy + 10), (hx + 6, hy + 14), (hx - 4, hy + 10)], fill=fur_l)
    d.polygon([(hx + 8, hy + 4), (hx + 15, hy + 9), (hx + 7, hy + 12)], fill=P['night0'])
    d.rectangle([hx + 13, hy + 8, hx + 15, hy + 9], fill=P['mag2'])
    # eye
    ec = P['ember1'] if pose in ('windup', 'slam') else (P['gold2'] if stunned else P['mag3'])
    d.rectangle([hx + 3, hy + 3, hx + 6, hy + 5], fill=ec)
    d.point((hx + 4, hy + 4), fill=P['white'])
    # antlers (branching, glowing tips)
    glow = P['mag3']
    base = (hx, hy)
    for side in (0, 1):
        ox = -2 if side else 3
        pts = [(hx + ox, hy), (hx + ox - 4 + side * -3, hy - 10), (hx + ox - 8 + side * -4, hy - 20)]
        d.line(pts, fill=P['stone3'], width=3)
        for (bx, by, ex, ey) in ((pts[1][0], pts[1][1], pts[1][0] + 9, pts[1][1] - 6),
                                  (pts[2][0], pts[2][1] + 3, pts[2][0] - 8, pts[2][1] - 6),
                                  (pts[2][0], pts[2][1], pts[2][0] + 4, pts[2][1] - 9)):
            d.line([(bx, by), (ex, ey)], fill=P['stone3'], width=2)
            d.rectangle([ex - 1, ey - 1, ex + 1, ey + 1], fill=glow)
    # shock glow when stunned
    if stunned:
        for i in range(4):
            sx = 20 + i * 18
            d.point((sx, body_y - 16 - (i % 2) * 4), fill=P['gold3'])
    im = finish(im, 0.2, 0.3)
    return im


# ------------------------------------------------------------- PICKUPS
def coin(i):
    im, d = new(16, 16)
    w = [6, 5, 3, 1, 3, 5][i % 6]
    cx = 8
    d.ellipse([cx - w, 2, cx + w, 13], fill=P['gold1'])
    if w >= 3:
        d.ellipse([cx - w + 1, 3, cx + w - 1, 12], fill=P['gold2'])
        d.rectangle([cx - 1, 5, cx, 10], fill=P['gold0'])
        d.point((cx - w + 2, 4), fill=P['gold3'])
    return auto_outline(im, None)


def heart_pick(i):
    im, d = new(16, 16)
    oy = [0, -1][i % 2]
    d.ellipse([1, 3 + oy, 8, 10 + oy], fill=P['ember1'])
    d.ellipse([7, 3 + oy, 14, 10 + oy], fill=P['ember1'])
    d.polygon([(1, 8 + oy), (14, 8 + oy), (8, 15 + oy)], fill=P['ember1'])
    d.rectangle([3, 4 + oy, 4, 5 + oy], fill=P['ember3'])
    return finish(im, 0.3, 0.3)


def shard(i):
    im, d = new(16, 16)
    pulse = [0, 1, 0, -1][i % 4]
    d.polygon([(8, 0 + pulse), (13, 7), (8, 15 - pulse), (3, 7)], fill=P['cyan_d'])
    d.polygon([(8, 0 + pulse), (13, 7), (8, 8)], fill=P['cyan'])
    d.polygon([(8, 8), (13, 7), (8, 15 - pulse)], fill=H('1d7f95'))
    d.line([(8, 2), (8, 12)], fill=P['white'], width=1)
    if i % 2 == 0:
        d.point((12, 2), fill=P['white'])
    else:
        d.point((3, 3), fill=P['white'])
    return finish(im, 0.3, 0.25)


def checkpoint(active, i=0):
    im, d = new(24, 40)
    # stone obelisk
    d.polygon([(6, 39), (18, 39), (16, 14), (8, 14)], fill=P['stone1'])
    d.polygon([(8, 14), (16, 14), (12, 6)], fill=P['stone2'])
    d.rectangle([4, 36, 19, 39], fill=P['stone0'])
    d.rectangle([7, 30, 16, 32], fill=P['stone2'])
    # rune slit
    rc = P['cyan'] if active else P['night2']
    d.rectangle([11, 18, 12, 28], fill=rc)
    d.rectangle([9, 22, 14, 23], fill=rc)
    # bowl + flame
    d.rectangle([6, 12, 17, 13], fill=P['stone3'])
    if active:
        fl = [0, 1, 2, 1][i % 4]
        d.polygon([(8, 11), (15, 11), (12, 1 - fl), ], fill=P['ember1'])
        d.polygon([(10, 11), (13, 11), (12, 4 - fl)], fill=P['gold2'])
    im = finish(im, 0.2, 0.3)
    return im


def lever(on):
    im, d = new(16, 16)
    d.rectangle([2, 12, 13, 15], fill=P['stone1'])
    d.rectangle([4, 10, 11, 12], fill=P['stone2'])
    if on:
        d.line([(8, 11), (13, 3)], fill=P['gold1'], width=2)
        d.ellipse([12, 1, 15, 4], fill=P['grass3'])
    else:
        d.line([(8, 11), (3, 3)], fill=P['gold1'], width=2)
        d.ellipse([1, 1, 4, 4], fill=P['ember1'])
    return finish(im)


def gate(i):
    """Crystal barrier 16x64."""
    im, d = new(16, 64)
    for k in range(4):
        y = k * 16
        d.polygon([(8, y), (14, y + 8), (8, y + 16), (2, y + 8)], fill=P['mag1'])
        d.polygon([(8, y), (14, y + 8), (8, y + 8)], fill=P['mag2'])
        d.line([(8, y + 2), (8, y + 13)], fill=P['mag3'] if (i + k) % 2 == 0 else P['mag2'])
    return finish(im, 0.3, 0.25)


def spikes():
    im, d = new(16, 8)
    for x in (0, 8):
        d.polygon([(x, 7), (x + 4, 0), (x + 8, 7)], fill=P['stone2'])
        d.polygon([(x + 4, 0), (x + 8, 7), (x + 4, 7)], fill=P['stone0'])
        d.point((x + 4, 1), fill=P['ember2'])
    d.rectangle([0, 7, 15, 7], fill=P['dirt0'])
    return finish(im, 0.2, 0.2)


def portal(i):
    im, d = new(32, 48)
    d.ellipse([2, 2, 29, 45], fill=P['night1'])
    for r in range(5):
        shift = (i * 2 + r * 3) % 8
        c = [P['night3'], P['mag1'], P['cyan_d'], P['mag2'], P['cyan']][r]
        d.ellipse([4 + r * 2, 4 + r * 3 + (shift % 2), 27 - r * 2, 43 - r * 3], outline=c, width=1)
    d.ellipse([12, 18, 19, 29], fill=P['white'])
    d.ellipse([13, 20, 18, 27], fill=P['cyan'])
    # stone frame
    d.rectangle([0, 44, 31, 47], fill=P['stone1'])
    return finish(im, 0.25, 0.25)


def platform_piece(kind):
    im, d = new(16, 12)
    d.rectangle([0, 2, 15, 9], fill=P['stone1'])
    d.rectangle([0, 2, 15, 3], fill=P['stone3'])
    d.rectangle([0, 8, 15, 9], fill=P['stone0'])
    if kind == 'mid':
        d.rectangle([6, 5, 9, 6], fill=P['cyan_d'])
    if kind == 'l':
        d.rectangle([0, 2, 1, 9], fill=P['stone2'])
        d.point((3, 5), fill=P['cyan'])
    if kind == 'r':
        d.rectangle([14, 2, 15, 9], fill=P['stone0'])
        d.point((12, 5), fill=P['cyan'])
    # glowing underside
    d.rectangle([2, 10, 13, 10], fill=P['mag1'])
    return finish(im, 0.2, 0.25)


# ------------------------------------------------------------- PROJECTILES
def bolt(i):
    im, d = new(16, 16)
    r = [3, 4, 3][i % 3]
    d.ellipse([8 - r - 2, 8 - r + 1, 8 + r - 2, 8 + r - 1], fill=P['cyan_d'])
    d.ellipse([8 - r + 1, 8 - r + 2, 8 + r + 3, 8 + r - 2], fill=P['cyan'])
    d.ellipse([7, 6, 11, 9], fill=P['white'])
    # trail
    d.line([(0, 8), (5, 8)], fill=P['cyan_d'])
    d.point((1, 7), fill=P['cyan'])
    return im


def spore(i):
    im, d = new(16, 16)
    r = [4, 5][i % 2]
    d.ellipse([8 - r, 8 - r, 8 + r, 8 + r], fill=P['mag1'])
    d.ellipse([8 - r + 1, 8 - r + 1, 8 + r - 2, 8 + r - 2], fill=P['mag2'])
    d.point((6, 6), fill=P['mag3'])
    return auto_outline(im)


def orb(i):
    im, d = new(16, 16)
    r = [5, 6, 5][i % 3]
    d.ellipse([8 - r, 8 - r, 8 + r, 8 + r], fill=P['mag0'])
    d.ellipse([8 - r + 1, 8 - r + 1, 8 + r - 1, 8 + r - 1], fill=P['mag1'])
    d.ellipse([8 - 3, 8 - 3, 8 + 3, 8 + 3], fill=P['mag3'])
    d.point((8, 8), fill=P['white'])
    return auto_outline(im)


def spear(i):
    im, d = new(16, 32)
    d.polygon([(8, 31), (4, 10), (8, 0), (12, 10)], fill=P['mag1'])
    d.polygon([(8, 0), (12, 10), (8, 31)], fill=P['mag0'])
    d.line([(8, 3), (8, 22)], fill=P['mag3'])
    if i % 2:
        d.point((8, 26), fill=P['white'])
    return auto_outline(im)


def wave(i):
    im, d = new(24, 20)
    h = [14, 16, 18][i % 3]
    d.polygon([(0, 19), (12, 19 - h), (24, 19), (12, 19 - h // 2)], fill=P['mag1'])
    d.polygon([(4, 19), (12, 19 - h + 5), (20, 19), (12, 19 - h // 2 + 2)], fill=P['mag3'])
    return auto_outline(im)


def puff(i):
    im, d = new(16, 16)
    r = 2 + i * 2
    d.ellipse([8 - r, 8 - r, 8 + r, 8 + r], outline=P['night4'], width=1)
    return im


def sprite_set():
    """Return dict name -> (frame_size, {anim: (frames, fps, loop)})"""
    S = {}
    S['mossling'] = ((32, 24), {
        'walk': ([mossling(i) for i in range(4)], 6, True),
        'alert': ([mossling(1, alert=True), mossling(2, alert=True)], 10, True),
        'squash': ([mossling(0, squash=1)], 1, False),
    })
    S['wisp'] = ((32, 32), {
        'fly': ([wisp(i) for i in range(4)], 10, True),
        'dive': ([wisp(i, True) for i in (0, 2)], 14, True),
    })
    S['sporecap'] = ((32, 32), {
        'idle': ([sporecap(0), sporecap(1)], 3, True),
        'shoot': ([sporecap(0, s) for s in range(3)], 10, False),
    })
    S['boss'] = ((96, 96), {
        'idle': ([boss('idle', t / 4) for t in range(4)], 4, True),
        'run': ([boss('run', t / 6) for t in range(6)], 12, True),
        'windup': ([boss('windup', 0.0), boss('windup', 0.9)], 8, True),
        'slam': ([boss('slam', 0.0), boss('slam', 0.9)], 6, False),
        'stun': ([boss('stun', 0.0), boss('stun', 0.5)], 4, True),
    })
    S['coin'] = ((16, 16), {'spin': ([coin(i) for i in range(6)], 10, True)})
    S['heart_pickup'] = ((16, 16), {'bob': ([heart_pick(i) for i in range(2)], 3, True)})
    S['shard'] = ((16, 16), {'shimmer': ([shard(i) for i in range(4)], 6, True)})
    S['checkpoint'] = ((24, 40), {
        'off': ([checkpoint(False)], 1, False),
        'on': ([checkpoint(True, i) for i in range(4)], 8, True),
    })
    S['lever'] = ((16, 16), {'off': ([lever(False)], 1, False), 'on': ([lever(True)], 1, False)})
    S['gate'] = ((16, 64), {'glow': ([gate(i) for i in range(4)], 5, True)})
    S['spikes'] = ((16, 8), {'default': ([spikes()], 1, False)})
    S['portal'] = ((32, 48), {'swirl': ([portal(i) for i in range(4)], 7, True)})
    S['plat'] = ((16, 12), {'l': ([platform_piece('l')], 1, False), 'mid': ([platform_piece('mid')], 1, False),
                            'r': ([platform_piece('r')], 1, False)})
    S['bolt'] = ((16, 16), {'fly': ([bolt(i) for i in range(3)], 14, True)})
    S['spore'] = ((16, 16), {'fly': ([spore(i) for i in range(2)], 8, True)})
    S['orb'] = ((16, 16), {'fly': ([orb(i) for i in range(3)], 10, True)})
    S['spear'] = ((16, 32), {'fall': ([spear(i) for i in range(2)], 8, True)})
    S['wave'] = ((24, 20), {'move': ([wave(i) for i in range(3)], 10, True)})
    S['puff'] = ((16, 16), {'pop': ([puff(i) for i in range(4)], 14, False)})
    return S


if __name__ == '__main__':
    S = sprite_set()
    rows = []
    for name, (fs, anims) in S.items():
        for an, (frames, fps, loop) in anims.items():
            rows.append(frames)
    # preview in chunks, small first
    small = [r for r in rows if r[0].width <= 32 and r[0].height <= 40]
    big = [r for r in rows if r[0].width > 32]
    w = max(sum(f.width for f in r) for r in small)
    h = sum(r[0].height for r in small)
    out = Image.new('RGBA', (w, h), (40, 50, 80, 255))
    y = 0
    for r in small:
        x = 0
        for f in r:
            out.alpha_composite(f, (x, y))
            x += f.width
        y += r[0].height
    upscale(out, 4).save('/tmp/ent_small.png')
    b = [f for r in big for f in r]
    w = 96 * 6
    out = Image.new('RGBA', (w, 96 * 4), (40, 50, 80, 255))
    for i, f in enumerate(b):
        out.alpha_composite(f, ((i % 6) * 96, (i // 6) * 96))
    upscale(out, 2).save('/tmp/ent_boss.png')
    print('ok', len(rows))
