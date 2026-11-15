# SHADOW RUNNER - Chapter 1: The Fallen City
Developed by **Shubh Gupta** - shubhgupta210112@gmail.com

HD 2D cartoon action platformer for Godot 4.x (GDScript, GL Compatibility renderer).

## Run it
1. Install Godot 4.2 or newer (4.3+ recommended).
2. Extract the ZIP, open Godot, **Import** `project.godot`.
3. Let the first import finish (it converts the PNG/WAV files), then press **Play (F5)**.

## Controls
| | PC | Android |
|---|---|---|
| Move | A / D or arrows | on-screen left / right (left thumb) |
| Jump | Space (W / Up) | jump button (right thumb) |
| Attack / action | E (J / X) | sword button |
| Pause | Esc | pause button (top right) |
Gamepad also works.

## What's in the chapter
Cinematic opening, 5 ground sections with pits, floating and moving platforms, spikes and saws, 3 enemy types (Crawler, Drone, Brute), 5 beacon checkpoints, 3 hidden gold crystals, health hearts, and the **VOID GUARDIAN** boss (intro, 3 telegraphed attacks, enraged 2nd phase, defeat sequence) followed by a portal ending and victory screen with rank.
Menu, HUD, pause, settings, about/credits, defeat and victory screens are all implemented.

## Project layout
`scenes/` (main_menu, level), `scripts/` (player, enemy, boss, level, hud, ...), `assets/` (characters, enemies, environments, backgrounds, effects, audio, fonts, ui, mobile), `tools/` (Python generators for all art/audio; re-run to regenerate).

## Honest status
- **Not yet play-tested in Godot.** The build environment had no Godot executable, so the code was written carefully and checked with static scripts only (file paths, bracket balance, indentation, API usage). Expect that a first run may reveal small errors (typos, tuning of jump/enemy values); please check the Godot Output panel and tell me what appears.
- **No Windows or Android builds exist.** To export: install Godot export templates, then Project > Export > add Windows Desktop / Android (landscape is already set in the project; Android needs JDK + Android SDK configured in Editor Settings).
- Art is procedurally generated vector-style cartoon art with frame-by-frame animation (hero: idle 8, run 10, jump 6, fall 4, land 4, attack 6, damage 4, victory 6), not hand-painted. Audio is synthesised.
