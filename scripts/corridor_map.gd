extends RefCounted
## Shared 5x5 corridor graph. Height changes have real gaps and landing platforms.
const STONE = preload("res://assets/stone.gdshader")
const NAMES := ["VERDANT RUINS", "BLUE CATACOMBS", "EMBER VAULT", "ROOTBOUND FOREST", "DUNE COAST"]
const STEP := 12.0
const THEMES := [
	[Color("374d3d"), Color("45544a"), Color("182d20"), Color("9eac75"), Color("0c1715")],
	[Color("354459"), Color("465a6d"), Color("1c3040"), Color("92b3bf"), Color("0b1522")],
	[Color("302c32"), Color("474049"), Color("4a2820"), Color("f58a42"), Color("1b0d12")],
	[Color("3d4930"), Color("49543c"), Color("263d23"), Color("9aaa6b"), Color("12261f")],
	[Color("a28f67"), Color("b7a57d"), Color("697a50"), Color("e0c48a"), Color("698e9d")],
]
var nodes: Array[Vector3] = []
var links: Array = []
var base_links: Array = []
var biome := 0
var root: Node3D
var batches: Dictionary = {}
var materials: Array[Material] = []
var box := BoxMesh.new()
var leaf := SphereMesh.new()
var canopy: ArrayMesh
var column := CylinderMesh.new()

func _init() -> void:
	box.size = Vector3.ONE
	leaf.radius = 0.5
	leaf.height = 1.0
	leaf.radial_segments = 32
	leaf.rings = 16
	column.top_radius = 0.5
	column.bottom_radius = 0.5
	column.height = 1
	column.radial_segments = 24
	canopy = _leaf_cluster()
	for z in range(5):
		for x in range(5):
			var height := 0.0
			if z == 1 and x == 2:
				height = 1.25
			if z == 0:
				height = 3.75 if x == 2 else 1.25
			nodes.append(Vector3((x - 2) * STEP, height, (z - 2) * STEP))
			var adjacent: Array[int] = []
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var p: Vector2i = Vector2i(x, z) + d
				if p.x >= 0 and p.x < 5 and p.y >= 0 and p.y < 5:
					adjacent.append(p.y * 5 + p.x)
			links.append(adjacent)
	base_links = links.duplicate(true)

func _connect(a: int, b: int) -> void:
	if b not in links[a]:
		links[a].append(b)
	if a not in links[b]:
		links[b].append(a)

func _leaf_cluster() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var random := RandomNumberGenerator.new()
	random.seed = 9903
	for i in range(256):
		var center := Vector3(random.randf_range(-0.45, 0.45), random.randf_range(-0.4, 0.4), random.randf_range(-0.45, 0.45))
		if center.length() > 0.5:
			center = center.normalized() * 0.45
		var yaw := random.randf_range(-PI, PI)
		var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, random.randf_range(-0.7, 0.7))
		var points := [Vector3(0, 0, -0.04), Vector3(-0.018, 0, 0), Vector3(0, 0.003, 0), Vector3(0.018, 0, 0), Vector3(0, 0, 0.04)]
		var leaf_color := Color.WHITE * random.randf_range(0.78, 1.05)
		for triangle in [[0, 1, 2], [0, 2, 3], [4, 2, 1], [4, 3, 2]]:
			for id in triangle:
				st.set_normal(basis * Vector3.UP)
				st.set_color(leaf_color)
				st.add_vertex(center + basis * points[id])
	return st.commit()

func _surface(kind: String, color: Color, tiling := 0.65) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/textures/%s/albedo.jpg" % kind)
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/textures/%s/normal.jpg" % kind)
	mat.normal_scale = 0.8
	mat.roughness_texture = load("res://assets/textures/%s/roughness.jpg" % kind)
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.albedo_color = color
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * tiling
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat

