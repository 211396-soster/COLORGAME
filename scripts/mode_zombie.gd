extends Node3D
## Modo 4 - Sobrevivência: depósito da Color Tintas, primeira pessoa, rolo de pintura como arma.

const ROOM = Rect2(-17.0, -13.0, 34.0, 26.0)
const MAX_WAVE = 10

var ui: TouchUI
var cam: Camera3D
var ppos: Vector3 = Vector3(0, 0, 10)
var yaw: float = 0.0
var pitch: float = 0.0
var hp: float = 100.0
var wave: int = 0
var kills: int = 0
var zombies: Array = []
var pickups: Array = []
var blockers: Array = []
var spawn_left: int = 0
var spawn_t: float = 0.0
var break_t: float = 2.0
var wave_active: bool = false
var swing_t: float = -1.0
var swing_cd: float = 0.0
var swing_hit: bool = false
var hit_cd: float = 0.0
var bob: float = 0.0
var anim_t: float = 0.0
var finished: bool = false
var roller: Node3D
var lamps: Array = []
var weapon: int = 0          # 0 rolo, 1 pistola de tinta
var ammo: int = 24
var pistol: Node3D
var recoil: float = 0.0
var lbl_ammo: Label

var lbl_hp: Label
var lbl_wave: Label
var lbl_kills: Label
var lbl_msg: Label
var flash: ColorRect
var msg_t: float = 0.0
var pause_layer: CanvasLayer

func _ready() -> void:
	Game.apply_quality(get_viewport())
	add_child(U.make_env("dark", false))
	_build_world()
	_build_hud()
	_say("Sobreviva às ondas!", 2.5)

func _build_world() -> void:
	var st = U.new_st()
	var r = ROOM
	U.quad(st, Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y), Color(0.34, 0.35, 0.37), Vector3.UP)
	U.quad(st, Vector3(r.position.x, 5.2, r.position.y), Vector3(r.end.x, 5.2, r.position.y), Vector3(r.end.x, 5.2, r.end.y), Vector3(r.position.x, 5.2, r.end.y), Color(0.18, 0.19, 0.21), Vector3.DOWN)
	var wc = Color(0.3, 0.32, 0.35)
	U.box(st, Vector3(0, 2.6, r.position.y - 0.25), Vector3(r.size.x + 1, 5.2, 0.5), wc)
	U.box(st, Vector3(0, 2.6, r.end.y + 0.25), Vector3(r.size.x + 1, 5.2, 0.5), wc)
	U.box(st, Vector3(r.position.x - 0.25, 2.6, 0), Vector3(0.5, 5.2, r.size.y), wc)
	U.box(st, Vector3(r.end.x + 0.25, 2.6, 0), Vector3(0.5, 5.2, r.size.y), wc)
	# faixas amarelas no chão (corredores)
	for zz in [-5.5, -0.5, 4.5]:
		U.box(st, Vector3(0, 0.02, zz), Vector3(32, 0.02, 0.15), Color(0.9, 0.75, 0.1))
	# prateleiras industriais
	var seed_n = 1
	for zz in [-9.0, -4.5, 0.0, 4.5]:
		for xx in [-10.0, 10.0]:
			Props.shelf(st, Vector3(xx, 0, zz), 8.0, 3.4, 1.0, seed_n, Color(0, 0, 0, 0), "can", true)
			seed_n += 1
			blockers.append(Rect2(xx - 4.0, zz - 0.5, 8.0, 1.0))
	# caixas e paletes
	var rng = RandomNumberGenerator.new()
	rng.seed = 21
	for i in range(9):
		var cx = rng.randf_range(-13.0, 13.0)
		var cz = rng.randf_range(-11.0, 11.0)
		if absf(cx) > 5.5 and absf(cx) < 14.0:
			var near_shelf = false
			for b in blockers:
				if cx > b.position.x - 1.5 and cx < b.end.x + 1.5 and cz > b.position.y - 1.5 and cz < b.end.y + 1.5:
					near_shelf = true
			if near_shelf:
				continue
		U.box(st, Vector3(cx, 0.6, cz), Vector3(1.2, 1.2, 1.2), Color(0.62, 0.45, 0.28))
		U.box(st, Vector3(cx, 1.5, cz), Vector3(0.9, 0.6, 0.9), Color(0.55, 0.4, 0.25))
		blockers.append(Rect2(cx - 0.6, cz - 0.6, 1.2, 1.2))
	# luz de emergência vermelha na parede do fundo
	U.box(st, Vector3(0, 3.8, r.position.y + 0.1), Vector3(3.0, 0.4, 0.1), Color(0.9, 0.1, 0.1))
	add_child(U.mesh_inst(st, U.vcol_mat(0.9)))
	# luzes do teto
	for p in [Vector3(-8, 4.6, -6), Vector3(8, 4.6, -6), Vector3(-8, 4.6, 6), Vector3(8, 4.6, 6), Vector3(0, 4.6, 0)]:
		var l = OmniLight3D.new()
		l.position = p
		l.omni_range = 13.0
		l.light_energy = 1.3
		l.light_color = Color(1.0, 0.95, 0.8)
		add_child(l)
		lamps.append(l)
	# câmera, lanterna e rolo
	cam = Camera3D.new()
	cam.fov = 78.0
	cam.near = 0.05
	cam.far = 80.0
	add_child(cam)
	var sp = SpotLight3D.new()
	sp.spot_range = 20.0
	sp.spot_angle = 38.0
	sp.light_energy = 2.2
	sp.position = Vector3(0.2, -0.1, 0)
	cam.add_child(sp)
	roller = Node3D.new()
	roller.position = Vector3(0.34, -0.36, -0.6)
	cam.add_child(roller)
	roller.add_child(Props.roller_view(Color(0.1, 0.35, 0.9)))
	pistol = Props.pistol_view(Color(0.1, 0.35, 0.9))
	pistol.position = Vector3(0.3, -0.28, -0.55)
	pistol.visible = false
	cam.add_child(pistol)
	_update_cam()

