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
