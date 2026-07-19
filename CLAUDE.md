# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A browser-based "League of Legends dodge trainer" — a top-down game where the player right-clicks to move a champion dot and dodges enemy skillshots. Score = survival time + projectiles dodged.

## Running

No build tools, no npm. Open `index.html` with a static server (VS Code **Live Server**) and reload the browser to see changes. Phaser 3 is loaded from CDN; `src/main.js` is loaded as an ES module.

## Hard constraints (do not violate)

- **Pure JavaScript + Phaser 3 via CDN.** No build step, no bundler, no npm, no TypeScript.
- **ES modules only**, imported with relative paths (`./config.js`).
- **All gameplay constants live in `src/config.js`** (the `CONFIG` object) — speeds, cooldowns, telegraph durations, spawn rates, colors, sizes. The user tunes these; never hardcode a tunable value elsewhere.
- Must run served over Live Server (module scripts need HTTP, not `file://`).

## Architecture

- `index.html` — CDN Phaser tag + `<script type="module" src="src/main.js">`.
- `src/config.js` — single source of truth for all tunables (`CONFIG`).
- `src/main.js` — Phaser game bootstrap + `GameScene` (arena/background drawing, right-click input, main `update` loop). Uses `Phaser.Scale.FIT` at the `arena.width/height` design resolution so the canvas letterboxes into any window.
- `src/player.js` — `Player` class: click-to-move at constant speed, stops at destination, clamps to arena bounds; ellipse drop-shadow for fake top-down perspective.
- `src/projectiles.js`, `src/spawner.js`, `src/ui.js` — **stubs** for later phases (skillshots, spawning, score/death UI). Empty on purpose.

### Conventions
- Fake perspective is faked with squashed ellipses (shadows, telegraphs, move markers), not real 3D.
- Orientation is set purely by swapping `CONFIG.arena.width`/`height` (currently 1280×720 landscape).
- Right-click moves; the browser context menu is disabled via `this.input.mouse.disableContextMenu()`.

## Workflow

Built incrementally in phases; **do not add features the user didn't ask for.** Phase 1 (movement) is done. Skillshots (line first, then circle AoE, then homing missile), spawner ramping, and score/death UI are planned but not yet implemented — stop and get approval before starting the next phase.

## Godot mobile port (godot/)

The mobile rebuild lives in `godot/` (Godot 4.7, GDScript). The web version in
`src/` stays untouched. Spec: `docs/superpowers/specs/2026-07-19-mobile-godot-port-design.md`.

- All tunables live in `godot/autoload/config.gd` (`Config` autoload) — never
  hardcode a tunable elsewhere.
- Monetization is isolated in the `Ads` / `Iap` autoloads (phase-1 stubs).
  Game scenes must never reference ad SDKs directly.
- Run tests:
  `& "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --headless --path godot res://tests/test_runner.tscn`
  (expect `ALL TESTS PASSED`).
- Run the game: same binary with `--path godot`, or from the Godot editor.
