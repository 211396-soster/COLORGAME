extends Node3D
## Modo 3 - Entregas em Passo Fundo.
## Ciclo: CARREGAR a caminhonete na loja -> DIRIGIR até o cliente -> DESCARREGAR e entregar -> voltar à loja.

const MAX_SPEED = 33.3 # 120 km/h em m/s
const MAX_REVERSE_SPEED = 5.5
const VEHICLE_WHEELBASE = 2.8
const NAMES = ["João Silva", "Maria Souza", "Carlos Pereira", "Ana Lima", "Pedro Alves", "Fernanda Costa",
	"Lucas Rocha", "Juliana Dias", "Marcos Teixeira", "Patrícia Gomes", "Rafael Moraes", "Camila Freitas"]
const KIND_NAME = {"tinta": "Lata de tinta", "balde": "Balde de massa", "caixa": "Caixa", "rolo": "Rolo"}
const KIND_VALUE = {"tinta": 14, "balde": 12, "caixa": 10, "rolo": 8}

var city: City
var truck: Node3D
var cam: Camera3D
var ui: TouchUI
var minimap: MiniMap
var pause_layer: CanvasLayer

var lbl_client: Label
var lbl_addr: Label
var lbl_dist: Label
var lbl_time: Label
var lbl_money: Label
var lbl_speed: Label
var lbl_msg: Label
var lbl_place: Label
var lbl_load: Label
var lbl_list: Label
var lbl_hint: Label

var state: String = "init"   # init, loading, drive, unloading, return
var speed: float = 0.0
var yaw: float = 0.0
var steer: float = 0.0
var cam_yaw: float = 0.0
var cockpit: bool = false
var order: Dictionary = {}
var route: PackedVector2Array = PackedVector2Array()
var route_timer: float = 0.0
var chunk_timer: float = 0.0
var msg_timer: float = 0.0
var marker: Node3D = null
var customer: Node3D = null
var gate: Node3D = null
var anim_t: float = 0.0
var order_no: int = 0
var session_earned: int = 0

# a pé
var player: Node3D
var pyaw: float = 0.0
var carrying: String = ""
var carry_node: Node3D = null
var carried_item_index: int = -1
var items: Array = []        # [{kind, col, loaded, delivered, node}]
var pallets: Array = []      # [{kind, node, pos}]
var guide: Node3D
var cust_pos: Vector3 = Vector3.ZERO
var lane_dir: Vector2 = Vector2.ZERO
var lane_perp: Vector2 = Vector2.ZERO
var tailgate: Node3D
var traffic: Traffic = null
var slots: Array = []
var stage_t: float = 0.0
var ret_dist_ok: bool = false

func _ready() -> void:
	Game.apply_quality(get_viewport())
	add_child(U.make_env("day", Game.shadows_on()))
	cam = Camera3D.new()
	cam.fov = 72.0
	cam.near = 0.3
	cam.far = 1600.0
	add_child(cam)
	_build_hud()
	await get_tree().process_frame
	await get_tree().process_frame
	city = City.new()
	add_child(city)
	city.setup(Game.chunk_radius())
	minimap.city = city
	traffic = Traffic.new()
	add_child(traffic)
	traffic.setup(city)
	truck = TruckModel.build(false)
	var blob = MeshInstance3D.new()
	var bq = QuadMesh.new()
	bq.size = Vector2(2.7, 5.9)
	var bm = StandardMaterial3D.new()
	bm.albedo_color = Color(0, 0, 0, 0.32)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bq.material = bm
	blob.mesh = bq
	blob.rotation.x = -PI * 0.5
	blob.position = Vector3(0, 0.13, 0)
	truck.add_child(blob)
	tailgate = truck.get_meta("tailgate")
	slots = truck.get_meta("slots")
	truck.position = city.spawn_pos
	yaw = city.spawn_yaw
	cam_yaw = yaw
	truck.rotation.y = yaw
	add_child(truck)
	player = Chars.employee(1)
	add_child(player)
	guide = DL.arrow(Color(1.0, 0.85, 0.1))
	add_child(guide)
	var nr = city.nearest_road(city.spawn_pos.x, city.spawn_pos.z)
	if nr.size() > 0:
		lane_dir = nr["dir"]
		lane_perp = Vector2(-lane_dir.y, lane_dir.x)
		if lane_perp.dot(Vector2(city.store_pos.x - city.spawn_pos.x, city.store_pos.z - city.spawn_pos.z)) < 0.0:
			lane_perp = -lane_perp
	_build_pallets(float(nr.get("w", 8.0)) if nr.size() > 0 else 8.0)
	city.update(truck.position, 99, 1)
	lbl_load.visible = false
	_new_order()
	_start_loading()

