extends RefCounted
## Original low-poly asset kit. Static boxes share materials and GPU instance batches.

const METAL_SHADER = preload("res://assets/metal.gdshader")
const SENTINEL = preload("res://assets/models/sentinel.glb")
const OUTLINE = preload("res://assets/team_outline.gdshader")
const WARDEN = preload("res://assets/models/warden.glb")
const SIDEARM = preload("res://assets/models/sidearm.glb")
const SKIN = preload("res://assets/skin.gdshader")
var character_materials: Dictionary = {}
const PALETTE := {
	"iron": Color("344250"), "dark": Color("18212c"),
	"plate": Color("526273"), "rust": Color("66473f"),
	"floor": Color("303b47"), "bone": Color("a29888"),
	"cyan": Color("64deea"), "amber": Color("f2ad56"),
	"red": Color("ff5b62"), "green": Color("8be5ab"),
}
var materials: Dictionary = {}
var batches: Dictionary = {}
var arena: Node3D
var unit_box := BoxMesh.new()
var model_box: ArrayMesh

func _init() -> void:
	unit_box.size = Vector3.ONE
	model_box = _beveled_box()
	for key in PALETTE:
		if key in ["cyan", "amber", "red", "green"]:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = PALETTE[key]
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			materials[key] = mat
		else:
			var mat := ShaderMaterial.new()
			mat.shader = METAL_SHADER
			mat.set_shader_parameter("metal_color", PALETTE[key])
			materials[key] = mat

func _part(parent: Node3D, pos: Vector3, size: Vector3, surface: String, tilt := 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = model_box
	mesh.material_override = materials[surface]
	parent.add_child(mesh)
	mesh.position = pos
	mesh.scale = size
	mesh.rotation.z = tilt
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh

func _beveled_box() -> ArrayMesh:
	# Chamfered armor edges create an angular silhouette without external models.
	var faces: Array = []
	var k := 0.36
	for axis in range(3):
		for side in [-1.0, 1.0]:
			var points: Array[Vector3] = []
			for corner in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1)]:
				var point := Vector3.ZERO
				point[axis] = side * 0.5
				point[(axis + 1) % 3] = corner.x * k
				point[(axis + 2) % 3] = corner.y * k
				points.append(point)
			faces.append(points)
	# Twelve edge bevels, connecting the six broad faces.
	for axis in range(3):
		var a := (axis + 1) % 3
		var b := (axis + 2) % 3
		for sa in [-1.0, 1.0]:
			for sb in [-1.0, 1.0]:
				var points: Array[Vector3] = []
				for corner in [Vector2(-1, 0), Vector2(1, 0), Vector2(1, 1), Vector2(-1, 1)]:
					var point := Vector3.ZERO
					point[axis] = corner.x * k
					point[a] = sa * (0.5 if corner.y == 0 else k)
					point[b] = sb * (k if corner.y == 0 else 0.5)
					points.append(point)
				faces.append(points)
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				faces.append([Vector3(x * 0.5, y * k, z * k), Vector3(x * k, y * 0.5, z * k), Vector3(x * k, y * k, z * 0.5)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		var normal: Vector3 = (face[1] - face[0]).cross(face[2] - face[0]).normalized()
		var center: Vector3 = Vector3.ZERO
		for point in face:
			center += point
		if normal.dot(center) < 0:
			normal = -normal
		for i in range(1, face.size() - 1):
			var triangle: Array = [face[0], face[i], face[i + 1]]
			if (triangle[1] - triangle[0]).cross(triangle[2] - triangle[0]).dot(normal) > 0:
				triangle.reverse()
			for point in triangle:
				st.set_normal(normal)
				st.set_uv(Vector2(point.x + point.z, point.y) + Vector2(0.5, 0.5))
				st.add_vertex(point)
	return st.commit()

func _static(pos: Vector3, size: Vector3, surface: String, solid := false, tilt := 0.0) -> void:
	if not batches.has(surface):
		batches[surface] = []
	var basis := Basis(Vector3.UP, tilt).scaled(size)
	batches[surface].append(Transform3D(basis, pos))
	if solid:
		var body := StaticBody3D.new()
		arena.add_child(body)
		body.position = pos
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)

func _flush() -> void:
	for surface in batches:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = unit_box
		multimesh.instance_count = batches[surface].size()
		for i in range(multimesh.instance_count):
			multimesh.set_instance_transform(i, batches[surface][i])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Arena_" + surface
		instance.multimesh = multimesh
		instance.material_override = materials[surface]
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arena.add_child(instance)
	batches.clear()

func _pack_model(parent: Node3D) -> void:
	# One draw per surface per model, instead of one draw for every armor plate.
	var groups: Dictionary = {}
	for child in parent.get_children():
		if child is MeshInstance3D:
			var key: int = child.material_override.get_instance_id()
			if not groups.has(key):
				groups[key] = {"material": child.material_override, "transforms": []}
			groups[key]["transforms"].append(child.transform)
			child.free()
	for key in groups:
		var data: Dictionary = groups[key]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = model_box
		multimesh.instance_count = data["transforms"].size()
		for i in range(multimesh.instance_count):
			multimesh.set_instance_transform(i, data["transforms"][i])
		var mesh := MultiMeshInstance3D.new()
		mesh.multimesh = multimesh
		mesh.material_override = data["material"]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mesh)

