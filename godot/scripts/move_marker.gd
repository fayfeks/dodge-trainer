class_name MoveMarker
extends Node2D
# Tap confirmation: a small dot plus a ring that ripples outward and fades,
# then frees itself.

const SEGMENTS := 48

var _t := 0.0

func _ready() -> void:
	var tw := create_tween()
	tw.tween_method(_set_progress, 0.0, 1.0, Config.MOVE_MARKER.duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(queue_free)

func _set_progress(t: float) -> void:
	_t = t
	queue_redraw()

func _draw() -> void:
	var m := Config.MOVE_MARKER
	var col := Color(m.color, 1.0 - _t)
	var r: float = lerpf(m.ring_start_radius, m.ring_end_radius, _t)
	var d: float = m.dot_radius * (1.0 - _t)
	if d > 0.0:
		draw_colored_polygon(_ellipse(d, m.squash, false), col)
	# Ellipse built from points (not a scaled transform) so line width stays even.
	draw_polyline(_ellipse(r, m.squash, true), col, m.ring_width, true)

func _ellipse(radius: float, squash: float, closed: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := SEGMENTS + (1 if closed else 0)
	for i in n:
		var a := TAU * i / SEGMENTS
		pts.append(Vector2(cos(a) * radius, sin(a) * radius * squash))
	return pts
