extends "res://scripts/corridor_map.gd"
## Walkable circular arenas. Nodes are spawn/wander points, never movement rails.
var layout_seed := 99
var nav_region: NavigationRegion3D
var nav_ready := false
var ramps: Array[Array] = []
var jump_links: Array[Array] = []
var ring_radius := 23.0
var spawn_nodes: Array[int]=[]
var building_count := 0
var foliage_patches := 0
const EDGE_RADIUS := 47.0
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
	_add_spawn_points()
	for i in range(nodes.size()):links.append([(i+1)%nodes.size()])
	spawn_nodes.assign(range(nodes.size()))
	root=Node3D.new();root.name="FreeArena";parent.add_child(root)
	nav_region=NavigationRegion3D.new();root.add_child(nav_region)
	var geometry:=Node3D.new();geometry.name="StaticArena";nav_region.add_child(geometry)
	var ground: String="masonry" if biome in [0,1,3] else "sand" if biome==4 else "rock"
	materials.append(_surface(ground,Color("9aa694") if biome in [0,3] else Color("b8b1a3")))
	materials.append(_surface("masonry" if biome in [0,1] else "rock",THEMES[biome][1].lightened(.3)))
	materials.append(_surface("bark" if biome==3 else "rock",Color("777e78")))
	var metal:=StandardMaterial3D.new();metal.albedo_color=Color("333c43");metal.metallic=.7;metal.roughness=.45;materials.append(metal)
	var glow:=StandardMaterial3D.new();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow.albedo_color=Color("ed9a51") if biome==2 else Color("6db1c6");materials.append(glow)
	var foliage:=StandardMaterial3D.new();foliage.albedo_color=Color("355c31");foliage.vertex_color_use_as_albedo=true;foliage.cull_mode=BaseMaterial3D.CULL_DISABLED;foliage.roughness=.95;materials.append(foliage)
	var windows:=StandardMaterial3D.new();windows.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;windows.albedo_color=Color("977349");materials.append(windows)
	var facade:=_surface("masonry",Color("41464d"));materials.append(facade)
	# The entire playable estate rests on a continuous building, not a void.
	_cylinder(geometry,Vector3(0,-12.5,0),48,24.3,7,true)
	_cylinder(geometry,Vector3(0,-.20,0),47.8,.3,0,true)
	_cylinder(geometry,Vector3(0,-.3,0),14.5,.6,0,true)
	for i in range(20):
		var a:=i*TAU/20
		_cylinder(geometry,Vector3(cos(a)*ring_radius,1.8,sin(a)*ring_radius),1.05,3.6,1,true)
	_safety_perimeter(geometry)
	var backdrop:=Node3D.new();backdrop.name="CityBackdrop";root.add_child(backdrop)
	_city_backdrop(backdrop)

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
		_cylinder(geometry,Vector3(center.x,1.85,center.z),5.9,3.7,7,true)
		_cylinder(geometry,center-Vector3.UP*.3,6,.6,0,true)
		_ramp(geometry,Vector3(side*(ring_radius+2),4,0),center,4.0)
		_railing(geometry,center,5.8,true)
		var high:=center+Vector3(0,4,-8)
		_cylinder(geometry,Vector3(high.x,3.75,high.z),3.3,7.5,7,true)
		_cylinder(geometry,high-Vector3.UP*.25,3.5,.5,0,true)
		_ramp(geometry,center+Vector3(0,0,2),high+Vector3(0,0,3.6),3.2)
		_railing(geometry,high,3.3,true)
		for k in range(6):
			var angle:=k*TAU/6
			if absf(sin(angle))<.3:continue
			_cylinder(geometry,center+Vector3(cos(angle)*5,2.4,sin(angle)*5),.30,4.8,1,true)
	# Enclosed gatehouses at the north/south approaches, with real arched doors.
	for side in [-1.0,1.0]:
		_gatehouse(geometry,Vector3(0,4,side*(ring_radius+8)),side)
	# Optional jump islands beyond the ring; the low railings can be jumped over.
	for i in [1,3,5,7]:
		var d:=Vector3(cos(i*TAU/8),0,sin(i*TAU/8))
		var center:=d*(ring_radius+8.2)+Vector3.UP*5
		_cylinder(geometry,Vector3(center.x,2.25,center.z),2.65,4.5,7,true)
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
	_overgrowth(geometry,rng)
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
			_validate_spawns(map)
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
	_batch(box,Transform3D(basis*Basis.from_scale(size),pos),mat)
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
	# Deep masonry cheeks carry each ramp into the building below it.
	for i in range(8):
		var t: float=(i+.5)/8.0;var p:=a.lerp(b,t);var height:=maxf(.10,p.y-.4-absf(direction.y)/16)
		_box(parent,Vector3(p.x,height*.5,p.z),Vector3(width-.15,height,direction.length()/8+.10),7,true,Basis(Vector3.UP,atan2(direction.x,direction.z)))
