extends "res://scripts/main.gd"
## Rail movement and route choices; aiming remains independent of the run direction.
const CorridorMap = preload("res://scripts/corridor_map.gd")
const RunnerReticle = preload("res://scripts/runner_reticle.gd")
const RUN_SPEED := 5.6
const JUMP_SPEED := 7.8
var course := CorridorMap.new()
var course_root: Node3D
var environment: Environment
var biome := 0
var origin_node := 22
var target_node := 17
var queued_node := -1
var route_options: Dictionary = {}
var route_buttons: Dictionary = {}
var jump_button: Button
var down_button: Button
var biome_button: Button
var route_status: Label
var aim_reticle: Control
var aim_yaw := 0.0
var jumps := 0
var coyote := 0.0
var distance_run := 0.0
var junctions := 0
var blocked_time := 0.0
var bot_respawn_left := 0.0
var notice := ""
var notice_left := 0.0
var has_started := false
var touch_aim := -1
var credits_button: Button
var credits_open := false

func _ready() -> void:
	Engine.max_fps = 60
	_make_player()
	_make_audio()
	_make_ui()
	_reset_run()
	_show_menu("DOMINION '99", "AUTO-RUN / ROUTE COMBAT\n\nDrag to aim at bots to auto-fire.\nYour weapon reloads automatically.\nChoose LEFT, AHEAD, RIGHT or DOWN.\nJUMP at ledges; tap again in the air\nfor a double jump.\n\nOffline bots share your hallways.", "START RUN")

func _build_course() -> void:
	if is_instance_valid(course_root):
		course_root.free()
	if environment == null:
		var world := WorldEnvironment.new()
		environment = Environment.new()
		var sky := Sky.new()
		var panorama := PanoramaSkyMaterial.new()
		panorama.panorama = load("res://assets/textures/lighting/kiara_1_dawn_1k.hdr")
		sky.sky_material = panorama
		sky.radiance_size = Sky.RADIANCE_SIZE_128
		environment.sky = sky
		environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		world.environment = environment
		add_child(world)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-55, -35, 0)
		sun.light_energy = 1.0
		sun.shadow_enabled = true
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_max_distance = 22.0
		add_child(sun)
	environment.background_mode = Environment.BG_SKY if biome >= 3 else Environment.BG_COLOR
	environment.background_color = CorridorMap.THEMES[biome][4]
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b6c9bf")
	environment.ambient_light_energy = 0.9
	environment.fog_enabled = true
	environment.fog_light_color = CorridorMap.THEMES[biome][4]
	environment.fog_density = 0.012
	environment.fog_sky_affect = 0.2
	course_root = course.build(self, biome)

