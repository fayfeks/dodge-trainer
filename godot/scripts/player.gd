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
