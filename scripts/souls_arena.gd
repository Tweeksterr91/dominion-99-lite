extends "res://scripts/runner.gd"
const Rules = preload("res://scripts/match_rules.gd")
const Rail = preload("res://scripts/rail_motion.gd")
const ArenaHUD = preload("res://scripts/arena_hud.gd")
const LanSession = preload("res://scripts/lan_session.gd")
const EssenceCloud = preload("res://scripts/essence_cloud.gd")
const HAND = preload("res://assets/models/essence_hand.glb")
var rules := Rules.new()
var hud_ui: CanvasLayer
var net: Node
var cloud: Node3D
var entities: Dictionary = {}
var rails: Dictionary = {}
var humans: Array[int] = [0]
var local_id := 0
var next_minion := 100
var screen := "title"
var demo := true
var app_paused := false
var selected_size := 1
var campaign_level := 0
var campaign_unlocked := 1
var campaign_match := true
var sensitivity_index := 1
var sound_volume := 0.8
var invert_aim := false
var camera_motion := true
var options_origin := "main"
var last_ip := ""
var phase_revision := -1
var seen_round := 0
var minion_spawn_left := 0.0
var snapshot_left := 0.0
var aim_send_left := 0.0
var snapshot_number := 0
var last_snapshot := -1
var critical_sequence := 0
var phase_wall_time := 0
var toast := ""
var toast_left := 0.0
var shot_events: Array = []
var notices: Array = []
var supply_nodes: Array[Node3D] = []
var supply_timers: Array[float] = []
var corpses: Array[Node3D] = []
var corpse_lives: Array[float] = []
var hand_root: Node3D
var hand_amount := 0.0
var settings := ConfigFile.new()
var combat_random := RandomNumberGenerator.new()
var shop_signature := ""

func _ready() -> void:
	Engine.max_fps = 60
	_load_settings()
	_make_player()
	_make_audio()
	shot_sound.volume_db = -12+linear_to_db(maxf(0.001,sound_volume))
	net = LanSession.new()
	net.name = "LanSession"
	add_child(net)
	net.launch.connect(_lan_launch)
	net.action_received.connect(_apply_action)
	net.state_received.connect(_apply_snapshot)
	net.lobby_changed.connect(_refresh_lobby)
	net.connection_error.connect(_network_error)
	net.fighter_disconnected.connect(_replace_departed)
	hud_ui = ArenaHUD.new()
	add_child(hud_ui)
	hud_ui.action.connect(_ui_action)
	cloud = EssenceCloud.new()
	add_child(cloud)
	cloud.collected.connect(_essence_collected)
	hand_root = HAND.instantiate()
	camera.add_child(hand_root)
	for mesh in hand_root.find_children("*","MeshInstance3D",true,false):
		mesh.layers = 2
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hand_root.hide()
	_start_match(1,0,99,[0],false,true)
	_show("title")

func _load_settings() -> void:
	settings.load("user://dominion_settings.cfg")
	sensitivity_index = clampi(int(settings.get_value("controls","sensitivity",1)),0,2)
	sound_volume = clampf(float(settings.get_value("audio","volume",0.8)),0,1)
	invert_aim = settings.get_value("controls","invert",false)
	camera_motion = settings.get_value("controls","motion",true)
	campaign_unlocked = clampi(int(settings.get_value("campaign","unlocked",1)),1,5)
	last_ip = settings.get_value("network","last_ip","")

func _save_settings() -> void:
	settings.set_value("controls","sensitivity",sensitivity_index)
	settings.set_value("controls","invert",invert_aim)
	settings.set_value("controls","motion",camera_motion)
	settings.set_value("audio","volume",sound_volume)
	settings.set_value("campaign","unlocked",campaign_unlocked)
	settings.set_value("network","last_ip",last_ip)
	settings.save("user://dominion_settings.cfg")

func _authority() -> bool:
	return not net.in_match or net.hosting

func _show(value: String,context: Dictionary={}) -> void:
	screen = value
	hud_ui.show_screen(value,context)
	touch_aim = -1
	if value == "play" and not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	phase_wall_time = Time.get_ticks_usec()

func _ui_action(kind: String,value: Variant) -> void:
	match kind:
		"main":_show("main")
		"campaign":_show("campaign",{"maps":CorridorMap.NAMES,"unlocked":campaign_unlocked})
		"campaign_start":
			campaign_level = clampi(int(value),0,campaign_unlocked-1)
			campaign_match = true
			net.close()
			local_id = 0
			_start_match(1,campaign_level,Time.get_ticks_msec(),[0])
		"multiplayer":_show("multiplayer")
		"mp_format":
			selected_size = clampi(int(value),1,4)
			_show("format",{"size":selected_size})
		"format":_show("format",{"size":selected_size})
		"practice":
			net.close()
			campaign_match = false
			local_id = 0
			_start_match(selected_size,biome,Time.get_ticks_msec(),[0])
		"lan_host":
			if net.host(selected_size,biome) == OK:_refresh_lobby()
			else:_show("join",{"message":"Could not open a room on UDP 27799.","ip":last_ip})
		"join_screen":_show("join",{"ip":last_ip})
		"lan_join":
			last_ip = hud_ui.ip.text.strip_edges()
			DisplayServer.virtual_keyboard_hide()
			_save_settings()
			var error: Error = net.join_room(last_ip)
			if error == OK:_show("lobby",{"status":"CONNECTING...","host":false})
			else:_show("join",{"ip":last_ip,"message":"Check the host IP address."})
		"lobby_ready":net.set_ready()
		"lobby_start":net.start_match(Time.get_ticks_msec())
		"leave_room":
			net.close()
			_show("multiplayer")
		"route":_request_action("turn",value)
		"jump":_request_action("jump")
		"essence":_request_action("suction")
		"pause":_pause()
		"resume":_show("play")
		"abandon":_return_to_main()
		"options":
			options_origin = "paused" if not demo else "main"
			_show_options()
		"option_sensitivity":
			sensitivity_index = (sensitivity_index+1)%3
			_save_settings()
			_show_options()
		"option_volume":
			sound_volume = fmod(sound_volume+0.2,1.19)
			shot_sound.volume_db = -12+linear_to_db(maxf(0.001,sound_volume))
			_save_settings()
			_show_options()
		"option_invert":
			invert_aim = not invert_aim
			_save_settings()
			_show_options()
		"option_motion":
			camera_motion = not camera_motion
			_save_settings()
			_show_options()
		"options_back":
			if options_origin == "paused":_show("paused",{"lan":net.in_match})
			else:_show("main")
		"buy":_request_action("buy",value)
		"shop_ready":_request_action("ready")
		"results_continue":
			if campaign_match and rules.match_winner == 0:
				campaign_level = mini(4,campaign_level+1)
				_start_match(1,campaign_level,Time.get_ticks_msec(),[0])
			else:_return_to_main()
		"credits":_show("credits")
		"quit":
			net.close()
			get_tree().quit()

