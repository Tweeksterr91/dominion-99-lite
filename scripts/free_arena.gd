extends "res://scripts/souls_arena.gd"
const HEROES=preload("res://scripts/hero_catalog.gd")
const CARBON=preload("res://assets/models/carbon_carbine.glb")
const SNIPER=preload("res://assets/models/warden_sniper.glb")
const Inventory=preload("res://scripts/weapon_inventory.gd")
const DOUBLE=preload("res://assets/models/double_barrel.glb")
const SCYTHE=preload("res://assets/models/plasma_scythe.glb")
const FreeMotion=preload("res://scripts/free_motion.gd")
const FreeMap=preload("res://scripts/free_map.gd")
const FreeHUD=preload("res://scripts/free_hud.gd")
const Brain=preload("res://scripts/free_brain.gd")
const Projectiles=preload("res://scripts/arena_projectiles.gd")
const Weather=preload("res://scripts/arena_weather.gd")
const PUMP=preload("res://assets/models/pump_shotgun.glb")
const BOT_MOVE_SPEED := 3.2
const MINION_SPEED_MULTIPLIER := .85
const SHOT_VOLUME_SCALE := .5
var touch_auto := false
var auto_heartbeat := 0.0
const LOCK_TIME := .7
var lock_states: Dictionary={}
var touch_lock := false
var lock_heartbeat := 0.0
var mouse_lock := false
var match_seed := 99
var conditions: Dictionary={}
var prelude_left := 0.0
var weather_node: Node3D
var sun: DirectionalLight3D
var projectiles: Node3D
var brains: Dictionary={}
var enemy_motions: Dictionary={}
var weapon_frame: CanvasLayer
var hero_id := "rook"
var hero_careers: Dictionary={}
var hero_page := 0
var hero_mission := 0
var hero_match_id := "rook"
var career_recorded := false
var career_passed := false
var spawns_synced := false
var pending_hit_directions: Dictionary={}
var carbon_rig: Node3D
var sniper_rig: Node3D
var double_rig: Node3D
var scythe_rig: Node3D
var swing_age := 99.0
var wheel_mouse_mode := Input.MOUSE_MODE_VISIBLE
var shotgun_rig: Node3D
var pump_sound: AudioStreamPlayer
var distant_shot: AudioStreamPlayer3D
var normal_shot: AudioStream
var pump_age := 99.0
var pump_sound_played := true
var keyboard_used := false
var keyboard_left := 0.0
var touch_move := Vector2.ZERO
var mouse_firing := false
var mouse_fire_left := 0.0
var lens: Node
var visual_effects: Dictionary={"bloom":true,"dof":true,"chromatic":true,"motion":true}
func _ready() -> void:
	super._ready()
	var previous:=hand_root
	camera.remove_child(previous);previous.queue_free()
	hand_root=Node3D.new();camera.add_child(hand_root);hand_root.hide()
	cloud.automatic_collection=true
	pump_sound=AudioStreamPlayer.new();pump_sound.stream=load("res://assets/audio/shotgun_pump.wav");add_child(pump_sound)
	distant_shot=AudioStreamPlayer3D.new();distant_shot.stream=load("res://assets/audio/shotgun_shot.wav");distant_shot.max_distance=45;distant_shot.unit_size=12;add_child(distant_shot)
	weapon_frame=preload("res://scripts/viewmodel_frame.gd").new();add_child(weapon_frame);weapon_frame.configure(camera)
	lens=preload("res://scripts/soft_lens.gd").new();add_child(lens);lens.configure(camera);lens.apply(visual_effects)
	_update_audio()
func _create_hud() -> CanvasLayer:return FreeHUD.new()
func _load_settings() -> void:
	super._load_settings()
	for key in visual_effects:visual_effects[key]=bool(settings.get_value("visuals",key,true))
	if is_instance_valid(lens):lens.apply(visual_effects)
	hero_id=str(settings.get_value("heroes","selected","rook"))
	if HEROES.find(hero_id)["id"]!=hero_id:hero_id="rook"
	hero_careers=settings.get_value("heroes","careers",{})
	for hero in HEROES.roster():
		if not hero_careers.has(hero["id"]):hero_careers[hero["id"]]=HEROES.empty_career()
	if not settings.has_section_key("heroes","careers"):
		hero_careers["rook"]["unlocked"]=campaign_unlocked
		hero_careers["rook"]["cleared"]=range(maxi(0,campaign_unlocked-1))
	campaign_unlocked=int(hero_careers[hero_id]["unlocked"]);hero_page=int(HEROES.find(hero_id)["index"])/8
	if int(settings.get_value("audio","arena_mix",0))<1:
		if is_equal_approx(sound_volume,.8):sound_volume=.7
		if is_equal_approx(music_volume,.35):music_volume=.7
		settings.set_value("audio","volume",sound_volume);settings.set_value("audio","music",music_volume);settings.set_value("audio","arena_mix",1);settings.save("user://dominion_settings.cfg")
func _load_controller_settings() -> void:
	super._load_controller_settings()
	var previous: Dictionary=pad_input.bindings.duplicate()
	var saved: Dictionary=settings.get_value("controller","bindings",{})
	pad_input.bindings=Controller.FREE_DEFAULTS.duplicate()
	if int(settings.get_value("controller","binding_layout",2))>=3:
		for action in Controller.FREE_DEFAULTS:
			if saved.has(action) and int(saved[action]) in [0,1,2,3,6,7,8,9,10]:pad_input.bind(action,int(saved[action]))
	else:
		for action in ["jump","reload","pause"]:
			var button: int=int(previous.get(action,Controller.FREE_DEFAULTS[action]))
			if button!=JOY_BUTTON_LEFT_SHOULDER:pad_input.bind(action,button)
		if saved.has("lock"):pad_input.bind("lock",int(saved["lock"]))
func _make_player() -> void:
	super._make_player()
	camera.far=270
	flash.layers=2
	for child in camera.get_children():
		if child is OmniLight3D:child.light_energy=.28
	shotgun_rig=PUMP.instantiate();gun.add_child(shotgun_rig);_layer_weapon(shotgun_rig)
	double_rig=DOUBLE.instantiate();gun.add_child(double_rig);_layer_weapon(double_rig);double_rig.hide()
	scythe_rig=SCYTHE.instantiate();gun.add_child(scythe_rig);_layer_weapon(scythe_rig);scythe_rig.hide()
	carbon_rig=CARBON.instantiate();gun.add_child(carbon_rig);_layer_weapon(carbon_rig);carbon_rig.hide()
	sniper_rig=SNIPER.instantiate();gun.add_child(sniper_rig);_layer_weapon(sniper_rig);sniper_rig.hide()
func _layer_weapon(model: Node3D) -> void:
	for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.layers=2;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _make_audio() -> void:
	super._make_audio();normal_shot=shot_sound.stream
func _start_match(size: int,map_id: int,seed_value: int,human_ids: Array,lan := false,attract := false) -> void:
	match_seed=seed_value;conditions=Weather.roll(seed_value,map_id);prelude_left=0;spawns_synced=false;career_recorded=false
	super._start_match(size,map_id,seed_value,human_ids,lan,attract)
	pad_input.free_movement=true
	if not lan and not attract:rules.players[0]["name"]=HEROES.find(hero_id)["name"]
	if not attract:
		prelude_left=6
		_show("conditions",{"conditions":conditions})
func _build_course() -> void:
	if is_instance_valid(course_root):course_root.free()
	if environment==null:
		var world:=WorldEnvironment.new();environment=Environment.new();world.environment=environment;add_child(world)
		sun=DirectionalLight3D.new();sun.shadow_enabled=true;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL;sun.directional_shadow_max_distance=30;add_child(sun)
	if not is_instance_valid(weather_node):weather_node=Weather.new();add_child(weather_node)
	course=FreeMap.new();course.layout_seed=match_seed;course_root=course.build(self,biome)
	weather_node.apply(conditions,environment,sun,camera)
	if not is_instance_valid(projectiles):projectiles=Projectiles.new();add_child(projectiles);projectiles.impact.connect(_projectile_impact)
	projectiles.clear()