# ------------------------------------------------------------------ HUD

func _build_hud() -> void:
	var hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var card = UIKit.panel()
	hud.add_child(card)
	UIKit.place(card, 0.0, 0.0, 14, 12, 1, 1)
	var v = VBoxContainer.new()
	card.add_child(v)
	v.add_child(UIKit.label("ENTREGA ATUAL", 18, UIKit.YELLOW))
	lbl_client = UIKit.label("", 22)
	lbl_addr = UIKit.label("", 18)
	lbl_dist = UIKit.label("", 18)
	lbl_time = UIKit.label("", 26, UIKit.YELLOW)
	lbl_list = UIKit.label("", 18, Color(0.85, 0.95, 1.0))
	for l in [lbl_client, lbl_addr, lbl_dist, lbl_time, lbl_list]:
		v.add_child(l)
	var mp = UIKit.panel()
	hud.add_child(mp)
	UIKit.place(mp, 1.0, 0.0, -12, 12, 0, 1)
	var mv = VBoxContainer.new()
	mp.add_child(mv)
	minimap = MiniMap.new()
	minimap.custom_minimum_size = Vector2(190, 190)
	mv.add_child(minimap)
	lbl_place = UIKit.label("", 16)
	lbl_place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mv.add_child(lbl_place)
	lbl_money = UIKit.label("", 28, UIKit.YELLOW)
	hud.add_child(lbl_money)
	UIKit.place(lbl_money, 0.5, 0.0, 0, 10, 2, 1)
	lbl_speed = UIKit.label("", 34)
	hud.add_child(lbl_speed)
	UIKit.place(lbl_speed, 0.5, 0.80, 0, 0, 2, 2)
	lbl_msg = UIKit.label("", 40, Color.WHITE)
	hud.add_child(lbl_msg)
	UIKit.place(lbl_msg, 0.5, 0.30, 0, 0, 2, 2)
	lbl_hint = UIKit.label("", 26, Color(1, 0.95, 0.6))
	lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(lbl_hint)
	UIKit.place(lbl_hint, 0.5, 0.90, 0, 0, 2, 2)
	lbl_load = UIKit.label("Carregando Passo Fundo...", 36)
	hud.add_child(lbl_load)
	UIKit.place(lbl_load, 0.5, 0.5, 0, 0, 2, 2)
	var tl = CanvasLayer.new()
	tl.layer = 4
	add_child(tl)
	ui = TouchUI.new()
	ui.use_joystick = false
	ui.add_button("left", Vector2(0.08, 0.82), 62, "◀", Color(0.2, 0.4, 0.9), KEY_LEFT)
	ui.add_button("right", Vector2(0.22, 0.82), 62, "▶", Color(0.2, 0.4, 0.9), KEY_RIGHT)
	ui.add_button("gas", Vector2(0.92, 0.80), 72, "ACEL", Color(0.1, 0.7, 0.3), KEY_UP)
	ui.add_button("brake", Vector2(0.79, 0.86), 54, "FREIO", Color(0.85, 0.15, 0.15), KEY_DOWN)
	ui.add_button("cam", Vector2(0.79, 0.64), 40, "CÂM", Color(0.3, 0.3, 0.4), KEY_C)
	ui.add_button("act", Vector2(0.90, 0.78), 80, "PEGAR", Color(0.1, 0.6, 0.3), KEY_SPACE)
	ui.add_button("enter", Vector2(0.76, 0.84), 56, "DIRIGIR", Color(0.15, 0.35, 0.85), KEY_E)
	ui.add_button("pause", Vector2(0.5, 0.92), 34, "II", Color(0.3, 0.3, 0.4), KEY_ESCAPE)
	tl.add_child(ui)
	pause_layer = UIKit.make_pause(self)