func _reset_run() -> void:
	shot_sound.stop()
	for enemy in enemies:
		enemy.free()
	enemies.clear()
	for pickup in pickups:
		pickup.free()
	pickups.clear()
	_build_course()
	origin_node = 22
	target_node = 17
	queued_node = -1
	player.position = course.nodes[origin_node] + Vector3.UP * 0.06
	player.velocity = Vector3.ZERO
	player.rotation.y = 0
	camera.rotation = Vector3.ZERO
	aim_yaw = 0
	pitch = 0
	health = 100
	shield = MAX_SHIELD
	shield_delay_left = 0
	ammo = MAG_SIZE
	reserve = 72
	reload_left = 0
	fire_left = 0
	hit_left = 0
	flash_left = 0
	hurt = 0
	damage.color.a = 0
	flash.visible = false
	jumps = 0
	coyote = 0.15
	distance_run = 0
	junctions = 0
	kills = 0
	blocked_time = 0
	notice_left = 0
	finished = false
	for id in [12, 7, 6, 18, 11, 13]:
		_spawn_bot(id)
	for id in [2, 6, 10, 14, 18, 20, 24]:
		_add_pickup(course.nodes[id] + Vector3.UP * 0.5, "health" if id % 2 else "ammo")
	_update_choices()
	_update_hud()

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var top := _hud_panel(root, Vector2.ZERO, Vector2(16, 28), Vector2(508, 88))
	hud = _label(root, "", Vector2(28, 34), Vector2(390, 74), 20)
	status = _label(root, "", Vector2.ZERO, Vector2(492, 54), 18)
	_place(status, Vector2(0.5, 0), Vector2(-246, 122), Vector2(492, 54))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_status = _label(root, "", Vector2.ZERO, Vector2(508, 54), 19)
	_place(route_status, Vector2(0.5, 1), Vector2(-254, -450), Vector2(508, 54))
	route_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aim_reticle = RunnerReticle.new()
	aim_reticle.name = "Crosshair"
	aim_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(aim_reticle)
	_place(aim_reticle, Vector2(0.5, 0.5), Vector2(-28, -28), Vector2(56, 56))
	health_frame = _hud_panel(root, Vector2(0, 1), Vector2(16, -154), Vector2(220, 116))
	health_label = _label(health_frame, "", Vector2(12, 8), Vector2(196, 30), 21)
	health_label.add_theme_color_override("font_color", Color("8be5ab"))
	health_bar = _meter(health_frame, Vector2(12, 40), Color("8be5ab"))
	shield_label = _label(health_frame, "", Vector2(12, 53), Vector2(196, 30), 21)
	shield_label.add_theme_color_override("font_color", Color("64deea"))
	shield_bar = _meter(health_frame, Vector2(12, 86), Color("64deea"))
	ammo_frame = _hud_panel(root, Vector2(1, 1), Vector2(-236, -154), Vector2(220, 116))
	_label(ammo_frame, "D-9 / AUTO", Vector2(12, 8), Vector2(196, 26), 16)
	ammo_label = _label(ammo_frame, "", Vector2(12, 36), Vector2(196, 62), 32)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_color_override("font_color", Color("f2ad56"))
	for key in ["left", "ahead", "right"]:
		var button := _button(root, key.to_upper(), Vector2.ZERO, Vector2(148, 68), _choose.bind(key))
		button.add_theme_font_size_override("font_size", 17)
		var x: float = {"left": -254.0, "ahead": -74.0, "right": 106.0}[key]
		_place(button, Vector2(0.5, 1), Vector2(x, -300), Vector2(148, 68))
		route_buttons[key] = button
	jump_button = _button(root, "JUMP", Vector2.ZERO, Vector2(156, 68), _jump)
	_place(jump_button, Vector2(0, 1), Vector2(16, -394), Vector2(156, 68))
	down_button = _button(root, "DOWN", Vector2.ZERO, Vector2(156, 68), _choose_down)
	_place(down_button, Vector2(1, 1), Vector2(-172, -394), Vector2(156, 68))
	pause_button = _button(root, "II", Vector2.ZERO, Vector2(58, 56), _pause)
	_place(pause_button, Vector2(1, 0), Vector2(-82, 42), Vector2(58, 56))
	damage = ColorRect.new()
	damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage.color = Color(0.8, 0.1, 0.05, 0)
	root.add_child(damage)
	menu = Panel.new()
	menu.add_theme_stylebox_override("panel", _style(Color("101a1c")))
	root.add_child(menu)
	_place(menu, Vector2(0.5, 0.5), Vector2(-242, -310), Vector2(484, 620))
	menu_title = _label(menu, "", Vector2(24, 24), Vector2(436, 60), 34)
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_body = _label(menu, "", Vector2(24, 104), Vector2(436, 280), 20)
	menu_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	biome_button = _button(menu, "", Vector2(30, 410), Vector2(424, 64), _cycle_biome)
	start_button = _button(menu, "START RUN", Vector2(54, 504), Vector2(376, 64), _start)
	credits_button = _button(menu, "ART CREDITS", Vector2(144, 582), Vector2(196, 28), _show_credits)
	credits_button.add_theme_font_size_override("font_size", 13)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_menu(title: String, body: String, action: String) -> void:
	super._show_menu(title, body, action)
	credits_open = false
	biome_button.show()
	credits_button.show()
	touch_aim = -1
	for enemy in enemies:
		if enemy.has_meta("animation"):
			enemy.get_meta("animation").active = false
	biome_button.disabled = false
	biome_button.text = "BIOME: " + CorridorMap.NAMES[biome]
	_update_choices()

func _show_credits() -> void:
	credits_open = true
	menu_title.text = "ART CREDITS"
	menu_body.text = "Sinbad creature: © Zi Ye\nCC BY-SA 3.0 / adapted model\ncreativecommons.org/licenses/by-sa/3.0/\n\nTextures: ambientCG / CC0\nSky: Poly Haven / CC0\n\nWeapon and other code: Dominion '99\nFull credits: repository ASSET_CREDITS.md"
	biome_button.hide()
	credits_button.hide()
	start_button.text = "BACK"

func _cycle_biome() -> void:
	biome = (biome + 1) % CorridorMap.NAMES.size()
	_reset_run()
	has_started = false
	biome_button.text = "BIOME: " + CorridorMap.NAMES[biome]
	_show_menu("NEW RUN", "Choose your next biome.\n\nDrag to aim / automatic fire and reload.\nQueue turns at the next junction.\nTime jumps at the marked ledges.\n\nYour new run starts with full supplies.", "START RUN")

