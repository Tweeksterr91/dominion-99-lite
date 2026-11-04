extends "res://scripts/souls_arena.gd"
const FreeMotion=preload("res://scripts/free_motion.gd")
const FreeMap=preload("res://scripts/free_map.gd")
const FreeHUD=preload("res://scripts/free_hud.gd")
const Brain=preload("res://scripts/free_brain.gd")
const Projectiles=preload("res://scripts/arena_projectiles.gd")
const Weather=preload("res://scripts/arena_weather.gd")
const PUMP=preload("res://assets/models/pump_shotgun.glb")
const HUMAN_HAND=preload("res://assets/models/human_harvest.glb")
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
func _ready() -> void:
	super._ready()
	var previous:=hand_root
	camera.remove_child(previous);previous.queue_free()
	hand_root=HUMAN_HAND.instantiate();camera.add_child(hand_root);hand_root.hide()
	_layer_weapon(hand_root)
	pump_sound=AudioStreamPlayer.new();pump_sound.stream=load("res://assets/audio/shotgun_pump.wav");add_child(pump_sound)
	distant_shot=AudioStreamPlayer3D.new();distant_shot.stream=load("res://assets/audio/shotgun_shot.wav");distant_shot.max_distance=45;distant_shot.unit_size=12;add_child(distant_shot)
	weapon_frame=preload("res://scripts/viewmodel_frame.gd").new();add_child(weapon_frame);weapon_frame.configure(camera)
	_update_audio()
func _create_hud() -> CanvasLayer:return FreeHUD.new()
func _load_settings() -> void:
	super._load_settings()
	if int(settings.get_value("audio","arena_mix",0))<1:
		if is_equal_approx(sound_volume,.8):sound_volume=.7
		if is_equal_approx(music_volume,.35):music_volume=.7
		settings.set_value("audio","volume",sound_volume);settings.set_value("audio","music",music_volume);settings.set_value("audio","arena_mix",1);settings.save("user://dominion_settings.cfg")
func _load_controller_settings() -> void:
	super._load_controller_settings()
	var previous: Dictionary=pad_input.bindings.duplicate()
	pad_input.bindings=Controller.FREE_DEFAULTS.duplicate()
	for action in ["jump","reload","suction","pause"]:pad_input.bind(action,int(previous.get(action,Controller.FREE_DEFAULTS[action])))
	var saved: Dictionary=settings.get_value("controller","bindings",{})
	if saved.has("lock"):pad_input.bind("lock",int(saved["lock"]))
func _make_player() -> void:
	super._make_player()
	camera.far=100
	flash.layers=2
	for child in camera.get_children():
		if child is OmniLight3D:child.light_energy=.28
	shotgun_rig=PUMP.instantiate();gun.add_child(shotgun_rig);_layer_weapon(shotgun_rig)
func _layer_weapon(model: Node3D) -> void:
	for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.layers=2;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _make_audio() -> void:
	super._make_audio();normal_shot=shot_sound.stream
func _start_match(size: int,map_id: int,seed_value: int,human_ids: Array,lan := false,attract := false) -> void:
	match_seed=seed_value;conditions=Weather.roll(seed_value,map_id);prelude_left=0
	super._start_match(size,map_id,seed_value,human_ids,lan,attract)
	pad_input.free_movement=true
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
	brains.clear();enemy_motions.clear();rails.clear();lock_states.clear();touch_lock=false;mouse_lock=false
	for node in supply_nodes:node.queue_free()
	supply_nodes.clear();supply_timers.clear()
	for body in corpses:
		if is_instance_valid(body):body.queue_free()
	corpses.clear();corpse_lives.clear();cloud.clear();projectiles.clear();next_minion=100
	for p in rules.players:
		var id: int=p["id"];var stat:=rules.stats(id)
		p.merge({"hp":float(stat["health"]),"shield":float(stat["shield"]),"ammo":int(stat["mag"]),"reserve":30 if p["weapon"]=="pump" else 72,"reload":0.0,"reload_total":float(stat["reload"]),"reload_used":false,"reload_flash":0.0,"fire_cd":0.0,"hit_age":10.0,"respawn":0.0,"invul":2.0,"suction":0.0,"deny_id":-1,"deny_dwell":0.0,"ai_pull":0.0,"shop_done":false,"damage_flash":0.0,"manual_left":0.0,"reload_cycle":0,"reload_finish":0},true)
		var lane: int=id if p["team"]==0 else id-selected_size
		var spawn: int=[10,9,11,19][lane] if p["team"]==0 else [14,13,15,23][lane]
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
	minion_spawn_left=2.5;treasure_spawn_left=combat_random.randf_range(55,125);_equip_viewmodel()
