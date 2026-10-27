class_name OcModels
extends RefCounted
## Modelos do modo "Overcooked": caixas chanfradas, itens, máquinas, chefs e cenário (tudo procedural).

const BLUE = Color(0.10, 0.30, 0.85)
const RED = Color(0.88, 0.12, 0.12)
const YELLOW = Color(0.98, 0.80, 0.10)
const BODY = Color(0.12, 0.40, 0.60)
const TOP = Color(0.27, 0.70, 0.78)
const RIM = Color(0.07, 0.26, 0.42)
const TIN = Color(0.80, 0.82, 0.86)
const WOOD = Color(0.60, 0.38, 0.20)

static var _mats: Dictionary = {}
static var _tex: Dictionary = {}

static func paint_color(kind: String) -> Color:
	match kind:
		"azul", "azul_c": return BLUE
		"verm", "verm_c": return RED
		"amar", "amar_c": return YELLOW
	return Color(0.9, 0.9, 0.9)

static func item_name(kind: String) -> String:
	match kind:
		"lata": return "Lata vazia"
		"massa": return "Massa corrida"
		"rolo": return "Rolo 23cm"
		"azul": return "Tinta Azul"
		"verm": return "Tinta Vermelha"
		"amar": return "Tinta Amarela"
		"azul_c", "verm_c", "amar_c": return "Tinta sem misturar"
	return kind

static func mat(c: Color, rough: float = 0.7) -> StandardMaterial3D:
	var key = c.to_html() + str(rough)
	if not _mats.has(key):
		var m = StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		_mats[key] = m
	return _mats[key]

static func tex_mat(path: String, world_scale: float, tint: Color = Color.WHITE, rough: float = 0.9) -> StandardMaterial3D:
	var key = path + str(world_scale) + tint.to_html()
	if not _tex.has(key):
		var m = StandardMaterial3D.new()
		m.albedo_texture = load(path)
		m.albedo_color = tint
		m.roughness = rough
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(world_scale, world_scale, world_scale)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_tex[key] = m
	return _tex[key]

# ------------------------------------------------------------------ geometria

## caixa com cantos chanfrados (vertex color). b = chanfro
static func bevel_box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color, b: float = 0.05) -> void:
	var h = s * 0.5
	var bb = minf(b, minf(h.x, minf(h.y, h.z)) * 0.9)
	var i = h - Vector3(bb, bb, bb)
	var E = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	var ec = col.lightened(0.07)
	for a in range(3):
		for sg in [-1.0, 1.0]:
			var o1 = (a + 1) % 3
			var o2 = (a + 2) % 3
			var ctr = c + E[a] * sg * h[a]
			var p0 = ctr + E[o1] * (-i[o1]) + E[o2] * (-i[o2])
			var p1 = ctr + E[o1] * (i[o1]) + E[o2] * (-i[o2])
			var p2 = ctr + E[o1] * (i[o1]) + E[o2] * (i[o2])
			var p3 = ctr + E[o1] * (-i[o1]) + E[o2] * (i[o2])
			var fc = col
			if a == 1 and sg > 0.0:
				fc = col.lightened(0.12)
			elif a == 1:
				fc = col.darkened(0.3)
			U.quad(st, p0, p1, p2, p3, fc, E[a] * sg)
	for pair in [[0, 1, 2], [0, 2, 1], [1, 2, 0]]:
		var a2 = pair[0]
		var b2 = pair[1]
		var t = pair[2]
		for sa in [-1.0, 1.0]:
			for sb in [-1.0, 1.0]:
				var base_a = c + E[a2] * sa * h[a2] + E[b2] * sb * i[b2]
				var base_b = c + E[a2] * sa * i[a2] + E[b2] * sb * h[b2]
				var q0 = base_a - E[t] * i[t]
				var q1 = base_a + E[t] * i[t]
				var q2 = base_b + E[t] * i[t]
				var q3 = base_b - E[t] * i[t]
				U.quad(st, q0, q1, q2, q3, ec, E[a2] * sa + E[b2] * sb)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var v0 = c + Vector3(sx * h.x, sy * i.y, sz * i.z)
				var v1 = c + Vector3(sx * i.x, sy * h.y, sz * i.z)
				var v2 = c + Vector3(sx * i.x, sy * i.y, sz * h.z)
				U.tri(st, v0, v1, v2, ec, Vector3(sx, sy, sz))

