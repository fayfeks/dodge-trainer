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
