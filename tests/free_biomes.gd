extends SceneTree
var failed:=false
func _initialize() -> void:call_deferred("verify")
func check(ok: bool,detail: String) -> void:
 if not ok:failed=true;push_error(detail)
func verify() -> void:
 var g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 g.set_physics_process(false);g.pad_input.set_physics_process(false)
 for biome in range(5):
  g._start_match(4,biome,800+biome,[0]);g.set_physics_process(false)
  var until:=Time.get_ticks_msec()+15000
  while not g.course.nav_ready and Time.get_ticks_msec()<until:await physics_frame
  for i in range(10):await physics_frame
  check(g.course.nav_ready,"Biome navigation ready")
  var map=g.get_world_3d().navigation_map
  var radius: float=g.course.ring_radius
  for target in [Vector3(0,4,radius),Vector3(radius+12,8,-8)]:
   var path=NavigationServer3D.map_get_path(map,Vector3.ZERO,target,true)
   check(not path.is_empty() and path[path.size()-1].distance_to(target)<1,"Every biome has connected raised routes")
  check(g.course.ramps.size()>=8 and g.course.jump_links.size()==4,"Every biome has ramps and optional jump islands")
  check(g.rules.players.size()==8 and g.entities.size()==13,"4v4 roster and minions build")
  var recorded: Dictionary=g.conditions.duplicate()
  g.prelude_left=0;g._show("play")
  for i in range(30):
   await physics_frame;g._tick_human_motion(1.0/60);g._tick_bots(1.0/60);g.projectiles.tick(1.0/60,true)
  check(g.conditions==recorded,"Weather and time stay fixed for the match")
  print("PASS biome ",biome,": ",recorded)
 print("FAIL" if failed else "PASS: all five free arenas, ramps/navigation/verticality, optional platforms, 4v4 bodies and deterministic environmental conditions")
 g._quit_game(1 if failed else 0)
