class_name TouchUI
extends Control
## Controles de toque multitoque: joystick flutuante (esquerda), arrasto para olhar (direita)
## e botões redondos. No PC funciona com teclado (WASD/setas + teclas dos botões).

var move: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var use_joystick: bool = true
var use_look: bool = false
var buttons: Dictionary = {}

var _stick_touch: int = -1
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_pos: Vector2 = Vector2.ZERO
var _look_touch: int = -1
var _touch_mode: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_mode = DisplayServer.is_touchscreen_available()

## frac = posição em fração da tela (0..1); r = raio em px (base 720p)
func add_button(bname: String, frac: Vector2, r: float, text: String, col: Color, key: int = 0) -> void:
	buttons[bname] = {"frac": frac, "r": r, "label": text, "color": col, "down": false,
		"pressed": false, "touch": -1, "key": key, "visible": true}

func set_label(bname: String, text: String) -> void:
	if buttons.has(bname):
		buttons[bname]["label"] = text

func set_visible_button(bname: String, v: bool) -> void:
	if buttons.has(bname):
		buttons[bname]["visible"] = v
		if not v:
			buttons[bname]["down"] = false

func is_down(bname: String) -> bool:
	return buttons.has(bname) and buttons[bname]["down"]

func consume(bname: String) -> bool:
	if buttons.has(bname) and buttons[bname]["pressed"]:
		buttons[bname]["pressed"] = false
		return true
	return false

func take_look() -> Vector2:
	var v = look_delta
	look_delta = Vector2.ZERO
	return v

func _scale() -> float:
	return size.y / 720.0

func _bpos(b: Dictionary) -> Vector2:
	return Vector2(size.x * b["frac"].x, size.y * b["frac"].y)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position, event.relative)
	elif event is InputEventMouseButton and not _touch_mode:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press(99, event.position)
			else:
				_release(99)
	elif event is InputEventMouseMotion and not _touch_mode:
		_drag(99, event.position, event.relative)
	elif event is InputEventKey and event.pressed and not event.echo:
		for n in buttons:
			var b = buttons[n]
			if b["key"] != 0 and b["key"] == event.keycode and b["visible"]:
				b["pressed"] = true

func _press(idx: int, pos: Vector2) -> void:
	var s = _scale()
	for n in buttons:
		var b = buttons[n]
		if not b["visible"] or b["touch"] != -1:
			continue
		if pos.distance_to(_bpos(b)) <= b["r"] * s * 1.2:
			b["touch"] = idx
			b["down"] = true
			b["pressed"] = true
			return
	if use_joystick and pos.x < size.x * 0.5 and _stick_touch == -1:
		_stick_touch = idx
		_stick_origin = pos
		_stick_pos = pos
	elif use_look and pos.x >= size.x * 0.4 and _look_touch == -1:
		_look_touch = idx

func _release(idx: int) -> void:
	for n in buttons:
		var b = buttons[n]
		if b["touch"] == idx:
			b["touch"] = -1
			b["down"] = false
	if idx == _stick_touch:
		_stick_touch = -1
		move = Vector2.ZERO
	if idx == _look_touch:
		_look_touch = -1

func _drag(idx: int, pos: Vector2, rel: Vector2) -> void:
	if idx == _stick_touch:
		var maxr = 90.0 * _scale()
		var v = pos - _stick_origin
		if v.length() > maxr:
			v = v.normalized() * maxr
		_stick_pos = _stick_origin + v
		move = v / maxr
	elif idx == _look_touch:
		look_delta += rel
	elif not _touch_mode and idx == 99 and use_look and _look_touch == -1 and _stick_touch == -1:
		pass

func _process(_d: float) -> void:
	# teclado (testes no PC)
	if _stick_touch == -1:
		var k = Vector2.ZERO
		if use_joystick:
			if Input.is_key_pressed(KEY_A): k.x -= 1
			if Input.is_key_pressed(KEY_D): k.x += 1
			if Input.is_key_pressed(KEY_W): k.y -= 1
			if Input.is_key_pressed(KEY_S): k.y += 1
		move = k.normalized() if k.length() > 0.0 else Vector2.ZERO
	for n in buttons:
		var b = buttons[n]
		if b["key"] != 0 and b["visible"]:
			var kd = Input.is_key_pressed(b["key"])
			if b["touch"] == -1:
				b["down"] = kd
	queue_redraw()

func _draw() -> void:
	var s = _scale()
	var font = ThemeDB.fallback_font
	if use_joystick:
		var o = _stick_origin if _stick_touch != -1 else Vector2(size.x * 0.14, size.y * 0.74)
		var kp = _stick_pos if _stick_touch != -1 else o
		draw_circle(o, 90 * s, Color(1, 1, 1, 0.10))
		draw_arc(o, 90 * s, 0, TAU, 40, Color(1, 1, 1, 0.45), 3.0)
		draw_circle(kp, 38 * s, Color(1, 1, 1, 0.35))
		draw_arc(kp, 38 * s, 0, TAU, 28, Color(1, 1, 1, 0.8), 3.0)
	for n in buttons:
		var b = buttons[n]
		if not b["visible"]:
			continue
		var p = _bpos(b)
		var r = b["r"] * s
		var c: Color = b["color"]
		var a = 0.78 if b["down"] else 0.45
		draw_circle(p, r, Color(c.r, c.g, c.b, a))
		draw_arc(p, r, 0, TAU, 40, Color(1, 1, 1, 0.85), 3.0)
		var fs = int(clamp(r * 0.5, 14, 34))
		draw_string(font, p + Vector2(-r, fs * 0.35), b["label"], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, Color.WHITE)