func _attach_brain(body: CharacterBody3D,key: int,motion: RefCounted) -> void:
	var brain:=Brain.new();body.add_child(brain);brains[key]=brain;enemy_motions[key]=motion
func _create_entity(key: int,role: String,node: int,fighter := -1,subtype := "scavenger") -> CharacterBody3D:
	var body:=super._create_entity(key,role,node,fighter,subtype)
	body.collision_mask=1;body.floor_snap_length=.4;body.floor_max_angle=deg_to_rad(44)
	if role=="minion":body.get_node("MuzzleFlash").material_override=art.materials["green"]
	if role=="minion" and _authority():
		var motion:=FreeMotion.new();motion.reset(body,course,node);_attach_brain(body,key,motion)
	return body
func _remove_entity(key: int) -> void:
	brains.erase(key);enemy_motions.erase(key);super._remove_entity(key)
func _adapt_orientation() -> void:
	super._adapt_orientation()
	if is_instance_valid(hud_ui) and is_instance_valid(hud_ui.lock_button):hud_ui.lock_button.release()
	if is_instance_valid(hud_ui) and is_instance_valid(hud_ui.stick) and hud_ui.stick.finger>=0:hud_ui.stick.release()
	if is_instance_valid(weapon_frame):weapon_frame.sync()

func _show(value: String,context: Dictionary={}) -> void:
	if value!="play":
		mouse_firing=false;mouse_lock=false;touch_lock=false
		if is_instance_valid(pad_input):pad_input.stop_locking()
		if not demo:_request_action("lock",false)
		if not demo:_request_action("fire",false)
	if value!="play" and is_instance_valid(pad_input):pad_input.stop_moving()
	if value!="play" and rails.has(local_id) and not demo:_request_action("move",Vector2.ZERO)
	super._show(value,context)
func _ui_action(kind: String,value: Variant) -> void:
	if kind=="reverse":return
	if kind=="lock":touch_lock=bool(value);_request_action("lock",value);return
	if kind=="move":
		touch_move=value;keyboard_used=false;_request_action("move",value)
	else:super._ui_action(kind,value)
func _controller_command(kind: String,value: Variant) -> void:
	if kind=="reverse":return
	if kind=="lock":
		if screen=="play" or value==false:_request_action(kind,value)
		return
	if kind=="move":
		keyboard_used=false
		if screen=="play" or value==Vector2.ZERO:_request_action("move",value)
		return
	super._controller_command(kind,value)
func _input(event: InputEvent) -> void:
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
func _look(change: Vector2) -> void:
	if not rails.has(local_id):return
	var motion=rails[local_id]
	motion.aim_yaw=wrapf(motion.aim_yaw-change.x*aim_sensitivity,-PI,PI)
	motion.pitch=clampf(motion.pitch-change.y*aim_sensitivity*(-1 if invert_aim else 1),-1.25,1.25)
	player.rotation.y=motion.aim_yaw;camera.rotation=Vector3(motion.pitch,0,0)
func _request_action(kind: String,value: Variant=null) -> void:
	if kind=="reverse":return
	if kind=="lock" and not demo:_set_lock_input(local_id,bool(value))
	if kind=="move" and not demo and rails.has(local_id) and value is Vector2:rails[local_id].set_move(value)
	super._request_action(kind,value)