func _say(t: String, secs: float) -> void:
	lbl_msg.text = t
	msg_timer = secs

# ------------------------------------------------------------------ pedido

func _build_pallets(w: float) -> void:
	var base = Vector2(city.spawn_pos.x, city.spawn_pos.z)
	var edge = lane_perp * (w * 0.28 + 3.4)
	var defs = [["tinta", Color(0.2, 0.4, 0.9), "TINTAS"], ["balde", Color(0.95, 0.8, 0.2), "MASSA"],
		["caixa", Color(0.85, 0.5, 0.2), "CAIXAS"], ["rolo", Color(0.9, 0.3, 0.1), "ROLOS"]]
	var offs = [-7.5, -2.5, 2.5, 7.5]
	for i in range(4):
		var p2 = base + edge + lane_dir * offs[i]
		var n = DL.pallet(defs[i][0], defs[i][1], defs[i][2])
		n.position = Vector3(p2.x, 0.0, p2.y)
		n.rotation.y = yaw
		add_child(n)
		pallets.append({"kind": defs[i][0], "node": n, "pos": n.position})

func _new_order() -> void:
	var dest = city.random_destination(truck.position, 350.0, 1500.0)
	if dest.size() == 0:
		return
	order_no += 1
	var rp: Vector3 = dest["pos"]
	var dir: Vector2 = dest["dir"]
	var perp = Vector2(-dir.y, dir.x)
	var cpos = Vector2(rp.x, rp.z) + perp * (float(dest["w"]) * 0.5 + 2.4)
	var nm = str(dest["name"])
	if nm == "":
		nm = "Rua sem nome"
	var rt = city.find_route(city.spawn_pos, rp)
	var plen = City.path_length(rt)
	items.clear()
	var n = randi_range(2, 4)
	var kinds = ["tinta", "tinta", "balde", "caixa", "rolo"]
	var reward_items = 0
	for i in range(n):
		var k: String = kinds[randi() % kinds.size()]
		var col = Props.PALETTE[randi() % Props.PALETTE.size()]
		items.append({"kind": k, "col": col, "loaded": false, "delivered": false, "node": null, "slot": -1})
		reward_items += int(KIND_VALUE[k])
	order = {
		"client": NAMES[randi() % NAMES.size()],
		"street": nm,
		"number": randi_range(30, 2400),
		"bairro": city.place_name_at(rp.x, rp.z),
		"pos": rp,
		"time": plen / 8.0 + 50.0 + 6.0 * n,
		"reward": 50 + int(plen * 0.05) + reward_items,
		"perp": perp,
	}
	cust_pos = Vector3(cpos.x, 0, cpos.y)
	route = rt
	if customer != null:
		customer.queue_free()
	if gate != null:
		gate.queue_free()
	customer = Chars.customer(order_no)
	customer.position = cust_pos
	add_child(customer)
	customer.look_at(Vector3(rp.x, 0, rp.z), Vector3.UP)
	gate = DL.gate(str(order["number"]))
	var gp = cpos + perp * 2.3
	gate.position = Vector3(gp.x, 0, gp.y)
	gate.rotation.y = atan2(-perp.x, -perp.y)
	add_child(gate)

func _set_marker(pos: Vector3, col: Color) -> void:
	if marker != null:
		marker.queue_free()
	marker = Node3D.new()
	marker.position = pos
	marker.add_child(DL.beam(1.6, col))
	var ring = DL.ring_disc(5.0, col)
	ring.position = Vector3(0, 0.2, 0)
	marker.add_child(ring)
	add_child(marker)

func _clear_marker() -> void:
	if marker != null:
		marker.queue_free()
		marker = null

# ------------------------------------------------------------------ fases