func _setup_round() -> void:
	shot_sound.stop();reload_lower_sound.stop();reload_raise_sound.stop()
	reload_lowering=0;seen_reload_cycle=0;seen_reload_finish=0;pump_age=99;pump_sound_played=true
	for body in entities.values():body.collision_layer=0;body.queue_free()
	entities.clear();enemies.clear()
	for brain in brains.values():
		if is_instance_valid(brain) and brain.get_parent()==player:
			if is_instance_valid(brain.agent):brain.agent.queue_free()
			brain.queue_free()
	brains.clear();enemy_motions.clear();rails.clear();lock_states.clear();touch_lock=false;mouse_lock=false;touch_auto=false
	for node in supply_nodes:node.queue_free()
	supply_nodes.clear();supply_timers.clear()
	for body in corpses:
		if is_instance_valid(body):body.queue_free()
	corpses.clear();corpse_lives.clear();cloud.clear();projectiles.clear();next_minion=100
	for p in rules.players:
		var id: int=p["id"];var stat:=rules.stats(id)
		p.merge({"hp":float(stat["health"]),"shield":float(stat["shield"]),"ammo":int(stat["mag"]),"reserve":-1 if Inventory.infinite(p["weapon"]) else 72,"reload":0.0,"reload_total":float(stat["reload"]),"reload_used":false,"reload_flash":0.0,"fire_cd":0.0,"hit_age":10.0,"respawn":0.0,"invul":2.0,"suction":0.0,"deny_id":-1,"deny_dwell":0.0,"ai_pull":0.0,"shop_done":false,"damage_flash":0.0,"damage_edges":Vector4.ZERO,"manual_left":0.0,"touch_auto_left":0.0,"reload_cycle":0,"reload_finish":0},true)
		Inventory.reset(p)
		var lane: int=id if p["team"]==0 else id-selected_size
		var spawn: int=_choose_spawn_node()
		var body:=player if id==local_id else _create_entity(id,"fighter",spawn,id)
		var motion:=FreeMotion.new();motion.reset(body,course,spawn);rails[id]=motion
		body.collision_layer=_fighter_layer(id);body.collision_mask=1
		if not p["human"]:_attach_brain(body,id,motion)
	camera.position=Vector3(0,1.75,0);camera.rotation=Vector3.ZERO;_adapt_orientation();gun.show()
	for index in range(8):
		var node: int=[0,2,4,6,8,10,12,14][index];var kind: String="health" if index%3==0 else "ammo"
		var item:=art.build_pickup(self,course.nodes[node]+Vector3.UP*.5,kind);item.set_meta("kind",kind);supply_nodes.append(item);supply_timers.append(0.0)
	if _authority():
		for i in range(6):_spawn_minion([0,2,4,6,17,21][i],["scavenger","stalker","brute"][i%3])
	minion_spawn_left=2.5;treasure_spawn_left=combat_random.randf_range(27.5,62.5);_equip_viewmodel()
func _attach_brain(body: CharacterBody3D,key: int,motion: RefCounted) -> void:
	var brain:=Brain.new();body.add_child(brain);brains[key]=brain;enemy_motions[key]=motion
func _create_entity(key: int,role: String,node: int,fighter := -1,subtype := "scavenger") -> CharacterBody3D:
	var body:=super._create_entity(key,role,node,fighter,subtype)
	body.collision_mask=1;body.floor_snap_length=.4;body.floor_max_angle=deg_to_rad(44)
	if role=="minion":body.get_node("MuzzleFlash").material_override=art.materials["green"]
	if role=="fighter":_sync_actor_weapon(body,fighter)
	if role=="minion" and _authority():
		var motion:=FreeMotion.new();motion.reset(body,course,node);_attach_brain(body,key,motion)
	return body
func _remove_entity(key: int) -> void:
	brains.erase(key);enemy_motions.erase(key);super._remove_entity(key)
func _adapt_orientation() -> void:
	super._adapt_orientation()
	_close_wheel(false)
	_set_touch_auto(false)
	if is_instance_valid(hud_ui) and is_instance_valid(hud_ui.lock_button):hud_ui.lock_button.release()
	if is_instance_valid(hud_ui) and is_instance_valid(hud_ui.stick) and hud_ui.stick.finger>=0:hud_ui.stick.release()
	if is_instance_valid(weapon_frame):weapon_frame.sync()

func _show(value: String,context: Dictionary={}) -> void:
	if value!="play":
		_close_wheel(false)
		_set_touch_auto(false)
		mouse_firing=false;mouse_lock=false;touch_lock=false
		if is_instance_valid(pad_input):pad_input.stop_locking()
		if not demo:_request_action("lock",false)
		if not demo:_request_action("fire",false)
	if value!="play" and is_instance_valid(pad_input):pad_input.stop_moving()
	if value!="play" and rails.has(local_id) and not demo:_request_action("move",Vector2.ZERO)
	super._show(value,context)
func _ui_action(kind: String,value: Variant) -> void:
	if kind=="visuals":_show_visuals();return
	if kind=="visual_back":_show_options();return
	if kind=="visual_motion":camera_motion=not camera_motion;_save_settings();_show_visuals();return
	if kind=="visual_toggle" and visual_effects.has(str(value)):
		visual_effects[str(value)]=not visual_effects[str(value)];lens.apply(visual_effects);_save_settings();_show_visuals();return
	if kind=="hero_current":_show_hero_detail();return
	if kind in ["campaign","hero_roster"]:_show_heroes();return
	if kind=="hero_back":_show("main");return
	if kind=="hero_page":hero_page=posmod(int(value),3);_show_heroes();return
	if kind=="hero_select":hero_id=HEROES.find(str(value))["id"];campaign_unlocked=int(hero_careers[hero_id]["unlocked"]);_save_settings();_show_hero_detail();return
	if kind in ["hero_start","campaign_start"]:_start_hero_mission(int(value));return
	if kind=="results_continue" and campaign_match:
		if career_passed and hero_mission<4:_start_hero_mission(hero_mission+1)
		else:_show_hero_detail()
		return
	if kind=="wheel":
		if value:_open_wheel()
		else:_close_wheel(true)
		return
	if kind in ["reverse","suction","essence"]:return
	if kind=="lock":touch_lock=bool(value);_request_action("lock",value);return
	if kind=="move":
		touch_move=value;keyboard_used=false;_request_action("move",value)
	else:super._ui_action(kind,value)
func _controller_command(kind: String,value: Variant) -> void:
	if kind=="wheel_cancel":_close_wheel(false);return
	if kind=="wheel":
		if value:_open_wheel()
		else:_close_wheel(true)
		return
	if kind=="wheel_aim":
		if _wheel_open():hud_ui.wheel.point(value)
		return
	if kind=="wheel_cycle":
		if _wheel_open():hud_ui.wheel.cycle(int(value))
		return
	if kind in ["reverse","suction","essence"]:return
	if kind=="lock":
		if screen=="play" or value==false:_request_action(kind,value)
		return
	if kind=="move":
		keyboard_used=false
		if screen=="play" or value==Vector2.ZERO:_request_action("move",value)
		return
	super._controller_command(kind,value)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode==KEY_TAB and not event.echo and (screen=="play" or _wheel_open()):
		if event.pressed:_open_wheel()
		else:_close_wheel(true)
		get_viewport().set_input_as_handled();return
	if screen=="play" and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		pad_input.set_active(false)
		if _wheel_open() and event is InputEventScreenDrag:hud_ui.wheel.select_point(event.position)
		if hud_ui.wheel_button.handle(event):get_viewport().set_input_as_handled();return
	if _wheel_open() and not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		if event is InputEventMouseMotion:hud_ui.wheel.select_point(event.position)
		if event is InputEventScreenTouch and event.pressed:hud_ui.wheel.select_point(event.position)
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:_close_wheel(false)
		get_viewport().set_input_as_handled();return
	if event is InputEventMouse or event is InputEventKey:_set_touch_auto(false)
	var ending_touch: bool=event is InputEventScreenTouch and not event.pressed and event.index==touch_aim
	if event is InputEventKey and event.keycode==KEY_Q:return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and screen=="play":
		mouse_lock=event.pressed;_request_action("lock",event.pressed);get_viewport().set_input_as_handled();return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and screen=="play":
		mouse_firing=event.pressed;_request_action("fire",event.pressed);get_viewport().set_input_as_handled();return
	if is_instance_valid(hud_ui) and screen=="play" and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		pad_input.set_active(false)
		if hud_ui.lock_button.handle(event):get_viewport().set_input_as_handled();return
		if hud_ui.stick.handle(event):get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT] and screen=="play":keyboard_used=true;get_viewport().set_input_as_handled();return
	super._input(event)
	if ending_touch:_set_touch_auto(false)
	elif screen=="play" and event is InputEventScreenTouch and event.pressed and touch_aim==event.index:_set_touch_auto(true)
	elif screen=="play" and event is InputEventScreenDrag and touch_aim==event.index:_set_touch_auto(true)
func _look(change: Vector2) -> void:
	if not rails.has(local_id):return
	var motion=rails[local_id]
	motion.aim_yaw=wrapf(motion.aim_yaw-change.x*aim_sensitivity,-PI,PI)
	motion.pitch=clampf(motion.pitch-change.y*aim_sensitivity*(-1 if invert_aim else 1),-1.25,1.25)
	player.rotation.y=motion.aim_yaw;camera.rotation=Vector3(motion.pitch,0,0)
func _request_action(kind: String,value: Variant=null) -> void:
	if kind in ["reverse","suction","essence"]:return
	if kind=="lock" and not demo:_set_lock_input(local_id,bool(value))
	if kind=="move" and not demo and rails.has(local_id) and value is Vector2:rails[local_id].set_move(value)
	super._request_action(kind,value)