func _build_hud() -> void:
	var hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	flash = ColorRect.new()
	flash.color = Color(0.8, 0, 0, 0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flash)
	var hp_panel = UIKit.panel()
	hud.add_child(hp_panel)
	UIKit.place(hp_panel, 0.0, 0.0, 14, 12, 1, 1)
	lbl_hp = UIKit.label("♥ 100", 32, Color(1, 0.3, 0.3))
	hp_panel.add_child(lbl_hp)
	var wp = UIKit.panel()
	hud.add_child(wp)
	UIKit.place(wp, 0.5, 0.0, 0, 12, 2, 1)
	var wv = VBoxContainer.new()
	wp.add_child(wv)
	lbl_wave = UIKit.label("Ondas: 0/" + str(MAX_WAVE), 28)
	lbl_wave.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_kills = UIKit.label("Zumbis: 0", 20, UIKit.YELLOW)
	lbl_kills.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wv.add_child(lbl_wave)
	wv.add_child(lbl_kills)
	lbl_ammo = UIKit.label("", 26, Color(0.5, 0.75, 1.0))
	hud.add_child(lbl_ammo)
	UIKit.place(lbl_ammo, 0.5, 0.92, 0, 0, 2, 2)
	var cross = UIKit.label("+", 30)
	hud.add_child(cross)
	UIKit.place(cross, 0.5, 0.5, 0, 0, 2, 2)
	lbl_msg = UIKit.label("", 40)
	hud.add_child(lbl_msg)
	UIKit.place(lbl_msg, 0.5, 0.3, 0, 0, 2, 2)
	var tl = CanvasLayer.new()
	tl.layer = 4
	add_child(tl)
	ui = TouchUI.new()
	ui.use_joystick = true
	ui.use_look = true
	ui.add_button("fire", Vector2(0.9, 0.78), 82, "PINTAR", Color(0.15, 0.4, 0.95), KEY_SPACE)
	ui.add_button("weapon", Vector2(0.78, 0.62), 42, "ROLO", Color(0.3, 0.3, 0.5), KEY_Q)
	ui.add_button("pause", Vector2(0.95, 0.2), 34, "II", Color(0.3, 0.3, 0.4), KEY_ESCAPE)
	tl.add_child(ui)
	pause_layer = UIKit.make_pause(self)

