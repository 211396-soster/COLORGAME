class_name City
extends Node3D
## Cidade de Passo Fundo gerada a partir dos dados do OpenStreetMap (map_osm.xml -> data/city.tres).
## Dados (c) OpenStreetMap contributors, licença ODbL. Carregamento por setores (chunks de 250 m).

const CHUNK = 250.0
const WALLS = [Color(0.96, 0.94, 0.88), Color(0.9, 0.86, 0.72), Color(0.82, 0.9, 0.95), Color(0.95, 0.8, 0.7),
	Color(0.85, 0.85, 0.88), Color(0.8, 0.88, 0.78), Color(0.97, 0.97, 0.97), Color(0.93, 0.78, 0.5)]
const ROOFS = [Color(0.72, 0.32, 0.2), Color(0.58, 0.26, 0.18), Color(0.45, 0.5, 0.55), Color(0.5, 0.36, 0.28)]
const TOWERS = [Color(0.86, 0.87, 0.9), Color(0.93, 0.9, 0.84), Color(0.78, 0.82, 0.88), Color(0.9, 0.85, 0.78)]
const ASPHALT = Color(0.22, 0.23, 0.26)
const WALK = Color(0.7, 0.7, 0.67)

var data: Dictionary = {}
var places: Array = []
var roads_b: Dictionary = {}
var builds_b: Dictionary = {}
var parks_b: Dictionary = {}
var water_b: Dictionary = {}
var edges: Dictionary = {}
var edges_dyn: Dictionary = {}
var chunks: Dictionary = {}
var dest_points: Array = []
var astar: AStar2D = AStar2D.new()
var radius: int = 3

var store_pos: Vector3 = Vector3.ZERO
var store_yaw: float = 0.0
var spawn_pos: Vector3 = Vector3.ZERO
var spawn_yaw: float = 0.0
var base_street: String = ""
var loaded: bool = false

var _mat_flat: StandardMaterial3D
var _mat_road: StandardMaterial3D
var _mat_walk: StandardMaterial3D
var _store_info: Array = []

func setup(rad: int) -> void:
	radius = rad
	_mat_flat = U.vcol_mat(0.9)
	_mat_road = _tex_mat(_preferred_tex("res://tex/realism/Asphalt003_2K-JPG_Color.jpg", "res://tex/ph/asphalt.jpg"), 0.22, Color(1.08, 1.08, 1.08), 0.94)
	_mat_walk = _tex_mat(_preferred_tex("res://tex/realism/PavingStones002_2K-JPG_Color.jpg", "res://tex/ph/walk.jpg"), 0.45, Color(1.25, 1.25, 1.22), 0.9)
	var res = load("res://data/city.tres")
	var txt = ""
	if res != null:
		txt = res.json_text
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Falha ao ler data/city.tres")
		return
	data = parsed
	places = data.get("places", [])
	_find_base()
	_bucket()
	_build_graph()
	_add_ground()
	_add_store()
	loaded = true

func _preferred_tex(primary: String, fallback: String) -> String:
	return primary if ResourceLoader.exists(primary) else fallback

func _tex_mat(path: String, scale: float, tint: Color, rough: float) -> StandardMaterial3D:
	var m = U.vcol_mat(rough)
	if ResourceLoader.exists(path):
		m.albedo_texture = load(path)
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(scale, scale, scale)
		m.albedo_color = tint
		# Micro-relevo sutil para quebrar o aspecto liso sem aumentar o tamanho do projeto.
		var normal_path = path.replace("_Color.jpg", "_NormalGL.jpg")
		var roughness_path = path.replace("_Color.jpg", "_Roughness.jpg")
		m.normal_enabled = true
		if path.begins_with("res://tex/realism/") and ResourceLoader.exists(normal_path):
			m.normal_texture = load(normal_path)
			m.normal_scale = 0.55 if scale < 0.3 else 0.35
		else:
			m.normal_texture = U.detail_normal_texture(17 if scale < 0.3 else 31)
			m.normal_scale = 0.28 if scale < 0.3 else 0.18
		if path.begins_with("res://tex/realism/") and ResourceLoader.exists(roughness_path):
			m.roughness_texture = load(roughness_path)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	else:
		m.albedo_color = Color(0.3, 0.3, 0.32) if scale < 0.3 else Color(0.7, 0.7, 0.67)
	return m

