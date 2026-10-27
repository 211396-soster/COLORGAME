extends Node3D
## Modo 1 - Loja de tintas (estilo Overcooked, câmera isométrica).
## Pegue latas vazias, tinja na máquina da cor certa, agite no agitador e entregue no balcão.

const SHIFT_TIME = 150.0
const BOUNDS = Rect2(-6.55, -3.55, 13.1, 6.1)
const SERVE_Z = 5.3
const TINT_TIME = 3.5
const SHAKE_TIME = 2.4
const SLOT_X = [-3.0, 0.0, 3.0]
const ITEM_VALUE = {"azul": 18, "verm": 18, "amar": 18, "massa": 10, "rolo": 8}

var ui: TouchUI
var cam: Camera3D
var player: Node3D
var carry_node: Node3D = null
var carrying: String = ""
var yaw: float = 0.0
var anim_t: float = 0.0

var stations: Array = []
var blockers: Array = []
var target = null
var highlight: MeshInstance3D

var orders: Array = []
var order_id: int = 0
var next_order_t: float = 1.0
var slots_used: Array = [false, false, false]
var time_left: float = SHIFT_TIME
var earned: int = 0
var completed: int = 0
var rep: int = 3
var finished: bool = false
var level: int = 0
var leaving: Array = []

var tickets_box: HBoxContainer
var clock: OcHud.Clock
var coin: OcHud.Coin
var lbl_stars: Label
var lbl_msg: Label
var msg_t: float = 0.0
var pause_layer: CanvasLayer
var end_layer: CanvasLayer
var bar_tex: ImageTexture

func _ready() -> void:
	level = mini(Game.shifts, 4)
	Game.apply_quality(get_viewport())
	var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	bar_tex = ImageTexture.create_from_image(img)
	_build_env()
	_build_world()
	_build_hud()

# ------------------------------------------------------------------ ambiente

func _build_env() -> void:
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.36, 0.30, 0.27)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.93, 0.84)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.04
	env.adjustment_contrast = 1.06
	# Brilho suave nas lâmpadas e superfícies claras, sem exagerar no bloom.
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_strength = 0.55
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.3
	we.environment = env
	add_child(we)
	var sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 0.95
	sun.rotation_degrees = Vector3(-52, 40, 0)
	sun.shadow_enabled = Game.shadows_on()
	sun.shadow_blur = 1.8
	sun.directional_shadow_max_distance = 40.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)

# ------------------------------------------------------------------ mundo

