class_name Traffic
extends Node3D
## Tráfego simples: carros que seguem rotas reais pelo grafo de ruas, perto do jogador.

const MAX_CARS = 9
var city: City
var cars: Array = []
var mats: Array = []
var timer: float = 0.0

func setup(c: City) -> void:
	city = c
	for col in Vehicles.paint_colors():
		var m = U.vcol_mat(0.5)
		m.albedo_color = col
		mats.append(m)

func update(delta: float, ppos: Vector3) -> void:
	timer -= delta
	if cars.size() < MAX_CARS and timer <= 0.0:
		timer = 1.2
		_spawn(ppos)
	var pv = Vector2(ppos.x, ppos.z)
	for c in cars.duplicate():
		var dir = c["path"][c["idx"]] - c["pos"]
		if dir.length() < 2.5:
			c["idx"] += 1
			if c["idx"] >= c["path"].size():
				_free(c)
				continue
			dir = c["path"][c["idx"]] - c["pos"]
		var f = dir.normalized()
		c["pos"] += f * c["speed"] * delta
		c["yaw"] = lerp_angle(c["yaw"], atan2(-f.x, -f.y), minf(1.0, 5.0 * delta))
		var right = Vector2(-f.y, f.x) * 1.9
		var n: Node3D = c["node"]
		n.position = Vector3(c["pos"].x + right.x, 0, c["pos"].y + right.y)
		n.rotation.y = c["yaw"]
		if c["pos"].distance_to(pv) > 450.0:
			_free(c)

func _free(c: Dictionary) -> void:
	c["node"].queue_free()
	cars.erase(c)

func _spawn(ppos: Vector3) -> void:
	var pv = Vector2(ppos.x, ppos.z)
	var segs = city.road_segments_near(pv, 300.0)
	if segs.size() < 3:
		return
	for i in range(12):
		var s = segs[randi() % segs.size()]
		if s[4] < 6:
			continue
		var mid = Vector2((s[0] + s[2]) * 0.5, (s[1] + s[3]) * 0.5)
		var d = mid.distance_to(pv)
		if d < 100.0 or d > 300.0:
			continue
		var t = segs[randi() % segs.size()]
		var path = city.find_route(Vector3(mid.x, 0, mid.y), Vector3(t[0], 0, t[1]))
		if path.size() < 4:
			continue
		var node = MeshInstance3D.new()
		node.mesh = Vehicles.sedan_mesh()
		node.material_override = mats[randi() % mats.size()]
		add_child(node)
		cars.append({"node": node, "path": path, "idx": 1, "pos": path[0], "yaw": 0.0, "speed": randf_range(7.0, 12.0)})
		return

## empurra o ponto p para fora dos carros do tráfego; retorna true se bateu
func push(p: Vector3, r: float) -> Array:
	var hit = false
	for c in cars:
		var cp: Vector3 = c["node"].position
		var d = Vector2(p.x - cp.x, p.z - cp.z)
		var l = d.length()
		if l < r + 1.5 and l > 0.01:
			var k = (r + 1.5 - l) / l
			p.x += d.x * k
			p.z += d.y * k
			hit = true
	return [p, hit]