## cilindro horizontal com eixo em X
static func cyl_x(st: SurfaceTool, c: Vector3, r: float, length: float, col: Color, segs: int = 12) -> void:
	var x0 = c.x - length * 0.5
	var x1 = c.x + length * 0.5
	for k in range(segs):
		var a0 = TAU * float(k) / float(segs)
		var a1 = TAU * float(k + 1) / float(segs)
		var d0 = Vector3(0, cos(a0), sin(a0))
		var d1 = Vector3(0, cos(a1), sin(a1))
		var b0 = Vector3(x0, c.y, c.z) + d0 * r
		var b1 = Vector3(x0, c.y, c.z) + d1 * r
		var t0 = Vector3(x1, c.y, c.z) + d0 * r
		var t1 = Vector3(x1, c.y, c.z) + d1 * r
		U.quad(st, b0, t0, t1, b1, col, d0 + d1)
		U.tri(st, Vector3(x1, c.y, c.z), t1, t0, col.lightened(0.1), Vector3.RIGHT)
		U.tri(st, Vector3(x0, c.y, c.z), b0, b1, col.darkened(0.1), Vector3.LEFT)

static func _inst(st: SurfaceTool, rough: float = 0.6) -> MeshInstance3D:
	return U.mesh_inst(st, U.vcol_mat(rough))

# ------------------------------------------------------------------ itens

static func _can(st: SurfaceTool, p: Vector3, label: Color, s: float, lid: Color = Color(0.62, 0.64, 0.7)) -> void:
	U.cyl(st, p + Vector3(0, 0.22 * s, 0), 0.19 * s, 0.44 * s, TIN, 14)
	U.cyl(st, p + Vector3(0, 0.22 * s, 0), 0.198 * s, 0.26 * s, label, 14)
	U.cyl(st, p + Vector3(0, 0.45 * s, 0), 0.205 * s, 0.04 * s, lid, 14, -1.0, true)
	U.cyl(st, p + Vector3(0, 0.01 * s, 0), 0.205 * s, 0.03 * s, Color(0.55, 0.57, 0.62), 14)
	# alça
	U.box(st, p + Vector3(0, 0.5 * s, 0), Vector3(0.3 * s, 0.025 * s, 0.025 * s), Color(0.35, 0.36, 0.4))

static func _bucket(st: SurfaceTool, p: Vector3, col: Color, s: float) -> void:
	U.cyl(st, p + Vector3(0, 0.2 * s, 0), 0.22 * s, 0.4 * s, col, 14, 0.27 * s, true)
	U.cyl(st, p + Vector3(0, 0.43 * s, 0), 0.285 * s, 0.07 * s, Color(0.96, 0.96, 0.96), 14, -1.0, true)
	U.cyl(st, p + Vector3(0, 0.1 * s, 0), 0.225 * s, 0.09 * s, Color(0.85, 0.2, 0.15), 14)

static func _roller(st: SurfaceTool, p: Vector3, col: Color, s: float) -> void:
	cyl_x(st, p + Vector3(0, 0.34 * s, 0), 0.1 * s, 0.46 * s, col, 12)
	U.box(st, p + Vector3(0.0, 0.34 * s, 0), Vector3(0.5 * s, 0.03 * s, 0.03 * s), Color(0.65, 0.66, 0.72))
	U.box(st, p + Vector3(0.24 * s, 0.26 * s, 0), Vector3(0.025 * s, 0.14 * s, 0.025 * s), Color(0.65, 0.66, 0.72))
	U.cyl(st, p + Vector3(0.24 * s, 0.12 * s, 0), 0.04 * s, 0.24 * s, Color(0.15, 0.3, 0.7), 8)

