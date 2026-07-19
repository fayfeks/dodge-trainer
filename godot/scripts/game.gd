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
var death_overlay: Control = null

func _ready() -> void:
	var a := Config.ARENA
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector2(a.width / 2.0, a.height / 2.0)
	add_child(player)
	spawner = Spawner.new(Config.DIFFICULTIES[Session.difficulty_key])
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
	else:
		var bm := Beam.new()
		bm.setup(order.origin, order.dir)
		add_child(bm)
		beams.append(bm)

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