func _say(t: String, secs: float) -> void:
	lbl_msg.text = t
	msg_t = secs

func _process(delta: float) -> void:
	if finished:
		return
	anim_t += delta
	if ui.consume("pause"):
		UIKit.show_pause(pause_layer, self)
		return
	_look()
	_move(delta)
	_attack(delta)
	_waves(delta)
	_zombies(delta)
	_pickups(delta)
	_update_cam()
	for i in range(lamps.size()):
		if i % 2 == 1:
			lamps[i].light_energy = 1.3 if randf() > 0.04 else 0.3
	flash.color.a = maxf(0.0, flash.color.a - delta * 1.6)
	lbl_hp.text = "♥ " + str(int(maxf(0.0, hp)))
	lbl_wave.text = "Ondas: " + str(wave) + "/" + str(MAX_WAVE)
	lbl_kills.text = "Zumbis: " + str(kills)
	if msg_t > 0.0:
		msg_t -= delta
		if msg_t <= 0.0:
			lbl_msg.text = ""
	if hp <= 0.0:
		_end(false)

func _look() -> void:
	var l = ui.take_look()
	yaw -= l.x * 0.0045
	pitch = clampf(pitch - l.y * 0.0045, -1.2, 1.2)

func _update_cam() -> void:
	cam.position = ppos + Vector3(0, 1.65 + sin(bob) * 0.04, 0)
	cam.rotation = Vector3(pitch, yaw, 0)

func _collide(p: Vector3, rad: float) -> Vector3:
	p.x = clampf(p.x, ROOM.position.x + rad, ROOM.end.x - rad)
	p.z = clampf(p.z, ROOM.position.y + rad, ROOM.end.y - rad)
	for r in blockers:
		var cx = clampf(p.x, r.position.x, r.end.x)
		var cz = clampf(p.z, r.position.y, r.end.y)
		var dx = p.x - cx
		var dz = p.z - cz
		var d2 = dx * dx + dz * dz
		if d2 < rad * rad:
			if d2 > 0.0001:
				var d = sqrt(d2)
				p.x += dx / d * (rad - d)
				p.z += dz / d * (rad - d)
			else:
				p.z += rad
	return p

func _move(delta: float) -> void:
	var m = ui.move
	var f = Vector3(-sin(yaw), 0, -cos(yaw))
	var r = Vector3(cos(yaw), 0, -sin(yaw))
	var dir = r * m.x + f * (-m.y)
	if dir.length() > 0.05:
		ppos = _collide(ppos + dir.limit_length(1.0) * 5.2 * delta, 0.45)
		bob += delta * 9.0

func _attack(delta: float) -> void:
	swing_cd -= delta
	recoil = maxf(0.0, recoil - delta * 6.0)
	if ui.consume("weapon") and swing_t < 0.0:
		weapon = 1 - weapon
		roller.visible = weapon == 0
		pistol.visible = weapon == 1
		ui.set_label("weapon", "ROLO" if weapon == 0 else "PISTOLA")
		ui.set_label("fire", "PINTAR" if weapon == 0 else "ATIRAR")
	lbl_ammo.text = "" if weapon == 0 else "Tinta: " + str(ammo)
	if weapon == 1:
		pistol.position = Vector3(0.3, -0.28 + recoil * 0.03, -0.55 + recoil * 0.12)
		pistol.rotation.x = recoil * 0.25
		if ui.is_down("fire") and swing_cd <= 0.0:
			if ammo > 0:
				ammo -= 1
				swing_cd = 0.28
				recoil = 1.0
				_shoot()
			else:
				swing_cd = 0.4
				_say("Sem tinta! Pegue latas azuis", 1.0)
		return
	if ui.is_down("fire") and swing_cd <= 0.0 and swing_t < 0.0:
		swing_t = 0.0
		swing_cd = 0.5
		swing_hit = false
	if swing_t >= 0.0:
		swing_t += delta / 0.34
		var k = sin(clampf(swing_t, 0.0, 1.0) * PI)
		roller.rotation = Vector3(-k * 1.0, 0.0, k * 0.4)
		roller.position = Vector3(0.34 - k * 0.2, -0.36 + k * 0.1, -0.6 - k * 0.25)
		if swing_t >= 0.45 and not swing_hit:
			swing_hit = true
			_hit_zombies()
		if swing_t >= 1.0:
			swing_t = -1.0
			roller.rotation = Vector3.ZERO
			roller.position = Vector3(0.34, -0.36, -0.6)