func _apply_action(id: int,kind: String,value: Variant,sequence: int) -> void:
	if not _authority() or id not in humans or not rails.has(id):return
	if kind in ["reverse","suction","essence"]:return
	if kind=="equip":
		if value is String and prelude_left<=0 and rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] and _alive(id):_switch_weapon(id,value)
		return
	if kind=="autofire":
		if value is bool and (not value or (prelude_left<=0 and rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] and _alive(id))):rules.players[id]["touch_auto_left"]=.5 if value else 0.0
		return
	if kind=="lock":
		if value is bool and (value==false or (prelude_left<=0 and rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] and _alive(id))):_set_lock_input(id,value)
		return
	if kind in ["move","aim"]:
		if not value is Vector2 or not is_finite(value.x) or not is_finite(value.y):return
		rails[id].last_input=sequence
		if kind=="move":
			if value==Vector2.ZERO or (rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] and _alive(id) and prelude_left<=0):rails[id].set_move(value.limit_length(1))
		else:rails[id].aim_yaw=wrapf(value.x,-PI,PI);rails[id].pitch=clampf(value.y,-1.25,1.25)
		return
	if prelude_left>0 and kind not in ["aim","move"] and not (kind=="fire" and value==false):return
	if kind=="turn":return
	super._apply_action(id,kind,value,sequence)
func _sync_legacy_motion() -> void:pass
func _tick_human_motion(delta: float) -> void:
	for id in humans:
		if not _alive(id) or not rails.has(id):continue
		var body:=_body(id);var event: String=rails[id].step(body,course,delta)
		if event=="fallen":_fall_fighter(id)
		if id==local_id:camera.position=Vector3(0,1.75,0);camera.rotation=Vector3(rails[id].pitch,0,0)
		else:_animate_actor(body,rails[id])
func _fall_fighter(id: int) -> void:
	var p: Dictionary=rules.players[id]
	if not _alive(id):return
	if demo:rails[id].reset(_body(id),course,10 if p["team"]==0 else 14);return
	p["invul"]=0;_damage_fighter(id,10000)
func _animate_actor(body: CharacterBody3D,motion: RefCounted) -> void:
	var moving:=Vector2(body.velocity.x,body.velocity.z).length()>.15
	var airborne: bool=not body.is_on_floor()
	body.set_meta("air",airborne)
	if body.has_meta("animation"):body.get_meta("animation").active=body.visible
	art.animate_enemy(body,"Jump" if airborne else "Run" if moving else "Idle")
	var muzzle:=maxf(0,float(body.get_meta("muzzle",0))-1.0/60);body.set_meta("muzzle",muzzle)
	body.get_node("MuzzleFlash").visible=muzzle>0
	_tick_actor_weapon(body,1.0/60)
func _respawn_fighter(id: int) -> void:
	var p: Dictionary=rules.players[id];var stat:=rules.stats(id)
	p["hp"]=float(stat["health"]);p["shield"]=float(stat["shield"]);p["ammo"]=int(stat["mag"]);p["reload"]=0.0;p["invul"]=2.0
	var body:=_body(id)
	if not is_instance_valid(body):return
	rails[id].reset(body,course,_choose_spawn_node());body.collision_layer=_fighter_layer(id);body.show();Inventory.store(p)
	if id==local_id:camera.position=Vector3(0,1.75,0);camera.rotation=Vector3.ZERO;gun.show()
func _replace_departed(id: int) -> void:
	if id<0 or id>=rules.players.size():return
	humans.erase(id);rules.players[id]["human"]=false;rules.players[id]["name"]="BOT %d" % (id+1)
	if rails.has(id):rails[id].set_move(Vector2.ZERO);_attach_brain(_body(id),id,rails[id])
	_notify("A disconnected player is now controlled by a bot.",4)
func _physics_process(delta: float) -> void:
	if is_instance_valid(lens):lens.step(delta,not app_paused and (screen=="play" or demo))
	if app_paused:return
	if running and is_instance_valid(course_root) and course.nav_ready and not spawns_synced and _authority():_sync_random_spawns()
	if _wheel_open() and (not _alive(local_id) or rules.phase not in [Rules.Phase.COLLECTION,Rules.Phase.HUNT]):_close_wheel(false)
	if prelude_left>0 and not demo:
		prelude_left=maxf(0 if _authority() else .02,prelude_left-delta)
		if _authority() and prelude_left<=0 and not course.nav_ready:prelude_left=.02
		if _authority() and net.in_match:
			snapshot_left-=delta
			if snapshot_left<=0:net.publish(_pack_snapshot());snapshot_left=.05
		if prelude_left<=0:_show("play");phase_wall_time=Time.get_ticks_usec()
		_render_hud(delta)
		return
	if screen=="play" and not demo and not _wheel_open():
		if touch_auto:
			if touch_aim<0 or pad_input.active:_set_touch_auto(false)
			else:
				auto_heartbeat-=delta
				if auto_heartbeat<=0:_request_action("autofire",true);auto_heartbeat=.18
		lock_heartbeat-=delta
		if (touch_lock or mouse_lock) and lock_heartbeat<=0:_request_action("lock",true);lock_heartbeat=.18
		if mouse_firing:
			mouse_fire_left-=delta
			if mouse_fire_left<=0:_request_action("fire",true);mouse_fire_left=.18
		keyboard_left-=delta
		if keyboard_left<=0:
			if keyboard_used:
				var movement:=Vector2(float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
				_request_action("move",movement.limit_length(1))
			elif not pad_input.active and touch_move!=Vector2.ZERO:_request_action("move",touch_move)
			keyboard_left=1.0/30
	var paused: bool=not demo and not net.in_match and screen in ["paused","options","credits","controller_options","bind_controller","controller_help"]
	if not paused:projectiles.tick(delta,_authority())
	if not paused and running and rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT]:_tick_locks(delta)
	super._physics_process(delta)
func _handle_phase_change() -> void:
	if prelude_left>0:return
	var before: int=phase_revision
	var ending: bool=rules.phase==Rules.Phase.RESULTS and rules.revision!=before
	var career_match: bool=campaign_match
	if ending:campaign_match=false
	if _authority() and before!=rules.revision and rules.phase==Rules.Phase.SHOP:
		for orb in cloud.orbs.values():
			if int(orb["owner"])>=0:rules.credit_essence(int(orb["owner"]),int(orb["value"]))
	super._handle_phase_change()
	campaign_match=career_match
	if ending and not demo:_show_match_results()
	if before!=phase_revision and rules.phase not in [Rules.Phase.COLLECTION,Rules.Phase.HUNT]:projectiles.clear();lock_states.clear()
	if before!=phase_revision and rules.phase==Rules.Phase.COLLECTION:_notify("COLLECTION / Kill minions. Their souls fly to the killer.",5)
func _tick_bots(delta: float) -> void:
	for key in entities.keys():
		if not entities.has(key) or not brains.has(key):continue
		var body: CharacterBody3D=entities[key]
		var fighter:=int(body.get_meta("fighter"))
		if fighter>=0 and (rules.players[fighter]["human"] or not _alive(fighter)):continue
		var motion=enemy_motions[key]
		var target:=_ai_target(body)
		var goal: Vector3=body.get_meta("wander_goal",course.nodes[(key*7)%course.nodes.size()])
		if is_instance_valid(target):
			var diff:=target.position-body.position
			if fighter>=0:_ai_choose_weapon(fighter,diff.length())
			motion.aim_yaw=_turn_toward(motion.aim_yaw,atan2(-diff.x,-diff.z),deg_to_rad(65 if fighter>=0 else 50)*delta)
			if body.get_meta("subtype","")=="treasure":
				var farthest: Vector3=course.nodes[0]
				for node in course.nodes:
					if node.distance_squared_to(target.position)>farthest.distance_squared_to(target.position):farthest=node
				goal=farthest
			elif diff.length()>(2.1 if fighter>=0 and Inventory.melee(rules.players[fighter]["weapon"]) else 10.0) or not _clear_sight(body.position+Vector3.UP*1.3,target.position+Vector3.UP):goal=target.position
			else:
				var side:=Vector3(-diff.z,0,diff.x).normalized()
				goal=body.position+side*sin(float(Time.get_ticks_msec())*.001+key)*2.5
		else:
			if body.position.distance_to(goal)<1.8:goal=course.nodes[combat_random.randi_range(0,course.nodes.size()-1)];body.set_meta("wander_goal",goal)

		var direction: Vector3=brains[key].steer(body,motion,goal,delta)
		if not is_instance_valid(target) and direction.length()>.2:motion.aim_yaw=_turn_toward(motion.aim_yaw,atan2(-direction.x,-direction.z),deg_to_rad(65 if fighter>=0 else 50)*delta)
		var local: Vector3=Basis(Vector3.UP,motion.aim_yaw).inverse()*direction
		motion.set_move(Vector2(local.x,local.z))
		var speed: float=float(Minions.TYPES[body.get_meta("subtype","scavenger")]["speed"])*MINION_SPEED_MULTIPLIER if fighter<0 else BOT_MOVE_SPEED
		if brains[key].jumping_left>0:speed=maxf(speed,6.0)
		var event: String=motion.step(body,course,delta,speed)
		if event=="fallen":
			if fighter>=0:_fall_fighter(fighter)
			else:_remove_entity(key)
			continue
		_animate_actor(body,motion)
		if is_instance_valid(target):
			if fighter>=0:_ai_fire(body,target,fighter,delta)
			else:_minion_fire(body,target,delta)
	if rules.phase==Rules.Phase.COLLECTION:
		minion_spawn_left-=delta;treasure_spawn_left-=delta
		if treasure_spawn_left<=0:_spawn_minion([0,2,4,6][combat_random.randi_range(0,3)],"treasure");treasure_spawn_left=INF
		if _minion_count()<6 and minion_spawn_left<=0:_spawn_minion(combat_random.randi_range(0,7));minion_spawn_left=2.5
