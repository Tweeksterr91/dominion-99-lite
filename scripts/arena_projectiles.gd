extends Node3D
signal impact(projectile: Dictionary,hit: Dictionary)
const LIMIT := 240
var bullets: Dictionary={}
var next_id := 1
var view: MultiMeshInstance3D
func _ready() -> void:
	view=MultiMeshInstance3D.new();view.multimesh=MultiMesh.new();view.multimesh.transform_format=MultiMesh.TRANSFORM_3D;view.multimesh.use_colors=true
	var mesh:=SphereMesh.new();mesh.radius=.045;mesh.height=.09;mesh.radial_segments=6;mesh.rings=3
	view.multimesh.mesh=mesh;view.multimesh.instance_count=LIMIT*2;view.multimesh.visible_instance_count=0
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.vertex_color_use_as_albedo=true;view.material_override=mat;view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(view)
func spawn(pos: Vector3,velocity: Vector3,owner: int,damage: float,mask: int,color: Color,exclude: RID,life := .75) -> void:
	if bullets.size()>=LIMIT:return
	bullets[next_id]={"id":next_id,"pos":pos,"velocity":velocity,"owner":owner,"damage":damage,"mask":mask,"color":color,"exclude":exclude,"life":life}
	next_id+=1
func clear() -> void:
	bullets.clear()
	if is_instance_valid(view):view.multimesh.visible_instance_count=0
func tick(delta: float,authoritative: bool) -> void:
	var n:=0
	for id in bullets.keys():
		if not bullets.has(id):continue
		var bullet: Dictionary=bullets[id]
		var next: Vector3=bullet["pos"]+Vector3(bullet["velocity"])*delta
		bullet["life"]-=delta
		if authoritative:
			var query:=PhysicsRayQueryParameters3D.create(bullet["pos"],next,bullet["mask"],[bullet["exclude"]]);query.collide_with_areas=true;query.hit_from_inside=true
			var hit:=get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty():
				impact.emit(bullet,hit);bullets.erase(id);continue
		if bullet["life"]<=0:bullets.erase(id);continue
		bullet["pos"]=next
		var direction: Vector3=Vector3(bullet["velocity"]).normalized()
		var basis:=Basis.looking_at(direction,Vector3.UP if absf(direction.y)<.98 else Vector3.RIGHT)
		view.multimesh.set_instance_transform(n,Transform3D(Basis.IDENTITY,next));view.multimesh.set_instance_color(n,bullet["color"]);n+=1
		view.multimesh.set_instance_transform(n,Transform3D(basis.scaled(Vector3(.45,.45,6)),next-direction*.22));view.multimesh.set_instance_color(n,Color(bullet["color"],1));n+=1
	view.multimesh.visible_instance_count=n
func pack() -> Array:
	var result: Array=[]
	for b in bullets.values():result.append([b["id"],b["pos"],b["velocity"],b["color"],b["life"]])
	return result
func apply_snapshot(packet: Array) -> void:
	var seen: Array[int]=[]
	for record in packet:
		var id:=int(record[0]);seen.append(id)
		bullets[id]={"id":id,"pos":record[1],"velocity":record[2],"color":record[3],"life":record[4]}
	for id in bullets.keys():
		if id not in seen:bullets.erase(id)
