extends SceneTree
var failed := false
func _initialize() -> void:
 call_deferred("verify")
func check(condition: bool, detail: String) -> void:
 if not condition:
  failed = true
  push_error(detail)
func verify() -> void:
 var game = load("res://scripts/runner.gd").new()
 root.add_child(game)
 current_scene = game
 game.set_physics_process(false)
 game._start()
 game._choose("left")
 for i in range(205):
  await physics_frame
  game._run_forward(1.0 / 60.0)
 check(game.junctions >= 1 and game.player.position.x < -5, "Auto-run moves and commits a queued corner turn without movement input")
 print("Flat and corner: ", game.player.position, " / ", game.junctions, " junctions")
 await traverse(game, 12, 7, 1)
 await traverse(game, 7, 2, 2)
 await traverse(game, 2, 7, 0)
 print("FAIL" if failed else "PASS: real collision traversal, auto-run, left turn, single jump, double jump, drop")
 quit(1 if failed else 0)
func traverse(game: Node, a: int, b: int, required_jumps: int) -> void:
 game.origin_node = a
 game.target_node = b
 game.queued_node = -1
 game.player.position = game.course.nodes[a] + Vector3.UP * 0.06
 game.player.velocity = Vector3.ZERO
 game.jumps = 0
 game.coyote = 0.15
 game.blocked_time = 0
 game.health = 100
 game.shield = 100
 var first_jump := false
 var second_jump := false
 var since_jump := 0.0
 for i in range(220):
  await physics_frame
  var travelled = Vector2(game.player.position.x - game.course.nodes[a].x, game.player.position.z - game.course.nodes[a].z).length()
  if required_jumps > 0 and not first_jump and travelled > 4.25:
   game._jump()
   first_jump = true
  if first_jump:
   since_jump += 1.0 / 60.0
  if required_jumps == 2 and not second_jump and since_jump > 0.16:
   game._jump()
   second_jump = true
  game._run_forward(1.0 / 60.0)
  if game.origin_node == b:
   break
 check(game.origin_node == b and game.shield == 100, "Successfully traversed height change " + str(a) + " -> " + str(b) + " with " + str(required_jumps) + " jumps")
 print("Traversal ", a, " -> ", b, ": ", game.player.position, " shield ", game.shield, " reached ", game.origin_node)