func _ai_target(body: CharacterBody3D) -> CharacterBody3D:
	var fighter:=int(body.get_meta("fighter"));var result: CharacterBody3D;var nearest:=10000.0
	for other in entities.values()+[player]:
		if other==body or not is_instance_valid(other):continue
		var other_id: int=local_id if other==player else int(other.get_meta("fighter"))
		var valid: bool=false
		if fighter<0:valid=other_id>=0 and _alive(other_id)
		elif rules.phase==Rules.Phase.COLLECTION:valid=other!=player and other.get_meta("role")=="minion"
		else:valid=other_id>=0 and _alive(other_id) and rules.can_harm(fighter,other_id)
		if not valid:continue
		var distance:=body.position.distance_squared_to(other.position)
		if distance<nearest:nearest=distance;result=other
	return result
func _ai_fire(body: CharacterBody3D,target: CharacterBody3D,id: int,_delta: float) -> void:
	var p: Dictionary=rules.players[id]
	if p["ammo"]==0 and p["reload"]<=0:_try_reload(id)
	if not _can_shoot(id) or body.position.distance_to(target.position)>(3.0 if Inventory.melee(p["weapon"]) else 28.0) or not _clear_sight(body.position+Vector3.UP*1.5,target.position+Vector3.UP):return
	var aim:=target.position+Vector3.UP*(.8 if target.get_meta("role","")=="minion" else 1.4)
	if not _facing_target(body,aim):return
	_fire_weapon(id,aim)
func _minion_fire(body: CharacterBody3D,target: CharacterBody3D,delta: float) -> void:
	var definition: Dictionary=Minions.TYPES[body.get_meta("subtype")]
	var timer:=float(body.get_meta("attack"))-delta;body.set_meta("attack",timer)
	if timer>0 or definition["damage"]<=0 or body.position.distance_to(target.position)>22 or not _clear_sight(body.position+Vector3.UP*.9,target.position+Vector3.UP):return
	body.set_meta("attack",definition["interval"]*1.25);body.set_meta("muzzle",.12)
	var origin: Vector3=body.get_node("MuzzleFlash").global_position
	if not _facing_target(body,target.position+Vector3.UP*1.2):return
	var direction:=origin.direction_to(target.position+Vector3.UP*1.2)
	projectiles.spawn(origin,direction*22,-1,float(definition["damage"]),1|4|16|32,Color("a3e876"),body.get_rid(),1.5)
	if net.in_match and net.hosting:shot_events.append(int(body.get_meta("key")))
	_play_distant(origin,false)
func _target_for(id: int) -> Dictionary:
	var body:=_body(id)
	if not is_instance_valid(body):return {}
	var basis:=Basis.from_euler(Vector3(rails[id].pitch,rails[id].aim_yaw,0)) if rails.has(id) else body.global_basis
	var origin:=body.position+Vector3.UP*1.65
	if id==local_id:origin=camera.global_position;basis=camera.global_basis
	var query:=PhysicsRayQueryParameters3D.create(origin,origin-basis.z*float(Rules.WEAPONS[rules.players[id]["weapon"]].get("range",40.0)),_ray_mask(id),[body.get_rid()]);query.collide_with_areas=true;query.hit_from_inside=true
	return get_world_3d().direct_space_state.intersect_ray(query)
func _tick_auto_combat(delta: float) -> void:
	for id in humans:
		if not _alive(id):continue
		var p: Dictionary=rules.players[id];var hit:=_target_for(id)
		if p["manual_left"]>0:
			if not hit.is_empty() and hit["collider"] is Area3D and cloud.orbs.get(int(hit["collider"].get_meta("orb",-1)),{}).get("gold",false):continue
			if _can_shoot(id):_fire_weapon(id)
			continue
		if not demo and float(p.get("touch_auto_left",0))<=0:continue
		if hit.is_empty():p["deny_id"]=-1;p["deny_dwell"]=0.0;continue
		var target: Object=hit["collider"]
		if target is Area3D and target.has_meta("orb"):
			var orb:=int(target.get_meta("orb"))
			if cloud.orbs.get(orb,{}).get("gold",false) or p["suction"]>0:continue
			if p["deny_id"]!=orb:p["deny_id"]=orb;p["deny_dwell"]=0.0
			p["deny_dwell"]+=delta
			if p["deny_dwell"]>=.55 and _can_shoot(id):_fire_weapon(id)
		elif target is CharacterBody3D and _can_shoot(id):
			if not Inventory.melee(p["weapon"]) or _body(id).position.distance_to(target.position)<=3.0:_fire_weapon(id)
func _fire_weapon(id: int,aim := Vector3.ZERO) -> void:
	if not _can_shoot(id):return
	if Inventory.melee(rules.players[id]["weapon"]):_melee_swing(id);return
	var body:=_body(id);var data: Dictionary=Rules.WEAPONS[rules.players[id]["weapon"]]
	var basis:=Basis.from_euler(Vector3(rails[id].pitch,rails[id].aim_yaw,0)) if rails.has(id) else body.global_basis
	var origin: Vector3=body.get_node("MuzzleFlash").global_position if id!=local_id else camera.global_position
	if id==local_id:
		basis=camera.global_basis
		var hit:=_target_for(id)
		aim=hit.get("position",camera.global_position-camera.global_basis.z*float(data.get("range",38.0)))
		origin=gun.global_transform*_muzzle_offset(rules.players[id]["weapon"])
		if is_instance_valid(weapon_frame):origin=weapon_frame.muzzle_world(origin)
		var blocked:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,origin,1))
		if not blocked.is_empty():origin=blocked["position"]+Vector3(blocked["normal"])*.04
	var state: Dictionary=lock_states.get(id,{})
	if float(state.get("charge",0))>=LOCK_TIME and float(state.get("ttl",0))>0:
		var target:=_lock_body(int(state["target"]))
		if is_instance_valid(target):aim=_lock_point(target)
	if aim!=Vector3.ZERO:basis=Basis.looking_at((aim-origin).normalized(),Vector3.UP)
	_spend_shot(id)
	var pellets:=int(data.get("pellets",1));var spread:=float(rules.stats(id)["spread"])
	for i in range(pellets):
		var direction:=(-basis.z+basis.x*combat_random.randf_range(-spread,spread)+basis.y*combat_random.randf_range(-spread,spread)).normalized()
		projectiles.spawn(origin,direction*float(data.get("speed",75)),id,float(rules.stats(id)["damage"]),_ray_mask(id),Color("83c5ff") if rules.players[id]["team"]==0 else Color("ff8f7c"),body.get_rid(),float(data.get("life",.65)))
	if id!=local_id:_play_weapon_audio(origin,rules.players[id]["weapon"])
func _projectile_impact(bullet: Dictionary,hit: Dictionary) -> void:
	var target: Object=hit["collider"]
	if target is Node and target.is_queued_for_deletion():return
	var owner_id:=int(bullet["owner"])
	if target is Area3D and target.has_meta("orb"):
		if owner_id>=0:cloud.destroy(int(target.get_meta("orb")))
	elif target is CharacterBody3D:
		if target==player:
			if owner_id<0 or rules.can_harm(owner_id,local_id):
				pending_hit_directions[local_id]=-Vector3(bullet["velocity"]).normalized();_damage_fighter(local_id,bullet["damage"],owner_id)
		elif target.has_meta("role"):
			if target.get_meta("role")=="minion":
				if owner_id>=0:_damage_entity(target,bullet["damage"],owner_id)
			else:
				var victim: int=int(target.get_meta("fighter"));pending_hit_directions[victim]=-Vector3(bullet["velocity"]).normalized()
				_damage_fighter(victim,bullet["damage"],owner_id)
func _play_distant(pos: Vector3,shotgun: bool) -> void:
	if not is_instance_valid(distant_shot):return
	var stream: AudioStream=load("res://assets/audio/shotgun_shot.wav") if shotgun else normal_shot
	if distant_shot.stream!=stream:distant_shot.stream=stream
	distant_shot.global_position=pos;distant_shot.play()
func _spend_shot(id: int) -> void:
	var melee: bool=Inventory.melee(rules.players[id]["weapon"])
	super._spend_shot(id)
	if not rules.players[id]["human"]:rules.players[id]["fire_cd"]*=1.30
	if melee:rules.players[id]["ammo"]=1;_body(id).set_meta("muzzle",0.0)
	if id==local_id:
		pump_age=0;pump_sound_played=false
		if melee:swing_age=0;flash_left=0
	Inventory.store(rules.players[id])
	if rules.players[id]["ammo"]==0 and (rules.players[id]["reserve"]>0 or Inventory.infinite(rules.players[id]["weapon"])):_try_reload(id)