func _show_options() -> void:
	_show("options",{"sensitivity_name":["LOW","NORMAL","HIGH"][sensitivity_index],"volume":sound_volume,"invert":invert_aim,"motion":camera_motion})

func _refresh_lobby() -> void:
	if not net.active or net.in_match:return
	var lines := ""
	for slot in net.human_slots:
		var ready := false
		if net.hosting:
			for peer in net.peers:
				if net.peers[peer] == slot:ready = net.ready_peers.get(peer,false)
		else:ready = net.ready_peers.get(slot,false)
		lines += "PLAYER %d%s  /  %s\n" % [slot+1," • YOU" if slot==net.local_slot else "","READY" if ready else "WAITING"]
	lines += "\nOpen slots use bots. Keep the host game open."
	_show("lobby",{"status":net.status,"host":net.hosting,"address":net.local_address()+"  /  UDP 27799" if net.hosting else "SAME WI-FI / DIRECT IP","roster":lines,"can_start":net.can_start()})

func _lan_launch(config: Dictionary) -> void:
	local_id = net.local_slot
	campaign_match = false
	var slots: Array[int] = []
	for id in config["humans"]:slots.append(int(id))
	_start_match(int(config["size"]),int(config["biome"]),int(config["seed"]),slots,true)

func _network_error(message: String) -> void:
	_return_to_main()
	_notify(message,6)
	_show("join",{"ip":last_ip,"message":message})

func _return_to_main() -> void:
	net.close()
	local_id = 0
	_start_match(1,biome,99,[0],false,true)
	_show("main")

func _start_match(size: int,map_id: int,seed_value: int,human_ids: Array,lan := false,attract := false) -> void:
	demo = attract
	biome = clampi(map_id,0,4)
	selected_size = size
	rules.start(size,seed_value)
	combat_random.seed = seed_value+414
	humans.clear()
	for id in human_ids:humans.append(int(id))
	if not lan:local_id = 0
	for p in rules.players:
		p["human"] = p["id"] in humans
		if lan and p["human"]:p["name"] = "HOST" if p["id"]==0 else "PLAYER %d" % (p["id"]+1)
	phase_revision = -1
	seen_round = 0
	snapshot_number = 0
	last_snapshot = -1
	critical_sequence = 0
	shot_events.clear()
	notices.clear()
	_build_course()
	_setup_round()
	phase_revision = rules.revision
	seen_round = rules.round_index
	running = true
	finished = false
	if not attract:_show("play")
	phase_wall_time = Time.get_ticks_usec()

func _setup_round() -> void:
	shot_sound.stop()
	for body in entities.values():
		body.collision_layer = 0
		body.queue_free()
	entities.clear()
	enemies.clear()
	for node in supply_nodes:node.queue_free()
	supply_nodes.clear()
	supply_timers.clear()
	for corpse in corpses:
		if is_instance_valid(corpse):corpse.queue_free()
	corpses.clear()
	corpse_lives.clear()
	cloud.clear()
	rails.clear()
	next_minion = 100
	for p in rules.players:
		var id: int = p["id"]
		var stat := rules.stats(id)
		p.merge({"hp":float(stat["health"]),"shield":float(stat["shield"]),"ammo":int(stat["mag"]),"reserve":72,"reload":0.0,"reload_total":float(stat["reload"]),"reload_used":false,"reload_flash":0.0,"fire_cd":0.0,"hit_age":10.0,"respawn":0.0,"invul":2.0,"suction":0.0,"deny_id":-1,"deny_dwell":0.0,"ai_pull":0.0,"shop_done":false,"damage_flash":0.0},true)
		var lane: int = id if p["team"]==0 else id-selected_size
		var spawn: int = [10,15,20,16][lane] if p["team"]==0 else [14,19,24,18][lane]
		var body := player if id == local_id else _create_entity(id,"fighter",spawn,id)
		body.collision_layer = _fighter_layer(id)
		if p["human"]:
			body.collision_mask = 1
			var motion := Rail.new()
			rails[id] = motion
			motion.reset(body,course,spawn)
		else:body.collision_mask = 0
	player.collision_mask = 1
	camera.position = Vector3(0,1.55,0)
	camera.rotation = Vector3.ZERO
	gun.visible = true
	for index in range(7):
		var node: int = [6,10,14,18,20,24,2][index]
		var kind := "health" if index%3==0 else "ammo"
		var item := art.build_pickup(self,course.nodes[node]+Vector3.UP*0.5,kind)
		item.set_meta("kind",kind)
		supply_nodes.append(item)
		supply_timers.append(0.0)
	if _authority():
		for node in [12,7,6,18,11,13]:_spawn_minion(node)
	minion_spawn_left = 2.5
	_sync_legacy_motion()
	_equip_viewmodel()

func _fighter_layer(id: int) -> int:
	return 32 if id == 0 else (16 if rules.players[id]["team"] == 0 else 4)

func _body(id: int) -> CharacterBody3D:
	return player if id == local_id else entities.get(id)

func _alive(id: int) -> bool:
	return id>=0 and id<rules.players.size() and rules.players[id].get("hp",0)>0 and rules.players[id]["lives"]>0 and rules.players[id].get("respawn",0)<=0

func _create_entity(key: int,role: String,node: int,fighter := -1) -> CharacterBody3D:
	super._spawn_bot(node)
	var body: CharacterBody3D = enemies.back()
	body.set_meta("key",key)
	body.set_meta("role",role)
	body.set_meta("fighter",fighter)
	body.set_meta("hp",65.0 if role=="minion" else 100.0)
	body.set_meta("muzzle",0.0)
	body.set_meta("attack",0.8)
	body.set_meta("air",false)
	if role == "minion":
		body.scale = Vector3.ONE*0.67
		body.collision_layer = 2
	else:body.collision_layer = _fighter_layer(fighter)
	body.collision_mask = 0
	var label := Label3D.new()
	label.text = "MINION" if role=="minion" else rules.players[fighter]["name"]
	label.font_size = 22
	label.pixel_size = 0.006
	label.position.y = 2.0
	label.modulate = Color("70ccff") if role=="minion" else Color("edb45d")
	body.add_child(label)
	entities[key] = body
	return body

func _spawn_minion(node: int) -> void:
	_create_entity(next_minion,"minion",node)
	next_minion += 1

func _notify(text: String,seconds := 2.2,fighter := -1) -> void:
	if fighter < 0 or fighter == local_id:
		toast = text
		toast_left = seconds
	elif net.hosting:notices.append([fighter,text])