func _shoot() -> void:
	var o = cam.global_position
	var d = -cam.global_transform.basis.z
	var best_t = 40.0
	var best = null
	for z in zombies:
		for h in [0.5, 1.1, 1.6]:
			var c = z["node"].position + Vector3(0, h, 0)
			var t = (c - o).dot(d)
			if t > 0.3 and t < best_t:
				if (c - (o + d * t)).length() < 0.42:
					best_t = t
					best = z
	var endp = o + d * best_t
	var mp = o + d * 0.5 + (-cam.global_transform.basis.y) * 0.12 + cam.global_transform.basis.x * 0.12
	_tracer(mp, endp)
	if best != null:
		best["hp"] = float(best["hp"]) - 26.0
		best["kb"] = Vector3(d.x, 0, d.z) * 2.0
		_splat(endp)
		if float(best["hp"]) <= 0.0:
			_kill(best)

func _tracer(a: Vector3, b: Vector3) -> void:
	var l = a.distance_to(b)
	if l < 0.1:
		return
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.04, 0.04, l)
	mi.mesh = bm
	mi.material_override = U.emissive_mat(Color(0.2, 0.5, 1.0), 3.0)
	add_child(mi)
	mi.global_position = (a + b) * 0.5
	mi.look_at(b, Vector3.UP)
	get_tree().create_timer(0.07).timeout.connect(mi.queue_free)

func _hit_zombies() -> void:
	var f = Vector3(-sin(yaw), 0, -cos(yaw))
	for z in zombies.duplicate():
		var to = z["node"].position - ppos
		to.y = 0
		var d = to.length()
		if d < 2.7 and d > 0.01 and f.dot(to / d) > 0.4:
			z["hp"] = float(z["hp"]) - 36.0
			z["kb"] = to / d * 5.0
			_splat(z["node"].position + Vector3(0, 1.3, 0))
			if float(z["hp"]) <= 0.0:
				_kill(z)

func _splat(p: Vector3) -> void:
	var pr = CPUParticles3D.new()
	pr.position = p
	pr.emitting = true
	pr.one_shot = true
	pr.amount = 14
	pr.lifetime = 0.6
	pr.explosiveness = 1.0
	pr.direction = Vector3(0, 1, 0)
	pr.spread = 70.0
	pr.initial_velocity_min = 2.0
	pr.initial_velocity_max = 5.0
	pr.gravity = Vector3(0, -9, 0)
	var sm = SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = U.mat(Color(0.1, 0.35, 0.9))
	pr.mesh = sm
	add_child(pr)
	get_tree().create_timer(1.2).timeout.connect(pr.queue_free)

func _kill(z: Dictionary) -> void:
	kills += 1
	zombies.erase(z)
	var p: Vector3 = z["node"].position
	z["node"].queue_free()
	if randf() < 0.25:
		var n = Props.item("azul")
		n.position = Vector3(p.x, 0.5, p.z)
		add_child(n)
		pickups.append({"node": n, "pos": p})

func _pickups(delta: float) -> void:
	for pk in pickups.duplicate():
		var n: Node3D = pk["node"]
		n.rotation.y += delta * 2.0
		n.position.y = 0.55 + sin(anim_t * 3.0) * 0.1
		if Vector2(ppos.x, ppos.z).distance_to(Vector2(pk["pos"].x, pk["pos"].z)) < 1.3:
			hp = minf(100.0, hp + 25.0)
			ammo += 10
			_say("+25 vida  +10 tinta", 1.2)
			n.queue_free()
			pickups.erase(pk)