func _apply_action(id: int,kind: String,value: Variant,sequence: int) -> void:
	if not _authority() or id not in humans or not rails.has(id):return
	if kind=="reverse":return
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
func _respawn_fighter(id: int) -> void:
	super._respawn_fighter(id)
	if rails.has(id):rails[id].set_move(Vector2.ZERO)
func _replace_departed(id: int) -> void:
	if id<0 or id>=rules.players.size():return
	humans.erase(id);rules.players[id]["human"]=false;rules.players[id]["name"]="BOT %d" % (id+1)
	if rails.has(id):rails[id].set_move(Vector2.ZERO);_attach_brain(_body(id),id,rails[id])
	_notify("A disconnected player is now controlled by a bot.",4)
func _physics_process(delta: float) -> void:
	if app_paused:return
	if prelude_left>0 and not demo:
		prelude_left=maxf(0 if _authority() else .02,prelude_left-delta)
		if _authority() and prelude_left<=0 and not course.nav_ready:prelude_left=.02
		if _authority() and net.in_match:
			snapshot_left-=delta
			if snapshot_left<=0:net.publish(_pack_snapshot());snapshot_left=.05
		if prelude_left<=0:_show("play");phase_wall_time=Time.get_ticks_usec()
		_render_hud(delta)
		return
	if screen=="play" and not demo:
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
	super._handle_phase_change()
	if before!=phase_revision and rules.phase not in [Rules.Phase.COLLECTION,Rules.Phase.HUNT]:projectiles.clear();lock_states.clear()
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
			motion.aim_yaw=_turn_toward(motion.aim_yaw,atan2(-diff.x,-diff.z),deg_to_rad(90 if fighter>=0 else 65)*delta)
			if body.get_meta("subtype","")=="treasure":
				var farthest: Vector3=course.nodes[0]
				for node in course.nodes:
					if node.distance_squared_to(target.position)>farthest.distance_squared_to(target.position):farthest=node
				goal=farthest
			elif diff.length()>10 or not _clear_sight(body.position+Vector3.UP*1.3,target.position+Vector3.UP):goal=target.position
			else:
				var side:=Vector3(-diff.z,0,diff.x).normalized()
				goal=body.position+side*sin(float(Time.get_ticks_msec())*.001+key)*2.5
		else:
			if body.position.distance_to(goal)<1.8:goal=course.nodes[combat_random.randi_range(0,24)];body.set_meta("wander_goal",goal)
		if fighter>=0 and rules.phase==Rules.Phase.COLLECTION:
			for orb in cloud.orbs.values():
				if body.position.distance_to(orb["pos"])<7:goal=orb["pos"];break
		var direction: Vector3=brains[key].steer(body,motion,goal,delta)
		if not is_instance_valid(target) and direction.length()>.2:motion.aim_yaw=_turn_toward(motion.aim_yaw,atan2(-direction.x,-direction.z),deg_to_rad(90 if fighter>=0 else 65)*delta)
		var local: Vector3=Basis(Vector3.UP,motion.aim_yaw).inverse()*direction
		motion.set_move(Vector2(local.x,local.z))
		var speed: float=Minions.TYPES[body.get_meta("subtype","scavenger")]["speed"] if fighter<0 else 5.0
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
	if not _can_shoot(id) or body.position.distance_to(target.position)>28 or not _clear_sight(body.position+Vector3.UP*1.5,target.position+Vector3.UP):return
	var aim:=target.position+Vector3.UP*(.8 if target.get_meta("role","")=="minion" else 1.4)
	if not _facing_target(body,aim):return
	_fire_weapon(id,aim)
func _minion_fire(body: CharacterBody3D,target: CharacterBody3D,delta: float) -> void:
	var definition: Dictionary=Minions.TYPES[body.get_meta("subtype")]
	var timer:=float(body.get_meta("attack"))-delta;body.set_meta("attack",timer)
	if timer>0 or definition["damage"]<=0 or body.position.distance_to(target.position)>22 or not _clear_sight(body.position+Vector3.UP*.9,target.position+Vector3.UP):return
	body.set_meta("attack",definition["interval"]);body.set_meta("muzzle",.12)
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
	var query:=PhysicsRayQueryParameters3D.create(origin,origin-basis.z*40,_ray_mask(id),[body.get_rid()]);query.collide_with_areas=true;query.hit_from_inside=true
	return get_world_3d().direct_space_state.intersect_ray(query)