func _replace_departed(id: int) -> void:
	if id<0 or id>=rules.players.size():return
	humans.erase(id)
	rules.players[id]["human"] = false
	rules.players[id]["name"] = "BOT %d" % (id+1)
	var body := _body(id)
	if is_instance_valid(body):
		body.collision_mask = 0
		if rails.has(id):
			body.set_meta("from",rails[id].origin)
			body.set_meta("to",rails[id].target)
			body.set_meta("progress",clampf(body.position.distance_to(course.nodes[rails[id].origin])/12.0,0,0.99))
	rails.erase(id)
	_notify("A disconnected player is now controlled by a bot.",4)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if screen == "title":
				_show("main")
				get_viewport().set_input_as_handled()
				return
			if screen == "play" and _alive(local_id):_request_action("reload")
			if hud_ui.press_at(event.position):
				get_viewport().set_input_as_handled()
				return
			if screen == "play" and touch_aim == -1 and _alive(local_id):touch_aim = event.index
		elif event.index == touch_aim:touch_aim = -1
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if screen == "title":_show("main")
		elif screen == "play":_request_action("reload")
	if screen == "join":return # Focused LineEdit receives normal keyboard/IME input.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if screen == "play":_pause()
			elif screen == "paused":_show("play")
			elif screen not in ["shop","reveal"]:_show("main")
		if screen == "play":
			if event.keycode in [KEY_A,KEY_LEFT]:_request_action("turn","left")
			if event.keycode in [KEY_D,KEY_RIGHT]:_request_action("turn","right")
			if event.keycode in [KEY_W,KEY_UP]:_request_action("turn","ahead")
			if event.keycode in [KEY_S,KEY_DOWN]:_request_action("turn","down")
			if event.keycode == KEY_SPACE:_request_action("jump")
			if event.keycode == KEY_E:_request_action("suction")
			if event.keycode == KEY_R:_request_action("reload")
	if screen != "play" or not _alive(local_id):return
	if event is InputEventScreenDrag and event.index == touch_aim:_look(event.relative*0.0035)
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:_look(event.relative*0.0025)

func _look(change: Vector2) -> void:
	if not rails.has(local_id):return
	var motion = rails[local_id]
	var multiplier: float = [0.65,1.0,1.4][sensitivity_index]
	motion.aim_yaw = clampf(motion.aim_yaw-change.x*multiplier,-1.1,1.1)
	motion.pitch = clampf(motion.pitch-change.y*multiplier*(-1 if invert_aim else 1),-0.95,0.95)
	camera.rotation = Vector3(motion.pitch,motion.aim_yaw,0)

func _request_action(kind: String,value: Variant=null) -> void:
	if demo:return
	if net.in_match:
		if not net.hosting and rails.has(local_id) and _alive(local_id):
			if kind == "turn":rails[local_id].choose(course,str(value))
			if kind == "jump":rails[local_id].jump(player)
		var seq: int = net.send_action(kind,value)
		if kind in ["turn","jump"]:critical_sequence = seq
	else:
		net.sequence += 1
		_apply_action(local_id,kind,value,net.sequence)

func _apply_action(id: int,kind: String,value: Variant,sequence: int) -> void:
	if not _authority() or id not in humans or id<0 or id>=rules.players.size():return
	if rails.has(id):rails[id].last_input = sequence
	if kind == "buy":
		if value is String:_purchase(id,value)
		return
	if kind == "ready":
		rules.ready(id)
		return
	if rules.phase not in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] or not _alive(id):return
	match kind:
		"aim":
			if value is Vector2 and is_finite(value.x) and is_finite(value.y) and rails.has(id):
				rails[id].aim_yaw = clampf(value.x,-1.1,1.1)
				rails[id].pitch = clampf(value.y,-0.95,0.95)
		"turn":
			if value in ["left","right","ahead","down"] and rails.has(id):rails[id].choose(course,value)
		"jump":
			if rails.has(id):rails[id].jump(_body(id))
		"reload":_try_reload(id)
		"suction":
			if rules.phase==Rules.Phase.COLLECTION:rules.players[id]["suction"] = 1.6

func _pause() -> void:
	if screen != "play":return
	_show("paused",{"lan":net.in_match})
	if not net.in_match:_set_animations(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		app_paused = true
		if screen=="play":_pause()
		if is_instance_valid(shot_sound):shot_sound.stop()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		app_paused = false
		phase_wall_time = Time.get_ticks_usec()

func _set_animations(active: bool) -> void:
	for body in entities.values():
		if body.has_meta("animation"):body.get_meta("animation").active = active and body.visible

func _physics_process(delta: float) -> void:
	if app_paused:return
	toast_left = maxf(0,toast_left-delta)
	if not demo and not net.in_match and screen in ["paused","options","credits"]:
		phase_wall_time = Time.get_ticks_usec()
		_render_hud(delta)
		return
	if demo:
		_demo_tick(delta)
	elif _authority():
		var now := Time.get_ticks_usec()
		var real_delta := clampf((now-phase_wall_time)/1000000.0,0,30)
		phase_wall_time = now
		rules.tick(real_delta)
		_handle_phase_change()
		_tick_fighter_states(delta)
		if rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT]:
			_tick_human_motion(delta)
			_tick_bots(delta)
			_tick_auto_combat(delta)
			_tick_supplies(delta)
			_tick_suction(delta)
			cloud.tick(delta,_collector_positions(),true)
		elif rules.phase==Rules.Phase.SHOP:_tick_bot_shopping()
		_handle_phase_change()
		snapshot_left -= delta
		if net.in_match and snapshot_left <= 0:
			net.publish(_pack_snapshot())
			snapshot_left = 0.05
	else:
		_client_tick(delta)
	_tick_corpses(delta)
	_tick_viewmodel(delta)
	_render_hud(delta)

func _handle_phase_change() -> void:
	if rules.revision == phase_revision:return
	phase_revision = rules.revision
	if rules.round_index != seen_round:
		seen_round = rules.round_index
		if _authority():_setup_round()
		_notify("ROUND %d / FIVE LIVES RESTORED" % rules.round_index,4)
	match rules.phase:
		Rules.Phase.COLLECTION:
			_show("play")
			_notify("COLLECTION / Minions only. Pull blue essence to earn souls.",5)
		Rules.Phase.SHOP:
			if _authority():
				for key in entities.keys():
					if entities[key].get_meta("role")=="minion":_remove_entity(key)
				cloud.clear()
				for p in rules.players:p["shop_done"] = false
			_show_shop()
			_set_animations(false)
		Rules.Phase.REVEAL:
			_show("reveal",{"rewards":rules.rewards,"names":_player_names(),"count":rules.players.size()})
			_set_animations(false)
		Rules.Phase.HUNT:
			_show("play")
			_notify("HUNTING / Rival players are now vulnerable.",4)
		Rules.Phase.RESULTS:
			if campaign_match and rules.match_winner==0:
				campaign_unlocked = maxi(campaign_unlocked,mini(5,campaign_level+2))
				_save_settings()
			var p: Dictionary = rules.players[local_id]
			var winner := "MATCH DRAW" if rules.match_winner<0 else ("VICTORY" if rules.match_winner==p["team"] else "DEFEAT")
			_show("results",{"summary":"%s\n\nROUNDS  %d : %d\n%d FRAGS / %d SOULS COLLECTED\n\nFive-round match complete." % [winner,rules.team_rounds[0],rules.team_rounds[1],p["frags"],p["essence"]]})
			_set_animations(false)

