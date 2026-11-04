extends SceneTree
var game
var failed := false
func _initialize() -> void:call_deferred("verify")
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error(message)
func press(button: int) -> void:
 for down in [true,false]:
  var e:=InputEventJoypadButton.new();e.device=99;e.button_index=button;e.pressed=down;game._input(e)
func trigger(value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=JOY_AXIS_TRIGGER_RIGHT;e.axis_value=value
 game._input(e);game.pad_input.step(.016)
func verify() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);current_scene=game
 game._start_match(1,0,99,[0]);game.set_physics_process(false);game.pad_input.set_physics_process(false)
 game.settings.set_value("controller","bindings",game.Controller.LEGACY_DEFAULTS.duplicate())
 game.settings.set_value("controller","binding_layout",1)
 game._load_controller_settings()
 check(game.pad_input.bindings["reload"]==JOY_BUTTON_RIGHT_SHOULDER and game.pad_input.bindings["suction"]==JOY_BUTTON_B and game.pad_input.bindings["reverse"]==JOY_BUTTON_Y,"Old default bindings migrate to RB reload, B harvest, Y reverse")
 var legacy: Dictionary=game.Controller.LEGACY_DEFAULTS.duplicate();legacy["jump"]=JOY_BUTTON_RIGHT_STICK
 game.settings.set_value("controller","bindings",legacy);game.settings.set_value("controller","binding_layout",1)
 game._load_controller_settings()
 check(game.pad_input.bindings["jump"]==JOY_BUTTON_RIGHT_STICK,"Migration preserves an unrelated custom jump binding")
 game._ui_action("controller_reset",null);game._show("play")
 for body in game.entities.values():body.position=Vector3(100,0,100)
 game.player.position=Vector3(0,.06,22);game.player.rotation=Vector3.ZERO;game.camera.rotation=Vector3.ZERO
 await physics_frame;await physics_frame
 var p: Dictionary=game.rules.players[0]
 p["ammo"]=12;p["fire_cd"]=0
 trigger(1)
 game._tick_auto_combat(.016)
 check(p["ammo"]==11 and p["reload"]==0,"RT fires a shot into empty space, not a reload")
 game._tick_auto_combat(.016)
 check(p["ammo"]==11,"Manual and auto fire share one cooldown")
 for i in range(60):
  game._tick_fighter_states(1.0/60);game.pad_input.step(1.0/60);game._tick_auto_combat(1.0/60)
 check(p["ammo"]>=6 and p["ammo"]<=8,"Held RT uses weapon cadence and heartbeat")
 trigger(0)
 check(p["manual_left"]==0,"RT release clears manual firing")
 var before: int=p["ammo"]
 game._tick_fighter_states(.4);game._tick_auto_combat(.016)
 check(p["ammo"]==before,"Releasing RT stops misses")
 game._apply_action(0,"fire",true,100)
 game._tick_fighter_states(.6);game._tick_auto_combat(.016)
 check(p["manual_left"]==0 and p["ammo"]==before,"Expired manual-fire state cannot get stuck")
 var minion
 for b in game.entities.values():
  if b.get_meta("subtype","")=="scavenger":minion=b;break
 minion.position=Vector3(0,0,18);game.camera.look_at(minion.position+Vector3(0,.8,0))
 await physics_frame;await physics_frame
 p["ammo"]=12;p["fire_cd"]=0
 game._tick_auto_combat(.016)
 check(p["ammo"]==11 and minion.get_meta("hp")==31,"Auto fire remains enabled without RT")
 p["fire_cd"]=0
 trigger(1);game._tick_auto_combat(.016)
 check(p["ammo"]==10 and p["minions"]==1,"Manual shot damages and kills a real raycast target")
 game.cloud.clear()
 game.camera.look_at(Vector3(0,1.5,18))
 var gold: int=game.cloud.spawn(Vector3(0,1.5,18),15,-1,true)
 await physics_frame;await physics_frame
 p["fire_cd"]=0;before=p["ammo"]
 game._tick_auto_combat(.016)
 check(game.cloud.orbs.has(gold) and p["ammo"]==before,"Manual fire cannot destroy gold souls or spend ammo on them")
 game.cloud.clear()
 var blue: int=game.cloud.spawn(Vector3(0,1.5,18),5)
 await physics_frame;await physics_frame
 p["fire_cd"]=0
 game._tick_auto_combat(.016)
 check(not game.cloud.orbs.has(blue) and p["ammo"]==before-1,"An intentional manual shot denies blue essence immediately")
 trigger(0);game.pad_input.clear_axes()
 p["ammo"]=6;p["reserve"]=20;p["reload"]=0;p["fire_cd"]=0
 game._request_action("reload")
 check(p["reload"]==0,"Touch tap does not reload a partial magazine")
 press(JOY_BUTTON_RIGHT_SHOULDER)
 check(p["reload"]>0,"RB reloads a partial magazine")
 var total: float=p["reload_total"]
 game._tick_fighter_states(total*.25);game._tick_viewmodel(total*.25)
 var lowered: float=game.gun.position.y
 check(lowered< -.60 and game.reload_lowering>.9,"Weapon dips completely down for reload")
 check(game.reload_lower_sound.playing,"Lowering starts original reload sound")
 game._tick_fighter_states(total*.65);game._tick_viewmodel(total*.65)
 check(game.gun.position.y>lowered,"Weapon rises near normal reload completion")
 game._tick_fighter_states(total*.2);game._tick_viewmodel(.2)
 check(p["ammo"]==12 and p["reserve"]==14,"Tactical reload conserves ammunition")
 check(absf(game.gun.position.y)<.01 and game.reload_raise_sound.playing,"Weapon returns with completion sound")
 p["ammo"]=2;p["reserve"]=20;p["fire_cd"]=0
 press(JOY_BUTTON_RIGHT_SHOULDER)
 game._tick_fighter_states(p["reload_total"]*.65);game._tick_viewmodel(.2)
 press(JOY_BUTTON_RIGHT_SHOULDER)
 check(p["ammo"]==12 and p["reload_flash"]>0 and not game._can_shoot(0),"RB active reload finishes early and locks shooting during quick raise")
 game._tick_viewmodel(.016)
 check(game.reload_lowering>0,"Active reload raises rather than snapping the gun instantly")
 game._tick_fighter_states(.16);game._tick_viewmodel(.16)
 check(game._can_shoot(0) and game.reload_lowering==0,"Weapon is ready after the brief active raise")
 p["ammo"]=0;p["reload"]=0
 game._tick_fighter_states(1)
 check(p["reload"]==0,"Empty magazines still wait for explicit reload")
 press(JOY_BUTTON_B)
 check(p["suction"]>0,"B harvests souls")
 var old_target: int=game.rails[0].target
 press(JOY_BUTTON_Y)
 check(game.rails[0].origin==old_target,"Y reverses 180 degrees")
 check(game.reload_lower_sound.stream.get_length()>.3 and game.reload_raise_sound.stream.get_length()>.15,"Original reload foley is loaded")
 print("FAIL" if failed else "PASS: control migration, RT manual fire/cadence/release/timeout, auto-fire coexistence, target/essence rules, RB tactical/active reload, down/up animation, foley, ammo conservation, B harvest and Y turn")
 game._quit_game(1 if failed else 0)