func _box(size: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	return mi

func _add_station(key: String, type: String, name_txt: String, r: Rect2, extra: Dictionary = {}) -> Dictionary:
	var s = {"key": key, "type": type, "name": name_txt, "rect": r, "item": "", "state": 0, "t": 0.0, "h": 0.9, "slot_pos": Vector3.ZERO, "slot_node": null, "bar": null}
	for k in extra:
		s[k] = extra[k]
	stations.append(s)
	blockers.append(r)
	return s

func _label3d(text: String, pos: Vector3, col: Color, px: float = 0.0085, fs: int = 56) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = fs
	l.pixel_size = px
	l.outline_size = 14
	l.modulate = col
	add_child(l)
	return l

func _make_bar(pos: Vector3, col: Color) -> Dictionary:
	var n = Node3D.new()
	n.position = pos
	add_child(n)
	n.global_transform = Transform3D(cam.global_transform.basis, pos)
	var bg = Sprite3D.new()
	bg.texture = bar_tex
	bg.pixel_size = 0.25
	bg.centered = false
	bg.offset = Vector2(0, -2)
	bg.position = Vector3(-0.5, 0, 0)
	bg.scale = Vector3(1.05, 0.2, 1)
	bg.modulate = Color(0.05, 0.06, 0.1, 0.85)
	bg.shaded = false
	bg.no_depth_test = true
	bg.render_priority = 1
	n.add_child(bg)
	var fg = Sprite3D.new()
	fg.texture = bar_tex
	fg.pixel_size = 0.25
	fg.centered = false
	fg.offset = Vector2(0, -2)
	fg.position = Vector3(-0.5, 0, 0.01)
	fg.scale = Vector3(0.01, 0.14, 1)
	fg.modulate = col
	fg.shaded = false
	fg.no_depth_test = true
	fg.render_priority = 2
	n.add_child(fg)
	n.visible = false
	return {"node": n, "fg": fg}

func _set_bar(s: Dictionary, frac: float, show: bool) -> void:
	var b = s["bar"]
	b["node"].visible = show
	b["fg"].scale.x = maxf(0.01, frac) * 1.0

func _build_world() -> void:
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 14.5
	cam.near = 0.1
	cam.far = 90.0
	cam.position = Vector3(13.5, 14.0, 13.0)
	add_child(cam)
	cam.look_at(Vector3(0.2, 0.4, 0.4), Vector3.UP)
	var floor_m = OcModels.tex_mat("res://tex/oc_floor.png", 0.5)
	var brick_m = OcModels.tex_mat("res://tex/oc_brick.png", 0.7)
	var pave_m = OcModels.tex_mat("res://tex/oc_pave.png", 0.5)
	var asph_m = OcModels.tex_mat("res://tex/oc_asphalt.png", 0.4)
	# piso e rua
	_box(Vector3(14.6, 0.3, 9.6), Vector3(0, -0.15, -0.5), floor_m)
	_box(Vector3(14.6, 0.34, 4.4), Vector3(0, -0.05, 6.8), pave_m)
	_box(Vector3(80, 0.2, 30), Vector3(0, -0.2, 24.0), asph_m)
	_box(Vector3(80, 0.2, 14), Vector3(0, -0.2, -13.0), OcModels.mat(Color(0.35, 0.55, 0.3), 0.95))
	var st0 = U.new_st()
	OcModels.bevel_box(st0, Vector3(0, 0.0, 9.15), Vector3(80, 0.3, 0.35), Color(0.82, 0.8, 0.76), 0.05)
	OcModels.bevel_box(st0, Vector3(-9.0, 0.0, 4.55), Vector3(2.0, 0.35, 0.5), Color(0.72, 0.7, 0.66), 0.05)
	for i in range(-6, 7):
		OcModels.bevel_box(st0, Vector3(i * 6.0, -0.08, 14.5), Vector3(2.6, 0.04, 0.28), Color(0.95, 0.85, 0.25), 0.01)
	add_child(U.mesh_inst(st0, U.vcol_mat(0.8)))
	# paredes de tijolo: fundo e esquerda altas, direita e frente baixas
	var cap_m = OcModels.mat(Color(0.88, 0.78, 0.6), 0.8)
	_box(Vector3(15.4, 3.6, 0.6), Vector3(0, 1.8, -5.3), brick_m)
	_box(Vector3(15.4, 0.22, 0.8), Vector3(0, 3.7, -5.3), cap_m)
	_box(Vector3(0.6, 3.6, 10.2), Vector3(-7.3, 1.8, -0.2), brick_m)
	_box(Vector3(0.8, 0.22, 10.4), Vector3(-7.3, 3.7, -0.2), cap_m)
	_box(Vector3(0.6, 1.1, 8.4), Vector3(7.3, 0.55, 0.0), brick_m)
	_box(Vector3(0.8, 0.2, 8.6), Vector3(7.3, 1.2, 0.0), cap_m)
	for sx in [-1, 1]:
		_box(Vector3(2.9, 1.1, 0.6), Vector3(sx * 5.95, 0.55, 4.3), brick_m)
		_box(Vector3(3.1, 0.2, 0.8), Vector3(sx * 5.95, 1.2, 4.3), cap_m)
	# janelas na parede do fundo e da esquerda
	var frame_m = OcModels.mat(Color(0.35, 0.2, 0.12), 0.7)
	var glass_m = OcModels.mat(Color(0.7, 0.86, 0.95), 0.2)
	for wx in [-5.0, 4.8]:
		_box(Vector3(2.0, 1.2, 0.12), Vector3(wx, 2.55, -4.97), frame_m)
		_box(Vector3(1.7, 0.9, 0.14), Vector3(wx, 2.55, -4.96), glass_m)
		_box(Vector3(0.08, 0.9, 0.16), Vector3(wx, 2.55, -4.95), frame_m)
	for wz in [-2.6, 0.4]:
		_box(Vector3(0.12, 1.2, 2.0), Vector3(-6.97, 2.55, wz), frame_m)
		_box(Vector3(0.14, 0.9, 1.7), Vector3(-6.96, 2.55, wz), glass_m)
	# letreiro na parede do fundo
	var lm = StandardMaterial3D.new()
	lm.albedo_texture = Chars.logo()
	lm.roughness = 0.9
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var q = QuadMesh.new()
	q.size = Vector2(4.2, 1.2)
	var sign_mi = MeshInstance3D.new()
	sign_mi.mesh = q
	sign_mi.material_override = lm
	sign_mi.position = Vector3(-0.2, 2.75, -4.95)
	add_child(sign_mi)
	_box(Vector3(4.5, 1.4, 0.08), Vector3(-0.2, 2.75, -4.98), OcModels.mat(Color(0.97, 0.97, 0.98), 0.6))
	# ---------------- estações (balcões)
	var tbl = func(key: String, r: Rect2) -> void:
		var s = _add_station(key, "table", "", r)
		s["slot_pos"] = OcModels.counter(self, r)
	# dispensadores
	var disp = [["lata", "LATAS", Rect2(-7, -5, 1.5, 1)], ["massa", "MASSA", Rect2(-5.5, -5, 1.5, 1)], ["rolo", "ROLOS", Rect2(-4, -5, 1.5, 1)]]
	for d in disp:
		var r: Rect2 = d[2]
		var s = _add_station(d[0], "disp", d[1], r, {"item": d[0]})
		var top = OcModels.counter(self, r)
		var stack = OcModels.stack_node(d[0], r.size.x - 0.3, r.size.y - 0.3)
		stack.position = top + Vector3(0, -0.02, 0)
		add_child(stack)
		_label3d(d[1], Vector3(r.position.x + r.size.x * 0.5, 2.1, r.position.y + 0.5), Color(1, 0.96, 0.7))
	tbl.call("t1", Rect2(-2.5, -5, 1, 1))
	# máquinas de tinta
	var mach = [["azul", "AZUL", Rect2(-1.5, -5, 1.6, 1)], ["verm", "VERMELHA", Rect2(0.1, -5, 1.6, 1)], ["amar", "AMARELA", Rect2(1.7, -5, 1.6, 1)]]
	for m in mach:
		var r2: Rect2 = m[2]
		var s2 = _add_station("t_" + m[0], "tint", m[1], r2, {"color": m[0]})
		s2["slot_pos"] = OcModels.tint_machine(self, r2, OcModels.paint_color(m[0]))
		s2["slot_pos"] += Vector3(0, 0, 0.12)
		s2["bar"] = _make_bar(s2["slot_pos"] + Vector3(0, 1.0, 0.1), OcModels.paint_color(m[0]).lightened(0.2))
		_label3d(m[1], Vector3(r2.position.x + r2.size.x * 0.5, 3.15, r2.position.y + 0.5), OcModels.paint_color(m[0]).lightened(0.55), 0.0085, 52)
	tbl.call("t2", Rect2(3.3, -5, 1.2, 1))
	# estante grande decorativa no fundo direito
	var stdec = U.new_st()
	Props.shelf(stdec, Vector3(5.8, 0, -4.55), 2.4, 2.4, 0.8, 21)
	add_child(U.mesh_inst(stdec, U.vcol_mat(0.85)))
	blockers.append(Rect2(4.6, -5.0, 2.4, 0.8))
	# coluna direita: agitador, mesa, lixeira
	var rs = Rect2(6, -3.9, 1, 1.5)
	var ss = _add_station("shake", "shake", "AGITADOR", rs)
	var sh = OcModels.shaker(self, rs)
	ss["slot_pos"] = sh["slot"]
	ss["clamp"] = sh["clamp"]
	ss["clamp_rest"] = sh["clamp_rest"]
	ss["bar"] = _make_bar(sh["slot"] + Vector3(0, 1.3, 0), Color(0.3, 0.9, 0.4))
	_label3d("AGITADOR", Vector3(6.5, 3.0, -3.1), Color(0.75, 1.0, 0.8), 0.0085, 52)
	tbl.call("t3", Rect2(6, -2.4, 1, 1.1))
	var rb = Rect2(6.1, -1.15, 0.9, 0.9)
	_add_station("bin", "bin", "LIXEIRA", rb)
	OcModels.bin(self, rb)
	# esquerda: mesa e estante decorativa
	tbl.call("t4", Rect2(-7, -3.9, 1, 1.3))
	var stl = U.new_st()
	Props.shelf(stl, Vector3.ZERO, 3.0, 2.4, 0.8, 55)
	var dec = U.mesh_inst(stl, U.vcol_mat(0.85))
	dec.position = Vector3(-6.6, 0, -1.0)
	dec.rotation.y = PI * 0.5
	add_child(dec)
	blockers.append(Rect2(-7.0, -2.5, 0.8, 3.0))
	# ilha central
	tbl.call("t5", Rect2(-3, -1.9, 2, 1))
	tbl.call("t6", Rect2(-1, -1.9, 2, 1))
	# balcão de entrega (janela do cliente)
	var rv = Rect2(-4.5, 3, 9, 1)
	_add_station("serve", "serve", "ENTREGA", rv, {"h": 0.9})
	var topv = OcModels.counter(self, rv)
	_label3d("ENTREGA", Vector3(0, 1.9, 3.5), Color(1, 1, 1), 0.01, 60)
	# toldo/faixa colorida sobre a janela
	var sta = U.new_st()
	OcModels.bevel_box(sta, Vector3(0, 2.15, 4.1), Vector3(9.4, 0.28, 0.3), Color(0.9, 0.15, 0.15), 0.06)
	OcModels.bevel_box(sta, Vector3(0, 1.9, 4.1), Vector3(9.4, 0.2, 0.3), Color(0.98, 0.8, 0.1), 0.05)
	for sx in [-4.5, 4.5]:
		OcModels.bevel_box(sta, Vector3(sx, 1.1, 4.1), Vector3(0.28, 2.2, 0.3), Color(0.12, 0.3, 0.7), 0.05)
	add_child(U.mesh_inst(sta, U.vcol_mat(0.6)))
	# plantas e árvores
	for p in [Vector3(-6.4, 0, 2.5), Vector3(6.4, 0, 2.5), Vector3(-6.4, 0.12, 5.4), Vector3(6.4, 0.12, 5.4)]:
		OcModels.plant(self, p, 1.1)
	blockers.append(Rect2(-6.9, 2.0, 0.9, 0.9))
	blockers.append(Rect2(5.9, 2.0, 0.9, 0.9))
	OcModels.tree(self, Vector3(-8.6, 0.12, 5.6), 1.2)
	OcModels.tree(self, Vector3(8.8, 0.12, 5.2), 1.3)
	OcModels.tree(self, Vector3(-10.5, 0, -2.0), 1.4)
	# placa da loja na calçada
	var stp = U.new_st()
	OcModels.bevel_box(stp, Vector3(6.2, 0.9, 7.2), Vector3(0.12, 1.8, 0.12), Color(0.5, 0.32, 0.18), 0.03)
	OcModels.bevel_box(stp, Vector3(4.2, 0.9, 7.2), Vector3(0.12, 1.8, 0.12), Color(0.5, 0.32, 0.18), 0.03)
	OcModels.bevel_box(stp, Vector3(5.2, 1.45, 7.2), Vector3(2.4, 1.0, 0.12), Color(0.97, 0.97, 0.98), 0.04)
	add_child(U.mesh_inst(stp, U.vcol_mat(0.7)))
	var q2 = QuadMesh.new()
	q2.size = Vector2(2.2, 0.64)
	var sg2 = MeshInstance3D.new()
	sg2.mesh = q2
	sg2.material_override = lm
	sg2.position = Vector3(5.2, 1.45, 7.27)
	add_child(sg2)
	# jogador
	player = OcModels.chef()
	player.position = Vector3(3.5, 0, -0.2)
	add_child(player)
	# destaque da estação alvo
	highlight = MeshInstance3D.new()
	var hm = BoxMesh.new()
	hm.size = Vector3(1, 0.06, 1)
	var mm = StandardMaterial3D.new()
	mm.albedo_color = Color(1.0, 0.92, 0.2, 0.5)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.material = mm
	highlight.mesh = hm
	highlight.visible = false
	add_child(highlight)

# ------------------------------------------------------------------ interface

func _build_hud() -> void:
	var hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	tickets_box = HBoxContainer.new()
	tickets_box.add_theme_constant_override("separation", 10)
	hud.add_child(tickets_box)
	UIKit.place(tickets_box, 0.0, 0.0, 12, 8, 1, 1)
	clock = OcHud.Clock.new()
	hud.add_child(clock)
	UIKit.place(clock, 1.0, 1.0, -14, -14, 0, 0)
	coin = OcHud.Coin.new()
	hud.add_child(coin)
	UIKit.place(coin, 0.0, 1.0, 14, -14, 1, 0)
	lbl_stars = UIKit.label("★★★", 30, UIKit.YELLOW)
	hud.add_child(lbl_stars)
	UIKit.place(lbl_stars, 1.0, 0.0, -90, 16, 0, 1)
	lbl_msg = UIKit.label("", 38)
	lbl_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(lbl_msg)
	UIKit.place(lbl_msg, 0.5, 0.3, 0, 0, 2, 2)
	var tl = CanvasLayer.new()
	tl.layer = 4
	add_child(tl)
	ui = TouchUI.new()
	ui.use_joystick = true
	ui.add_button("act", Vector2(0.88, 0.62), 82, "PEGAR", Color(0.1, 0.65, 0.3), KEY_SPACE)
	ui.add_button("work", Vector2(0.72, 0.78), 66, "AGITAR", Color(0.95, 0.55, 0.1), KEY_E)
	ui.set_visible_button("work", false)
	ui.add_button("pause", Vector2(0.95, 0.14), 34, "II", Color(0.3, 0.3, 0.4), KEY_ESCAPE)
	tl.add_child(ui)
	pause_layer = UIKit.make_pause(self)
	_say("Atenda os clientes!", 2.5)

func _say(t: String, secs: float) -> void:
	lbl_msg.text = t
	msg_t = secs

# ------------------------------------------------------------------ loop

func _process(delta: float) -> void:
	if finished:
		return
	anim_t += delta
	if ui.consume("pause"):
		UIKit.show_pause(pause_layer, self)
		return
	_move(delta)
	_find_target()
	if ui.consume("act"):
		_act()
	_work(delta)
	_stations(delta)
	_orders(delta)
	_leaving(delta)
	time_left -= delta
	if time_left <= 0.0 or rep <= 0:
		_end_shift()
	_hud(delta)

func _move(delta: float) -> void:
	var m = ui.move
	var right = Vector3(1, 0, -1).normalized()
	var upv = Vector3(-1, 0, -1).normalized()
	var dir = right * m.x + upv * (-m.y)
	var amount = clampf(dir.length(), 0.0, 1.0)
	if amount > 0.12:
		var d = dir.normalized()
		var np = player.position + d * 5.8 * amount * delta
		yaw = lerp_angle(yaw, atan2(-d.x, -d.z), minf(1.0, 16.0 * delta))
		player.rotation.y = yaw
		player.position = _collide(np)
		Chars.walk(player, anim_t, 1.0)
	else:
		Chars.walk(player, anim_t, 0.0)
	if carrying != "":
		player.get_meta("armL").rotation.x = -1.1
		player.get_meta("armR").rotation.x = -1.1
	player.get_meta("body").position.y = absf(sin(anim_t * 9.0)) * 0.05 * amount

func _collide(p: Vector3) -> Vector3:
	p.x = clampf(p.x, BOUNDS.position.x, BOUNDS.end.x)
	p.z = clampf(p.z, BOUNDS.position.y, BOUNDS.end.y)
	for r in blockers:
		var cx = clampf(p.x, r.position.x, r.end.x)
		var cz = clampf(p.z, r.position.y, r.end.y)
		var dx = p.x - cx
		var dz = p.z - cz
		var d2 = dx * dx + dz * dz
		if d2 < 0.16:
			if d2 > 0.0001:
				var d = sqrt(d2)
				p.x += dx / d * (0.4 - d)
				p.z += dz / d * (0.4 - d)
			else:
				p.z -= 0.4
	return p

func _rect_dist(r: Rect2, p: Vector3) -> float:
	var dx = maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dz = maxf(maxf(r.position.y - p.z, 0.0), p.z - r.end.y)
	return sqrt(dx * dx + dz * dz)

func _find_target() -> void:
	var face = Vector3(-sin(yaw), 0, -cos(yaw))
	var probe = player.position + face * 0.7
	var best = 1.3
	target = null
	for s in stations:
		var d = _rect_dist(s["rect"], probe)
		if d < best:
			best = d
			target = s
	ui.set_visible_button("work", target != null and target["type"] == "shake" and target["state"] == 1)
	if target == null:
		highlight.visible = false
		ui.set_label("act", "SOLTAR" if carrying != "" else "PEGAR")
		return
	var r: Rect2 = target["rect"]
	highlight.visible = true
	(highlight.mesh as BoxMesh).size = Vector3(r.size.x + 0.08, 0.05, r.size.y + 0.08)
	highlight.position = Vector3(r.position.x + r.size.x * 0.5, float(target["h"]) + 0.2, r.position.y + r.size.y * 0.5)
	ui.set_label("act", _act_label())

func _act_label() -> String:
	var t = target
	match t["type"]:
		"disp":
			return "PEGAR" if carrying == "" else "GUARDAR"
		"table":
			if carrying != "":
				return "COLOCAR"
			return "PEGAR" if t["item"] != "" else "..."
		"tint":
			if carrying == "lata" and t["state"] == 0:
				return "TINGIR"
			if carrying == "" and t["state"] >= 1:
				return "PEGAR"
			return "..."
		"shake":
			if carrying != "" and t["state"] == 0:
				return "COLOCAR"
			if carrying == "" and t["state"] >= 1:
				return "PEGAR"
			return "..."
		"serve":
			return "ENTREGAR" if carrying != "" else "..."
		"bin":
			return "JOGAR" if carrying != "" else "..."
	return "..."

func _set_carry(kind: String) -> void:
	carrying = kind
	if carry_node != null:
		carry_node.queue_free()
		carry_node = null
	if kind != "":
		carry_node = OcModels.item_node(kind, 1.15)
		carry_node.position = Vector3(0, 0.88, -0.62)
		player.add_child(carry_node)
	else:
		player.get_meta("armL").rotation.x = 0.0
		player.get_meta("armR").rotation.x = 0.0

func _set_slot(s: Dictionary, kind: String) -> void:
	s["item"] = kind
	if s["slot_node"] != null:
		s["slot_node"].queue_free()
		s["slot_node"] = null
	if kind != "":
		var n = OcModels.item_node(kind, 1.1)
		n.position = s["slot_pos"]
		add_child(n)
		s["slot_node"] = n

func _act() -> void:
	if target == null:
		return
	var s = target
	match s["type"]:
		"disp":
			if carrying == "":
				_set_carry(s["item"])
			elif carrying == s["item"]:
				_set_carry("")
			else:
				_say("Mãos ocupadas!", 1.0)
		"table":
			if carrying != "" and s["item"] == "":
				_set_slot(s, carrying)
				_set_carry("")
			elif carrying == "" and s["item"] != "":
				var k = s["item"]
				_set_slot(s, "")
				_set_carry(k)
		"tint":
			if carrying == "lata" and s["state"] == 0:
				_set_carry("")
				s["state"] = 1
				s["t"] = 0.0
				_set_slot(s, "lata")
			elif carrying == "" and s["state"] == 1:
				_set_slot(s, "")
				s["state"] = 0
				_set_carry("lata")
			elif carrying == "" and s["state"] == 2:
				var k2 = s["color"] + "_c"
				_set_slot(s, "")
				s["state"] = 0
				_set_carry(k2)
			elif carrying != "":
				_say("Só latas vazias aqui!", 1.2)
		"shake":
			if carrying.ends_with("_c") and s["state"] == 0:
				s["raw"] = carrying
				_set_slot(s, carrying)
				_set_carry("")
				s["state"] = 1
				s["t"] = 0.0
			elif carrying == "" and s["state"] == 1:
				_set_carry(s["raw"])
				_set_slot(s, "")
				s["state"] = 0
			elif carrying == "" and s["state"] == 2:
				var fin = str(s["raw"]).replace("_c", "")
				_set_slot(s, "")
				s["state"] = 0
				_set_carry(fin)
			elif carrying != "":
				_say("Só tinta já tingida!", 1.2)
		"serve":
			if carrying != "":
				_deliver(carrying)
		"bin":
			if carrying != "":
				_set_carry("")
				_say("Jogou fora", 0.8)

func _work(delta: float) -> void:
	var s = null
	for st in stations:
		if st["type"] == "shake":
			s = st
	if s == null:
		return
	var working = false
	if s["state"] == 1 and target == s and ui.is_down("work"):
		working = true
		s["t"] = float(s["t"]) + delta
		if float(s["t"]) >= SHAKE_TIME:
			s["state"] = 2
			var raw = str(s["raw"])
			_set_slot(s, raw.replace("_c", ""))
			_say("Pronta! Pegue a tinta", 1.2)
	var clamp_node: Node3D = s["clamp"]
	var rest: float = s["clamp_rest"]
	if working:
		clamp_node.position.y = rest - 0.5 + sin(anim_t * 40.0) * 0.04
		if s["slot_node"] != null:
			s["slot_node"].position = s["slot_pos"] + Vector3(sin(anim_t * 45.0) * 0.03, 0, 0)
	else:
		clamp_node.position.y = lerpf(clamp_node.position.y, rest if s["state"] != 1 else rest - 0.35, minf(1.0, 8.0 * delta))
	if s["state"] == 1:
		_set_bar(s, float(s["t"]) / SHAKE_TIME, true)
	else:
		_set_bar(s, 1.0, false)

func _stations(delta: float) -> void:
	for s in stations:
		if s["type"] != "tint":
			continue
		if s["state"] == 1:
			s["t"] = float(s["t"]) + delta
			_set_bar(s, float(s["t"]) / TINT_TIME, true)
			if float(s["t"]) >= TINT_TIME:
				s["state"] = 2
				_set_slot(s, s["color"] + "_c")
				_say("Tinta pronta! Agora agite", 1.2)
		else:
			_set_bar(s, 1.0, false)

# ------------------------------------------------------------------ pedidos

func _orders(delta: float) -> void:
	if orders.size() < 3:
		next_order_t -= delta
		if next_order_t <= 0.0:
			_new_order()
			next_order_t = randf_range(10.0, 15.0) - level * 1.5
	for o in orders.duplicate():
		var cust: Node3D = o["cust"]
		var arrived = absf(cust.position.z - SERVE_Z) < 0.06
		if not arrived:
			cust.position.z = move_toward(cust.position.z, SERVE_Z, 3.2 * delta)
			Chars.walk(cust, anim_t * 1.3 + o["id"], 1.0)
		else:
			Chars.walk(cust, anim_t + o["id"], 0.0)
			cust.get_meta("body").position.y = absf(sin(anim_t * 2.0 + o["id"])) * 0.03
			o["time"] = float(o["time"]) - delta
		if float(o["time"]) <= 0.0:
			rep -= 1
			_say("Cliente foi embora! ★ perdida", 2.0)
			_remove_order(o, false)

func _new_order() -> void:
	var slot = -1
	for i in range(3):
		if not slots_used[i]:
			slot = i
			break
	if slot == -1:
		return
	order_id += 1
	var maxn = 1 + mini(2, 1 + level / 2)
	var n = 1 + randi() % maxn
	var pool = ["massa", "rolo", "azul"]
	if level >= 1:
		pool.append("verm")
	if level >= 2:
		pool.append("amar")
	if level == 0:
		pool.append("azul")
	var items = []
	for i in range(n):
		items.append(pool[randi() % pool.size()])
	var cust = OcModels.customer(order_id)
	cust.position = Vector3(SLOT_X[slot], 0.12, SERVE_Z + 5.5)
	cust.rotation.y = 0.0
	add_child(cust)
	slots_used[slot] = true
	var total = 62.0 + 16.0 * n - level * 4.0
	var o = {"id": order_id, "items": items, "got": [], "time": total, "total": total, "cust": cust, "slot": slot}
	for i in range(n):
		o["got"].append(false)
	var tag = _label3d("#" + str(order_id), Vector3(0, 2.7, 0), Color(1, 0.9, 0.3), 0.01, 60)
	remove_child(tag)
	cust.add_child(tag)
	_build_ticket(o)
	orders.append(o)

func _build_ticket(o: Dictionary) -> void:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.97, 0.95)
	sb.set_corner_radius_all(10)
	sb.border_color = Color(0.75, 0.75, 0.72)
	sb.set_border_width_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(2, 3)
	p.add_theme_stylebox_override("panel", sb)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var bar = OcHud.Bar.new()
	v.add_child(bar)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	v.add_child(row)
	var num = Label.new()
	num.text = "#" + str(o["id"])
	num.add_theme_font_size_override("font_size", 20)
	num.add_theme_color_override("font_color", Color(0.15, 0.2, 0.35))
	row.add_child(num)
	var icons = []
	for it in o["items"]:
		var ic = OcHud.Icon.new(it, 46.0)
		row.add_child(ic)
		icons.append(ic)
	tickets_box.add_child(p)
	o["panel"] = p
	o["bar"] = bar
	o["icons"] = icons

