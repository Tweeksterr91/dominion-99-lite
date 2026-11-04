extends SceneTree
var g
var host:=false
var started:=0
var configured:=false
var pressed:=false
var released:=false
var charge_seen:=false
var charging_blocked:=false
var sent_lock:=false
var deadline:=0
func _initialize() -> void:call_deferred("run")
func axis(id: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=id;e.axis_value=value;g._input(e)
func run() -> void:
 host="host" in OS.get_cmdline_user_args();root.size=Vector2i(1206,540) if host else Vector2i(540,1206)
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 deadline=Time.get_ticks_msec()+28000
 g.net.launch.connect(func(_config):started=Time.get_ticks_msec())
 g.net.action_received.connect(func(_id,kind,value,_seq):
  if kind=="lock" and value==true:sent_lock=true)
 if host:assert(g.net.host(1,0,27829)==OK)
 else:assert(g.net.join_room("127.0.0.1",27829)==OK)
func _process(_delta: float) -> bool:
 if g==null or g.quitting:return false
 if Time.get_ticks_msec()>deadline:push_error("LAN lock timeout");quit(1);return false
 if not g.net.in_match:
  if host and g.net.can_start():g.net.start_match(9909)
  elif not host and g.net.human_slots.size()==2:g.net.set_ready()
  return false
 var elapsed: float=(Time.get_ticks_msec()-started)/1000.0
 if host:
  if elapsed>6.3 and not configured:
   g.rules.phase=g.Rules.Phase.HUNT;g.rules.revision+=1;g.rules.remaining=82.5;g._handle_phase_change()
   g.player.position=Vector3(0,.05,3);g.rails[0].aim_yaw=PI;g.player.rotation.y=PI
   g.entities[1].position=Vector3(0,.05,8);g.rails[1].aim_yaw=0;g.rails[1].pitch=atan2(-.3,5)
   g.rules.players[0]["hp"]=1000;g.rules.players[0]["shield"]=1000;configured=true
  if sent_lock:
   var state: Dictionary=g.lock_states.get(1,{})
   if float(state.get("ttl",0))>0 and float(state.get("charge",0))<g.LOCK_TIME:
    charging_blocked=true;assert(not g._can_shoot(1))
   if float(state.get("charge",0))>=g.LOCK_TIME:charge_seen=true
  if elapsed>10:
   assert(sent_lock and charging_blocked and charge_seen,"Host independently acquires, charges and gates a network lock")
   assert(g.rules.players[1]["ammo"]<5,"Host accepts shots only after acquiring lock")
   assert(float(g.lock_states[1]["ttl"])==0,"Release clears host state")
   print("PASS: LAN lock host: validated LT, acquisition gating, green charge, shooting and release")
   g._quit_game()
 else:
  if elapsed>6.8 and not configured:
   g.rails[1].aim_yaw=0;g.rails[1].pitch=atan2(-.3,5);g.player.rotation.y=0;g.camera.rotation=Vector3(g.rails[1].pitch,0,0);configured=true
  if elapsed>7 and not pressed:axis(JOY_AXIS_TRIGGER_LEFT,1);axis(JOY_AXIS_TRIGGER_RIGHT,1);pressed=true
  if pressed and not released:charge_seen=charge_seen or g._lock_progress(1)>=1
  if elapsed>8.8 and not released:
   assert(charge_seen and g.rules.players[1]["ammo"]<5,"Guest sees charged authoritative lock and shots")
   axis(JOY_AXIS_TRIGGER_LEFT,0);axis(JOY_AXIS_TRIGGER_RIGHT,0);released=true
  if elapsed>9.6:
   assert(released and float(g.lock_states[1]["ttl"])==0)
   print("PASS: LAN lock client: portrait guest sees authoritative green acquisition, shots and release")
   g._quit_game()
 return false
