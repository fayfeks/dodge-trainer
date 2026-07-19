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
