extends SceneTree
var failed := false
func check(ok: bool,message: String) -> void:
 if not ok:failed=true;push_error(message)
func _initialize() -> void:call_deferred("verify")
func verify() -> void:
 var g = load("res://tests/legacy_fixture.gd").new()
 root.add_child(g)
 current_scene=g
 g._start_match(2,0,99,[0])
 g.set_physics_process(false)
 await physics_frame
 check(ProjectSettings.get_setting("application/boot_splash/show_image")==false,"Godot splash image disabled")
 check(g.hud_ui.jump.circled and g.hud_ui.essence.circled,"Jump and harvest have full circular outlines")
 for dimensions in [Vector2i(540,960),Vector2i(540,1206)]:
  root.size=dimensions
  await process_frame
  await process_frame
  var bounds:=Rect2(Vector2.ZERO,root.get_visible_rect().size)
  check(bounds.encloses(g.hud_ui.reverse.get_global_rect()),"Reverse fits portrait")
  check(g.hud_ui.reverse.get_global_rect().position.y>g.hud_ui.jump.get_global_rect().end.y,"Reverse is below jump")
  check(not g.hud_ui.reverse.get_global_rect().intersects(g.hud_ui.labels["health"].get_global_rect()),"Reverse clears health")
  check(not g.hud_ui.reverse.get_global_rect().intersects(g.hud_ui.labels["ammo"].get_global_rect()),"Reverse clears ammo")
 var r=g.rails[0]
 r.reset(g.player,g.course,22)
 g.player.position=Vector3(0,.06,20)
 var origin: int=r.origin
 var target: int=r.target
 var position: Vector3=g.player.position
 var forward: Vector3=-g.player.global_basis.z
 var touch:=InputEventScreenTouch.new()
 touch.index=1;touch.pressed=true;touch.position=g.hud_ui.reverse.get_global_rect().get_center()
 g._input(touch)
 check(r.origin==target and r.target==origin and r.queued== -1,"Reverse swaps rail endpoints")
 check(g.player.position==position and (-g.player.global_basis.z).dot(forward)< -.999,"Turn is exactly 180 degrees without teleporting")
 for i in range(15):
  await physics_frame
  r.step(g.player,g.course,1.0/60)
 check(g.player.position.z>20,"Autorun continues in reverse direction")
 g.aim_sensitivity=1.8
 r.aim_yaw=0
 g._look(Vector2(.1,0))
 check(is_equal_approx(r.aim_yaw,-.18),"Default aiming speed increased 80 percent")
 g._ui_action("sensitivity_adjust",.1)
 check(is_equal_approx(g.aim_sensitivity,1.9),"Sensitivity can change in 10 percent increments")
 g._load_settings()
 check(is_equal_approx(g.aim_sensitivity,1.9),"Sensitivity persists")
 g._ui_action("sensitivity_reset",null)
 check(is_equal_approx(g.aim_sensitivity,1.8),"Sensitivity reset")
 for id in [1,2]:
  var body=g.entities[id]
  check(body.get_meta("model").name=="Sentinel","Players use a new original armored model")
  check(body.get_meta("clips").has_all(["Run","Idle","Jump"]),"Player model has real animation clips")
  for mesh in body.get_meta("model").find_children("*","MeshInstance3D",true,false):
   for surface in range(mesh.mesh.get_surface_count()):
    var m: Material=mesh.get_active_material(surface)
    check(m.next_pass is ShaderMaterial,"Player surface has silhouette outline")
    var color: Color=m.next_pass.get_shader_parameter("team_color")
    check(color.b>color.r if id==1 else color.r>color.b,"Outline matches blue/red team")
  var ap=body.get_meta("animation")
  var skeleton=body.get_meta("model").find_children("*","Skeleton3D",true,false)[0]
  g.art.animate_enemy(body,"Run")
  ap.seek(0,true)
  var pose: Array=[]
  for bone in range(skeleton.get_bone_count()):pose.append(skeleton.get_bone_pose_rotation(bone))
  ap.seek(.2,true)
  var changed:=false
  for bone in range(skeleton.get_bone_count()):changed=changed or not pose[bone].is_equal_approx(skeleton.get_bone_pose_rotation(bone))
  check(changed,"Original rig animates actual joints")
 var types: Dictionary={}
 for b in g.entities.values():
  if b.get_meta("role")=="minion":
   types[b.get_meta("subtype")]=b
   check(b.scale.y<1 and float(b.get_meta("hp"))==g.Minions.TYPES[b.get_meta("subtype")]["hp"],"Minions are smaller and use variant health")
 check(types.has_all(["scavenger","stalker","brute"]),"Three regular minion types spawn")
 for name in ["stalker","brute"]:
  var b=types[name]
  b.set_meta("from",10);b.set_meta("to",5);b.set_meta("progress",.1)
  g._move_bot(b,.5)
 check(types["stalker"].get_meta("progress")>types["brute"].get_meta("progress"),"Stalker is faster than brute")
 g.treasure_spawn_left=.001
 g._tick_bots(.01)
 var treasure
 for b in g.entities.values():
  if b.get_meta("subtype","")=="treasure":treasure=b
 check(is_instance_valid(treasure),"Rare treasure minion appears at its scheduled time")
 g.cloud.clear()
 g._damage_entity(treasure,1000,0)
 check(g.cloud.orbs.size()==6,"Treasure releases six gold clusters")
 var total:=0
 for id in g.cloud.orbs.keys():
  total+=int(g.cloud.orbs[id]["value"])
  check(g.cloud.orbs[id]["gold"] and not g.cloud.destroy(id),"Gold souls resist denial")
 check(total==90,"Treasure yields six times ordinary souls")
 var encoded: Array=g.cloud.pack()
 g.cloud.clear()
 g.cloud.apply_snapshot(encoded)
 check(g.cloud.orbs.values()[0]["gold"],"Gold state survives LAN snapshot serialization")
 g.cloud.tick(30,{},true)
 check(g.cloud.orbs.size()==6,"Gold souls do not expire like blue souls")
 g.cloud.clear()
 for body in g.entities.values():body.position=Vector3(100,0,100)
 g.player.position=Vector3(0,.06,22)
 g.player.rotation=Vector3.ZERO
 var gold_id: int=g.cloud.spawn(Vector3(0,1.5,18),15,-1,true)
 g.camera.look_at(Vector3(0,1.5,18))
 await physics_frame
 await physics_frame
 var hit: Dictionary=g._target_for(0)
 check(not hit.is_empty() and hit["collider"] is Area3D,"Crosshair detects gold souls")
 var ammunition: int=g.rules.players[0]["ammo"]
 g._tick_auto_combat(1)
 check(g.cloud.orbs.has(gold_id) and g.rules.players[0]["ammo"]==ammunition,"Auto fire cannot deny gold or waste ammo on it")
 for team_id in [0,2]:
  g.cloud.clear()
  var orb: int=g.cloud.spawn(Vector3(0,2,0),15,-1,true)
  var before: int=g.rules.players[team_id]["souls"]
  var collectors: Dictionary={team_id:Vector3(0,2,1)}
  g.cloud.pull(team_id,collectors[team_id],12,collectors,func(_a,_b):return true)
  g.cloud.tick(.2,collectors,true)
  check(g.rules.players[team_id]["souls"]==before+15,"Both teams can consume gold souls")
 for map_id in range(5):
  g.soundscape.set_map(map_id)
  check(g.soundscape.music.stream.loop and g.soundscape.music.stream.get_length()>30,"Every biome has a full original music loop")
 check(g.soundscape.ambience.stream.loop and g.soundscape.ambience.stream.get_length()>15,"Brown noise loops")
 g.music_volume=0;g.ambience_volume=0;g._update_audio()
 check(g.soundscape.music.stream_paused and g.soundscape.ambience.stream_paused,"Independent ambience/music mute")
 g._pause()
 print("FAIL" if failed else "PASS: splash, circular controls, 180 reverse movement, sensitivity persistence, new animated players, team outlines, minion variants, rare indestructible shared gold, map music and ambience")
 g.soundscape.shutdown()
 await create_timer(.15).timeout
 g.queue_free()
 await process_frame
 await process_frame
 quit(1 if failed else 0)
