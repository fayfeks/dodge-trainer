extends Node
# Purchase boundary. Phase-1 stub: "purchase" grants instantly and persists.
# The Play Billing phase replaces purchase_remove_ads() internals only.

const SAVE_PATH := "user://save.cfg"

var _ad_free := false

func _ready() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		_ad_free = cf.get_value("iap", "ad_free", false)

func is_ad_free() -> bool:
	return _ad_free

func purchase_remove_ads() -> void:
	_set_ad_free(true)

func _set_ad_free(v: bool) -> void:
	_ad_free = v
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("iap", "ad_free", v)
	cf.save(SAVE_PATH)
