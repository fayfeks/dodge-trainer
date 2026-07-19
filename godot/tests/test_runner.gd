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

func _make_player(): # -> Player: (workaround: dynamic return type to avoid parse-time Player lookup)
	var p = preload("res://scenes/player.tscn").instantiate()
	add_child(p)
	p.position = Vector2(640, 360)
	return p

func test_player_moves_at_constant_speed() -> void:
	var p: Node = _make_player() # (workaround: use Node type since Player unavailable at parse time)
	p.move_to(Vector2(940, 360))
	p.tick(0.5)
	check(abs(p.position.x - 790.0) < 0.01, "moved 150px in 0.5s, got x=%f" % p.position.x)
	p.queue_free()

func test_player_snaps_and_stops_at_target() -> void:
	var p: Node = _make_player() # (workaround: use Node type)
	p.move_to(Vector2(650, 360))
	p.tick(1.0)
	check(p.position == Vector2(650, 360), "snapped to target")
	check(p.target == null, "target cleared on arrival")
	p.queue_free()

func test_player_target_clamped_to_arena() -> void:
	var p: Node = _make_player() # (workaround: use Node type)
	p.move_to(Vector2(5000, -5000))
	var a := Config.ARENA
	var r: float = Config.PLAYER.radius
	check(p.target.x == a.width - a.margin - r, "x clamped")
	check(p.target.y == a.margin + r, "y clamped")
	p.queue_free()