func _start() -> void:
	if credits_open:
		_show_menu("DOMINION '99", "AUTO-RUN / ROUTE COMBAT\n\nDrag to aim at bots to auto-fire.\nYour weapon reloads automatically.\nChoose your route and time your jumps.\n\nOffline bots share your hallways.", "RESUME" if has_started and not finished else "START RUN")
		return
	if finished:
		_reset_run()
	menu.hide()
	running = true
	has_started = true
	for enemy in enemies:
		if enemy.has_meta("animation"):
			enemy.get_meta("animation").active = true
	_update_choices()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _pause() -> void:
	if running:
		_show_menu("PAUSED", "Your route is waiting.\n\nAim with a drag.\nChoose your next hallway.\nTime your jumps at the marked gaps.\n\nChanging biome starts a fresh run.", "RESUME")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if running:
				_pause()
			elif not finished:
				_start()
		if running:
			if event.keycode in [KEY_A, KEY_LEFT]:
				_choose("left")
			if event.keycode in [KEY_D, KEY_RIGHT]:
				_choose("right")
			if event.keycode in [KEY_W, KEY_UP]:
				_choose("ahead")
			if event.keycode in [KEY_S, KEY_DOWN]:
				_choose_down()
			if event.keycode == KEY_SPACE:
				_jump()
	if event is InputEventScreenTouch:
		if event.pressed and _touch_button(event.position):
			get_viewport().set_input_as_handled()
			return
		if running and event.pressed and touch_aim == -1:
			touch_aim = event.index
		elif not event.pressed and event.index == touch_aim:
			touch_aim = -1
		return
	if not running:
		return
	if event is InputEventScreenDrag and event.index == touch_aim:
		_look(event.relative * 0.0035)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.relative * 0.0025)

func _touch_button(point: Vector2) -> bool:
	# Handle each touch directly so a second thumb can turn/jump while aiming.
	var controls: Array = [start_button, biome_button, credits_button] if menu.visible else route_buttons.values() + [jump_button, down_button, pause_button]
	for control in controls:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(point):
			if not control.disabled:
				control.pressed.emit()
			return true
	return false

func _over_button(point: Vector2) -> bool:
	var controls: Array = route_buttons.values() + [jump_button, down_button, pause_button]
	for control in controls:
		if control.get_global_rect().has_point(point):
			return true
	return false

func _look(delta: Vector2) -> void:
	aim_yaw = clampf(aim_yaw - delta.x, -1.1, 1.1)
	pitch = clampf(pitch - delta.y, -0.95, 0.95)
	camera.rotation = Vector3(pitch, aim_yaw, 0)

func _options() -> Dictionary:
	var result: Dictionary = {}
	var forward := course.direction(origin_node, target_node)
	var right := Vector3(-forward.z, 0, forward.x)
	for id in course.links[target_node]:
		if id == origin_node:
			continue
		var d := course.direction(target_node, id)
		var side := d.dot(right)
		result["right" if side > 0.5 else ("left" if side < -0.5 else "ahead")] = id
	if result.is_empty():
		result["ahead"] = origin_node
	return result

func _choose(key: String) -> void:
	if running and route_options.has(key):
		queued_node = route_options[key]
		_update_choices()

func _choose_down() -> void:
	if not running:
		return
	for key in route_options:
		if course.climb(target_node, route_options[key]) < 0:
			_choose(key)
			return

func _jump() -> void:
	if not running or jumps >= 2:
		return
	if jumps == 0 and not player.is_on_floor() and coyote <= 0:
		return
	player.velocity.y = JUMP_SPEED
	jumps += 1
	coyote = 0
	_update_choices()

func _update_choices() -> void:
	route_options = _options()
	var has_drop := false
	for key in route_buttons:
		var button: Button = route_buttons[key]
		button.disabled = not running or not route_options.has(key)
		var suffix := ""
		if route_options.has(key):
			var id: int = route_options[key]
			var climb := course.climb(target_node, id)
			has_drop = has_drop or climb < 0
			suffix = { -1: "\nDROP", 0: "", 1: "\nJUMP", 2: "\n2x JUMP" }[climb]
			if queued_node == id:
				suffix += " ✓"
		button.text = key.to_upper() + suffix
	down_button.disabled = not running or not has_drop
	down_button.modulate.a = 1.0 if has_drop else 0.35
	jump_button.disabled = not running or jumps >= 2
	jump_button.text = "JUMP AGAIN" if jumps == 1 else ("AIRBORNE" if jumps >= 2 else "JUMP")