func _equip_viewmodel() -> void:
	if rules.players.is_empty() or not is_instance_valid(shotgun_rig):return
	var key: String=rules.players[local_id]["weapon"]
	var pump: bool=key=="pump"
	double_rig.visible=key=="double";scythe_rig.visible=key=="scythe";carbon_rig.visible=key=="needle";sniper_rig.visible=key=="sniper"
	if key=="scythe":_tint_scythe(scythe_rig,int(rules.players[local_id]["team"]))
	gun.get_node("DetailedSidearm").visible=key=="pulse"
	shotgun_rig.get_node("Shotgun").visible=key in ["pump","scatter"];shotgun_rig.get_node("PumpSlide").visible=key in ["pump","scatter"]
	shotgun_rig.get_node("SupportArm").visible=key in ["pump","double","scatter","needle","sniper"]
	shotgun_rig.get_node("GripArm").show()
	if not pump:
		for mesh in gun.get_node("DetailedSidearm").find_children("*","MeshInstance3D",true,false):
			var material: Material=mesh.get_active_material(0)
			if material is StandardMaterial3D and ("Glove" in material.resource_name or "sleeve" in material.resource_name):mesh.hide()
	var desired_shot: AudioStream=_weapon_shot_stream(key)
	if shot_sound.stream!=desired_shot:shot_sound.stream=desired_shot
	var desired_load: AudioStream=load("res://assets/audio/shotgun_load.wav") if key in ["pump","double","scatter"] else load("res://assets/audio/reload_lower.wav")
	if reload_lower_sound.stream!=desired_load:reload_lower_sound.stream=desired_load
	var desired_ready: AudioStream=load("res://assets/audio/shotgun_ready.wav") if key in ["pump","double","scatter"] else load("res://assets/audio/reload_raise.wav")
	if reload_raise_sound.stream!=desired_ready:reload_raise_sound.stream=desired_ready
	_set_weapon_audio_levels(key in ["pump","double","scatter","sniper"])
func _tick_viewmodel(delta: float) -> void:
	super._tick_viewmodel(delta)
	gun.scale=Vector3.ONE*.88
	gun.position.x=-.10 if get_window().size.y>get_window().size.x else .025
	gun.position.y-=.20 if get_window().size.y>get_window().size.x else .04
	if get_window().size.y>get_window().size.x:
		gun.position.z-=.35
	hand_amount=0;hand_root.hide()
	if is_instance_valid(weapon_frame):weapon_frame.sync()
	pump_age+=delta
	flash.global_position=gun.global_transform*_muzzle_offset(rules.players[local_id]["weapon"])
	swing_age+=delta;gun.rotation.y=0
	if Inventory.melee(rules.players[local_id]["weapon"]):
		flash.hide()
		var amount:=sin(clampf(swing_age/.45,0,1)*PI)
		gun.rotation.z-=amount*.45;gun.rotation.y=amount*.65
	if rules.players[local_id]["weapon"] in ["pump","scatter"]:
		var offset:=sin(clampf((pump_age-.18)/.32,0,1)*PI)*.11 if pump_age<.50 else 0.0
		shotgun_rig.get_node("PumpSlide").position.z=offset
		shotgun_rig.get_node("SupportArm").position.z=offset
		shotgun_rig.get_node("SupportArm").visible=hand_amount<.2
		if pump_age>.18 and not pump_sound_played and is_instance_valid(pump_sound):pump_sound.play();pump_sound_played=true
func _set_weapon_audio_levels(pump: bool) -> void:
	shot_sound.volume_db=-80 if sound_volume==0 else (-5 if pump else -12)+linear_to_db(sound_volume*SHOT_VOLUME_SCALE)
	for effect in [reload_lower_sound,reload_raise_sound]:effect.volume_db=-80 if sound_volume==0 else (-9 if pump else -17)+linear_to_db(sound_volume)

func _update_audio() -> void:
	super._update_audio()
	if not rules.players.is_empty():_set_weapon_audio_levels(rules.players[local_id]["weapon"] in ["pump","double","scatter","sniper"])
	if is_instance_valid(pump_sound):pump_sound.volume_db=-80 if sound_volume==0 else -13+linear_to_db(sound_volume*SHOT_VOLUME_SCALE);pump_sound.stream_paused=app_paused or (not demo and not net.in_match and screen!="play")
	if is_instance_valid(distant_shot):distant_shot.volume_db=-80 if sound_volume==0 else -20+linear_to_db(sound_volume*SHOT_VOLUME_SCALE)
func _demo_tick(delta: float) -> void:
	_tick_fighter_states(delta)
	var motion=rails[local_id]
	if not brains.has(-10):_attach_brain(player,-10,motion)
	var nearest: CharacterBody3D
	for body in entities.values():
		if body.get_meta("role")=="minion" and (not is_instance_valid(nearest) or player.position.distance_to(body.position)<player.position.distance_to(nearest.position)):nearest=body
	var goal: Vector3=nearest.position if is_instance_valid(nearest) else course.nodes[0]
	var direction: Vector3=brains[-10].steer(player,motion,goal,delta)
	if is_instance_valid(nearest):
		var aim:=player.position+Vector3.UP*1.75
		var diff:=nearest.position+Vector3.UP*.8-aim
		motion.aim_yaw=lerp_angle(motion.aim_yaw,atan2(-diff.x,-diff.z),minf(1,delta*3));motion.pitch=lerpf(motion.pitch,asin(diff.normalized().y),minf(1,delta*3))
	var local:=Basis(Vector3.UP,motion.aim_yaw).inverse()*direction
	motion.set_move(Vector2(local.x,local.z))
	_tick_human_motion(delta);_tick_bots(delta);_tick_auto_combat(delta)
	if rules.players[local_id]["ammo"]==0 and rules.players[local_id]["reload"]<=0:_try_reload(local_id)
	_tick_suction(delta);cloud.tick(delta,_collector_positions(),true);_tick_supplies(delta)
func _render_hud(delta: float) -> void:
	if rules.players.is_empty():return
	var p: Dictionary=rules.players[local_id];var stat:=rules.stats(local_id)
	var hit:=_target_for(local_id) if _alive(local_id) else {}
	var essence: bool=not hit.is_empty() and hit["collider"] is Area3D
	var gold: bool=essence and cloud.orbs.get(int(hit["collider"].get_meta("orb",-1)),{}).get("gold",false)
	var key: String=pad_input.button_name(pad_input.bindings["reload"]) if pad_input.active else "TAP"
	var hint: String=(key+" IN AMBER" if not p["reload_used"] else "RELOADING") if p["reload"]>0 else (("FIND AMMO") if p["ammo"]==0 else "GOLD / AUTO COLLECTION" if gold else "BLUE ESSENCE / AUTO COLLECTION" if essence else "")
	var lock_state: Dictionary=lock_states.get(local_id,{})
	if float(lock_state.get("ttl",0))>0 and lock_state.get("chosen",false) and not _valid_lock(local_id,_lock_body(int(lock_state.get("target",-1))),true) and p["reload"]<=0:hint="TARGET LOST / RELEASE LOCK"
	var notice: String=toast if toast_left>0 else ""
	if not _alive(local_id):notice="RESPAWN / %.0f" % ceilf(p["respawn"]) if p["lives"]>0 else "ELIMINATED / WATCHING THE MATCH"
	hud_ui.update_view({"team":p["team"],"lives":p["lives"],"souls":p["souls"],"frags":p["frags"],"remaining":rules.remaining,"round":rules.round_index,"phase_name":["COLLECTION","ARMORY","SHARED ROLL","HUNTING","MATCH COMPLETE"][rules.phase],"health":p["hp"],"shield":p["shield"],"max_health":stat["health"],"max_shield":stat["shield"],"ammo":p["ammo"],"reserve":p["reserve"],"weapon":Rules.WEAPONS[p["weapon"]]["name"],"infinite_ammo":Inventory.infinite(p["weapon"]),"melee":Inventory.melee(p["weapon"]),"notice":notice,"damage_edges":p.get("damage_edges",Vector4.ZERO),"lock_progress":_lock_progress(local_id),"lock_active":float(lock_states.get(local_id,{}).get("ttl",0))>0,"lock_rect":_lock_rect(),"route_hint":"%s / %s" % [conditions.get("time",""),conditions.get("weather","")],"routes":{},"queued":"","can_drop":false,"jumps":rails[local_id].jumps if rails.has(local_id) else 0,"alive":_alive(local_id),"can_collect":rules.phase==Rules.Phase.COLLECTION,"locked":not hit.is_empty() and hit["collider"] is CharacterBody3D,"essence_target":essence,"essence_gold":gold,"reload_hint":hint,"reload_progress":1.0-p["reload"]/maxf(.1,p["reload_total"]) if p["reload"]>0 else -1.0,"reload_used":p["reload_used"],"reload_success":p["reload_flash"]*2,"rewards":rules.rewards,"names":_player_names(),"conditions":conditions,"prelude":prelude_left},delta)
	if screen=="shop":
		var signature:=str([p["souls"],p["weapon"],p["upgrades"],p["ready"]])
		if signature!=shop_signature:_show_shop()
func _pack_snapshot() -> Dictionary:
	var packet:=super._pack_snapshot();packet["projectiles"]=projectiles.pack();packet["conditions"]=conditions;packet["prelude"]=prelude_left;packet["locks"]=lock_states.duplicate(true)
	return packet
