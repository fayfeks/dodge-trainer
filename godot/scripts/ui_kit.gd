class_name UiKit
extends Object
# Code-built UI helpers, mirror of the old ui.js makeButton.

static func make_button(parent: Node, center: Vector2, label: String, on_press: Callable,
		size := Vector2(260, 64), font_size := 26) -> Button:
	var b := Button.new()
	b.text = label
	b.size = size
	b.position = center - size / 2.0
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Config.MENU.button_text_color)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Config.MENU.button_color
	sb.border_color = Config.MENU.button_border_color
	sb.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", sb)
	var sbh: StyleBoxFlat = sb.duplicate()
	sbh.bg_color = Config.MENU.button_hover_color
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b

static func make_label(parent: Node, center: Vector2, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(900, 80)
	l.position = center - l.size / 2.0
	parent.add_child(l)
	return l
