class_name Props
extends RefCounted
## Objetos de cenário: latas de tinta, baldes, prateleiras, árvores, rolo.

const PALETTE = [Color(0.85, 0.15, 0.15), Color(0.15, 0.35, 0.8), Color(0.95, 0.8, 0.15),
	Color(0.2, 0.65, 0.3), Color(0.95, 0.95, 0.95), Color(0.92, 0.5, 0.1),
	Color(0.55, 0.25, 0.65), Color(0.15, 0.15, 0.2), Color(0.1, 0.65, 0.7)]
const WOOD = Color(0.55, 0.36, 0.2)
const WOOD_D = Color(0.38, 0.24, 0.14)
const TIN = Color(0.78, 0.8, 0.84)

static func can(st: SurfaceTool, pos: Vector3, label: Color, s: float = 1.0, segs: int = 10) -> void:
	U.cyl(st, pos + Vector3(0, 0.18 * s, 0), 0.14 * s, 0.36 * s, TIN, segs)
	U.cyl(st, pos + Vector3(0, 0.18 * s, 0), 0.146 * s, 0.2 * s, label, segs)
	U.cyl(st, pos + Vector3(0, 0.375 * s, 0), 0.15 * s, 0.03 * s, Color(0.6, 0.62, 0.66), segs)

static func bucket(st: SurfaceTool, pos: Vector3, col: Color, s: float = 1.0) -> void:
	U.cyl(st, pos + Vector3(0, 0.17 * s, 0), 0.19 * s, 0.34 * s, col, 10, 0.22 * s)
	U.cyl(st, pos + Vector3(0, 0.36 * s, 0), 0.225 * s, 0.05 * s, Color(0.92, 0.92, 0.92), 10)

static func roller(st: SurfaceTool, pos: Vector3, col: Color, s: float = 1.0) -> void:
	# rolo deitado (aproximação em caixas): cabo + cilindro
	U.box(st, pos + Vector3(0, 0.25 * s, 0), Vector3(0.05 * s, 0.4 * s, 0.05 * s), Color(0.15, 0.15, 0.2))
	U.box(st, pos + Vector3(0, 0.46 * s, 0), Vector3(0.3 * s, 0.14 * s, 0.14 * s), col)
	U.box(st, pos + Vector3(0, 0.46 * s, 0), Vector3(0.32 * s, 0.05 * s, 0.05 * s), Color(0.6, 0.6, 0.65))

## prateleira de loja. pos = centro da base; frente voltada para +Z
static func shelf(st: SurfaceTool, pos: Vector3, w: float, h: float, d: float, seed_v: int, only: Color = Color(0, 0, 0, 0), kind: String = "can", lite: bool = false) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_v
	var levels = 4
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			U.box(st, pos + Vector3((w * 0.5 - 0.04) * sx, h * 0.5, (d * 0.5 - 0.04) * sz), Vector3(0.08, h, 0.08), WOOD_D)
	U.box(st, pos + Vector3(0, h * 0.5, -d * 0.5 + 0.02), Vector3(w, h, 0.04), WOOD_D)
	for l in range(levels):
		var y = 0.1 + (h - 0.2) * float(l) / float(levels)
		U.box(st, pos + Vector3(0, y, 0), Vector3(w, 0.05, d), WOOD)
		var n = int(w / (0.5 if lite else 0.34))
		for i in range(n):
			var cx = -w * 0.5 + 0.25 + float(i) * (w - 0.5) / float(max(n - 1, 1))
			var col = PALETTE[rng.randi() % PALETTE.size()]
			if only.a > 0.0:
				col = only
			var p = pos + Vector3(cx, y + 0.025, rng.randf_range(-0.05, 0.05))
			if kind == "bucket":
				bucket(st, p, col, 0.9)
			elif kind == "roller":
				roller(st, p, col, 0.9)
			else:
				can(st, p, col, 1.0, 6 if lite else 10)
				if d > 0.7 and not lite:
					can(st, p + Vector3(0, 0, -0.32), col, 1.0)
	U.box(st, pos + Vector3(0, h + 0.03, 0), Vector3(w + 0.1, 0.06, d + 0.1), WOOD_D)

## item carregável (Node3D) por tipo: branca, base, azul, massa, rolo
static func item(kind: String) -> Node3D:
	var st = U.new_st()
	if kind == "branca":
		can(st, Vector3.ZERO, Color(0.95, 0.95, 0.97), 1.6)
		U.cyl(st, Vector3(0, 0.29, 0), 0.241, 0.06, Color(0.2, 0.35, 0.8), 10)
	elif kind == "base":
		can(st, Vector3.ZERO, Color(0.45, 0.47, 0.5), 1.6)
	elif kind == "azul":
		can(st, Vector3.ZERO, Color(0.1, 0.3, 0.85), 1.6)
		U.cyl(st, Vector3(0, 0.29, 0), 0.241, 0.06, Color(0.95, 0.95, 0.97), 10)
	elif kind == "massa":
		bucket(st, Vector3.ZERO, Color(0.96, 0.82, 0.25), 1.6)
	else:
		roller(st, Vector3(0, 0, 0), Color(0.9, 0.3, 0.1), 1.6)
	return U.mesh_inst(st, U.vcol_mat())