func _start_loading() -> void:
	state = "loading"
	speed = 0.0
	player.visible = true
	_clear_marker()
	route = PackedVector2Array()
	ui.use_joystick = true
	ui.use_look = true
	var side = truck.global_transform.basis.x * (1.0 if lane_perp.dot(Vector2(truck.global_transform.basis.x.x, truck.global_transform.basis.x.z)) > 0.0 else -1.0)
	player.position = truck.position + side * 2.6 - truck.global_transform.basis.z * 1.0
	pyaw = yaw
	cam_yaw = yaw
	_open_gate(true)
	_set_buttons()
	_say("Novo pedido #" + str(order_no) + ": carregue a picape!", 3.0)

func _open_gate(open: bool) -> void:
	var tw = create_tween()
	tw.tween_property(tailgate, "rotation:x", deg_to_rad(88.0) if open else 0.0, 0.4)

func _set_buttons() -> void:
	var drive = state == "drive" or state == "return"
	for b in ["left", "right", "gas", "brake", "cam"]:
		ui.set_visible_button(b, drive)
	ui.set_visible_button("act", not drive)
	ui.set_visible_button("enter", false)
	ui.use_joystick = not drive
	ui.use_look = not drive

func _loaded_count() -> int:
	var c = 0
	for it in items:
		if it["loaded"]:
			c += 1
	return c

func _delivered_count() -> int:
	var c = 0
	for it in items:
		if it["delivered"]:
			c += 1
	return c

func _next_to_load() -> int:
	for i in range(items.size()):
		if not items[i]["loaded"]:
			return i
	return -1

func _next_slot() -> int:
	for s in range(slots.size()):
		var used = false
		for it in items:
			if it["loaded"] and not it["delivered"] and it["slot"] == s:
				used = true
		if not used:
			return s
	return 0

func _bed_point() -> Vector3:
	return truck.to_global(Vector3(0, 0, 3.7))

func _near_truck_cab() -> bool:
	return player.position.distance_to(truck.to_global(Vector3(-1.6, 0, -0.2))) < 3.4 or player.position.distance_to(truck.to_global(Vector3(1.6, 0, -0.2))) < 3.4

func _hold(kind: String, col: Color) -> void:
	if carry_node != null:
		carry_node.queue_free()
		carry_node = null
	carrying = kind
	if kind != "":
		carry_node = DL.item(kind, col)
		carry_node.position = Vector3(0, 1.0, -0.55)
		carry_node.rotation.y = PI
		player.add_child(carry_node)
	var a = -1.2 if kind != "" else 0.0
	player.get_meta("armL").rotation.x = a
	player.get_meta("armR").rotation.x = a

# ------------------------------------------------------------------ loop

func _process(delta: float) -> void:
	if traffic != null and truck != null:
		traffic.update(delta, truck.position)
	if state == "loading" or state == "unloading":
		anim_t += delta
		if ui.consume("pause"):
			UIKit.show_pause(pause_layer, self)
			return
		_walk(delta)
		if state == "loading":
			_loading_logic()
		else:
			_unloading_logic()
		_camera_foot(delta)
		_orders_idle(delta)
		_hud(delta)
		chunk_timer += delta
		if chunk_timer > 0.15:
			chunk_timer = 0.0
			city.update(player.position, 1)
		return
	if state != "drive" and state != "return":
		return
	anim_t += delta
	if ui.consume("pause"):
		UIKit.show_pause(pause_layer, self)
		return
	if ui.consume("cam"):
		cockpit = not cockpit
	_drive(delta)
	_camera(delta)
	_orders(delta)
	_hud(delta)
	chunk_timer += delta
	if chunk_timer > 0.15:
		chunk_timer = 0.0
		city.update(truck.position, 1)

func _walk(delta: float) -> void:
	var look = ui.take_look()
	cam_yaw -= look.x * 0.006
	var m = ui.move
	var f = Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
	var r = Vector3(cos(cam_yaw), 0, -sin(cam_yaw))
	var dir = r * m.x + f * (-m.y)
	var amount = clampf(dir.length(), 0.0, 1.0)
	if amount > 0.12:
		var d = dir.normalized()
		var np = player.position + d * 5.4 * amount * delta
		pyaw = lerp_angle(pyaw, atan2(-d.x, -d.z), minf(1.0, 14.0 * delta))
		player.rotation.y = pyaw
		np = city.push_out(np, 0.5)
		np = _truck_block(np)
		player.position = np
		Chars.walk(player, anim_t, 1.0)
	else:
		Chars.walk(player, anim_t, 0.0)
	if carrying != "":
		player.get_meta("armL").rotation.x = -1.2
		player.get_meta("armR").rotation.x = -1.2
	player.get_meta("body").position.y = absf(sin(anim_t * 9.0)) * 0.05 * amount

