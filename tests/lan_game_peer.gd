extends SceneTree
var game
var hosting := false
var started_at := 0
var deadline := 0
var ready_sent := false
var buy_sent := false
var seen := {}
var switched_shop := false
var shortened_reveal := false
var hurt := false
var disconnected := false
var received := 0
var last_phase := -1
var gold_seen := false
var gold_placed := false
var reversed := false
var reverse_received := false
var variant_seen := {}
var launch_position := Vector3.ZERO
func _initialize() -> void:call_deferred("start")
func start() -> void:
 hosting = "host" in OS.get_cmdline_user_args()
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 deadline = Time.get_ticks_msec()+22000
 game.net.connection_error.connect(func(message):push_error(message);quit(1))
 game.net.launch.connect(func(_config):started_at=Time.get_ticks_msec();launch_position=game.player.position)
 game.net.state_received.connect(func(_packet):received+=1)
 game.net.action_received.connect(func(_id,kind,_value,_sequence):
  if kind=="reverse":reverse_received=true)
 game.net.fighter_disconnected.connect(func(_fid):disconnected=true)
 if hosting:
  assert(game.net.host(4,0,27809)==OK)
 else:
  assert(game.net.join_room("127.0.0.1",27809)==OK)
func _process(_delta: float) -> bool:
 if game==null or game.quitting:return false
 var now := Time.get_ticks_msec()
 if now>deadline:
  push_error("LAN test timed out")
  quit(1)
  return false
 if hosting and disconnected:
  assert(not game.rules.players[4]["human"])
  print("PASS: LAN host: 4v4, ready, shopping, shared reveal, hunt, disconnect bot takeover")
  game._quit_game()
  return false
 if not game.net.in_match:
  if hosting:
   if disconnected:
    assert(not game.rules.players[4]["human"])
    print("PASS: LAN host: 4v4, ready, shopping, shared reveal, hunt, disconnect bot takeover")
    game._quit_game()
   elif game.net.can_start():game.net.start_match(717)
  elif game.net.human_slots.size()==2 and not ready_sent:
   ready_sent = true
   game.net.set_ready()
  return false
 var elapsed := (now-started_at)/1000.0
 var phase: int = game.rules.phase
 seen[phase] = true
 if phase!=last_phase:
  print("LAN ","host" if hosting else "client"," phase ",phase," slot ",game.local_id)
  last_phase = phase
 if hosting:
  if phase==0 and not gold_placed:
   game.cloud.spawn(Vector3(0,2,0),15,-1,true)
   gold_placed=true
  if elapsed>2 and not switched_shop:
   assert(game.rails[4].last_input>0,"Remote aiming reaches host")
   assert(reverse_received,"Remote reversal reaches host")
   game.rules.credit_essence(4,140)
   game.rules.remaining = 0.001
   switched_shop = true
  if phase==1:
   if game.rules.players[4]["weapon"]=="needle":game.rules.ready(0)
  if phase==2 and not shortened_reveal:
   assert(game.rules.rewards.size()==8)
   game.rules.remaining = 2.0
   shortened_reveal = true
  if phase==3 and not hurt:
   game.rules.players[4]["invul"] = 0
   game._damage_fighter(4,35,0)
   hurt = true
 else:
  assert(game.local_id==4,"Guest is on opposing team")
  for orb in game.cloud.orbs.values():
   gold_seen = gold_seen or orb["gold"]
  for body in game.entities.values():
   if body.get_meta("role")=="minion":variant_seen[body.get_meta("subtype")]=true
  if phase==0 and elapsed>.7 and not reversed:
   game._request_action("reverse")
   reversed=true
  if phase==1 and not buy_sent:
   game._request_action("buy","needle")
   game._request_action("ready")
   buy_sent = true
  if phase==3 and elapsed>9:
   assert(seen.has_all([0,1,2,3]),"All phases synchronized")
   assert(received>70,"Continuous snapshots")
   assert(gold_seen and variant_seen.has_all(["scavenger","stalker","brute"]),"Guest receives gold and all minion variants")
   assert(reversed,"Guest predicts reverse")
   assert(game.rules.players[4]["weapon"]=="needle" and game.rules.players[4]["souls"]==60,"Host validates and syncs purchase")
   assert(game.rules.rewards.size()==8,"Guest sees every player's gift")
   assert(game.player.position.distance_to(launch_position)>1,"Guest predicts actual movement")
   assert(game.entities.has(0) and game.entities.size()>=7,"Guest receives all fighters")
   print("PASS: LAN client: remote input, ",received," snapshots, authoritative purchase, all phases, 8 rolls, reversal, gold and variants, movement")
   game.net.close()
   game._quit_game()
 return false
