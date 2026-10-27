class_name Facade
extends RefCounted
## Texturas de fachada (janelas) e a loja Color Tintas (baseada nas fotos da fachada real).

static var _wall_mats: Dictionary = {}

## kind 0 = casas (janela com venezianas), 1 = prédios (faixa de vidro)
static func wall_material(kind: int = 0) -> StandardMaterial3D:
	if not _wall_mats.has(kind):
		# Uma textura por andar, com reboco/concreto, caixilhos, vidros e pequenas variações.
		# O padrão repete-se em escala real pelas UVs já geradas em city.gd.
		var size = 256
		var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var rng = RandomNumberGenerator.new()
		rng.seed = 704 + kind * 91
		var wall = Color(0.76, 0.75, 0.71) if kind == 0 else Color(0.68, 0.69, 0.7)
		for y in range(size):
			for x in range(size):
				var n = rng.randf_range(-0.025, 0.025)
				img.set_pixel(x, y, Color(clampf(wall.r + n, 0, 1), clampf(wall.g + n, 0, 1), clampf(wall.b + n, 0, 1), 1))
		if kind == 0:
			# Casa: duas janelas com esquadrias claras, reflexo azul e peitoril.
			for x0 in [30, 150]:
				img.fill_rect(Rect2i(x0 - 4, 34, 84, 116), Color(0.91, 0.9, 0.85))
				img.fill_rect(Rect2i(x0, 38, 76, 106), Color(0.13, 0.2, 0.26))
				img.fill_rect(Rect2i(x0 + 4, 42, 31, 46), Color(0.42, 0.59, 0.69))
				img.fill_rect(Rect2i(x0 + 39, 42, 33, 46), Color(0.27, 0.42, 0.53))
				img.fill_rect(Rect2i(x0 + 4, 92, 31, 48), Color(0.21, 0.31, 0.37))
				img.fill_rect(Rect2i(x0 + 39, 92, 33, 48), Color(0.34, 0.48, 0.56))
				img.fill_rect(Rect2i(x0 + 36, 38, 4, 106), Color(0.91, 0.9, 0.85))
				img.fill_rect(Rect2i(x0 - 6, 146, 88, 7), Color(0.84, 0.83, 0.79))
				img.fill_rect(Rect2i(x0 + 7, 44, 3, 94), Color(0.75, 0.76, 0.75))
			img.fill_rect(Rect2i(0, 12, 256, 5), Color(0.92, 0.91, 0.87))
			img.fill_rect(Rect2i(0, 226, 256, 8), Color(0.62, 0.61, 0.58))
		else:
			# Prédio: três vãos por fachada, vidro com reflexos diagonais e faixas de laje.
			img.fill_rect(Rect2i(0, 0, 256, 15), Color(0.84, 0.84, 0.82))
			img.fill_rect(Rect2i(0, 241, 256, 15), Color(0.82, 0.82, 0.8))
			for x0 in [12, 96, 180]:
				img.fill_rect(Rect2i(x0 - 3, 20, 66, 204), Color(0.82, 0.82, 0.8))
				img.fill_rect(Rect2i(x0, 23, 60, 196), Color(0.11, 0.18, 0.23))
				img.fill_rect(Rect2i(x0 + 4, 27, 24, 188), Color(0.32, 0.47, 0.56))
				img.fill_rect(Rect2i(x0 + 31, 27, 25, 188), Color(0.17, 0.29, 0.36))
				img.fill_rect(Rect2i(x0 + 7, 31, 4, 180), Color(0.55, 0.66, 0.7))
				img.fill_rect(Rect2i(x0, 120, 60, 4), Color(0.72, 0.73, 0.72))
				img.fill_rect(Rect2i(x0 - 2, 124, 64, 3), Color(0.88, 0.87, 0.84))
				img.fill_rect(Rect2i(x0 - 3, 219, 66, 5), Color(0.9, 0.89, 0.86))
		img.generate_mipmaps()
		var m = StandardMaterial3D.new()
		m.albedo_texture = ImageTexture.create_from_image(img)
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.72 if kind == 0 else 0.32
		m.metallic = 0.0 if kind == 0 else 0.12
		m.normal_enabled = true
		m.normal_texture = U.detail_normal_texture(43 + kind)
		m.normal_scale = 0.12
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_wall_mats[kind] = m
	return _wall_mats[kind]

static func _glass_mat(a: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.75, 0.9, a)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.metallic = 0.3
	return m