func _apply_snapshot(packet: Dictionary) -> void:
	if not net.in_match or net.hosting or int(packet.get("seq",-1))<=last_snapshot:return
	prelude_left=float(packet.get("prelude",0))
	if conditions!=packet["conditions"]:conditions=packet["conditions"];weather_node.apply(conditions,environment,sun,camera)
	super._apply_snapshot(packet)
	projectiles.apply_snapshot(packet["projectiles"])
	for body in entities.values():
		if int(body.get_meta("fighter",-1))>=0:_sync_actor_weapon(body,int(body.get_meta("fighter")))
	lock_states=packet.get("locks",{}).duplicate(true)
	if prelude_left>0 and screen!="conditions":_show("conditions",{"conditions":conditions})
	elif prelude_left<=0 and screen=="conditions":_show("play")
	for shooter in packet["shots"]:
		if shooter==local_id:pump_age=0;pump_sound_played=false;swing_age=0
		elif is_instance_valid(_body(int(shooter))):_play_actor_shot(int(shooter))
func _client_tick(delta: float) -> void:
	rules.remaining=maxf(0,rules.remaining-delta)
	if rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] and _alive(local_id):
		rails[local_id].step(player,course,delta);camera.position=Vector3(0,1.75,0);camera.rotation=Vector3(rails[local_id].pitch,0,0)
	aim_send_left-=delta
	if aim_send_left<=0:net.send_action("aim",Vector2(rails[local_id].aim_yaw,rails[local_id].pitch));aim_send_left=.05
	for body in entities.values():
		_tick_actor_weapon(body,delta)
		if body.has_meta("network_pos"):
			body.position=body.position.lerp(body.get_meta("network_pos"),minf(1,delta*18));body.rotation.y=lerp_angle(body.rotation.y,float(body.get_meta("network_yaw")),minf(1,delta*18))
		if body.has_meta("animation"):body.get_meta("animation").active=body.visible and rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT]
		art.animate_enemy(body,"Jump" if body.get_meta("air",false) else "Run" if body.position.distance_to(body.get_meta("network_pos",body.position))>.04 else "Idle")
		var muzzle:=maxf(0,float(body.get_meta("muzzle",0))-delta);body.set_meta("muzzle",muzzle);body.get_node("MuzzleFlash").visible=muzzle>0
	cloud.tick(delta,{},false)
	var p: Dictionary=rules.players[local_id]
	if p["reload"]>0:p["reload"]=maxf(.001,p["reload"]-delta)
	p["reload_flash"]=maxf(0,p["reload_flash"]-delta);p["suction"]=maxf(0,p["suction"]-delta);p["respawn"]=maxf(0,p["respawn"]-delta)

func _quit_game(exit_code := 0) -> void:
	if is_instance_valid(pump_sound):pump_sound.stop()
	if is_instance_valid(distant_shot):distant_shot.stop()
	super._quit_game(exit_code)

func _turn_toward(current: float,target: float,step: float) -> float:
	return wrapf(current+clampf(angle_difference(current,target),-step,step),-PI,PI)
func _facing_target(body: CharacterBody3D,point: Vector3) -> bool:
	var diff:=point-body.position;diff.y=0
	return diff.length()<.1 or (-body.global_basis.z).normalized().dot(diff.normalized())>cos(deg_to_rad(9))
func _set_lock_input(id: int,pressed: bool) -> void:
	if not lock_states.has(id):lock_states[id]={"ttl":0.0,"target":-1,"charge":0.0,"chosen":false}
	if pressed and float(lock_states[id]["ttl"])<=0:lock_states[id]["target"]=-1;lock_states[id]["charge"]=0.0;lock_states[id]["chosen"]=false
	lock_states[id]["ttl"]=.5 if pressed else 0.0
	if not pressed:lock_states[id]["target"]=-1;lock_states[id]["charge"]=0.0;lock_states[id]["chosen"]=false
func _lock_body(key: int) -> CharacterBody3D:
	if key<0:return null
	return player if key==local_id else entities.get(key)
func _lock_point(target: CharacterBody3D) -> Vector3:
	return target.position+Vector3.UP*(.85 if target.get_meta("role","")=="minion" else 1.35)
func _valid_lock(id: int,target: CharacterBody3D,sticky := false) -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.visible or target==_body(id):return false
	var other: int=local_id if target==player else int(target.get_meta("fighter",-1))
	if other>=0:
		if not _alive(other) or not rules.can_harm(id,other):return false
	elif target.get_meta("role","")!="minion" or rules.phase!=Rules.Phase.COLLECTION:return false
	var origin:=_body(id).position+Vector3.UP*1.65
	var offset:=_lock_point(target)-origin
	if offset.length()>32+int(rules.players[id]["gifts"].get("reach",0)):return false
	var m=rails[id];var forward: Vector3=-Basis.from_euler(Vector3(m.pitch,m.aim_yaw,0)).z
	return forward.dot(offset.normalized())>cos(deg_to_rad(55 if sticky else 22)) and _clear_sight(origin,_lock_point(target))
func _tick_locks(delta: float) -> void:
	for id in lock_states.keys():
		if not _authority() and id!=local_id:continue
		var state: Dictionary=lock_states[id]
		state["ttl"]=maxf(0,float(state["ttl"])-delta)
		if state["ttl"]<=0 or not _alive(id):state["target"]=-1;state["charge"]=0.0;state["chosen"]=false;continue
		var target:=_lock_body(int(state["target"]))
		if state.get("chosen",false) and not _valid_lock(id,target,true):state["charge"]=0.0;continue
		if not state.get("chosen",false):
			state["target"]=-1;state["charge"]=0.0;target=null
			var best:=INF
			for candidate in entities.values()+[player]:
				if not _valid_lock(id,candidate):continue
				var offset:=_lock_point(candidate)-(_body(id).position+Vector3.UP*1.65)
				var m=rails[id];var forward: Vector3=-Basis.from_euler(Vector3(m.pitch,m.aim_yaw,0)).z
				var score:=1.0-forward.dot(offset.normalized())
				if score<best:best=score;target=candidate
			if is_instance_valid(target):state["target"]=local_id if target==player else int(target.get_meta("key"));state["chosen"]=true
		if not is_instance_valid(target):continue
		state["charge"]=minf(LOCK_TIME,float(state["charge"])+delta)
		var m=rails[id];var diff:=_lock_point(target)-(_body(id).position+Vector3.UP*1.65)
		m.aim_yaw=_turn_toward(m.aim_yaw,atan2(-diff.x,-diff.z),delta*3.4)
		m.pitch=move_toward(m.pitch,asin(diff.normalized().y),delta*2.7)
		_body(id).rotation.y=m.aim_yaw
		if id==local_id:camera.rotation=Vector3(m.pitch,0,0)
func _can_shoot(id: int) -> bool:
	if id==local_id and _wheel_open():return false
	if not super._can_shoot(id):return false
	var state: Dictionary=lock_states.get(id,{})
	if float(state.get("ttl",0))<=0:return true
	return float(state.get("charge",0))>=LOCK_TIME and _valid_lock(id,_lock_body(int(state.get("target",-1))),true)
func _lock_progress(id: int) -> float:return clampf(float(lock_states.get(id,{}).get("charge",0))/LOCK_TIME,0,1)
func _lock_rect() -> Rect2:
	var state: Dictionary=lock_states.get(local_id,{})
	if float(state.get("ttl",0))<=0:return Rect2()
	var target:=_lock_body(int(state.get("target",-1)))
	if not _valid_lock(local_id,target,true) or camera.is_position_behind(target.position+Vector3.UP):return Rect2()
	var height:=1.8 if target.get_meta("role","")=="minion" else 2.4
	var a:=camera.unproject_position(target.position+Vector3.UP*height)
	var b:=camera.unproject_position(target.position)
	var extent:=maxf(12,absf(b.y-a.y)*.32)
	return Rect2(Vector2((a.x+b.x)*.5-extent,minf(a.y,b.y)-5),Vector2(extent*2,absf(b.y-a.y)+10))
func _tick_fighter_states(delta: float) -> void:
	super._tick_fighter_states(delta)
	for p in rules.players:
		p["touch_auto_left"]=maxf(0,float(p.get("touch_auto_left",0))-delta)
		p["suction"]=0.0
		var edges: Vector4=p.get("damage_edges",Vector4.ZERO)
		p["damage_edges"]=Vector4(maxf(0,edges.x-delta*2.2),maxf(0,edges.y-delta*2.2),maxf(0,edges.z-delta*2.2),maxf(0,edges.w-delta*2.2))
		Inventory.store(p)
		if _alive(p["id"]) and p["ammo"]==0 and (p["reserve"]>0 or Inventory.infinite(p["weapon"])) and p["reload"]<=0:_try_reload(p["id"])

func _set_touch_auto(enabled: bool) -> void:
	if enabled==touch_auto:return
	touch_auto=enabled;auto_heartbeat=0
	if not demo and running and not rules.players.is_empty():_request_action("autofire",enabled)
func _controller_mode(active: bool) -> void:
	if active:touch_aim=-1;_set_touch_auto(false)
	super._controller_mode(active)
func _tick_suction(_delta: float) -> void:pass
func _collector_positions() -> Dictionary:
	var collectors: Dictionary={}
	for p in rules.players:
		var body:=_body(int(p["id"]))
		if is_instance_valid(body):collectors[p["id"]]=body.position+Vector3.UP*1.15
	return collectors
