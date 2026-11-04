extends CanvasLayer
## Render the first-person rig in a bottom-anchored landscape frame in portrait.
## The arena camera keeps its independent world FOV and aiming projection.
var source: Camera3D
var viewport: SubViewport
var view_camera: Camera3D
var image: TextureRect
var portrait := false
func configure(camera: Camera3D) -> void:
 source=camera;layer=1
 viewport=SubViewport.new();viewport.transparent_bg=true;viewport.gui_disable_input=true
 viewport.world_3d=camera.get_world_3d();viewport.msaa_3d=Viewport.MSAA_2X
 viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(viewport)
 view_camera=Camera3D.new();view_camera.cull_mask=2;view_camera.keep_aspect=Camera3D.KEEP_HEIGHT
 view_camera.fov=65;view_camera.near=.025;view_camera.far=4
 var environment:=Environment.new();environment.background_mode=Environment.BG_CLEAR_COLOR
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY;view_camera.environment=environment
 viewport.add_child(view_camera);view_camera.current=true
 image=TextureRect.new();image.texture=viewport.get_texture();image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_SCALE;add_child(image)
 sync()
func _process(_delta: float) -> void:sync()
func sync() -> void:
 if not is_instance_valid(source):return
 var size:=source.get_viewport().get_visible_rect().size
 portrait=size.y>size.x
 source.set_cull_mask_value(2,not portrait)
 image.visible=portrait
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS if portrait else SubViewport.UPDATE_DISABLED
 if not portrait:return
 var frame:=Vector2i(roundi(size.x),maxi(1,roundi(size.x*9.0/16.0)))
 if viewport.size!=frame:viewport.size=frame
 image.position=Vector2(0,size.y-frame.y);image.size=Vector2(frame)
 view_camera.global_transform=source.global_transform
 var world_environment: Environment=source.get_parent().get_parent().environment
 if world_environment!=null:
  view_camera.environment.ambient_light_energy=world_environment.ambient_light_energy
  view_camera.environment.ambient_light_color=world_environment.ambient_light_color
  view_camera.environment.sky=world_environment.sky
func muzzle_world(position: Vector3) -> Vector3:
 sync()
 if not portrait:return position
 # Match the displayed muzzle while keeping the physical projectile above the floor.
 var pixel:=image.position+view_camera.unproject_position(position)
 return source.project_position(pixel,.30)