func _deliver(kind: String) -> void:
	var best = null
	var bi = -1
	for o in orders:
		if absf((o["cust"] as Node3D).position.z - SERVE_Z) > 0.1:
			continue
		for i in range(o["items"].size()):
			if o["items"][i] == kind and not o["got"][i]:
				if best == null or o["id"] < best["id"]:
					best = o
					bi = i
				break
	if best == null:
		_say("Ninguém pediu isso!", 1.3)
		return
	best["got"][bi] = true
	best["icons"][bi].done = true
	best["icons"][bi].queue_redraw()
	var cust: Node3D = best["cust"]
	# item voa até o cliente
	var fly = OcModels.item_node(kind, 1.1)
	add_child(fly)
	fly.global_position = player.global_position + Vector3(0, 1.1, -0.5)
	var tw = create_tween()
	tw.tween_property(fly, "global_position", cust.global_position + Vector3(0, 1.0, 0), 0.25)
	tw.tween_callback(fly.queue_free)
	_set_carry("")
	var done = true
	for g in best["got"]:
		if not g:
			done = false
	if done:
		var reward = 0
		for it in best["items"]:
			reward += int(ITEM_VALUE.get(it, 8))
		reward += int(float(best["time"]) / float(best["total"]) * 12.0)
		earned += reward
		completed += 1
		_say("+" + U.fmt_money(reward) + "  Obrigado!", 1.8)
		_remove_order(best, true)
	else:
		_say("Entregue!", 0.8)