func _waves(delta: float) -> void:
	if not wave_active:
		break_t -= delta
		if break_t <= 0.0:
			wave += 1
			spawn_left = 4 + wave * 2
			spawn_t = 0.0
			wave_active = true
			ammo = maxi(ammo, 24)
			_say("ONDA " + str(wave), 2.0)
		return
	if spawn_left > 0 and zombies.size() < 12:
		spawn_t -= delta
		if spawn_t <= 0.0:
			_spawn()
			spawn_left -= 1
			spawn_t = 0.9
	elif spawn_left == 0 and zombies.size() == 0:
		wave_active = false
		break_t = 3.5
		if wave >= MAX_WAVE:
			_end(true)
		else:
			_say("Onda " + str(wave) + " limpa!", 2.0)

func _spawn() -> void:
	var pts = [Vector3(-15, 0, -11), Vector3(15, 0, -11), Vector3(-15, 0, 11), Vector3(15, 0, 11),
		Vector3(0, 0, -12), Vector3(0, 0, 12), Vector3(-16, 0, 0), Vector3(16, 0, 0)]
	var p = pts[randi() % pts.size()]
	for i in range(6):
		if Vector2(p.x, p.z).distance_to(Vector2(ppos.x, ppos.z)) > 10.0:
			break
		p = pts[randi() % pts.size()]
	var node = Chars.zombie(randi() % 4)
	node.position = p
	add_child(node)
	zombies.append({"node": node, "hp": 60.0 + wave * 6.0, "speed": minf(3.3, 1.3 + wave * 0.12 + randf() * 0.4),
		"cd": 0.4, "kb": Vector3.ZERO, "t": randf() * 5.0})

func _zombies(delta: float) -> void:
	for z in zombies:
		var n: Node3D = z["node"]
		var to = ppos - n.position
		to.y = 0
		var d = to.length()
		z["t"] = float(z["t"]) + delta
		var kb: Vector3 = z["kb"]
		var dir = Vector3.ZERO
		if d > 0.01:
			dir = to / d
		var np = n.position + kb * delta
		z["kb"] = kb * maxf(0.0, 1.0 - 6.0 * delta)
		if d > 1.15:
			np += dir * float(z["speed"]) * delta
		for o in zombies:
			if o != z:
				var sep = np - o["node"].position
				sep.y = 0
				var sd = sep.length()
				if sd < 0.9 and sd > 0.01:
					np += sep / sd * (0.9 - sd) * 0.5
		n.position = _collide(np, 0.4)
		if d > 0.01:
			n.rotation.y = atan2(-dir.x, -dir.z)
		Chars.walk(n, float(z["t"]), 1.0, true)
		z["cd"] = float(z["cd"]) - delta
		if d <= 1.35 and float(z["cd"]) <= 0.0:
			z["cd"] = 1.0
			hp -= 6.0 + wave
			flash.color.a = 0.45

func _end(win: bool) -> void:
	if finished:
		return
	finished = true
	var reward = kills * 3
	if win:
		reward += 300
	Game.best_wave = maxi(Game.best_wave, wave if not win else MAX_WAVE)
	Game.add_money(reward)
	var layer = CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var dim = ColorRect.new()
	dim.color = Color(0.05, 0, 0, 0.75) if not win else Color(0, 0.05, 0.1, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var box = VBoxContainer.new()
	layer.add_child(box)
	UIKit.place(box, 0.5, 0.5, 0, 0, 2, 2)
	box.add_theme_constant_override("separation", 12)
	var t = UIKit.label("DEPÓSITO LIMPO!" if win else "VOCÊ CAIU...", 46, UIKit.YELLOW if win else UIKit.RED)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var info = UIKit.label("Onda alcançada: " + str(wave) + "\nZumbis derrotados: " + str(kills) + "\nRecompensa: " + U.fmt_money(reward), 26)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	var b1 = UIKit.button("TENTAR DE NOVO")
	var b2 = UIKit.button("MENU PRINCIPAL")
	box.add_child(b1)
	box.add_child(b2)
	b1.pressed.connect(func(): get_tree().reload_current_scene())
	b2.pressed.connect(func(): Game.go("menu"))
