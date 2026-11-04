extends "res://scripts/corridor_map.gd"
## Walkable circular arenas. Nodes are spawn/wander points, never movement rails.
var layout_seed := 99
var nav_region: NavigationRegion3D
var nav_ready := false
var ramps: Array[Array] = []
var jump_links: Array[Array] = []
var ring_radius := 23.0
var geometry_batches: Dictionary = {}
func build(parent: Node3D,theme: int) -> Node3D:
	column.radial_segments=64
	NavigationServer3D.map_set_use_async_iterations(parent.get_world_3d().navigation_map,false)
	biome=theme;ring_radius=[23.0,22.0,24.0,23.5,25.0][theme]
	nodes.clear();links.clear();materials.clear();ramps.clear();jump_links.clear()
	for i in range(8):nodes.append(Vector3(cos(i*TAU/8)*8,0,sin(i*TAU/8)*8))
	for i in range(8):nodes.append(Vector3(cos(i*TAU/8)*ring_radius,4,sin(i*TAU/8)*ring_radius))
	for i in range(8):nodes.append(Vector3(cos(i*TAU/8)*11,0,sin(i*TAU/8)*11))
	nodes.append(Vector3.ZERO)
	for i in range(25):links.append([(i+1)%25])
	root=Node3D.new();root.name="FreeArena";parent.add_child(root)
	nav_region=NavigationRegion3D.new();root.add_child(nav_region)
	var geometry:=Node3D.new();geometry.name="StaticArena";nav_region.add_child(geometry)
	var ground: String="earth" if biome in [0,3] else "sand" if biome==4 else "rock"
	materials.append(_surface(ground,Color("9aa694") if biome in [0,3] else Color("b8b1a3")))
	materials.append(_surface("masonry" if biome in [0,1] else "rock",THEMES[biome][1].lightened(.3)))
	materials.append(_surface("bark" if biome==3 else "rock",Color("777e78")))
	var metal:=StandardMaterial3D.new();metal.albedo_color=Color("333c43");metal.metallic=.7;metal.roughness=.45;materials.append(metal)
	var glow:=StandardMaterial3D.new();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow.albedo_color=Color("ed9a51") if biome==2 else Color("6db1c6");materials.append(glow)
	var foliage:=StandardMaterial3D.new();foliage.albedo_color=Color("355c31");foliage.vertex_color_use_as_albedo=true;foliage.cull_mode=BaseMaterial3D.CULL_DISABLED;foliage.roughness=.95;materials.append(foliage)
	_cylinder(geometry,Vector3(0,-.3,0),14.5,.6,0,true)
	_ring(geometry,Vector3(0,4,0),ring_radius-3,ring_radius+3,0,true)
	_railing(geometry,Vector3.ZERO,14.2,true)
	_ring(geometry,Vector3(0,6.2,0),11.5,12.5,1,true)
	_railing(geometry,Vector3(0,4,0),ring_radius-2.85,true)
	_railing(geometry,Vector3(0,4,0),ring_radius+2.85,true)
	for i in range(4):
		var d:=Vector3(cos(i*PI/2),0,sin(i*PI/2))
		var begin:=d*11
		var finish:=d*(ring_radius-3.5)+Vector3.UP*4
		_ramp(geometry,begin,finish,4.2)
		_box(geometry,d*(ring_radius-1.7)+Vector3.UP*3.8,Vector3(4.2,.4,3.6) if i%2 else Vector3(3.6,.4,4.2),0,true)
	# Wide side rotundas and ramps to upper balconies introduce genuine vertical routes.
	for side in [-1.0,1.0]:
		var center:=Vector3(side*(ring_radius+12),4,0)
		_cylinder(geometry,center-Vector3.UP*.3,6,.6,0,true)
		_ramp(geometry,Vector3(side*(ring_radius+2),4,0),center,4.0)
		_railing(geometry,center,5.8,true)
		var high:=center+Vector3(0,4,-8)
		_cylinder(geometry,high-Vector3.UP*.25,3.5,.5,0,true)
		_ramp(geometry,center+Vector3(0,0,2),high+Vector3(0,0,3.6),3.2)
		_railing(geometry,high,3.3,true)
		for k in range(6):
			var angle:=k*TAU/6
			if absf(sin(angle))<.3:continue
			_cylinder(geometry,center+Vector3(cos(angle)*5,2.4,sin(angle)*5),.30,4.8,1,true)
	# Optional jump islands beyond the ring; the low railings can be jumped over.
	for i in [1,3,5,7]:
		var d:=Vector3(cos(i*TAU/8),0,sin(i*TAU/8))
		var center:=d*(ring_radius+8.2)+Vector3.UP*5
		_cylinder(geometry,center-Vector3.UP*.25,2.8,.5,0,true)
		_railing(geometry,center,2.65,true)
		var entry:=d*(ring_radius+2.3)+Vector3.UP*4
		var exit:=d*(ring_radius+6.4)+Vector3.UP*5
		jump_links.append([entry,exit])
		var link:=NavigationLink3D.new();link.start_position=entry;link.end_position=exit;link.bidirectional=true;link.enter_cost=4;root.add_child(link)
	# Pillars and scattered cover break sightlines without enclosing every route in boxes.
	for i in range(12):
		var a: float=i*TAU/12+PI/12
		var p:=Vector3(cos(a)*12,3.1,sin(a)*12)
		_cylinder(geometry,p,.45,6.2,1,true)
		_cylinder(geometry,p+Vector3.UP*2.6,.52,.13,4,false)
	var rng:=RandomNumberGenerator.new();rng.seed=layout_seed+theme*71
	for i in range(12):
		var a:=rng.randf()*TAU;var r:=rng.randf_range(4,10)
		_cylinder(geometry,Vector3(cos(a)*r,.6,sin(a)*r),rng.randf_range(.6,1.1),1.2,1,true)
	# A distant visual basin gives fall depth; it never catches players as a hidden floor.
	_cylinder(geometry,Vector3(0,-14,0),65,.2,4 if biome in [2,4] else 1,false)
	if biome==3:
		for i in range(24):
			var a:=i*TAU/24;var p:=Vector3(cos(a)*43,-2,sin(a)*43)
			_cylinder(geometry,p,.5,15,2,false)
			_batch(canopy,Transform3D(Basis.IDENTITY.scaled(Vector3(9,6,9)),p+Vector3.UP*6),5)
	_flush_geometry(geometry)
	var mesh:=NavigationMesh.new()
	mesh.cell_size=.3;mesh.cell_height=.15;mesh.agent_height=2.1;mesh.agent_radius=.6;mesh.agent_max_climb=.3;mesh.agent_max_slope=42
	mesh.geometry_parsed_geometry_type=NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_region.navigation_mesh=mesh
	nav_region.bake_finished.connect(_navigation_baked)
	nav_region.bake_navigation_mesh(true)
	return root