## Loja: face frontal em z=0 voltada para +Z; ocupa x[-12,12], z[-14,0]
static func build_store() -> Node3D:
	var root = Node3D.new()
	var st = U.new_st()
	var white = Color(0.95, 0.95, 0.97)
	var red = Color(0.85, 0.1, 0.12)
	var blue = Color(0.1, 0.2, 0.62)
	var wood = Color(0.45, 0.28, 0.17)
	U.box(st, Vector3(0, 3.25, -7), Vector3(24, 6.5, 14), white)
	U.box(st, Vector3(0, 6.62, -7), Vector3(24.4, 0.25, 14.4), Color(0.78, 0.78, 0.8))
	U.box(st, Vector3(0, 4.2, 0.2), Vector3(24.4, 1.0, 0.5), red)
	U.box(st, Vector3(0, 3.72, 0.1), Vector3(24, 0.2, 0.3), blue)
	for x in [-11.9, -8.0, -4.0, 4.0, 8.0, 11.9]:
		U.box(st, Vector3(x, 1.85, 0.1), Vector3(0.3, 3.7, 0.3), blue)
	# interior visível atrás do vidro: prateleiras de tintas
	U.box(st, Vector3(0, 0.05, -3), Vector3(23, 0.1, 6), Color(0.78, 0.74, 0.7))
	Props.shelf(st, Vector3(-8, 0, -1.3), 7.0, 2.6, 0.9, 11)
	Props.shelf(st, Vector3(8, 0, -1.3), 7.0, 2.6, 0.9, 12)
	Props.shelf(st, Vector3(-8, 0, -3.8), 7.0, 2.6, 0.9, 13)
	Props.shelf(st, Vector3(8, 0, -3.8), 7.0, 2.6, 0.9, 14)
	U.box(st, Vector3(0, 0.8, -3.5), Vector3(4.0, 1.6, 1.2), Color(0.9, 0.9, 0.92))
	# letreiro Sparlack/Cetol sobre a porta
	U.box(st, Vector3(0, 3.1, 0.18), Vector3(3.0, 1.1, 0.1), blue)
	U.box(st, Vector3(0, 2.7, 0.24), Vector3(3.0, 0.45, 0.06), Color(0.93, 0.5, 0.15))
	# deck e escada de madeira
	U.box(st, Vector3(0, 0.3, 2.0), Vector3(5.0, 0.6, 3.8), wood)
	U.box(st, Vector3(0, 0.2, 4.15), Vector3(5.0, 0.4, 0.5), wood.darkened(0.1))
	U.box(st, Vector3(0, 0.1, 4.6), Vector3(5.0, 0.2, 0.5), wood.darkened(0.2))
	# pergola
	for sx in [-1, 1]:
		U.box(st, Vector3(2.3 * sx, 2.3, 3.5), Vector3(0.35, 3.4, 0.35), wood.darkened(0.2))
		U.box(st, Vector3(2.45 * sx, 1.15, 2.0), Vector3(0.06, 1.0, 3.6), Color(0.85, 0.55, 0.25))
		U.box(st, Vector3(2.45 * sx, 1.65, 2.0), Vector3(0.1, 0.06, 3.6), Color(0.85, 0.55, 0.25))
	for i in range(5):
		U.box(st, Vector3(0, 4.05, 0.6 + i * 0.7), Vector3(5.2, 0.16, 0.2), wood.darkened(0.25))
	U.box(st, Vector3(0, 3.95, 2.0), Vector3(0.2, 0.2, 3.6), wood.darkened(0.25))
	# gramado, pedras e agaves
	for sx in [-1, 1]:
		U.box(st, Vector3(7.5 * sx, 0.07, 2.2), Vector3(9.0, 0.14, 4.0), Color(0.3, 0.56, 0.25))
		for k in range(4):
			U.cyl(st, Vector3((3.6 + k * 0.7) * sx, 0.5, 1.2 + (k % 2) * 0.9), 0.5, 0.9, Color(0.18, 0.5, 0.3), 7, 0.04)
	root.add_child(U.mesh_inst(st, U.vcol_mat(0.8)))
	# vidros translúcidos (fachada e teto da pergola)
	var gst = U.new_st()
	U.quad(gst, Vector3(-11.7, 0.1, 0.12), Vector3(-11.7, 3.65, 0.12), Vector3(11.7, 3.65, 0.12), Vector3(11.7, 0.1, 0.12), Color.WHITE, Vector3(0, 0, 1))
	U.quad(gst, Vector3(-2.5, 4.15, 0.6), Vector3(-2.5, 4.15, 3.6), Vector3(2.5, 4.15, 3.6), Vector3(2.5, 4.15, 0.6), Color.WHITE, Vector3(0, 1, 0))
	var g = U.mesh_inst(gst, _glass_mat(0.28))
	root.add_child(g)
	# letreiro com logotipo
	var q = QuadMesh.new()
	q.size = Vector2(10.5, 3.08)
	var lm = StandardMaterial3D.new()
	lm.albedo_texture = Chars.logo()
	lm.roughness = 0.7
	var logo = MeshInstance3D.new()
	logo.mesh = q
	logo.material_override = lm
	logo.position = Vector3(-3.5, 5.6, 0.2)
	root.add_child(logo)
	var logo2 = MeshInstance3D.new()
	var q2 = QuadMesh.new()
	q2.size = Vector2(4.0, 1.17)
	logo2.mesh = q2
	logo2.material_override = lm
	logo2.position = Vector3(8.5, 5.6, 0.2)
	root.add_child(logo2)
	# luz interna quente
	var l = OmniLight3D.new()
	l.position = Vector3(0, 3.0, -2.5)
	l.omni_range = 14.0
	l.light_energy = 1.2
	l.light_color = Color(1.0, 0.92, 0.8)
	root.add_child(l)
	return root