func _layout(theme: int) -> void:
	links.clear()
	for i in range(25):
		links.append([])
	var visited: Array[int] = [22]
	var stack: Array[int] = [22]
	while not stack.is_empty():
		var node: int = stack.back()
		var options: Array[int] = []
		for id in base_links[node]:
			if id not in visited:
				options.append(id)
		if options.is_empty():
			stack.pop_back()
		else:
			var next: int = options[(node * 13 + theme * 7 + stack.size() * 3) % options.size()]
			_connect(node, next)
			visited.append(next)
			stack.append(next)
	# Add different loops for each biome; retain a readable first junction and climbs.
	for a in range(25):
		for b in base_links[a]:
			if b > a and (a * 19 + b * 7 + theme * 11) % 5 < 2:
				_connect(a, b)
	for pair in [[22, 17], [17, 16], [17, 12], [17, 18], [12, 7], [7, 2]]:
		_connect(pair[0], pair[1])

func build(parent: Node3D, theme: int) -> Node3D:
	biome = theme
	_layout(theme)
	root = Node3D.new()
	root.name = "BiomeCorridors"
	parent.add_child(root)
	materials.clear()
	var ground := "earth" if biome in [0, 3] else ("sand" if biome == 4 else "rock")
	materials.append(_surface(ground, Color("a8b8a2") if biome in [0, 3] else Color("c1bdaf")))
	materials.append(_surface("masonry" if biome == 0 else "rock", THEMES[biome][1].lightened(0.38)))
	materials.append(_surface("bark" if biome in [0, 3] else "rock", Color("9d9a87")))
	materials.append(_surface("rock", THEMES[biome][3].lightened(0.2)))
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("e76c2c") if biome == 2 else Color("365c79")
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	materials.append(glow)
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color("354e29")
	leaves.vertex_color_use_as_albedo = true
	leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaves.roughness = 0.95
	materials.append(leaves)
	for i in range(nodes.size()):
		_room(i)
		for next in links[i]:
			if next > i:
				_hall(i, next)
	for key in batches:
		var data: Dictionary = batches[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = {"leaves": canopy, "mound": leaf, "column": column, "box": box}[data["shape"]]
		mm.instance_count = data["transforms"].size()
		for i in range(mm.instance_count):
			mm.set_instance_transform(i, data["transforms"][i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = mm
		instance.material_override = materials[data["surface"]]
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(instance)
	batches.clear()
	return root

func _piece(pos: Vector3, size: Vector3, surface: int, solid := false, foliage := false, yaw := 0.0) -> void:
	var shape_kind := "leaves" if foliage and surface == 2 else ("mound" if foliage else ("column" if size.y > 2.7 and size.x < 1.0 and size.z < 1.0 else "box"))
	var material := 5 if shape_kind == "leaves" else surface
	var key := str(material) + shape_kind
	if not batches.has(key):
		batches[key] = {"surface": material, "shape": shape_kind, "transforms": []}
	batches[key]["transforms"].append(Transform3D(Basis(Vector3.UP, yaw).scaled(size), pos))
	if solid:
		var body := StaticBody3D.new()
		root.add_child(body)
		body.position = pos
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)

func _room(id: int) -> void:
	var p := nodes[id]
	_piece(p + Vector3(0, -0.2, 0), Vector3(5.0, 0.4, 5.0), 0, true)
	for x in [-2.45, 2.45]:
		for z in [-2.45, 2.45]:
			_piece(p + Vector3(x, 1.8, z), Vector3(0.65, 3.6, 0.65), 1, true)
			_piece(p + Vector3(x, 0.2, z), Vector3(0.9, 0.4, 0.9), 1)
	var cell := Vector2i(id % 5, id / 5)
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var q: Vector2i = cell + d
		if q.x < 0 or q.x > 4 or q.y < 0 or q.y > 4 or (q.y * 5 + q.x) not in links[id]:
			_piece(p + Vector3(d.x * 2.5, 1.7, d.y * 2.5), Vector3(0.4 if d.x else 5.0, 3.4, 0.4 if d.y else 5.0), 1, true)
	# Landmark above each junction, below the tall camera's upper edge.
	if biome < 3:
		_piece(p + Vector3(0, 3.9, 0), Vector3(5.6, 0.5, 5.6), 1)
		_piece(p + Vector3(0, 3.6, 0), Vector3(0.8, 0.16, 0.8), 3)
	if biome == 0 or biome == 3:
		for side in [-1.0, 1.0]:
			_piece(p + Vector3(side * 3.8, 1.9, 3.7), Vector3(0.7, 4.6, 0.7), 2)
			_piece(p + Vector3(side * 3.8, 4.8, 3.7), Vector3(5.8, 3.1, 4.8), 2, false, true)
			_piece(p + Vector3(side * 2.82, 2.1, -2.4), Vector3(0.08, 2.8, 0.48), 2)
	if biome == 2:
		_piece(p + Vector3(5.2, -1.2, 4.5), Vector3(5.0, 0.25, 5.0), 4)
		_piece(p + Vector3(-4, 0.9, 4.2), Vector3(2.7, 3.0, 2.0), 1, false, false, 0.3)
	if biome == 4:
		_piece(p + Vector3(5.0, 0, 4.8), Vector3(6.0, 3.0, 5.5), 0, false, true)
		_piece(p + Vector3(-4.6, 1.5, 4.2), Vector3(0.45, 4.5, 0.45), 2)
		_piece(p + Vector3(-4.6, 3.9, 4.2), Vector3(4.0, 0.7, 3.0), 2, false, true)
		_piece(p + Vector3(0, -2.0, 8), Vector3(11, 0.3, 5), 4)

func _hall(a: int, b: int) -> void:
	var start := nodes[a]
	var end := nodes[b]
	var flat := end - start
	flat.y = 0
	var dir := flat.normalized()
	var sideways := Vector3(-dir.z, 0, dir.x)
	var along_x := absf(dir.x) > 0.5
	var change := not is_equal_approx(start.y, end.y)
	for half in range(2):
		var center := start + dir * (4.0 if half == 0 else 8.0)
		center.y = start.y if half == 0 else end.y
		var length := 2.8 if change else 4.0
		_piece(center + Vector3(0, -0.2, 0), Vector3(length, 0.4, 4.4) if along_x else Vector3(4.4, 0.4, length), 0, true)
		for side in [-1.0, 1.0]:
			var wall: Vector3 = center + sideways * side * 2.4
			var wall_height := 1.3 if biome >= 3 else 3.4
			_piece(wall + Vector3(0, wall_height * 0.5, 0), Vector3(4.0, wall_height, 0.4) if along_x else Vector3(0.4, wall_height, 4.0), 1, true)
			_piece(wall + Vector3(0, 0.2, 0), Vector3(4.0, 0.35, 0.55) if along_x else Vector3(0.55, 0.35, 4.0), 2)
			if biome == 3:
				var tree: Vector3 = wall + sideways * side * 1.5
				_piece(tree + Vector3.UP * 2.0, Vector3(0.55, 4.0, 0.55), 2)
				_piece(tree + Vector3.UP * 4.5, Vector3(4.5, 3.5, 4.8), 2, false, true)
			if biome == 4:
				_piece(wall + sideways * side * 3.5 + Vector3.UP * 0.3, Vector3(7.0, 3.2, 6.0), 0, false, true)
		if biome < 3 and not change:
			_piece(center + Vector3(0, 3.65, 0), Vector3(4.0, 0.35, 5.0) if along_x else Vector3(5.0, 0.35, 4.0), 1)
	if change:
		# Earthy stone edge markers show the takeoff/landing gap without neon rails.
		for distance in [5.25, 6.75]:
			var marker: Vector3 = start + dir * distance
			marker.y = (start.y if distance < 6 else end.y) + 0.02
			_piece(marker, Vector3(0.1, 0.04, 4.2) if along_x else Vector3(4.2, 0.04, 0.1), 3)

func direction(a: int, b: int) -> Vector3:
	var d := nodes[b] - nodes[a]
	d.y = 0
	return d.normalized()

func climb(a: int, b: int) -> int:
	var difference := nodes[b].y - nodes[a].y
	if difference < -0.1:
		return -1
	if difference > 1.5:
		return 2
	return 1 if difference > 0.1 else 0
