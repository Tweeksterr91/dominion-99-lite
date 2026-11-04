extends SceneTree
var g
func _initialize() -> void:call_deferred("verify")
func button(id: int,pressed: bool) -> void:
 var e:=InputEventJoypadButton.new();e.device=99;e.button_index=id;e.pressed=pressed;g._input(e)
func axis(id: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=id;e.axis_value=value;g._input(e)
func verify() -> void:
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 g.set_physics_process(false);g.pad_input.set_physics_process(false)
 for dimensions in [Vector2i(540,1206),Vector2i(1206,540)]:
  root.size=dimensions
  for i in range(4):await process_frame
  for screen in ["title","main"]:
   g._show(screen)
   for child in g.hud_ui.overlay.get_children():assert(not child is TextureRect,"Start and main menus have no gradient scrim")
 g._start_match(1,0,99,[0]);g.set_physics_process(false)
 while not g.course.nav_ready:await physics_frame
 g.prelude_left=0;g._show("play")
 var p: Dictionary=g.rules.players[0]
 assert(p["owned"]==["pump","scythe"] and p["reserve"]==-1)
 assert(g.Rules.ROUND_COUNT==3 and g.Rules.COLLECTION_TIME==82.5 and g.Rules.SHOP_TIME==30 and g.Rules.HUNT_TIME==82.5 and g.Rules.REVEAL_TIME==3)
 for i in range(25):
  p["ammo"]=1;p["fire_cd"]=0;g._fire_weapon(0)
  assert(p["ammo"]==0 and p["reload"]>0 and p["reserve"]==-1)
  g._complete_reload(0);assert(p["ammo"]==5 and p["reserve"]==-1)
 assert(not g._switch_weapon(0,"needle"),"Unowned weapon cannot be equipped")
 g.rules.phase=g.Rules.Phase.SHOP;p["souls"]=1000
 for key in ["double","pulse","needle","scatter"]:g._purchase(0,key)
 assert(p["owned"].size()==6 and p["inventory"].size()==6,"All acquired weapons remain available together")
 g.rules.phase=g.Rules.Phase.COLLECTION
 g._switch_weapon(0,"pulse");p["ammo"]=7;p["reserve"]=41
 g._switch_weapon(0,"needle");p["ammo"]=11;p["reserve"]=26
 g._switch_weapon(0,"pulse");assert(p["ammo"]==7 and p["reserve"]==41)
 g._try_reload(0,true);assert(p["reload"]>0)
 g._switch_weapon(0,"needle");g._switch_weapon(0,"pulse")
 assert(p["ammo"]==7 and p["reserve"]==41 and p["reload"]==0,"Reload cancellation/switching cannot duplicate ammunition")
 g._switch_weapon(0,"pump");g.Inventory.add_reserve(p,24);assert(p["inventory"]["needle"]["reserve"]==50);assert(p["reserve"]==-1,"Pickups cannot replace infinite reserve with finite ammo")
 button(JOY_BUTTON_LEFT_SHOULDER,true)
 assert(g._wheel_open() and g.pad_input.wheel_open,"LB opens the wheel instead of jumping")
 var ammo: int=p["ammo"];g._fire_weapon(0);assert(p["ammo"]==ammo,"No firing through the open wheel")
 axis(JOY_AXIS_RIGHT_X,.866);axis(JOY_AXIS_RIGHT_Y,-.5);g.pad_input.step(.04)
 assert(g.hud_ui.wheel.selected=="scythe")
 button(JOY_BUTTON_LEFT_SHOULDER,false)
 assert(not g._wheel_open() and p["weapon"]=="scythe" and p["ammo"]==1)
 axis(JOY_AXIS_RIGHT_X,0);axis(JOY_AXIS_RIGHT_Y,0)
 g._tick_viewmodel(.016);assert(g.scythe_rig.visible and not g.double_rig.visible)
 assert(g.scythe_rig.get_meta("plasma_team")==0)
 g.rules.players[0]["team"]=1;g._equip_viewmodel();assert(g.scythe_rig.get_meta("plasma_team")==1)
 g.rules.players[0]["team"]=0;g._equip_viewmodel()
 for body in g.entities.values():body.position=Vector3(100,0,100)
 g.player.position=Vector3(0,.05,8);g.rails[0].aim_yaw=0;g.rails[0].pitch=0;g.player.rotation.y=0;g.camera.rotation=Vector3.ZERO
 var target
 for body in g.entities.values():
  if body.get_meta("subtype","")=="scavenger":target=body;break
 target.position=Vector3(0,0,5.7);target.set_meta("hp",65.0)
 await physics_frame;await physics_frame
 p["fire_cd"]=0;g._fire_weapon(0)
 assert(p["ammo"]==1 and p["reserve"]==-1 and p["reload"]==0 and p["minions"]==1,"Plasma scythe hits nearby minions with unlimited use")
 assert(g.projectiles.bullets.size()<=g.Projectiles.LIMIT)
 var enemy=g.entities[1];enemy.position=Vector3(0,0,5.7);g.rules.players[1]["invul"]=0
 var total: float=g.rules.players[1]["hp"]+g.rules.players[1]["shield"]
 p["fire_cd"]=0;g._fire_weapon(0);assert(g.rules.players[1]["hp"]+g.rules.players[1]["shield"]==total,"Melee respects collection protection")
 g.rules.phase=g.Rules.Phase.HUNT;p["fire_cd"]=0;g._fire_weapon(0)
 assert(g.rules.players[1]["hp"]+g.rules.players[1]["shield"]==total-75,"Melee damages opposing players in hunting")
 var wall:=StaticBody3D.new();wall.collision_layer=1;wall.position=Vector3(0,1.25,6.9);g.add_child(wall)
 var collider:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(4,3,.2);collider.shape=box;wall.add_child(collider)
 await physics_frame;await physics_frame
 total=g.rules.players[1]["hp"]+g.rules.players[1]["shield"];p["fire_cd"]=0;g._fire_weapon(0)
 assert(g.rules.players[1]["hp"]+g.rules.players[1]["shield"]==total,"A wall blocks the melee arc")
 wall.queue_free();await physics_frame;await physics_frame
 enemy.position=Vector3(100,0,100);g.rules.phase=g.Rules.Phase.COLLECTION
 g._switch_weapon(0,"double");assert(p["ammo"]==2 and p["reserve"]==-1)
 p["fire_cd"]=0;g.projectiles.clear();g._fire_weapon(0)
 assert(p["ammo"]==1 and g.projectiles.bullets.size()==10 and g.double_rig.visible,"Sawed-off upgrade uses its own model and ten-pellet blasts")
 # Touch wheel selection uses its own held finger and never enables auto-fire.
 g.pad_input.set_active(false)
 for i in range(4):await process_frame
 var point: Vector2=g.hud_ui.wheel_button.get_global_rect().get_center()
 var press:=InputEventScreenTouch.new();press.index=21;press.position=point;press.pressed=true;g._input(press)
 assert(g._wheel_open())
 var drag:=InputEventScreenDrag.new();drag.index=21;drag.position=root.get_visible_rect().size*.5+Vector2.UP*120;g._input(drag)
 press.pressed=false;g._input(press)
 assert(p["weapon"]=="pump" and not g._wheel_open() and not g.touch_auto)
 # A held lock keeps the same target through crossing, obstruction or target death.
 g._switch_weapon(0,"pump");g.lock_states.clear()
 var first=g._create_entity(994,"minion",0,-1,"brute");first.position=Vector3(0,0,3)
 var second=g._create_entity(995,"minion",0,-1,"brute");second.position=Vector3(1,0,3)
 g.rails[0].pitch=atan2(-.9,5);g.camera.rotation.x=g.rails[0].pitch
 await physics_frame;await physics_frame
 for i in range(48):g._set_lock_input(0,true);g._tick_locks(1.0/60)
 assert(g.lock_states[0]["target"]==994)
 first.position=Vector3(0,0,40);second.position=Vector3(0,0,3)
 await physics_frame
 for i in range(20):g._set_lock_input(0,true);g._tick_locks(1.0/60)
 assert(g.lock_states[0]["target"]==994 and g._lock_progress(0)==0,"Lost target cannot switch to a different enemy while LT stays held")
 g._set_lock_input(0,false);g._set_lock_input(0,true);g._tick_locks(.016)
 assert(g.lock_states[0]["target"]==995,"Release and re-press acquires a new target")
 g._close_wheel(false);g._set_lock_input(0,false)
 g.rules.players[1]["fire_cd"]=0;g.rules.players[1]["ammo"]=5;g._fire_weapon(1,g.player.position+Vector3.UP)
 assert(g.rules.players[1]["fire_cd"]>=1.16,"Bot shooting cadence is slower than the player interval")
 g.rules.phase=g.Rules.Phase.HUNT;g.rules.advance();g._handle_phase_change()
 assert(g.rules.round_index==2 and p["owned"].size()==6 and p["inventory"].size()==6,"Weapon ownership persists to the next round")
 g.pad_input.bind("wheel",JOY_BUTTON_X);g._save_settings();g._load_controller_settings()
 assert(g.pad_input.bindings["wheel"]==JOY_BUTTON_X,"Weapon-wheel remapping persists")
 button(JOY_BUTTON_LEFT_SHOULDER,true);assert(g._wheel_open());button(JOY_BUTTON_LEFT_SHOULDER,false);assert(not g._wheel_open(),"LB fallback releases after wheel remapping")
 print("PASS: three half-length rounds, clear start screens, infinite pump/scythe, all-weapon inventory/ammo persistence, reload cancellation, LB wheel/release, team-colored melee, double-barrel upgrade, sticky lock target")
 g._quit_game()
