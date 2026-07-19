class_name AdGate
extends RefCounted
# Pure interstitial gating: every Nth death, but never inside the
# post-launch grace window and never for ad-free players.
# Deaths keep counting during grace; the first death after grace with a
# full counter shows the ad. Time is injected so tests are deterministic.

var deaths := 0
var _launch_sec: float
var _per: int
var _grace: float

func _init(launch_sec: float, per: int, grace: float) -> void:
	_launch_sec = launch_sec
	_per = per
	_grace = grace

func on_death(now_sec: float, ad_free: bool) -> bool:
	deaths += 1
	if ad_free:
		return false
	if now_sec - _launch_sec < _grace:
		return false
	if deaths >= _per:
		deaths = 0
		return true
	return false