func _key(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / CHUNK), floori(z / CHUNK))

func _find_base() -> void:
	var best = 1e12
	var bs = []
	for r in data["roads"]:
		if r["w"] < 7 or r["n"] == "":
			continue
		var p = r["p"]
		for i in range(0, p.size() - 3, 2):
			var x0 = p[i]
			var z0 = p[i + 1]
			var x1 = p[i + 2]
			var z1 = p[i + 3]
			var l = Vector2(x1 - x0, z1 - z0).length()
			if l < 26.0:
				continue
			var mx = (x0 + x1) * 0.5
			var mz = (z0 + z1) * 0.5
			var d = mx * mx + mz * mz
			if d < best:
				best = d
				bs = [x0, z0, x1, z1, r["w"], r["n"]]
	if bs.size() == 0:
		store_pos = Vector3(0, 0, 20)
		spawn_pos = Vector3.ZERO
		return
	var dir = Vector2(bs[2] - bs[0], bs[3] - bs[1]).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var mid = Vector2((bs[0] + bs[2]) * 0.5, (bs[1] + bs[3]) * 0.5)
	var w = float(bs[4])
	var sp = mid + perp * (w * 0.5 + 8.0)
	store_pos = Vector3(sp.x, 0, sp.y)
	store_yaw = atan2(-perp.x, -perp.y)
	var lane = mid + perp * (w * 0.22)
	spawn_pos = Vector3(lane.x, 0, lane.y)
	spawn_yaw = atan2(-dir.x, -dir.y)
	base_street = str(bs[5])
	# retângulo local da loja (x[-12,12], z[-14,0]) em coordenadas do mundo, para colisão
	var c = cos(store_yaw)
	var s = sin(store_yaw)
	var pts = []
	for lp in [Vector2(-12, 0), Vector2(12, 0), Vector2(12, -14), Vector2(-12, -14)]:
		pts.append(Vector2(sp.x + lp.x * c + lp.y * s, sp.y - lp.x * s + lp.y * c))
	_store_info = pts

func _in_store(x: float, z: float) -> bool:
	var dx = x - store_pos.x
	var dz = z - store_pos.z
	var c = cos(store_yaw)
	var s = sin(store_yaw)
	var lx = dx * c - dz * s
	var lz = dx * s + dz * c
	return lx > -16.0 and lx < 16.0 and lz > -18.0 and lz < 8.0

func _bheight(b: Dictionary, area: float, cx: float, cz: float) -> float:
	if b["h"] > 0:
		return clampf(b["h"], 3.0, 80.0)
	var hsh = int(absf(cx * 7.3 + cz * 3.1)) % 100
	var dc = sqrt(cx * cx + cz * cz)
	var h = 3.4 + float(hsh % 4) * 0.6
	if area > 350.0:
		h = 6.0 + float(hsh % 3) * 3.0
	if dc < 900.0 and hsh % 5 == 0:
		h = 12.0 + float(hsh % 7) * 3.0
	if dc < 450.0 and hsh % 3 == 0:
		h = 18.0 + float(hsh % 9) * 3.0
	return h

func _push(dict: Dictionary, k: Vector2i, v) -> void:
	if not dict.has(k):
		dict[k] = []
	dict[k].append(v)