func _navigation_baked() -> void:
	for attempt in range(200):
		if not is_instance_valid(root) or not root.is_inside_tree():return
		var map:=nav_region.get_navigation_map()
		NavigationServer3D.map_force_update(map)
		if NavigationServer3D.map_get_closest_point(map,Vector3(0,4,ring_radius)).y>3.5:
			nav_ready=true
			return
		await root.get_tree().create_timer(.05).timeout
	push_error("Arena navigation did not synchronize")

func _batch(mesh: Mesh,transform: Transform3D,material: int) -> void:
	var key:=str(mesh.get_instance_id())+":"+str(material)
	if not geometry_batches.has(key):geometry_batches[key]={"mesh":mesh,"material":material,"transforms":[]}
	geometry_batches[key]["transforms"].append(transform)
func _flush_geometry(parent: Node3D) -> void:
	for data in geometry_batches.values():
		var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=data["mesh"];mm.instance_count=data["transforms"].size()
		for i in range(mm.instance_count):mm.set_instance_transform(i,data["transforms"][i])
		var view:=MultiMeshInstance3D.new();view.multimesh=mm;view.material_override=materials[data["material"]];parent.add_child(view)
	geometry_batches.clear()
func _solid(parent: Node3D,pos: Vector3,shape: Shape3D,basis := Basis.IDENTITY) -> void:
	var body:=StaticBody3D.new();body.position=pos;body.basis=basis;body.collision_layer=1;parent.add_child(body)
	var col:=CollisionShape3D.new();col.shape=shape;body.add_child(col)
