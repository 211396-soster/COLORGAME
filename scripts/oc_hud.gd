class_name OcHud
extends RefCounted
## Elementos de interface desenhados do modo Overcooked: ícones de item, cronômetro, moeda e barra do pedido.

static func paint_color(kind: String) -> Color:
	return OcModels.paint_color(kind)

## Ícone de item (lata/balde/rolo) desenhado em _draw
class Icon extends Control:
	var kind: String = "lata"
	var done: bool = false

	func _init(k: String = "lata", sz: float = 46.0) -> void:
		kind = k
		custom_minimum_size = Vector2(sz, sz)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s = minf(size.x, size.y)
		var o = Vector2(size.x * 0.5 - s * 0.5, 0)
		# fundo redondo claro
		draw_circle(o + Vector2(s, s) * 0.5, s * 0.5, Color(0.88, 0.93, 0.96))
		var c = o + Vector2(s, s) * 0.5
		match kind:
			"azul", "verm", "amar", "azul_c", "verm_c", "amar_c", "lata":
				var col = OcModels.paint_color(kind)
				var body = Rect2(c.x - s * 0.2, c.y - s * 0.2, s * 0.4, s * 0.42)
				draw_rect(body, Color(0.78, 0.8, 0.84))
				if kind != "lata":
					draw_rect(Rect2(body.position.x, body.position.y + s * 0.08, body.size.x, s * 0.24), col)
				else:
					draw_rect(Rect2(body.position.x, body.position.y + s * 0.08, body.size.x, s * 0.24), Color(0.95, 0.95, 0.97))
				draw_rect(Rect2(body.position.x - s * 0.02, body.position.y - s * 0.04, body.size.x + s * 0.04, s * 0.07), Color(0.55, 0.57, 0.62))
				draw_arc(c + Vector2(0, -s * 0.2), s * 0.17, PI, TAU, 10, Color(0.35, 0.36, 0.4), 2.0)
			"massa":
				var pts = PackedVector2Array([c + Vector2(-s * 0.2, -s * 0.12), c + Vector2(s * 0.2, -s * 0.12), c + Vector2(s * 0.16, s * 0.22), c + Vector2(-s * 0.16, s * 0.22)])
				draw_colored_polygon(pts, Color(0.98, 0.8, 0.1))
				draw_rect(Rect2(c.x - s * 0.23, c.y - s * 0.2, s * 0.46, s * 0.1), Color(0.97, 0.97, 0.97))
			_:
				draw_rect(Rect2(c.x - s * 0.24, c.y - s * 0.2, s * 0.44, s * 0.17), Color(0.9, 0.3, 0.1))
				draw_line(c + Vector2(s * 0.2, -s * 0.12), c + Vector2(s * 0.26, -s * 0.12), Color(0.5, 0.5, 0.55), 2.0)
				draw_line(c + Vector2(s * 0.26, -s * 0.12), c + Vector2(s * 0.26, s * 0.0), Color(0.5, 0.5, 0.55), 2.0)
				draw_line(c + Vector2(s * 0.26, 0), c + Vector2(s * 0.0, 0), Color(0.5, 0.5, 0.55), 2.0)
				draw_line(c + Vector2(0, 0), c + Vector2(0, s * 0.26), Color(0.15, 0.3, 0.7), 4.0)
		if done:
			draw_circle(o + Vector2(s, s) * 0.5, s * 0.5, Color(0.2, 0.75, 0.3, 0.75))
			draw_line(c + Vector2(-s * 0.18, 0), c + Vector2(-s * 0.04, s * 0.14), Color.WHITE, 4.0)
			draw_line(c + Vector2(-s * 0.04, s * 0.14), c + Vector2(s * 0.2, -s * 0.14), Color.WHITE, 4.0)

## barra de progresso do pedido (verde -> amarelo -> vermelho)
class Bar extends Control:
	var frac: float = 1.0

	func _init() -> void:
		custom_minimum_size = Vector2(120, 14)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r = Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.78, 0.8, 0.82))
		var col = Color(0.3, 0.8, 0.25)
		if frac < 0.5:
			col = Color(0.98, 0.78, 0.1)
		if frac < 0.22:
			col = Color(0.9, 0.2, 0.15)
		draw_rect(Rect2(0, 0, size.x * clampf(frac, 0.0, 1.0), size.y), col)

## cronômetro estilo Overcooked
class Clock extends Control:
	var frac: float = 1.0
	var text: String = "02:30"

	func _init() -> void:
		custom_minimum_size = Vector2(112, 112)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c = size * 0.5
		var r = minf(size.x, size.y) * 0.5 - 6.0
		draw_circle(c + Vector2(3, 5), r, Color(0, 0, 0, 0.3))
		draw_rect(Rect2(c.x - 8, c.y - r - 9, 16, 9), Color(0.7, 0.72, 0.78))
		draw_circle(c, r, Color(0.78, 0.8, 0.86))
		draw_circle(c, r - 5, Color(0.97, 0.97, 0.98))
		var col = Color(0.3, 0.75, 0.3)
		if frac < 0.5:
			col = Color(0.98, 0.7, 0.1)
		if frac < 0.2:
			col = Color(0.9, 0.2, 0.15)
		draw_arc(c, r - 10, -PI * 0.5, -PI * 0.5 + TAU * clampf(frac, 0.0, 1.0), 40, col, 7.0)
		var font = ThemeDB.fallback_font
		var fs = 26
		var ts = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string_outline(font, c + Vector2(-ts.x * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(1, 1, 1))
		draw_string(font, c + Vector2(-ts.x * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.15, 0.15, 0.2))

## moeda dourada com a pontuação
class Coin extends Control:
	var text: String = "0"

	func _init() -> void:
		custom_minimum_size = Vector2(120, 78)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c = Vector2(42, size.y * 0.5)
		var pts = PackedVector2Array()
		for k in range(8):
			var a = TAU * (k + 0.5) / 8.0
			pts.append(c + Vector2(cos(a), sin(a)) * 36.0)
		var sh = PackedVector2Array()
		for p in pts:
			sh.append(p + Vector2(2, 4))
		draw_colored_polygon(sh, Color(0, 0, 0, 0.3))
		draw_colored_polygon(pts, Color(0.88, 0.62, 0.08))
		var inner = PackedVector2Array()
		for k in range(8):
			var a = TAU * (k + 0.5) / 8.0
			inner.append(c + Vector2(cos(a), sin(a)) * 28.0)
		draw_colored_polygon(inner, Color(0.99, 0.82, 0.2))
		var font = ThemeDB.fallback_font
		var fs = 30
		draw_string_outline(font, Vector2(c.x - 9, c.y + 10), "R$", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, Color(0.55, 0.35, 0.02))
		draw_string(font, Vector2(c.x - 9, c.y + 10), "R$", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
		draw_string_outline(font, Vector2(c.x + 40, c.y + 11), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0.35, 0.2, 0.0))
		draw_string(font, Vector2(c.x + 40, c.y + 11), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.88, 0.3))
