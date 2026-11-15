"""Shared drawing helpers for the Shadow Runner procedural art pipeline (original art, CC0)."""
import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def new(w, h, c=(0, 0, 0, 0)):
    return Image.new("RGBA", (int(w), int(h)), c)

def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3])

def mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))

def capsule(d, p1, p2, w, fill):
    d.line([p1, p2], fill=fill, width=max(1, int(round(w))))
    r = w / 2.0
    for p in (p1, p2):
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=fill)

def ocap(d, p1, p2, w, fill, outline, ow):
    capsule(d, p1, p2, w + 2 * ow, outline)
    capsule(d, p1, p2, w, fill)

def opoly(d, pts, fill, outline, ow):
    d.polygon(pts, fill=outline)
    d.line(list(pts) + [pts[0]], fill=outline, width=int(2 * ow), joint="curve")
    d.polygon(pts, fill=fill)

def oell(d, box, fill, outline, ow):
    d.ellipse([box[0] - ow, box[1] - ow, box[2] + ow, box[3] + ow], fill=outline)
    d.ellipse(box, fill=fill)

def fk(o, a, L):
    return (o[0] + math.sin(a) * L, o[1] + math.cos(a) * L)

def downsample(img, size):
    pm = img.convert("RGBa").resize(size, Image.LANCZOS)
    return pm.convert("RGBA")

def blur(img, r):
    pm = img.convert("RGBa").filter(ImageFilter.GaussianBlur(r))
    return pm.convert("RGBA")

def tint_white(img, t):
    if t <= 0:
        return img
    a = np.array(img).astype(np.float32)
    a[..., :3] = a[..., :3] * (1 - t) + 255.0 * t
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")

def tint_color(img, color, t):
    a = np.array(img).astype(np.float32)
    for i in range(3):
        a[..., i] = a[..., i] * (1 - t) + color[i] * t
    return Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGBA")

def make_sheet(rows, F, cols=None):
    cols = cols or max(len(r) for r in rows)
    sheet = new(cols * F[0], len(rows) * F[1])
    for ry, row in enumerate(rows):
        for cx, fr in enumerate(row):
            sheet.paste(fr, (cx * F[0], ry * F[1]))
    return sheet

def radial(size, inner=(255, 255, 255), power=2.0, alpha=1.0):
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    c = (size - 1) / 2.0
    r = np.sqrt((x - c) ** 2 + (y - c) ** 2) / c
    a = np.clip(1 - r, 0, 1) ** power * alpha
    arr = np.zeros((size, size, 4), np.uint8)
    arr[..., 0], arr[..., 1], arr[..., 2] = inner
    arr[..., 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")

def vgrad(w, h, stops):
    ys = np.linspace(0, 1, h)
    arr = np.zeros((h, w, 4), np.uint8)
    for ch in range(3):
        arr[..., ch] = np.interp(ys, [s[0] for s in stops], [s[1][ch] for s in stops])[:, None]
    arr[..., 3] = 255
    return Image.fromarray(arr, "RGBA")

def tile_noise(w, h, cells_x, cells_y, seed):
    rng = np.random.RandomState(seed)
    g = rng.rand(cells_y, cells_x).astype(np.float32)
    g3 = np.concatenate([g, g, g], axis=1)
    im = Image.fromarray((g3 * 255).astype(np.uint8), "L").resize((w * 3, h), Image.BICUBIC)
    a = np.array(im).astype(np.float32) / 255.0
    return a[:, w:2 * w]