func _remove_order(o: Dictionary, happy: bool) -> void:
	slots_used[o["slot"]] = false
	orders.erase(o)
	if is_instance_valid(o["panel"]):
		o["panel"].queue_free()
	var cust: Node3D = o["cust"]
	cust.rotation.y = PI
	leaving.append({"node": cust, "happy": happy, "t": 0.0})

func _leaving(delta: float) -> void:
	for l in leaving.duplicate():
		var n: Node3D = l["node"]
		if not is_instance_valid(n):
			leaving.erase(l)
			continue
		l["t"] = float(l["t"]) + delta
		n.position.z += 3.4 * delta
		Chars.walk(n, anim_t * 1.3, 1.0)
		if l["happy"]:
			n.get_meta("armL").rotation.x = -2.8
		if n.position.z > SERVE_Z + 7.0:
			n.queue_free()
			leaving.erase(l)

func _hud(delta: float) -> void:
	var t = int(maxf(0.0, time_left))
	clock.text = "%d:%02d" % [t / 60, t % 60]
	clock.frac = time_left / SHIFT_TIME
	clock.queue_redraw()
	lbl_stars.text = UIKit.stars_text(rep)
	coin.text = str(earned)
	coin.queue_redraw()
	for o in orders:
		if is_instance_valid(o["bar"]):
			o["bar"].frac = float(o["time"]) / float(o["total"])
			o["bar"].queue_redraw()
	if msg_t > 0.0:
		msg_t -= delta
		if msg_t <= 0.0:
			lbl_msg.text = ""