func _bucket() -> void:
	for r in data["roads"]:
		var p = r["p"]
		for i in range(0, p.size() - 3, 2):
			var mx = (p[i] + p[i + 2]) * 0.5
			var mz = (p[i + 1] + p[i + 3]) * 0.5
			_push(roads_b, _key(mx, mz), [p[i], p[i + 1], p[i + 2], p[i + 3], r["w"], r["n"]])
	for b in data["buildings"]:
		var p = b["p"]
		var n = p.size() / 2
		if n < 3:
			continue
		var pts = PackedVector2Array()
		var cx = 0.0
		var cz = 0.0
		for i in range(n):
			pts.append(Vector2(p[i * 2], p[i * 2 + 1]))
			cx += p[i * 2]
			cz += p[i * 2 + 1]
		cx /= n
		cz /= n
		if _in_store(cx, cz):
			continue
		var area = 0.0
		for i in range(n):
			var j = (i + 1) % n
			area += pts[i].x * pts[j].y - pts[j].x * pts[i].y
		area = absf(area) * 0.5
		if area < 12.0:
			continue
		var h = _bheight(b, area, cx, cz)
		_push(builds_b, _key(cx, cz), {"pts": pts, "h": h, "cx": cx, "cz": cz})
		if area > 40.0 and area < 900.0:
			dest_points.append(Vector2(cx, cz))
		for i in range(n):
			var j = (i + 1) % n
			var mx = (pts[i].x + pts[j].x) * 0.5
			var mz = (pts[i].y + pts[j].y) * 0.5
			var ek = _key(mx, mz)
			if not edges.has(ek):
				edges[ek] = []
			var e = edges[ek]
			e.append(pts[i].x)
			e.append(pts[i].y)
			e.append(pts[j].x)
			e.append(pts[j].y)
	for pk in data["parks"]:
		if pk.size() >= 6:
			_push(parks_b, _key(pk[0], pk[1]), pk)
	for w in data["water"]:
		_push(water_b, _key(w["p"][0], w["p"][1]), w)
	# colisão da loja
	if _store_info.size() == 4:
		for i in range(4):
			var a = _store_info[i]
			var b2 = _store_info[(i + 1) % 4]
			var ek2 = _key((a.x + b2.x) * 0.5, (a.y + b2.y) * 0.5)
			if not edges.has(ek2):
				edges[ek2] = []
			var e2 = edges[ek2]
			e2.append(a.x)
			e2.append(a.y)
			e2.append(b2.x)
			e2.append(b2.y)

func _build_graph() -> void:
	var ids = {}
	var nid = 0
	for r in data["roads"]:
		var p = r["p"]
		var prev = -1
		for i in range(0, p.size(), 2):
			var key = Vector2i(roundi(p[i] * 0.5), roundi(p[i + 1] * 0.5))
			var id = -1
			if ids.has(key):
				id = ids[key]
			else:
				id = nid
				nid += 1
				ids[key] = id
				astar.add_point(id, Vector2(p[i], p[i + 1]))
			if prev != -1 and prev != id:
				astar.connect_points(prev, id, true)
			prev = id

func _add_ground() -> void:
	var mi = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(9000, 9000)
	mi.mesh = pm
	if ResourceLoader.exists("res://tex/ph/grass.jpg"):
		var gm = U.mat(Color(1, 1, 1), 1.0)
		gm.albedo_texture = load("res://tex/ph/grass.jpg")
		gm.uv1_scale = Vector3(1125, 1125, 1)
		gm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		mi.material_override = gm
		mi.position = Vector3(0, -0.02, 0)
		add_child(mi)
		return
	var img = Image.create(64, 64, true, Image.FORMAT_RGBA8)
	var rg = RandomNumberGenerator.new()
	rg.seed = 3
	for y in range(64):
		for x in range(64):
			var v = rg.randf_range(-0.05, 0.05)
			img.set_pixel(x, y, Color(0.42 + v, 0.58 + v * 1.5, 0.32 + v, 1.0))
	img.generate_mipmaps()
	var m = U.mat(Color(1, 1, 1), 1.0)
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.uv1_scale = Vector3(450, 450, 1)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mi.material_override = m
	mi.position = Vector3(0, -0.02, 0)
	add_child(mi)

func _add_store() -> void:
	var s = Facade.build_store()
	s.position = store_pos
	s.rotation.y = store_yaw
	add_child(s)

# ---------------------------------------------------------------- setores