func build_arena(parent: Node3D) -> void:
	arena = parent
	_static(Vector3(0, -0.3, 0), Vector3(36, 0.6, 36), "floor", true)
	for z in [-18.0, 18.0]:
		_static(Vector3(0, 3.5, z), Vector3(37, 7, 1), "dark", true)
		var inset: float = z * 0.965
		for x in range(-15, 16, 6):
			_static(Vector3(x, 2.5, inset), Vector3(5.6, 4.8, 0.16), "iron")
			_static(Vector3(x, 0.35, inset - signf(z) * 0.1), Vector3(5.6, 0.5, 0.22), "rust")
			_static(Vector3(x, 5.5, inset), Vector3(0.3, 2.2, 0.35), "plate")
			_static(Vector3(x, 4.6, inset - signf(z) * 0.13), Vector3(3.6, 0.08, 0.08), "cyan")
			for rib in [-2.6, 2.6]:
				_static(Vector3(x + rib, 2.7, inset - signf(z) * 0.15), Vector3(0.25, 5.3, 0.35), "plate")
	for x in [-18.0, 18.0]:
		_static(Vector3(x, 3.5, 0), Vector3(1, 7, 36), "dark", true)
		for z in range(-15, 16, 6):
			_static(Vector3(x * 0.965, 2.5, z), Vector3(0.16, 4.8, 5.6), "iron")
			_static(Vector3(x * 0.957, 4.6, z), Vector3(0.08, 0.08, 3.6), "cyan")
			_static(Vector3(x * 0.952, 2.7, z - 2.6), Vector3(0.35, 5.3, 0.25), "plate")
	# Four cover pylons keep the original collision footprints.
	for x in [-7.0, 7.0]:
		for z in [-6.0, 6.0]:
			_static(Vector3(x, 1.9, z), Vector3(2.5, 3.8, 2.5), "dark", true)
			_static(Vector3(x, 0.28, z), Vector3(2.7, 0.55, 2.7), "plate")
			_static(Vector3(x, 3.65, z), Vector3(2.7, 0.3, 2.7), "rust")
			for side in [-1.0, 1.0]:
				_static(Vector3(x + side * 1.27, 2.0, z), Vector3(0.06, 2.6, 0.6), "iron")
				_static(Vector3(x + side * 1.31, 2.0, z), Vector3(0.04, 1.8, 0.10), "cyan")
				_static(Vector3(x, 2.0, z + side * 1.27), Vector3(1.7, 2.6, 0.06), "iron")
				_static(Vector3(x, 2.1, z + side * 1.31), Vector3(0.10, 1.8, 0.04), "cyan")
				for band in [0.8, 3.0]:
					_static(Vector3(x, band, z + side * 1.32), Vector3(2.2, 0.1, 0.04), "amber")
	# Steel floor seams, inset energy conduits, and a marked central dueling area.
	for i in range(-4, 5):
		_static(Vector3(i * 4, 0.012, 0), Vector3(0.045, 0.02, 35), "dark")
		_static(Vector3(0, 0.013, i * 4), Vector3(35, 0.02, 0.045), "dark")
	for side in [-1.0, 1.0]:
		_static(Vector3(side * 3.0, 0.025, 0), Vector3(0.055, 0.02, 30), "cyan")
		_static(Vector3(0, 0.026, side * 3.0), Vector3(6, 0.02, 0.07), "amber")
		for i in range(8):
			_static(Vector3(-1.75 + i * 0.5, 0.03, side * 3.35), Vector3(0.22, 0.025, 0.5), "rust", false, -0.5)
	# Ceiling trusses frame a dark open industrial vault.
	_static(Vector3(0, 8.3, 0), Vector3(37, 0.4, 37), "dark")
	for x in [-12.0, 0.0, 12.0]:
		_static(Vector3(x, 7.0, 0), Vector3(0.6, 0.7, 36), "dark")
		_static(Vector3(x, 6.6, 0), Vector3(0.14, 0.08, 29), "cyan")
	for z in [-12.0, 0.0, 12.0]:
		_static(Vector3(0, 7.0, z), Vector3(36, 0.6, 0.6), "iron")
	# Recessed blast-door artwork behind the far boundary.
	_static(Vector3(0, 2.2, -17.25), Vector3(4.5, 4.4, 0.25), "dark")
	for side in [-1.0, 1.0]:
		_static(Vector3(side * 2.35, 2.25, -17.05), Vector3(0.25, 4.5, 0.35), "plate")
		_static(Vector3(side * 0.07, 2.15, -17.05), Vector3(0.035, 3.8, 0.04), "red")
	_static(Vector3(0, 4.55, -17.05), Vector3(4.9, 0.3, 0.35), "plate")
	_flush()
	var reactor := Node3D.new()
	parent.add_child(reactor)
	reactor.position = Vector3(0, 6.1, 0)
	_part(reactor, Vector3.ZERO, Vector3(2.4, 2.2, 2.4), "dark")
	_part(reactor, Vector3(0, 1.15, 0), Vector3(3.0, 0.35, 3.0), "plate")
	_part(reactor, Vector3(0, -1.05, 0), Vector3(2.8, 0.3, 2.8), "rust")
	for side in [-1.0, 1.0]:
		_part(reactor, Vector3(side * 1.21, 0, 0), Vector3(0.025, 1.5, 1.3), "amber")
		_part(reactor, Vector3(0, 0, side * 1.21), Vector3(1.3, 1.5, 0.025), "amber")
		for rib in [-0.55, 0.0, 0.55]:
			_part(reactor, Vector3(rib, 0, side * 1.25), Vector3(0.20, 1.8, 0.12), "dark")
	_part(reactor, Vector3(0, -1.22, 0), Vector3(1.5, 0.04, 1.5), "red")
	_pack_model(reactor)
	_sign(parent, "DOMINION\nSECTOR 99", Vector3(0, 5.7, -17.0), 0, 54)
	_sign(parent, "CONTAINMENT / 04", Vector3(0, 4.15, -16.99), 0, 22)