func _railing(parent: Node3D,center: Vector3,radius: float,openings: bool) -> void:
	for i in range(48):
		var a:=i*TAU/48;var b: float=(i+1)*TAU/48
		if openings and absf(sin(a+b))<minf(.85,4.0/radius):continue
		var p:=center+Vector3(cos(a)*radius,.76,sin(a)*radius)
		var q:=center+Vector3(cos(b)*radius,.76,sin(b)*radius)
		_box(parent,(p+q)*.5,Vector3(.12,.12,p.distance_to(q)+.04),3,true,Basis.looking_at(-(q-p).normalized(),Vector3.UP))
		if i%3==0:_box(parent,p-Vector3.UP*.38,Vector3(.12,.76,.12),3,true)
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

func _gatehouse(parent: Node3D,center: Vector3,_side: float) -> void:
	# Floor joins the raised ring. Wall openings and arch colliders match the visible mesh.
	_box(parent,center-Vector3.UP*2.15,Vector3(12,3.7,10.6),7,true)
	_box(parent,center-Vector3.UP*.2,Vector3(12,.4,10.6),1,true)
	for x in [-6.0,6.0]:_box(parent,center+Vector3(x,2.65,0),Vector3(.65,5.3,10.6),1,true)
	for z in [-5.0,5.0]:
		for x in [-4.0,4.0]:_box(parent,center+Vector3(x,2.65,z),Vector3(4,5.3,.7),1,true)
		_arch(parent,center+Vector3(0,0,z),2.0,2.1,5.3,.7)
	_box(parent,center+Vector3(0,5.4,0),Vector3(12.6,.35,11.0),1,true)
	for x in [-4.8,4.8]:
		for z in [-3.8,3.8]:
			_cylinder(parent,center+Vector3(x,2.35,z),.28,4.7,1,true)
			_box(parent,center+Vector3(x,2.9,z),Vector3(.12,.5,.25),4,false)
	# Low stone furnishings leave the center lane open.
	for x in [-3.8,3.8]:_box(parent,center+Vector3(x,.55,0),Vector3(1.2,1.1,2.4),1,true)

func _arch(parent: Node3D,origin: Vector3,radius: float,spring: float,height: float,depth: float) -> void:
	# Vertical strips follow a semicircular intrados; no invisible box across the doorway.
	for i in range(24):
		var x0: float=-radius+2*radius*i/24.0
		var x1: float=-radius+2*radius*(i+1)/24.0
		var low: float=spring+sqrt(maxf(0,radius*radius-pow((x0+x1)*.5,2)))
		_box(parent,origin+Vector3((x0+x1)*.5,(low+height)*.5,0),Vector3(x1-x0+.008,height-low,depth),1,true)
	# Dark stone voussoirs make the curved doorway easy to read.
	for i in range(16):
		var angle: float=(i+.5)*PI/16
		var pos:=origin+Vector3(cos(angle)*(radius+.13),spring+sin(angle)*(radius+.13),0)
		_box(parent,pos,Vector3(.42,.26,depth+.16),2,false,Basis(Vector3.FORWARD,-angle))

func _add_spawn_points() -> void:
	for radius in [4.0,30.0,39.0,43.0]:
		for i in range(12):nodes.append(Vector3(cos(i*TAU/12+.13)*radius,0,sin(i*TAU/12+.13)*radius))
	for i in range(16):nodes.append(Vector3(cos((i+.5)*TAU/16)*ring_radius,4,sin((i+.5)*TAU/16)*ring_radius))
	for side in [-1.0,1.0]:
		var x: float=side*(ring_radius+12)
		for offset in [-1.5,0.0,1.5]:nodes.append(Vector3(x+offset,4,0))
		nodes.append(Vector3(x,8,-8));nodes.append(Vector3(0,4,side*(ring_radius+8)))
	for i in [1,3,5,7]:nodes.append(Vector3(cos(i*TAU/8)*(ring_radius+8.2),5,sin(i*TAU/8)*(ring_radius+8.2)))
