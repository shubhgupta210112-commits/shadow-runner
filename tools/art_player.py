"""Player sprite: the hooded 'Shadow Runner' with a trailing ember scarf."""
import math
from pxlib import *

P = PAL
CLOAK = P['night2']
CLOAK_D = P['night1']
CLOAK_L = P['night3']
SCARF = P['ember1']
SCARF_L = P['ember2']
SCARF_D = P['ember0']
EYE = P['cyan']
BOOT = H('1a1634')
SKIN_VOID = H('07060f')


class OffsetDraw:
    """Wraps ImageDraw and translates every coordinate by (ox, oy)."""
    def __init__(self, d, ox, oy=0):
        self.d, self.ox, self.oy = d, ox, oy
    def _p(self, p):
        return (p[0] + self.ox, p[1] + self.oy)
    def line(self, pts, fill=None, width=1):
        self.d.line([self._p(p) for p in pts], fill=fill, width=width)
    def polygon(self, pts, fill=None):
        self.d.polygon([self._p(p) for p in pts], fill=fill)
    def ellipse(self, box, fill=None):
        self.d.ellipse([box[0] + self.ox, box[1] + self.oy, box[2] + self.ox, box[3] + self.oy], fill=fill)
    def rectangle(self, box, fill=None):
        self.d.rectangle([box[0] + self.ox, box[1] + self.oy, box[2] + self.ox, box[3] + self.oy], fill=fill)
    def arc(self, box, start, end, fill=None, width=1):
        self.d.arc([box[0] + self.ox, box[1] + self.oy, box[2] + self.ox, box[3] + self.oy], start, end, fill=fill, width=width)
    def pieslice(self, box, start, end, fill=None):
        self.d.pieslice([box[0] + self.ox, box[1] + self.oy, box[2] + self.ox, box[3] + self.oy], start, end, fill=fill)
    def point(self, p, fill=None):
        self.d.point(self._p(p), fill=fill)


def _line(d, pts, color, width=1):
    for a, b in zip(pts[:-1], pts[1:]):
        d.line([a, b], fill=color, width=width)


def _scarf(d, neck, phase, droop, length, color_main=SCARF):
    """Trailing scarf: chain of segments streaming backwards (to the left)."""
    pts = [neck]
    x, y = neck
    for i in range(length):
        x -= 1.7
        y += droop * 0.25 + math.sin(phase + i * 0.9) * 0.9 * (i / length + 0.3)
        pts.append((x, y))
    # shadow, body, highlight
    _line(d, [(px, py + 1) for px, py in pts], SCARF_D, 2)
    _line(d, pts, color_main, 2)
    _line(d, [(px, py - 0.5) for px, py in pts[:-2]], SCARF_L, 1)
    # frayed tip
    ex, ey = pts[-1]
    d.point((int(ex - 1), int(ey + 1)), fill=SCARF_D)
    d.point((int(ex - 2), int(ey)), fill=SCARF)


