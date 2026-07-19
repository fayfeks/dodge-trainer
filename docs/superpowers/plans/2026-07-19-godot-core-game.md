# Godot Core Game (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Phaser dodge-trainer 1:1 in Godot 4.7 (desktop-playable), with monetization logic (interstitial gating, revive/shield rewards, ad-free flag) implemented behind stub singletons so the real AdMob/Billing plugins can be dropped in later without touching game code.

**Architecture:** One Godot project at `godot/`. Scenes are minimal `.tscn` files (one root node + script); all children are built in code, mirroring the old JS structure. All tunables live in the `Config` autoload. Monetization is isolated in `Ads`/`Iap` autoloads; pure decision logic (`AdGate`, `Spawner`) lives in `RefCounted` classes so it is headless-testable.

**Tech Stack:** Godot 4.7.1 (Steam build), GDScript, no external plugins in this phase.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-19-mobile-godot-port-design.md`. Later phases (Android export, AdMob plugin, Play Billing) are separate plans.
- Godot binary: `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`. In every PowerShell snippet below, `$GODOT` = that path (set it once per shell: `$GODOT = "C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe"`).
- All commands run from repo root `c:\Users\Omer\Documents\mygodotgames\dodge-game`.
- **Every gameplay tunable goes in `godot/autoload/config.gd` — never hardcoded elsewhere.** Durations are seconds, speeds px/sec.
- Design resolution 1280×720 landscape; touch/tap = move (mouse emulates touch via `pointing/emulate_touch_from_mouse=true`, already set).
- Monetization rules (from spec): interstitial every **3rd death**, **300 s** no-interstitial grace after each app launch (deaths still count during grace), revive **once per run**, shield = next run's first hit absorbed, ad-free flag kills interstitials only.
- Game scenes never talk to ad SDKs — only to `Ads` / `Iap` autoload APIs defined in Task 7.
- Do not modify the web version (`src/`, `index.html`).
- `godot/project.godot` was rewritten by the editor on import — edit it additively (add `[autoload]` entries), do not restore removed lines.
- Test runner: `& $GODOT --headless --path godot res://tests/test_runner.tscn` — prints `ALL TESTS PASSED` and exits 0 on success. Every task adds `test_*` methods to `godot/tests/test_runner.gd`.
- UI copy stays English (matches existing game; localization is out of scope).

---

### Task 1: Test runner + Config autoload

**Files:**
- Create: `godot/tests/test_runner.gd`, `godot/tests/test_runner.tscn`, `godot/autoload/config.gd`
- Modify: `godot/project.godot` (add `[autoload]` section)

**Interfaces:**
- Produces: `Config` autoload with const dicts `ARENA, BACKGROUND, PLAYER, MOVE_MARKER, MENU, BOLT, BEAM, SPAWNER, DIFFICULTIES, ADS, REWARDS`. Test helper `check(cond: bool, msg: String)` in the runner; runner auto-calls every `test_*` method.

- [ ] **Step 1: Write the test runner and a failing config test**

`godot/tests/test_runner.gd`:

```gdscript
extends Node
# Headless test runner. Run:
#   & $GODOT --headless --path godot res://tests/test_runner.tscn
# Auto-runs every `test_*` method; exits 1 on any failure.
var failures := 0

func _ready() -> void:
	for m in get_method_list():
		if String(m.name).begins_with("test_"):
			call(m.name)
	if failures == 0:
		print("ALL TESTS PASSED")
	get_tree().quit(1 if failures > 0 else 0)

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("FAIL: " + msg)

func test_config_values() -> void:
	check(Config.ARENA.width == 1280.0, "arena width")
	check(Config.ARENA.margin == 30.0, "arena margin")
	check(Config.PLAYER.move_speed == 300.0, "player speed")
	check(Config.DIFFICULTIES.hard.projectile_speed == 500.0, "hard bolt speed")
	check(Config.SPAWNER.beam_chance == 0.1, "beam chance")
	check(Config.ADS.deaths_per_interstitial == 3, "deaths per interstitial")
	check(Config.ADS.launch_grace_sec == 300.0, "launch grace")
```

`godot/tests/test_runner.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/test_runner.gd" id="1"]

[node name="TestRunner" type="Node"]
script = ExtResource("1")
```

- [ ] **Step 2: Run tests, verify failure**

```powershell
& $GODOT --headless --path godot res://tests/test_runner.tscn; "exit=$LASTEXITCODE"
```
Expected: parse error — `Config` not declared (autoload missing yet). Nonzero exit.

- [ ] **Step 3: Write `godot/autoload/config.gd`**

```gdscript
extends Node
# All gameplay constants live here. Tune freely. (Godot port of src/config.js.)
# Durations are SECONDS, speeds px/sec.

const ARENA := {
	width = 1280.0, height = 720.0,
	margin = 30.0,                      # gap between arena border and canvas edge
	border_color = Color("2a3a52"), border_width = 3.0,
}

const BACKGROUND := {
	outer_color = Color("05070c"),      # base fill behind the arena
	floor_color = Color("111a2b"),
	vignette_color = Color("070b12"), vignette_alpha = 0.55,
	grid_size = 64.0, grid_color = Color("1e2c44"), grid_alpha = 0.6, grid_width = 1.0,
}

const PLAYER := {
	radius = 18.0, move_speed = 300.0, stop_distance = 2.0,
	color = Color("4fc3f7"), outline_color = Color("bde7ff"),
	shadow_squash = 0.45, shadow_alpha = 0.35, shadow_offset_y = 10.0,
}

const MOVE_MARKER := { color = Color("35d07f"), radius = 16.0, squash = 0.45, duration = 0.35 }

const MENU := {
	bg_color = Color("05070c"), title_color = Color("8fd3ff"),
	subtitle_color = Color("6f89a8"), text_color = Color("cfe4ff"),
	button_color = Color("1b2740"), button_hover_color = Color("2a3f66"),
	button_border_color = Color("3a557f"), button_text_color = Color("e8f2ff"),
}

const BOLT := { radius = 15.0, color = Color("ff5a4f"), glow_color = Color("ffb3ad") }

const BEAM := {
	telegraph_width = 7.5, telegraph_color = Color("e01414"), telegraph_alpha = 0.85,
	telegraph_duration = 1.0,           # thin warning line duration
	width_multiplier = 5.0, beam_color = Color("ffffff"), beam_alpha = 0.9,
	active_duration = 0.5,              # fired beam fade-out time
	damage_window = 0.08,               # seconds after firing during which it can hit
}

const SPAWNER := { edge_inset = 40.0, beam_chance = 0.1 }

const DIFFICULTIES := {
	easy   = { label = "EASY",   spawn_interval = 1.4,  spawn_interval_min = 0.7,
			   ramp_per_second = 0.008, projectile_speed = 300.0, aim_jitter_deg = 7.0 },
	normal = { label = "NORMAL", spawn_interval = 1.0,  spawn_interval_min = 0.48,
			   ramp_per_second = 0.012, projectile_speed = 400.0, aim_jitter_deg = 10.0 },
	hard   = { label = "HARD",   spawn_interval = 0.65, spawn_interval_min = 0.32,
			   ramp_per_second = 0.016, projectile_speed = 500.0, aim_jitter_deg = 14.0 },
}

const ADS := {
	deaths_per_interstitial = 3,        # full-screen ad every Nth death
	launch_grace_sec = 300.0,           # no interstitials this long after app launch
}

const REWARDS := {
	revive_invuln_sec = 1.5,            # invulnerability after an ad revive
	shield_invuln_sec = 1.0,            # invulnerability after the shield breaks
}
```

