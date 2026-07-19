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

func test_game_scene_boots() -> void:
	var g = preload("res://scenes/game.tscn").instantiate()
	add_child(g)
	g._process(0.016)
	check(g.player is Player, "game has a player")
	check(g.player.position == Vector2(640, 360), "player starts centered")
	g.queue_free()

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

func test_beam_lifecycle_and_damage_window() -> void:
	var bm = Beam.new()
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