func _box(parent: Node3D,pos: Vector3,size: Vector3,mat: int,solid: bool,basis := Basis.IDENTITY) -> void:
	_batch(box,Transform3D(basis.scaled(size),pos),mat)
	if solid:
		var shape:=BoxShape3D.new();shape.size=size;_solid(parent,pos,shape,basis)
func _cylinder(parent: Node3D,pos: Vector3,radius: float,height: float,mat: int,solid: bool) -> void:
	_batch(column,Transform3D(Basis.IDENTITY.scaled(Vector3(radius*2,height,radius*2)),pos),mat)
	if solid:
		var shape:=CylinderShape3D.new();shape.radius=radius;shape.height=height;_solid(parent,pos,shape)
func _ramp(parent: Node3D,a: Vector3,b: Vector3,width: float) -> void:
	ramps.append([a,b,width])
	var direction:=b-a;var basis:=Basis.looking_at(-direction.normalized(),Vector3.UP)
	_box(parent,(a+b)*.5-basis.y*.2,Vector3(width,.4,direction.length()+.15),0,true,basis)
func _railing(parent: Node3D,center: Vector3,radius: float,openings: bool) -> void:
	for i in range(48):
		var a:=i*TAU/48;var b: float=(i+1)*TAU/48
		if openings and absf(sin(a+b))<minf(.85,4.0/radius):continue
		var p:=center+Vector3(cos(a)*radius,.64,sin(a)*radius)
		var q:=center+Vector3(cos(b)*radius,.64,sin(b)*radius)
		_box(parent,(p+q)*.5,Vector3(.075,.075,p.distance_to(q)+.04),3,true,Basis.looking_at(-(q-p).normalized(),Vector3.UP))
		if i%3==0:_box(parent,p-Vector3.UP*.32,Vector3(.08,.64,.08),3,true)
func _ring(parent: Node3D,center: Vector3,inner: float,outer: float,mat: int,solid: bool) -> void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(96):
		var a:=i*TAU/96;var b: float=(i+1)*TAU/96
		var points: Array[Vector3]=[Vector3(cos(a)*inner,0,sin(a)*inner),Vector3(cos(a)*outer,0,sin(a)*outer),Vector3(cos(b)*outer,0,sin(b)*outer),Vector3(cos(b)*inner,0,sin(b)*inner)]
		for id in [0,1,2,0,2,3]:st.set_normal(Vector3.UP);st.add_vertex(points[id])
		for pair in [[1,2],[3,0]]:
			var wall: Array[Vector3]=[points[pair[0]],points[pair[1]],points[pair[1]]-Vector3.UP*.4,points[pair[0]]-Vector3.UP*.4]
			var normal: Vector3=Vector3(cos((a+b)*.5),0,sin((a+b)*.5))*(1 if pair[0]==1 else -1)
			for index in [0,1,2,0,2,3]:st.set_normal(normal);st.add_vertex(wall[index])
	var mesh:=st.commit();var view:=MeshInstance3D.new();view.mesh=mesh;view.position=center;var ring_mat: Material=materials[mat].duplicate();ring_mat.cull_mode=BaseMaterial3D.CULL_DISABLED;view.material_override=ring_mat;parent.add_child(view)
	if solid:
		for i in range(96):
			var angle: float=(i+.5)*TAU/96
			var radius: float=(inner+outer)*.5
			var shape:=BoxShape3D.new();shape.size=Vector3(outer-inner,.4,2*outer*sin(PI/96)+.32)
			_solid(parent,center+Vector3(cos(angle)*radius,-.2,sin(angle)*radius),shape,Basis(Vector3.UP,-angle))