func update(pos: Vector3, budget: int = 1, max_ring: int = -1) -> void:
	var c = _key(pos.x, pos.z)
	var rr = radius if max_ring < 0 else mini(radius, max_ring)
	var built = 0
	for ring in range(0, rr + 1):
		for dx in range(-ring, ring + 1):
			for dz in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dz)) != ring:
					continue
				var k = Vector2i(c.x + dx, c.y + dz)
				if not chunks.has(k) and built < budget:
					_make_chunk(k)
					built += 1
	for k in chunks.keys():
		if maxi(absi(k.x - c.x), absi(k.y - c.y)) > radius + 1:
			chunks[k].queue_free()
			chunks.erase(k)

func _mm(parent: Node3D, mesh: Mesh, xf: Array, cols: Array) -> void:
	if xf.size() == 0:
		return
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = cols.size() == xf.size()
	mm.mesh = mesh
	mm.instance_count = xf.size()
	for i in range(xf.size()):
		mm.set_instance_transform(i, xf[i])
		if mm.use_colors:
			mm.set_instance_color(i, cols[i])
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _mat_flat
	parent.add_child(mmi)

func _make_chunk(k: Vector2i) -> void:
	var root = Node3D.new()
	add_child(root)
	chunks[k] = root
	var st_flat = U.new_st()
	var st_road = U.new_st()
	var st_walk = U.new_st()
	var nroad = 0
	var nwalk = 0
	var st_house = U.new_st()
	var st_tower = U.new_st()
	var nflat = 0
	var nhouse = 0
	var ntower = 0
	var rng = RandomNumberGenerator.new()
	rng.seed = k.x * 7919 + k.y * 104729
	var trees: Array = []
	var tree_cols: Array = []
	var poles: Array = []
	var cars: Array = []
	var car_cols: Array = []
	var dyn: Array = []
	var pcols = Vehicles.paint_colors()
	for pk in parks_b.get(k, []):
		nflat += _flat_poly(st_flat, pk, 0.04, Color(0.35, 0.62, 0.3))
	for w in water_b.get(k, []):
		if w["c"] == 1:
			nflat += _flat_poly(st_flat, w["p"], 0.03, Color(0.25, 0.5, 0.78))
		else:
			var wp = w["p"]
			for i in range(0, wp.size() - 3, 2):
				nflat += _strip(st_flat, wp[i], wp[i + 1], wp[i + 2], wp[i + 3], 5.0, 0.03, Color(0.25, 0.5, 0.78))
	# ruas, postes, árvores e carros estacionados
	for s in roads_b.get(k, []):
		var w = s[4]
		nwalk += _strip(st_walk, s[0], s[1], s[2], s[3], w + 4.4, 0.06, Color.WHITE, 0.3)
		nwalk += _strip(st_walk, s[0], s[1], s[2], s[3], w + 0.9, 0.08, Color(0.8, 0.8, 0.78), 0.3)
		nroad += _strip(st_road, s[0], s[1], s[2], s[3], w, 0.10, Color.WHITE, 0.3)
		var l = Vector2(s[2] - s[0], s[3] - s[1]).length()
		if l < 1.0:
			continue
		var ux = (s[2] - s[0]) / l
		var uz = (s[3] - s[1]) / l
		if w >= 8 and l > 9.0:
			var nd = int(l / 7.0)
			for j in range(nd):
				var d0 = 1.5 + j * 7.0
				var d1 = d0 + 3.5
				if d1 > l:
					break
				nflat += _strip(st_flat, s[0] + ux * d0, s[1] + uz * d0, s[0] + ux * d1, s[1] + uz * d1, 0.18, 0.14, Color(0.95, 0.95, 0.88))
		if w >= 6 and l > 14.0:
			var d = 5.0
			while d < l - 5.0:
				var side = -1.0 if rng.randf() < 0.5 else 1.0
				if w <= 9 and rng.randf() < 0.42:
					var off = (w * 0.5 + 2.9) * side
					var tx = s[0] + ux * d - uz * off
					var tz = s[1] + uz * d + ux * off
					if _key(tx, tz) == k:
						var sc = rng.randf_range(0.8, 1.25)
						trees.append(Transform3D(Basis.from_scale(Vector3(sc, sc, sc)).rotated(Vector3.UP, rng.randf() * TAU), Vector3(tx, 0, tz)))
						tree_cols.append(Color(rng.randf_range(0.8, 1.0), rng.randf_range(0.88, 1.0), rng.randf_range(0.7, 1.0)))
				d += 22.0
			d = 9.0
			while d < l - 5.0:
				var sd = -1.0 if rng.randf() < 0.5 else 1.0
				var offp = (w * 0.5 + 1.6) * sd
				var px = s[0] + ux * d - uz * offp
				var pz = s[1] + uz * d + ux * offp
				if _key(px, pz) == k:
					var ov = Vector2(-uz * sd, ux * sd)
					poles.append(Transform3D(Basis(Vector3.UP, atan2(ov.y, -ov.x)), Vector3(px, 0, pz)))
				d += 38.0
			if w <= 10 and l > 18.0:
				d = 10.0
				while d < l - 8.0:
					if rng.randf() < 0.3:
						var sc2 = -1.0 if rng.randf() < 0.5 else 1.0
						var offc = (w * 0.5 - 1.15) * sc2
						var cx = s[0] + ux * d - uz * offc
						var cz = s[1] + uz * d + ux * offc
						if _key(cx, cz) == k:
							var yawc = atan2(-ux, -uz) + (PI if rng.randf() < 0.5 else 0.0)
							cars.append(Transform3D(Basis(Vector3.UP, yawc), Vector3(cx, 0, cz)))
							car_cols.append(pcols[rng.randi() % pcols.size()])
							var fx = Vector2(ux, uz) * 2.15
							var rx = Vector2(-uz, ux) * 0.95
							var c0 = Vector2(cx, cz)
							var q = [c0 + fx + rx, c0 + fx - rx, c0 - fx - rx, c0 - fx + rx]
							for qi in range(4):
								var qa = q[qi]
								var qb = q[(qi + 1) % 4]
								dyn.append(qa.x)
								dyn.append(qa.y)
								dyn.append(qb.x)
								dyn.append(qb.y)
					d += 17.0 + rng.randf() * 10.0
	edges_dyn[k] = dyn
	# prédios
	for b in builds_b.get(k, []):
		var pts: PackedVector2Array = b["pts"]
		var h: float = b["h"]
		var n = pts.size()
		var nf = maxi(1, roundi(h / 3.0))
		var wh = float(nf) * 3.0
		var hsh = int(absf(b["cx"] * 13.1 + b["cz"] * 5.7))
		var is_house = n <= 8 and h < 9.0
		var wcol = WALLS[hsh % WALLS.size()] if is_house else TOWERS[hsh % TOWERS.size()]
		var stw = st_house if is_house else st_tower
		var acc = 0.0
		for i in range(n):
			var j = (i + 1) % n
			var a = pts[i]
			var bb = pts[j]
			var elen = a.distance_to(bb)
			if elen < 0.05:
				continue
			var mid = (a + bb) * 0.5
			var out = Vector3(mid.x - b["cx"], 0, mid.y - b["cz"])
			var u0 = acc / 3.0
			var u1 = (acc + elen) / 3.0
			acc += elen
			U.quad(stw, Vector3(a.x, 0, a.y), Vector3(a.x, wh, a.y), Vector3(bb.x, wh, bb.y), Vector3(bb.x, 0, bb.y),
				wcol, out, [Vector2(u0, nf), Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, nf)])
			if is_house:
				nhouse += 1
			else:
				ntower += 1
		var rcol = ROOFS[(hsh / 7) % ROOFS.size()]
		if is_house:
			var rh = _gable(st_flat, pts, wh, rcol, wcol)
			nflat += 8
			if hsh % 4 == 0:
				U.box(st_flat, Vector3(b["cx"], wh + rh * 0.7, b["cz"]), Vector3(0.5, rh + 1.0, 0.5), Color(0.55, 0.3, 0.25))
				nflat += 12
			_door(st_flat, pts, b["cx"], b["cz"])
		else:
			var idx = Geometry2D.triangulate_polygon(pts)
			for t in range(0, idx.size(), 3):
				U.tri(st_flat, Vector3(pts[idx[t]].x, wh + 0.05, pts[idx[t]].y), Vector3(pts[idx[t + 1]].x, wh + 0.05, pts[idx[t + 1]].y),
					Vector3(pts[idx[t + 2]].x, wh + 0.05, pts[idx[t + 2]].y), Color(0.6, 0.6, 0.58), Vector3.UP)
				nflat += 1
			if h >= 9.0:
				U.box(st_flat, Vector3(b["cx"], wh + 1.2, b["cz"]), Vector3(3.0, 2.4, 3.0), Color(0.72, 0.72, 0.7))
				nflat += 12
	if nroad > 0:
		root.add_child(U.mesh_inst(st_road, _mat_road))
	if nwalk > 0:
		root.add_child(U.mesh_inst(st_walk, _mat_walk))
	if nflat > 0:
		root.add_child(U.mesh_inst(st_flat, _mat_flat))
	if nhouse > 0:
		root.add_child(U.mesh_inst(st_house, Facade.wall_material(0)))
	if ntower > 0:
		root.add_child(U.mesh_inst(st_tower, Facade.wall_material(1)))
	_mm(root, Props.tree_mesh(), trees, tree_cols)
	_mm(root, Props.pole_mesh(), poles, [])
	_mm(root, Vehicles.sedan_mesh(), cars, car_cols)