func _tick_auto_combat(delta: float) -> void:
	for id in humans:
		if not _alive(id):continue
		var p: Dictionary=rules.players[id];var hit:=_target_for(id)
		if p["manual_left"]>0:
			if not hit.is_empty() and hit["collider"] is Area3D and cloud.orbs.get(int(hit["collider"].get_meta("orb",-1)),{}).get("gold",false):continue
			if _can_shoot(id):_fire_weapon(id)
			continue
		if hit.is_empty():p["deny_id"]=-1;p["deny_dwell"]=0.0;continue
		var target: Object=hit["collider"]
		if target is Area3D and target.has_meta("orb"):
			var orb:=int(target.get_meta("orb"))
			if cloud.orbs.get(orb,{}).get("gold",false) or p["suction"]>0:continue
			if p["deny_id"]!=orb:p["deny_id"]=orb;p["deny_dwell"]=0.0
			p["deny_dwell"]+=delta
			if p["deny_dwell"]>=.55 and _can_shoot(id):_fire_weapon(id)
		elif target is CharacterBody3D and _can_shoot(id):_fire_weapon(id)
func _fire_weapon(id: int,aim := Vector3.ZERO) -> void:
	if not _can_shoot(id):return
	var body:=_body(id);var data: Dictionary=Rules.WEAPONS[rules.players[id]["weapon"]]
	var basis:=Basis.from_euler(Vector3(rails[id].pitch,rails[id].aim_yaw,0)) if rails.has(id) else body.global_basis
	var origin: Vector3=body.get_node("MuzzleFlash").global_position if id!=local_id else camera.global_position
	if id==local_id:
		basis=camera.global_basis
		var hit:=_target_for(id)
		aim=hit.get("position",camera.global_position-camera.global_basis.z*38)
		origin=gun.global_transform*(Vector3(.19,-.157,-1.19) if rules.players[id]["weapon"]=="pump" else Vector3(.15,-.187,-.76))
		if is_instance_valid(weapon_frame):origin=weapon_frame.muzzle_world(origin)
		var blocked:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,origin,1))
		if not blocked.is_empty():origin=blocked["position"]+Vector3(blocked["normal"])*.04
	var state: Dictionary=lock_states.get(id,{})
	if float(state.get("charge",0))>=LOCK_TIME and float(state.get("ttl",0))>0:
		var target:=_lock_body(int(state["target"]))
		if is_instance_valid(target):aim=_lock_point(target)
	if aim!=Vector3.ZERO:basis=Basis.looking_at((aim-origin).normalized(),Vector3.UP)
	_spend_shot(id)
	var pellets:=int(data.get("pellets",1));var spread:=float(data.get("spread",.005))
	for i in range(pellets):
		var direction:=(-basis.z+basis.x*combat_random.randf_range(-spread,spread)+basis.y*combat_random.randf_range(-spread,spread)).normalized()
		projectiles.spawn(origin,direction*float(data.get("speed",75)),id,float(rules.stats(id)["damage"]),_ray_mask(id),Color("83c5ff") if rules.players[id]["team"]==0 else Color("ff8f7c"),body.get_rid(),.65)
	if id!=local_id:_play_distant(origin,data.has("pellets"))
func _projectile_impact(bullet: Dictionary,hit: Dictionary) -> void:
	var target: Object=hit["collider"]
	if target is Node and target.is_queued_for_deletion():return
	var owner_id:=int(bullet["owner"])
	if target is Area3D and target.has_meta("orb"):
		if owner_id>=0:cloud.destroy(int(target.get_meta("orb")))
	elif target is CharacterBody3D:
		if target==player:
			if owner_id<0 or rules.can_harm(owner_id,local_id):_damage_fighter(local_id,bullet["damage"],owner_id)
		elif target.has_meta("role"):
			if target.get_meta("role")=="minion":
				if owner_id>=0:_damage_entity(target,bullet["damage"],owner_id)
			else:_damage_fighter(int(target.get_meta("fighter")),bullet["damage"],owner_id)
