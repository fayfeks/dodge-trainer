extends Node
# Monetization boundary: game scenes only ever call this API.
# Phase-1 stub logs instead of showing ads; the AdMob phase fills in
# _show_interstitial() and show_rewarded() without changing callers.

var _gate: AdGate

func _ready() -> void:
	_gate = AdGate.new(_now(), Config.ADS.deaths_per_interstitial, Config.ADS.launch_grace_sec)

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

# Call exactly once per player death, after the death overlay is up.
# AdMob phase: when the gate says an interstitial is due, do NOT show it over
# the death overlay while the rewarded-revive offer is on screen. Defer the
# actual display until the player picks RETRY or MENU; a death the player
# revives out of still counts toward the cadence but shows no interstitial.
func on_player_death() -> void:
	if _gate.on_death(_now(), Iap.is_ad_free()):
		_show_interstitial()

func rewarded_available() -> bool:
	return true

# kind: "revive" | "shield". on_reward runs only after a completed watch.
func show_rewarded(kind: String, on_reward: Callable) -> void:
	print("[Ads] rewarded ad (stub, auto-granted): ", kind)
	on_reward.call()

func _show_interstitial() -> void:
	print("[Ads] interstitial would show now (stub)")
