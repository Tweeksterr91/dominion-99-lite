extends SceneTree
var g
func _initialize() -> void:call_deferred("verify")
func verify() -> void:
 root.size=Vector2i(540,1206)
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 g.set_physics_process(false);g.pad_input.set_physics_process(false)
 var counts: Dictionary={};var names: Dictionary={};var routes: Dictionary={}
 for hero in g.HEROES.roster():
  counts[hero["kind"]]=counts.get(hero["kind"],0)+1;names[hero["name"]]=true
  var route: Array=[]
  for i in range(5):route.append(g.HEROES.mission(hero["id"],i)["map"])
  routes[str(route)]=true
 assert(counts=={"male":8,"female":8,"anthro":4,"robot":4} and names.size()==24 and routes.size()==24)
 g._show_heroes();assert(g.screen=="heroes")
 g._ui_action("hero_select","vera");assert(g.screen=="hero_detail" and g.hero_id=="vera")
 g.hero_id="rook";g._start_match(1,0,99,[0]);g.set_physics_process(false)
 var deadline:=Time.get_ticks_msec()+25000
 while not g.course.nav_ready and Time.get_ticks_msec()<deadline:await physics_frame
 assert(g.course.nav_ready and g.course.spawn_nodes.size()>50,"Larger rooftop navigation and validated shared spawn pool")
 assert(g.course.building_count==48 and g.course.foliage_patches==84)
 g._sync_random_spawns();g.prelude_left=0;g._show("play")
 var seen: Dictionary={}
 for i in range(30):
  g._respawn_fighter(0)
  var key: int=g._nearest_node(g.player.position);seen[key]=true
  assert(key in g.course.spawn_nodes)
 assert(seen.size()>10,"Respawns genuinely randomize across shared points")
 var m=g.rails[0];g.player.position=Vector3(0,.1,45);g.player.velocity=Vector3.ZERO;m.aim_yaw=PI
 var lives: int=g.rules.players[0]["lives"]
 for i in range(180):
  await physics_frame;m.set_move(Vector2(0,-1));g._tick_human_motion(1.0/60)
  if i in [30,50]:m.jump(g.player)
 assert(g.player.position.z<47 and g.player.position.y>-.3 and g.rules.players[0]["lives"]==lives,"Rooftop edge cannot be jumped out of")
 g.player.position=Vector3(0,10,18);g.player.velocity=Vector3.ZERO;m.set_move(Vector2.ZERO)
 for i in range(150):await physics_frame;g._tick_human_motion(1.0/60)
 assert(g.player.position.y>=-.3 and g.rules.players[0]["lives"]==lives,"Former void gaps now land on the continuous building")
 assert(g.Rules.ROUND_COUNT==1)
 for seed_value in range(32):assert(not ":" in str(g.Weather.roll(seed_value,0)["time"]))
 g._render_hud(.016);assert(not g.hud_ui.labels["round"].visible)
 g.rules.phase=g.Rules.Phase.SHOP;var p: Dictionary=g.rules.players[0];p["souls"]=2000
 g._show_shop()
 for item in g.hud_ui.data["items"]:assert(item["id"] not in p["owned"] and item["id"] not in ["health","shield","heal","reload"])
 var spread: float=g.rules.stats(0)["spread"]
 for i in range(3):g._purchase(0,"choke")
 assert(g.rules.stats(0)["spread"]<spread*.56)
 g._purchase(0,"needle");g._purchase(0,"sniper");assert("sniper" in p["owned"])
 g.rules.players[1]["souls"]=2000;assert(not g.rules.buy(1,"sniper"),"Bots cannot buy the sniper")
 g._show_shop()
 for item in g.hud_ui.data["items"]:assert(item["id"] not in p["owned"])
 g.rules.phase=g.Rules.Phase.COLLECTION;g._switch_weapon(0,"needle");assert(g.carbon_rig.visible)
 g._switch_weapon(0,"sniper");assert(g.sniper_rig.visible)
 for rig in [g.carbon_rig,g.sniper_rig]:
  for mesh in rig.find_children("*","MeshInstance3D",true,false):
   for surface in range(mesh.mesh.get_surface_count()):
    var material: Material=mesh.get_active_material(surface)
    if material is StandardMaterial3D:assert(not material.emission_enabled,"Military rifles contain no neon/emission")
 # Incoming projectile directions are transformed into the victim's view, not world compass axes.
 p["invul"]=0;m.aim_yaw=0
 for pair in [[Vector3.LEFT,0],[Vector3.RIGHT,1],[Vector3.FORWARD,2],[Vector3.BACK,3]]:
  p["damage_edges"]=Vector4.ZERO;g.pending_hit_directions[0]=pair[0];g._damage_fighter(0,1,-1)
  assert(p["damage_edges"][pair[1]]>.9)
 m.aim_yaw=PI/2;p["damage_edges"]=Vector4.ZERO;g.pending_hit_directions[0]=Vector3.RIGHT;g._damage_fighter(0,1,-1)
 assert(p["damage_edges"].w>.9,"Turning around remaps attack directions correctly")
 g._tick_fighter_states(.6);assert(p["damage_edges"]==Vector4.ZERO)
 p["invul"]=2;g.pending_hit_directions[0]=Vector3.RIGHT;g._damage_fighter(0,1,-1);assert(p["damage_edges"]==Vector4.ZERO)
 # Separate career goals, unlocks and counters survive a real settings-file round trip.
 g.hero_id="rook";g.hero_match_id="rook";g.hero_mission=0;g.hero_careers["rook"]=g.HEROES.empty_career()
 g.hero_careers["inez"]=g.HEROES.empty_career();g.rules.match_winner=0;p["minions"]=3;p["essence"]=30;p["frags"]=1
 g.career_recorded=false;g._record_hero_career();assert(g.hero_careers["rook"]["unlocked"]==2)
 g.hero_match_id="inez";p["minions"]=0;g.career_recorded=false;g._record_hero_career()
 assert(g.hero_careers["inez"]["unlocked"]==1 and g.hero_careers["inez"]["cleared"].is_empty())
 g.hero_careers={};g._load_settings();assert(g.hero_careers["rook"]["unlocked"]==2 and g.hero_careers["inez"]["unlocked"]==1)
 for i in range(1,5):
  g.hero_match_id="rook";g.hero_mission=i;g.career_recorded=false;p["minions"]=99;g._record_hero_career()
 assert(g.hero_careers["rook"]["cleared"].size()==5 and g.hero_careers["inez"]["cleared"].is_empty())
 print("PASS: supported safe rooftop, skyline/overgrowth, random shared spawns, one-match HUD, no clock labels, filtered armory/choke, military rifles/human-only sniper, directional damage, 24 unique hero campaigns and separate saved careers")
 g._quit_game()