func _sign(parent: Node3D, text: String, pos: Vector3, yaw: float, font_size: int) -> void:
	var label := Label3D.new()
	parent.add_child(label)
	label.text = text
	label.position = pos
	label.rotation.y = yaw
	label.font_size = font_size
	label.pixel_size = 0.009
	label.modulate = PALETTE["cyan"]
	label.outline_size = 0
	label.no_depth_test = false

func build_weapon(parent: Node3D) -> void:
	var model := SIDEARM.instantiate()
	model.name = "DetailedSidearm"
	parent.add_child(model)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.layers = 2

func build_enemy(parent: Node3D) -> void:
	var model := WARDEN.instantiate()
	model.name = "Creature"
	model.rotation.y = PI
	parent.add_child(model)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for surface in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.get_active_material(surface)
			if original is StandardMaterial3D and ("body" in original.resource_name.to_lower() or "clothes" in original.resource_name.to_lower()):
				var key := original.resource_name
				if not character_materials.has(key):
					var skin := ShaderMaterial.new()
					skin.shader = SKIN
					skin.set_shader_parameter("albedo_tex", original.albedo_texture)
					skin.set_shader_parameter("tint", Color("9aa6ac") if "body" in key.to_lower() else Color("555c66"))
					character_materials[key] = skin
				mesh.set_surface_override_material(surface, character_materials[key])
	var animation: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if animation:
		var clips: Dictionary = {}
		for clip in animation.get_animation_list():
			for name in ["Run", "Idle", "Jump"]:
				if clip.ends_with(name):
					clips[name] = clip
					animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		parent.set_meta("animation", animation)
		parent.set_meta("clips", clips)
		animate_enemy(parent, "Run")
	parent.set_meta("model", model)
	var flash := _part(parent, Vector3(0.35, 1.01, -0.76), Vector3(0.12, 0.12, 0.16), "red")
	flash.name = "MuzzleFlash"
	flash.visible = false

