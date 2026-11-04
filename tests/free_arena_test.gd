extends SceneTree
var failed := false
var g
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error(message)
func _initialize() -> void:call_deferred("verify")
func wait_nav() -> void:
 var deadline:=Time.get_ticks_msec()+12000
 while not g.course.nav_ready and Time.get_ticks_msec()<deadline:await physics_frame
 for i in range(8):await physics_frame
 check(g.course.nav_ready,"Navigation bake and map synchronize")
func simulate(motion: RefCounted,frames: int,input: Vector2) -> void:
 for i in range(frames):
  await physics_frame
  motion.set_move(input);motion.step(g.player,g.course,1.0/60)
func verify() -> void:
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 g._start_match(1,0,99,[0]);g.set_physics_process(false);g.pad_input.set_physics_process(false)
 await wait_nav()
 check(g.screen=="conditions" and g.prelude_left==6 and g.rules.remaining==165,"Shared environment reveal precedes full collection timer")
 check(is_equal_approx(g.sound_volume,.7) and is_equal_approx(g.music_volume,.7),"Fresh effects and music default to 70 percent")
 check(g.rules.players[0]["weapon"]=="pump" and g.rules.players[0]["ammo"]==5,"Starting weapon is a five-shell pump shotgun")
 check(g.shotgun_rig.has_node("PumpSlide") and g.shotgun_rig.has_node("SupportArm"),"Pump and human arms are real separate model parts")
 check(g.conditions==g.Weather.roll(99,0),"Environment roll is deterministic from match seed")
 var times: Dictionary={};var weather: Dictionary={}
 for seed_value in range(64):
  var roll: Dictionary=g.Weather.roll(seed_value,3);times[roll["time"]]=true;weather[roll["weather"]]=true
 check(times.size()==4 and weather.has("RAIN") and weather.has("SNOW"),"Random rolls cover multiple times and biome weather")
 for i in range(365):g._physics_process(1.0/60)
 g.set_physics_process(false)
 check(g.prelude_left==0 and g.screen=="play" and g.rules.remaining>164,"Reveal does not consume collection time")
 var map=g.get_world_3d().navigation_map
 for target in [Vector3(0,4,23),Vector3(35,4,0),Vector3(35,8,-8),Vector3(22,5,22)]:
  var path=NavigationServer3D.map_get_path(map,Vector3.ZERO,target,true)
  check(not path.is_empty() and path[path.size()-1].distance_to(target)<1.5,"Navigation reaches ring, side rotunda, upper balcony and jump island: "+str(target))
 g.prelude_left=0;g._show("play")
 var motion=g.rails[0]
 g.player.position=Vector3(0,.08,0);motion.aim_yaw=0;motion.set_move(Vector2.ZERO)
 await simulate(motion,60,Vector2.ZERO)
 var resting: Vector3=g.player.position
 await simulate(motion,30,Vector2.ZERO)
 check(g.player.position.distance_to(resting)<.02,"No automatic running when input is released")
 await simulate(motion,45,Vector2.RIGHT)
 check(g.player.position.x>2 and absf(g.player.position.z)<.1,"Strafing is independent of facing")
 motion.set_move(Vector2.ZERO)
 for i in range(30):await physics_frame;motion.step(g.player,g.course,1.0/60)
 check(Vector2(g.player.velocity.x,g.player.velocity.z).length()<.01,"Releasing the stick stops movement")
 motion.aim_yaw=0;g._look(Vector2(1.5,0))
 check(absf(motion.aim_yaw)>1.1 and absf(g.camera.rotation.y)<.01,"Free look turns beyond the old rail aiming clamp")
 # Walk a real ramp from the low circle onto the raised ring without jumping.
 g.player.position=Vector3(0,.05,11);g.player.velocity=Vector3.ZERO;motion.aim_yaw=PI;motion.jumps=0
 for i in range(180):
  await physics_frame;motion.set_move(Vector2(0,-1));motion.step(g.player,g.course,1.0/60)
  if g.player.position.z>22 and g.player.position.y>3.8:break
 print("Ramp endpoint: ",g.player.position," jumps ",motion.jumps)
 check(g.player.position.y>3.8 and g.player.position.z>22 and motion.jumps==0,"Ramps replace compulsory jump gaps")
 # A low railing stops ordinary walking but can be jumped over into a genuine fall.
 var direction:=Vector3(cos(PI/8),0,sin(PI/8))
 g.player.position=direction*24.3+Vector3.UP*4.05;g.player.velocity=Vector3.ZERO;motion.aim_yaw=atan2(-direction.x,-direction.z)
 await simulate(motion,60,Vector2(0,-1))
 check(Vector2(g.player.position.x,g.player.position.z).length()<26.1,"Low railing blocks walking off the ring")
 motion.jump(g.player)
 await simulate(motion,55,Vector2(0,-1))
 check(Vector2(g.player.position.x,g.player.position.z).length()>26.5,"Player can jump over the railing")
 var lives: int=g.rules.players[0]["lives"]
 for i in range(180):
  await physics_frame;motion.set_move(Vector2(0,-1));g._tick_human_motion(1.0/60)
  if not g._alive(0):break
 check(g.rules.players[0]["lives"]==lives-1,"Falling off an actual platform consumes a life")
 g._tick_fighter_states(3.1)
 check(g._alive(0) and motion.move_input==Vector2.ZERO,"Respawn does not restart automatic movement")
 # Shotgun pellets travel through the world and damage only when they collide.
 for body in g.entities.values():body.position=Vector3(100,0,100)
 g.player.position=Vector3(0,.05,8);g.player.rotation=Vector3.ZERO;motion.aim_yaw=0
 var minion
 for body in g.entities.values():
  if body.get_meta("subtype","")=="scavenger":minion=body;break
 minion.position=Vector3(0,0,3);minion.velocity=Vector3.ZERO
 g.camera.rotation=Vector3.ZERO;g.camera.look_at(minion.position+Vector3.UP*.8)
 await physics_frame;await physics_frame
 var p: Dictionary=g.rules.players[0]
 p["ammo"]=5;p["fire_cd"]=0;p["invul"]=0
 g.projectiles.clear();g._fire_weapon(0)
 check(p["ammo"]==4 and g.projectiles.bullets.size()==7,"One shell emits seven physical pellets")
 check(minion.get_meta("hp")==65,"Projectile launch never applies instant hitscan damage")
 for i in range(9):g.projectiles.tick(1.0/60,true)
 check(p["minions"]==1 and g.cloud.orbs.size()==3,"Moving pellets collide, kill once, and release essence once")
 check(g.pump_age==0 and g.shot_sound.stream.resource_path.ends_with("shotgun_shot.wav"),"Shotgun firing uses dedicated sound and pump presentation")
 g._tick_viewmodel(.25)
 check(g.shotgun_rig.get_node("PumpSlide").position.z>.01 and g.pump_sound.playing,"Pump slide and supporting hand cycle after firing")
 # A minion also creates a visible projectile, then causes damage on impact.
 var caster
 for body in g.entities.values():
  if body.get_meta("role")=="minion":caster=body;break
 caster.position=Vector3(0,0,4);caster.rotation.y=PI;caster.set_meta("attack",0)
 g.projectiles.clear();g._minion_fire(caster,g.player,.016)
 check(g.projectiles.bullets.size()==1,"Minion attacks are visible moving projectiles too")
 var before: float=p["hp"]+p["shield"]
 for i in range(30):g.projectiles.tick(1.0/60,true)
 check(p["hp"]+p["shield"]<before,"Enemy projectiles hit through collision physics")
 # Player/player protection still holds during collection.
 var enemy=g.entities[1];enemy.position=Vector3(0,0,4);g.rules.players[1]["ammo"]=5;g.rules.players[1]["fire_cd"]=0
 g.projectiles.clear();g._fire_weapon(1,g.player.position+Vector3.UP*1.5)
 before=p["hp"]+p["shield"]
 for i in range(30):g.projectiles.tick(1.0/60,true)
 check(p["hp"]+p["shield"]==before,"Player projectiles preserve collection protection")
 g.cloud.clear();var gold: int=g.cloud.spawn(Vector3(0,1,2),15,-1,true)
 await physics_frame;await physics_frame
 g.projectiles.clear();g.projectiles.spawn(Vector3(0,1,4),Vector3(0,0,-30),0,15,64,Color.WHITE,g.player.get_rid(),1)
 g.projectiles.tick(.1,true)
 check(g.cloud.orbs.has(gold),"Gold souls survive projectile impacts")
 # Independent bodies use navmesh steering with collision, not hallway interpolation.
 g._start_match(1,0,99,[0]);g.prelude_left=0;g._show("play");await wait_nav()
 var bot=g.entities[1];var initial: Vector3=bot.position
 for i in range(150):
  await physics_frame;g._tick_fighter_states(1.0/60);g._tick_bots(1.0/60);g.projectiles.tick(1.0/60,true)
 check(bot.position.distance_to(initial)>1 and bot.collision_mask==1 and g.brains.has(1),"Bot navigates freely using real body collisions")
 # Touch movement and HUD fit in both orientations.
 for dimensions in [Vector2i(540,960),Vector2i(540,1206),Vector2i(1206,540),Vector2i(1280,800)]:
  root.size=dimensions
  for i in range(5):await process_frame
  g.hud_ui._relayout();g._show("play")
  var bounds:=Rect2(Vector2.ZERO,root.get_visible_rect().size)
  for control in [g.hud_ui.stick,g.hud_ui.jump,g.hud_ui.essence,g.hud_ui.lock_button]:check(bounds.encloses(control.get_global_rect()),"Free touch controls fit "+str(dimensions))
  check(not g.hud_ui.routes["ahead"].visible and not g.hud_ui.down.visible,"Rail arrows and down-route button are removed")
  check(g.hud_ui.reticle.get_global_rect().get_center().distance_to(bounds.get_center())<1,"Aim stays centered")
 print("FAIL" if failed else "PASS: environment roll, 70% mix, free movement/strafe/stop/look, connected navigation and ramps, jumpable railings/falls, shotgun/arms/pump, real projectile damage/protection, free bots, responsive touch")
 g._quit_game(1 if failed else 0)
