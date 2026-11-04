extends SceneTree
var g
func _initialize() -> void:call_deferred("verify")
func verify() -> void:
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 g.set_physics_process(false);g.pad_input.set_physics_process(false)
 var initial_round: int=g.rules.round_index
 for dimensions in [Vector2i(960,540),Vector2i(540,960),Vector2i(540,1206),Vector2i(1206,540),Vector2i(800,1280)]:
  root.size=dimensions
  for i in range(4):await process_frame
  g._tick_viewmodel(.016)
  var f=g.weapon_frame
  var portrait: bool=dimensions.y>dimensions.x
  assert(f.portrait==portrait and g.camera.get_cull_mask_value(2)==not portrait)
  assert(f.image.visible==portrait and g.gun.scale.is_equal_approx(Vector3.ONE*.88))
  if portrait:
   var bounds: Vector2=g.camera.get_viewport().get_visible_rect().size
   assert(Vector2(f.viewport.size).is_equal_approx(bounds))
   assert(is_equal_approx(f.image.position.y+f.image.size.y,bounds.y))
   assert(f.image.position==Vector2.ZERO and f.image.size.is_equal_approx(bounds),"Weapon perspective shares the world crosshair center")
   var muzzle: Vector3=g.gun.global_transform*Vector3(.19,-.157,-1.19)
   var projected: Vector2=g.camera.unproject_position(f.muzzle_world(muzzle))
   var displayed: Vector2=f.image.position+f.view_camera.unproject_position(muzzle)
   assert(projected.distance_to(displayed)<.05,"Physical projectile emerges at displayed muzzle")
   assert(displayed.y/bounds.y>.64 and displayed.y/bounds.y<.76,"Muzzle stays visible in the lower third, rather than disappearing below the HUD")
   assert(displayed.x/bounds.x>.50 and displayed.x/bounds.x<.75,"Weapon stays just right of the crosshair")
   var receiver: Vector2=f.view_camera.unproject_position(g.gun.global_transform*Vector3(.19,-.19,-.56))
   assert(receiver.y/bounds.y>.77 and receiver.y/bounds.y<.95,"The receiver and supporting hand remain on screen")
   var distant: Vector2=f.view_camera.unproject_position(g.gun.global_transform*Vector3(.19,-.157,-1000))
   assert(distant.distance_to(bounds*.5)<1,"Barrel perspective converges on the actual crosshair, not the bottom of the screen")
   var original_z: float=g.gun.position.z
   for i in range(20):g._tick_viewmodel(.016)
   assert(is_equal_approx(original_z,g.gun.position.z),"Portrait depth offset cannot accumulate")
   assert(g.camera.global_position.distance_to(f.muzzle_world(muzzle))<1,"Framing cannot move physical shots below the player's feet")
  assert(g.rules.round_index==initial_round)
 # The harvesting palm also stays inside the narrow portrait weapon camera.
 g._show("play");g.rules.players[g.local_id]["suction"]=1.6;g.hand_amount=1;g._tick_viewmodel(.016)
 var palm: Vector2=g.weapon_frame.view_camera.unproject_position(g.hand_root.global_position)
 var view_size: Vector2=Vector2(g.weapon_frame.viewport.size)
 assert(palm.x/view_size.x>.10 and palm.x/view_size.x<.40 and palm.y/view_size.y>.6 and palm.y/view_size.y<.9,"Harvesting hand remains visible in portrait")
 # Classic reload still fully lowers the gun in the portrait weapon pass.
 var p: Dictionary=g.rules.players[g.local_id]
 p["reload"]=1.4;p["reload_total"]=2.8
 for i in range(20):g._tick_viewmodel(.016)
 var muzzle: Vector3=g.gun.global_transform*Vector3(.19,-.157,-1.19)
 assert(g.weapon_frame.view_camera.unproject_position(muzzle).y>g.weapon_frame.viewport.size.y)
 print("PASS: centered portrait weapon perspective, visible muzzle/receiver/hand, bounded proportions, both rotation directions/aspects, transparent input-free overlay, aligned projectile muzzle and full reload lowering")
 g._quit_game()