Add to `godot/project.godot` (new section, keep existing content):

```ini
[autoload]

Config="*res://autoload/config.gd"
```

- [ ] **Step 4: Run tests, verify pass**

Same command. Expected: `ALL TESTS PASSED`, `exit=0`.

- [ ] **Step 5: Commit**

```powershell
git add godot; git commit -m "feat(godot): test runner + Config autoload"
```

---

### Task 2: Player movement

**Files:**
- Create: `godot/scripts/player.gd`, `godot/scenes/player.tscn`
- Test: `godot/tests/test_runner.gd` (append)

**Interfaces:**
- Produces: `Player` (Node2D): `move_to(p: Vector2)`, `stop()`, `tick(delta: float)`, `var target` (Vector2 or null), `var shield_visual: bool`. Constant speed toward target, snap+stop at arrival, clamped to arena minus margin+radius.

- [ ] **Step 1: Append failing tests**

Append to `godot/tests/test_runner.gd`:

```gdscript
func _make_player() -> Player:
	var p: Player = preload("res://scenes/player.tscn").instantiate()
	add_child(p)
	p.position = Vector2(640, 360)
	return p

func test_player_moves_at_constant_speed() -> void:
	var p := _make_player()
	p.move_to(Vector2(940, 360))
	p.tick(0.5)
	check(abs(p.position.x - 790.0) < 0.01, "moved 150px in 0.5s, got x=%f" % p.position.x)
	p.queue_free()

func test_player_snaps_and_stops_at_target() -> void:
	var p := _make_player()
	p.move_to(Vector2(650, 360))
	p.tick(1.0)
	check(p.position == Vector2(650, 360), "snapped to target")
	check(p.target == null, "target cleared on arrival")
	p.queue_free()

func test_player_target_clamped_to_arena() -> void:
	var p := _make_player()
	p.move_to(Vector2(5000, -5000))
	var a := Config.ARENA
	var r: float = Config.PLAYER.radius
	check(p.target.x == a.width - a.margin - r, "x clamped")
	check(p.target.y == a.margin + r, "y clamped")
	p.queue_free()
```

- [ ] **Step 2: Run tests, verify failure** — expected: load error on missing `player.tscn`, nonzero exit.

- [ ] **Step 3: Implement**

`godot/scripts/player.gd`:

```gdscript
class_name Player
extends Node2D
# Champion dot: constant-speed click-to-move with a fake-perspective shadow.

var target = null            # Vector2 destination, or null when standing still
var shield_visual := false   # ring drawn while a rewarded shield is armed

func move_to(p: Vector2) -> void:
	var a := Config.ARENA
	var r: float = Config.PLAYER.radius
	target = Vector2(
		clampf(p.x, a.margin + r, a.width - a.margin - r),
		clampf(p.y, a.margin + r, a.height - a.margin - r)
	)

func stop() -> void:
	target = null

func tick(delta: float) -> void:
	if target != null:
		var pc := Config.PLAYER
		var dist: float = position.distance_to(target)
		var step: float = pc.move_speed * delta
		if dist <= maxf(step, pc.stop_distance):
			position = target
			target = null
		else:
			position += (target - position).normalized() * step
	queue_redraw()

func _draw() -> void:
	var pc := Config.PLAYER
	draw_set_transform(Vector2(0, pc.shadow_offset_y), 0.0, Vector2(1.0, pc.shadow_squash))
	draw_circle(Vector2.ZERO, pc.radius * 1.1, Color(0, 0, 0, pc.shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, pc.radius, pc.color)
	draw_arc(Vector2.ZERO, pc.radius, 0.0, TAU, 48, pc.outline_color, 2.0)
	if shield_visual:
		draw_arc(Vector2.ZERO, pc.radius + 6.0, 0.0, TAU, 48, Color("5fe0a0"), 3.0)
```

`godot/scenes/player.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/player.gd" id="1"]

[node name="Player" type="Node2D"]
script = ExtResource("1")
```

- [ ] **Step 4: Run tests, verify pass** — expected `ALL TESTS PASSED`.

- [ ] **Step 5: Commit** — `git add godot; git commit -m "feat(godot): player movement"`

---

### Task 3: Game scene — arena, tap input, move marker

**Files:**
- Create: `godot/scripts/game.gd`, `godot/scenes/game.tscn`, `godot/scripts/move_marker.gd`
- Modify: `godot/project.godot` (`run/main_scene="res://scenes/game.tscn"`)
- Delete: `godot/scenes/main.tscn`
- Test: `godot/tests/test_runner.gd` (append smoke test)

**Interfaces:**
- Consumes: `Player` from Task 2.
- Produces: `game.tscn` — root `Node2D` with `game.gd`; `var player: Player`, `var elapsed: float`, `var over: bool`. Tap (`InputEventScreenTouch` pressed) moves the player and spawns a `MoveMarker`.

- [ ] **Step 1: Append failing smoke test**

