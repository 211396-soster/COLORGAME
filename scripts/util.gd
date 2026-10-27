class_name U
extends RefCounted
## Utilidades: materiais, geometria (SurfaceTool com cor por vértice) e ambiente.

static func mat(color: Color, rough: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m

static func vcol_mat(rough: float = 0.85) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = rough
	return m

# Textura normal procedural reutilizável para dar micro-relevo a asfalto e concreto.
# É gerada uma vez por sessão, sem depender de arquivos externos ou downloads em tempo de jogo.
static var _detail_normal_cache: Dictionary = {}

static func detail_normal_texture(seed_value: int = 17) -> Texture2D:
	var cache_key = str(seed_value)
	if _detail_normal_cache.has(cache_key):
		return _detail_normal_cache[cache_key]
	var height = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.075
	for y in range(128):
		for x in range(128):
			var n = noise.get_noise_2d(float(x), float(y))
			var v = clampf(0.5 + n * 0.11, 0.0, 1.0)
			height.set_pixel(x, y, Color(v, v, v, 1.0))
	var normal_image = height.bump_map_to_normal_map(1.35)
	var texture = ImageTexture.create_from_image(normal_image)
	_detail_normal_cache[cache_key] = texture
	return texture

static func emissive_mat(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

static func new_st() -> SurfaceTool:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, hint: Vector3, ua: Vector2 = Vector2.ZERO, ub: Vector2 = Vector2.ZERO, uc: Vector2 = Vector2.ZERO) -> void:
	var n = (c - a).cross(b - a)
	if n.length_squared() < 0.0000001:
		return
	n = n.normalized()
	if n.dot(hint) < 0.0:
		var t = b
		b = c
		c = t
		var tu = ub
		ub = uc
		uc = tu
		n = -n
	st.set_color(col)
	st.set_normal(n)
	st.set_uv(ua)
	st.add_vertex(a)
	st.set_uv(ub)
	st.add_vertex(b)
	st.set_uv(uc)
	st.add_vertex(c)

## quad a,b,c,d em sequência de contorno; uvs opcional (4 Vector2)
static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, hint: Vector3, uvs: Array = []) -> void:
	var u0 = Vector2.ZERO
	var u1 = Vector2.ZERO
	var u2 = Vector2.ZERO
	var u3 = Vector2.ZERO
	if uvs.size() == 4:
		u0 = uvs[0]
		u1 = uvs[1]
		u2 = uvs[2]
		u3 = uvs[3]
	tri(st, a, b, c, col, hint, u0, u1, u2)
	tri(st, a, c, d, col, hint, u0, u2, u3)

static func box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color) -> void:
	var h = s * 0.5
	var p = [
		c + Vector3(-h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, -h.z),
		c + Vector3(h.x, h.y, -h.z), c + Vector3(-h.x, h.y, -h.z),
		c + Vector3(-h.x, -h.y, h.z), c + Vector3(h.x, -h.y, h.z),
		c + Vector3(h.x, h.y, h.z), c + Vector3(-h.x, h.y, h.z)]
	quad(st, p[0], p[1], p[2], p[3], col, Vector3(0, 0, -1))
	quad(st, p[5], p[4], p[7], p[6], col, Vector3(0, 0, 1))
	quad(st, p[4], p[0], p[3], p[7], col, Vector3(-1, 0, 0))
	quad(st, p[1], p[5], p[6], p[2], col, Vector3(1, 0, 0))
	quad(st, p[3], p[2], p[6], p[7], col.lightened(0.1), Vector3(0, 1, 0))
	quad(st, p[4], p[5], p[1], p[0], col.darkened(0.3), Vector3(0, -1, 0))

## cilindro/cone de eixo vertical. c = centro, h = altura total
static func cyl(st: SurfaceTool, c: Vector3, r: float, h: float, col: Color, segs: int = 10, r_top: float = -1.0, cap_bottom: bool = false) -> void:
	if r_top < 0.0:
		r_top = r
	var y0 = c.y - h * 0.5
	var y1 = c.y + h * 0.5
	var top_c = Vector3(c.x, y1, c.z)
	var bot_c = Vector3(c.x, y0, c.z)
	for i in range(segs):
		var a0 = TAU * float(i) / float(segs)
		var a1 = TAU * float(i + 1) / float(segs)
		var d0 = Vector3(cos(a0), 0, sin(a0))
		var d1 = Vector3(cos(a1), 0, sin(a1))
		var b0 = Vector3(c.x, y0, c.z) + d0 * r
		var b1 = Vector3(c.x, y0, c.z) + d1 * r
		var t0 = Vector3(c.x, y1, c.z) + d0 * r_top
		var t1 = Vector3(c.x, y1, c.z) + d1 * r_top
		quad(st, b0, t0, t1, b1, col, d0 + d1)
		if r_top > 0.001:
			tri(st, top_c, t1, t0, col.lightened(0.1), Vector3.UP)
		if cap_bottom:
			tri(st, bot_c, b0, b1, col.darkened(0.3), Vector3.DOWN)