## item carregável. Origem = base do item
static func item_node(kind: String, s: float = 1.5) -> Node3D:
	if kind == "lata":
		var sc = DL.scan_can(0.44 * s / 0.36)
		if sc != null:
			var holder = Node3D.new()
			holder.add_child(sc)
			return holder
	var st = U.new_st()
	match kind:
		"lata":
			_can(st, Vector3.ZERO, Color(0.92, 0.92, 0.95), s)
		"azul_c", "verm_c", "amar_c":
			_can(st, Vector3.ZERO, Color(0.92, 0.92, 0.95), s, paint_color(kind))
			U.cyl(st, Vector3(0, 0.46 * s, 0), 0.17 * s, 0.03 * s, paint_color(kind), 14)
		"azul", "verm", "amar":
			_can(st, Vector3.ZERO, paint_color(kind), s, Color(0.95, 0.95, 0.97))
		"massa":
			_bucket(st, Vector3.ZERO, YELLOW, s)
		_:
			_roller(st, Vector3.ZERO, Color(0.9, 0.3, 0.1), s)
	var n = Node3D.new()
	n.add_child(_inst(st, 0.45))
	return n

## pilha decorativa de itens (caixa de reposição)
static func stack_node(kind: String, w: float, d: float) -> Node3D:
	var st = U.new_st()
	var cols = 3
	var rows = 2
	var extra: Array = []
	for ix in range(cols):
		for iz in range(rows):
			var p = Vector3(-w * 0.5 + w * (ix + 0.5) / cols, 0, -d * 0.5 + d * (iz + 0.5) / rows)
			match kind:
				"lata":
					var sc = DL.scan_can(1.15 * 0.44 / 0.36)
					if sc != null:
						sc.position = p
						sc.rotation.y = (ix * 2 + iz) * 0.9
						extra.append(sc)
					else:
						_can(st, p, Color(0.92, 0.92, 0.95), 1.15)
				"massa":
					_bucket(st, p, YELLOW, 1.1)
				_:
					_roller(st, p, Color(0.9, 0.3, 0.1), 1.0)
	var n = Node3D.new()
	if extra.size() == 0:
		n.add_child(_inst(st, 0.55))
	for e in extra:
		n.add_child(e)
	return n

# ------------------------------------------------------------------ estações

## balcão básico (corpo azul-petróleo + tampo claro com borda escura). pos = centro do retângulo no chão
static func counter(parent: Node3D, r: Rect2, h: float = 0.9) -> Vector3:
	var cx = r.position.x + r.size.x * 0.5
	var cz = r.position.y + r.size.y * 0.5
	var st = U.new_st()
	bevel_box(st, Vector3(cx, h * 0.5, cz), Vector3(r.size.x - 0.02, h, r.size.y - 0.02), BODY, 0.06)
	bevel_box(st, Vector3(cx, h + 0.02, cz), Vector3(r.size.x + 0.04, 0.08, r.size.y + 0.04), RIM, 0.03)
	bevel_box(st, Vector3(cx, h + 0.09, cz), Vector3(r.size.x - 0.04, 0.1, r.size.y - 0.04), TOP, 0.04)
	# portinhas
	var n = int(r.size.x)
	for k in range(max(n, 1)):
		var dx = -r.size.x * 0.5 + (k + 0.5) * r.size.x / max(n, 1)
		bevel_box(st, Vector3(cx + dx, h * 0.45, cz + r.size.y * 0.5 - 0.005), Vector3(r.size.x / max(n, 1) - 0.14, h * 0.62, 0.03), BODY.lightened(0.12), 0.015)
	parent.add_child(_inst(st, 0.5))
	return Vector3(cx, h + 0.14, cz)

