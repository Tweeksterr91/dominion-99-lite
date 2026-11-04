extends SceneTree
var g
func _initialize() -> void:call_deferred("verify")
func verify() -> void:
 root.size=Vector2i(1206,540)
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 g.set_physics_process(false);g.pad_input.set_physics_process(false)
 g._start_match(1,0,99,[0]);g.set_physics_process(false)
 while not g.course.nav_ready:await physics_frame
 g.prelude_left=0;g._show("play")
 var lens=g.lens
 lens.initialized=false;lens.step(.016,true)
 assert(lens.material.get_shader_parameter("motion_pixels")==Vector2.ZERO)
 g.camera.rotation.y+=.02;lens.step(.016,true)
 var blur: Vector2=lens.material.get_shader_parameter("motion_pixels")
 assert(blur.length()>0 and blur.length()<=2.201)
 lens.step(.016,true);assert(lens.material.get_shader_parameter("motion_pixels")==Vector2.ZERO,"Stationary camera has no motion smear")
 g.camera.rotation.y+=1;lens.step(.016,false)
 assert(lens.material.get_shader_parameter("motion_pixels")==Vector2.ZERO,"Paused camera has no blur")
 g.player.position+=Vector3.RIGHT*6;g.camera.rotation.y+=1;lens.step(.016,true)
 assert(lens.material.get_shader_parameter("motion_pixels")==Vector2.ZERO,"Respawns/cuts cannot smear across the screen")
 g.camera.rotation=Vector3.ZERO;g.player.position=Vector3(0,.1,8)
 var wall:=StaticBody3D.new();wall.collision_layer=1;wall.position=Vector3(0,1.8,-2);g.add_child(wall)
 var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(5,5,.2);shape.shape=box;wall.add_child(shape)
 await physics_frame;await physics_frame
 for i in range(90):lens.step(.016,true)
 assert(lens.focus_distance>8 and lens.focus_distance<11,"Focus follows the actual crosshair world obstruction")
 for dimensions in [Vector2i(540,1206),Vector2i(1206,540)]:
  root.size=dimensions
  for i in range(4):await process_frame
  g._show_visuals()
  var bounds:=root.get_visible_rect()
  var rects: Array=[]
  for b in g.hud_ui.buttons:
   if is_instance_valid(b) and b.is_visible_in_tree():
    var rect: Rect2=b.get_global_rect();assert(bounds.encloses(rect))
    for other in rects:assert(not rect.intersects(other),"Visual buttons do not overlap")
    rects.append(rect)
  assert(rects.size()==6)
  g.camera.rotation.y+=.03;lens.step(.016,true)
  assert(lens.material.get_shader_parameter("motion_pixels")==Vector2.ZERO,"Orientation change clears motion history")
  var timer: float=g.rules.remaining;g._physics_process(.2);assert(g.rules.remaining==timer,"Offline visual settings pause gameplay")
 for key in g.visual_effects:
  if g.visual_effects[key]:g._ui_action("visual_toggle",key)
 assert(not lens.surface.visible,"All effects off removes the entire post pass")
 g._save_settings();g.visual_effects={"bloom":true,"dof":true,"chromatic":true,"motion":true};g._load_settings()
 assert(not g.visual_effects.values().has(true) and not lens.surface.visible,"Independent effect switches survive save/reload")
 g._ui_action("visual_toggle","bloom");assert(lens.surface.visible and lens.effects["bloom"] and not lens.effects["dof"])
 g._ui_action("visual_motion",null);g._ui_action("visual_back",null);assert(g.screen=="options")
 g._show_visuals();g._controller_back();assert(g.screen=="options")
 for index in range(4):
  var value: Dictionary={"time":g.Weather.TIMES[index],"time_id":index,"weather":"CALM BEFORE STORM"}
  g.weather_node.apply(value,g.environment,g.sun,g.camera)
  assert(g.environment.fog_sky_affect<.3)
  assert(g.weather_node.city_sky.get_shader_parameter("night_amount")>0)
 var city=g.weather_node.city_sky;g.weather_node._process(.3)
 assert(city.get_shader_parameter("cloud_time")>.2,"Clouds drift independently of precipitation")
 assert(g.weapon_frame.view_camera.cull_mask==2 and lens.surface.layers==4 and g.hud_ui.layer==10)
 print("PASS: bounded camera blur and cut/rotation/pause resets, physical crosshair focus, independent saved switches, zero-pass off mode, responsive visual settings, offline pause, sky visibility and drifting clouds, isolated HUD/portrait weapon")
 g._quit_game()