## telhado de duas águas com beiral; retorna a altura da cumeeira
func _gable(st: SurfaceTool, pts: PackedVector2Array, wh: float, rcol: Color, wcol: Color) -> float:
	var n = pts.size()
	var best = 0.0
	var d = Vector2(1, 0)
	for i in range(n):
		var e = pts[(i + 1) % n] - pts[i]
		if e.length() > best:
			best = e.length()
			d = e.normalized()
	var p = Vector2(-d.y, d.x)
	var minu = 1e9
	var maxu = -1e9
	var minv = 1e9
	var maxv = -1e9
	for q in pts:
		minu = minf(minu, q.dot(d))
		maxu = maxf(maxu, q.dot(d))
		minv = minf(minv, q.dot(p))
		maxv = maxf(maxv, q.dot(p))
	minu -= 0.5
	maxu += 0.5
	minv -= 0.5
	maxv += 0.5
	var midv = (minv + maxv) * 0.5
	var rh = clampf((maxv - minv) * 0.28, 1.2, 2.6)
	var y0 = wh - 0.05
	var A = _p3(d, p, minu, minv, y0)
	var B = _p3(d, p, maxu, minv, y0)
	var C = _p3(d, p, maxu, maxv, y0)
	var D = _p3(d, p, minu, maxv, y0)
	var R0 = _p3(d, p, minu, midv, y0 + rh)
	var R1 = _p3(d, p, maxu, midv, y0 + rh)
	U.quad(st, A, B, R1, R0, rcol, Vector3(-p.x * 0.6, 1, -p.y * 0.6))
	U.quad(st, D, C, R1, R0, rcol.darkened(0.08), Vector3(p.x * 0.6, 1, p.y * 0.6))
	U.tri(st, A, D, R0, wcol, Vector3(-d.x, 0, -d.y))
	U.tri(st, B, C, R1, wcol, Vector3(d.x, 0, d.y))
	return rh