static func sphere(st: SurfaceTool, c: Vector3, r: float, cb: Color, ct: Color, segs: int = 8, rings: int = 5) -> void:
	for j in range(rings):
		var a0 = PI * float(j) / float(rings)
		var a1 = PI * float(j + 1) / float(rings)
		for i in range(segs):
			var t0 = TAU * float(i) / float(segs)
			var t1 = TAU * float(i + 1) / float(segs)
			var p00 = c + Vector3(sin(a0) * cos(t0), cos(a0), sin(a0) * sin(t0)) * r
			var p01 = c + Vector3(sin(a0) * cos(t1), cos(a0), sin(a0) * sin(t1)) * r
			var p10 = c + Vector3(sin(a1) * cos(t0), cos(a1), sin(a1) * sin(t0)) * r
			var p11 = c + Vector3(sin(a1) * cos(t1), cos(a1), sin(a1) * sin(t1)) * r
			var col = cb.lerp(ct, (cos((a0 + a1) * 0.5) + 1.0) * 0.5)
			quad(st, p00, p01, p11, p10, col, (p00 + p11) * 0.5 - c)

static func mesh_inst(st: SurfaceTool, material: Material) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = material
	return m

static func make_env(kind: String, shadows: bool) -> Node3D:
	var root = Node3D.new()
	var we = WorldEnvironment.new()
	var env = Environment.new()
	var sun = DirectionalLight3D.new()
	if kind == "day":
		var sky = Sky.new()
		var hdr = "res://assets/sky/sky_day.hdr"
		if ResourceLoader.exists(hdr):
			var pm = PanoramaSkyMaterial.new()
			pm.panorama = load(hdr)
			sky.sky_material = pm
			sky.radiance_size = Sky.RADIANCE_SIZE_128
			sun.basis = Basis.looking_at(-Vector3(0.374, 0.745, -0.552), Vector3.UP)
		else:
			var psm = ProceduralSkyMaterial.new()
			psm.sky_top_color = Color(0.25, 0.5, 0.9)
			psm.sky_horizon_color = Color(0.72, 0.82, 0.93)
			psm.ground_horizon_color = Color(0.72, 0.8, 0.85)
			psm.ground_bottom_color = Color(0.4, 0.45, 0.4)
			sky.sky_material = psm
			sun.rotation_degrees = Vector3(-42, -35, 0)
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_energy = 1.0
		env.fog_enabled = true
		env.fog_light_color = Color(0.72, 0.82, 0.93)
		env.fog_density = 0.0011
		env.fog_sun_scatter = 0.08
		env.ambient_light_sky_contribution = 0.8
		sun.light_energy = 1.25
		sun.light_color = Color(1.0, 0.94, 0.82)
	elif kind == "shop":
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.04, 0.07, 0.14)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.85, 0.85, 0.95)
		env.ambient_light_energy = 0.75
		sun.light_energy = 0.9
		sun.light_color = Color(1.0, 0.92, 0.8)
		sun.rotation_degrees = Vector3(-60, 35, 0)
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.02, 0.03, 0.05)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.35, 0.4, 0.55)
		env.ambient_light_energy = 0.55
		env.fog_enabled = true
		env.fog_light_color = Color(0.05, 0.07, 0.1)
		env.fog_density = 0.03
		sun.light_energy = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.05
	env.adjustment_contrast = 1.07
	# Bloom muito discreto: realça superfícies iluminadas sem criar aparência de filtro.
	env.glow_enabled = true
	env.glow_intensity = 0.28
	env.glow_strength = 0.65
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.25
	we.environment = env
	root.add_child(we)
	sun.shadow_enabled = shadows and kind != "dark"
	sun.directional_shadow_max_distance = 90.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	root.add_child(sun)
	return root

static func fmt_money(v: int) -> String:
	return "R$ " + str(v)