func _damage_entity(body: CharacterBody3D,amount: float,attacker: int) -> void:
	if not is_instance_valid(body) or body.is_queued_for_deletion() or not body.has_meta("role"):return
	if body.get_meta("role")=="fighter":_damage_fighter(int(body.get_meta("fighter")),amount,attacker);return
	if rules.phase!=Rules.Phase.COLLECTION or attacker<0 or attacker>=rules.players.size():return
	var hp:=float(body.get_meta("hp"))-amount;body.set_meta("hp",hp)
	if hp>0:return
	rules.players[attacker]["minions"]+=1
	var pos:=body.position;_create_corpse(body)
	var drop: Dictionary=Minions.TYPES[body.get_meta("subtype","scavenger")]
	for i in range(int(drop["drops"])):
		var id: int=cloud.spawn(pos+Vector3((i-(int(drop["drops"])-1)*.5)*.20,.9,.15*sin(i*2.0)),int(drop["value"]),-1,bool(drop["gold"]))
		if id>=0:cloud.orbs[id]["owner"]=attacker;cloud.orbs[id]["area"].collision_layer=0
		else:rules.credit_essence(attacker,int(drop["value"]))
	_remove_entity(int(body.get_meta("key")))

func _wheel_open() -> bool:
	return is_instance_valid(hud_ui) and is_instance_valid(hud_ui.wheel) and hud_ui.wheel.opened
func _open_wheel() -> void:
	if screen!="play" or demo or not _alive(local_id) or _wheel_open():return
	mouse_firing=false;mouse_lock=false;touch_lock=false;keyboard_used=false;touch_move=Vector2.ZERO;touch_aim=-1
	_set_touch_auto(false);_request_action("fire",false);_request_action("lock",false);_request_action("move",Vector2.ZERO)
	Inventory.store(rules.players[local_id]);hud_ui.wheel.present(rules.players[local_id]);pad_input.wheel_open=true
	wheel_mouse_mode=Input.mouse_mode;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func _close_wheel(commit: bool) -> void:
	if not _wheel_open():return
	var key: String=hud_ui.wheel.selected
	hud_ui.wheel.close();pad_input.wheel_open=false
	hud_ui.wheel_button.finger=-1;hud_ui.wheel_button.queue_redraw()
	if not pad_input.active:Input.mouse_mode=wheel_mouse_mode
	if commit and screen=="play":_request_action("equip",key)
func _switch_weapon(id: int,key: String) -> bool:
	var p: Dictionary=rules.players[id]
	if not Rules.WEAPONS.has(key) or key not in p["owned"]:return false
	if p["weapon"]==key:return true
	Inventory.store(p);Inventory.restore(p,key)
	p["reload"]=0.0;p["reload_total"]=rules.stats(id)["reload"];p["reload_used"]=false;p["fire_cd"]=maxf(float(p["fire_cd"]),.18)
	if id==local_id:
		reload_lower_sound.stop();reload_raise_sound.stop();pump_age=99;pump_sound_played=true;swing_age=99;recoil=0;gun.rotation=Vector3.ZERO
		_equip_viewmodel()
	else:_sync_actor_weapon(_body(id),id)
	return true
func _try_reload(id: int,partial := false) -> void:
	var p: Dictionary=rules.players[id]
	if Inventory.melee(p["weapon"]):return
	if Inventory.infinite(p["weapon"]):
		p["reserve"]=99999;super._try_reload(id,partial);p["reserve"]=-1
	else:super._try_reload(id,partial)
	Inventory.store(p)
func _complete_reload(id: int) -> void:
	var p: Dictionary=rules.players[id]
	if Inventory.infinite(p["weapon"]):
		var early: bool=p["reload"]>0
		p["ammo"]=int(rules.stats(id)["mag"]);p["reserve"]=-1;p["reload"]=0.0;p["reload_finish"]+=1
		if early:p["fire_cd"]=maxf(float(p["fire_cd"]),.14)
	else:super._complete_reload(id)
	Inventory.store(p)
func _purchase(id: int,item: String) -> void:
	var p: Dictionary=rules.players[id]
	if Rules.WEAPONS.has(item):
		Inventory.store(p)
		if not rules.buy(id,item):_notify("ARMORY / PURCHASE UNAVAILABLE",2,id);return
		Inventory.restore(p,item);p["reload"]=0.0;p["reload_total"]=rules.stats(id)["reload"]
		_notify("ARMORY / WEAPON ACQUIRED",2,id)
		if id==local_id:_equip_viewmodel()
		else:_sync_actor_weapon(_body(id),id)
	elif item=="ammo":
		var available:=false
		for key in p["owned"]:
			if not Inventory.infinite(key) and int(p["inventory"][key]["reserve"])<360:available=true
		if not available or not rules.buy(id,item):_notify("NO RESUPPLY NEEDED",2,id);return
		Inventory.add_reserve(p,72);_notify("ARMORY / RESUPPLIED",2,id)
	else:super._purchase(id,item)
func _tick_supplies(delta: float) -> void:
	for i in range(supply_nodes.size()):
		var node: Node3D=supply_nodes[i]
		if supply_timers[i]>0:
			supply_timers[i]=maxf(0,supply_timers[i]-delta);node.visible=supply_timers[i]<=0;continue
		node.rotate_y(delta)
		for p in rules.players:
			var id: int=p["id"];var body:=_body(id)
			if not _alive(id) or not is_instance_valid(body) or body.position.distance_to(node.position-Vector3.UP*.5)>1.2:continue
			if node.get_meta("kind")=="health":
				if p["hp"]>=rules.stats(id)["health"]:continue
				p["hp"]=minf(rules.stats(id)["health"],p["hp"]+30)
			elif not Inventory.add_reserve(p,24):continue
			supply_timers[i]=15.0;node.hide();break
func _muzzle_offset(key: String) -> Vector3:
	return Vector3(.19,-.157,-1.47) if key=="sniper" else Vector3(.19,-.157,-1.28) if key=="needle" else Vector3(.19,-.157,-.99) if key=="double" else Vector3(.19,-.157,-1.19) if key in ["pump","scatter"] else Vector3(.15,-.187,-.76)
func _melee_swing(id: int) -> void:
	_spend_shot(id)
	var body:=_body(id);var origin:=body.position+Vector3.UP*1.25
	var basis:=Basis.from_euler(Vector3(rails[id].pitch,rails[id].aim_yaw,0)) if rails.has(id) else body.global_basis
	for target in entities.values()+[player]:
		if target==body or not is_instance_valid(target) or target.is_queued_for_deletion():continue
		var other: int=local_id if target==player else int(target.get_meta("fighter",-1))
		var valid: bool=rules.can_harm(id,other) if other>=0 else target.get_meta("role","")=="minion" and rules.phase==Rules.Phase.COLLECTION
		if not valid:continue
		var point: Vector3=target.position+Vector3.UP*1.1;var diff: Vector3=point-origin
		if diff.length()>3 or (-basis.z).dot(diff.normalized())<cos(deg_to_rad(50)) or not _clear_sight(origin,point):continue
		if other>=0:_damage_fighter(other,float(rules.stats(id)["damage"]),id)
		else:_damage_entity(target,float(rules.stats(id)["damage"]),id)
	if id!=local_id:_play_melee_audio(body.position);body.set_meta("scythe_swing",.4)
func _play_melee_audio(position: Vector3) -> void:
	if not is_instance_valid(distant_shot):return
	distant_shot.stream=load("res://assets/audio/scythe_swing.wav");distant_shot.global_position=position;distant_shot.play()
func _play_actor_shot(key: int) -> void:
	var body:=_body(key)
	if not is_instance_valid(body):return
	if key>=0 and key<rules.players.size() and Inventory.melee(rules.players[key]["weapon"]):
		_play_melee_audio(body.position);body.set_meta("scythe_swing",.4)
	elif key>=0 and key<rules.players.size():_play_weapon_audio(body.position,rules.players[key]["weapon"])
	else:_play_distant(body.position,false)
func _tint_scythe(model: Node3D,team: int) -> void:
	if int(model.get_meta("plasma_team",-1))==team:return
	model.set_meta("plasma_team",team)
	var color:=Color("5bbdff") if team==0 else Color("ff5269")
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var material: Material=mesh.get_active_material(surface)
			if material is StandardMaterial3D and "Plasma" in material.resource_name:
				var copy: StandardMaterial3D=material.duplicate();copy.albedo_color=color;copy.emission=color;copy.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
				mesh.set_surface_override_material(surface,copy)
func _sync_actor_weapon(body: CharacterBody3D,id: int) -> void:
	if not is_instance_valid(body) or id==local_id:return
	var key: String=rules.players[id]["weapon"]
	if body.get_meta("shown_weapon","")==key:return
	body.set_meta("shown_weapon",key)
	for name in ["Armory_scythe","Armory_double","Armory_needle","Armory_sniper"]:
		var previous:=body.get_node_or_null(name)
		if is_instance_valid(previous):previous.hide()
	if key not in ["scythe","double","needle","sniper"]:return
	var model:=body.get_node_or_null("Armory_"+key)
	if not is_instance_valid(model):
		model={"scythe":SCYTHE,"double":DOUBLE,"needle":CARBON,"sniper":SNIPER}[key].instantiate();model.name="Armory_"+key;body.add_child(model)
		model.position=Vector3(.12,1.28,.15);model.scale=Vector3.ONE*1.15
	if key=="scythe":_tint_scythe(model,int(rules.players[id]["team"]))
	model.show()
