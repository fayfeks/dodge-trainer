extends Node
# All gameplay constants live here. Tune freely. (Godot port of src/config.js.)
# Durations are SECONDS, speeds px/sec.

const ARENA := {
	width = 1280.0, height = 720.0,
	margin = 30.0,                      # gap between arena border and canvas edge
	border_color = Color("2a3a52"), border_width = 3.0,
}

const BACKGROUND := {
	outer_color = Color("05070c"),      # base fill behind the arena
	floor_color = Color("111a2b"),
	vignette_color = Color("070b12"), vignette_alpha = 0.55,
	grid_size = 64.0, grid_color = Color("1e2c44"), grid_alpha = 0.6, grid_width = 1.0,
}

const PLAYER := {
	radius = 18.0, move_speed = 300.0, stop_distance = 2.0,
	color = Color("4fc3f7"), outline_color = Color("bde7ff"),
	shadow_squash = 0.45, shadow_alpha = 0.35, shadow_offset_y = 10.0,
}

const MOVE_MARKER := { color = Color("35d07f"), radius = 16.0, squash = 0.45, duration = 0.35 }

const MENU := {
	bg_color = Color("05070c"), title_color = Color("8fd3ff"),
	subtitle_color = Color("6f89a8"), text_color = Color("cfe4ff"),
	button_color = Color("1b2740"), button_hover_color = Color("2a3f66"),
	button_border_color = Color("3a557f"), button_text_color = Color("e8f2ff"),
}

const BOLT := { radius = 15.0, color = Color("ff5a4f"), glow_color = Color("ffb3ad") }

const BEAM := {
	telegraph_width = 7.5, telegraph_color = Color("e01414"), telegraph_alpha = 0.85,
	telegraph_duration = 1.0,           # thin warning line duration
	width_multiplier = 5.0, beam_color = Color("ffffff"), beam_alpha = 0.9,
	active_duration = 0.5,              # fired beam fade-out time
	damage_window = 0.08,               # seconds after firing during which it can hit
}

const SPAWNER := { edge_inset = 40.0, beam_chance = 0.1 }

const DIFFICULTIES := {
	easy   = { label = "EASY",   spawn_interval = 1.4,  spawn_interval_min = 0.7,
			   ramp_per_second = 0.008, projectile_speed = 300.0, aim_jitter_deg = 7.0 },
	normal = { label = "NORMAL", spawn_interval = 1.0,  spawn_interval_min = 0.48,
			   ramp_per_second = 0.012, projectile_speed = 400.0, aim_jitter_deg = 10.0 },
	hard   = { label = "HARD",   spawn_interval = 0.65, spawn_interval_min = 0.32,
			   ramp_per_second = 0.016, projectile_speed = 500.0, aim_jitter_deg = 14.0 },
}

const ADS := {
	deaths_per_interstitial = 3,        # full-screen ad every Nth death
	launch_grace_sec = 300.0,           # no interstitials this long after app launch
}

const REWARDS := {
	revive_invuln_sec = 1.5,            # invulnerability after an ad revive
	shield_invuln_sec = 1.0,            # invulnerability after the shield breaks
}
