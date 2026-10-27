class_name TruckModel
extends RefCounted
## Caminhonete branca de entregas da Color Tintas (frente = -Z). Comprimento ~5,2 m.

## with_cargo=false: caçamba vazia, com tampa traseira articulada (meta 'tailgate') e posições de carga (meta 'slots').
static func build(with_cargo: bool = true) -> Node3D:
	var root = Node3D.new()
	var st = U.new_st()
	var white = Color(0.95, 0.95, 0.97)
	var dark = Color(0.1, 0.1, 0.12)
	var glass = Color(0.1, 0.17, 0.25)
	# chassi / lataria baixa
	U.box(st, Vector3(0, 0.78, 0), Vector3(1.96, 0.62, 5.2), white)
	# capô
	U.box(st, Vector3(0, 1.12, -1.75), Vector3(1.9, 0.12, 1.65), white.darkened(0.03))
	# cabine
	U.box(st, Vector3(0, 1.55, 0.02), Vector3(1.9, 0.78, 1.15), white)
	# parabrisa inclinado e laterais triangulares
	var wl = Vector3(-0.85, 1.18, -0.95)
	var wr = Vector3(0.85, 1.18, -0.95)
	var tl = Vector3(-0.85, 1.94, -0.55)
	var tr = Vector3(0.85, 1.94, -0.55)
	U.quad(st, wl, tl, tr, wr, glass, Vector3(0, 0.6, -1))
	U.tri(st, Vector3(0.95, 1.18, -0.95), Vector3(0.95, 1.94, -0.55), Vector3(0.95, 1.18, -0.55), white, Vector3(1, 0, 0))
	U.tri(st, Vector3(-0.95, 1.18, -0.95), Vector3(-0.95, 1.94, -0.55), Vector3(-0.95, 1.18, -0.55), white, Vector3(-1, 0, 0))
	# janelas laterais e traseira
	for sx in [-1, 1]:
		U.quad(st, Vector3(0.96 * sx, 1.5, -0.4), Vector3(0.96 * sx, 1.9, -0.4), Vector3(0.96 * sx, 1.9, 0.5), Vector3(0.96 * sx, 1.5, 0.5), glass, Vector3(sx, 0, 0))
	U.quad(st, Vector3(-0.8, 1.55, 0.6), Vector3(-0.8, 1.88, 0.6), Vector3(0.8, 1.88, 0.6), Vector3(0.8, 1.55, 0.6), glass, Vector3(0, 0, 1))
	# caçamba: laterais e traseira
	for sx in [-1, 1]:
		U.box(st, Vector3(0.93 * sx, 1.2, 1.6), Vector3(0.1, 0.5, 2.0), white)
	if with_cargo:
		U.box(st, Vector3(0, 1.2, 2.55), Vector3(1.96, 0.5, 0.1), white)
	U.box(st, Vector3(0, 0.98, 1.6), Vector3(1.8, 0.06, 2.0), Color(0.25, 0.25, 0.28))
	if with_cargo:
		# carga: latas e baldes
		var rng = RandomNumberGenerator.new()
		rng.seed = 7
		for i in range(3):
			for j in range(4):
				var c = Props.PALETTE[rng.randi() % Props.PALETTE.size()]
				if (i + j) % 3 == 0:
					Props.bucket(st, Vector3(-0.55 + j * 0.37, 1.01, 0.9 + i * 0.5), c, 1.0)
				else:
					Props.can(st, Vector3(-0.55 + j * 0.37, 1.01, 0.9 + i * 0.5), c, 1.3)
	# faixas (azul e vermelha) na lateral baixa, como identidade da loja
	for sx in [-1, 1]:
		U.quad(st, Vector3(0.985 * sx, 0.62, -2.5), Vector3(0.985 * sx, 0.7, -2.5), Vector3(0.985 * sx, 0.7, 2.5), Vector3(0.985 * sx, 0.62, 2.5), Color(0.85, 0.12, 0.12), Vector3(sx, 0, 0))
		U.quad(st, Vector3(0.985 * sx, 0.5, -2.5), Vector3(0.985 * sx, 0.6, -2.5), Vector3(0.985 * sx, 0.6, 2.5), Vector3(0.985 * sx, 0.5, 2.5), Color(0.12, 0.2, 0.6), Vector3(sx, 0, 0))
	# para-choques, grade, faróis, lanternas
	U.box(st, Vector3(0, 0.55, -2.65), Vector3(2.0, 0.28, 0.2), dark)
	U.box(st, Vector3(0, 0.55, 2.65), Vector3(2.0, 0.28, 0.2), dark)
	U.box(st, Vector3(0, 0.95, -2.62), Vector3(1.0, 0.3, 0.06), Color(0.05, 0.05, 0.07))
	for sx in [-1, 1]:
		U.box(st, Vector3(0.7 * sx, 0.98, -2.62), Vector3(0.38, 0.2, 0.08), Color(1.0, 0.97, 0.8))
		U.box(st, Vector3(0.88 * sx, 1.1, 2.61), Vector3(0.18, 0.28, 0.06), Color(0.9, 0.1, 0.1))
		# espelhos, maçanetas e frisos da cabine
		U.box(st, Vector3(1.02 * sx, 1.52, -0.62), Vector3(0.18, 0.13, 0.22), dark)
		U.box(st, Vector3(1.105 * sx, 1.52, -0.62), Vector3(0.025, 0.075, 0.14), Color(0.25, 0.35, 0.42))
		U.box(st, Vector3(0.97 * sx, 1.48, 0.2), Vector3(0.035, 0.045, 0.2), Color(0.65, 0.67, 0.7))
		U.box(st, Vector3(0.97 * sx, 1.25, -1.65), Vector3(0.035, 0.025, 0.45), Color(0.75, 0.76, 0.78))
	# frisos horizontais na grade frontal e placa
	for yy in [0.91, 0.97, 1.03]:
		U.box(st, Vector3(0, yy, -2.66), Vector3(0.72, 0.018, 0.02), Color(0.42, 0.44, 0.47))
	U.box(st, Vector3(0, 0.66, -2.76), Vector3(0.42, 0.12, 0.025), Color(0.88, 0.89, 0.9))
	# trilhos de amarração na caçamba (aço)
	var steel = Color(0.62, 0.64, 0.7)
	for sx in [-1, 1]:
		U.box(st, Vector3(0.93 * sx, 1.5, 1.6), Vector3(0.05, 0.05, 2.0), steel)
		for zz in [0.7, 1.6, 2.45]:
			U.box(st, Vector3(0.93 * sx, 1.5, zz), Vector3(0.05, 0.1, 0.05), steel)
	root.add_child(U.mesh_inst(st, U.vcol_mat(0.55)))
	if not with_cargo:
		# tampa traseira articulada na base (abre para trás ao carregar)
		var hinge = Node3D.new()
		hinge.position = Vector3(0, 0.95, 2.55)
		root.add_child(hinge)
		var gst = U.new_st()
		U.box(gst, Vector3(0, 0.25, 0), Vector3(1.96, 0.5, 0.1), white)
		U.box(gst, Vector3(0.0, 0.25, 0.055), Vector3(1.5, 0.3, 0.02), white.darkened(0.08))
		hinge.add_child(U.mesh_inst(gst, U.vcol_mat(0.55)))
		root.set_meta("tailgate", hinge)
		var slots: Array = []
		for zz in [0.95, 1.55, 2.15]:
			for xx in [-0.42, 0.42]:
				slots.append(Vector3(xx, 1.01, zz))
		root.set_meta("slots", slots)
	# logo nas laterais da caçamba
	var lm = StandardMaterial3D.new()
	lm.albedo_texture = Chars.logo()
	lm.roughness = 0.8
	var q = QuadMesh.new()
	q.size = Vector2(1.7, 0.5)
	for sx in [-1, 1]:
		var mi = MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = lm
		mi.position = Vector3(0.986 * sx, 1.2, 1.6)
		mi.rotation.y = PI * 0.5 * sx
		root.add_child(mi)
	# rodas
	var tire = CylinderMesh.new()
	tire.top_radius = 0.4
	tire.bottom_radius = 0.4
	tire.height = 0.3
	tire.radial_segments = 14
	var hub = CylinderMesh.new()
	hub.top_radius = 0.2
	hub.bottom_radius = 0.2
	hub.height = 0.32
	hub.radial_segments = 8
	var steer: Array = []
	var spins: Array = []
	for sx in [-1, 1]:
		for zz in [-1.65, 1.6]:
			var sp = Node3D.new()
			sp.position = Vector3(0.95 * sx, 0.4, zz)
			root.add_child(sp)
			var spin = Node3D.new()
			sp.add_child(spin)
			var t = MeshInstance3D.new()
			t.mesh = tire
			t.material_override = U.mat(Color(0.08, 0.08, 0.09), 0.9)
			t.rotation.z = PI * 0.5
			spin.add_child(t)
			var h = MeshInstance3D.new()
			h.mesh = hub
			h.material_override = U.mat(Color(0.7, 0.7, 0.75), 0.4, 0.7)
			h.rotation.z = PI * 0.5
			spin.add_child(h)
			spins.append(spin)
			if zz < 0:
				steer.append(sp)
	root.set_meta("steer", steer)
	root.set_meta("spins", spins)
	return root