func _physics_process(delta: float) -> void:
	if not running:
		return
	_tick_shield(delta)
	fire_left = maxf(0, fire_left - delta)
	hit_left = maxf(0, hit_left - delta)
	flash_left = maxf(0, flash_left - delta)
	flash.visible = flash_left > 0
	hurt = maxf(0, hurt - delta)
	damage.color.a = hurt * 0.7
	recoil = move_toward(recoil, 0, delta * 0.8)
	gun.position.z = recoil
	gun.position.y = sin(distance_run * 5.0) * 0.003
	gun.rotation.x = -recoil * 0.55
	gun.rotation.z = -sin(clampf(reload_left / 1.25, 0, 1) * PI) * 0.35
	notice_left = maxf(0, notice_left - delta)
	_tick_auto_reload(delta)
	_run_forward(delta)
	if not running:
		return
	_tick_enemies(delta)
	if not running:
		return
	_tick_pickups(delta)
	_tick_auto_fire()
	bot_respawn_left -= delta
	if enemies.size() < 6 and bot_respawn_left <= 0:
		var farthest := 0
		for i in range(course.nodes.size()):
			if course.nodes[i].distance_to(player.position) > course.nodes[farthest].distance_to(player.position):
				farthest = i
		_spawn_bot(farthest)
		bot_respawn_left = 3.0
	_update_choices()
	_update_hud()

func _tick_auto_fire() -> void:
	var target := _target_enemy()
	aim_reticle.locked = target != null
	aim_reticle.hit = hit_left > 0
	aim_reticle.queue_redraw()
	if target != null and reload_left <= 0:
		_shoot()
		if ammo == 0:
			_reload()

func _tick_auto_reload(delta: float) -> void:
	if reload_left > 0:
		reload_left -= delta
		if reload_left <= 0:
			var amount := mini(MAG_SIZE - ammo, reserve)
			ammo += amount
			reserve -= amount
	if ammo == 0 and reserve > 0 and reload_left <= 0:
		_reload()

func _target_enemy() -> CharacterBody3D:
	var start := camera.global_position
	var hit := _ray(start, start - camera.global_basis.z * 45, [player.get_rid()])
	return hit.collider if not hit.is_empty() and hit.collider is CharacterBody3D and hit.collider in enemies else null

func _run_forward(delta: float) -> void:
	var destination := course.nodes[target_node]
	var offset := destination - player.position
	offset.y = 0
	var dir := offset.normalized()
	var remaining := offset.length()
	var heading := course.direction(origin_node, target_node)
	player.rotation.y = lerp_angle(player.rotation.y, atan2(-heading.x, -heading.z), minf(1, delta * 9))
	if player.is_on_floor() and player.velocity.y <= 0:
		jumps = 0
		coyote = 0.12
	else:
		coyote = maxf(0, coyote - delta)
	player.velocity.x = dir.x * RUN_SPEED if remaining > 0.25 else 0.0
	player.velocity.z = dir.z * RUN_SPEED if remaining > 0.25 else 0.0
	player.velocity.y -= 18 * delta
	var before := player.position
	player.move_and_slide()
	var travel := Vector2(player.position.x - before.x, player.position.z - before.z).length()
	distance_run += travel
	blocked_time = blocked_time + delta if travel < 0.005 and remaining > 0.5 and player.is_on_floor() else 0.0
	if player.position.y < minf(course.nodes[origin_node].y, destination.y) - 4 or blocked_time > 1.5:
		_recover_route()
		return
	if remaining < 0.4 and player.is_on_floor() and absf(player.position.y - destination.y) < 0.3:
		_arrive()

func _arrive() -> void:
	var options := _options()
	var next: int = queued_node if queued_node in options.values() else options.get("ahead", options.values()[0])
	origin_node = target_node
	target_node = next
	queued_node = -1
	junctions += 1
	aim_yaw = 0
	camera.rotation.y = 0
	blocked_time = 0
	if junctions % 4 == 0:
		_add_pickup(course.nodes[origin_node] + Vector3.UP * 0.5, "ammo" if junctions % 8 == 0 else "health")
	_update_choices()

func _recover_route() -> void:
	_take_damage(25)
	if not running:
		return
	player.position = course.nodes[origin_node] + Vector3.UP * 0.06
	player.velocity = Vector3.ZERO
	jumps = 0
	coyote = 0.15
	blocked_time = 0
	notice = "MISSED LANDING / -25 SHIELD OR HEALTH"
	notice_left = 2.0