func _validate_spawns(map: RID) -> void:
	spawn_nodes.clear()
	var capsule:=CapsuleShape3D.new();capsule.height=2.1;capsule.radius=.38
	for i in range(nodes.size()):
		var point:=nodes[i];var near:=NavigationServer3D.map_get_closest_point(map,point)
		if point.distance_to(near)>1.0:continue
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.transform=Transform3D(Basis.IDENTITY,point+Vector3.UP*1.18);query.collision_mask=1
		if root.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():spawn_nodes.append(i)
func _safety_perimeter(parent: Node3D) -> void:
	for i in range(96):
		var a: float=i*TAU/96;var b: float=(i+1)*TAU/96
		var p:=Vector3(cos(a)*EDGE_RADIUS,0,sin(a)*EDGE_RADIUS)
		var q:=Vector3(cos(b)*EDGE_RADIUS,0,sin(b)*EDGE_RADIUS)
		var basis:=Basis.looking_at(-(q-p).normalized(),Vector3.UP)
		_box(parent,(p+q)*.5+Vector3.UP*.45,Vector3(.45,.9,p.distance_to(q)+.08),1,true,basis)
		_box(parent,p+Vector3.UP*1.3,Vector3(.09,2.6,.09),3,false)
		_box(parent,(p+q)*.5+Vector3.UP*2.4,Vector3(.06,.06,p.distance_to(q)+.05),3,false,basis)
		var shape:=BoxShape3D.new();shape.size=Vector3(.30,24,p.distance_to(q)+.12)
		_solid(parent,(p+q)*.5+Vector3.UP*12,shape,basis)
func _city_backdrop(parent: Node3D) -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=layout_seed+1929
	for i in range(48):
		var a: float=i*TAU/48;var distance:=rng.randf_range(85,155);var height:=rng.randf_range(20,75)
		var center:=Vector3(cos(a)*distance,-18,sin(a)*distance);var width:=rng.randf_range(9,17);var depth:=rng.randf_range(9,17)
		for tier in range(3):
			var h: float=height*(.65 if tier==0 else .22 if tier==1 else .13)
			var y: float=height*(0 if tier==0 else .65 if tier==1 else .87)
			_box(parent,center+Vector3(0,y+h*.5,0),Vector3(width*(1-tier*.18),h,depth*(1-tier*.18)),7,false)
		for row in range(2,int(height/3.2)):
			for col in range(4):
				if rng.randf()<.42:continue
				var tier: int=0 if row*3.2<height*.65 else 1 if row*3.2<height*.87 else 2
				var factor: float=1-tier*.18
				var offset: float=(col-1.5)*.20
				if absf(center.z)>=absf(center.x):
					_box(parent,center+Vector3(offset*width*factor,row*3.2,-signf(center.z)*depth*factor*.501),Vector3(.65,1.25,.08),6,false)
				else:
					_box(parent,center+Vector3(-signf(center.x)*width*factor*.501,row*3.2,offset*depth*factor),Vector3(.08,1.25,.65),6,false)
		if i%3==0:
			_cylinder(parent,center+Vector3(0,height+2.2,0),2.0,4.4,2,false)
			for x in [-1.5,1.5]:_box(parent,center+Vector3(x,height-.5,0),Vector3(.14,3,.14),3,false)
		building_count+=1
func _overgrowth(parent: Node3D,rng: RandomNumberGenerator) -> void:
	for i in range(84):
		var a:=rng.randf()*TAU;var radius:=rng.randf_range(15,45);var p:=Vector3(cos(a)*radius,.13,sin(a)*radius)
		var scale:=rng.randf_range(.8,1.9)
		_batch(canopy,Transform3D(Basis.IDENTITY.scaled(Vector3(scale,.5,scale)),p),5);foliage_patches+=1
	# Ivy hangs from the central columns and gatehouse facades in broken patches.
	for i in range(12):
		var a: float=i*TAU/12+PI/12;var center:=Vector3(cos(a)*12,5.8,sin(a)*12)
		for j in range(6):
			var p:=center+Vector3(sin(j*.9+i)*.22,-j*.65,cos(j*.6+i)*.22)
			_batch(canopy,Transform3D(Basis.IDENTITY.scaled(Vector3(.5,.65,.5)),p),5)
	for side in [-1.0,1.0]:
		for x in [-4.8,4.8]:
			for j in range(6):_batch(canopy,Transform3D(Basis.IDENTITY.scaled(Vector3(.7,.55,.5)),Vector3(x+sin(j)*.2,8.8-j*.6,side*(ring_radius+3))),5)