func _show_shop() -> void:
	var p: Dictionary = rules.players[local_id]
	var items: Array = []
	for id in Rules.WEAPONS:
		var weapon: Dictionary = Rules.WEAPONS[id]
		var owned: bool = id in p["owned"]
		items.append({"id":id,"text":"%s    %s" % [weapon["name"],"EQUIPPED" if p["weapon"]==id else ("EQUIP" if owned else "%d SOULS" % weapon["cost"])],"disabled":p["ready"] or (not owned and p["souls"]<weapon["cost"])})
	for id in Rules.UPGRADES:
		var item: Dictionary = Rules.UPGRADES[id]
		items.append({"id":id,"text":"%s    %d" % [item["name"],item["cost"]],"disabled":p["ready"] or p["souls"]<item["cost"] or int(p["upgrades"].get(id,0))>=item["limit"]})
	_show("shop",{"items":items})
	shop_signature = str([p["souls"],p["weapon"],p["upgrades"],p["ready"]])

func _purchase(id: int,item: String) -> void:
	var p: Dictionary = rules.players[id]
	if item=="heal" and (p["lives"]<=0 or p["hp"]>=rules.stats(id)["health"]):return
	if item=="ammo" and p["reserve"]>=360:return
	if not rules.buy(id,item):
		_notify("PURCHASE UNAVAILABLE",2,id)
		return
	var stat := rules.stats(id)
	if Rules.WEAPONS.has(item):
		p["ammo"] = stat["mag"]
		p["reload"] = 0.0
	elif item=="health":p["hp"] = minf(stat["health"],p["hp"]+20)
	elif item=="shield":p["shield"] = minf(stat["shield"],p["shield"]+20)
	elif item=="heal":p["hp"] = stat["health"] if p["lives"]>0 else 0.0
	elif item=="ammo":p["reserve"] = mini(360,p["reserve"]+72)
	_notify("ARMORY / PURCHASE COMPLETE",2,id)
	if id==local_id:_equip_viewmodel()

func _tick_bot_shopping() -> void:
	if Rules.SHOP_TIME-rules.remaining<1.5:return
	for p in rules.players:
		if p["human"] or p["shop_done"]:continue
		var id: int = p["id"]
		if p["souls"]>=80 and "needle" not in p["owned"]:_purchase(id,"needle")
		if p["hp"]<60 and p["souls"]>=20:_purchase(id,"heal")
		for item in ["damage","shield","reload"]:
			if p["souls"]>=Rules.UPGRADES[item]["cost"]:_purchase(id,item)
		if p["reserve"]<36 and p["souls"]>=15:_purchase(id,"ammo")
		p["shop_done"] = true
		rules.ready(id)

func _tick_fighter_states(delta: float) -> void:
	for p in rules.players:
		var id: int = p["id"]
		var stat := rules.stats(id)
		p["fire_cd"] = maxf(0,p["fire_cd"]-delta)
		p["invul"] = maxf(0,p["invul"]-delta)
		p["suction"] = maxf(0,p["suction"]-delta)
		p["reload_flash"] = maxf(0,p["reload_flash"]-delta)
		p["damage_flash"] = maxf(0,p["damage_flash"]-delta)
		var before := float(p["hit_age"])
		p["hit_age"] += delta
		if _alive(id) and p["shield"]<stat["shield"]:
			var recovery := maxf(0,float(p["hit_age"])-maxf(before,stat["shield_delay"]))
			p["shield"] = minf(stat["shield"],p["shield"]+recovery*20)
		if p["reload"]>0:
			p["reload"] = maxf(0,p["reload"]-delta)
			if p["reload"]<=0:_complete_reload(id)
		if p["respawn"]>0:
			p["respawn"] = maxf(0,p["respawn"]-delta)
			if p["respawn"]<=0 and p["lives"]>0:_respawn_fighter(id)

func _try_reload(id: int) -> void:
	var p: Dictionary = rules.players[id]
	if p["reload"]>0:
		if p["reload_used"]:return
		p["reload_used"] = true
		var progress := 1.0-float(p["reload"])/float(p["reload_total"])
		if progress>=0.60 and progress<=0.78:
			_complete_reload(id)
			p["reload_flash"] = 0.45
			_notify("ACTIVE RELOAD",1.2,id)
		return
	if p["ammo"]>0:return
	if p["reserve"]<=0:
		_notify("NO RESERVE / FIND AMBER AMMO",2,id)
		return
	p["reload_total"] = rules.stats(id)["reload"]
	p["reload"] = p["reload_total"]
	p["reload_used"] = false

func _complete_reload(id: int) -> void:
	var p: Dictionary = rules.players[id]
	var amount := mini(int(rules.stats(id)["mag"])-int(p["ammo"]),int(p["reserve"]))
	p["ammo"] += amount
	p["reserve"] -= amount
	p["reload"] = 0.0

func _respawn_fighter(id: int) -> void:
	var p: Dictionary = rules.players[id]
	var stat := rules.stats(id)
	p["hp"] = float(stat["health"])
	p["shield"] = float(stat["shield"])
	p["ammo"] = int(stat["mag"])
	p["reload"] = 0.0
	p["invul"] = 2.0
	var body := _body(id)
	if not is_instance_valid(body):return
	var node := 10 if p["team"]==0 else 14
	if rails.has(id):rails[id].reset(body,course,node)
	else:
		body.position = course.nodes[node]
		body.set_meta("from",node)
		body.set_meta("to",course.links[node][0])
		body.set_meta("progress",0.0)
	body.collision_layer = _fighter_layer(id)
	if id!=local_id:body.show()
	else:
		camera.position = Vector3(0,1.55,0)
		camera.rotation = Vector3.ZERO
		gun.show()

func _damage_fighter(victim: int,amount: float,attacker := -1) -> void:
	if not _alive(victim) or amount<=0:return
	if attacker>=0 and not rules.can_harm(attacker,victim):return
	var p: Dictionary = rules.players[victim]
	if p["invul"]>0 or demo:return
	var absorbed := minf(p["shield"],amount)
	p["shield"] -= absorbed
	p["hp"] = maxf(0,p["hp"]-(amount-absorbed))
	p["hit_age"] = 0.0
	p["damage_flash"] = 0.25
	if p["hp"]<=0:
		var body := _body(victim)
		if is_instance_valid(body):
			body.collision_layer = 0
			if victim!=local_id:
				_create_corpse(body)
				body.hide()
		p["respawn"] = 3.0
		p["suction"] = 0.0
		p["reload"] = 0.0
		rules.lose_life(victim,attacker)
		if victim==local_id:gun.hide()