func build_player(parent: Node3D,team: int) -> void:
	var model := SENTINEL.instantiate()
	model.name = "Sentinel"
	parent.add_child(model)
	var color := Color("48a9ff") if team==0 else Color("ff4f62")
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for surface in range(mesh.mesh.get_surface_count()):
			var original: StandardMaterial3D = mesh.get_active_material(surface)
			var key := "sentinel_%d_%s" % [team,original.resource_name]
			if not character_materials.has(key):
				var material: StandardMaterial3D = original.duplicate()
				if original.resource_name.begins_with("Team"):
					material.albedo_color = color.darkened(.35) if "enamel" in original.resource_name else color
					if material.emission_enabled:material.emission = color
				var outline := ShaderMaterial.new()
				outline.shader = OUTLINE
				outline.set_shader_parameter("team_color",color)
				material.next_pass = outline
				character_materials[key] = material
			mesh.set_surface_override_material(surface,character_materials[key])
	var animation: AnimationPlayer = model.find_child("AnimationPlayer",true,false)
	var clips: Dictionary = {}
	if animation:
		for clip in animation.get_animation_list():
			for state in ["Run","Idle","Jump"]:
				if clip.ends_with(state):
					clips[state] = clip
					animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		parent.set_meta("animation",animation)
		parent.set_meta("clips",clips)
	parent.set_meta("model",model)
	parent.set_meta("team_color",color)
	animate_enemy(parent,"Run")
	var flash := _part(parent,Vector3(.4,1.13,-.53),Vector3(.08,.08,.12),"amber")
	flash.name = "MuzzleFlash"
	flash.hide()

func style_minion(parent: Node3D,kind: String) -> void:
	var tint: Color = {"scavenger":Color("82998b"),"stalker":Color("9d78b9"),"brute":Color("b47b61"),"treasure":Color("e6c16b")}.get(kind,Color.WHITE)
	var model: Node3D = parent.get_meta("model")
	if kind=="stalker":model.scale = Vector3(.78,1.03,.85)
	if kind=="brute":model.scale = Vector3(1.08,1,1.08)
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.get_active_material(surface)
			if original is ShaderMaterial:
				var key := "minion_%s_%d_%d" % [kind,surface,original.get_instance_id()]
				if not character_materials.has(key):
					var material: ShaderMaterial = original.duplicate()
					material.set_shader_parameter("tint",tint if surface==0 else tint.darkened(.4))
					character_materials[key] = material
				mesh.set_surface_override_material(surface,character_materials[key])
	if kind=="treasure":
		var crown := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = .27
		torus.outer_radius = .32
		torus.rings = 16
		torus.ring_segments = 8
		crown.mesh = torus
		crown.material_override = materials["amber"]
		crown.position = Vector3(0,2.1,0)
		crown.rotation.z = .20
		model.add_child(crown)
		for side in [-1.0,1.0]:
			var crystal := MeshInstance3D.new()
			var gem := PrismMesh.new()
			gem.size = Vector3(.16,.45,.15)
			crystal.mesh = gem
			crystal.material_override = materials["amber"]
			crystal.position = Vector3(side*.65,1.1,0)
			model.add_child(crystal)

func animate_enemy(enemy: Node3D, state: String) -> void:
	if not enemy.has_meta("animation"):
		return
	var player: AnimationPlayer = enemy.get_meta("animation")
	var clips: Dictionary = enemy.get_meta("clips")
	if clips.has(state) and player.current_animation != clips[state]:
		player.play(clips[state], 0.12)

func build_pickup(parent: Node3D, pos: Vector3, kind: String) -> Node3D:
	var item := Node3D.new()
	parent.add_child(item)
	item.position = pos
	var accent := "green" if kind == "health" else "amber"
	_part(item, Vector3.ZERO, Vector3(0.5, 0.42, 0.42), "dark")
	_part(item, Vector3(0, 0.23, 0), Vector3(0.53, 0.06, 0.45), "plate")
	for side in [-1.0, 1.0]:
		if kind == "health":
			_part(item, Vector3(0, 0, side * 0.22), Vector3(0.30, 0.09, 0.02), accent)
			_part(item, Vector3(0, 0, side * 0.225), Vector3(0.09, 0.30, 0.02), accent)
		else:
			for x in [-0.14, 0.0, 0.14]:
				_part(item, Vector3(x, 0, side * 0.22), Vector3(0.065, 0.27, 0.02), accent)
	_pack_model(item)
	return item