func _truck_block(p: Vector3) -> Vector3:
	var l = truck.to_local(p)
	var hx = 1.45
	var hz = 2.9
	if absf(l.x) < hx and absf(l.z) < hz:
		var px = hx - absf(l.x)
		var pz = hz - absf(l.z)
		if px < pz:
			l.x = hx * signf(l.x if l.x != 0.0 else 1.0)
		else:
			l.z = hz * signf(l.z if l.z != 0.0 else 1.0)
		return truck.to_global(l)
	return p

func _camera_foot(delta: float) -> void:
	var f = Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
	var target_pos = player.position - f * 6.5 + Vector3(0, 4.2, 0)
	cam.position = cam.position.lerp(target_pos, minf(1.0, 6.0 * delta)) if cam.position.distance_to(target_pos) < 30.0 else target_pos
	cam.look_at(player.position + Vector3(0, 1.2, 0) + f * 1.5, Vector3.UP)

func _guide_at(p: Vector3) -> void:
	guide.visible = true
	guide.position = p + Vector3(0, 1.0 + sin(anim_t * 4.0) * 0.18, 0)
	guide.rotation.y += 0.04

func _loading_logic() -> void:
	var idx = _next_to_load()
	for pl in pallets:
		(pl["node"].get_meta("ring") as Node3D).visible = false
	if idx == -1:
		# tudo carregado: ir para a cabine
		lbl_hint.text = "Tudo carregado! Entre na picape."
		_guide_at(truck.to_global(Vector3(-1.4, 2.2, -0.2)))
		var near = _near_truck_cab()
		ui.set_visible_button("act", false)
		ui.set_visible_button("enter", near)
		ui.set_label("enter", "DIRIGIR")
		if ui.consume("enter") or (near and ui.consume("act")):
			_depart()
		return
	var need: String = items[idx]["kind"]
	if carrying == "":
		var best = null
		var bd = 1e9
		for pl in pallets:
			if pl["kind"] != need:
				continue
			var d = player.position.distance_to(pl["pos"])
			if d < bd:
				bd = d
				best = pl
		if best == null:
			lbl_hint.text = "Não há mais itens deste tipo disponíveis."
			ui.set_visible_button("act", false)
			return
		_guide_at(best["pos"] + Vector3(0, 1.4, 0))
		var close = bd < 2.4
		(best["node"].get_meta("ring") as Node3D).visible = true
		ui.set_label("act", "PEGAR")
		lbl_hint.text = "Pegue: " + KIND_NAME[need]
		ui.set_visible_button("act", close)
		if close and ui.consume("act"):
			_hold(need, items[idx]["col"])
			Input.vibrate_handheld(30)
	else:
		var bp = _bed_point()
		_guide_at(bp + Vector3(0, 1.6, 0))
		var close2 = player.position.distance_to(bp) < 2.8
		ui.set_label("act", "COLOCAR")
		lbl_hint.text = "Leve até a caçamba da picape"
		ui.set_visible_button("act", close2)
		if close2 and ui.consume("act"):
			_place_in_bed(idx)

func _place_in_bed(idx: int) -> void:
	var it: Dictionary = items[idx]
	var slot = _next_slot()
	var node = carry_node
	carry_node = null
	carrying = ""
	carried_item_index = -1
	player.get_meta("armL").rotation.x = 0.0
	player.get_meta("armR").rotation.x = 0.0
	var gp = node.global_position
	player.remove_child(node)
	truck.add_child(node)
	node.global_position = gp
	node.rotation = Vector3(0, PI, 0)
	var sp: Vector3 = slots[slot]
	var tw = create_tween()
	var mid = node.position.lerp(sp, 0.5) + Vector3(0, 0.9, 0)
	tw.tween_property(node, "position", mid, 0.18)
	tw.tween_property(node, "position", sp, 0.18)
	it["loaded"] = true
	it["node"] = node
	it["slot"] = slot
	node.rotation = Vector3(0, PI, 0)
	if _loaded_count() == items.size():
		_say("Carga completa!", 1.5)

