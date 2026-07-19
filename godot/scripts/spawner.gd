class_name Spawner
extends RefCounted
# Pure spawn logic: decides WHEN and FROM WHERE skillshots appear.
# The game scene turns the returned orders into Bolt/Beam nodes.

var diff: Dictionary
var elapsed := 0.0
var since_spawn := 0.0
var dodged := 0
var rng := RandomNumberGenerator.new()

func _init(difficulty: Dictionary) -> void:
	diff = difficulty

func current_interval() -> float:
	return maxf(diff.spawn_interval_min, diff.spawn_interval - diff.ramp_per_second * elapsed)

func tick(delta: float, player_pos: Vector2) -> Array:
	elapsed += delta
	since_spawn += delta
	var orders: Array = []
	while since_spawn >= current_interval():
		since_spawn -= current_interval()
		orders.append(_make_order(player_pos))
	return orders

func _make_order(player_pos: Vector2) -> Dictionary:
	var origin := _random_edge_point()
	var jitter := deg_to_rad(rng.randf_range(-diff.aim_jitter_deg, diff.aim_jitter_deg))
	var dir := (player_pos - origin).normalized().rotated(jitter)
	var kind := "beam" if rng.randf() < Config.SPAWNER.beam_chance else "bolt"
	return { type = kind, origin = origin, dir = dir }

func _random_edge_point() -> Vector2:
	var a := Config.ARENA
	var inset: float = Config.SPAWNER.edge_inset
	match rng.randi_range(0, 3):
		0: return Vector2(rng.randf_range(0.0, a.width), a.margin - inset)
		1: return Vector2(rng.randf_range(0.0, a.width), a.height - a.margin + inset)
		2: return Vector2(a.margin - inset, rng.randf_range(0.0, a.height))
		_: return Vector2(a.width - a.margin + inset, rng.randf_range(0.0, a.height))
