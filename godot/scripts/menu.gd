extends Node2D

var shield_btn: Button

func _ready() -> void:
	var a := Config.ARENA
	var bg := ColorRect.new()
	bg.color = Config.MENU.bg_color
	bg.size = Vector2(a.width, a.height)
	add_child(bg)
	var cx: float = a.width / 2.0
	var cy: float = a.height / 2.0
	UiKit.make_label(self, Vector2(cx, cy - 140.0), "DODGE TRAINER", 64, Config.MENU.title_color)
	UiKit.make_label(self, Vector2(cx, cy - 70.0), "Tap to move. Dodge the skillshots.", 22, Config.MENU.subtitle_color)
	UiKit.make_button(self, Vector2(cx, cy + 30.0), "PLAY", func() -> void:
		get_tree().change_scene_to_file("res://scenes/difficulty.tscn"))
	shield_btn = UiKit.make_button(self, Vector2(cx, cy + 120.0), _shield_label(), _on_shield_pressed,
		Vector2(380, 56), 20)
	shield_btn.disabled = Session.shield_pending or not Ads.rewarded_available()
	if not Iap.is_ad_free():
		UiKit.make_button(self, Vector2(cx, cy + 200.0), "REMOVE ADS — $4.99", func() -> void:
			Iap.purchase_remove_ads()
			get_tree().reload_current_scene(), Vector2(380, 56), 20)

func _shield_label() -> String:
	return "SHIELD ARMED FOR NEXT RUN" if Session.shield_pending else "START WITH SHIELD (AD)"

func _on_shield_pressed() -> void:
	Ads.show_rewarded("shield", func() -> void:
		Session.shield_pending = true
		shield_btn.text = _shield_label()
		shield_btn.disabled = true)