func _tick_actor_weapon(body: CharacterBody3D,delta: float) -> void:
	var remaining:=maxf(0,float(body.get_meta("scythe_swing",0))-delta);body.set_meta("scythe_swing",remaining)
	var model:=body.get_node_or_null("Armory_scythe")
	if is_instance_valid(model):model.rotation.z=-sin(remaining/.4*PI)*.6

func _ai_choose_weapon(id: int,distance: float) -> void:
	var p: Dictionary=rules.players[id]
	if distance<2.5 and "scythe" in p["owned"]:_switch_weapon(id,"scythe")
	elif Inventory.melee(p["weapon"]) and distance>3.5:
		for key in ["double","needle","pulse","scatter","pump"]:
			if key in p["owned"]:_switch_weapon(id,key);break
	elif p["ammo"]==0 and p["reserve"]==0:_switch_weapon(id,"pump")

func _show_visuals() -> void:
	_show("visuals",{"effects":visual_effects,"motion":camera_motion})
func _save_settings() -> void:
	for key in visual_effects:settings.set_value("visuals",key,visual_effects[key])
	settings.set_value("heroes","selected",hero_id);settings.set_value("heroes","careers",hero_careers)
	super._save_settings()
func _show_heroes() -> void:
	_show("heroes",{"heroes":HEROES.roster(),"careers":hero_careers,"page":hero_page})
func _show_hero_detail() -> void:
	var missions: Array=[]
	for i in range(5):missions.append(HEROES.mission(hero_id,i))
	_show("hero_detail",{"hero":HEROES.find(hero_id),"career":hero_careers[hero_id],"missions":missions})
func _start_hero_mission(index: int) -> void:
	var career: Dictionary=hero_careers[hero_id]
	if index<0 or index>=5 or index>=int(career["unlocked"]):return
	hero_mission=index;hero_match_id=hero_id;career_passed=false;campaign_match=true
	var mission:=HEROES.mission(hero_id,index);campaign_level=int(mission["map"])
	net.close();local_id=0;_start_match(int(mission["size"]),campaign_level,Time.get_ticks_msec(),[0])
	_notify(str(mission["title"]).to_upper()+" / "+str(mission["description"]),6)
func _controller_back() -> void:
	if screen=="visuals":_show_options()
	elif screen=="heroes":_show("main")
	elif screen=="hero_detail":_show_heroes()
	else:super._controller_back()
func _record_hero_career() -> String:
	if career_recorded:return ""
	career_recorded=true
	var p: Dictionary=rules.players[local_id];var career: Dictionary=hero_careers[hero_match_id]
	var mission:=HEROES.mission(hero_match_id,hero_mission)
	var won: bool=rules.match_winner==int(p["team"])
	var actual: int={"win":1 if won else 0,"frags":int(p["frags"]),"minions":int(p["minions"]),"souls":int(p["essence"])}[mission["goal"]]
	career_passed=won and actual>=int(mission["amount"])
	career["matches"]+=1;career["wins"]+=1 if won else 0;career["frags"]+=int(p["frags"]);career["souls"]+=int(p["essence"])
	if career_passed:
		if hero_mission not in career["cleared"]:career["cleared"].append(hero_mission)
		career["unlocked"]=maxi(int(career["unlocked"]),mini(5,hero_mission+2))
	career["best"][str(hero_mission)]={"frags":maxi(int(career["best"].get(str(hero_mission),{}).get("frags",0)),int(p["frags"])),"souls":maxi(int(career["best"].get(str(hero_mission),{}).get("souls",0)),int(p["essence"]))}
	campaign_unlocked=int(hero_careers[hero_id]["unlocked"]);_save_settings()
	return "%s / %s\n%s\nCAREER %d / 5 COMPLETE" % [HEROES.find(hero_match_id)["name"],"CHAPTER CLEARED" if career_passed else "OBJECTIVE NOT CLEARED",mission["description"],career["cleared"].size()]
func _show_match_results() -> void:
	var p: Dictionary=rules.players[local_id]
	var result: String="DRAW" if rules.match_winner<0 else "VICTORY" if rules.match_winner==int(p["team"]) else "DEFEAT"
	var summary: String="%s\n%d FRAGS / %d SOULS\nMATCH COMPLETE" % [result,p["frags"],p["essence"]]
	if campaign_match and not net.in_match:summary+="\n\n"+_record_hero_career()
	_show("results",{"summary":summary})
func _show_shop() -> void:
	var p: Dictionary=rules.players[local_id];var items: Array=[]
	for key in Rules.WEAPONS:
		if key in p["owned"] or (Rules.WEAPONS[key].get("human_only",false) and not p["human"]):continue
		items.append({"id":key,"text":"%s / %d SOULS" % [Rules.WEAPONS[key]["name"],Rules.WEAPONS[key]["cost"]],"disabled":p["ready"] or p["souls"]<Rules.WEAPONS[key]["cost"]})
	for key in Rules.UPGRADES:
		var data: Dictionary=Rules.UPGRADES[key]
		items.append({"id":key,"text":"%s / %d" % [data["name"],data["cost"]],"disabled":p["ready"] or p["souls"]<data["cost"] or int(p["upgrades"].get(key,0))>=data["limit"]})
	_show("shop",{"items":items});shop_signature=str([p["souls"],p["weapon"],p["upgrades"],p["ready"]])
func _tick_bot_shopping() -> void:
	if Rules.SHOP_TIME-rules.remaining<1.5:return
	for p in rules.players:
		if p["human"] or p["shop_done"]:continue
		var id: int=p["id"]
		for key in ["double","needle","pulse","scatter"]:
			if key not in p["owned"] and p["souls"]>=Rules.WEAPONS[key]["cost"]:_purchase(id,key);break
		for key in ["damage","choke"]:
			if p["souls"]>=Rules.UPGRADES[key]["cost"]:_purchase(id,key)
		if p["souls"]>=15 and p["reserve"]>=0 and p["reserve"]<36:_purchase(id,"ammo")
		p["shop_done"]=true;rules.ready(id)
func _choose_spawn_node() -> int:
	var available: Array=course.spawn_nodes.duplicate() if not course.spawn_nodes.is_empty() else range(course.nodes.size())
	var best: int=int(available[combat_random.randi_range(0,available.size()-1)]);var greatest:=-1.0
	for attempt in range(mini(60,available.size())):
		var index: int=int(available[combat_random.randi_range(0,available.size()-1)])
		var separation:=9999.0
		for body in entities.values()+[player]:
			if not is_instance_valid(body) or not body.visible:continue
			separation=minf(separation,course.nodes[index].distance_squared_to(body.position))
		if separation>9:return index
		if separation>greatest:greatest=separation;best=index
	return best
func _sync_random_spawns() -> void:
	spawns_synced=true
	for p in rules.players:
		var id: int=p["id"]
		if rails.has(id):rails[id].reset(_body(id),course,_choose_spawn_node())
	for key in enemy_motions:
		if key>=100 and entities.has(key):enemy_motions[key].reset(entities[key],course,_choose_spawn_node())
func _spawn_minion(_node: int,subtype := "") -> void:
	super._spawn_minion(_choose_spawn_node(),subtype)
func _damage_fighter(victim: int,amount: float,attacker := -1) -> void:
	var direction: Vector3=pending_hit_directions.get(victim,Vector3.ZERO);pending_hit_directions.erase(victim)
	if direction==Vector3.ZERO and attacker>=0 and is_instance_valid(_body(attacker)) and is_instance_valid(_body(victim)):direction=_body(attacker).position-_body(victim).position
	var p: Dictionary=rules.players[victim];var before: float=p["hp"]+p["shield"]
	super._damage_fighter(victim,amount,attacker)
	if p["hp"]+p["shield"]>=before or direction.length()<.01:return
	var local: Vector3=Basis(Vector3.UP,rails[victim].aim_yaw).inverse()*direction.normalized()
	var edges:=Vector4(maxf(0,-local.x),maxf(0,local.x),maxf(maxf(0,-local.z),maxf(0,local.y)),maxf(maxf(0,local.z),maxf(0,-local.y)))
	var old: Vector4=p.get("damage_edges",Vector4.ZERO)
	p["damage_edges"]=Vector4(maxf(old.x,edges.x),maxf(old.y,edges.y),maxf(old.z,edges.z),maxf(old.w,edges.w))
func _weapon_shot_stream(key: String) -> AudioStream:
	if key=="scythe":return load("res://assets/audio/scythe_swing.wav")
	if key=="needle":return load("res://assets/audio/carbine_shot.wav")
	if key=="sniper":return load("res://assets/audio/sniper_shot.wav")
	if key in ["pump","double","scatter"]:return load("res://assets/audio/shotgun_shot.wav")
	return normal_shot
func _play_weapon_audio(position: Vector3,key: String) -> void:
	if not is_instance_valid(distant_shot):return
	distant_shot.stream=_weapon_shot_stream(key);distant_shot.global_position=position;distant_shot.play()