func _p3(d: Vector2, p: Vector2, u: float, v: float, y: float) -> Vector3:
	var q = d * u + p * v
	return Vector3(q.x, y, q.y)

## porta de entrada na parede voltada para a rua mais próxima
func _door(st: SurfaceTool, pts: PackedVector2Array, cx: float, cz: float) -> void:
	var rd = nearest_road(cx, cz, 1)
	if rd.size() == 0:
		return
	var rp = Vector2(rd["pos"].x, rd["pos"].z)
	var n = pts.size()
	var best = -2.0
	var bi = -1
	var bn = Vector2.ZERO
	for i in range(n):
		var a = pts[i]
		var b = pts[(i + 1) % n]
		var e = b - a
		var l = e.length()
		if l < 3.5:
			continue
		var nrm = Vector2(e.y, -e.x) / l
		var mid = (a + b) * 0.5
		if nrm.dot(mid - Vector2(cx, cz)) < 0.0:
			nrm = -nrm
		var sc = nrm.dot((rp - mid).normalized())
		if sc > best:
			best = sc
			bi = i
			bn = nrm
	if bi < 0:
		return
	var a2 = pts[bi]
	var b2 = pts[(bi + 1) % n]
	var u = (b2 - a2).normalized()
	var m = (a2 + b2) * 0.5
	var hint = Vector3(bn.x, 0, bn.y)
	var f0 = m + bn * 0.03
	U.quad(st, Vector3(f0.x - u.x * 0.65, 0, f0.y - u.y * 0.65), Vector3(f0.x - u.x * 0.65, 2.3, f0.y - u.y * 0.65),
		Vector3(f0.x + u.x * 0.65, 2.3, f0.y + u.y * 0.65), Vector3(f0.x + u.x * 0.65, 0, f0.y + u.y * 0.65), Color(0.95, 0.95, 0.92), hint)
	var d0 = m + bn * 0.05
	U.quad(st, Vector3(d0.x - u.x * 0.5, 0, d0.y - u.y * 0.5), Vector3(d0.x - u.x * 0.5, 2.1, d0.y - u.y * 0.5),
		Vector3(d0.x + u.x * 0.5, 2.1, d0.y + u.y * 0.5), Vector3(d0.x + u.x * 0.5, 0, d0.y + u.y * 0.5), Color(0.42, 0.24, 0.14), hint)
	var s0 = m + bn * 0.6
	U.quad(st, Vector3(s0.x - u.x * 0.8 - bn.x * 0.55, 0.08, s0.y - u.y * 0.8 - bn.y * 0.55), Vector3(s0.x + u.x * 0.8 - bn.x * 0.55, 0.08, s0.y + u.y * 0.8 - bn.y * 0.55),
		Vector3(s0.x + u.x * 0.8 + bn.x * 0.55, 0.08, s0.y + u.y * 0.8 + bn.y * 0.55), Vector3(s0.x - u.x * 0.8 + bn.x * 0.55, 0.08, s0.y - u.y * 0.8 + bn.y * 0.55), Color(0.62, 0.62, 0.6), Vector3.UP)

