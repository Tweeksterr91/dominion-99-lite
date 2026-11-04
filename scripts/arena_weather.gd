extends Node3D
const TIMES := ["DAWN 06:10","DAY 12:30","DUSK 18:40","NIGHT 23:20"]
const WEATHERS := [["CLEAR","RAIN","FOG","OVERCAST"],["CLEAR","FOG","OVERCAST"],["CLEAR","ASH STORM","FOG"],["CLEAR","RAIN","FOG","SNOW"],["CLEAR","SANDSTORM","OVERCAST"]]
var conditions: Dictionary={}
var particles: MultiMeshInstance3D
var phase := 0.0
var camera_ref: Camera3D
static func roll(seed_value: int,biome: int) -> Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value+990819
	var time_id:=rng.randi_range(0,3)
	return {"time":TIMES[time_id],"time_id":time_id,"weather":WEATHERS[biome][rng.randi_range(0,WEATHERS[biome].size()-1)]}
func apply(value: Dictionary,environment: Environment,sun: DirectionalLight3D,camera: Camera3D) -> void:
	conditions=value;camera_ref=camera
	var index: int=value["time_id"];var weather: String=value["weather"]
	var sky:=ProceduralSkyMaterial.new()
	sky.sky_top_color=[Color("536c91"),Color("407da6"),Color("45384f"),Color("101e35")][index]
	sky.sky_horizon_color=[Color("d5a079"),Color("b4c5cc"),Color("c47c68"),Color("354a63")][index]
	if weather!="CLEAR":sky.sky_top_color=sky.sky_top_color.lerp(Color("687681"),.45);sky.sky_horizon_color=sky.sky_horizon_color.lerp(Color("859099"),.35)
	sky.ground_bottom_color=Color("20262c");sky.ground_horizon_color=sky.sky_horizon_color.darkened(.25)
	var sky_resource:=Sky.new();sky_resource.sky_material=sky;sky_resource.radiance_size=Sky.RADIANCE_SIZE_128
	environment.sky=sky_resource;environment.background_mode=Environment.BG_SKY;environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("b9c9da");environment.ambient_light_energy=.68 if index!=3 else .50
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.fog_enabled=true;environment.fog_light_color=sky.sky_horizon_color
	environment.fog_density=.018 if weather=="FOG" else .011 if weather in ["SANDSTORM","ASH STORM"] else .0025
	sun.rotation_degrees=Vector3([-18,-55,-14,-28][index],[-70,-25,100,35][index],0)
	sun.light_energy=[.8,1.0,.85,.45][index];sun.light_color=[Color("f2caa0"),Color("fff3dd"),Color("efab80"),Color("90b3e0")][index]
	if is_instance_valid(particles):particles.queue_free()
	particles=MultiMeshInstance3D.new();particles.multimesh=MultiMesh.new();particles.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	var mesh:=BoxMesh.new();mesh.size=Vector3(.015,.55,.015) if weather=="RAIN" else Vector3(.065,.065,.065)
	particles.multimesh.mesh=mesh;particles.multimesh.instance_count=160 if weather=="RAIN" else 96
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color("a8c4d5") if weather=="RAIN" else Color("d8dce0") if weather=="SNOW" else Color("c6aa78") if weather=="SANDSTORM" else Color("8f8278")
	particles.material_override=mat;particles.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visible=weather in ["RAIN","SNOW","ASH STORM","SANDSTORM"]
	add_child(particles)
func _process(delta: float) -> void:
	if not is_instance_valid(particles) or not particles.visible or not is_instance_valid(camera_ref):return
	phase+=delta
	var rain: bool=conditions["weather"]=="RAIN"
	for i in range(particles.multimesh.instance_count):
		var p:=Vector3(fposmod(i*13.73+phase*(.3 if rain else 2.0),34)-17,fposmod(i*4.31-phase*(16 if rain else 2.2),18)-2,fposmod(i*8.93+phase*.8,34)-17)
		particles.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,p+camera_ref.global_position))