func _tick_human_motion(delta: float) -> void:
	for id in humans:
		if not rails.has(id) or not _alive(id):continue
		var body := _body(id)
		if not is_instance_valid(body):continue
		var muzzle := maxf(0,float(body.get_meta("muzzle",0))-delta)
		body.set_meta("muzzle",muzzle)
		if body.has_node("MuzzleFlash"):body.get_node("MuzzleFlash").visible = muzzle>0
		var event: String = rails[id].step(body,course,delta)
		if event=="missed":
			_damage_fighter(id,25)
			_notify("MISSED LANDING",2,id)
		if id==local_id:
			camera.position = Vector3(0,1.55,0)
			camera.rotation = Vector3(rails[id].pitch,rails[id].aim_yaw,0)
		else:
			if body.has_meta("animation"):body.get_meta("animation").active = true
			art.animate_enemy(body,"Jump" if rails[id].jumps>0 else "Run")
	_sync_legacy_motion()

func _sync_legacy_motion() -> void:
	if not rails.has(local_id):return
	var motion = rails[local_id]
	origin_node = motion.origin
	target_node = motion.target
	queued_node = motion.queued
	jumps = motion.jumps
	distance_run = motion.distance
	junctions = motion.junctions

func _tick_bots(delta: float) -> void:
	for key in entities.keys():
		if not entities.has(key):continue
		var body: CharacterBody3D = entities[key]
		var role: String = body.get_meta("role")
		var id := int(body.get_meta("fighter"))
		if role=="fighter" and (rules.players[id]["human"] or not _alive(id)):continue
		_move_bot(body,delta)
		if role=="minion":_minion_attack(body,delta)
		else:_bot_attack(id,delta)
	if rules.phase==Rules.Phase.COLLECTION:
		minion_spawn_left -= delta
		if _minion_count()<6 and minion_spawn_left<=0:
			_spawn_minion([6,8,11,13,17,7][combat_random.randi_range(0,5)])
			minion_spawn_left = 2.5

func _move_bot(body: CharacterBody3D,delta: float) -> void:
	var a := int(body.get_meta("from"))
	var b := int(body.get_meta("to"))
	var progress := float(body.get_meta("progress"))+delta*(2.8 if body.get_meta("role")=="minion" else 4.4)/12
	if progress>=1:
		var choices: Array = []
		for node in course.links[b]:
			if node!=a:choices.append(node)
		if choices.is_empty():choices.append(a)
		a = b
		var goal := _bot_goal(body)
		b = choices[combat_random.randi_range(0,choices.size()-1)]
		if combat_random.randf()>0.20:
			var best := 999
			for node in choices:
				var hops := _graph_distance(int(node),goal)
				if hops<best:
					best = hops
					b = node
		progress -= 1
		body.set_meta("from",a)
		body.set_meta("to",b)
	body.set_meta("progress",progress)
	var direction: Vector3 = course.direction(a,b)
	body.position = course.nodes[a].lerp(course.nodes[b],progress)+Vector3(-direction.z,0,direction.x)*0.55
	var airborne: bool = course.climb(a,b)>0 and progress>0.25 and progress<0.8
	if course.climb(a,b)>0:body.position.y += sin(progress*PI)*(2.0 if course.climb(a,b)==2 else 1.0)
	body.rotation.y = atan2(-direction.x,-direction.z)
	body.set_meta("air",airborne)
	if body.has_meta("animation"):body.get_meta("animation").active = true
	art.animate_enemy(body,"Jump" if airborne else "Run")
	var muzzle := maxf(0,float(body.get_meta("muzzle"))-delta)
	body.set_meta("muzzle",muzzle)
	body.get_node("MuzzleFlash").visible = muzzle>0

func _bot_goal(body: CharacterBody3D) -> int:
	var goal := 12
	var nearest := INF
	var role: String = body.get_meta("role")
	var id := int(body.get_meta("fighter"))
	if role=="fighter" and rules.phase==Rules.Phase.COLLECTION:
		for orb in cloud.orbs.values():
			var distance := body.position.distance_squared_to(orb["pos"])
			if distance<nearest:
				nearest = distance
				goal = _nearest_node(orb["pos"])
		if nearest<100:return goal
		for target in entities.values():
			if target.get_meta("role")!="minion":continue
			var distance := body.position.distance_squared_to(target.position)
			if distance<nearest:
				nearest = distance
				goal = _nearest_node(target.position)
	else:
		for p in rules.players:
			var candidate: int = p["id"]
			if not _alive(candidate) or (role=="fighter" and p["team"]==rules.players[id]["team"]):continue
			var other := _body(candidate)
			if not is_instance_valid(other):continue
			var distance := body.position.distance_squared_to(other.position)
			if distance<nearest:
				nearest = distance
				goal = _nearest_node(other.position)
	return goal

func _nearest_node(pos: Vector3) -> int:
	var result := 0
	for i in range(course.nodes.size()):
		if course.nodes[i].distance_squared_to(pos)<course.nodes[result].distance_squared_to(pos):result = i
	return result

func _graph_distance(start: int,end: int) -> int:
	var queue: Array = [[start,0]]
	var seen: Array[int] = [start]
	while not queue.is_empty():
		var pair: Array = queue.pop_front()
		if pair[0]==end:return pair[1]
		for node in course.links[pair[0]]:
			if node not in seen:
				seen.append(node)
				queue.append([node,pair[1]+1])
	return 999

func _minion_attack(body: CharacterBody3D,delta: float) -> void:
	var timer := float(body.get_meta("attack"))-delta
	body.set_meta("attack",timer)
	if timer>0:return
	body.set_meta("attack",1.15)
	var best := -1
	var nearest := 10.0
	for p in rules.players:
		var id: int = p["id"]
		if not _alive(id):continue
		var target := _body(id)
		if not is_instance_valid(target):continue
		var distance := body.position.distance_to(target.position)
		if distance<nearest and _clear_sight(body.position+Vector3.UP*0.8,target.position+Vector3.UP):
			nearest = distance
			best = id
	if best>=0:
		_damage_fighter(best,9)
		body.set_meta("muzzle",0.12)

func _bot_attack(id: int,delta: float) -> void:
	var p: Dictionary = rules.players[id]
	if p["ammo"]<=0 and p["reload"]<=0:_try_reload(id)
	if p["ammo"]<=0 or p["reload"]>0 or p["fire_cd"]>0:return
	var body := _body(id)
	var best: CharacterBody3D
	var nearest := 22.0
	for candidate in entities.values():
		if candidate==body:continue
		var role: String = candidate.get_meta("role")
		var other := int(candidate.get_meta("fighter"))
		if rules.phase==Rules.Phase.COLLECTION and role!="minion":continue
		if rules.phase==Rules.Phase.HUNT and (role!="fighter" or not rules.can_harm(id,other) or not _alive(other)):continue
		var distance := body.position.distance_to(candidate.position)
		if distance<nearest and _clear_sight(body.position+Vector3.UP*1.3,candidate.position+Vector3.UP):
			nearest = distance
			best = candidate
	if rules.phase==Rules.Phase.HUNT and rules.can_harm(id,local_id) and _alive(local_id):
		var distance := body.position.distance_to(player.position)
		if distance<nearest and _clear_sight(body.position+Vector3.UP*1.3,camera.global_position):best = player
	if not is_instance_valid(best):return
	p["ammo"] -= 1
	p["fire_cd"] = maxf(0.4,float(rules.stats(id)["interval"])*2.3)
	body.set_meta("muzzle",0.12)
	if combat_random.randf()>0.50:return
	if best==player:_damage_fighter(local_id,rules.stats(id)["damage"],id)
	else:_damage_entity(best,rules.stats(id)["damage"],id)