func _depart() -> void:
	_open_gate(false)
	player.visible = false
	guide.visible = false
	for pl in pallets:
		(pl["node"].get_meta("ring") as Node3D).visible = false
	state = "drive"
	cockpit = false
	cam_yaw = yaw
	speed = 0.0
	_set_buttons()
	_set_marker(order["pos"], Color(1.0, 0.85, 0.1))
	route = city.find_route(truck.position, order["pos"])
	_say("Boa viagem! Entregue em " + str(order["street"]), 2.5)

func _arrive_customer() -> void:
	speed = 0.0
	state = "unloading"
	_clear_marker()
	route = PackedVector2Array()
	ui.use_joystick = true
	ui.use_look = true
	_set_buttons()
	player.visible = true
	var side = truck.global_transform.basis.x * (1.0 if lane_perp.dot(Vector2(truck.global_transform.basis.x.x, truck.global_transform.basis.x.z)) > 0.0 else -1.0)
	var op: Vector2 = order["perp"]
	var side_dir = truck.global_transform.basis.x
	if Vector2(side_dir.x, side_dir.z).dot(op) < 0.0:
		side_dir = -side_dir
	player.position = truck.position + side_dir * 2.6 - truck.global_transform.basis.z * 1.0
	pyaw = yaw
	cam_yaw = yaw
	_open_gate(true)
	_say("Chegou! Descarregue a encomenda", 3.0)

func _unloading_logic() -> void:
	var pending = _loaded_count() - _delivered_count()
	if pending == 0 and carrying == "":
		guide.visible = true
		_guide_at(truck.to_global(Vector3(-1.4, 2.2, -0.2)))
		var near = _near_truck_cab()
		lbl_hint.text = "Entrega concluída! Volte para a picape."
		ui.set_visible_button("act", false)
		ui.set_visible_button("enter", near)
		if ui.consume("enter") or (near and ui.consume("act")):
			_depart_return()
		return
	if carrying == "":
		var bp = _bed_point()
		_guide_at(bp + Vector3(0, 1.6, 0))
		var close = player.position.distance_to(bp) < 2.8
		ui.set_label("act", "PEGAR")
		lbl_hint.text = "Pegue a encomenda na caçamba"
		ui.set_visible_button("act", close)
		if close and ui.consume("act"):
			# Pegue o primeiro item ainda não entregue; só conta como entregue quando chega ao cliente.
			for i in range(items.size()):
				var it: Dictionary = items[i]
				if it["loaded"] and not it["delivered"] and it["node"] != null:
					it["node"].queue_free()
					it["node"] = null
					carried_item_index = i
					_hold(it["kind"], it["col"])
					break
	else:
		_guide_at(cust_pos + Vector3(0, 2.3, 0))
		var close2 = player.position.distance_to(cust_pos) < 2.6
		ui.set_label("act", "ENTREGAR")
		lbl_hint.text = "Entregue ao cliente " + str(order["client"])
		ui.set_visible_button("act", close2)
		if close2 and ui.consume("act"):
			_give_to_customer()

