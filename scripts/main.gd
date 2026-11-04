extends Node3D
## Small, asset-free FPS prototype. All dimensions use metres.

const SPEED := 5.8
const MAG_SIZE := 12
const LAST_WAVE := 3
var player: CharacterBody3D
var camera: Camera3D
var gun: Node3D
var enemies: Array[CharacterBody3D] = []
var pickups: Array[Node3D] = []
var health := 100
var ammo := MAG_SIZE
var reserve := 72
var wave := 0
var kills := 0
var running := false
var finished := false
var reload_left := 0.0
var fire_left := 0.0
var wave_wait := 1.5
var hurt := 0.0
var recoil := 0.0
var move_finger := -1
var look_finger := -1
var move_origin := Vector2.ZERO
var move_input := Vector2.ZERO
var pitch := 0.0
var hud: Label
var status: Label
var damage: ColorRect
var menu: Panel
var menu_title: Label
var menu_body: Label
var start_button: Button
var fire_button: Button
var reload_button: Button
var pause_button: Button
var quality_button: Button
var pad: Panel
var knob: Panel
var low_power := false
var flash: MeshInstance3D
var flash_left := 0.0
var shot_sound: AudioStreamPlayer

func _ready() -> void:
	Engine.max_fps = 60
	_make_arena()
	_make_player()
	_make_audio()
	_make_ui()
	_show_menu("DOMINION '99", "LITE / OFFLINE ARENA\n\nClear 3 waves. Collect green health and amber ammo.\nLeft thumb: move • Right thumb: aim • FIRE: shoot\nDesktop: WASD / mouse / click / R / Esc", "DEPLOY")

