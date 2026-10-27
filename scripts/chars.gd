class_name Chars
extends RefCounted
## Personagens estilizados (funcionários uniformizados, clientes e zumbis).

static var _mats: Dictionary = {}
static var _logo: Texture2D = null

static func _m(c: Color) -> StandardMaterial3D:
	var key = c.to_html()
	if not _mats.has(key):
		var m = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.8
		_mats[key] = m
	return _mats[key]

static func _mi(mesh: Mesh, c: Color, parent: Node3D, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _m(c)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func logo() -> Texture2D:
	if _logo == null:
		_logo = load("res://tex/logo.png")
	return _logo

## Constrói um humano. Frente = -Z. Metadados: armL, armR, legL, legR (Node3D pivôs)
static func build(shirt: Color, skin: Color, hair: Color, pants: Color, cap: bool, uniform_logo: bool, zombie: bool = false) -> Node3D:
	var root = Node3D.new()
	var body = Node3D.new()
	root.add_child(body)
	# tronco
	var torso = BoxMesh.new()
	torso.size = Vector3(0.52, 0.62, 0.28)
	_mi(torso, shirt, body, Vector3(0, 1.08, 0))
	# cabeça
	var head = SphereMesh.new()
	head.radius = 0.17
	head.height = 0.36
	head.radial_segments = 14
	head.rings = 8
	_mi(head, skin, body, Vector3(0, 1.6, 0))
	# cabelo / boné
	if cap:
		var capm = CylinderMesh.new()
		capm.top_radius = 0.175
		capm.bottom_radius = 0.185
		capm.height = 0.12
		capm.radial_segments = 14
		_mi(capm, shirt, body, Vector3(0, 1.72, 0))
		var visor = BoxMesh.new()
		visor.size = Vector3(0.26, 0.025, 0.18)
		_mi(visor, shirt, body, Vector3(0, 1.675, -0.2))
	else:
		var hm = SphereMesh.new()
		hm.radius = 0.18
		hm.height = 0.24
		hm.radial_segments = 12
		hm.rings = 5
		_mi(hm, hair, body, Vector3(0, 1.69, 0.015))
	# olhos
	var eye = BoxMesh.new()
	eye.size = Vector3(0.04, 0.04, 0.02)
	var ecol = Color(0.05, 0.05, 0.05)
	if zombie:
		ecol = Color(0.9, 0.1, 0.05)
	for sx in [-1, 1]:
		var e = _mi(eye, ecol, body, Vector3(0.065 * sx, 1.62, -0.16))
		if zombie:
			e.material_override = U.emissive_mat(Color(1, 0.1, 0.05), 2.0)
	# Detalhes de rosto, pescoço e uniforme para silhuetas menos genéricas.
	var neck = CylinderMesh.new()
	neck.top_radius = 0.07
	neck.bottom_radius = 0.08
	neck.height = 0.14
	neck.radial_segments = 12
	_mi(neck, skin, body, Vector3(0, 1.39, 0))
	var ear = SphereMesh.new()
	ear.radius = 0.045
	ear.height = 0.08
	ear.radial_segments = 10
	ear.rings = 5
	for sx in [-1, 1]:
		_mi(ear, skin, body, Vector3(0.17 * sx, 1.59, -0.005))
	var nose = SphereMesh.new()
	nose.radius = 0.035
	nose.height = 0.075
	nose.radial_segments = 10
	nose.rings = 5
	_mi(nose, skin.darkened(0.04), body, Vector3(0, 1.59, -0.177))
	var brow = BoxMesh.new()
	brow.size = Vector3(0.07, 0.018, 0.025)
	for sx in [-1, 1]:
		_mi(brow, hair.darkened(0.1), body, Vector3(0.065 * sx, 1.665, -0.16))
	# logo no peito e nas costas
	if uniform_logo:
		var q = QuadMesh.new()
		q.size = Vector2(0.24, 0.07)
		var lm = StandardMaterial3D.new()
		lm.albedo_texture = logo()
		lm.roughness = 0.9
		var f = MeshInstance3D.new()
		f.mesh = q
		f.material_override = lm
		f.position = Vector3(0.1, 1.22, -0.142)
		f.rotation.y = PI
		body.add_child(f)
		var q2 = QuadMesh.new()
		q2.size = Vector2(0.4, 0.12)
		var b = MeshInstance3D.new()
		b.mesh = q2
		b.material_override = lm
		b.position = Vector3(0, 1.2, 0.142)
		body.add_child(b)
	# braços
	var armm = CapsuleMesh.new()
	armm.radius = 0.07
	armm.height = 0.58
	armm.radial_segments = 8
	armm.rings = 3
	for sx in [-1, 1]:
		var piv = Node3D.new()
		piv.position = Vector3(0.34 * sx, 1.32, 0)
		body.add_child(piv)
		_mi(armm, shirt, piv, Vector3(0, -0.24, 0))
		var hand = SphereMesh.new()
		hand.radius = 0.065
		hand.height = 0.13
		hand.radial_segments = 8
		hand.rings = 4
		_mi(hand, skin, piv, Vector3(0, -0.53, 0))
		root.set_meta("arm" + ("L" if sx < 0 else "R"), piv)
	# pernas
	var legm = CapsuleMesh.new()
	legm.radius = 0.09
	legm.height = 0.74
	legm.radial_segments = 8
	legm.rings = 3
	var shoe = BoxMesh.new()
	shoe.size = Vector3(0.16, 0.08, 0.28)
	for sx in [-1, 1]:
		var pv = Node3D.new()
		pv.position = Vector3(0.13 * sx, 0.78, 0)
		body.add_child(pv)
		_mi(legm, pants, pv, Vector3(0, -0.36, 0))
		_mi(shoe, Color(0.12, 0.1, 0.1), pv, Vector3(0, -0.74, -0.05))
		root.set_meta("leg" + ("L" if sx < 0 else "R"), pv)
	root.set_meta("body", body)
	return root

static func employee(variant: int = 0) -> Node3D:
	var skins = [Color(0.93, 0.74, 0.6), Color(0.75, 0.55, 0.4), Color(0.55, 0.38, 0.28), Color(0.86, 0.66, 0.5)]
	var hairs = [Color(0.12, 0.08, 0.05), Color(0.3, 0.2, 0.1), Color(0.05, 0.05, 0.05), Color(0.45, 0.3, 0.15)]
	var navy = Color(0.1, 0.16, 0.38)
	return build(navy, skins[variant % 4], hairs[variant % 4], Color(0.18, 0.2, 0.28), variant % 2 == 0, true)

static func customer(variant: int = 0) -> Node3D:
	var shirts = [Color(0.85, 0.3, 0.25), Color(0.25, 0.6, 0.35), Color(0.9, 0.75, 0.2), Color(0.55, 0.35, 0.65), Color(0.2, 0.55, 0.8)]
	var skins = [Color(0.93, 0.74, 0.6), Color(0.75, 0.55, 0.4), Color(0.55, 0.38, 0.28), Color(0.86, 0.66, 0.5)]
	var hairs = [Color(0.12, 0.08, 0.05), Color(0.3, 0.2, 0.1), Color(0.05, 0.05, 0.05), Color(0.6, 0.45, 0.2)]
	return build(shirts[variant % 5], skins[variant % 4], hairs[(variant + 1) % 4], Color(0.25, 0.28, 0.4), false, false)

static func zombie(variant: int = 0) -> Node3D:
	var shirts = [Color(0.1, 0.16, 0.38), Color(0.35, 0.3, 0.25), Color(0.4, 0.15, 0.15), Color(0.25, 0.3, 0.28)]
	var z = build(shirts[variant % 4], Color(0.45, 0.62, 0.38), Color(0.12, 0.1, 0.08), Color(0.22, 0.22, 0.18), false, variant % 4 == 0, true)
	z.get_meta("armL").rotation.x = -1.45
	z.get_meta("armR").rotation.x = -1.45
	z.get_meta("body").rotation.x = 0.12
	return z

## anima caminhada. t = tempo acumulado, amount 0..1
static func walk(c: Node3D, t: float, amount: float, arms_forward: bool = false) -> void:
	var sw = sin(t * 9.0) * 0.7 * amount
	c.get_meta("legL").rotation.x = sw
	c.get_meta("legR").rotation.x = -sw
	if not arms_forward:
		c.get_meta("armL").rotation.x = -sw * 0.8
		c.get_meta("armR").rotation.x = sw * 0.8
	else:
		c.get_meta("armL").rotation.x = -1.45 + sin(t * 5.0) * 0.12
		c.get_meta("armR").rotation.x = -1.45 - sin(t * 5.0) * 0.12
