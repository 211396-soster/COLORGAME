class_name DL
extends RefCounted
## Modelos do modo entrega: itens carregáveis, paletes, setas, anéis, portão do cliente.
## Tudo montado com primitivas (cilindros/caixas/toros) para ficar arredondado e leve.

static var _mc: Dictionary = {}
static var _can_scene: PackedScene = null

## lata de tinta escaneada (assets/models/lata_tinta.glb); null se o arquivo não existir
static func scan_can(scale_f: float = 1.0) -> Node3D:
	if _can_scene == null:
		if ResourceLoader.exists("res://assets/models/lata_tinta.glb"):
			_can_scene = load("res://assets/models/lata_tinta.glb")
		else:
			return null
	var n = _can_scene.instantiate()
	n.scale = Vector3(scale_f, scale_f, scale_f)
	return n

const WOOD = Color(0.62, 0.43, 0.24)
const WOOD_D = Color(0.45, 0.3, 0.17)
const TIN = Color(0.84, 0.86, 0.9)
const CARD = Color(0.78, 0.6, 0.38)

static func mt(c: Color, rough: float = 0.7, metal: float = 0.0) -> StandardMaterial3D:
	var key = c.to_html() + str(rough) + str(metal)
	if not _mc.has(key):
		var m = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.metallic = metal
		_mc[key] = m
	return _mc[key]

static func glow_mat(c: Color, alpha: float = 0.85) -> StandardMaterial3D:
	var key = "g" + c.to_html() + str(alpha)
	if not _mc.has(key):
		var m = StandardMaterial3D.new()
		m.albedo_color = Color(c.r, c.g, c.b, alpha)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mc[key] = m
	return _mc[key]