func _ray_mask(id: int) -> int:
	if rules.phase==Rules.Phase.COLLECTION:return 1|2|8
	return 1|8|(4 if rules.players[id]["team"]==0 else 16|32)

func _target_for(id: int) -> Dictionary:
	var body := _body(id)
	if not is_instance_valid(body):return {}
	var origin := body.position+Vector3.UP*1.55
	var basis := body.global_basis
	if rails.has(id):basis *= Basis.from_euler(Vector3(rails[id].pitch,rails[id].aim_yaw,0))
	if id==local_id:
		origin = camera.global_position
		basis = camera.global_basis
	var query := PhysicsRayQueryParameters3D.create(origin,origin-basis.z*45,_ray_mask(id),[body.get_rid()])
	query.collide_with_areas = true
	return get_world_3d().direct_space_state.intersect_ray(query)

func _tick_auto_combat(delta: float) -> void:
	for id in humans:
		if not _alive(id):continue
		var p: Dictionary = rules.players[id]
		var hit := _target_for(id)
		if hit.is_empty():
			p["deny_id"] = -1
			p["deny_dwell"] = 0.0
			continue
		var target: Object = hit["collider"]
		if target is Area3D and target.has_meta("orb"):
			var orb := int(target.get_meta("orb"))
			if p["suction"]>0:continue
			if p["deny_id"]!=orb:
				p["deny_id"] = orb
				p["deny_dwell"] = 0.0
			p["deny_dwell"] += delta
			if p["deny_dwell"]>=0.55 and _can_shoot(id):
				_spend_shot(id)
				cloud.destroy(orb)
				_notify("ESSENCE DENIED",1.3,id)
			continue
		p["deny_id"] = -1
		p["deny_dwell"] = 0.0
		if target is CharacterBody3D and _can_shoot(id):
			if target==player and rules.can_harm(id,local_id):
				_spend_shot(id)
				_damage_fighter(local_id,rules.stats(id)["damage"],id)
			elif target.has_meta("role"):
				var role: String = target.get_meta("role")
				var other := int(target.get_meta("fighter"))
				if (rules.phase==Rules.Phase.COLLECTION and role=="minion") or (role=="fighter" and rules.can_harm(id,other)):
					_spend_shot(id)
					_damage_entity(target,rules.stats(id)["damage"],id)

func _can_shoot(id: int) -> bool:
	var p: Dictionary = rules.players[id]
	return p["ammo"]>0 and p["reload"]<=0 and p["fire_cd"]<=0

func _spend_shot(id: int) -> void:
	var p: Dictionary = rules.players[id]
	p["ammo"] -= 1
	p["fire_cd"] = rules.stats(id)["interval"]
	var body := _body(id)
	if is_instance_valid(body):body.set_meta("muzzle",0.12)
	if net.in_match and net.hosting:shot_events.append(id)
	if id==local_id:
		shot_sound.play()
		recoil = 0.065
		flash_left = 0.05

func _damage_entity(body: CharacterBody3D,amount: float,attacker: int) -> void:
	if not is_instance_valid(body) or not body.has_meta("role"):return
	if body.get_meta("role")=="fighter":
		_damage_fighter(int(body.get_meta("fighter")),amount,attacker)
		return
	if rules.phase!=Rules.Phase.COLLECTION:return
	var hp := float(body.get_meta("hp"))-amount
	body.set_meta("hp",hp)
	if hp<=0:
		rules.players[attacker]["minions"] += 1
		var pos := body.position
		_create_corpse(body)
		for i in range(3):cloud.spawn(pos+Vector3((i-1)*0.25,0.9,0.15*sin(i*2.0)),5)
		_remove_entity(int(body.get_meta("key")))

func _remove_entity(key: int) -> void:
	if not entities.has(key):return
	var body: CharacterBody3D = entities[key]
	body.collision_layer = 0
	enemies.erase(body)
	entities.erase(key)
	body.queue_free()

func _create_corpse(body: Node3D) -> void:
	if not body.has_meta("model") or not is_instance_valid(body.get_meta("model")):return
	var model: Node3D = body.get_meta("model")
	if body.has_meta("animation"):body.get_meta("animation").active = false
	model.reparent(self,true)
	var tween := create_tween()
	tween.tween_property(model,"rotation:z",1.45,0.35)
	corpses.append(model)
	corpse_lives.append(24.0)
	# A respawning fighter receives a fresh visual when its old model becomes a body.
	if body.get_meta("role")=="fighter":
		var old_flash = body.get_node_or_null("MuzzleFlash")
		if old_flash:old_flash.free()
		art.build_enemy(body)
	while corpses.size()>6:
		var first: Node3D = corpses.pop_front()
		corpse_lives.pop_front()
		if is_instance_valid(first):first.queue_free()

func _tick_corpses(delta: float) -> void:
	for i in range(corpses.size()-1,-1,-1):
		corpse_lives[i] -= delta
		if corpse_lives[i]<=1 and is_instance_valid(corpses[i]):corpses[i].position.y -= delta*0.8
		if corpse_lives[i]<=0:
			if is_instance_valid(corpses[i]):corpses[i].queue_free()
			corpses.remove_at(i)
			corpse_lives.remove_at(i)

