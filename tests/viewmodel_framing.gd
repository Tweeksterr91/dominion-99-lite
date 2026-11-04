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
   assert(absf(float(f.viewport.size.x)/f.viewport.size.y-16.0/9)<.01)
   assert(is_equal_approx(f.image.position.y+f.image.size.y,bounds.y))
   assert(f.image.size.y<bounds.y*.36,"Weapon pass cannot occupy the tall portrait camera frustum")
   var muzzle: Vector3=g.gun.global_transform*Vector3(.19,-.157,-1.19)
   var projected: Vector2=g.camera.unproject_position(f.muzzle_world(muzzle))
   var displayed: Vector2=f.image.position+f.view_camera.unproject_position(muzzle)
   assert(projected.distance_to(displayed)<.05,"Physical projectile emerges at displayed muzzle")
   assert(g.camera.global_position.distance_to(f.muzzle_world(muzzle))<1,"Framing cannot move physical shots below the player's feet")
  assert(g.rules.round_index==initial_round)
 # Classic reload still fully lowers the gun in the landscape-shaped weapon pass.
 var p: Dictionary=g.rules.players[g.local_id]
 p["reload"]=1.4;p["reload_total"]=2.8
 for i in range(20):g._tick_viewmodel(.016)
 var muzzle: Vector3=g.gun.global_transform*Vector3(.19,-.157,-1.19)
 assert(g.weapon_frame.view_camera.unproject_position(muzzle).y>g.weapon_frame.viewport.size.y)
 print("PASS: landscape-preserving portrait frame, natural pose, both rotation directions/aspects, transparent input-free overlay, aligned projectile muzzle and full reload lowering")
 g._quit_game()