func _give_to_customer() -> void:
	var fly = DL.item(carrying, Color.WHITE)
	if carry_node != null:
		fly = carry_node
		player.remove_child(carry_node)
		add_child(fly)
		fly.global_position = player.position + Vector3(0, 1.1, 0)
		carry_node = null
	var tw = create_tween()
	tw.tween_property(fly, "global_position", cust_pos + Vector3(0, 1.1, 0), 0.25)
	tw.tween_callback(fly.queue_free)
	if carried_item_index >= 0 and carried_item_index < items.size():
		items[carried_item_index]["delivered"] = true
		items[carried_item_index]["node"] = null
	carried_item_index = -1
	carrying = ""
	player.get_meta("armL").rotation.x = 0.0
	player.get_meta("armR").rotation.x = 0.0
	Input.vibrate_handheld(30)
	if _loaded_count() - _delivered_count() == 0:
		var reward = int(order["reward"])
		var late = float(order["time"]) < 0.0
		if late:
			reward = reward / 2
		else:
			reward += int(float(order["time"]) * 0.4)
		Game.add_money(reward)
		Game.deliveries += 1
		session_earned += reward
		_say("ENTREGA CONCLUÍDA!  +" + U.fmt_money(reward) + (" (atrasou)" if late else ""), 3.5)
		order["time"] = 0.0
		order["done"] = true
	else:
		_say("Entregue!", 0.8)

func _depart_return() -> void:
	_open_gate(false)
	player.visible = false
	guide.visible = false
	state = "return"
	cockpit = false
	cam_yaw = yaw
	speed = 0.0
	_set_buttons()
	_set_marker(city.spawn_pos, Color(0.3, 0.7, 1.0))
	route = city.find_route(truck.position, city.spawn_pos)
	_say("Volte à loja para o próximo pedido", 2.5)

func _arrive_shop() -> void:
	speed = 0.0
	_clear_marker()
	var tw = create_tween()
	tw.tween_property(truck, "position", city.spawn_pos, 0.6)
	yaw = city.spawn_yaw
	truck.rotation.y = yaw
	for it in items:
		if it["node"] != null:
			it["node"].queue_free()
	_new_order()
	_start_loading()

func _orders_idle(delta: float) -> void:
	if customer != null:
		Chars.walk(customer, anim_t, 0.0)
		if order.get("done", false) or state == "unloading":
			customer.get_meta("armR").rotation.x = -2.5 + sin(anim_t * 7.0) * 0.45
	if state == "unloading" and not order.get("done", false):
		order["time"] = float(order["time"]) - delta

func _drive(delta: float) -> void:
	var str_in = 0.0
	if ui.is_down("left"):
		str_in += 1.0
	if ui.is_down("right"):
		str_in -= 1.0
	# Aceleração, travagem e arrasto aproximados para uma picape de rua.
	if ui.is_down("gas"):
		if speed < 0.0:
			speed = move_toward(speed, 0.0, 7.0 * delta)
		else:
			speed = move_toward(speed, MAX_SPEED, 4.0 * delta)
	elif ui.is_down("brake"):
		if speed > 0.0:
			speed = move_toward(speed, 0.0, 8.5 * delta)
		else:
			speed = move_toward(speed, -MAX_REVERSE_SPEED, 2.4 * delta)
	else:
		var drag = 0.55 + absf(speed) * 0.035
		speed = move_toward(speed, 0.0, drag * delta)
	speed = clampf(speed, -MAX_REVERSE_SPEED, MAX_SPEED)
	steer = lerpf(steer, str_in, minf(1.0, 5.5 * delta))
	# Modelo bicicleta: direção diminui progressivamente em alta velocidade.
	var speed_ratio = clampf(absf(speed) / MAX_SPEED, 0.0, 1.0)
	var max_wheel_angle = lerpf(0.58, 0.22, speed_ratio)
	var turn_rate = (speed / VEHICLE_WHEELBASE) * tan(steer * max_wheel_angle)
	yaw += turn_rate * delta
	var fwd = Vector3(-sin(yaw), 0, -cos(yaw))
	var np = truck.position + fwd * speed * delta
	var pf = city.push_out(np + fwd * 1.8, 1.15)
	var pb = city.push_out(np - fwd * 1.6, 1.15)
	var shift = ((pf - (np + fwd * 1.8)) + (pb - (np - fwd * 1.6))) * 0.5
	if shift.length() > 0.005:
		np += shift
		speed *= maxf(0.0, 1.0 - 4.0 * delta)
	if traffic != null:
		var tr = traffic.push(np, 1.9)
		np = tr[0]
		if tr[1]:
			speed *= maxf(0.0, 1.0 - 5.0 * delta)
	truck.position = np
	truck.rotation.y = yaw
	var spins: Array = truck.get_meta("spins")
	for s in spins:
		s.rotation.x -= speed * delta / 0.4
	var fronts: Array = truck.get_meta("steer")
	for f in fronts:
		f.rotation.y = steer * 0.45