func _strip(st: SurfaceTool, x0: float, z0: float, x1: float, z1: float, w: float, y: float, col: Color, ext_f: float = 0.0) -> int:
	var dx = x1 - x0
	var dz = z1 - z0
	var l = sqrt(dx * dx + dz * dz)
	if l < 0.3:
		return 0
	var ux = dx / l
	var uz = dz / l
	var px = -uz
	var pz = ux
	var ext = minf(w * ext_f, 3.0)
	var ax = x0 - ux * ext
	var az = z0 - uz * ext
	var bx = x1 + ux * ext
	var bz = z1 + uz * ext
	var hw = w * 0.5
	U.quad(st, Vector3(ax + px * hw, y, az + pz * hw), Vector3(bx + px * hw, y, bz + pz * hw),
		Vector3(bx - px * hw, y, bz - pz * hw), Vector3(ax - px * hw, y, az - pz * hw), col, Vector3.UP)
	return 2

func _flat_poly(st: SurfaceTool, flat: Array, y: float, col: Color) -> int:
	var pts = PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		pts.append(Vector2(flat[i], flat[i + 1]))
	if pts.size() < 3:
		return 0
	var idx = Geometry2D.triangulate_polygon(pts)
	var c = 0
	for t in range(0, idx.size(), 3):
		U.tri(st, Vector3(pts[idx[t]].x, y, pts[idx[t]].y), Vector3(pts[idx[t + 1]].x, y, pts[idx[t + 1]].y),
			Vector3(pts[idx[t + 2]].x, y, pts[idx[t + 2]].y), col, Vector3.UP)
		c += 1
	return c

# ---------------------------------------------------------------- consultas

