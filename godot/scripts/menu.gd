extends Node2D

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
