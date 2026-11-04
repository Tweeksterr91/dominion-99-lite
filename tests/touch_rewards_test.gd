extends SceneTree
var g
func _initialize() -> void:call_deferred("verify")
func axis(id: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=id;e.axis_value=value;g._input(e);g.pad_input.step(.04)
func touch(index: int,point: Vector2,pressed: bool) -> void:
 var e:=InputEventScreenTouch.new();e.index=index;e.position=point;e.pressed=pressed;g._input(e)
func verify() -> void:
 root.size=Vector2i(540,1206)
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 g._start_match(1,0,99,[0]);g.set_physics_process(false);g.pad_input.set_physics_process(false)
 while not g.course.nav_ready:await physics_frame
 g.prelude_left=0;g._show("play");g.camera_motion=false
 for i in range(4):await process_frame
 for body in g.entities.values():body.position=Vector3(100,0,100)
 var m=g.rails[0];var p: Dictionary=g.rules.players[0]
 g.player.position=Vector3(0,.05,8);m.aim_yaw=0;m.pitch=atan2(-.95,5);g.player.rotation.y=0;g.camera.rotation=Vector3(m.pitch,0,0)
 var target
 for body in g.entities.values():
  if body.get_meta("subtype","")=="scavenger":target=body;break
 target.position=Vector3(0,0,3);target.set_meta("hp",10000.0)
 await physics_frame;await physics_frame
 p["ammo"]=5;p["fire_cd"]=0
 g._tick_auto_combat(.016);assert(p["ammo"]==5,"Idle and mouse/controller play never auto-fire")
 axis(JOY_AXIS_RIGHT_X,.8);axis(JOY_AXIS_RIGHT_X,0)
 m.aim_yaw=0;m.pitch=atan2(-.95,5);g.player.rotation.y=0;g.camera.rotation=Vector3(m.pitch,0,0)
 g._tick_auto_combat(.016);assert(p["ammo"]==5,"Controller aim without RT does not fire")
 axis(JOY_AXIS_TRIGGER_RIGHT,1);g._tick_auto_combat(.016);assert(p["ammo"]==4,"RT still fires manually")
 axis(JOY_AXIS_TRIGGER_RIGHT,0);p["fire_cd"]=0
 var center: Vector2=root.get_visible_rect().size*.5
 touch(11,center,true);assert(g.touch_auto and p["touch_auto_left"]>0)
 g._tick_auto_combat(.016);assert(p["ammo"]==3,"An actual touch in the aim area enables auto-fire")
 touch(11,center,false);p["fire_cd"]=0
 g._tick_auto_combat(.016);assert(p["ammo"]==3 and not g.touch_auto,"Lifting the aiming finger stops auto-fire")
 touch(12,g.hud_ui.stick.get_global_rect().get_center(),true)
 g._tick_auto_combat(.016);assert(p["ammo"]==3,"Touch movement alone cannot enable auto-fire")
 touch(12,g.hud_ui.stick.get_global_rect().get_center(),false)
 touch(13,center,true);axis(JOY_AXIS_RIGHT_X,.7);axis(JOY_AXIS_RIGHT_X,0)
 assert(not g.touch_auto and p["touch_auto_left"]==0,"Switching to a controller immediately cancels touch auto-fire")
 touch(13,center,false)
 g._apply_action(0,"autofire",true,1);g._tick_fighter_states(.6)
 assert(p["touch_auto_left"]==0,"Missing touch heartbeat times out on the authority")
 touch(14,center,true);g._notification(g.NOTIFICATION_APPLICATION_PAUSED)
 assert(not g.touch_auto and g.touch_aim==-1,"Backgrounding clears touch auto-fire and stale aiming finger")
 g._notification(g.NOTIFICATION_APPLICATION_RESUMED);g._show("play")
 g._update_audio()
 assert(is_equal_approx(db_to_linear(g.shot_sound.volume_db-(-5+linear_to_db(g.sound_volume))),.5),"Local shooting amplitude is halved")
 assert(is_equal_approx(db_to_linear(g.distant_shot.volume_db-(-20+linear_to_db(g.sound_volume))),.5),"Distant player/minion shooting amplitude is halved")
 assert(is_equal_approx(db_to_linear(g.pump_sound.volume_db-(-13+linear_to_db(g.sound_volume))),.5),"Pump cycle amplitude is halved")
 var refill: float=g.reload_lower_sound.volume_db
 assert(is_equal_approx(refill,-9+linear_to_db(g.sound_volume)),"Reload volume stays independent")
 assert(not g.pad_input.bindings.has("suction") and not "HARVEST" in g.pad_input.prompt())
 for size in [Vector2i(540,1206),Vector2i(1206,540)]:
  root.size=size
  for i in range(4):await process_frame
  g._tick_viewmodel(.016)
  assert(not g.hud_ui.essence.visible and not g.hand_root.visible and g.hand_root.get_child_count()==0)
 # A nonlethal first hit does not claim the reward; the killing shot determines ownership.
 g.cloud.clear();g.rules.players[0]["souls"]=0;g.rules.players[1]["souls"]=0
 target.set_meta("hp",65.0);g._damage_entity(target,10,1);assert(g.cloud.orbs.is_empty())
 g._damage_entity(target,100,0)
 assert(g.cloud.orbs.size()==3 and p["minions"]==1)
 for orb in g.cloud.orbs.values():assert(orb["owner"]==0 and orb["area"].collision_layer==0)
 g.cloud.pull(1,Vector3(0,1,3),100,g._collector_positions(),func(_a,_b):return true)
 for id in g.cloud.orbs:
  assert(g.cloud.orbs[id]["owner"]==0 and not g.cloud.destroy(id),"Claimed rewards cannot be stolen or denied")
 for i in range(90):g.cloud.tick(1.0/60,g._collector_positions(),true)
 assert(p["souls"]==15 and g.rules.players[1]["souls"]==0 and g.cloud.orbs.is_empty(),"Souls fly to the killer without a harvest input")
 g.entities[1].position=Vector3(2,0,4)
 var treasure=g._create_entity(999,"minion",0,-1,"treasure")
 g._damage_entity(treasure,1000,1)
 g.rules.players[1]["hp"]=0
 for i in range(400):g.cloud.tick(1.0/60,g._collector_positions(),true)
 assert(g.rules.players[1]["souls"]==90,"Gold rewards stay assigned even if the killer dies while orbs travel")
 var late=g._create_entity(998,"minion",0,-1,"scavenger");g._damage_entity(late,1000,0)
 g.rules.remaining=0;g.rules.advance();g._handle_phase_change()
 assert(p["souls"]==30 and g.cloud.orbs.is_empty(),"Pending killer rewards settle before the shop clears orbs")
 g._start_match(1,0,99,[0]);g.set_physics_process(false)
 while not g.course.nav_ready:await physics_frame
 g.prelude_left=0;g._show("play")
 var bot=g.entities[1];var initial: Vector3=bot.position;var max_speed:=0.0
 for i in range(150):
  await physics_frame;g._tick_fighter_states(1.0/60);g._tick_bots(1.0/60)
  if g.brains[1].jumping_left<=0:max_speed=maxf(max_speed,Vector2(bot.velocity.x,bot.velocity.z).length())
 assert(max_speed<=3.21 and max_speed>2 and bot.position.distance_to(initial)>1,"Rival bot genuinely moves at the slower 3.2 m/s speed")
 assert(g.MINION_SPEED_MULTIPLIER==.85)
 print("PASS: touch-aim-only auto-fire and controller/manual fire, release/hot-switch/timeout, half-volume shots, no harvesting UI/hand, killer-owned automatic blue/gold collection, no theft/denial, death/phase settlement, slower physical bot movement")
 g._quit_game()