static func item_color(kind: String) -> Color:
	match kind:
		"branca": return Color(0.95, 0.95, 0.97)
		"base": return Color(0.5, 0.52, 0.56)
		"azul": return Color(0.1, 0.3, 0.85)
		"massa": return Color(0.96, 0.82, 0.25)
	return Color(0.9, 0.3, 0.1)

static func item_name(kind: String) -> String:
	match kind:
		"branca": return "Tinta Branca"
		"base": return "Base p/ Tingir"
		"azul": return "Azul Del Rey"
		"massa": return "Massa Corrida"
	return "Rolo 23cm"

static var _tree_mesh: ArrayMesh = null

static func tree_mesh() -> ArrayMesh:
	if _tree_mesh == null:
		var st = U.new_st()
		U.cyl(st, Vector3(0, 1.2, 0), 0.2, 2.4, Color(0.42, 0.29, 0.18), 6, 0.13)
		var cb = Color(0.13, 0.38, 0.17)
		var ct = Color(0.42, 0.74, 0.28)
		U.sphere(st, Vector3(0, 3.7, 0), 1.9, cb, ct)
		U.sphere(st, Vector3(1.1, 3.2, 0.4), 1.3, cb, ct)
		U.sphere(st, Vector3(-1.0, 3.9, -0.5), 1.3, cb, ct)
		_tree_mesh = st.commit()
	return _tree_mesh

static var _pole_mesh: ArrayMesh = null

static func pole_mesh() -> ArrayMesh:
	if _pole_mesh == null:
		var st = U.new_st()
		U.cyl(st, Vector3(0, 3.6, 0), 0.11, 7.2, Color(0.58, 0.58, 0.56), 6, 0.08)
		U.box(st, Vector3(0.9, 6.95, 0), Vector3(1.8, 0.08, 0.08), Color(0.3, 0.3, 0.33))
		U.box(st, Vector3(1.75, 6.85, 0), Vector3(0.55, 0.12, 0.26), Color(1.0, 0.95, 0.7))
		U.box(st, Vector3(0, 6.3, 0), Vector3(0.08, 0.07, 1.3), Color(0.25, 0.22, 0.2))
		_pole_mesh = st.commit()
	return _pole_mesh

## Rolo de pintura em primeira pessoa (frente = -Z)
static func roller_view(paint: Color) -> Node3D:
	var root = Node3D.new()
	var handle = MeshInstance3D.new()
	var hm = CylinderMesh.new()
	hm.top_radius = 0.022
	hm.bottom_radius = 0.026
	hm.height = 0.5
	handle.mesh = hm
	handle.material_override = U.mat(Color(0.1, 0.1, 0.12))
	handle.position = Vector3(0, -0.08, 0)
	root.add_child(handle)
	var roll = MeshInstance3D.new()
	var rm = CylinderMesh.new()
	rm.top_radius = 0.075
	rm.bottom_radius = 0.075
	rm.height = 0.34
	rm.radial_segments = 14
	roll.mesh = rm
	roll.material_override = U.mat(paint, 0.95)
	roll.rotation.z = PI * 0.5
	roll.position = Vector3(0, 0.22, 0)
	root.add_child(roll)
	var bar = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.03, 0.03, 0.03)
	bar.mesh = bm
	bar.material_override = U.mat(Color(0.7, 0.7, 0.75), 0.4, 0.8)
	bar.position = Vector3(0, 0.17, 0)
	root.add_child(bar)
	return root

## Pistola de tinta em primeira pessoa (frente = -Z)
static func pistol_view(paint: Color) -> Node3D:
	var root = Node3D.new()
	var parts = [
		[Vector3(0.07, 0.1, 0.3), Vector3(0, 0, 0), Color(0.15, 0.16, 0.2)],
		[Vector3(0.05, 0.05, 0.18), Vector3(0, 0.01, -0.22), Color(0.6, 0.62, 0.68)],
		[Vector3(0.06, 0.16, 0.08), Vector3(0, -0.12, 0.1), Color(0.1, 0.1, 0.12)]]
	for pt in parts:
		var mi = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = pt[0]
		mi.mesh = bm
		mi.material_override = U.mat(pt[2], 0.5, 0.4)
		mi.position = pt[1]
		root.add_child(mi)
	var tank = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.05
	cm.height = 0.16
	tank.mesh = cm
	tank.material_override = U.emissive_mat(paint, 0.8)
	tank.rotation.x = PI * 0.5
	tank.position = Vector3(0, 0.09, -0.02)
	root.add_child(tank)
	return root
