extends Node3D
## Original dark sci-fi FPS prototype. All dimensions use metres.
const VisualAssets = preload("res://scripts/visual_assets.gd")
var art := VisualAssets.new()

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
var pad: Panel
var knob: Panel
var flash: MeshInstance3D
var flash_left := 0.0
var shot_sound: AudioStreamPlayer
var reticle: Label
var hit_left := 0.0

func _ready() -> void:
	Engine.max_fps = 60
	_make_arena()
	_make_player()
	_make_audio()
	_make_ui()
	_show_menu("DOMINION '99", "SECTOR 99 / CONTAINMENT\n\nClear 3 waves.\nGreen pickups: health\nAmber pickups: ammo\n\nLeft thumb: move\nRight thumb: aim\nHold FIRE to shoot. Tap RELOAD.", "DEPLOY")

func _make_arena() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("080b17")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("92a6bf")
	env.ambient_light_energy = 0.78
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("111426")
	env.fog_density = 0.009
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_color = Color("b6c8df")
	sun.light_energy = 0.9
	sun.shadow_enabled = false
	add_child(sun)
	art.build_arena(self)
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
	# Preserve horizontal awareness and keep the pistol visible in portrait.
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.far = 65
	player.add_child(camera)
	gun = Node3D.new()
	camera.add_child(gun)
	art.build_weapon(gun)
	flash = MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.10
	flash_mesh.height = 0.18
	flash.mesh = flash_mesh
	flash.material_override = art.materials["cyan"]
	flash.position = Vector3(0.22, -0.23, -0.83)
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

func _style(color: Color, radius := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(2)
	s.border_color = Color(0.35, 0.77, 0.85, 0.5)
	return s

func _label(parent: Node, text_value: String, pos: Vector2, size: Vector2, font_size := 22) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("c9dfed"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text_value: String, pos: Vector2, size: Vector2, action: Callable) -> Button:
	var b := Button.new()
	b.text = text_value
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_stylebox_override("normal", _style(Color(0.035, 0.07, 0.10, 0.88)))
	b.add_theme_stylebox_override("pressed", _style(Color("31566c")))
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
	var hud_frame := Panel.new()
	hud_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_frame.add_theme_stylebox_override("panel", _style(Color(0.025, 0.05, 0.08, 0.84)))
	root.add_child(hud_frame)
	hud_frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud_frame.offset_left = 16
	hud_frame.offset_right = -16
	hud_frame.offset_top = 24
	hud_frame.offset_bottom = 118
	_label(root, "SECTOR 99  /  CONTAINMENT", Vector2(24, 120), Vector2(390, 25), 14)
	hud = _label(root, "", Vector2(28, 34), Vector2(390, 82), 23)
	status = _label(root, "", Vector2.ZERO, Vector2(492, 64), 21)
	_place(status, Vector2(0.5, 0), Vector2(-246, 136), Vector2(492, 64))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var crosshair := _label(root, "+", Vector2.ZERO, Vector2(30, 42), 30)
	reticle = crosshair
	reticle.add_theme_color_override("font_color", Color("64deea"))
	_place(crosshair, Vector2(0.5, 0.5), Vector2(-15, -21), Vector2(30, 42))
	crosshair.name = "Crosshair"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pad = Panel.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_stylebox_override("panel", _style(Color(0.03, 0.09, 0.13, 0.5), 72))
	root.add_child(pad)
	_place(pad, Vector2(0, 1), Vector2(32, -232), Vector2(145, 145))
	knob = Panel.new()
	knob.size = Vector2(50, 50)
	knob.position = Vector2(47.5, 47.5)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.add_theme_stylebox_override("panel", _style(Color(0.35, 0.78, 0.86, 0.45), 25))
	pad.add_child(knob)
	fire_button = _button(root, "FIRE", Vector2.ZERO, Vector2(132, 132), _shoot)
	_place(fire_button, Vector2(1, 1), Vector2(-164, -260), Vector2(132, 132))
	reload_button = _button(root, "RELOAD", Vector2.ZERO, Vector2(144, 64), _reload)
	_place(reload_button, Vector2(1, 1), Vector2(-176, -106), Vector2(144, 64))
	pause_button = _button(root, "II", Vector2.ZERO, Vector2(58, 56), _pause)
	_place(pause_button, Vector2(1, 0), Vector2(-82, 34), Vector2(58, 56))
	damage = ColorRect.new()
	damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage.color = Color(0.8, 0.1, 0.05, 0)
	damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage)
	menu = Panel.new()
	menu.add_theme_stylebox_override("panel", _style(Color("0c1420"), 3))
	root.add_child(menu)
	_place(menu, Vector2(0.5, 0.5), Vector2(-242, -260), Vector2(484, 520))
	menu_title = _label(menu, "", Vector2(28, 24), Vector2(428, 60), 36)
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_body = _label(menu, "", Vector2(28, 104), Vector2(428, 290), 22)
	menu_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_button = _button(menu, "DEPLOY", Vector2(54, 426), Vector2(376, 64), _start)
	_update_hud()

func _place(control: Control, anchor: Vector2, offset: Vector2, dimensions: Vector2) -> void:
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + dimensions.x
	control.offset_bottom = offset.y + dimensions.y

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
		_show_menu("PAUSED", "DOMINION '99 (LITE)\n\nTake a breather.\nYour arena is waiting.", "RESUME")

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
	hit_left = maxf(0, hit_left - delta)
	reticle.text = "×" if hit_left > 0 else "+"
	reticle.modulate = Color("ffb968") if hit_left > 0 else Color.WHITE
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
		hit_left = 0.14
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
		art.build_enemy(enemy)
		enemy.set_meta("hp", 100)
		enemy.set_meta("attack", 1.6 + i * 0.2)
		enemy.set_meta("muzzle", 0.0)
		enemies.append(enemy)
	# Each wave replenishes a basic supply so missed shots are recoverable.
	reserve += 24
	_add_pickup(Vector3(0, 0.5, -12), "ammo")
	_add_pickup(Vector3(0, 0.5, 12), "health")

func _tick_enemies(delta: float) -> void:
	for enemy in enemies:
		var muzzle_left := maxf(0, float(enemy.get_meta("muzzle")) - delta)
		enemy.set_meta("muzzle", muzzle_left)
		enemy.get_node("MuzzleFlash").visible = muzzle_left > 0
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
			enemy.set_meta("muzzle", 0.12)
			enemy.get_node("MuzzleFlash").visible = true
			attack = 1.8
			health = maxi(0, health - (4 + wave))
			hurt = 0.3
			if health <= 0:
				_end(false)
				return
		enemy.set_meta("attack", attack)

func _add_pickup(pos: Vector3, kind: String) -> void:
	var item := art.build_pickup(self, pos, kind)
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
	hud.text = "HP %03d     WAVE %d / %d\nAMMO %02d / %02d" % [health, wave, LAST_WAVE, ammo, reserve]
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
