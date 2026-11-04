extends Node3D
signal collected(fighter: int,value: int)
signal denied
const MAX_ORBS := 128
var orbs: Dictionary = {}
var next_id := 1
var cloud: MultiMeshInstance3D
var elapsed := 0.0
var automatic_collection := false

func _ready() -> void:
	cloud = MultiMeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.065
	mesh.height = 0.13
	mesh.radial_segments = 8
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.WHITE
	mat.vertex_color_use_as_albedo = true
	cloud.material_override = mat
	cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cloud.multimesh = MultiMesh.new()
	cloud.multimesh.use_colors = true
	cloud.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	cloud.multimesh.mesh = mesh
	cloud.multimesh.instance_count = MAX_ORBS*3
	cloud.multimesh.visible_instance_count = 0
	add_child(cloud)

func spawn(pos: Vector3,value := 5,id := -1,gold := false) -> int:
	if orbs.size() >= MAX_ORBS:return -1
	if id < 0:
		id = next_id
		next_id += 1
	var area := Area3D.new()
	area.collision_layer = 64 if gold else 8
	area.collision_mask = 0
	area.set_meta("orb",id)
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.18
	col.shape = sphere
	area.add_child(col)
	add_child(area)
	area.position = pos
	orbs[id] = {"area":area,"pos":pos,"anchor":pos,"value":value,"owner":-1,"life":-1.0 if gold else 25.0,"gold":gold}
	return id

func remove(id: int) -> void:
	if not orbs.has(id):return
	var area: Area3D = orbs[id]["area"]
	area.collision_layer = 0
	area.queue_free()
	orbs.erase(id)

func clear() -> void:
	for id in orbs.keys():remove(id)
	if is_instance_valid(cloud):cloud.multimesh.visible_instance_count = 0

func destroy(id: int) -> bool:
	if not orbs.has(id) or orbs[id]["gold"] or (automatic_collection and int(orbs[id]["owner"])>=0):return false
	remove(id)
	denied.emit()
	return true

func pull(fighter: int,from: Vector3,reach: float,collectors: Dictionary,clear_sight: Callable) -> void:
	if automatic_collection:return
	for id in orbs:
		var orb: Dictionary = orbs[id]
		var distance := from.distance_to(orb["pos"])
		if distance > reach or not clear_sight.call(from,orb["pos"]):continue
		var owner: int = orb["owner"]
		if owner < 0 or owner == fighter or not collectors.has(owner) or distance < Vector3(collectors[owner]).distance_to(orb["pos"])*0.95:
			orb["owner"] = fighter

func tick(delta: float,collectors: Dictionary,authoritative: bool) -> void:
	elapsed += delta
	var index := 0
	for id in orbs.keys():
		var orb: Dictionary = orbs[id]
		if authoritative:
			if not orb["gold"]:orb["life"] -= delta
			if not orb["gold"] and orb["life"] <= 0:
				remove(id)
				continue
			var owner: int = orb["owner"]
			if owner >= 0 and collectors.has(owner):
				var end: Vector3 = collectors[owner]
				orb["pos"] = Vector3(orb["pos"]).move_toward(end,delta*15)
				if Vector3(orb["pos"]).distance_to(end)<0.22:
					collected.emit(owner,int(orb["value"]))
					remove(id)
					continue
			else:
				orb["owner"] = -1
				orb["pos"] = Vector3(orb["anchor"])+Vector3(0,sin(elapsed*2+id)*0.1,0)
			orb["area"].position = orb["pos"]
		var color := Color("ffd06a") if orb["gold"] else Color("69cfff")
		var pos: Vector3 = orb["pos"]
		cloud.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*(1.35 if orb["gold"] else 1.0)),pos))
		cloud.multimesh.set_instance_color(index,color)
		index += 1
		for side in [-1.0,1.0]:
			var offset := Vector3(sin(elapsed*3+id)*0.15*side,cos(elapsed*3+id)*0.12,cos(elapsed*2+id)*0.12*side)
			cloud.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*0.36),pos+offset))
			cloud.multimesh.set_instance_color(index,color)
			index += 1
	cloud.multimesh.visible_instance_count = index

func pack() -> Array:
	var result: Array = []
	for id in orbs:
		var orb: Dictionary = orbs[id]
		result.append([id,orb["pos"],orb["value"],orb["owner"],orb["gold"]])
	return result

func apply_snapshot(data: Array) -> void:
	var seen: Array[int] = []
	for item in data:
		var id := int(item[0])
		seen.append(id)
		if not orbs.has(id):spawn(item[1],int(item[2]),id,bool(item[4]))
		orbs[id]["pos"] = item[1]
		orbs[id]["owner"] = int(item[3])
		orbs[id]["area"].collision_layer=0 if automatic_collection and int(item[3])>=0 else 64 if bool(item[4]) else 8
		orbs[id]["area"].position = item[1]
	for id in orbs.keys():
		if id not in seen:remove(id)
