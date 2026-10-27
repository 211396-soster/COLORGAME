class_name UIKit
extends RefCounted
## Estilo visual da interface (azul-marinho + amarelo, como no conceito).

const NAVY = Color(0.05, 0.10, 0.20, 0.88)
const EDGE = Color(0.25, 0.45, 0.8, 0.9)
const YELLOW = Color(1.0, 0.8, 0.12)
const RED = Color(0.86, 0.12, 0.12)

static func style(bg: Color = NAVY, border: Color = EDGE, radius: int = 14, bw: int = 2) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

static func panel(bg: Color = NAVY, border: Color = EDGE) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(bg, border))
	return p

static func label(text: String, size: int = 22, color: Color = Color.WHITE) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	return l

static func button(text: String, size: int = 26, accent: Color = Color(0.12, 0.22, 0.45)) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", YELLOW)
	b.add_theme_color_override("font_pressed_color", YELLOW)
	b.add_theme_stylebox_override("normal", style(accent, EDGE, 10, 2))
	b.add_theme_stylebox_override("hover", style(accent.lightened(0.15), YELLOW, 10, 2))
	b.add_theme_stylebox_override("pressed", style(accent.darkened(0.2), YELLOW, 10, 3))
	b.custom_minimum_size = Vector2(300, 62)
	return b

static func stars_text(n: int, total: int = 3) -> String:
	var s = ""
	for i in range(total):
		s += "★" if i < n else "☆"
	return s

## Menu de pausa (CanvasLayer que funciona com a árvore pausada)
static func make_pause(host: Node) -> CanvasLayer:
	var layer = CanvasLayer.new()
	layer.layer = 50
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.visible = false
	var dim = ColorRect.new()
	dim.color = Color(0, 0.03, 0.1, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var box = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 14)
	layer.add_child(box)
	var t = label("PAUSADO", 44, YELLOW)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var b1 = button("CONTINUAR")
	var b2 = button("REINICIAR")
	var b3 = button("MENU PRINCIPAL")
	box.add_child(b1)
	box.add_child(b2)
	box.add_child(b3)
	b1.pressed.connect(func():
		host.get_tree().paused = false
		layer.visible = false)
	b2.pressed.connect(func():
		host.get_tree().paused = false
		host.get_tree().reload_current_scene())
	b3.pressed.connect(func(): Game.go("menu"))
	host.add_child(layer)
	return layer

static func show_pause(layer: CanvasLayer, host: Node) -> void:
	layer.visible = true
	host.get_tree().paused = true

## Posiciona um Control por âncora (ax, ay em 0..1) com deslocamento em px
static func place(c: Control, ax: float, ay: float, ox: float = 0.0, oy: float = 0.0, gh: int = 2, gv: int = 1) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = ox
	c.offset_right = ox
	c.offset_top = oy
	c.offset_bottom = oy
	c.grow_horizontal = gh
	c.grow_vertical = gv
