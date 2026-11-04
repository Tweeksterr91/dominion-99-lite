extends SceneTree
var failed := false
var game
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error(message)
func _initialize() -> void:call_deferred("verify")
func button(id: int) -> void:
 for pressed in [true,false]:
  var e:=InputEventJoypadButton.new();e.device=99;e.button_index=id;e.pressed=pressed
  game._input(e)
func axis(id: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=id;e.axis_value=value
 game._input(e)
func verify() -> void:
 game=load("res://tests/legacy_fixture.gd").new()
 root.add_child(game);current_scene=game
 game.set_physics_process(false)
 game.pad_input.set_physics_process(false)
 game.pad_input.bindings=game.Controller.DEFAULTS.duplicate()
 check(ProjectSettings.get_setting("display/window/handheld/orientation")==6,"Sensor rotation enabled")
 button(JOY_BUTTON_A)
 await process_frame
 check(game.screen=="main" and game.pad_input.active,"Gamepad enters main menu")
 button(JOY_BUTTON_DPAD_DOWN)
 button(JOY_BUTTON_A)
 await process_frame
 check(game.screen=="multiplayer","D-pad navigates main menu")
 button(JOY_BUTTON_B)
 await process_frame
 button(JOY_BUTTON_A)
 await process_frame
 check(game.screen=="campaign","Controller confirms campaign")
 button(JOY_BUTTON_A)
 await process_frame
 check(game.screen=="play" and game.pad_input.playing,"Controller starts gameplay without touch")
 check(not game.hud_ui.jump.visible and game.hud_ui.labels["pad_prompt"].visible,"Controller HUD hides touch buttons and shows prompts")
 var r=game.rails[0]
 r.reset(game.player,game.course,22)
 r.jumps=0;r.coyote=.12
 button(JOY_BUTTON_A)
 check(r.jumps==1,"South button jumps")
 button(JOY_BUTTON_LEFT_SHOULDER)
 check(r.jumps==2,"Shoulder supports jumping while aiming")
 var origin: int=r.origin
 button(JOY_BUTTON_Y)
 check(r.target==origin,"East button reverses")
 var p: Dictionary=game.rules.players[0]
 p["ammo"]=0;p["reserve"]=24
 button(JOY_BUTTON_X)
 check(p["reload"]>0,"West button starts manual reload")
 game._tick_fighter_states(float(p["reload_total"])*.65)
 button(JOY_BUTTON_X)
 check(p["ammo"]==12 and p["reload_flash"]>0,"West button completes active reload")
 button(JOY_BUTTON_B)
 check(p["suction"]>0,"North button harvests")
 game.pad_input.clear_axes()
 p["ammo"]=0;p["reserve"]=24;p["reload"]=0
 button(JOY_BUTTON_RIGHT_SHOULDER)
 check(p["reload"]>0,"RB starts reload")
 game._tick_fighter_states(float(p["reload_total"])*.65)
 button(JOY_BUTTON_RIGHT_SHOULDER)
 check(p["reload_flash"]>0,"RB completes active reload")
 r.reset(game.player,game.course,22)
 button(JOY_BUTTON_DPAD_LEFT)
 check(r.queued==r.options(game.course)["left"],"D-pad chooses contextual left route")
 game.pad_input.clear_axes()
 axis(JOY_AXIS_LEFT_X,1)
 game.pad_input.step(1.0/60)
 check(r.queued==r.options(game.course)["right"],"Left stick queues right route")
 r.aim_yaw=0
 axis(JOY_AXIS_RIGHT_X,.1)
 game.pad_input.step(.016)
 check(r.aim_yaw==0,"Deadzone suppresses drift")
 axis(JOY_AXIS_RIGHT_X,1)
 game.pad_input.step(.016)
 check(r.aim_yaw<0,"Right stick aims")
 var yaw: float=r.aim_yaw
 game.pad_input.clear_axes()
 game.pad_input.swap_sticks=true
 axis(JOY_AXIS_LEFT_X,1)
 game.pad_input.step(.016)
 check(r.aim_yaw<yaw,"Swapped sticks support aiming")
 game.pad_input.swap_sticks=false;game.pad_input.clear_axes()
 button(JOY_BUTTON_START)
 await process_frame
 check(game.screen=="paused","Start pauses")
 button(JOY_BUTTON_START)
 check(game.screen=="play","Start resumes")
 game._ui_action("options",null)
 game._ui_action("controller_options",null)
 game._ui_action("controller_bind","jump")
 button(JOY_BUTTON_RIGHT_STICK)
 check(game.screen=="controller_options" and game.pad_input.bindings["jump"]==JOY_BUTTON_RIGHT_STICK,"Button capture remaps jump")
 game._load_controller_settings()
 check(game.pad_input.bindings["jump"]==JOY_BUTTON_RIGHT_STICK,"Bindings persist")
 game.pad_input.bind("jump",JOY_BUTTON_Y)
 check(game.pad_input.bindings["suction"]!=JOY_BUTTON_Y,"Duplicate binding swaps the old action")
 game._ui_action("controller_reset",null)
 game._show("play")
 game.pad_input.set_active(true)
 game.pad_input.device=99
 game.pad_input._connection(99,false)
 check(game.screen=="paused" and not game.pad_input.active,"Disconnect pauses offline and restores touch mode")
 game._show("play")
 check(game.hud_ui.jump.visible,"Touch controls work after disconnect")
 # Rotate through multiple aspect ratios without replacing the match or its state.
 game.rules.advance()
 game._handle_phase_change()
 game._show_shop()
 button(JOY_BUTTON_BACK)
 check(game.screen=="controller_help","View opens guide during shopping")
 button(JOY_BUTTON_B)
 check(game.screen=="shop","Closing guide restores the shop instead of gameplay")
 game._show("play")
 var before_lives: int=game.rules.players[0]["lives"]
 var before_round: int=game.rules.round_index
 for dimensions in [Vector2i(540,960),Vector2i(1080,2412),Vector2i(960,540),Vector2i(2412,1080),Vector2i(1280,800),Vector2i(540,960)]:
  root.size=dimensions
  for i in range(4):await process_frame
  game.hud_ui._relayout()
  var bounds:=Rect2(Vector2.ZERO,root.get_visible_rect().size)
  var wide: bool=dimensions.x>dimensions.y
  check(game.hud_ui.landscape==wide,"Layout follows orientation "+str(dimensions))
  check(root.content_scale_size==(Vector2i(960,540) if wide else Vector2i(540,960)),"Logical viewport switches orientation")
  check(game.camera.keep_aspect==(Camera3D.KEEP_HEIGHT if wide else Camera3D.KEEP_WIDTH),"Projection follows orientation")
  game._show("play")
  for c in game.hud_ui.routes.values()+[game.hud_ui.jump,game.hud_ui.reverse,game.hud_ui.essence,game.hud_ui.down,game.hud_ui.labels["health"],game.hud_ui.labels["ammo"]]:
   check(bounds.encloses(c.get_global_rect()),"Gameplay controls fit "+str(dimensions))
  check(game.hud_ui.reticle.get_global_rect().get_center().distance_to(bounds.get_center())<1,"Reticle stays on camera center")
  check(not game.hud_ui.labels["reload"].get_global_rect().intersects(game.hud_ui.jump.get_global_rect()),"Reload hint clears jump")
  for screen in ["main","campaign","multiplayer","format","options","controller_options","controller_help","join","lobby","paused","shop","reveal","results","credits"]:
   if screen=="campaign":game._show(screen,{"maps":game.CorridorMap.NAMES,"unlocked":5})
   elif screen=="controller_options":game._show_controller_options()
   elif screen=="controller_help":game._show_controller_help()
   elif screen=="shop":game._show_shop()
   elif screen=="reveal":game._show(screen,{"count":8,"rewards":[],"names":[]})
   else:game._show(screen)
   await process_frame
   for c in game.hud_ui.focusables():check(bounds.encloses(c.get_global_rect()),"Menu control fits "+screen+" "+str(dimensions))
   var controls: Array=game.hud_ui.focusables()
   for i in range(controls.size()):
    for j in range(i+1,controls.size()):check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()),"Menu controls do not overlap: "+screen)
  game._show("play")
 check(game.rules.players[0]["lives"]==before_lives and game.rules.round_index==before_round,"Rotation preserves round and lives")
 print("FAIL" if failed else "PASS: gamepad-only menus/play, buttons/shoulders, manual active reload, analog route/aim/deadzone, stick swap, remap/persistence, hotplug, portrait/landscape/tablet layouts, centered aim, match continuity")
 game._quit_game(1 if failed else 0)
