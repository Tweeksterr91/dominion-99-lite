extends SceneTree
var failed := false
func check(ok: bool,detail: String) -> void:
 if not ok:
  failed = true
  push_error(detail)
func _initialize() -> void:call_deferred("verify")
func verify() -> void:
 var g = load("res://tests/legacy_fixture.gd").new()
 root.add_child(g)
 current_scene = g
 g.set_physics_process(false)
 await physics_frame
 check(g.demo and g.screen=="title","Live title demo starts")
 g._ui_action("main",null)
 g._ui_action("campaign_start",0)
 g.set_physics_process(false)
 check(not g.demo and g.screen=="play" and g.rules.players[0]["lives"]==5,"Campaign starts five-life collection")
 for dimensions in [Vector2i(540,960),Vector2i(540,1206)]:
  root.size = dimensions
  await process_frame
  await process_frame
  var bounds := Rect2(Vector2.ZERO,root.get_visible_rect().size)
  for control in g.hud_ui.routes.values()+[g.hud_ui.jump,g.hud_ui.essence,g.hud_ui.labels["health"],g.hud_ui.labels["ammo"],g.hud_ui.labels["lives"],g.hud_ui.labels["souls"],g.hud_ui.labels["frags"]]:
   check(bounds.encloses(control.get_global_rect()),"HUD fits portrait "+str(dimensions))
  check(g.hud_ui.jump.get_global_rect().position.y>g.hud_ui.routes["ahead"].get_global_rect().end.y,"Jump sits below ahead arrow")
  check(g.hud_ui.reticle.get_global_rect().get_center().distance_to(bounds.get_center())<1,"Crosshair centered")
 var p: Dictionary = g.rules.players[0]
 p["ammo"] = 0
 p["reserve"] = 24
 g._tick_fighter_states(1)
 check(p["reload"]==0 and p["ammo"]==0,"Empty magazine never automatically reloads")
 g._request_action("reload")
 check(p["reload"]>0,"Tap starts reload")
 g._tick_fighter_states(p["reload_total"]*0.65)
 g._request_action("reload")
 check(p["ammo"]==12 and p["reserve"]==12 and p["reload_flash"]>0,"Amber tap completes active reload")
 p["ammo"] = 0
 g._request_action("reload")
 g._tick_fighter_states(0.1)
 g._request_action("reload")
 check(p["reload_used"] and p["reload"]>0,"Early tap uses bonus attempt but reload continues")
 g._tick_fighter_states(2)
 check(p["ammo"]==12 and p["reserve"]==0,"Normal reload finishes after missed timing")
 var minion
 for body in g.entities.values():
  body.position = Vector3(100,0,100)
  if body.get_meta("role")=="minion" and body.get_meta("subtype")=="scavenger":minion=body
 g.player.position = Vector3(0,.05,22)
 g.player.rotation = Vector3.ZERO
 minion.position = Vector3(0,0,18)
 g.camera.look_at(minion.position+Vector3(0,.8,0))
 await physics_frame
 await physics_frame
 var hit: Dictionary = g._target_for(0)
 check(not hit.is_empty() and hit["collider"]==minion,"Camera ray hits PvE minion")
 p["fire_cd"] = 0
 g._tick_auto_combat(.016)
 check(p["ammo"]==11 and minion.get_meta("hp")==31,"Aim automatically shoots actual minion target")
 p["fire_cd"] = 0
 g._tick_auto_combat(.016)
 check(g.cloud.orbs.size()==3 and p["minions"]==1 and p["frags"]==0,"Minion corpse releases blue essence without PvP frag")
 g._setup_round()
 await physics_frame
 var touch := InputEventScreenTouch.new()
 touch.index = 0
 touch.pressed = true
 touch.position = Vector2(250,350)
 g._input(touch)
 var drag := InputEventScreenDrag.new()
 drag.index = 0
 drag.relative = Vector2(10,-8)
 g._input(drag)
 var second := InputEventScreenTouch.new()
 second.index = 1
 second.pressed = true
 second.position = g.hud_ui.routes["ahead"].get_global_rect().get_center()
 g._input(second)
 check(g.touch_aim==0 and g.rails[0].queued>=0,"Separate thumb queues a route while aiming")
 second.position = g.hud_ui.jump.get_global_rect().get_center()
 g._input(second)
 g._input(second)
 check(g.rails[0].jumps==2 and g.rails[0].aim_yaw<0,"Jump icon supports double jump while dragging aim")
 touch.pressed = false
 g._input(touch)
 check(g.touch_aim== -1,"Aiming finger releases")
 p["invul"] = 0
 var health_before: float = p["hp"]+p["shield"]
 g._damage_fighter(0,50,1)
 check(p["hp"]+p["shield"]==health_before,"Players cannot hurt players in collection")
 var cloud = g.cloud
 cloud.clear()
 var orb: int = cloud.spawn(Vector3(0,2,0),5)
 var collectors := {0:Vector3(0,2,6),1:Vector3(0,2,2)}
 var sight := func(_a,_b):return true
 cloud.pull(0,collectors[0],12,collectors,sight)
 check(cloud.orbs[orb]["owner"]==0,"First collector attracts unclaimed essence")
 cloud.pull(1,collectors[1],12,collectors,sight)
 check(cloud.orbs[orb]["owner"]==1,"Closer player can steal essence")
 var balance: int = g.rules.players[1]["souls"]
 cloud.tick(0.2,collectors,true)
 check(g.rules.players[1]["souls"]==balance+5 and cloud.orbs.is_empty(),"Only arrival credits new owner")
 orb = cloud.spawn(Vector3(0,2,0),5)
 balance = p["souls"]
 check(cloud.destroy(orb) and cloud.orbs.is_empty() and p["souls"]==balance,"Destroying essence awards nobody")
 g.rules.credit_essence(0,200)
 g.rules.advance()
 g._handle_phase_change()
 check(g.screen=="shop" and g.hud_ui.bottom.visible==false,"Shop replaces combat controls")
 g._purchase(0,"needle")
 check(p["weapon"]=="needle" and p["ammo"]==24,"Shop equips real weapon stats")
 g.rules.ready(0)
 g._tick_bot_shopping() # timer still 30; bot not ready yet
 g.rules.remaining = 27
 g._tick_bot_shopping()
 g._handle_phase_change()
 check(g.screen=="reveal" and g.rules.rewards.size()==2,"Both players receive visible roll")
 g.rules.advance()
 g._handle_phase_change()
 p["invul"] = 0
 g._damage_fighter(0,500,1)
 check(p["lives"]==4 and g.rules.players[1]["frags"]==1,"Hunt deaths consume lives and credit frags")
 g._tick_fighter_states(3.1)
 check(g._alive(0) and p["hp"]==g.rules.stats(0)["health"],"Surviving life respawns")
 g._pause()
 var position: Vector3 = g.player.position
 g._physics_process(1)
 check(g.screen=="paused" and g.player.position==position,"Offline pause freezes match")
 g._ui_action("resume",null)
 g.rules.advance()
 g._handle_phase_change()
 check(g.rules.players[0]["lives"]==5 and g.rules.round_index==2,"Next round restores five lives")
 print("FAIL" if failed else "PASS: portrait HUD, manual/active reload, PvP protection, steal/deny/credit essence, shop, reveal, respawn, pause")
 g.shot_sound.stop()
 g.soundscape.shutdown()
 await create_timer(.15).timeout
 g.queue_free()
 await process_frame
 await process_frame
 quit(1 if failed else 0)