func push_out(p: Vector3, r: float) -> Vector3:
	var ck = _key(p.x, p.z)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for src in [edges, edges_dyn]:
				var e = src.get(Vector2i(ck.x + dx, ck.y + dz))
				if e == null:
					continue
				for i in range(0, e.size(), 4):
					var ax = e[i]
					var az = e[i + 1]
					var abx = e[i + 2] - ax
					var abz = e[i + 3] - az
					var t = ((p.x - ax) * abx + (p.z - az) * abz) / (abx * abx + abz * abz + 0.0001)
					t = clampf(t, 0.0, 1.0)
					var qx = p.x - (ax + abx * t)
					var qz = p.z - (az + abz * t)
					var d2 = qx * qx + qz * qz
					if d2 < r * r and d2 > 0.00001:
						var d = sqrt(d2)
						var k = (r - d) / d
						p.x += qx * k
						p.z += qz * k
	return p

func nearest_road(x: float, z: float, rng_c: int = 2) -> Dictionary:
	var ck = _key(x, z)
	var best = 1e12
	var res = {}
	for dx in range(-rng_c, rng_c + 1):
		for dz in range(-rng_c, rng_c + 1):
			for s in roads_b.get(Vector2i(ck.x + dx, ck.y + dz), []):
				var abx = s[2] - s[0]
				var abz = s[3] - s[1]
				var t = ((x - s[0]) * abx + (z - s[1]) * abz) / (abx * abx + abz * abz + 0.0001)
				t = clampf(t, 0.0, 1.0)
				var qx = s[0] + abx * t
				var qz = s[1] + abz * t
				var d = (x - qx) * (x - qx) + (z - qz) * (z - qz)
				if d < best:
					best = d
					res = {"pos": Vector3(qx, 0, qz), "dir": Vector2(abx, abz).normalized(), "w": s[4], "name": s[5]}
	return res

func road_segments_near(c: Vector2, rad: float) -> Array:
	var out: Array = []
	var k0 = _key(c.x - rad, c.y - rad)
	var k1 = _key(c.x + rad, c.y + rad)
	for kx in range(k0.x, k1.x + 1):
		for kz in range(k0.y, k1.y + 1):
			var l = roads_b.get(Vector2i(kx, kz))
			if l != null:
				out.append_array(l)
	return out

func find_route(from: Vector3, to: Vector3) -> PackedVector2Array:
	var a = astar.get_closest_point(Vector2(from.x, from.z))
	var b = astar.get_closest_point(Vector2(to.x, to.z))
	if a >= 0 and b >= 0:
		var path = astar.get_point_path(a, b)
		if path.size() >= 2:
			return path
	return PackedVector2Array([Vector2(from.x, from.z), Vector2(to.x, to.z)])

func has_route(from: Vector3, to: Vector3) -> bool:
	var a = astar.get_closest_point(Vector2(from.x, from.z))
	var b = astar.get_closest_point(Vector2(to.x, to.z))
	if a < 0 or b < 0:
		return false
	return astar.get_point_path(a, b).size() >= 2

static func path_length(path: PackedVector2Array) -> float:
	var l = 0.0
	for i in range(path.size() - 1):
		l += path[i].distance_to(path[i + 1])
	return l

func random_destination(from: Vector3, dmin: float, dmax: float) -> Dictionary:
	for attempt in range(40):
		if dest_points.size() == 0:
			break
		var c: Vector2 = dest_points[randi() % dest_points.size()]
		var d = Vector2(from.x, from.z).distance_to(c)
		if d < dmin or d > dmax:
			continue
		var r = nearest_road(c.x, c.y)
		if r.size() == 0 or r["w"] < 6:
			continue
		if has_route(from, r["pos"]):
			r["building"] = c
			return r
	var r2 = nearest_road(from.x + 200.0, from.z)
	r2["building"] = Vector2(from.x + 200.0, from.z)
	return r2

func place_name_at(x: float, z: float) -> String:
	var best = 1e12
	var nm = "Passo Fundo"
	for p in places:
		if p.has("poi") or p["n"] == "Passo Fundo":
			continue
		var d = (p["p"][0] - x) * (p["p"][0] - x) + (p["p"][1] - z) * (p["p"][1] - z)
		if d < best:
			best = d
			nm = p["n"]
	return nm
