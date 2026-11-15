"""Generate every PNG used by SHADOW RUNNER.  Run:  python3 tools/gen_art.py"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(HERE)
A = os.path.join(ROOT, 'assets')

from pxlib import *
import art_player
import art_entities
import art_env


def save(im, *path):
    p = os.path.join(A, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    im.save(p)


def main():
    meta = {}

    # ---- sprite sheets: one row per animation
    def add(name, frame_size, anims):
        rows, m = [], {}
        for ri, (an, (frames, fps, loop)) in enumerate(anims.items()):
            rows.append(frames)
            m[an] = {'row': ri, 'frames': len(frames), 'fps': fps, 'loop': loop}
        save(sheet(rows), 'sprites', name + '.png')
        meta[name] = {'frame': list(frame_size), 'anims': m}

    add('player', (48, 32), art_player.player_frames())
    for name, (fs, anims) in art_entities.sprite_set().items():
        add(name, fs, anims)
    with open(os.path.join(A, 'sprites', 'sprites.json'), 'w') as f:
        json.dump(meta, f, indent=1)

    # ---- tiles + decor
    save(art_env.tile_atlas(), 'tiles', 'tileset.png')
    for k, im in art_env.decor_set().items():
        save(im, 'sprites', 'decor', k + '.png')

    # ---- backgrounds
    save(art_env.bg_sky(), 'backgrounds', 'sky.png')
    save(art_env.bg_mountains(seed=1, top=150, amp=90, col=(30, 26, 66), rim=(96, 82, 170), cyc=2), 'backgrounds', 'mountains_far.png')
    save(art_env.bg_mountains(seed=4, top=205, amp=60, col=(22, 20, 52), rim=(70, 58, 130), cyc=3), 'backgrounds', 'mountains_near.png')
    save(art_env.bg_forest(seed=5, base=335, hmin=70, hmax=130, col=(18, 17, 42), rim=(58, 47, 107), count=30), 'backgrounds', 'forest_mid.png')
    save(art_env.bg_near(seed=8), 'backgrounds', 'trees_near.png')
    save(art_env.bg_fog(), 'backgrounds', 'fog.png')

    # ---- ui / hud / menus
    icons = art_env.ui_icons()
    for k, im in icons.items():
        save(im, 'hud', k + '.png')
    font = os.path.join(A, 'fonts', 'PressStart2P-Regular.ttf')
    save(art_env.make_logo(font), 'menus', 'logo.png')
    save(art_env.make_icon(), 'menus', 'icon_128.png')
    save(art_env.make_icon().resize((128, 128)), '..', 'icon.png') if False else None
    art_env.make_icon().save(os.path.join(ROOT, 'icon.png'))

    # ---- lights + particles
    save(art_env.light_tex(128, 1.6), 'lights', 'light_soft.png')
    save(art_env.light_tex(256, 2.4), 'lights', 'light_wide.png')
    save(art_env.particle_tex('dot'), 'sprites', 'particle_dot.png')
    save(art_env.particle_tex('sq'), 'sprites', 'particle_sq.png')
    print('art done')


if __name__ == '__main__':
    main()
