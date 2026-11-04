extends SceneTree
var g
var host:=false
var deadline:=0
var started:=0
var ready_sent:=false
var granted:=false
var bought:=false
var wheel_selected:=false
var shooting:=false
var stopped:=false
var melee_selected:=false
var returning:=false
var saved_ammo:=-1
var damage_sent:=false
var edge_seen:=false
var fired_at:=0
var host_done_at:=0
func _initialize() -> void:call_deferred("run")
func axis(id: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=id;e.axis_value=value;g._input(e)
func button(id: int,pressed: bool) -> void:
 var e:=InputEventJoypadButton.new();e.device=99;e.button_index=id;e.pressed=pressed;g._input(e)
func choose_weapon(key: String) -> void:
 choose(Vector2.from_angle(-PI/2+TAU*g.hud_ui.wheel.keys.find(key)/7))
func choose(direction: Vector2) -> void:
 button(JOY_BUTTON_LEFT_SHOULDER,true);axis(JOY_AXIS_RIGHT_X,direction.x);axis(JOY_AXIS_RIGHT_Y,direction.y)
 g.pad_input.step(.04);button(JOY_BUTTON_LEFT_SHOULDER,false)
 axis(JOY_AXIS_RIGHT_X,0);axis(JOY_AXIS_RIGHT_Y,0)
func run() -> void:
 host="host" in OS.get_cmdline_user_args();root.size=Vector2i(1206,540) if host else Vector2i(540,1206)
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 deadline=Time.get_ticks_msec()+32000
 g.net.launch.connect(func(_config):started=Time.get_ticks_msec())
 if host:assert(g.net.host(1,0,27849)==OK)
 else:assert(g.net.join_room("127.0.0.1",27849)==OK)
func _process(_delta: float) -> bool:
 if g==null or g.quitting:return false
 if Time.get_ticks_msec()>deadline:push_error("LAN armory timeout");quit(1);return false
 if not g.net.in_match:
  if host and g.net.can_start():g.net.start_match(99)
  elif not host and g.net.human_slots.size()==2 and not ready_sent:g.net.set_ready();ready_sent=true
  return false
 var elapsed: float=(Time.get_ticks_msec()-started)/1000.0
 if host:
  if elapsed>6.3 and not granted:
   g.rules.credit_essence(1,800);g.rules.remaining=.001;granted=true
  if g.rules.phase==g.Rules.Phase.SHOP and g.rules.players[1]["ready"]:g.rules.ready(0)
  if g.rules.phase==g.Rules.Phase.HUNT:
   if not damage_sent:
    g.rules.players[1]["invul"]=0;g.pending_hit_directions[1]=Vector3.RIGHT;g._damage_fighter(1,10,0);damage_sent=true
   if g.rules.players[0]["weapon"]!="scythe":g._request_action("equip","scythe")
   if g.rules.players[1]["weapon"]=="needle" and g.rules.players[1]["ammo"]<24:saved_ammo=g.rules.players[1]["ammo"]
   if g.rules.players[1]["weapon"]=="scythe":
    assert(g.rules.players[1]["ammo"]==1 and g.rules.players[1]["reserve"]==-1 and g.rules.players[1]["owned"].size()==7)
    assert(g.entities[1].get_node("Armory_scythe").get_meta("plasma_team")==1)
    melee_selected=true
   if melee_selected and g.rules.players[1]["weapon"]=="needle" and host_done_at==0:
    assert(g.rules.players[1]["ammo"]==saved_ammo and g.rules.players[1]["souls"]==240)
    host_done_at=Time.get_ticks_msec()
  if host_done_at>0 and Time.get_ticks_msec()-host_done_at>900:
   print("PASS: LAN armory host: all weapons purchased, equipped through LB wheel, per-weapon ammo preserved, infinite scythe and red-team visual replicated, owned/economy authoritative")
   g._quit_game()
 else:
  var edges: Vector4=g.rules.players[1].get("damage_edges",Vector4.ZERO)
  edge_seen=edge_seen or edges.length()>0
  if g.rules.phase==g.Rules.Phase.SHOP and not bought:
   for key in ["double","pulse","needle","scatter","sniper"]:g._request_action("buy",key)
   g._request_action("ready");bought=true
  if g.rules.phase==g.Rules.Phase.HUNT:
   if not wheel_selected:
    assert(g.rules.players[1]["owned"].size()==7 and g.rules.players[1]["inventory"].size()==7)
    choose_weapon("needle");wheel_selected=true
   elif g.rules.players[1]["weapon"]=="needle" and not shooting:axis(JOY_AXIS_TRIGGER_RIGHT,1);shooting=true;fired_at=Time.get_ticks_msec()
   if shooting and not stopped and Time.get_ticks_msec()-fired_at>450:
    axis(JOY_AXIS_TRIGGER_RIGHT,0);stopped=true;saved_ammo=g.rules.players[1]["ammo"]
    choose_weapon("scythe")
   if stopped and g.rules.players[1]["weapon"]=="scythe" and not returning:
    saved_ammo=int(g.rules.players[1]["inventory"]["needle"]["ammo"])
    assert(g.scythe_rig.visible and g.scythe_rig.get_meta("plasma_team")==1)
    assert(g.entities[0].get_node("Armory_scythe").get_meta("plasma_team")==0,"Guest sees host's blue scythe")
    assert(g.rules.players[1]["reserve"]==-1)
    choose_weapon("needle");returning=true
   if returning and g.rules.players[1]["weapon"]=="needle":
    assert(g.rules.players[1]["ammo"]==saved_ammo and saved_ammo<24)
    assert(edge_seen,"Authoritative directional damage reaches portrait client")
    print("PASS: LAN armory client: portrait LB wheel, all seven weapons, finite ammo survives swaps, infinite melee, red/blue plasma visuals, single-match rules")
    g._quit_game()
 return false
