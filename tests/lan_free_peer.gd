extends SceneTree
var g
var host := false
var started := 0
var deadline := 0
var ready_sent := false
var bought := false
var shop_started := false
var reveal_shortened := false
var disconnected := false
var packets := 0
var move_sent := false
var stopped := false
var fired := false
var released := false
var turned := false
var move_seen := false
var fire_seen := false
var bullets_seen := false
var gold_seen := false
var phases := {}
var initial := Vector3.ZERO
func _initialize() -> void:call_deferred("start")
func start() -> void:
 host="host" in OS.get_cmdline_user_args();root.size=Vector2i(1206,540) if host else Vector2i(540,1206)
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 deadline=Time.get_ticks_msec()+40000
 g.net.launch.connect(func(_config):started=Time.get_ticks_msec();initial=g.player.position)
 g.net.state_received.connect(func(_packet):packets+=1)
 g.net.action_received.connect(func(_id,kind,value,_seq):
  if kind=="move" and value!=Vector2.ZERO:move_seen=true
  if kind=="fire" and value==true:fire_seen=true)
 g.net.fighter_disconnected.connect(func(_fighter):disconnected=true)
 if host:assert(g.net.host(4,0,27819)==OK)
 else:assert(g.net.join_room("127.0.0.1",27819)==OK)
func axis(id: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=id;e.axis_value=value;g._input(e)
func _process(_delta: float) -> bool:
 if g==null or g.quitting:return false
 if Time.get_ticks_msec()>deadline:push_error("LAN free-arena test timed out");quit(1);return false
 if host and disconnected:
  assert(not g.rules.players[4]["human"] and g.brains.has(4),"Disconnected client becomes a navigation-driven bot")
  print("PASS: LAN free host: shared conditions/prelude, validated free movement and pellets, shopping, hunting, free-bot takeover")
  g._quit_game();return false
 if not g.net.in_match:
  if host and g.net.can_start():g.net.start_match(717)
  elif not host and g.net.human_slots.size()==2 and not ready_sent:g.net.set_ready();ready_sent=true
  return false
 var elapsed: float=(Time.get_ticks_msec()-started)/1000.0
 phases[g.rules.phase]=true
 if host:
  if elapsed<5.8:assert(g.rules.remaining==165,"Prelude does not eat collection time")
  if elapsed>6.2 and not gold_seen:g.cloud.spawn(Vector3(0,2,0),15,-1,true);gold_seen=true
  if elapsed>9.0 and not shop_started:
   assert(move_seen and fire_seen and g.rules.players[4]["ammo"]<5,"Host receives movement and manual pellet shots")
   g.rules.credit_essence(4,140);g.rules.remaining=.001;shop_started=true
  if g.rules.phase==1 and g.rules.players[4]["weapon"]=="needle":g.rules.ready(0)
  if g.rules.phase==2 and not reveal_shortened:g.rules.remaining=2;reveal_shortened=true
 else:
  assert(g.local_id==4)
  assert(g.conditions==g.Weather.roll(717,0),"Both phones agree on time and weather")
  bullets_seen=bullets_seen or not g.projectiles.bullets.is_empty()
  for orb in g.cloud.orbs.values():gold_seen=gold_seen or orb["gold"]
  if elapsed>6.6 and g.screen=="play" and not move_sent:axis(JOY_AXIS_LEFT_X,.8);move_sent=true
  if elapsed>7.0 and g.screen=="play" and not fired:axis(JOY_AXIS_TRIGGER_RIGHT,1);fired=true
  if elapsed>7.9 and not stopped:axis(JOY_AXIS_LEFT_X,0);stopped=true
  if elapsed>8.1 and not released:axis(JOY_AXIS_TRIGGER_RIGHT,0);released=true
  if elapsed>8.3 and g.screen=="play" and not turned:
   var e:=InputEventJoypadButton.new();e.device=99;e.button_index=JOY_BUTTON_Y;e.pressed=true;g._input(e);e.pressed=false;g._input(e);turned=true
  if g.rules.phase==1 and not bought:g._request_action("buy","needle");g._request_action("ready");bought=true
  if g.rules.phase==3 and elapsed>16:
   assert(packets>150 and bullets_seen and gold_seen,"Client receives continuous state, projectiles, and gold")
   assert(phases.has_all([0,1,2,3]) and g.rules.rewards.size()==8,"Full match phases and rolls synchronize")
   assert(g.player.position.distance_to(initial)>1,"Client predicts genuine free movement")
   assert(Vector2(g.player.velocity.x,g.player.velocity.z).length()<.1,"Releasing movement stops the client")
   assert(g.rules.players[4]["weapon"]=="needle" and g.rules.players[4]["souls"]==60,"Shop remains authoritative")
   print("PASS: LAN free client: ",packets," snapshots, portrait/landscape, shared weather RNG, free move/stop, visible pellets, economy and five-round phases")
   g.net.close();g._quit_game()
 return false
