class_name Vehicles
extends RefCounted
## Carros de rua (sedan) em malha única. A cor da lataria vem de material/cor de instância.

static var _sedan: ArrayMesh = null

static func sedan_mesh() -> ArrayMesh:
	if _sedan == null:
		var st = U.new_st()
		var body = Color(1, 1, 1)
		var glass = Color(0.08, 0.12, 0.18)
		var dark = Color(0.06, 0.06, 0.07)
		U.box(st, Vector3(0, 0.62, 0), Vector3(1.8, 0.58, 4.3), body)
		U.box(st, Vector3(0, 1.15, 0.25), Vector3(1.55, 0.55, 2.2), body)
		for sx in [-1, 1]:
			U.quad(st, Vector3(0.78 * sx, 1.0, -0.7), Vector3(0.78 * sx, 1.38, -0.7), Vector3(0.78 * sx, 1.38, 1.15), Vector3(0.78 * sx, 1.0, 1.15), glass, Vector3(sx, 0, 0))
			for sz in [-1.4, 1.4]:
				U.box(st, Vector3(0.9 * sx, 0.31, sz), Vector3(0.22, 0.62, 0.62), dark)
		U.quad(st, Vector3(-0.7, 1.0, -0.86), Vector3(-0.7, 1.38, -0.86), Vector3(0.7, 1.38, -0.86), Vector3(0.7, 1.0, -0.86), glass, Vector3(0, 0, -1))
		U.quad(st, Vector3(-0.7, 1.0, 1.36), Vector3(-0.7, 1.38, 1.36), Vector3(0.7, 1.38, 1.36), Vector3(0.7, 1.0, 1.36), glass, Vector3(0, 0, 1))
		U.box(st, Vector3(0, 0.38, -2.18), Vector3(1.85, 0.24, 0.16), dark)
		U.box(st, Vector3(0, 0.38, 2.18), Vector3(1.85, 0.24, 0.16), dark)
		for sx in [-1, 1]:
			U.box(st, Vector3(0.62 * sx, 0.72, -2.16), Vector3(0.4, 0.14, 0.05), Color(1, 1, 0.85))
			U.box(st, Vector3(0.65 * sx, 0.74, 2.16), Vector3(0.36, 0.14, 0.05), Color(0.7, 0.05, 0.05))
		_sedan = st.commit()
	return _sedan

static func paint_colors() -> Array:
	return [Color(0.95, 0.95, 0.95), Color(0.72, 0.74, 0.78), Color(0.12, 0.12, 0.14), Color(0.78, 0.14, 0.12),
		Color(0.16, 0.32, 0.72), Color(0.85, 0.7, 0.15), Color(0.2, 0.5, 0.35), Color(0.45, 0.45, 0.5)]
