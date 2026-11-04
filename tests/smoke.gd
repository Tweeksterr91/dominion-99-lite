extends SceneTree
var failed := false

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var game = load("res://scripts/main.gd").new()
	root.add_child(game)
	current_scene = game
	game.set_physics_process(false)
	await physics_frame
	_check(not game.running and game.menu.visible, "Title menu")
	await check_layout(game)
	_check(Engine.max_fps == 60 and not game.has_method("_quality"), "60 FPS without a toggle")
	_check(game.camera.keep_aspect == Camera3D.KEEP_WIDTH, "Portrait camera field of view")
	game._start()
	_check(game.running and not game.menu.visible, "Start")
	_check(game.shield == 100 and game.health == 100, "Full starting health and shield")
	game._take_damage(40)
	_check(game.shield == 60 and game.health == 100, "Shield absorbs damage")
	game._tick_shield(3.9)
	_check(game.shield == 60, "No recharge before damage delay")
	game._tick_shield(0.2)
	_check(is_equal_approx(game.shield, 62.0), "Only time beyond delay recharges shield")
	game._take_damage(70)
	_check(game.shield == 0 and game.health == 92, "Damage spills into health after shield breaks")
	game._tick_shield(4.0)
	_check(game.shield == 0, "A new hit resets the recharge delay")
	game._tick_shield(2.0)
	_check(game.shield == 40, "Recharge rate is 20 shield per second")
	game._tick_shield(20.0)
	_check(game.shield == 100 and game.health == 92, "Shield caps at 100 without regenerating health")
	game.health = 100
	game._spawn_wave()
	_check(game.wave == 1 and game.enemies.size() == 5, "First wave")
	var target = game.enemies[0]
	target.position = Vector3(0, 0, 4)
	for i in range(1, game.enemies.size()):
		game.enemies[i].position = Vector3(14, 0, i * 2)
	await physics_frame
	await physics_frame
	for i in range(3):
		game.fire_left = 0
		game._shoot()
	_check(game.kills == 1 and game.enemies.size() == 4 and game.ammo == 9, "Raycast damage and elimination")
	game._reload()
	_check(game.reload_left > 0, "Reload start")
	var before = game.reserve
	game._physics_process(1.3)
	_check(game.ammo == 12 and game.reserve == before - 3, "Reload transfers ammo")
	for item in game.pickups:
		item.queue_free()
	game.pickups.clear()
	game.health = 40
	game._add_pickup(game.player.position + Vector3.UP * 0.5, "health")
	game._tick_pickups(0.1)
	_check(game.health == 70, "Health pickup")
	before = game.reserve
	game._add_pickup(game.player.position + Vector3.UP * 0.5, "ammo")
	game._tick_pickups(0.1)
	_check(game.reserve == before + 24, "Ammo pickup")
	var touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(100, 400)
	touch.pressed = true
	game._input(touch)
	var drag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(165, 400)
	game._input(drag)
	_check(game.move_input.x == 1, "Touch movement")
	touch.pressed = false
	game._input(touch)
	_check(game.move_input == Vector2.ZERO and game.move_finger == -1, "Touch release")
	game.shield = 10
	game.shield_delay_left = 0
	game._pause()
	game._physics_process(5.0)
	_check(game.shield == 10, "Pause freezes regeneration")
	game.shield = 100
	_check(not game.running and game.menu.visible, "Pause")
	_check(Engine.max_fps == 60, "Fixed 60 FPS while paused")
	game._start()
	for enemy in game.enemies:
		enemy.queue_free()
	game.enemies.clear()
	game.wave_wait = 0
	game._physics_process(0.01)
	_check(game.wave == 2 and game.enemies.size() == 7, "Second wave")
	for enemy in game.enemies:
		enemy.queue_free()
	game.enemies.clear()
	game.wave_wait = 0
	game._physics_process(0.01)
	_check(game.wave == 3 and game.enemies.size() == 9, "Third wave")
	for enemy in game.enemies:
		enemy.queue_free()
	game.enemies.clear()
	game._physics_process(0.01)
	_check(game.finished and not game.running and game.menu_title.text == "ARENA SECURED", "Victory")
	game.finished = false
	game.queue_free()
	var replacement = load("res://scripts/main.gd").new()
	root.add_child(replacement)
	current_scene = replacement
	await process_frame
	await process_frame
	game = current_scene
	_check(game.wave == 0 and game.health == 100 and game.shield == 100 and not game.finished, "Restart")
	game.set_physics_process(false)
	game._start()
	game._spawn_wave()
	game.health = 1
	game.shield = 0
	game.enemies[0].position = Vector3(0, 0, 8)
	game.enemies[0].set_meta("attack", 0)
	await physics_frame
	await physics_frame
	game._tick_enemies(0.1)
	_check(game.finished and game.health == 0 and game.menu_title.text == "SIGNAL LOST", "Enemy attacks and defeat")
	print("FAILED checks; see errors above" if failed else "PASS: shield absorption, spillover, recharge delay/rate/cap, pause, lower HUD positions, start, raycast combat, reload, pickups, touch, pause, fixed 60 FPS, portrait layouts, all waves, victory, restart, defeat")
	quit(1 if failed else 0)

func check_layout(game: Node) -> void:
	_check(ProjectSettings.get_setting("display/window/handheld/orientation") == 1, "Portrait orientation")
	for screen in [Vector2i(540, 960), Vector2i(1080, 2412)]:
		root.size = screen
		await process_frame
		await process_frame
		var bounds = Rect2(Vector2.ZERO, root.get_visible_rect().size)
		for control in [game.hud, game.status, game.pad, game.fire_button, game.reload_button, game.pause_button, game.menu, game.health_frame, game.ammo_frame]:
			_check(bounds.encloses(control.get_global_rect()), "Portrait controls must fit: " + str(control.get_global_rect()) + " in " + str(bounds))
		_check(not game.fire_button.get_global_rect().intersects(game.reload_button.get_global_rect()), "Separate touch buttons")
		_check(not game.pad.get_global_rect().intersects(game.fire_button.get_global_rect()), "Separate movement and fire")
		var crosshair = game.hud.get_parent().get_node("Crosshair")
		_check(crosshair.get_global_rect().get_center().distance_to(bounds.get_center()) < 1, "Centered aim reticle")
		_check(game.menu.get_global_rect().get_center().distance_to(bounds.get_center()) < 1, "Centered portrait menu")
		_check(game.menu.get_global_rect().encloses(game.start_button.get_global_rect()), "Menu button fits")
		_check(not game.menu_body.get_global_rect().intersects(game.start_button.get_global_rect()), "Instructions fit above deploy")
		_check(not game.health_bar.get_global_rect().intersects(game.shield_label.get_global_rect()), "Health bar leaves shield label clear")
		_check(game.health_frame.get_global_rect().get_center().x < bounds.size.x * 0.5, "Health and shield in lower left")
		_check(game.ammo_frame.get_global_rect().get_center().x > bounds.size.x * 0.5, "Ammo in lower right")
		for panel in [game.health_frame, game.ammo_frame]:
			_check(panel.get_global_rect().position.y > bounds.size.y * 0.5, "Stats in lower quadrants")
			for control in [game.pad, game.fire_button, game.reload_button]:
				_check(not panel.get_global_rect().intersects(control.get_global_rect()), "Stats never overlap touch controls")
		print("Portrait layout OK: ", screen, " -> ", bounds.size)
	root.size = Vector2i(540, 960)
	await process_frame

func _check(condition: bool, detail: String) -> void:
	if not condition:
		failed = true
		push_error(detail)
