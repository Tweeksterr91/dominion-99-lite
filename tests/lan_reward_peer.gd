extends SceneTree
var g
var host:=false
var started:=0
var deadline:=0
var configured:=false
var pressed:=false
var released:=false
var fired:=false
var claimed:=false
var touch_seen:=false
var ready_sent:=false
func _initialize() -> void:call_deferred("run")
func axis(id: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=id;e.axis_value=value;g._input(e)
func aim_touch(pressed_value: bool) -> void:
 var e:=InputEventScreenTouch.new();e.index=17;e.position=root.get_visible_rect().size*.5;e.pressed=pressed_value;g._input(e)
func run() -> void:
 host="host" in OS.get_cmdline_user_args();root.size=Vector2i(1206,540) if host else Vector2i(540,1206)
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 deadline=Time.get_ticks_msec()+28000
 g.net.launch.connect(func(_config):started=Time.get_ticks_msec())
 g.net.action_received.connect(func(_id,kind,value,_sequence):
  if kind=="autofire" and value==true:touch_seen=true)
 if host:assert(g.net.host(1,0,27839)==OK)
 else:assert(g.net.join_room("127.0.0.1",27839)==OK)
func _process(_delta: float) -> bool:
 if g==null or g.quitting:return false
 if Time.get_ticks_msec()>deadline:push_error("LAN touch/reward test timeout");quit(1);return false
 if not g.net.in_match:
  if host and g.net.can_start():g.net.start_match(99)
  elif not host and g.net.human_slots.size()==2 and not ready_sent:g.net.set_ready();ready_sent=true
  return false
 var elapsed: float=(Time.get_ticks_msec()-started)/1000.0
 if host:
  if elapsed>6.3 and not configured:
   g.brains.clear();g.minion_spawn_left=999;g.treasure_spawn_left=999
   for body in g.entities.values():body.position=Vector3(100,0,100)
   g.player.position=Vector3(.5,.05,3)
   g.entities[1].position=Vector3(0,.05,8);g.rails[1].aim_yaw=0;g.rails[1].pitch=atan2(-.95,5)
   var minion=g.entities[100];minion.position=Vector3(0,0,3);minion.set_meta("hp",10000.0)
   configured=true
  if elapsed>7.1 and elapsed<7.35:assert(g.rules.players[1]["ammo"]==5,"Controller aiming alone cannot auto-fire on the host")
  if elapsed>8.8 and g.entities.has(100):g.entities[100].set_meta("hp",15.0)
  for orb in g.cloud.orbs.values():
   if orb["owner"]==1:claimed=true
   assert(orb["owner"]==1,"Reward belongs to the killing guest despite closer host")
  if elapsed>12:
   assert(touch_seen and claimed and g.rules.players[1]["souls"]==15 and g.rules.players[0]["souls"]==0)
   assert(g.rules.players[1]["touch_auto_left"]==0 and g.cloud.orbs.is_empty())
   print("PASS: LAN reward host: controller aim does not shoot, touch auto-fire is validated, manual RT kill gets claimed blue orbs, closer rival gets no reward, currency and release synchronize")
   g._quit_game()
 else:
  if elapsed>6.8 and not configured:
   axis(JOY_AXIS_RIGHT_X,.7);g.pad_input.step(.04);axis(JOY_AXIS_RIGHT_X,0)
   g.rails[1].aim_yaw=0;g.rails[1].pitch=atan2(-.95,5);g.player.rotation.y=0;g.camera.rotation=Vector3(g.rails[1].pitch,0,0);configured=true
  if elapsed>7.4 and not pressed:aim_touch(true);pressed=true
  if elapsed>8.3 and not released:
   assert(g.rules.players[1]["ammo"]<5,"Touch aiming auto-fires without RT")
   aim_touch(false);released=true
  for orb in g.cloud.orbs.values():
   claimed=claimed or orb["owner"]==1
   assert(orb["area"].collision_layer==0,"Clients cannot shoot claimed orbs")
  if elapsed>9.5 and not fired:axis(JOY_AXIS_TRIGGER_RIGHT,1);fired=true
  if elapsed>10.5:axis(JOY_AXIS_TRIGGER_RIGHT,0)
  if elapsed>11.6:
   assert(claimed and g.rules.players[1]["souls"]==15 and g.rules.players[0]["souls"]==0)
   assert(not g.hud_ui.essence.visible and not g.hand_root.visible and not g.pad_input.bindings.has("suction"))
   print("PASS: LAN reward client: portrait touch/manual fire, claimed particle ownership and automatic wallet credit replicate, harvest UI is removed")
   g._quit_game()
 return false
