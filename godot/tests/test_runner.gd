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