static func _add(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, col: Color, rough: float = 0.6, metal: float = 0.0, segs: int = 20, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var m = CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = h
	m.radial_segments = segs
	m.rings = 1
	return _add(parent, m, mt(col, rough, metal), pos, rot)

static func box(parent: Node3D, size: Vector3, pos: Vector3, col: Color, rough: float = 0.8) -> MeshInstance3D:
	var m = BoxMesh.new()
	m.size = size
	return _add(parent, m, mt(col, rough), pos)

static func torus(parent: Node3D, inner: float, outer: float, pos: Vector3, rot: Vector3, col: Color, rough: float = 0.5, metal: float = 0.0) -> MeshInstance3D:
	var m = TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 20
	m.ring_segments = 8
	return _add(parent, m, mt(col, rough, metal), pos, rot)

static func _logo_quad(parent: Node3D, size: Vector2, pos: Vector3, facing_back: bool = false) -> void:
	var q = QuadMesh.new()
	q.size = size
	var m = StandardMaterial3D.new()
	m.albedo_texture = Chars.logo()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	m.roughness = 0.8
	var mi = _add(parent, q, m, pos)
	if not facing_back:
		mi.rotation.y = PI   # a face visível do quad aponta para -Z (frente do item)

## item carregável. kind: tinta | balde | caixa | rolo. Origem = centro da base.
static func item(kind: String, col: Color) -> Node3D:
	var n = Node3D.new()
	match kind:
		"tinta":
			var scan = scan_can(1.0)
			if scan != null:
				n.add_child(scan)
				return n
			cyl(n, 0.2, 0.2, 0.3, Vector3(0, 0.15, 0), TIN, 0.35, 0.6)
			cyl(n, 0.206, 0.206, 0.17, Vector3(0, 0.14, 0), col, 0.55)
			cyl(n, 0.208, 0.208, 0.03, Vector3(0, 0.235, 0), Color(1, 1, 1), 0.6)
			cyl(n, 0.214, 0.214, 0.03, Vector3(0, 0.31, 0), TIN.darkened(0.2), 0.3, 0.7)
			cyl(n, 0.17, 0.17, 0.012, Vector3(0, 0.322, 0), TIN, 0.3, 0.6)
			torus(n, 0.16, 0.172, Vector3(0, 0.315, 0), Vector3(PI * 0.5, 0, 0), Color(0.3, 0.3, 0.33), 0.4, 0.8).scale = Vector3(1, 1, 0.5)
			_logo_quad(n, Vector2(0.15, 0.07), Vector3(0, 0.14, -0.209))
		"balde":
			cyl(n, 0.255, 0.215, 0.42, Vector3(0, 0.21, 0), col, 0.6)
			cyl(n, 0.262, 0.262, 0.035, Vector3(0, 0.43, 0), Color(0.95, 0.95, 0.96), 0.5)
			cyl(n, 0.25, 0.25, 0.012, Vector3(0, 0.448, 0), Color(0.93, 0.93, 0.94), 0.5)
			cyl(n, 0.238, 0.238, 0.12, Vector3(0, 0.2, 0), col.lightened(0.35), 0.6)
			torus(n, 0.235, 0.248, Vector3(0, 0.44, 0), Vector3(PI * 0.5, 0, 0), Color(0.25, 0.25, 0.28), 0.4, 0.7).scale = Vector3(1, 1, 0.6)
			_logo_quad(n, Vector2(0.17, 0.09), Vector3(0, 0.2, -0.245))
		"caixa":
			box(n, Vector3(0.46, 0.3, 0.34), Vector3(0, 0.15, 0), CARD, 0.9)
			box(n, Vector3(0.07, 0.006, 0.345), Vector3(0, 0.303, 0), CARD.lightened(0.35), 0.5)
			box(n, Vector3(0.465, 0.04, 0.345), Vector3(0, 0.285, 0), CARD.darkened(0.08), 0.9)
			box(n, Vector3(0.3, 0.1, 0.006), Vector3(0, 0.15, -0.172), Color(0.96, 0.96, 0.98), 0.7)
			_logo_quad(n, Vector2(0.26, 0.076), Vector3(0, 0.15, -0.176))
			box(n, Vector3(0.06, 0.03, 0.006), Vector3(0.17, 0.07, -0.172), col, 0.7)
		_:
			# rolo de pintura em pé: cabo, haste e cilindro felpudo
			cyl(n, 0.024, 0.026, 0.16, Vector3(0, 0.08, 0), Color(0.1, 0.1, 0.14), 0.7)
			cyl(n, 0.009, 0.009, 0.16, Vector3(0, 0.24, 0), Color(0.7, 0.72, 0.76), 0.3, 0.8)
			cyl(n, 0.009, 0.009, 0.28, Vector3(0, 0.33, 0), Color(0.7, 0.72, 0.76), 0.3, 0.8, 8, Vector3(0, 0, PI * 0.5))
			cyl(n, 0.065, 0.065, 0.24, Vector3(0, 0.33, 0), col, 0.95, 0.0, 18, Vector3(0, 0, PI * 0.5))
			cyl(n, 0.066, 0.066, 0.012, Vector3(0.12, 0.33, 0), Color(0.75, 0.75, 0.8), 0.3, 0.7, 14, Vector3(0, 0, PI * 0.5))
			cyl(n, 0.066, 0.066, 0.012, Vector3(-0.12, 0.33, 0), Color(0.75, 0.75, 0.8), 0.3, 0.7, 14, Vector3(0, 0, PI * 0.5))
	return n

## palete de madeira com pilha de amostras do tipo, rótulo flutuante e anel de destaque
static func pallet(kind: String, col: Color, title: String) -> Node3D:
	var n = Node3D.new()
	for i in range(3):
		box(n, Vector3(1.1, 0.07, 0.12), Vector3(0, 0.035, -0.4 + i * 0.4), WOOD_D)
	for i in range(5):
		box(n, Vector3(1.1, 0.025, 0.17), Vector3(0, 0.083, -0.45 + i * 0.225), WOOD)
	var layers = 2 if kind == "tinta" else 1
	if kind == "caixa":
		layers = 2
	for ly in range(layers):
		for ix in range(2):
			for iz in range(2):
				var it = item(kind, col if kind != "tinta" else Props.PALETTE[(ix * 2 + iz + ly) % Props.PALETTE.size()])
				var h = 0.3 if kind != "balde" else 0.42
				if kind == "tinta" and ResourceLoader.exists("res://assets/models/lata_tinta.glb"):
					h = 0.37
				if kind == "rolo":
					h = 0.0
				it.position = Vector3(-0.26 + ix * 0.52, 0.095 + ly * h, -0.24 + iz * 0.48)
				it.rotation.y = PI + (ix + iz) * 0.1
				n.add_child(it)
	var lb = Label3D.new()
	lb.text = title
	lb.font_size = 56
	lb.pixel_size = 0.012
	lb.outline_size = 14
	lb.modulate = Color(1, 0.95, 0.5)
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.no_depth_test = true
	lb.position = Vector3(0, 1.55, 0)
	n.add_child(lb)
	var ring = ring_disc(1.2, Color(1.0, 0.85, 0.1))
	ring.position = Vector3(0, 0.03, 0)
	ring.visible = false
	n.add_child(ring)
	n.set_meta("ring", ring)
	return n

static func ring_disc(r: float, col: Color) -> MeshInstance3D:
	var t = TorusMesh.new()
	t.inner_radius = r - 0.12
	t.outer_radius = r
	t.rings = 36
	t.ring_segments = 3
	var mi = MeshInstance3D.new()
	mi.mesh = t
	mi.material_override = glow_mat(col, 0.7)
	mi.scale = Vector3(1, 0.05, 1)
	return mi

## seta apontando para baixo, em cima do alvo
static func arrow(col: Color) -> Node3D:
	var n = Node3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.55
	cone.bottom_radius = 0.0
	cone.height = 0.9
	cone.radial_segments = 4
	_add(n, cone, glow_mat(col, 0.95), Vector3(0, 0.45, 0))
	var shaft = CylinderMesh.new()
	shaft.top_radius = 0.2
	shaft.bottom_radius = 0.2
	shaft.height = 0.7
	shaft.radial_segments = 4
	_add(n, shaft, glow_mat(col, 0.95), Vector3(0, 1.25, 0))
	return n

static func beam(r: float, col: Color) -> MeshInstance3D:
	var cm = CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 60.0
	cm.radial_segments = 24
	var mi = MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = glow_mat(col, 0.28)
	mi.position = Vector3(0, 30, 0)
	return mi

## portão/entrada do cliente (frente = +Z, voltada para a rua) com número
static func gate(number: String) -> Node3D:
	var n = Node3D.new()
	var wall = Color(0.93, 0.9, 0.82)
	for sx in [-1, 1]:
		box(n, Vector3(0.22, 1.7, 0.22), Vector3(0.75 * sx, 0.85, 0), wall)
		box(n, Vector3(0.3, 0.1, 0.3), Vector3(0.75 * sx, 1.74, 0), wall.darkened(0.1))
	box(n, Vector3(1.8, 0.12, 0.2), Vector3(0, 1.66, 0), wall.darkened(0.05))
	# folhas do portão (grade de ferro)
	for sx in [-1, 1]:
		for i in range(6):
			box(n, Vector3(0.03, 1.25, 0.03), Vector3(sx * (0.12 + i * 0.1), 0.78, 0.02), Color(0.12, 0.13, 0.16), 0.5)
		box(n, Vector3(0.62, 0.04, 0.04), Vector3(sx * 0.4, 1.35, 0.02), Color(0.12, 0.13, 0.16), 0.5)
		box(n, Vector3(0.62, 0.04, 0.04), Vector3(sx * 0.4, 0.25, 0.02), Color(0.12, 0.13, 0.16), 0.5)
	box(n, Vector3(0.5, 0.26, 0.04), Vector3(0, 2.0, 0.0), Color(0.1, 0.25, 0.65))
	var lb = Label3D.new()
	lb.text = number
	lb.font_size = 64
	lb.pixel_size = 0.0045
	lb.outline_size = 0
	lb.modulate = Color.WHITE
	lb.position = Vector3(0, 2.0, 0.03)
	n.add_child(lb)
	return n