func _spawn_bot(node: int) -> void:
	var enemy := CharacterBody3D.new()
	add_child(enemy)
	enemy.collision_layer = 2
	enemy.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	col.position.y = 0.9
	enemy.add_child(col)
	var shoulder_hitbox := CollisionShape3D.new()
	var torso := BoxShape3D.new()
	torso.size = Vector3(1.25, 0.55, 0.55)
	shoulder_hitbox.shape = torso
	shoulder_hitbox.position.y = 1.16
	enemy.add_child(shoulder_hitbox)
	art.build_enemy(enemy)
	if enemy.has_meta("animation"):
		enemy.get_meta("animation").active = running
	var next: int = course.links[node][0]
	enemy.position = course.nodes[node]
	enemy.set_meta("from", node)
	enemy.set_meta("to", next)
	enemy.set_meta("progress", 0.0)
	enemy.set_meta("hp", 100)
	enemy.set_meta("attack", 2.0)
	enemy.set_meta("muzzle", 0.0)
	enemies.append(enemy)

func _tick_enemies(delta: float) -> void:
	for enemy in enemies:
		var a := int(enemy.get_meta("from"))
		var b := int(enemy.get_meta("to"))
		var progress := float(enemy.get_meta("progress")) + delta * 3.6 / CorridorMap.STEP
		if progress >= 1:
			var choices: Array = []
			for id in course.links[b]:
				if id != a:
					choices.append(id)
			if choices.is_empty():
				choices.append(a)
			a = b
			# Deterministic varied routes make repeat encounters possible.
			b = choices[(int(enemy.get_instance_id()) + junctions + int(distance_run / 8)) % choices.size()]
			progress -= 1
			enemy.set_meta("from", a)
			enemy.set_meta("to", b)
		enemy.set_meta("progress", progress)
		var dir := course.direction(a, b)
		var side := Vector3(-dir.z, 0, dir.x)
		enemy.position = course.nodes[a].lerp(course.nodes[b], progress) + side * 0.55
		if course.climb(a, b) > 0:
			enemy.position.y += sin(progress * PI) * (2.0 if course.climb(a, b) == 2 else 1.0)
		art.animate_enemy(enemy, "Jump" if course.climb(a, b) > 0 and progress > 0.25 and progress < 0.8 else "Run")
		enemy.rotation.y = atan2(-dir.x, -dir.z)
		var muzzle := maxf(0, float(enemy.get_meta("muzzle")) - delta)
		var attack := float(enemy.get_meta("attack")) - delta
		if attack <= 0 and enemy.position.distance_to(player.position) < 18:
			var hit := _ray(enemy.position + Vector3.UP * 1.45, camera.global_position, [enemy.get_rid()])
			if not hit.is_empty() and hit.collider == player:
				_take_damage(6)
				attack = 2.0
				muzzle = 0.12
		enemy.set_meta("attack", attack)
		enemy.set_meta("muzzle", muzzle)
		enemy.get_node("MuzzleFlash").visible = muzzle > 0
		if not running:
			return

func _update_hud() -> void:
	hud.text = "%s\n%d m  /  %d ROUTES  /  %d KILLS" % [CorridorMap.NAMES[biome], int(distance_run), junctions, kills]
	health_label.text = "HEALTH  %03d" % health
	shield_label.text = "SHIELD  %03d%s" % [ceili(shield), " +" if shield < MAX_SHIELD and shield_delay_left <= 0 else ""]
	health_bar.value = health
	shield_bar.value = shield
	ammo_label.text = "%02d / %02d" % [ammo, reserve]
	status.text = "AUTO-RELOADING" if reload_left > 0 else ("FIND AMBER AMMO" if ammo == 0 and reserve == 0 else "AIM AT A BOT TO AUTO-FIRE")
	var remaining := Vector2(course.nodes[target_node].x - player.position.x, course.nodes[target_node].z - player.position.z).length()
	var rise := course.climb(origin_node, target_node)
	var gap_distance := remaining - 6.6
	if notice_left > 0:
		route_status.text = notice
	elif rise > 0 and gap_distance > -0.5 and gap_distance < 4:
		route_status.text = ("DOUBLE JUMP" if rise == 2 else "JUMP") + " / LEDGE IN %.1f m" % maxf(0, gap_distance)
	else:
		route_status.text = "JUNCTION IN %.0f m\n%s" % [remaining, "ROUTE QUEUED" if queued_node >= 0 else "CHOOSE A ROUTE / DEFAULT AHEAD"]
	biome_button.text = "BIOME: " + CorridorMap.NAMES[biome]

func _end(_won: bool) -> void:
	finished = true
	_show_menu("RUN ENDED", "%s\n\n%d metres travelled\n%d junctions / %d bots defeated\n\nChoose a biome and run again." % [CorridorMap.NAMES[biome], int(distance_run), junctions, kills], "RUN AGAIN")
