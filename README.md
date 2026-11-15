# SHADOW RUNNER

An original pixel-art arcade platformer for **Godot 4.3+** (GDScript, GL Compatibility renderer).
Chapter 1: **The Whispering Grove** - run, jump, stomp, cast Shadow Bolts, find the hidden Shadow Shards and defeat the spectral stag **GLOOMHORN**.

> Developed by Shubh Gupta
> Contact: shubhgupta210112@gmail.com

## Quick start

1. Install **Godot 4.3 or newer** (standard build, no .NET needed): <https://godotengine.org/download>
2. Unzip this project, open Godot, click **Import**, pick `project.godot`.
3. Let Godot import the assets (first open only, ~10 seconds), then press **F5** (Play).

Everything is generated and included - no plugins, no downloads, works offline.

## Controls

| Action | Keys |
|---|---|
| Move | A / D or Left / Right |
| Jump (hold = higher) | Space, W or Up |
| Shadow Bolt | F or J |
| Interact (levers) | E |
| Drop through one-way platforms | Down + Jump |
| Pause | Esc (or P) |

Gamepad: left stick / d-pad, A = jump, X = interact, B = bolt, Start = pause.

## How to play

* **Stomp** enemies from above or shoot them with Shadow Bolts. Hits knock enemies back; they recover and rebound.
* Collect **coins** (+10), hidden **Shadow Shards** (3 total, +500) and **hearts** (heal 1).
* Touch a rune obelisk to set a **checkpoint**. You have 3 lives; falling in a pit costs one heart.
* Pull the lever (E) in the ruins to open the crystal gate.
* Beyond the last checkpoint is the **GLOOMHORN** arena. Wall-crash stuns it; hit it while stunned for double damage. Three phases: charge + orb volley -> ground slam shockwaves -> spear rain.
* Defeat it, step through the portal, and see your rank (S/A/B/C) on the results screen.

## Project structure

```
project.godot            input map, collision layer names, autoloads
icon.png
scenes/                  main_menu, game, level_01, player, enemy, boss, projectile,
                         pickup, hazard, checkpoint, moving_platform, switch_gate,
                         level_exit, hud, pause_menu, game_over, results_screen, credits
scripts/
  game_manager.gd        autoload: score, lives, settings, saves, scene fades
  audio_manager.gd       autoload: SFX pool, music crossfade, ambience
  level_manager.gd       checkpoints, respawn, boss arena sequence, exit
  player.gd enemy.gd boss.gd projectile.gd pickup.gd ...
  ui_kit.gd              shared code-built pixel UI helpers
assets/
  sprites/ tiles/ backgrounds/ hud/ menus/ lights/ fonts/ ui/ audio/{sfx,music,ambient}
tools/                   asset + scene generators and QA bots (see below)
```

Collision layers: 1 world, 2 one-way platforms, 3 player, 4 enemy hitboxes, 5 hazards,
6 pickups, 7 player projectiles, 8 enemy projectiles, 9 interactables.

## Rebuilding generated content (optional)

Art, audio and scenes are produced by scripts, so you can tweak and regenerate:

```
pip install pillow numpy scipy          # ffmpeg with libvorbis needed for .ogg
python3 tools/gen_art.py                # sprites, tiles, backgrounds, logo
python3 tools/gen_audio.py              # sfx, music, ambience
godot --headless --path . --import
godot --headless --path . --script res://tools/build_frames.gd
godot --headless --path . res://tools/builder.tscn      # scenes + tileset + theme
```

QA bots (need a display, e.g. `xvfb-run`): `res://tools/playtest.tscn` plays the whole level incl. the boss and prints PASS/FAIL checks; `res://tools/uitest.tscn` screenshots the UI.

## Credits & licences

* Game design, code, art direction: **Shubh Gupta**.
* All sprites, tiles, backgrounds, music and sound effects are original and generated procedurally for this project.
* Fonts: **Press Start 2P** (CodeMan38) and **Silkscreen** (Jason Kottke), both under the SIL Open Font License 1.1 (licences in `assets/fonts/`).
* Inspired in general spirit by side-scrolling arcade platformers; no characters, art, maps, audio or code from *Dan the Man* or any other game are used.

## Known limitations

* One chapter / one level (by design for a 5-hour jam MVP).
* Music is synthesised chiptune - listenable but not a composer's work; swap files in `assets/audio/music/` freely.
* Keyboard + basic gamepad only; no remapping UI.
* Tested headless (automated play-through) and under software rendering; not tested on every GPU/OS or on Godot < 4.3 (TileMapLayer needs 4.3+).
* Web export is untested.

## Final testing checklist

- [x] Project imports with no errors; all scene/resource references resolve
- [x] Main menu: Play / Settings / About / Exit all work; credits shown exactly
- [x] Input actions: move, jump, interact, shoot, pause
- [x] Movement: coyote time, jump buffering, variable jump, drop-through
- [x] Enemies: patrol/detect/charge, swoop, spore lobbing; stomp + bolt + knockback
- [x] Hazards, pit falls, checkpoints, respawn, lives, game over
- [x] Lever + gate, moving platforms, coins, hidden shards, hearts
- [x] Boss: awaken, 3 phases, stun, defeat, portal unlock
- [x] Results screen, restart and main-menu buttons, credits roll
- [x] Pause menu + settings (volumes, fullscreen, screen shake) persist