func _clear_sight(from: Vector3,to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from,to,1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _collector_positions() -> Dictionary:
	var result: Dictionary = {}
	for p in rules.players:
		var id: int = p["id"]
		if not _alive(id):continue
		var body := _body(id)
		if not is_instance_valid(body):continue
		result[id] = camera.global_transform*Vector3(-0.18,-0.18,-0.5) if id==local_id else body.global_transform*Vector3(-0.18,1.3,-0.5)
	return result

func _tick_suction(delta: float) -> void:
	if rules.phase!=Rules.Phase.COLLECTION:return
	var collectors := _collector_positions()
	for p in rules.players:
		var id: int = p["id"]
		if not _alive(id) or not collectors.has(id):continue
		if not p["human"]:
			p["ai_pull"] -= delta
			if p["ai_pull"]<=0:
				p["suction"] = 1.6
				p["ai_pull"] = 1.8
		if p["suction"]>0:cloud.pull(id,collectors[id],rules.stats(id)["reach"],collectors,_clear_sight)

func _essence_collected(id: int,value: int) -> void:
	if not _authority():return
	rules.credit_essence(id,value)
	if id==local_id:_notify("+%d SOULS" % value,0.7)

func _tick_supplies(delta: float) -> void:
	for i in range(supply_nodes.size()):
		var node := supply_nodes[i]
		if supply_timers[i]>0:
			supply_timers[i] = maxf(0,supply_timers[i]-delta)
			node.visible = supply_timers[i]<=0
			continue
		node.rotate_y(delta)
		for p in rules.players:
			var id: int = p["id"]
			var body := _body(id)
			if not _alive(id) or not is_instance_valid(body) or body.position.distance_to(node.position-Vector3.UP*0.5)>1.2:continue
			if node.get_meta("kind")=="health":
				if p["hp"]>=rules.stats(id)["health"]:continue
				p["hp"] = minf(rules.stats(id)["health"],p["hp"]+30)
			else:p["reserve"] = mini(360,p["reserve"]+24)
			supply_timers[i] = 15.0
			node.hide()
			break

func _minion_count() -> int:
	var count := 0
	for body in entities.values():
		if body.get_meta("role")=="minion":count += 1
	return count

func _demo_tick(delta: float) -> void:
	_tick_fighter_states(delta)
	var motion = rails[local_id]
	var travel := Vector2(player.position.x-course.nodes[motion.origin].x,player.position.z-course.nodes[motion.origin].z).length()
	var climb: int = course.climb(motion.origin,motion.target)
	if climb>0 and travel>4.2 and motion.jumps==0:motion.jump(player)
	if climb==2 and motion.jumps==1 and player.velocity.y<5.0:motion.jump(player)
	var options: Dictionary = motion.options(course)
	for key in options:
		if course.climb(motion.target,options[key])==0:
			motion.choose(course,key)
			break
	var target: CharacterBody3D
	var distance := 28.0
	for body in entities.values():
		if body.get_meta("role")!="minion":continue
		var d := player.position.distance_to(body.position)
		if d<distance and _clear_sight(camera.global_position,body.position+Vector3.UP*0.65):
			target = body
			distance = d
	if is_instance_valid(target):
		var direction: Vector3 = camera.global_position.direction_to(target.position+Vector3.UP*0.65)
		var desired_yaw := atan2(-direction.x,-direction.z)-player.rotation.y
		desired_yaw = wrapf(desired_yaw,-PI,PI)
		motion.aim_yaw = lerpf(motion.aim_yaw,clampf(desired_yaw,-1.1,1.1),minf(1,delta*3))
		motion.pitch = lerpf(motion.pitch,asin(clampf(direction.y,-1,1)),minf(1,delta*3))
	_tick_human_motion(delta)
	_tick_bots(delta)
	_tick_auto_combat(delta)
	var p: Dictionary = rules.players[local_id]
	if p["ammo"]==0 and p["reload"]<=0:_try_reload(local_id)
	p["suction"] = 1.5
	_tick_suction(delta)
	cloud.tick(delta,_collector_positions(),true)
	_tick_supplies(delta)

func _equip_viewmodel() -> void:
	if rules.players.is_empty():return
	var model := gun.get_node_or_null("DetailedSidearm")
	if not model:return
	match rules.players[local_id]["weapon"]:
		"needle":model.scale = Vector3(0.95,1,1.25)
		"scatter":model.scale = Vector3(1.18,1.05,0.95)
		_:model.scale = Vector3.ONE

func _tick_viewmodel(delta: float) -> void:
	if rules.players.is_empty():return
	var p: Dictionary = rules.players[local_id]
	recoil = move_toward(recoil,0,delta*0.8)
	flash_left = maxf(0,flash_left-delta)
	flash.visible = flash_left>0
	gun.position.z = recoil
	gun.position.y = sin(float(Time.get_ticks_msec())*0.012)*0.002 if camera_motion else 0.0
	gun.rotation.x = -recoil*0.55
	gun.rotation.z = -sin(clampf(p["reload"]/maxf(0.1,p["reload_total"]),0,1)*PI)*0.35
	hand_amount = move_toward(hand_amount,1.0 if p["suction"]>0 and _alive(local_id) else 0.0,delta*5)
	hand_root.visible = hand_amount>0.01 and screen=="play"
	hand_root.position = Vector3(-0.18,-0.55,-0.42).lerp(Vector3(-0.18,-0.20,-0.56),hand_amount)
	hand_root.rotation.x = lerpf(0.5,-0.12,hand_amount)
	if not _alive(local_id):
		gun.hide()
		var watch: CharacterBody3D
		for other in rules.players:
			if other["id"]!=local_id and _alive(other["id"]):
				watch = _body(other["id"])
				break
		if is_instance_valid(watch):
			camera.global_position = watch.position+Vector3(0,2.6,4)
			camera.look_at(watch.position+Vector3.UP)
	else:gun.show()

func _player_names() -> Array:
	var names: Array = []
	for p in rules.players:names.append(p["name"]+ (" • YOU" if p["id"]==local_id else ""))
	return names

func _render_hud(delta: float) -> void:
	if rules.players.is_empty():return
	var p: Dictionary = rules.players[local_id]
	var stat := rules.stats(local_id)
	var choices: Dictionary = {}
	var queued := ""
	var can_drop := false
	var route_hint := ""
	if rails.has(local_id):
		var motion = rails[local_id]
		var routes: Dictionary = motion.options(course)
		for key in routes:
			var difference: int = course.climb(motion.target,routes[key])
			choices[key] = {-1:"DROP",0:"",1:"JUMP",2:"2x"}[difference]
			can_drop = can_drop or difference<0
			if routes[key]==motion.queued:queued = key
		var distance := Vector2(course.nodes[motion.target].x-player.position.x,course.nodes[motion.target].z-player.position.z).length()
		route_hint = "JUNCTION / %.0f m" % distance
		var rise: int = course.climb(motion.origin,motion.target)
		if rise>0 and distance<10 and distance>5.9:route_hint = ("DOUBLE JUMP" if rise==2 else "JUMP")+" / LEDGE %.1f m" % maxf(0,distance-6.6)
	var hit := _target_for(local_id) if _alive(local_id) and rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] else {}
	var essence_target: bool = not hit.is_empty() and hit["collider"] is Area3D
	var locked: bool = not hit.is_empty() and hit["collider"] is CharacterBody3D
	var reload_hint := ""
	if p["reload"]>0:reload_hint = "TAP IN AMBER" if not p["reload_used"] else "RELOADING"
	elif p["ammo"]==0:reload_hint = "TAP ANYWHERE / RELOAD" if p["reserve"]>0 else "FIND AMMO"
	elif essence_target:reload_hint = "HOLD AIM TO DENY / PULL TO COLLECT"
	var message := toast if toast_left>0 else ""
	if not _alive(local_id):message = "RESPAWN / %.0f" % ceilf(p["respawn"]) if p["lives"]>0 else "ELIMINATED / WATCHING THE ROUND"
	var view := {"lives":p["lives"],"souls":p["souls"],"frags":p["frags"],"remaining":rules.remaining,"round":rules.round_index,"phase_name":["COLLECTION A","SHOP","SHARED ROLL","HUNTING B","MATCH COMPLETE"][rules.phase],"health":p["hp"],"shield":p["shield"],"max_health":stat["health"],"max_shield":stat["shield"],"ammo":p["ammo"],"reserve":p["reserve"],"weapon":Rules.WEAPONS[p["weapon"]]["name"],"notice":message,"route_hint":route_hint,"routes":choices,"queued":queued,"can_drop":can_drop,"jumps":rails[local_id].jumps if rails.has(local_id) else 0,"alive":_alive(local_id),"can_collect":rules.phase==Rules.Phase.COLLECTION,"locked":locked,"essence_target":essence_target,"reload_hint":reload_hint,"reload_progress":1.0-p["reload"]/maxf(0.01,p["reload_total"]) if p["reload"]>0 else -1.0,"reload_used":p["reload_used"],"reload_success":p["reload_flash"]*2,"rewards":rules.rewards,"names":_player_names()}
	hud_ui.update_view(view,delta)
	if screen=="shop":
		var signature := str([p["souls"],p["weapon"],p["upgrades"],p["ready"]])
		if signature!=shop_signature:_show_shop()