func _camera(delta: float) -> void:
	if cockpit:
		var off = Basis(Vector3.UP, yaw) * Vector3(-0.42, 1.8, -0.1)
		cam.position = truck.position + off
		cam.rotation = Vector3(0, yaw, 0)
		return
	cam_yaw = lerp_angle(cam_yaw, yaw, minf(1.0, 4.0 * delta))
	var f = Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
	var d = 8.8 + absf(speed) * 0.06
	cam.position = truck.position - f * d + Vector3(0, 3.8 + absf(speed) * 0.02, 0)
	cam.look_at(truck.position + Vector3(0, 1.3, 0) + f * 3.0, Vector3.UP)

func _orders(delta: float) -> void:
	if state == "drive":
		order["time"] = float(order["time"]) - delta
		route_timer += delta
		if route_timer > 2.5:
			route_timer = 0.0
			route = city.find_route(truck.position, order["pos"])
		var d = truck.position.distance_to(order["pos"])
		lbl_hint.text = "Dirija até o destino"
		if d < 12.0 and absf(speed) < 5.0:
			_arrive_customer()
	elif state == "return":
		route_timer += delta
		if route_timer > 2.5:
			route_timer = 0.0
			route = city.find_route(truck.position, city.spawn_pos)
		var d2 = truck.position.distance_to(city.spawn_pos)
		lbl_hint.text = "Volte à loja Color Tintas"
		if d2 < 14.0 and absf(speed) < 5.0:
			_arrive_shop()

func _hud(delta: float) -> void:
	var here = Vector2(truck.position.x, truck.position.z)
	var ang = yaw
	if state == "loading" or state == "unloading":
		here = Vector2(player.position.x, player.position.z)
		ang = cam_yaw
	minimap.set_state(here, ang)
	minimap.route = route
	if state == "return":
		minimap.has_target = true
		minimap.target = Vector2(city.spawn_pos.x, city.spawn_pos.z)
	elif order.size() > 0:
		var op: Vector3 = order["pos"]
		minimap.target = Vector2(op.x, op.z)
		minimap.has_target = true
	else:
		minimap.has_target = false
	if order.size() > 0:
		lbl_client.text = "Cliente: " + str(order["client"])
		lbl_addr.text = str(order["street"]) + ", " + str(order["number"]) + "\n" + str(order["bairro"])
		var rem = City.path_length(route) if route.size() > 1 else truck.position.distance_to(order["pos"])
		lbl_dist.text = "Distância: " + ("%.1f" % (rem / 1000.0)) + " km" if state != "loading" else ""
		var t = int(maxf(0.0, float(order["time"])))
		lbl_time.text = ("%02d:%02d" % [t / 60, t % 60]) if state != "loading" else "Tempo começa ao partir"
		lbl_time.add_theme_color_override("font_color", UIKit.RED if float(order["time"]) < 10.0 and state == "drive" else UIKit.YELLOW)
	var lines = ""
	for it in items:
		var mark = "○"
		if state == "loading" or state == "drive":
			mark = "●" if it["loaded"] else "○"
		else:
			mark = "●" if it["delivered"] else "○"
		lines += mark + " " + KIND_NAME[it["kind"]] + "\n"
	var head = "CARGA " + str(_loaded_count()) + "/" + str(items.size())
	if state == "unloading":
		head = "ENTREGUES " + str(_delivered_count()) + "/" + str(items.size())
	lbl_list.text = head + "\n" + lines.strip_edges()
	lbl_money.text = U.fmt_money(Game.money)
	lbl_speed.text = str(int(absf(speed) * 3.6)) + " km/h" if state == "drive" or state == "return" else ""
	lbl_place.text = city.place_name_at(here.x, here.y)
	if msg_timer > 0.0:
		msg_timer -= delta
		if msg_timer <= 0.0:
			lbl_msg.text = ""
	if state == "drive" or state == "return":
		guide.visible = false
