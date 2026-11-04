extends Node3D
const TIMES := ["DARK SUNSET","STORM FRONT","OVERCAST DUSK","NIGHT"]
const WEATHERS := [["OVERCAST","RAIN","FOG","CALM BEFORE STORM"],["OVERCAST","FOG","CALM BEFORE STORM"],["OVERCAST","ASH STORM","FOG"],["OVERCAST","RAIN","FOG","SNOW"],["OVERCAST","SANDSTORM","CALM BEFORE STORM"]]
var conditions: Dictionary={}
var particles: MultiMeshInstance3D
var phase := 0.0
var city_sky: ShaderMaterial
var cloud_tick := 0.0
var camera_ref: Camera3D
static func roll(seed_value: int,biome: int) -> Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value+990819
	var time_id:=rng.randi_range(0,3)
	return {"time":TIMES[time_id],"time_id":time_id,"weather":WEATHERS[biome][rng.randi_range(0,WEATHERS[biome].size()-1)]}
func apply(value: Dictionary,environment: Environment,sun: DirectionalLight3D,camera: Camera3D) -> void:
	conditions=value;camera_ref=camera
	var index: int=value["time_id"];var weather: String=value["weather"]
	var sky:=ProceduralSkyMaterial.new()
	sky.sky_top_color=[Color("211e32"),Color("172331"),Color("252b3b"),Color("070d1c")][index]
	sky.sky_horizon_color=[Color("684650"),Color("354452"),Color("4b505c"),Color("202c41")][index]
	if weather!="CLEAR":sky.sky_top_color=sky.sky_top_color.lerp(Color("283341"),.25);sky.sky_horizon_color=sky.sky_horizon_color.lerp(Color("3d4656"),.20)
	sky.ground_bottom_color=Color("20262c");sky.ground_horizon_color=sky.sky_horizon_color.darkened(.25)
	var city:=ShaderMaterial.new();city.shader=preload("res://assets/city_sky.gdshader");city.set_shader_parameter("zenith",sky.sky_top_color);city.set_shader_parameter("horizon",sky.sky_horizon_color)
	city_sky=city;phase=0;cloud_tick=0
	city.set_shader_parameter("night_amount",[.22,.45,.30,1.0][index])
	city.set_shader_parameter("cloud_cover",.90 if weather in ["OVERCAST","RAIN","SNOW","ASH STORM"] else .76 if weather in ["FOG","SANDSTORM"] else .52)
	var sky_resource:=Sky.new();sky_resource.process_mode=Sky.PROCESS_MODE_INCREMENTAL;sky_resource.sky_material=city;sky_resource.radiance_size=Sky.RADIANCE_SIZE_128
	environment.sky=sky_resource;environment.background_mode=Environment.BG_SKY;environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("b9c9da");environment.ambient_light_energy=.48 if index!=3 else .34
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.fog_enabled=true;environment.fog_light_color=sky.sky_horizon_color;environment.fog_sky_affect=.16
	environment.fog_density=.018 if weather=="FOG" else .011 if weather in ["SANDSTORM","ASH STORM"] else .0025
	sun.rotation_degrees=Vector3([-9,-12,-10,-28][index],[-70,-25,100,35][index],0)
	sun.light_energy=[.48,.32,.38,.25][index];sun.light_color=[Color("f2caa0"),Color("fff3dd"),Color("efab80"),Color("90b3e0")][index]
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
	phase+=delta;cloud_tick+=delta
	if cloud_tick>=.25 and is_instance_valid(city_sky):
		city_sky.set_shader_parameter("cloud_time",phase);cloud_tick=0
	if not is_instance_valid(particles) or not particles.visible or not is_instance_valid(camera_ref):return
	var rain: bool=conditions["weather"]=="RAIN"
	for i in range(particles.multimesh.instance_count):
		var p:=Vector3(fposmod(i*13.73+phase*(.3 if rain else 2.0),34)-17,fposmod(i*4.31-phase*(16 if rain else 2.2),18)-2,fposmod(i*8.93+phase*.8,34)-17)
		particles.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,p+camera_ref.global_position))