```gdscript
func test_game_scene_boots() -> void:
	var g = preload("res://scenes/game.tscn").instantiate()
	add_child(g)
	g._process(0.016)
	check(g.player is Player, "game has a player")
	check(g.player.position == Vector2(640, 360), "player starts centered")
	g.queue_free()
```

- [ ] **Step 2: Run tests, verify failure** — missing `game.tscn`.

- [ ] **Step 3: Implement**

`godot/scripts/move_marker.gd`:

```gdscript
class_name MoveMarker
extends Node2D
# LoL-style green ground ping: shrinks and fades, then frees itself.

func _ready() -> void:
	var m := Config.MOVE_MARKER
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(0.3, 0.3), m.duration)
	tw.tween_property(self, "modulate:a", 0.0, m.duration)
	tw.chain().tween_callback(queue_free)

func _draw() -> void:
	var m := Config.MOVE_MARKER
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, m.squash))
	draw_arc(Vector2.ZERO, m.radius, 0.0, TAU, 32, m.color, 2.0)
```

`godot/scripts/game.gd` (this task's version — later tasks extend it):

```gdscript
extends Node2D
# Gameplay scene: draws the arena, owns the player, handles tap-to-move.

var player: Player
var elapsed := 0.0
var over := false

func _ready() -> void:
	var a := Config.ARENA
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector2(a.width / 2.0, a.height / 2.0)
	add_child(player)

func _unhandled_input(event: InputEvent) -> void:
	if over:
		return
	if event is InputEventScreenTouch and event.pressed:
		player.move_to(event.position)
		var marker := MoveMarker.new()
		marker.position = event.position
		add_child(marker)

func _process(delta: float) -> void:
	if over:
		return
	elapsed += delta
	player.tick(delta)

func _draw() -> void:
	var a := Config.ARENA
	var bg := Config.BACKGROUND
	var x: float = a.margin
	var y: float = a.margin
	var w: float = a.width - a.margin * 2.0
	var h: float = a.height - a.margin * 2.0

	draw_rect(Rect2(0, 0, a.width, a.height), bg.outer_color)
	draw_rect(Rect2(x, y, w, h), bg.floor_color)

	var gc: Color = bg.grid_color
	gc.a = bg.grid_alpha
	var gx: float = x + bg.grid_size
	while gx < x + w:
		draw_line(Vector2(gx, y), Vector2(gx, y + h), gc, bg.grid_width)
		gx += bg.grid_size
	var gy: float = y + bg.grid_size
	while gy < y + h:
		draw_line(Vector2(x, gy), Vector2(x + w, gy), gc, bg.grid_width)
		gy += bg.grid_size

	var steps := 6
	for i in steps:
		var inset := (float(i) / steps) * 90.0
		var vc: Color = bg.vignette_color
		vc.a = (bg.vignette_alpha / steps) * (steps - i)
		draw_rect(Rect2(x + inset, y + inset, w - inset * 2.0, h - inset * 2.0), vc, false, 18.0)

	draw_rect(Rect2(x, y, w, h), a.border_color, false, a.border_width)
```

`godot/scenes/game.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/game.gd" id="1"]

[node name="Game" type="Node2D"]
script = ExtResource("1")
```

In `godot/project.godot` set `run/main_scene="res://scenes/game.tscn"`, then `git rm godot/scenes/main.tscn`.

- [ ] **Step 4: Run tests, verify pass.**

- [ ] **Step 5: Visual check** — run `& $GODOT --path godot` : dark arena with grid and vignette, blue dot centered, click moves it with a green shrinking ping, dot stops at destination and clamps at walls. Close the window.

- [ ] **Step 6: Commit** — `git add -A godot; git commit -m "feat(godot): game scene with arena drawing and tap-to-move"`

---

### Task 4: Spawner + Bolt + HUD + death stub

**Files:**
- Create: `godot/scripts/spawner.gd`, `godot/scripts/bolt.gd`
- Modify: `godot/scripts/game.gd`
- Test: `godot/tests/test_runner.gd` (append)

**Interfaces:**
- Consumes: `Config`, `Player`, `game.gd` from earlier tasks.
- Produces: `Spawner` (RefCounted): `_init(difficulty: Dictionary)`, `tick(delta: float, player_pos: Vector2) -> Array` of orders `{type: "bolt"|"beam", origin: Vector2, dir: Vector2}`, `current_interval() -> float`, `var dodged: int`, `var elapsed: float`, `var rng: RandomNumberGenerator`. `Bolt` (Node2D): `setup(origin, dir, speed)`, `tick(delta)`, `is_off_arena() -> bool`, `hits(player_pos) -> bool`. `game.gd` gains `_die()`, `_check_hit(hit: bool) -> bool`, `var shield`, `var invuln_left`, arrays `bolts`, `beams`, HUD labels.

- [ ] **Step 1: Append failing tests**

```gdscript
func test_spawner_interval_ramps_to_floor() -> void:
	var s := Spawner.new(Config.DIFFICULTIES.normal)
	check(s.current_interval() == 1.0, "starts at spawn_interval")
	s.elapsed = 20.0
	check(abs(s.current_interval() - 0.76) < 0.0001, "ramped by 0.012/s")
	s.elapsed = 10000.0
	check(s.current_interval() == 0.48, "clamped at min interval")

func test_spawner_emits_orders_from_outside_arena() -> void:
	var s := Spawner.new(Config.DIFFICULTIES.easy)
	s.rng.seed = 42
	var orders := s.tick(3.0, Vector2(640, 360))
	check(orders.size() >= 2, "several orders after 3s of easy")
	for o in orders:
		var inside: bool = o.origin.x > Config.ARENA.margin \
			and o.origin.x < Config.ARENA.width - Config.ARENA.margin \
			and o.origin.y > Config.ARENA.margin \
			and o.origin.y < Config.ARENA.height - Config.ARENA.margin
		check(not inside, "origin outside the arena")
		check(abs(o.dir.length() - 1.0) < 0.001, "dir normalized")

func test_bolt_flight_and_hit() -> void:
	var b := Bolt.new()
	add_child(b)
	b.setup(Vector2(0, 360), Vector2.RIGHT, 400.0)
	b.tick(1.0)
	check(b.position == Vector2(400, 360), "bolt moved 400px in 1s")
	check(b.hits(Vector2(410, 360)), "hit inside combined radii")
	check(not b.hits(Vector2(500, 360)), "no hit far away")
	check(not b.is_off_arena(), "still on arena")
	b.position = Vector2(1500, 360)
	check(b.is_off_arena(), "off arena when far past the edge")
	b.queue_free()
```

- [ ] **Step 2: Run tests, verify failure** — `Spawner` / `Bolt` not declared.

- [ ] **Step 3: Implement**

`godot/scripts/spawner.gd`:

```gdscript
class_name Spawner
extends RefCounted
# Pure spawn logic: decides WHEN and FROM WHERE skillshots appear.
# The game scene turns the returned orders into Bolt/Beam nodes.

var diff: Dictionary
var elapsed := 0.0
var since_spawn := 0.0
var dodged := 0
var rng := RandomNumberGenerator.new()

func _init(difficulty: Dictionary) -> void:
	diff = difficulty

func current_interval() -> float:
	return maxf(diff.spawn_interval_min, diff.spawn_interval - diff.ramp_per_second * elapsed)

func tick(delta: float, player_pos: Vector2) -> Array:
	elapsed += delta
	since_spawn += delta
	var orders: Array = []
	while since_spawn >= current_interval():
		since_spawn -= current_interval()
		orders.append(_make_order(player_pos))
	return orders

func _make_order(player_pos: Vector2) -> Dictionary:
	var origin := _random_edge_point()
	var jitter := deg_to_rad(rng.randf_range(-diff.aim_jitter_deg, diff.aim_jitter_deg))
	var dir := (player_pos - origin).normalized().rotated(jitter)
	var kind := "beam" if rng.randf() < Config.SPAWNER.beam_chance else "bolt"
	return { type = kind, origin = origin, dir = dir }

func _random_edge_point() -> Vector2:
	var a := Config.ARENA
	var inset: float = Config.SPAWNER.edge_inset
	match rng.randi_range(0, 3):
		0: return Vector2(rng.randf_range(0.0, a.width), a.margin - inset)
		1: return Vector2(rng.randf_range(0.0, a.width), a.height - a.margin + inset)
		2: return Vector2(a.margin - inset, rng.randf_range(0.0, a.height))
		_: return Vector2(a.width - a.margin + inset, rng.randf_range(0.0, a.height))
```

`godot/scripts/bolt.gd`:

```gdscript
class_name Bolt
extends Node2D
# Travelling ball skillshot: no telegraph, straight line, kills on contact.

const OFF_ARENA_SLACK := 80.0  # must fully clear the arena to count as dodged

var velocity := Vector2.ZERO

func setup(origin: Vector2, dir: Vector2, speed: float) -> void:
	position = origin
	velocity = dir * speed

func tick(delta: float) -> void:
	position += velocity * delta
	queue_redraw()

func is_off_arena() -> bool:
	var a := Config.ARENA
	return position.x < -OFF_ARENA_SLACK or position.x > a.width + OFF_ARENA_SLACK \
		or position.y < -OFF_ARENA_SLACK or position.y > a.height + OFF_ARENA_SLACK

func hits(player_pos: Vector2) -> bool:
	return position.distance_to(player_pos) < Config.BOLT.radius + Config.PLAYER.radius

func _draw() -> void:
	draw_circle(Vector2.ZERO, Config.BOLT.radius, Config.BOLT.color)
	draw_arc(Vector2.ZERO, Config.BOLT.radius, 0.0, TAU, 32, Config.BOLT.glow_color, 3.0)
```

Modify `godot/scripts/game.gd` — replace the whole file with:

```gdscript
extends Node2D
# Gameplay scene: arena, player, projectiles, HUD, death handling.

var player: Player
var spawner: Spawner
var bolts: Array = []
var beams: Array = []
var elapsed := 0.0
var over := false
var shield := false        # armed rewarded shield: absorbs one hit
var invuln_left := 0.0     # seconds of post-revive/post-shield invulnerability
var hud_time: Label
var hud_dodged: Label

func _ready() -> void:
	var a := Config.ARENA
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector2(a.width / 2.0, a.height / 2.0)
	add_child(player)
	spawner = Spawner.new(Config.DIFFICULTIES.normal)
	_build_hud()

func _build_hud() -> void:
	var a := Config.ARENA
	hud_time = Label.new()
	hud_dodged = Label.new()
	for l: Label in [hud_time, hud_dodged]:
		l.add_theme_font_size_override("font_size", 24)
		l.add_theme_color_override("font_color", Config.MENU.text_color)
		add_child(l)
	hud_time.position = Vector2(a.margin + 8.0, a.margin + 8.0)
	hud_dodged.position = Vector2(a.margin + 8.0, a.margin + 40.0)

func _unhandled_input(event: InputEvent) -> void:
	if over:
		return
	if event is InputEventScreenTouch and event.pressed:
		player.move_to(event.position)
		var marker := MoveMarker.new()
		marker.position = event.position
		add_child(marker)

func _process(delta: float) -> void:
	if over:
		return
	elapsed += delta
	if invuln_left > 0.0:
		invuln_left = maxf(0.0, invuln_left - delta)
	player.shield_visual = shield
	player.tick(delta)
	for order in spawner.tick(delta, player.position):
		_spawn(order)
	_tick_projectiles(delta)
	hud_time.text = "Time: %.1fs" % elapsed
	hud_dodged.text = "Dodged: %d" % spawner.dodged

func _spawn(order: Dictionary) -> void:
	if order.type == "bolt":
		var b := Bolt.new()
		b.setup(order.origin, order.dir, spawner.diff.projectile_speed)
		add_child(b)
		bolts.append(b)
	# "beam" orders are handled in the beam task

func _tick_projectiles(delta: float) -> void:
	for b in bolts.duplicate():
		b.tick(delta)
		if _check_hit(b.hits(player.position)):
			bolts.erase(b)
			b.queue_free()
			if over:
				return
		elif b.is_off_arena():
			spawner.dodged += 1
			bolts.erase(b)
			b.queue_free()

# Resolves a potential hit. Returns true when the projectile was consumed
# (absorbed by the shield or lethal).
func _check_hit(hit: bool) -> bool:
	if not hit or invuln_left > 0.0:
		return false
	if shield:
		shield = false
		invuln_left = Config.REWARDS.shield_invuln_sec
		return true
	_die()
	return true

func _die() -> void:
	over = true
	# Death overlay + monetization hooks arrive in later tasks.

func _draw() -> void:
	var a := Config.ARENA
	var bg := Config.BACKGROUND
	var x: float = a.margin
	var y: float = a.margin
	var w: float = a.width - a.margin * 2.0
	var h: float = a.height - a.margin * 2.0

	draw_rect(Rect2(0, 0, a.width, a.height), bg.outer_color)
	draw_rect(Rect2(x, y, w, h), bg.floor_color)

	var gc: Color = bg.grid_color
	gc.a = bg.grid_alpha
	var gx: float = x + bg.grid_size
	while gx < x + w:
		draw_line(Vector2(gx, y), Vector2(gx, y + h), gc, bg.grid_width)
		gx += bg.grid_size
	var gy: float = y + bg.grid_size
	while gy < y + h:
		draw_line(Vector2(x, gy), Vector2(x + w, gy), gc, bg.grid_width)
		gy += bg.grid_size

	var steps := 6
	for i in steps:
		var inset := (float(i) / steps) * 90.0
		var vc: Color = bg.vignette_color
		vc.a = (bg.vignette_alpha / steps) * (steps - i)
		draw_rect(Rect2(x + inset, y + inset, w - inset * 2.0, h - inset * 2.0), vc, false, 18.0)

	draw_rect(Rect2(x, y, w, h), a.border_color, false, a.border_width)
```

- [ ] **Step 4: Run tests, verify pass** (all previous tests must still pass — `test_game_scene_boots` exercises the new `_process`).

- [ ] **Step 5: Visual check** — `& $GODOT --path godot`: red bolts fly in from the edges toward you, HUD counts time and dodges, getting hit freezes the game.

- [ ] **Step 6: Commit** — `git add godot; git commit -m "feat(godot): spawner, bolt skillshot, HUD, death stub"`

---

### Task 5: Beam skillshot

**Files:**
- Create: `godot/scripts/beam.gd`
- Modify: `godot/scripts/game.gd` (`_spawn`, `_tick_projectiles`)
- Test: `godot/tests/test_runner.gd` (append)

**Interfaces:**
- Consumes: `Config.BEAM`, `game.gd` arrays from Task 4.
- Produces: `Beam` (Node2D): `setup(origin, dir)`, `tick(delta)`, `is_done() -> bool`, `can_damage() -> bool`, `hits(player_pos) -> bool`, `var did_hit: bool`.

- [ ] **Step 1: Append failing tests**

```gdscript
func test_beam_lifecycle_and_damage_window() -> void:
	var bm := Beam.new()
	add_child(bm)
	bm.setup(Vector2(0, 360), Vector2.RIGHT)
	bm.tick(0.5)
	check(not bm.can_damage(), "telegraph phase can't damage")
	check(not bm.hits(Vector2(200, 360)), "no hit during telegraph")
	bm.tick(0.55)  # age 1.05: fired, inside 0.08s damage window
	check(bm.can_damage(), "damage window open right after firing")
	check(bm.hits(Vector2(200, 360)), "on-axis player is hit")
	check(not bm.hits(Vector2(200, 460)), "player 100px off-axis is safe")
	bm.tick(0.1)   # age 1.15: window closed, beam still fading
	check(not bm.can_damage(), "damage window closed")
	check(not bm.is_done(), "still fading")
	bm.tick(0.4)   # age 1.55 > 1.5
	check(bm.is_done(), "gone after telegraph + active duration")
	bm.queue_free()
```

- [ ] **Step 2: Run tests, verify failure** — `Beam` not declared.

- [ ] **Step 3: Implement**

`godot/scripts/beam.gd`:

```gdscript
class_name Beam
extends Node2D
# Telegraphed laser: thin red warning line, then an instant fat white beam
# on the same axis with a short damage window, then it fades out.

const LENGTH := 2200.0  # long enough to cross the arena from any edge

var dir := Vector2.RIGHT
var age := 0.0
var fired := false
var did_hit := false

func setup(origin: Vector2, direction: Vector2) -> void:
	position = origin
	dir = direction.normalized()

func tick(delta: float) -> void:
	age += delta
	if not fired and age >= Config.BEAM.telegraph_duration:
		fired = true
	queue_redraw()

func is_done() -> bool:
	return age >= Config.BEAM.telegraph_duration + Config.BEAM.active_duration

func can_damage() -> bool:
	return fired and age <= Config.BEAM.telegraph_duration + Config.BEAM.damage_window

func hits(player_pos: Vector2) -> bool:
	if not can_damage():
		return false
	var to_p := player_pos - position
	var along := clampf(to_p.dot(dir), 0.0, LENGTH)
	var closest := position + dir * along
	var half_width: float = Config.BEAM.telegraph_width * Config.BEAM.width_multiplier / 2.0
	return closest.distance_to(player_pos) < half_width + Config.PLAYER.radius

func _draw() -> void:
	var b := Config.BEAM
	var endp := dir * LENGTH
	if not fired:
		var c: Color = b.telegraph_color
		c.a = b.telegraph_alpha
		draw_line(Vector2.ZERO, endp, c, b.telegraph_width)
	else:
		var t: float = (age - b.telegraph_duration) / b.active_duration
		var c: Color = b.beam_color
		c.a = b.beam_alpha * (1.0 - clampf(t, 0.0, 1.0))
		draw_line(Vector2.ZERO, endp, c, b.telegraph_width * b.width_multiplier)
```

In `game.gd`, replace the `# "beam" orders...` comment in `_spawn` with:

```gdscript
	else:
		var bm := Beam.new()
		bm.setup(order.origin, order.dir)
		add_child(bm)
		beams.append(bm)
```

Append to `_tick_projectiles`:

```gdscript
	for bm in beams.duplicate():
		bm.tick(delta)
		if _check_hit(bm.hits(player.position)):
			bm.did_hit = true
			if over:
				return
		if bm.is_done():
			if not bm.did_hit:
				spawner.dodged += 1
			beams.erase(bm)
			bm.queue_free()
```

- [ ] **Step 4: Run tests, verify pass.**

- [ ] **Step 5: Visual check** — `& $GODOT --path godot`: occasionally a thin red line telegraphs, one second later a fat white beam flashes and fades; standing on the line when it fires kills you.

- [ ] **Step 6: Commit** — `git add godot; git commit -m "feat(godot): beam skillshot with telegraph and damage window"`

---

### Task 6: Menus, difficulty select, death overlay, scene flow

**Files:**
- Create: `godot/autoload/session.gd`, `godot/scripts/ui_kit.gd`, `godot/scripts/menu.gd`, `godot/scenes/menu.tscn`, `godot/scripts/difficulty.gd`, `godot/scenes/difficulty.tscn`
- Modify: `godot/scripts/game.gd` (use `Session.difficulty_key`, real `_die()` overlay), `godot/project.godot` (Session autoload, `run/main_scene="res://scenes/menu.tscn"`)
- Test: `godot/tests/test_runner.gd` (append)

**Interfaces:**
- Consumes: everything so far.
- Produces: `Session` autoload: `var difficulty_key: String = "normal"`, `var shield_pending: bool = false`. `UiKit` statics: `make_button(parent, center, label, on_press, size := Vector2(260, 64), font_size := 26) -> Button`, `make_label(parent, center, text, font_size, color) -> Label`. `game.gd`: `_die()` builds an in-scene death overlay (Retry / Menu); `var death_overlay: Control`.

- [ ] **Step 1: Append failing tests**

```gdscript
func test_session_defaults() -> void:
	check(Session.difficulty_key == "normal", "default difficulty")
	check(Session.shield_pending == false, "no shield pending")

func test_menu_and_difficulty_scenes_boot() -> void:
	for path in ["res://scenes/menu.tscn", "res://scenes/difficulty.tscn"]:
		var s = load(path).instantiate()
		add_child(s)
		s.queue_free()
	check(true, "menu scenes instantiate without crashing")

func test_death_shows_overlay() -> void:
	var g = preload("res://scenes/game.tscn").instantiate()
	add_child(g)
	g._die()
	check(g.over, "game over flag set")
	check(g.death_overlay != null, "death overlay created")
	g.queue_free()
```

- [ ] **Step 2: Run tests, verify failure** — `Session` not declared.

- [ ] **Step 3: Implement**

`godot/autoload/session.gd`:

```gdscript
extends Node
# Cross-scene run state (menu picks it, game consumes it).

var difficulty_key := "normal"
var shield_pending := false   # armed via the rewarded ad in the menu
```

Register in `godot/project.godot` under `[autoload]` (after Config):

```ini
Session="*res://autoload/session.gd"
```

`godot/scripts/ui_kit.gd`:

```gdscript
class_name UiKit
extends Object
# Code-built UI helpers, mirror of the old ui.js makeButton.

static func make_button(parent: Node, center: Vector2, label: String, on_press: Callable,
		size := Vector2(260, 64), font_size := 26) -> Button:
	var b := Button.new()
	b.text = label
	b.size = size
	b.position = center - size / 2.0
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Config.MENU.button_text_color)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Config.MENU.button_color
	sb.border_color = Config.MENU.button_border_color
	sb.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = Config.MENU.button_hover_color
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b

static func make_label(parent: Node, center: Vector2, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(900, 80)
	l.position = center - l.size / 2.0
	parent.add_child(l)
	return l
```

`godot/scripts/menu.gd` (monetization buttons arrive in Task 8):

```gdscript
extends Node2D

func _ready() -> void:
	var a := Config.ARENA
	var bg := ColorRect.new()
	bg.color = Config.MENU.bg_color
	bg.size = Vector2(a.width, a.height)
	add_child(bg)
	var cx: float = a.width / 2.0
	var cy: float = a.height / 2.0
	UiKit.make_label(self, Vector2(cx, cy - 140.0), "DODGE TRAINER", 64, Config.MENU.title_color)
	UiKit.make_label(self, Vector2(cx, cy - 70.0), "Tap to move. Dodge the skillshots.", 22, Config.MENU.subtitle_color)
	UiKit.make_button(self, Vector2(cx, cy + 30.0), "PLAY", func() -> void:
		get_tree().change_scene_to_file("res://scenes/difficulty.tscn"))
```

`godot/scenes/menu.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/menu.gd" id="1"]

[node name="Menu" type="Node2D"]
script = ExtResource("1")
```

`godot/scripts/difficulty.gd`:

```gdscript
extends Node2D

func _ready() -> void:
	var a := Config.ARENA
	var bg := ColorRect.new()
	bg.color = Config.MENU.bg_color
	bg.size = Vector2(a.width, a.height)
	add_child(bg)
	var cx: float = a.width / 2.0
	var cy: float = a.height / 2.0
	UiKit.make_label(self, Vector2(cx, cy - 160.0), "SELECT DIFFICULTY", 48, Config.MENU.title_color)
	var i := 0
	for key in Config.DIFFICULTIES:
		var k: String = key
		UiKit.make_button(self, Vector2(cx, cy - 50.0 + i * 84.0), Config.DIFFICULTIES[k].label, func() -> void:
			Session.difficulty_key = k
			get_tree().change_scene_to_file("res://scenes/game.tscn"))
		i += 1
	UiKit.make_button(self, Vector2(cx, cy + 220.0), "BACK", func() -> void:
		get_tree().change_scene_to_file("res://scenes/menu.tscn"), Vector2(160, 48), 20)
```

`godot/scenes/difficulty.tscn`: same pattern as `menu.tscn` with `res://scripts/difficulty.gd`, root name `Difficulty`.

In `godot/scripts/game.gd`:
- add member `var death_overlay: Control = null`
- in `_ready()` change the spawner line to `spawner = Spawner.new(Config.DIFFICULTIES[Session.difficulty_key])`
- replace `_die()` with:

```gdscript
func _die() -> void:
	over = true
	death_overlay = Control.new()
	death_overlay.size = Vector2(Config.ARENA.width, Config.ARENA.height)
	add_child(death_overlay)
	var dim := ColorRect.new()
	dim.color = Color(Config.MENU.bg_color, 0.92)
	dim.size = death_overlay.size
	death_overlay.add_child(dim)
	var cx: float = Config.ARENA.width / 2.0
	var cy: float = Config.ARENA.height / 2.0
	UiKit.make_label(death_overlay, Vector2(cx, cy - 150.0), "YOU GOT HIT", 56, Color("ff7a70"))
	UiKit.make_label(death_overlay, Vector2(cx, cy - 60.0),
		"Survived %.1fs  •  Dodged %d" % [elapsed, spawner.dodged], 28, Config.MENU.text_color)
	UiKit.make_button(death_overlay, Vector2(cx, cy + 30.0), "RETRY", func() -> void:
		get_tree().reload_current_scene())
	UiKit.make_button(death_overlay, Vector2(cx, cy + 110.0), "MENU", func() -> void:
		get_tree().change_scene_to_file("res://scenes/menu.tscn"), Vector2(200, 52), 22)
```

In `godot/project.godot` set `run/main_scene="res://scenes/menu.tscn"`.

- [ ] **Step 4: Run tests, verify pass.**

- [ ] **Step 5: Visual check** — `& $GODOT --path godot`: menu → PLAY → difficulty pick → game; die → overlay with stats; RETRY restarts same difficulty; MENU returns. HARD is visibly faster than EASY.

- [ ] **Step 6: Commit** — `git add godot; git commit -m "feat(godot): menu, difficulty select, death overlay, scene flow"`

---

### Task 7: AdGate + Ads/Iap stub autoloads

**Files:**
- Create: `godot/scripts/ad_gate.gd`, `godot/autoload/ads.gd`, `godot/autoload/iap.gd`
- Modify: `godot/project.godot` (Iap then Ads autoloads — Iap first, Ads reads it)
- Test: `godot/tests/test_runner.gd` (append)

**Interfaces:**
- Consumes: `Config.ADS`.
- Produces: `AdGate` (RefCounted): `_init(launch_sec: float, per: int, grace: float)`, `on_death(now_sec: float, ad_free: bool) -> bool`, `var deaths: int`. `Ads` autoload: `on_player_death()`, `rewarded_available() -> bool`, `show_rewarded(kind: String, on_reward: Callable)` (kind is `"revive"` or `"shield"`; `on_reward` fires only on completed watch — stub grants instantly). `Iap` autoload: `is_ad_free() -> bool`, `purchase_remove_ads()`, persisted at `user://save.cfg`.

- [ ] **Step 1: Append failing tests**

```gdscript
func test_adgate_grace_and_every_third_death() -> void:
	var gate := AdGate.new(1000.0, 3, 300.0)
	# Deaths inside the 300s grace: counted, never shown.
	check(not gate.on_death(1010.0, false), "death 1 in grace")
	check(not gate.on_death(1020.0, false), "death 2 in grace")
	check(not gate.on_death(1030.0, false), "death 3 in grace: still no ad")
	# First death after grace: counter is already >= 3, so it fires and resets.
	check(gate.on_death(1400.0, false), "first post-grace death fires")
	check(gate.deaths == 0, "counter reset after showing")
	check(not gate.on_death(1410.0, false), "1/3")
	check(not gate.on_death(1420.0, false), "2/3")
	check(gate.on_death(1430.0, false), "3/3 fires")

func test_adgate_ad_free_never_fires() -> void:
	var gate := AdGate.new(0.0, 3, 0.0)
	for i in 9:
		check(not gate.on_death(1000.0 + i, true), "ad-free death %d" % i)

func test_ads_and_iap_apis_exist() -> void:
	check(Ads.rewarded_available(), "stub rewarded always available")
	var granted := [false]
	Ads.show_rewarded("shield", func() -> void: granted[0] = true)
	check(granted[0], "stub grants reward immediately")
	check(typeof(Iap.is_ad_free()) == TYPE_BOOL, "is_ad_free returns bool")
```

- [ ] **Step 2: Run tests, verify failure** — `AdGate` not declared.

- [ ] **Step 3: Implement**

`godot/scripts/ad_gate.gd`:

```gdscript
class_name AdGate
extends RefCounted
# Pure interstitial gating: every Nth death, but never inside the
# post-launch grace window and never for ad-free players.
# Deaths keep counting during grace; the first death after grace with a
# full counter shows the ad. Time is injected so tests are deterministic.

var deaths := 0
var _launch_sec: float
var _per: int
var _grace: float

func _init(launch_sec: float, per: int, grace: float) -> void:
	_launch_sec = launch_sec
	_per = per
	_grace = grace

func on_death(now_sec: float, ad_free: bool) -> bool:
	deaths += 1
	if ad_free:
		return false
	if now_sec - _launch_sec < _grace:
		return false
	if deaths >= _per:
		deaths = 0
		return true
	return false
```

`godot/autoload/iap.gd`:

```gdscript
extends Node
# Purchase boundary. Phase-1 stub: "purchase" grants instantly and persists.
# The Play Billing phase replaces purchase_remove_ads() internals only.

const SAVE_PATH := "user://save.cfg"

var _ad_free := false

func _ready() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		_ad_free = cf.get_value("iap", "ad_free", false)

func is_ad_free() -> bool:
	return _ad_free

func purchase_remove_ads() -> void:
	_set_ad_free(true)

func _set_ad_free(v: bool) -> void:
	_ad_free = v
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("iap", "ad_free", v)
	cf.save(SAVE_PATH)
```

`godot/autoload/ads.gd`:

```gdscript
extends Node
# Monetization boundary: game scenes only ever call this API.
# Phase-1 stub logs instead of showing ads; the AdMob phase fills in
# _show_interstitial() and show_rewarded() without changing callers.

var _gate: AdGate

func _ready() -> void:
	_gate = AdGate.new(_now(), Config.ADS.deaths_per_interstitial, Config.ADS.launch_grace_sec)

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

# Call exactly once per player death, after the death overlay is up.
func on_player_death() -> void:
	if _gate.on_death(_now(), Iap.is_ad_free()):
		_show_interstitial()

func rewarded_available() -> bool:
	return true

# kind: "revive" | "shield". on_reward runs only after a completed watch.
func show_rewarded(kind: String, on_reward: Callable) -> void:
	print("[Ads] rewarded ad (stub, auto-granted): ", kind)
	on_reward.call()

func _show_interstitial() -> void:
	print("[Ads] interstitial would show now (stub)")
```

`godot/project.godot` `[autoload]` section becomes (order matters — Ads reads Iap):

```ini
[autoload]

Config="*res://autoload/config.gd"
Session="*res://autoload/session.gd"
Iap="*res://autoload/iap.gd"
Ads="*res://autoload/ads.gd"
```

- [ ] **Step 4: Run tests, verify pass.**

- [ ] **Step 5: Commit** — `git add godot; git commit -m "feat(godot): ad gating logic + Ads/Iap stub singletons"`

---

### Task 8: Wire monetization into the game

**Files:**
- Modify: `godot/scripts/game.gd` (interstitial + revive), `godot/scripts/menu.gd` (shield + remove-ads buttons)
- Test: `godot/tests/test_runner.gd` (append)

**Interfaces:**
- Consumes: `Ads`, `Iap`, `Session`, `game.gd` internals from Tasks 4–7.
- Produces: `game.gd` gains `var revive_used: bool` and `_revive()`; death overlay gains a `REVIVE (AD)` button (once per run). Menu gains `START WITH SHIELD (AD)` and `REMOVE ADS — $4.99` buttons.

- [ ] **Step 1: Append failing tests**

```gdscript
func test_shield_absorbs_one_hit() -> void:
	var g = preload("res://scenes/game.tscn").instantiate()
	add_child(g)
	g.shield = true
	check(g._check_hit(true), "shielded hit consumes the projectile")
	check(not g.over, "shield prevented death")
	check(not g.shield, "shield broke")
	check(g.invuln_left > 0.0, "post-shield invulnerability granted")
	g.invuln_left = 0.0
	check(g._check_hit(true), "second hit is lethal")
	check(g.over, "dead without shield")
	g.queue_free()

func test_revive_resumes_run_once() -> void:
	var g = preload("res://scenes/game.tscn").instantiate()
	add_child(g)
	g.elapsed = 12.5
	g._die()
	g._revive()
	check(not g.over, "revive resumes play")
	check(g.revive_used, "revive marked used")
	check(g.death_overlay == null, "overlay removed")
	check(g.invuln_left == Config.REWARDS.revive_invuln_sec, "revive invulnerability")
	check(g.elapsed == 12.5, "score/time preserved")
	check(g.bolts.is_empty() and g.beams.is_empty(), "field cleared on revive")
	g.queue_free()

func test_shield_pending_consumed_by_game() -> void:
	Session.shield_pending = true
	var g = preload("res://scenes/game.tscn").instantiate()
	add_child(g)
	check(g.shield, "pending shield armed the run")
	check(not Session.shield_pending, "pending flag consumed")
	g.queue_free()
```

- [ ] **Step 2: Run tests, verify failure** — no `_revive` / `revive_used`.

- [ ] **Step 3: Implement**

In `godot/scripts/game.gd`:
- add member `var revive_used := false`
- in `_ready()`, after creating the spawner, add:

```gdscript
	shield = Session.shield_pending
	Session.shield_pending = false
```

- at the end of `_die()` add the revive button + the interstitial hook:

```gdscript
	if not revive_used and Ads.rewarded_available():
		UiKit.make_button(death_overlay, Vector2(cx, cy + 190.0), "REVIVE (AD)", func() -> void:
			Ads.show_rewarded("revive", _revive), Vector2(280, 52), 22)
	Ads.on_player_death()
```

- add `_revive()`:

```gdscript
# Rewarded-ad revive: resume the same run in place, once per run.
func _revive() -> void:
	revive_used = true
	over = false
	invuln_left = Config.REWARDS.revive_invuln_sec
	for b in bolts:
		b.queue_free()
	bolts.clear()
	for bm in beams:
		bm.queue_free()
	beams.clear()
	death_overlay.queue_free()
	death_overlay = null
```

In `godot/scripts/menu.gd`, add member `var shield_btn: Button` and append to `_ready()`:

```gdscript
	shield_btn = UiKit.make_button(self, Vector2(cx, cy + 120.0), _shield_label(), _on_shield_pressed,
		Vector2(380, 56), 20)
	shield_btn.disabled = Session.shield_pending or not Ads.rewarded_available()
	if not Iap.is_ad_free():
		UiKit.make_button(self, Vector2(cx, cy + 200.0), "REMOVE ADS — $4.99", func() -> void:
			Iap.purchase_remove_ads()
			get_tree().reload_current_scene(), Vector2(380, 56), 20)
```

and the two helpers:

```gdscript
func _shield_label() -> String:
	return "SHIELD ARMED FOR NEXT RUN" if Session.shield_pending else "START WITH SHIELD (AD)"

func _on_shield_pressed() -> void:
	Ads.show_rewarded("shield", func() -> void:
		Session.shield_pending = true
		shield_btn.text = _shield_label()
		shield_btn.disabled = true)
```

- [ ] **Step 4: Run tests, verify pass.**

- [ ] **Step 5: Visual check** — `& $GODOT --path godot`: shield button arms a green ring for the next run and the first hit breaks it; dying shows REVIVE (AD) once per run and continues in place; console prints `[Ads] ...` stub lines (interstitial line only appears after the 3rd death AND 5 minutes after launch — for a quick check temporarily set `launch_grace_sec = 5.0` in `config.gd`, verify, then set it back to `300.0`); REMOVE ADS button disappears after pressing (and stays gone on restart — delete `%APPDATA%\Godot\app_userdata\Dodge Trainer\save.cfg` to reset).

- [ ] **Step 6: Commit** — `git add godot; git commit -m "feat(godot): interstitial gating, revive and shield rewards, remove-ads stub"`

---

### Task 9: Document the Godot project in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Interfaces:** none (docs only).

- [ ] **Step 1: Append a "Godot mobile port" section to `CLAUDE.md`**

```markdown
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
```

- [ ] **Step 2: Commit** — `git add CLAUDE.md; git commit -m "docs: document godot port workflow"`

---

## Out of scope (separate follow-up plans)

1. **Android export:** export templates, keystore, landscape lock verification on device.
2. **AdMob integration:** poing-studios plugin, test ad unit IDs, fill `Ads._show_interstitial()` / `show_rewarded()` internals.
3. **Play Billing:** official plugin, `remove_ads` product, startup purchase query replacing the Iap stub internals.