func _end_shift() -> void:
	finished = true
	Game.add_money(earned)
	Game.shifts += 1
	Game.save_game()
	var stars = 1
	if earned >= 50:
		stars = 2
	if earned >= 120:
		stars = 3
	end_layer = CanvasLayer.new()
	end_layer.layer = 60
	add_child(end_layer)
	var dim = ColorRect.new()
	dim.color = Color(0, 0.03, 0.1, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_layer.add_child(dim)
	var box = VBoxContainer.new()
	end_layer.add_child(box)
	UIKit.place(box, 0.5, 0.5, 0, 0, 2, 2)
	box.add_theme_constant_override("separation", 12)
	var t = UIKit.label("FIM DO EXPEDIENTE", 44, UIKit.YELLOW)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var s = UIKit.label(UIKit.stars_text(stars), 56, UIKit.YELLOW)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(s)
	var info = UIKit.label("Pedidos entregues: " + str(completed) + "\nGanho no turno: " + U.fmt_money(earned) + "\nTotal no caixa: " + U.fmt_money(Game.money), 26)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	var b1 = UIKit.button("JOGAR DE NOVO")
	var b2 = UIKit.button("MENU PRINCIPAL")
	box.add_child(b1)
	box.add_child(b2)
	b1.pressed.connect(func(): get_tree().reload_current_scene())
	b2.pressed.connect(func(): Game.go("menu"))