def draw_player(
    bob=0.0, lean=0.0, legs=None, arm_f=(4, 6), arm_b=(-3, 6),
    scarf_phase=0.0, scarf_droop=0.0, tail=5, squash=0, hit=False,
    eyes_open=True, cast=False, head_tilt=0,
):
    im, d0 = new(48, 32)
    d = OffsetDraw(d0, 9, 0)
    base_y = 31
    hip = (15 + lean * 0.3, 21 + bob)
    neck = (15 + lean, 13.5 + bob + squash * 0.5)
    if legs is None:
        legs = [((16, 26), (16, 31)), ((14, 26), (14, 31))]  # absolute knee/foot (back first, front second)
    back_leg, front_leg = legs

    # ---- back arm
    sh_b = (neck[0] - 1, neck[1] + 2)
    hand_b = (sh_b[0] + arm_b[0], sh_b[1] + arm_b[1])
    _line(d, [sh_b, hand_b], CLOAK_D, 2)
    d.point((int(hand_b[0]), int(hand_b[1])), fill=H('3c3270'))

    # ---- back leg
    _line(d, [hip, back_leg[0], back_leg[1]], CLOAK_D, 3)
    fx, fy = back_leg[1]
    d.rectangle([fx - 1, fy - 1, fx + 2, fy], fill=BOOT)

    # ---- cloak tail (streams behind)
    tl = tail
    tail_poly = [
        (neck[0] - 2, neck[1] + 1),
        (neck[0] - 3 - tl, neck[1] + 5 + scarf_droop * 2 + math.sin(scarf_phase + 1.2) * 1.2),
        (neck[0] - 2 - tl * 0.8, neck[1] + 9 + math.sin(scarf_phase) * 1.2),
        (neck[0] - 1 - tl * 0.5, neck[1] + 11 + bob * 0.2),
        (hip[0] - 3, hip[1] + 4),
    ]
    d.polygon(tail_poly, fill=CLOAK_D)

    # ---- scarf (behind head)
    _scarf(d, (neck[0] - 1, neck[1] - 1.5), scarf_phase, scarf_droop, min(10, 6 + int(tail * 0.7)))

    # ---- torso / cloak body
    torso = [
        (neck[0] - 3, neck[1]), (neck[0] + 3, neck[1]),
        (hip[0] + 5, hip[1] + 5), (hip[0] - 5, hip[1] + 5),
    ]
    d.polygon(torso, fill=CLOAK)
    # jagged hem
    hy = int(hip[1] + 5)
    for i, hx in enumerate(range(int(hip[0] - 5), int(hip[0] + 6), 2)):
        d.point((hx, hy + 1), fill=CLOAK)
    # chest highlight and belt
    _line(d, [(neck[0] + 2, neck[1] + 1), (hip[0] + 3, hip[1] + 3)], CLOAK_L, 1)
    d.line([(hip[0] - 4, hip[1] + 1), (hip[0] + 4, hip[1] + 1)], fill=BOOT, width=1)
    d.point((int(hip[0] + 1), int(hip[1] + 1)), fill=P['gold2'])

    # ---- front leg
    _line(d, [hip, front_leg[0], front_leg[1]], CLOAK, 3)
    _line(d, [(hip[0] + 1, hip[1]), (front_leg[0][0] + 1, front_leg[0][1])], CLOAK_L, 1)
    fx, fy = front_leg[1]
    d.rectangle([fx - 1, fy - 1, fx + 3, fy], fill=BOOT)
    d.point((fx + 3, fy - 1), fill=P['teal'])

    # ---- head / hood
    hx, hy2 = neck[0] + 1 + head_tilt, neck[1] - 5.5
    d.ellipse([hx - 5, hy2 - 5, hx + 5, hy2 + 4], fill=CLOAK)
    # hood point sweeping back
    d.polygon([(hx - 3, hy2 - 4), (hx - 8, hy2 - 1 + scarf_droop), (hx - 4, hy2 + 2)], fill=CLOAK)
    # hood rim highlight
    _line(d, [(hx - 3, hy2 - 5), (hx, hy2 - 6), (hx + 3, hy2 - 4)], CLOAK_L, 1)
    # face void
    d.ellipse([hx, hy2 - 3, hx + 6, hy2 + 3], fill=SKIN_VOID)
    if eyes_open:
        d.point((int(hx + 2), int(hy2 - 1)), fill=EYE)
        d.point((int(hx + 4), int(hy2 - 1)), fill=EYE)
        d.point((int(hx + 2), int(hy2)), fill=H('2fb6c9'))
        d.point((int(hx + 4), int(hy2)), fill=H('2fb6c9'))
    else:
        d.line([(int(hx + 2), int(hy2)), (int(hx + 5), int(hy2))], fill=H('2fb6c9'))

    # ---- front arm
    sh_f = (neck[0] + 1, neck[1] + 2)
    hand_f = (sh_f[0] + arm_f[0], sh_f[1] + arm_f[1])
    mid = ((sh_f[0] + hand_f[0]) / 2 + 0.5, (sh_f[1] + hand_f[1]) / 2 + 1)
    _line(d, [sh_f, mid, hand_f], CLOAK_L, 2)
    d.point((int(hand_f[0]), int(hand_f[1])), fill=H('c9bff5'))
    if cast:
        # little glowing bolt charge at the hand
        d.ellipse([hand_f[0], hand_f[1] - 2, hand_f[0] + 3, hand_f[1] + 1], fill=P['cyan'])
        d.point((int(hand_f[0] + 1), int(hand_f[1] - 1)), fill=P['white'])

    im = rimlight(im, 0.22, 0.28)
    if hit:
        a = np.array(im)
        m = a[..., 3] > 0
        a[m, 0] = np.clip(a[m, 0] * 0.6 + 150, 0, 255)
        a[m, 1] = np.clip(a[m, 1] * 0.6 + 70, 0, 255)
        a[m, 2] = np.clip(a[m, 2] * 0.6 + 70, 0, 255)
        im = Image.fromarray(a, 'RGBA')
    im = auto_outline(im)
    return im