func _pack_snapshot() -> Dictionary:
	snapshot_number += 1
	var bodies: Array = []
	for p in rules.players:
		var id: int = p["id"]
		var body := _body(id)
		if not is_instance_valid(body):continue
		bodies.append({"key":id,"role":"fighter","fid":id,"position":body.position,"velocity":body.velocity,"yaw":body.rotation.y,"air":rails[id].jumps>0 if rails.has(id) else body.get_meta("air",false),"muzzle":float(body.get_meta("muzzle",0.0)),"rail":rails[id].pack() if rails.has(id) else []})
	for key in entities:
		var body: CharacterBody3D = entities[key]
		if body.get_meta("role")!="minion":continue
		bodies.append({"key":key,"role":"minion","fid":-1,"position":body.position,"velocity":body.velocity,"yaw":body.rotation.y,"air":body.get_meta("air"),"muzzle":body.get_meta("muzzle"),"hp":body.get_meta("hp"),"rail":[]})
	var packet := {"seq":snapshot_number,"players":rules.players.duplicate(true),"phase":rules.phase,"time":rules.remaining,"round":rules.round_index,"revision":rules.revision,"wins":rules.team_rounds.duplicate(),"winner":rules.match_winner,"rewards":rules.rewards.duplicate(true),"bodies":bodies,"orbs":cloud.pack(),"supplies":supply_timers.duplicate(),"shots":shot_events.duplicate(),"notices":notices.duplicate()}
	shot_events.clear()
	notices.clear()
	return packet

func _apply_snapshot(packet: Dictionary) -> void:
	if not net.in_match or net.hosting or int(packet.get("seq",-1))<=last_snapshot:return
	last_snapshot = int(packet["seq"])
	var old_round := rules.round_index
	rules.players.assign(packet["players"])
	rules.phase = int(packet["phase"])
	rules.remaining = float(packet["time"])
	rules.round_index = int(packet["round"])
	rules.revision = int(packet["revision"])
	rules.team_rounds = packet["wins"]
	rules.match_winner = int(packet["winner"])
	rules.rewards.assign(packet["rewards"])
	if old_round!=rules.round_index:
		for body in entities.values():
			body.collision_layer = 0
			body.queue_free()
		entities.clear()
		enemies.clear()
		cloud.clear()
	var seen: Array[int] = []
	for record in packet["bodies"]:
		var key := int(record["key"])
		if key==local_id:
			var motion = rails[local_id]
			if record["rail"].size()==8 and int(record["rail"][7])>=critical_sequence:
				var saved_yaw: float = motion.aim_yaw
				var saved_pitch: float = motion.pitch
				motion.unpack(record["rail"])
				motion.aim_yaw = saved_yaw
				motion.pitch = saved_pitch
			var error := player.position.distance_to(record["position"])
			if error>3:
				player.position = record["position"]
				player.velocity = record["velocity"]
			elif error>0.6:player.position = player.position.lerp(record["position"],0.5)
			player.collision_layer = _fighter_layer(local_id) if _alive(local_id) else 0
			continue
		seen.append(key)
		if not entities.has(key):_create_entity(key,record["role"],_nearest_node(record["position"]),int(record["fid"]))
		var body: CharacterBody3D = entities[key]
		body.set_meta("network_pos",record["position"])
		body.set_meta("network_yaw",record["yaw"])
		body.set_meta("air",record["air"])
		body.set_meta("muzzle",record["muzzle"])
		body.collision_mask = 0
		var id := int(record["fid"])
		if id>=0:
			if not _alive(id) and body.visible:_create_corpse(body)
			body.visible = _alive(id)
			body.collision_layer = _fighter_layer(id) if _alive(id) else 0
		else:body.set_meta("hp",record["hp"])
	for key in entities.keys():
		if key not in seen:
			if rules.phase==Rules.Phase.COLLECTION and old_round==rules.round_index:_create_corpse(entities[key])
			_remove_entity(key)
	cloud.apply_snapshot(packet["orbs"])
	for i in range(mini(supply_timers.size(),packet["supplies"].size())):
		supply_timers[i] = float(packet["supplies"][i])
		supply_nodes[i].visible = supply_timers[i]<=0
	for id in packet["shots"]:
		if id==local_id:
			shot_sound.play()
			recoil = 0.065
			flash_left = 0.05
	for message in packet["notices"]:
		if int(message[0])==local_id:_notify(message[1])
	_equip_viewmodel()
	_handle_phase_change()

func _client_tick(delta: float) -> void:
	rules.remaining = maxf(0,rules.remaining-delta)
	if rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] and _alive(local_id):
		var event: String = rails[local_id].step(player,course,delta)
		if event=="missed":_notify("MISSED LANDING")
		camera.position = Vector3(0,1.55,0)
		camera.rotation = Vector3(rails[local_id].pitch,rails[local_id].aim_yaw,0)
		_sync_legacy_motion()
	aim_send_left -= delta
	if aim_send_left<=0 and rails.has(local_id):
		net.send_action("aim",Vector2(rails[local_id].aim_yaw,rails[local_id].pitch))
		aim_send_left = 0.05
	for body in entities.values():
		if body.has_meta("network_pos"):
			body.position = body.position.lerp(body.get_meta("network_pos"),minf(1,delta*18))
			body.rotation.y = lerp_angle(body.rotation.y,float(body.get_meta("network_yaw")),minf(1,delta*18))
		var active: bool = rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] and body.visible
		if body.has_meta("animation"):body.get_meta("animation").active = active
		art.animate_enemy(body,"Jump" if body.get_meta("air",false) else "Run")
		var muzzle := maxf(0,float(body.get_meta("muzzle",0))-delta)
		body.set_meta("muzzle",muzzle)
		body.get_node("MuzzleFlash").visible = muzzle>0
	cloud.tick(delta,{},false)
	var p: Dictionary = rules.players[local_id]
	if p["reload"]>0:p["reload"] = maxf(0.001,p["reload"]-delta)
	p["reload_flash"] = maxf(0,p["reload_flash"]-delta)
	p["suction"] = maxf(0,p["suction"]-delta)
	p["respawn"] = maxf(0,p["respawn"]-delta)
