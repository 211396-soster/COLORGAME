class_name MiniMap
extends Control
## Minimapa com ruas reais (dados do OpenStreetMap), rota ativa e destino. Gira com o veículo.

var city: City = null
var center: Vector2 = Vector2.ZERO
var yaw: float = 0.0
var route: PackedVector2Array = PackedVector2Array()
var has_target: bool = false
var target: Vector2 = Vector2.ZERO
var range_m: float = 170.0

var _acc: float = 10.0
var _cache: Array = []

func _ready() -> void:
	clip_contents = true

func set_state(c: Vector2, y: float) -> void:
	center = c
	yaw = y

func _process(d: float) -> void:
	_acc += d
	if _acc > 0.12 and city != null and visible:
		_acc = 0.0
		_cache = city.road_segments_near(center, range_m * 1.5)
		queue_redraw()

func _tp(p: Vector2) -> Vector2:
	var rel = p - center
	var f = Vector2(-sin(yaw), -cos(yaw))
	var r = Vector2(cos(yaw), -sin(yaw))
	var sc = size.x * 0.5 / range_m
	return size * 0.5 + Vector2(rel.dot(r), -rel.dot(f)) * sc

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.82, 0.86, 0.8))
	var sc = size.x * 0.5 / range_m
	for s in _cache:
		var a = _tp(Vector2(s[0], s[1]))
		var b = _tp(Vector2(s[2], s[3]))
		var w = clampf(float(s[4]) * sc * 0.9, 2.0, 9.0)
		draw_line(a, b, Color(0.55, 0.58, 0.62), w + 2.0)
	for s in _cache:
		var a = _tp(Vector2(s[0], s[1]))
		var b = _tp(Vector2(s[2], s[3]))
		var w = clampf(float(s[4]) * sc * 0.9, 2.0, 9.0)
		draw_line(a, b, Color(1, 1, 1), w)
	# rota
	if route.size() >= 2:
		var pts = PackedVector2Array()
		for p in route:
			pts.append(_tp(p))
		draw_polyline(pts, Color(0.15, 0.4, 0.95), 5.0)
	# base (loja)
	if city != null:
		var bp = _tp(Vector2(city.store_pos.x, city.store_pos.z))
		draw_rect(Rect2(bp - Vector2(8, 8), Vector2(16, 16)), Color(0.85, 0.1, 0.12))
		draw_rect(Rect2(bp - Vector2(8, 8), Vector2(16, 16)), Color.WHITE, false, 2.0)
	# destino
	if has_target:
		var tp = _tp(target)
		var half = size * 0.5 - Vector2(14, 14)
		var rel = tp - size * 0.5
		if absf(rel.x) > half.x or absf(rel.y) > half.y:
			var k = minf(half.x / maxf(absf(rel.x), 0.01), half.y / maxf(absf(rel.y), 0.01))
			tp = size * 0.5 + rel * k
		draw_circle(tp, 10, Color(0.1, 0.75, 0.3))
		draw_arc(tp, 10, 0, TAU, 20, Color.WHITE, 2.5)
	# veículo (sempre apontando para cima)
	var c = size * 0.5
	var tri = PackedVector2Array([c + Vector2(0, -13), c + Vector2(-9, 10), c + Vector2(9, 10)])
	draw_colored_polygon(tri, Color(1.0, 0.8, 0.1))
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(0.1, 0.1, 0.1), 2.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.25, 0.45, 0.8), false, 4.0)
