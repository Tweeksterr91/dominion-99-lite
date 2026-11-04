extends SceneTree
var failed := false
func _initialize() -> void:
 call_deferred("verify")
func check(condition: bool, detail: String) -> void:
 if not condition:
  failed = true
  push_error(detail)
func verify() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.set_physics_process(false)
 await physics_frame
 check(not game.running and game.menu.visible, "Starts in menu")
 check(Engine.max_fps == 60, "Fixed 60 FPS")
 check(game.fire_button == null and game.reload_button == null and game.pad == null, "No fire, reload, or movement controls")
 check(game.course.nodes.size() == 25, "Connected 25-junction map")
 var visited = [0]
 var frontier = [0]
 while not frontier.is_empty():
  var id = frontier.pop_front()
  for next in game.course.links[id]:
   check(id in game.course.links[next], "Hallways can be shared in either direction")
   if next not in visited:
    visited.append(next)
    frontier.append(next)
 check(visited.size() == 25, "Every junction is reachable")
 check(game.course.climb(12, 7) == 1, "Single-jump route")
 check(game.course.climb(7, 2) == 2, "Double-jump route")
 check(game.course.climb(2, 7) == -1, "Descending route")
 for dimensions in [Vector2i(540, 960), Vector2i(1080, 2412)]:
  root.size = dimensions
  await process_frame
  await process_frame
  var bounds = Rect2(Vector2.ZERO, root.get_visible_rect().size)
  var controls = game.route_buttons.values() + [game.jump_button, game.down_button, game.health_frame, game.ammo_frame, game.menu, game.route_status]
  for control in controls:
   check(bounds.encloses(control.get_global_rect()), "Portrait UI fits at " + str(dimensions))
  check(not game.menu_body.get_global_rect().intersects(game.biome_button.get_global_rect()), "Menu instructions fit above biome control")
  for panel in [game.health_frame, game.ammo_frame]:
   for button in game.route_buttons.values() + [game.jump_button, game.down_button]:
    check(not panel.get_global_rect().intersects(button.get_global_rect()), "Route controls do not cover stats")
  check(game.aim_reticle.get_global_rect().get_center().distance_to(bounds.get_center()) < 1, "Reticle is centered")
  check(not game.aim_reticle.get_global_rect().intersects(game.route_status.get_global_rect()), "Route text leaves the aiming reticle clear")
 root.size = Vector2i(540, 960)
 var start_touch = InputEventScreenTouch.new()
 start_touch.index = 0
 start_touch.position = game.start_button.get_global_rect().get_center()
 start_touch.pressed = true
 game._input(start_touch)
 check(game.running, "Touch starts the game without mouse emulation")
 var animated_bot = game.enemies[0]
 check(animated_bot.has_meta("animation"), "Imported enemy has an animation player")
 var animation = animated_bot.get_meta("animation")
 check(animated_bot.get_meta("clips").has_all(["Run", "Idle", "Jump"]), "Rigged enemy provides running, idle, and jumping clips")
 var skeleton = animated_bot.get_meta("model").find_children("*", "Skeleton3D", true, false)[0]
 animation.seek(0, true)
 var first_pose: Array = []
 for i in range(skeleton.get_bone_count()):
  first_pose.append(skeleton.get_bone_pose_rotation(i))
 animation.seek(0.23, true)
 var changed = false
 for i in range(skeleton.get_bone_count()):
  changed = changed or not first_pose[i].is_equal_approx(skeleton.get_bone_pose_rotation(i))
 check(changed, "Animation changes actual skeleton joint poses")
 var options = game._options()
 check(options.has("left") and options.has("ahead") and options.has("right"), "First junction offers routes")
 game._choose("left")
 var expected = options["left"]
 game._arrive()
 check(game.target_node == expected and game.origin_node == 17, "Queued left turn is committed at corner")
 game._take_damage(40)
 check(game.shield == 60 and game.health == 100, "Shield absorbs damage")
 game._tick_shield(4.5)
 check(is_equal_approx(game.shield, 70.0), "Delayed shield regeneration")
 game.ammo = 0
 game.reserve = 24
 game.reload_left = 0
 game._tick_auto_reload(0.01)
 check(game.reload_left > 0, "Empty weapon starts reload automatically")
 game._tick_auto_reload(1.3)
 check(game.ammo == 12 and game.reserve == 12, "Automatic reload transfers ammo")
 # Keep one target in the aim ray and move the other bodies away.
 game.player.position = Vector3(0, 0.05, 22)
 game.player.rotation = Vector3.ZERO
 game.camera.rotation = Vector3.ZERO
 var bot = game.enemies[0]
 bot.position = Vector3(0, 0, 18)
 for i in range(1, game.enemies.size()):
  game.enemies[i].position = Vector3(100 + i * 3, 0, 100)
 await physics_frame
 await physics_frame
 check(game._target_enemy() == bot, "Reticle detects a visible enemy")
 game.fire_left = 0
 game._tick_auto_fire()
 check(game.ammo == 11 and bot.get_meta("hp") == 66, "Automatic weapon path damages enemy")
 game.camera.rotation.y = 0.8
 check(game._target_enemy() == null, "No target lock away from enemy")
 var prior_ammo = game.ammo
 game.fire_left = 0
 game._tick_auto_fire()
 check(game.ammo == prior_ammo, "Auto-fire never spends ammo without a target")
 var touch = InputEventScreenTouch.new()
 touch.index = 0
 touch.position = Vector2(240, 350)
 touch.pressed = true
 game._input(touch)
 var drag = InputEventScreenDrag.new()
 drag.index = 0
 drag.relative = Vector2(20, -10)
 game._input(drag)
 var second = InputEventScreenTouch.new()
 second.index = 1
 second.position = game.route_buttons["right"].get_global_rect().get_center()
 second.pressed = true
 game._input(second)
 check(game.touch_aim == 0 and game.queued_node == game.route_options["right"], "Second thumb selects a route while first thumb keeps aiming")
 game.jumps = 0
 game.coyote = 0.15
 second.position = game.jump_button.get_global_rect().get_center()
 game._input(second)
 check(game.jumps == 1 and game.touch_aim == 0, "Jump works while aiming with another finger")
 game._input(second)
 check(game.jumps == 2, "Second jump touch performs a double jump")
 check(game.aim_yaw < 0 and game.pitch > 0, "Drag controls aim without movement")
 touch.pressed = false
 game._input(touch)
 check(game.touch_aim == -1, "Aim finger releases")
 game.jumps = 0
 game.coyote = 0.15
 game._jump()
 check(game.jumps == 1 and game.player.velocity.y > 0, "First jump")
 game._jump()
 check(game.jumps == 2, "Second jump in air")
 game._jump()
 check(game.jumps == 2, "No third jump")
 game._pause()
 check(not game.enemies[0].get_meta("animation").active, "Pause stops character animation")
 var prior = game.player.position
 game._physics_process(5)
 check(game.player.position == prior and not game.running, "Pause stops auto-run")
 game._show_credits()
 check(game.credits_open and not game.biome_button.visible, "Credits are accessible from menu")
 game._start()
 check(not game.credits_open and not game.running, "Credits BACK returns to menu without starting play")
 # Biomes all build real geometry and preserve the graph.
 var layouts: Array[String] = []
 for theme in range(5):
  game.biome = theme
  game._reset_run()
  check(game.course_root.get_child_count() > 50 and game.enemies.size() == 6, "Biome builds with bots: " + str(theme))
  var signature = str(game.course.links)
  check(signature not in layouts, "Biomes have different corridor layouts")
  layouts.append(signature)
  var found = [22]
  var search = [22]
  while not search.is_empty():
   var id = search.pop_front()
   for next in game.course.links[id]:
    if next not in found:
     found.append(next)
     search.append(next)
  check(found.size() == 25, "Every biome is fully connected")
 var bot_from = game.enemies[0].get_meta("from")
 game._tick_enemies(3.4)
 check(game.enemies[0].get_meta("from") != bot_from, "Bots cross junctions using the shared hallway graph")
 game._start()
 game.origin_node = 2
 game.target_node = 7
 game._update_choices()
 game._choose_down()
 check(game.queued_node >= 0 and game.course.climb(7, game.queued_node) == -1, "DOWN selects descending hallway")
 game.health = 1
 game.shield = 0
 game._take_damage(2)
 check(game.finished and not game.running, "Defeat ends run")
 game._start()
 check(game.running and game.health == 100 and game.shield == 100 and game.junctions == 0, "Restart resets run")
 print("FAIL" if failed else "PASS: runner graph, contextual routes, auto reload, targeting, weapon damage, drag aim, double jump, shield, biomes, HUD, pause, restart")
 game.shot_sound.stop()
 game.queue_free()
 await process_frame
 await process_frame
 quit(1 if failed else 0)