func _play_distant(pos: Vector3,shotgun: bool) -> void:
	if not is_instance_valid(distant_shot):return
	var stream: AudioStream=load("res://assets/audio/shotgun_shot.wav") if shotgun else normal_shot
	if distant_shot.stream!=stream:distant_shot.stream=stream
	distant_shot.global_position=pos;distant_shot.play()
func _spend_shot(id: int) -> void:
	super._spend_shot(id)
	if id==local_id:pump_age=0;pump_sound_played=false
	if rules.players[id]["ammo"]==0 and rules.players[id]["reserve"]>0:_try_reload(id)
func _equip_viewmodel() -> void:
	if rules.players.is_empty() or not is_instance_valid(shotgun_rig):return
	var pump: bool=rules.players[local_id]["weapon"]=="pump"
	gun.get_node("DetailedSidearm").visible=not pump
	shotgun_rig.get_node("Shotgun").visible=pump;shotgun_rig.get_node("PumpSlide").visible=pump
	shotgun_rig.get_node("SupportArm").visible=pump and hand_amount<.2
	shotgun_rig.get_node("GripArm").show()
	if not pump:
		for mesh in gun.get_node("DetailedSidearm").find_children("*","MeshInstance3D",true,false):
			var material: Material=mesh.get_active_material(0)
			if material is StandardMaterial3D and ("Glove" in material.resource_name or "sleeve" in material.resource_name):mesh.hide()
	var desired_shot: AudioStream=load("res://assets/audio/shotgun_shot.wav") if pump else normal_shot
	if shot_sound.stream!=desired_shot:shot_sound.stream=desired_shot
	var desired_load: AudioStream=load("res://assets/audio/shotgun_load.wav") if pump else load("res://assets/audio/reload_lower.wav")
	if reload_lower_sound.stream!=desired_load:reload_lower_sound.stream=desired_load
	var desired_ready: AudioStream=load("res://assets/audio/shotgun_ready.wav") if pump else load("res://assets/audio/reload_raise.wav")
	if reload_raise_sound.stream!=desired_ready:reload_raise_sound.stream=desired_ready
	_set_weapon_audio_levels(pump)
func _tick_viewmodel(delta: float) -> void:
	super._tick_viewmodel(delta)
	gun.scale=Vector3.ONE*.88
	gun.position.x=-.10 if get_window().size.y>get_window().size.x else .025
	gun.position.y-=.20 if get_window().size.y>get_window().size.x else .04
	if get_window().size.y>get_window().size.x:
		gun.position.z-=.35
		hand_root.position.x=-.08
	if is_instance_valid(weapon_frame):weapon_frame.sync()
	pump_age+=delta
	flash.global_position=gun.global_transform*(Vector3(.19,-.157,-1.20) if rules.players[local_id]["weapon"]=="pump" else Vector3(.15,-.187,-.76))
	if rules.players[local_id]["weapon"]=="pump":
		var offset:=sin(clampf((pump_age-.18)/.32,0,1)*PI)*.11 if pump_age<.50 else 0.0
		shotgun_rig.get_node("PumpSlide").position.z=offset
		shotgun_rig.get_node("SupportArm").position.z=offset
		shotgun_rig.get_node("SupportArm").visible=hand_amount<.2
		if pump_age>.18 and not pump_sound_played and is_instance_valid(pump_sound):pump_sound.play();pump_sound_played=true
func _set_weapon_audio_levels(pump: bool) -> void:
	shot_sound.volume_db=-80 if sound_volume==0 else (-5 if pump else -12)+linear_to_db(sound_volume)
	for effect in [reload_lower_sound,reload_raise_sound]:effect.volume_db=-80 if sound_volume==0 else (-9 if pump else -17)+linear_to_db(sound_volume)

