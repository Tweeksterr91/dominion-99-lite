extends SceneTree
var g
var failed:=false
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 if not value:failed=true;push_error(message)
func axis(id: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=id;e.axis_value=value;g._input(e);g.pad_input.step(.04)
func run() -> void:
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 g._start_match(1,0,99,[0]);g.set_physics_process(false);g.pad_input.set_physics_process(false)
 while not g.course.nav_ready:await physics_frame
 g.prelude_left=0;g._show("play")
 for body in g.entities.values():body.position=Vector3(100,0,100)
 var m=g.rails[0];var p: Dictionary=g.rules.players[0]
 g.player.position=Vector3(0,.05,8);m.aim_yaw=0;m.pitch=atan2(-.95,5);g.player.rotation.y=0;g.camera.rotation=Vector3(m.pitch,0,0)
 var minion
 for body in g.entities.values():
  if body.get_meta("subtype","")=="scavenger":minion=body;break
 minion.position=Vector3(0,0,3);minion.set_meta("hp",9999.0)
 await physics_frame;await physics_frame
 p["ammo"]=5;p["fire_cd"]=0;p["invul"]=0
 var yaw: float=m.aim_yaw
 axis(JOY_AXIS_TRIGGER_LEFT,1)
 check(g.lock_states[0]["ttl"]>0 and m.aim_yaw==yaw,"LT starts locking without a 180-degree turn")
 check(not g.pad_input.bindings.has("reverse") and g.pad_input.bindings.has("lock"),"Instant reversal removed from active bindings")
 for i in range(40):
  if i%10==0:g.pad_input.step(.18)
  g._tick_locks(1.0/60);g._tick_auto_combat(1.0/60)
 check(p["ammo"]==5 and not g._can_shoot(0) and g._lock_progress(0)>.8,"Acquisition blocks both manual and automatic shooting before green")
 check(g._lock_rect().has_area(),"Amber target bracket rectangle projects from actual target")
 for i in range(5):g.pad_input.step(.04);g._tick_locks(1.0/60)
 check(g._lock_progress(0)==1 and g._can_shoot(0),"Green acquisition ring enables firing")
 g._fire_weapon(0);check(p["ammo"]==4,"Charged lock can shoot")
 axis(JOY_AXIS_TRIGGER_LEFT,0);p["fire_cd"]=0
 check(g.lock_states[0]["ttl"]==0 and g._can_shoot(0),"Releasing LT immediately restores ordinary shooting")
 g._request_action("reverse");check(absf(angle_difference(yaw,m.aim_yaw))<.1,"Old reverse action does nothing")
 p["ammo"]=1;p["reserve"]=10;p["fire_cd"]=0
 g._fire_weapon(0)
 check(p["ammo"]==0 and p["reload"]>0 and not p["reload_used"],"Final shell immediately starts automatic reload without consuming active attempt")
 p["reload"]=p["reload_total"]*.35;g._try_reload(0,true)
 check(p["reload"]==0 and p["ammo"]==5 and p["reserve"]==5 and p["reload_flash"]>0,"Active reload stays available during automatic reload and conserves ammunition")
 axis(JOY_AXIS_TRIGGER_LEFT,1);g._tick_locks(.05)
 minion.position=Vector3(0,0,40)
 await physics_frame;g._tick_locks(.016)
 check(g.lock_states[0]["target"]==-1 and g._lock_progress(0)==0 and not g._can_shoot(0),"Losing target resets charge and prevents firing while LT stays held")
 axis(JOY_AXIS_TRIGGER_LEFT,0)
 minion.position=Vector3(0,0,3)
 var bot=g.entities[1];bot.position=Vector3(0,0,-5);g.enemy_motions[1].aim_yaw=0;bot.rotation.y=0
 g.rules.players[1]["fire_cd"]=0;g.rules.players[1]["ammo"]=5
 await physics_frame;g._tick_bots(1.0/60)
 check(absf(g.enemy_motions[1].aim_yaw)<=deg_to_rad(90)/60+.001,"Enemy bots turn at a bounded 90 degrees per second")
 check(g.rules.players[1]["ammo"]==5,"A bot cannot shoot backward while it is turning")
 for size in [Vector2i(540,1206),Vector2i(1206,540)]:
  root.size=size
  for i in range(4):await process_frame
  g._tick_viewmodel(.016)
  var x: float=g.gun.position.x
  for i in range(30):g._tick_viewmodel(.016)
  check(g.gun.position.x==x,"Viewmodel position never drifts")
  check(is_equal_approx(g.gun.scale.x,.88),"Both orientations retain the same natural weapon pose")
  check(not g.hud_ui.reverse.visible,"No 180 button in either orientation")
 # Compare actual visual and collider corners for rotated rail/ramp boxes.
 var fixture=load("res://scripts/free_map.gd").new();var holder:=Node3D.new();g.add_child(holder)
 for rotation in [Vector3(0,.72,0),Vector3(-.45,0,0)]:
  fixture.geometry_batches.clear()
  var size:=Vector3(.12,.16,6);var basis:=Basis.from_euler(rotation)
  fixture._box(holder,Vector3(4,2,0),size,0,true,basis)
  var rendered: Transform3D=fixture.geometry_batches.values()[0]["transforms"][0]
  var body: StaticBody3D=holder.get_child(holder.get_child_count()-1)
  var shape: CollisionShape3D=body.get_child(0)
  for x in [-.5,.5]:
   for y in [-.5,.5]:
    for z in [-.5,.5]:
     var corner:=Vector3(x,y,z)
     check((rendered*corner).distance_to(shape.global_transform*(corner*shape.shape.size))<.001,"Rotated ramp/rail rendered corners match collision corners")
 holder.queue_free()
 for seed_value in range(256):
  for biome in range(5):
   var roll: Dictionary=g.Weather.roll(seed_value,biome)
   check(not "DAY " in roll["time"] and roll["weather"]!="CLEAR","Every environment roll excludes sunny daytime")
 g._show("play");g._render_hud(.016)
 axis(JOY_AXIS_TRIGGER_LEFT,1);g._tick_locks(.1);g._pause()
 check(g.lock_states[0]["ttl"]==0,"Pausing releases lock input")
 print("FAIL" if failed else "PASS: optional LT charge/gating/tracking/release/loss, projected brackets, no instant reversal, final-shell auto/active reload, slow bot turning and facing, compact stable portrait viewmodel, dark-only environment")
 g._quit_game(1 if failed else 0)
