"""Touch-control button art (original, drawn procedurally)."""
import os, sys, math
from PIL import Image, ImageDraw, ImageFilter

SS = 4

def button(size, icon, pressed, accent):
    W = size * SS
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    c = W / 2
    r = W * 0.43
    gd.ellipse([c - r - 14, c - r - 14, c + r + 14, c + r + 14], fill=accent + (110 if pressed else 70,))
    glow = glow.filter(ImageFilter.GaussianBlur(W * 0.03))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    fill = (accent[0] // 2, accent[1] // 2, accent[2] // 2, 215 if pressed else 150)
    d.ellipse([c - r, c - r, c + r, c + r], fill=fill, outline=accent + (255,), width=int(W * 0.03))
    d.ellipse([c - r * 0.86, c - r * 0.86, c + r * 0.86, c + r * 0.86], outline=(255, 255, 255, 60), width=int(W * 0.012))
    col = (255, 255, 255, 255)
    k = W * 0.2
    if icon == "left":
        d.polygon([(c - k, c), (c + k * 0.8, c - k * 1.2), (c + k * 0.8, c + k * 1.2)], fill=col)
    elif icon == "right":
        d.polygon([(c + k, c), (c - k * 0.8, c - k * 1.2), (c - k * 0.8, c + k * 1.2)], fill=col)
    elif icon == "jump":
        d.polygon([(c, c - k * 1.1), (c - k * 1.3, c + k * 0.3), (c - k * 0.55, c + k * 0.3), (c - k * 0.55, c + k * 1.1),
                   (c + k * 0.55, c + k * 1.1), (c + k * 0.55, c + k * 0.3), (c + k * 1.3, c + k * 0.3)], fill=col)
    elif icon == "action":
        # sword slash
        d.polygon([(c - k * 1.1, c + k * 1.1), (c + k * 1.1, c - k * 1.1), (c + k * 1.3, c - k * 0.7), (c - k * 0.7, c + k * 1.3)], fill=col)
        d.polygon([(c - k * 1.3, c + k * 0.4), (c - k * 0.4, c + k * 1.3), (c - k * 1.4, c + k * 1.4)], fill=col)
    elif icon == "pause":
        d.rounded_rectangle([c - k * 0.8, c - k, c - k * 0.2, c + k], radius=6, fill=col)
        d.rounded_rectangle([c + k * 0.2, c - k, c + k * 0.8, c + k], radius=6, fill=col)
    return img.resize((size, size), Image.LANCZOS)

def run(out):
    os.makedirs(out, exist_ok=True)
    spec = {"left": (176, (80, 220, 255)), "right": (176, (80, 220, 255)), "jump": (176, (120, 255, 180)),
            "action": (176, (255, 170, 80)), "pause": (84, (200, 200, 255))}
    for name, (size, acc) in spec.items():
        for pressed in (False, True):
            button(size, name, pressed, acc).save(os.path.join(out, "btn_%s%s.png" % (name, "_down" if pressed else "")), optimize=True)

if __name__ == "__main__":
    run(sys.argv[1] if len(sys.argv) > 1 else ".")