def player_frames():
    anims = {}

    # idle: gentle breathing + scarf sway
    idle = []
    for i in range(4):
        t = i / 4 * math.tau
        bob = (math.sin(t) + 1) * 0.5
        idle.append(draw_player(
            bob=bob, legs=[((14, 26 + bob * 0.3), (13, 31)), ((17, 26 + bob * 0.3), (18, 31))],
            arm_f=(3, 6), arm_b=(-2, 6), scarf_phase=t, scarf_droop=0.3, tail=3))
    anims['idle'] = (idle, 6, True)

    # run: 8 frames
    run = []
    for i in range(8):
        ph = i / 8 * math.tau
        bob = abs(math.sin(ph)) * 1.6
        hp = (15 + 3 * 0.3, 21 + bob)

        def leg(phase, hp=hp):
            fxo = 7 * math.sin(phase)
            lift = max(0.0, math.cos(phase)) * 5.5
            foot = (hp[0] + 1 + fxo, 31 - lift)
            knee = (hp[0] + 1 + fxo * 0.5 + 2.5, (hp[1] + foot[1]) / 2 - 0.5)
            return (knee, foot)
        legs = [leg(ph + math.pi), leg(ph)]
        arm_f = (5 * math.sin(ph + math.pi) * 0.9 + 1, 5 + 1.5 * math.cos(ph))
        arm_b = (5 * math.sin(ph) * 0.9 - 1, 5 + 1.5 * math.cos(ph + math.pi))
        run.append(draw_player(
            bob=bob, lean=2.0, legs=legs, arm_f=arm_f, arm_b=arm_b,
            scarf_phase=ph * 1.0, scarf_droop=-0.4, tail=8))
    anims['run'] = (run, 12, True)

    # jump (rising)
    jump = [
        draw_player(bob=-1, lean=1, legs=[((12, 26), (9, 29)), ((18, 25), (19, 29))],
                    arm_f=(4, -4), arm_b=(-4, -2), scarf_phase=0.5, scarf_droop=1.2, tail=7, head_tilt=1),
        draw_player(bob=-1, lean=1, legs=[((12, 26), (9, 28)), ((18, 25), (20, 28))],
                    arm_f=(5, -3), arm_b=(-4, -1), scarf_phase=1.5, scarf_droop=1.4, tail=7, head_tilt=1),
    ]
    anims['jump'] = (jump, 8, False)

    # fall
    fall = [
        draw_player(bob=0, lean=0.5, legs=[((12, 26), (11, 30)), ((18, 26), (19, 30))],
                    arm_f=(4, -2), arm_b=(-4, -3), scarf_phase=0.0, scarf_droop=-1.6, tail=4),
        draw_player(bob=0, lean=0.5, legs=[((12, 26), (11, 31)), ((18, 26), (19, 31))],
                    arm_f=(4, -3), arm_b=(-4, -2), scarf_phase=2.0, scarf_droop=-1.8, tail=4),
    ]
    anims['fall'] = (fall, 8, True)

    # land: squash
    land = [
        draw_player(bob=5, squash=2, lean=1, legs=[((11, 28), (9, 31)), ((19, 28), (21, 31))],
                    arm_f=(5, 3), arm_b=(-5, 3), scarf_phase=0.5, scarf_droop=0.5, tail=3),
        draw_player(bob=2, squash=1, lean=0.5, legs=[((12, 27), (11, 31)), ((18, 27), (19, 31))],
                    arm_f=(4, 5), arm_b=(-3, 5), scarf_phase=1.0, scarf_droop=0.2, tail=3),
    ]
    anims['land'] = (land, 14, False)

    # hit reaction
    hit = [
        draw_player(bob=1, lean=-2, legs=[((12, 26), (9, 31)), ((17, 26), (18, 31))],
                    arm_f=(-2, -4), arm_b=(-5, -3), scarf_phase=0.2, scarf_droop=1.5, tail=6, hit=True,
                    eyes_open=False, head_tilt=-2),
        draw_player(bob=2, lean=-1, legs=[((12, 26), (10, 31)), ((17, 26), (18, 31))],
                    arm_f=(-1, 2), arm_b=(-4, 2), scarf_phase=1.0, scarf_droop=1.0, tail=5, hit=False,
                    eyes_open=False, head_tilt=-1),
    ]
    anims['hit'] = (hit, 10, False)

    # cast (shoot bolt)
    cast = []
    for i in range(3):
        cast.append(draw_player(
            bob=0.5, lean=1 + i * 0.3, legs=[((12, 26), (10, 31)), ((18, 26), (20, 31))],
            arm_f=(8 + i, 0 - 0.5 * i), arm_b=(-3, 4), scarf_phase=i, scarf_droop=0.2, tail=4, cast=(i < 2)))
    anims['cast'] = (cast, 18, False)

    return anims


if __name__ == '__main__':
    a = player_frames()
    rows = [f for f, _, _ in a.values()]
    s = sheet(rows)
    upscale(s, 6).save('/tmp/player_preview.png')
    print({k: len(v[0]) for k, v in a.items()})