func _update_audio() -> void:
	super._update_audio()
	if not rules.players.is_empty():_set_weapon_audio_levels(rules.players[local_id]["weapon"]=="pump")
	if is_instance_valid(pump_sound):pump_sound.volume_db=-80 if sound_volume==0 else -13+linear_to_db(sound_volume);pump_sound.stream_paused=app_paused or (not demo and not net.in_match and screen!="play")
	if is_instance_valid(distant_shot):distant_shot.volume_db=-80 if sound_volume==0 else -20+linear_to_db(sound_volume)
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
	rules.players[local_id]["suction"]=1.5
	_tick_suction(delta);cloud.tick(delta,_collector_positions(),true);_tick_supplies(delta)
func _render_hud(delta: float) -> void:
	if rules.players.is_empty():return
	var p: Dictionary=rules.players[local_id];var stat:=rules.stats(local_id)
	var hit:=_target_for(local_id) if _alive(local_id) else {}
	var essence: bool=not hit.is_empty() and hit["collider"] is Area3D
	var gold: bool=essence and cloud.orbs.get(int(hit["collider"].get_meta("orb",-1)),{}).get("gold",false)
	var key: String=pad_input.button_name(pad_input.bindings["reload"]) if pad_input.active else "TAP"
	var hint: String=(key+" IN AMBER" if not p["reload_used"] else "RELOADING") if p["reload"]>0 else (("FIND AMMO") if p["ammo"]==0 else "GOLD / HARVEST ONLY" if gold else "BLUE ESSENCE / HARVEST OR DENY" if essence else "")
	var notice: String=toast if toast_left>0 else ""
	if not _alive(local_id):notice="RESPAWN / %.0f" % ceilf(p["respawn"]) if p["lives"]>0 else "ELIMINATED / WATCHING THE ROUND"
	hud_ui.update_view({"team":p["team"],"lives":p["lives"],"souls":p["souls"],"frags":p["frags"],"remaining":rules.remaining,"round":rules.round_index,"phase_name":["COLLECTION A","SHOP","SHARED ROLL","HUNTING B","MATCH COMPLETE"][rules.phase],"health":p["hp"],"shield":p["shield"],"max_health":stat["health"],"max_shield":stat["shield"],"ammo":p["ammo"],"reserve":p["reserve"],"weapon":Rules.WEAPONS[p["weapon"]]["name"],"notice":notice,"lock_progress":_lock_progress(local_id),"lock_active":float(lock_states.get(local_id,{}).get("ttl",0))>0,"lock_rect":_lock_rect(),"route_hint":"%s / %s" % [conditions.get("time",""),conditions.get("weather","")],"routes":{},"queued":"","can_drop":false,"jumps":rails[local_id].jumps if rails.has(local_id) else 0,"alive":_alive(local_id),"can_collect":rules.phase==Rules.Phase.COLLECTION,"locked":not hit.is_empty() and hit["collider"] is CharacterBody3D,"essence_target":essence,"essence_gold":gold,"reload_hint":hint,"reload_progress":1.0-p["reload"]/maxf(.1,p["reload_total"]) if p["reload"]>0 else -1.0,"reload_used":p["reload_used"],"reload_success":p["reload_flash"]*2,"rewards":rules.rewards,"names":_player_names(),"conditions":conditions,"prelude":prelude_left},delta)
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
	lock_states=packet.get("locks",{}).duplicate(true)
	if prelude_left>0 and screen!="conditions":_show("conditions",{"conditions":conditions})
	elif prelude_left<=0 and screen=="conditions":_show("play")
	for shooter in packet["shots"]:
		if shooter==local_id:pump_age=0;pump_sound_played=false
		elif is_instance_valid(_body(int(shooter))):_play_distant(_body(int(shooter)).position,int(shooter)<rules.players.size() and rules.players[int(shooter)]["weapon"]=="pump")