static func tint_machine(parent: Node3D, r: Rect2, col: Color) -> Vector3:
	var slot = counter(parent, r)
	var cx = r.position.x + r.size.x * 0.5
	var cz = r.position.y + r.size.y * 0.5
	var st = U.new_st()
	# corpo traseiro
	bevel_box(st, Vector3(cx, 1.55, r.position.y + 0.3), Vector3(r.size.x - 0.15, 1.3, 0.55), Color(0.88, 0.9, 0.93), 0.08)
	bevel_box(st, Vector3(cx, 2.3, r.position.y + 0.3), Vector3(r.size.x - 0.05, 0.22, 0.65), col.darkened(0.15), 0.07)
	# painel frontal colorido e display
	bevel_box(st, Vector3(cx, 1.7, r.position.y + 0.6), Vector3(r.size.x - 0.4, 0.3, 0.06), col, 0.02)
	bevel_box(st, Vector3(cx, 1.28, r.position.y + 0.6), Vector3(0.5, 0.2, 0.05), Color(0.1, 0.12, 0.16), 0.02)
	# bico dosador
	U.cyl(st, Vector3(cx, 1.5, cz - 0.02), 0.07, 0.35, Color(0.4, 0.42, 0.48), 10)
	U.cyl(st, Vector3(cx, 1.3, cz - 0.02), 0.045, 0.1, col, 10)
	# garrafas de corante no topo
	for k in range(3):
		U.cyl(st, Vector3(cx - 0.35 + k * 0.35, 2.58, r.position.y + 0.3), 0.12, 0.34, col.lightened(0.05 * k), 10)
	parent.add_child(_inst(st, 0.4))
	return slot

static func shaker(parent: Node3D, r: Rect2) -> Dictionary:
	var slot = counter(parent, r)
	var cx = r.position.x + r.size.x * 0.5
	var cz = r.position.y + r.size.y * 0.5
	var st = U.new_st()
	bevel_box(st, Vector3(cx, 1.0, cz), Vector3(0.8, 0.12, 0.8), Color(0.35, 0.37, 0.42), 0.04)
	for sx in [-1, 1]:
		bevel_box(st, Vector3(cx + 0.38 * sx, 1.55, r.position.y + 0.25), Vector3(0.1, 1.1, 0.1), Color(0.7, 0.72, 0.78), 0.03)
	bevel_box(st, Vector3(cx, 2.15, r.position.y + 0.25), Vector3(0.9, 0.14, 0.14), Color(0.7, 0.72, 0.78), 0.04)
	parent.add_child(_inst(st, 0.4))
	var clamp_node = Node3D.new()
	clamp_node.position = Vector3(cx, 1.65, cz)
	var st2 = U.new_st()
	bevel_box(st2, Vector3.ZERO, Vector3(0.7, 0.1, 0.7), Color(0.2, 0.7, 0.35), 0.04)
	bevel_box(st2, Vector3(0, 0.25, -0.1), Vector3(0.12, 0.45, 0.12), Color(0.7, 0.72, 0.78), 0.03)
	clamp_node.add_child(_inst(st2, 0.4))
	parent.add_child(clamp_node)
	return {"slot": Vector3(cx, 1.0 + 0.06, cz), "clamp": clamp_node, "clamp_rest": 1.65}

static func bin(parent: Node3D, r: Rect2) -> void:
	var cx = r.position.x + r.size.x * 0.5
	var cz = r.position.y + r.size.y * 0.5
	var st = U.new_st()
	U.cyl(st, Vector3(cx, 0.45, cz), 0.38, 0.9, Color(0.32, 0.36, 0.42), 14, 0.44, true)
	U.cyl(st, Vector3(cx, 0.93, cz), 0.47, 0.1, Color(0.2, 0.23, 0.28), 14, -1.0, true)
	U.cyl(st, Vector3(cx, 0.99, cz), 0.3, 0.03, Color(0.06, 0.07, 0.09), 14)
	parent.add_child(_inst(st, 0.5))

static func plant(parent: Node3D, p: Vector3, s: float = 1.0) -> void:
	var st = U.new_st()
	U.cyl(st, p + Vector3(0, 0.25 * s, 0), 0.27 * s, 0.5 * s, Color(0.78, 0.38, 0.2), 12, 0.34 * s, true)
	U.cyl(st, p + Vector3(0, 0.52 * s, 0), 0.36 * s, 0.07 * s, Color(0.68, 0.3, 0.16), 12)
	U.cyl(st, p + Vector3(0, 0.53 * s, 0), 0.28 * s, 0.04 * s, Color(0.25, 0.15, 0.1), 12)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(p.x * 13 + p.z * 7)
	for k in range(7):
		var a = TAU * k / 7.0
		var d = Vector3(cos(a), 0, sin(a))
		var tip = p + Vector3(0, (1.2 + rng.randf() * 0.4) * s, 0) + d * 0.55 * s
		var base = p + Vector3(0, 0.55 * s, 0) + d * 0.04
		var side = Vector3(-d.z, 0, d.x) * 0.11 * s
		var mid = (base + tip) * 0.5 + Vector3(0, 0.12 * s, 0) + d * 0.1 * s
		var gcol = Color(0.25, 0.62, 0.25) if k % 2 == 0 else Color(0.2, 0.5, 0.2)
		U.tri(st, base, mid + side, tip, gcol, Vector3.UP)
		U.tri(st, base, tip, mid - side, gcol.lightened(0.08), Vector3.UP)
		U.tri(st, base, mid + side, tip, gcol, Vector3.DOWN)
		U.tri(st, base, tip, mid - side, gcol, Vector3.DOWN)
	parent.add_child(_inst(st, 0.8))

