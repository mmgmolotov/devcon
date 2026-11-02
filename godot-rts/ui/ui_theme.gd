class_name UITheme
extends RefCounted
## Shared medieval UI theme (wood panels, gold trim, serif font) used by the
## in-game HUD and the main menu.

const PARCHMENT := Color(0.98, 0.92, 0.78)
const GOLD := Color(0.83, 0.66, 0.32)
const WOOD_BG := Color(0.2, 0.13, 0.08, 0.95)
const TITLE := Color(1.0, 0.86, 0.5)


static func framed(bg: Color, border: Color, border_w: int, radius: int, margin: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


static func serif() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif", "Liberation Serif", "serif"])
	font.font_weight = 600
	return font


static func build(font_size := 22) -> Theme:
	var t := Theme.new()
	t.default_font_size = font_size
	t.default_font = serif()
	var panel := framed(WOOD_BG, GOLD, 3, 6, 8)
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 6
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_color("font_color", "Label", PARCHMENT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	t.set_constant("outline_size", "Label", 4)
	t.set_stylebox("normal", "Button", framed(Color(0.36, 0.24, 0.13), GOLD.darkened(0.15), 2, 8, 6))
	t.set_stylebox("hover", "Button", framed(Color(0.43, 0.29, 0.16), GOLD, 2, 8, 6))
	t.set_stylebox("pressed", "Button", framed(Color(0.55, 0.38, 0.17), Color(1.0, 0.85, 0.45), 3, 8, 6))
	t.set_stylebox("disabled", "Button", framed(Color(0.2, 0.16, 0.12), Color(0.4, 0.35, 0.3), 2, 8, 6))
	t.set_stylebox("hover_pressed", "Button", framed(Color(0.55, 0.38, 0.17), Color(1.0, 0.85, 0.45), 3, 8, 6))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", PARCHMENT)
	t.set_color("font_hover_color", "Button", Color(1, 0.97, 0.88))
	t.set_color("font_pressed_color", "Button", Color(1, 0.95, 0.75))
	t.set_color("font_hover_pressed_color", "Button", Color(1, 0.95, 0.75))
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.5, 0.45))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "Button", 3)
	t.set_stylebox("background", "ProgressBar", framed(Color(0.08, 0.05, 0.03), GOLD.darkened(0.3), 1, 3, 0))
	t.set_stylebox("fill", "ProgressBar", framed(Color(0.3, 0.75, 0.3), Color(0, 0, 0, 0), 0, 3, 0))
	# Sliders (settings).
	var track := framed(Color(0.1, 0.07, 0.04), GOLD.darkened(0.3), 1, 4, 0)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", framed(GOLD.darkened(0.2), Color(0, 0, 0, 0), 0, 4, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", framed(GOLD, Color(0, 0, 0, 0), 0, 4, 0))
	return t


static func button(text: String, min_size: Vector2, cb: Callable, font_size := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	if font_size > 0:
		b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(func(): Sound.play("click", null, -8.0))
	b.pressed.connect(cb)
	return b


static func label(text: String, size := 0, color := Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	return l


## A labelled volume slider bound to Sound.
static func volume_slider(caption: String, music: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var l := label(caption, 22)
	l.custom_minimum_size.x = 120
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.custom_minimum_size = Vector2(300, 40)
	s.value = Sound.music_volume if music else Sound.sfx_volume
	s.value_changed.connect(func(v):
		if music:
			Sound.set_volumes(v, Sound.sfx_volume)
		else:
			Sound.set_volumes(Sound.music_volume, v)
			Sound.play("click", null, -6.0))
	row.add_child(s)
	return row
