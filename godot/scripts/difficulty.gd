extends Node2D

func _ready() -> void:
	var a := Config.ARENA
	var bg := ColorRect.new()
	bg.color = Config.MENU.bg_color
	bg.size = Vector2(a.width, a.height)
	add_child(bg)
	var cx: float = a.width / 2.0
	var cy: float = a.height / 2.0
	UiKit.make_label(self, Vector2(cx, cy - 160.0), "SELECT DIFFICULTY", 48, Config.MENU.title_color)
	var i := 0
	for key in Config.DIFFICULTIES:
		var k: String = key
		UiKit.make_button(self, Vector2(cx, cy - 50.0 + i * 84.0), Config.DIFFICULTIES[k].label, func() -> void:
			Session.difficulty_key = k
			get_tree().change_scene_to_file("res://scenes/game.tscn"))
		i += 1
	UiKit.make_button(self, Vector2(cx, cy + 220.0), "BACK", func() -> void:
		get_tree().change_scene_to_file("res://scenes/menu.tscn"), Vector2(160, 48), 20)