static func tree(parent: Node3D, p: Vector3, s: float = 1.0) -> void:
	var st = U.new_st()
	U.cyl(st, p + Vector3(0, 0.9 * s, 0), 0.17 * s, 1.8 * s, Color(0.45, 0.3, 0.16), 8, 0.22 * s, true)
	parent.add_child(_inst(st, 0.9))
	var greens = [Color(0.42, 0.55, 0.15), Color(0.5, 0.62, 0.18), Color(0.36, 0.5, 0.14)]
	var offs = [Vector3(0, 2.5, 0), Vector3(0.6, 2.2, 0.2), Vector3(-0.55, 2.3, -0.2), Vector3(0.1, 3.0, -0.4), Vector3(-0.2, 2.2, 0.6)]
	for k in range(offs.size()):
		var sp = SphereMesh.new()
		sp.radius = (0.95 - 0.05 * k) * s
		sp.height = sp.radius * 1.8
		sp.radial_segments = 10
		sp.rings = 6
		var mi = MeshInstance3D.new()
		mi.mesh = sp
		mi.material_override = mat(greens[k % 3], 0.9)
		mi.position = p + offs[k] * s
		parent.add_child(mi)

# ------------------------------------------------------------------ personagens

static func _mesh_mi(mesh: Mesh, c: Color, parent: Node3D, pos: Vector3, rough: float = 0.7) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(c, rough)
	mi.position = pos
	parent.add_child(mi)
	return mi