func _client_tick(delta: float) -> void:
	rules.remaining=maxf(0,rules.remaining-delta)
	if rules.phase in [Rules.Phase.COLLECTION,Rules.Phase.HUNT] and _alive(local_id):
		rails[local_id].step(player,course,delta);camera.position=Vector3(0,1.75,0);camera.rotation=Vector3(rails[local_id].pitch,0,0)
	aim_send_left-=delta
	if aim_send_left<=0:net.send_action("aim",Vector2(rails[local_id].aim_yaw,rails[local_id].pitch));aim_send_left=.05
	for body in entities.values():
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
	if not lock_states.has(id):lock_states[id]={"ttl":0.0,"target":-1,"charge":0.0}
	lock_states[id]["ttl"]=.5 if pressed else 0.0
	if not pressed:lock_states[id]["target"]=-1;lock_states[id]["charge"]=0.0
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
	if offset.length()>32:return false
	var m=rails[id];var forward: Vector3=-Basis.from_euler(Vector3(m.pitch,m.aim_yaw,0)).z
	return forward.dot(offset.normalized())>cos(deg_to_rad(55 if sticky else 22)) and _clear_sight(origin,_lock_point(target))
func _tick_locks(delta: float) -> void:
	for id in lock_states.keys():
		if not _authority() and id!=local_id:continue
		var state: Dictionary=lock_states[id]
		state["ttl"]=maxf(0,float(state["ttl"])-delta)
		if state["ttl"]<=0 or not _alive(id):state["target"]=-1;state["charge"]=0.0;continue
		var target:=_lock_body(int(state["target"]))
		if not _valid_lock(id,target,true):
			state["target"]=-1;state["charge"]=0.0;target=null
			var best:=INF
			for candidate in entities.values()+[player]:
				if not _valid_lock(id,candidate):continue
				var offset:=_lock_point(candidate)-(_body(id).position+Vector3.UP*1.65)
				var m=rails[id];var forward: Vector3=-Basis.from_euler(Vector3(m.pitch,m.aim_yaw,0)).z
				var score:=1.0-forward.dot(offset.normalized())
				if score<best:best=score;target=candidate
			if is_instance_valid(target):state["target"]=local_id if target==player else int(target.get_meta("key"))
		if not is_instance_valid(target):continue
		state["charge"]=minf(LOCK_TIME,float(state["charge"])+delta)
		var m=rails[id];var diff:=_lock_point(target)-(_body(id).position+Vector3.UP*1.65)
		m.aim_yaw=_turn_toward(m.aim_yaw,atan2(-diff.x,-diff.z),delta*3.4)
		m.pitch=move_toward(m.pitch,asin(diff.normalized().y),delta*2.7)
		_body(id).rotation.y=m.aim_yaw
		if id==local_id:camera.rotation=Vector3(m.pitch,0,0)
func _can_shoot(id: int) -> bool:
	if not super._can_shoot(id):return false
	var state: Dictionary=lock_states.get(id,{})
	if float(state.get("ttl",0))<=0:return true
	return float(state.get("charge",0))>=LOCK_TIME and _valid_lock(id,_lock_body(int(state.get("target",-1))),true)
func _lock_progress(id: int) -> float:return clampf(float(lock_states.get(id,{}).get("charge",0))/LOCK_TIME,0,1)
func _lock_rect() -> Rect2:
	var state: Dictionary=lock_states.get(local_id,{})
	if float(state.get("ttl",0))<=0:return Rect2()
	var target:=_lock_body(int(state.get("target",-1)))
	if not is_instance_valid(target) or camera.is_position_behind(target.position+Vector3.UP):return Rect2()
	var height:=1.8 if target.get_meta("role","")=="minion" else 2.4
	var a:=camera.unproject_position(target.position+Vector3.UP*height)
	var b:=camera.unproject_position(target.position)
	var extent:=maxf(12,absf(b.y-a.y)*.32)
	return Rect2(Vector2((a.x+b.x)*.5-extent,minf(a.y,b.y)-5),Vector2(extent*2,absf(b.y-a.y)+10))
func _tick_fighter_states(delta: float) -> void:
	super._tick_fighter_states(delta)
	for p in rules.players:
		if _alive(p["id"]) and p["ammo"]==0 and p["reserve"]>0 and p["reload"]<=0:_try_reload(p["id"])
