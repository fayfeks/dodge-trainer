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