func _material(color: Color, glow := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	if glow:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid := true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(body)
	body.position = pos
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = _material(color)
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		collision.shape = box
		body.add_child(collision)
	return body

func _make_arena() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("15202d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a4b5c5")
	env.ambient_light_energy = 0.7
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, -25, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = false
	add_child(sun)
	_box(self, Vector3(0, -0.3, 0), Vector3(36, 0.6, 36), Color("39444c"))
	for z in [-18.0, 18.0]:
		_box(self, Vector3(0, 2, z), Vector3(37, 4, 1), Color("566773"))
		_box(self, Vector3(0, 2.8, z * 0.97), Vector3(36, 0.22, 0.1), Color("c5dc89"), false)
	for x in [-18.0, 18.0]:
		_box(self, Vector3(x, 2, 0), Vector3(1, 4, 36), Color("465963"))
	for x in [-7.0, 7.0]:
		for z in [-6.0, 6.0]:
			_box(self, Vector3(x, 1.25, z), Vector3(2.5, 2.5, 2.5), Color("647573"))
			_box(self, Vector3(x, 2.55, z), Vector3(2.6, 0.12, 2.6), Color("b6ca88"), false)
	for i in range(-4, 5):
		_box(self, Vector3(i * 4, 0.012, 0), Vector3(0.035, 0.015, 35), Color("53616a"), false)
		_box(self, Vector3(0, 0.013, i * 4), Vector3(35, 0.015, 0.035), Color("53616a"), false)
	_add_pickup(Vector3(-12, 0.5, 0), "health")
	_add_pickup(Vector3(12, 0.5, 0), "ammo")

func _make_player() -> void:
	player = CharacterBody3D.new()
	add_child(player)
	player.position = Vector3(0, 0.1, 11)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.7
	collision.shape = shape
	collision.position.y = 0.85
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position.y = 1.55
	camera.fov = 78
	camera.far = 65
	player.add_child(camera)
	gun = Node3D.new()
	camera.add_child(gun)
	_box(gun, Vector3(0.25, -0.22, -0.48), Vector3(0.13, 0.14, 0.42), Color("25313a"), false)
	_box(gun, Vector3(0.25, -0.34, -0.35), Vector3(0.10, 0.23, 0.12), Color("65706a"), false)
	_box(gun, Vector3(0.25, -0.14, -0.48), Vector3(0.04, 0.025, 0.36), Color("d6e8a6"), false)
	flash = MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.10
	flash_mesh.height = 0.18
	flash.mesh = flash_mesh
	flash.material_override = _material(Color("ffe9a0"), true)
	flash.position = Vector3(0.25, -0.21, -0.74)
	gun.add_child(flash)
	flash.visible = false

func _make_audio() -> void:
	# Short synthesized effect keeps the project free of external assets.
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(2205 * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(2205):
		var t := float(i) / 22050.0
		var sample := (rng.randf_range(-1, 1) * 0.65 + sin(t * 650.0) * 0.35) * exp(-t * 65.0)
		bytes.encode_s16(i * 2, int(sample * 16000))
	sound.data = bytes
	shot_sound = AudioStreamPlayer.new()
	shot_sound.stream = sound
	shot_sound.volume_db = -12
	add_child(shot_sound)

func _style(color: Color, radius := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(2)
	s.border_color = Color(0.65, 0.78, 0.65, 0.4)
	return s

func _label(parent: Node, text_value: String, pos: Vector2, size: Vector2, font_size := 22) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("dfebda"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text_value: String, pos: Vector2, size: Vector2, action: Callable) -> Button:
	var b := Button.new()
	b.text = text_value
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_stylebox_override("normal", _style(Color(0.06, 0.12, 0.16, 0.8)))
	b.add_theme_stylebox_override("pressed", _style(Color("526a4d")))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud = _label(root, "", Vector2(24, 16), Vector2(730, 40), 23)
	status = _label(root, "", Vector2(200, 75), Vector2(560, 50), 23)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var crosshair := _label(root, "+", Vector2(465, 249), Vector2(30, 42), 30)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pad = Panel.new()
	pad.position = Vector2(45, 350)
	pad.size = Vector2(145, 145)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_stylebox_override("panel", _style(Color(0.1, 0.2, 0.23, 0.35), 72))
	root.add_child(pad)
	knob = Panel.new()
	knob.size = Vector2(50, 50)
	knob.position = Vector2(47.5, 47.5)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.add_theme_stylebox_override("panel", _style(Color(0.7, 0.85, 0.65, 0.45), 25))
	pad.add_child(knob)
	fire_button = _button(root, "FIRE", Vector2(810, 355), Vector2(120, 120), _shoot)
	reload_button = _button(root, "RELOAD", Vector2(660, 440), Vector2(130, 65), _reload)
	pause_button = _button(root, "II", Vector2(875, 18), Vector2(60, 48), _pause)
	damage = ColorRect.new()
	damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage.color = Color(0.8, 0.1, 0.05, 0)
	damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage)
	menu = Panel.new()
	menu.position = Vector2(155, 75)
	menu.size = Vector2(650, 390)
	menu.add_theme_stylebox_override("panel", _style(Color("101d26"), 16))
	root.add_child(menu)
	menu_title = _label(menu, "", Vector2(30, 20), Vector2(590, 60), 40)
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_body = _label(menu, "", Vector2(30, 95), Vector2(590, 175), 20)
	menu_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_button = _button(menu, "DEPLOY", Vector2(35, 300), Vector2(280, 60), _start)
	quality_button = _button(menu, "60 FPS TARGET", Vector2(335, 300), Vector2(280, 60), _quality)
	_update_hud()

func _quality() -> void:
	low_power = not low_power
	Engine.max_fps = 30 if low_power else 60
	quality_button.text = "30 FPS / SAVE POWER" if low_power else "60 FPS TARGET"

func _show_menu(title: String, body: String, action: String) -> void:
	running = false
	move_finger = -1
	look_finger = -1
	move_input = Vector2.ZERO
	menu_title.text = title
	menu_body.text = body
	start_button.text = action
	menu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _start() -> void:
	if finished:
		get_tree().reload_current_scene()
		return
	menu.hide()
	running = true
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _pause() -> void:
	if running:
		_show_menu("PAUSED", "DOMINION '99 (LITE)\n\nTake a breather. Your arena is waiting.\nUse 30 FPS to reduce power use and heat.", "RESUME")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and running:
		_pause()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if running:
				_pause()
			elif not finished:
				_start()
		if event.keycode == KEY_R and running:
			_reload()
	if not running:
		return
	if event is InputEventScreenTouch:
		if not event.pressed:
			if event.index == move_finger:
				move_finger = -1
				move_input = Vector2.ZERO
			if event.index == look_finger:
				look_finger = -1
		elif not _over_button(event.position):
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.43 and move_finger == -1:
				move_finger = event.index
				move_origin = event.position
			elif look_finger == -1:
				look_finger = event.index
	if event is InputEventScreenDrag:
		if event.index == move_finger:
			move_input = ((event.position - move_origin) / 65.0).limit_length()
		elif event.index == look_finger:
			_look(event.relative * 0.004)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.relative * 0.0025)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_shoot()

func _over_button(point: Vector2) -> bool:
	for b in [fire_button, reload_button, pause_button]:
		if b.get_global_rect().has_point(point):
			return true
	return false

func _look(delta: Vector2) -> void:
	player.rotation.y -= delta.x
	pitch = clampf(pitch - delta.y, -1.25, 1.25)
	camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not running:
		return
	fire_left = maxf(0, fire_left - delta)
	flash_left = maxf(0, flash_left - delta)
	flash.visible = flash_left > 0
	hurt = maxf(0, hurt - delta)
	damage.color.a = hurt * 0.7
	recoil = move_toward(recoil, 0, delta * 0.8)
	gun.position.z = recoil
	if reload_left > 0:
		reload_left -= delta
		if reload_left <= 0:
			var amount := mini(MAG_SIZE - ammo, reserve)
			ammo += amount
			reserve -= amount
	if fire_button.button_pressed:
		_shoot()
	var input := move_input
	input += Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	input = input.limit_length()
	knob.position = Vector2(47.5, 47.5) + move_input * 40
	var direction := player.basis * Vector3(input.x, 0, input.y)
	player.velocity.x = direction.x * SPEED
	player.velocity.z = direction.z * SPEED
	player.velocity.y = -1.0 if player.is_on_floor() else player.velocity.y - 18 * delta
	player.move_and_slide()
	_tick_enemies(delta)
	_tick_pickups(delta)
	if enemies.is_empty():
		if wave >= LAST_WAVE:
			_end(true)
		else:
			wave_wait -= delta
			if wave_wait <= 0:
				_spawn_wave()
	_update_hud()

func _ray(from: Vector3, to: Vector3, exclude: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude
	return get_world_3d().direct_space_state.intersect_ray(query)

func _shoot() -> void:
	if not running or fire_left > 0 or reload_left > 0:
		return
	if ammo <= 0:
		_reload()
		return
	ammo -= 1
	fire_left = 0.22
	recoil = 0.075
	flash_left = 0.055
	shot_sound.play()
	var origin := camera.global_position
	var hit := _ray(origin, origin - camera.global_basis.z * 60, [player.get_rid()])
	if not hit.is_empty() and hit.collider in enemies:
		var enemy: CharacterBody3D = hit.collider
		var hp := int(enemy.get_meta("hp")) - 34
		enemy.set_meta("hp", hp)
		if hp <= 0:
			kills += 1
			enemies.erase(enemy)
			if kills % 3 == 0:
				_add_pickup(enemy.position + Vector3(0, 0.5, 0), "ammo" if kills % 2 == 0 else "health")
			enemy.queue_free()
			if enemies.is_empty():
				wave_wait = 2.5
	_update_hud()

func _reload() -> void:
	if running and reload_left <= 0 and ammo < MAG_SIZE and reserve > 0:
		reload_left = 1.25

func _spawn_wave() -> void:
	wave += 1
	for i in range(3 + wave * 2):
		var enemy := CharacterBody3D.new()
		add_child(enemy)
		var angle := float(i) / float(3 + wave * 2) * TAU
		enemy.position = Vector3(sin(angle) * 14, 0.05, cos(angle) * 14)
		# Keep a new wave away from the player's current position.
		if enemy.position.distance_to(player.position) < 7:
			enemy.position.x *= -1
			enemy.position.z *= -1
		var col := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.4
		shape.height = 1.8
		col.shape = shape
		col.position.y = 0.9
		enemy.add_child(col)
		_box(enemy, Vector3(0, 0.85, 0), Vector3(0.7, 1.1, 0.45), Color("b95c47"), false)
		_box(enemy, Vector3(0, 1.6, 0), Vector3(0.48, 0.42, 0.45), Color("d3c3a1"), false)
		_box(enemy, Vector3(0, 1.65, -0.24), Vector3(0.38, 0.10, 0.03), Color("26343c"), false)
		_box(enemy, Vector3(0.35, 1.05, -0.32), Vector3(0.14, 0.14, 0.50), Color("27333b"), false)
		enemy.set_meta("hp", 100)
		enemy.set_meta("attack", 1.6 + i * 0.2)
		enemies.append(enemy)
	# Each wave replenishes a basic supply so missed shots are recoverable.
	reserve += 24
	_add_pickup(Vector3(0, 0.5, -12), "ammo")
	_add_pickup(Vector3(0, 0.5, 12), "health")

func _tick_enemies(delta: float) -> void:
	for enemy in enemies:
		var offset := player.position - enemy.position
		offset.y = 0
		var distance := offset.length()
		if distance > 0.1:
			enemy.look_at(enemy.position + offset.normalized(), Vector3.UP)
		var sight := _ray(enemy.position + Vector3.UP * 1.45, camera.global_position, [enemy.get_rid()])
		var can_see: bool = not sight.is_empty() and sight.collider == player
		var direction := offset.normalized()
		if not can_see:
			# Steer around the arena's isolated pillars; this is not a navigation mesh.
			var probe := _ray(enemy.position + Vector3.UP, enemy.position + Vector3.UP + direction * 2, [enemy.get_rid()])
			if not probe.is_empty():
				direction = direction.rotated(Vector3.UP, 1.1)
		var speed := 1.8 + wave * 0.2 if distance > 6 or not can_see else 0.0
		enemy.velocity = Vector3(direction.x * speed, -2, direction.z * speed)
		enemy.move_and_slide()
		var attack := float(enemy.get_meta("attack")) - delta
		if attack <= 0 and can_see and distance < 22:
			attack = 1.8
			health = maxi(0, health - (4 + wave))
			hurt = 0.3
			if health <= 0:
				_end(false)
				return
		enemy.set_meta("attack", attack)

func _add_pickup(pos: Vector3, kind: String) -> void:
	var color := Color("95dc89") if kind == "health" else Color("e8ba64")
	var item := _box(self, pos, Vector3(0.55, 0.55, 0.55), color, false)
	item.set_meta("kind", kind)
	pickups.append(item)

func _tick_pickups(delta: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var item := pickups[i]
		item.rotate_y(delta * 1.4)
		if item.position.distance_to(player.position + Vector3.UP * 0.5) < 1.3:
			if item.get_meta("kind") == "health":
				if health >= 100:
					continue
				health = mini(100, health + 30)
			else:
				reserve += 24
			pickups.remove_at(i)
			item.queue_free()

func _update_hud() -> void:
	hud.text = "HP %03d     /     AMMO %02d : %02d     /     WAVE %d / %d" % [health, ammo, reserve, wave, LAST_WAVE]
	if reload_left > 0:
		status.text = "RELOADING..."
	elif ammo == 0 and reserve == 0:
		status.text = "COLLECT AN AMBER AMMO PICKUP"
	elif enemies.is_empty() and wave < LAST_WAVE:
		status.text = "WAVE %d INCOMING" % (wave + 1)
	else:
		status.text = "%d HOSTILES REMAIN" % enemies.size()

func _end(won: bool) -> void:
	finished = true
	_show_menu("ARENA SECURED" if won else "SIGNAL LOST", "DOMINION '99 (LITE)\n\n%s\n%d hostiles eliminated" % ["All 3 waves cleared." if won else "You fell in wave %d." % wave, kills], "PLAY AGAIN")
