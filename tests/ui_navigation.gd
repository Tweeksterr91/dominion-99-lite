extends SceneTree
func _initialize() -> void:call_deferred("verify")
func tap(g,text: String) -> void:
 for b in g.hud_ui.buttons:
  if is_instance_valid(b) and b.is_visible_in_tree() and b.text.begins_with(text):
   assert(g.hud_ui.press_at(b.get_global_rect().get_center()))
   return
 assert(false,"Missing button "+text)
func verify() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 current_scene=g
 g.set_physics_process(false)
 g._show("main")
 await process_frame
 tap(g,"MULTIPLAYER")
 assert(g.screen=="multiplayer")
 tap(g,"2 v 2")
 assert(g.screen=="format")
 tap(g,"HOST ROOM")
 assert(g.screen=="lobby" and g.net.hosting)
 tap(g,"LEAVE ROOM")
 assert(g.screen=="multiplayer" and not g.net.active)
 tap(g,"BACK")
 tap(g,"OPTIONS")
 assert(g.screen=="options")
 tap(g,"EFFECTS /")
 tap(g,"BACK")
 assert(g.screen=="main")
 tap(g,"SINGLE PLAYER CAMPAIGN")
 assert(g.screen=="campaign")
 tap(g,"01 / VERDANT RUINS")
 assert(g.screen=="conditions")
 print("PASS: actual touch button dispatch, menus, host lobby, leave, settings, campaign")
 g._quit_game()