## chef/cliente "fofo": cabeça grande, corpo robusto. Metadados compatíveis com Chars.walk
static func person(shirt: Color, skin: Color, hair: Color, pants: Color, cap: bool, logo: bool) -> Node3D:
	var root = Node3D.new()
	var body = Node3D.new()
	root.add_child(body)
	var torso = CapsuleMesh.new()
	torso.radius = 0.3
	torso.height = 0.85
	torso.radial_segments = 12
	torso.rings = 4
	_mesh_mi(torso, shirt, body, Vector3(0, 0.98, 0))
	# cabeça grande
	var head = SphereMesh.new()
	head.radius = 0.29
	head.height = 0.56
	head.radial_segments = 16
	head.rings = 10
	_mesh_mi(head, skin, body, Vector3(0, 1.62, 0))
	# nariz, orelhas
	var nose = SphereMesh.new()
	nose.radius = 0.045
	nose.height = 0.09
	nose.radial_segments = 6
	nose.rings = 4
	_mesh_mi(nose, skin.darkened(0.08), body, Vector3(0, 1.58, -0.28))
	for sx in [-1, 1]:
		var ear = SphereMesh.new()
		ear.radius = 0.06
		ear.height = 0.12
		ear.radial_segments = 6
		ear.rings = 4
		_mesh_mi(ear, skin, body, Vector3(0.28 * sx, 1.6, 0.0))
	# olhos
	var eye = SphereMesh.new()
	eye.radius = 0.045
	eye.height = 0.09
	eye.radial_segments = 6
	eye.rings = 4
	for sx in [-1, 1]:
		_mesh_mi(eye, Color(0.05, 0.05, 0.07), body, Vector3(0.1 * sx, 1.66, -0.255), 0.3)
	var mouth = BoxMesh.new()
	mouth.size = Vector3(0.12, 0.025, 0.02)
	_mesh_mi(mouth, Color(0.55, 0.2, 0.2), body, Vector3(0, 1.5, -0.265))
	if cap:
		var cm = SphereMesh.new()
		cm.radius = 0.31
		cm.height = 0.34
		cm.radial_segments = 14
		cm.rings = 6
		_mesh_mi(cm, shirt, body, Vector3(0, 1.8, 0.01))
		var band = CylinderMesh.new()
		band.top_radius = 0.3
		band.bottom_radius = 0.3
		band.height = 0.06
		band.radial_segments = 14
		_mesh_mi(band, Color(0.96, 0.78, 0.12), body, Vector3(0, 1.73, 0.0))
		var vis = BoxMesh.new()
		vis.size = Vector3(0.34, 0.035, 0.22)
		_mesh_mi(vis, shirt.darkened(0.1), body, Vector3(0, 1.74, -0.33))
	else:
		var hm = SphereMesh.new()
		hm.radius = 0.3
		hm.height = 0.34
		hm.radial_segments = 14
		hm.rings = 6
		_mesh_mi(hm, hair, body, Vector3(0, 1.83, 0.04))
	if logo:
		var q = QuadMesh.new()
		q.size = Vector2(0.3, 0.09)
		var lm = StandardMaterial3D.new()
		lm.albedo_texture = Chars.logo()
		lm.roughness = 0.9
		lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		var f = MeshInstance3D.new()
		f.mesh = q
		f.material_override = lm
		f.position = Vector3(0.1, 1.12, -0.305)
		f.rotation.y = PI
		body.add_child(f)
	# braços
	var armm = CapsuleMesh.new()
	armm.radius = 0.085
	armm.height = 0.52
	armm.radial_segments = 8
	armm.rings = 3
	for sx in [-1, 1]:
		var piv = Node3D.new()
		piv.position = Vector3(0.38 * sx, 1.28, 0)
		body.add_child(piv)
		_mesh_mi(armm, shirt, piv, Vector3(0, -0.2, 0))
		var hand = SphereMesh.new()
		hand.radius = 0.09
		hand.height = 0.18
		hand.radial_segments = 8
		hand.rings = 4
		_mesh_mi(hand, Color(0.97, 0.97, 0.97), piv, Vector3(0, -0.46, 0))
		root.set_meta("arm" + ("L" if sx < 0 else "R"), piv)
	# pernas
	var legm = CapsuleMesh.new()
	legm.radius = 0.11
	legm.height = 0.56
	legm.radial_segments = 8
	legm.rings = 3
	var shoe = SphereMesh.new()
	shoe.radius = 0.14
	shoe.height = 0.2
	shoe.radial_segments = 8
	shoe.rings = 4
	for sx in [-1, 1]:
		var pv = Node3D.new()
		pv.position = Vector3(0.15 * sx, 0.58, 0)
		body.add_child(pv)
		_mesh_mi(legm, pants, pv, Vector3(0, -0.22, 0))
		var sh = _mesh_mi(shoe, Color(0.15, 0.12, 0.12), pv, Vector3(0, -0.5, -0.05))
		sh.scale = Vector3(1.0, 0.7, 1.5)
		root.set_meta("leg" + ("L" if sx < 0 else "R"), pv)
	root.set_meta("body", body)
	return root

static func chef() -> Node3D:
	return person(Color(0.10, 0.17, 0.42), Color(0.93, 0.74, 0.6), Color(0.15, 0.1, 0.06), Color(0.2, 0.22, 0.3), true, true)

static func customer(variant: int) -> Node3D:
	var shirts = [Color(0.85, 0.3, 0.25), Color(0.25, 0.6, 0.35), Color(0.9, 0.7, 0.2), Color(0.55, 0.35, 0.65), Color(0.2, 0.55, 0.8), Color(0.9, 0.5, 0.15)]
	var skins = [Color(0.93, 0.74, 0.6), Color(0.75, 0.55, 0.4), Color(0.55, 0.38, 0.28), Color(0.86, 0.66, 0.5)]
	var hairs = [Color(0.12, 0.08, 0.05), Color(0.3, 0.2, 0.1), Color(0.05, 0.05, 0.05), Color(0.6, 0.45, 0.2)]
	return person(shirts[variant % shirts.size()], skins[variant % 4], hairs[(variant + 1) % 4], Color(0.25, 0.28, 0.4), false, false)
