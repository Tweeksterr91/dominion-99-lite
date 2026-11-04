extends SceneTree
## Run with a real Compatibility renderer (X11 or a device), not --headless.
var stage: Node3D
var camera: Camera3D
var lens
func _initialize() -> void:call_deferred("verify")
func picture() -> Image:
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func difference(a: Image,b: Image,rect: Rect2i) -> float:
 var total:=0.0
 for y in range(rect.position.y,rect.end.y):
  for x in range(rect.position.x,rect.end.x):total+=absf(a.get_pixel(x,y).r-b.get_pixel(x,y).r)
 return total/(rect.size.x*rect.size.y)
func verify() -> void:
 root.size=Vector2i(640,360)
 stage=Node3D.new();root.add_child(stage);current_scene=stage
 camera=Camera3D.new();camera.fov=65;stage.add_child(camera);camera.current=true;camera.cull_mask=1
 var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(.02,.02,.02);stage.add_child(environment)
 var shader:=Shader.new();shader.code="shader_type spatial;render_mode unshaded;void fragment(){float c=step(.5,fract(UV.x*90.));ALBEDO=vec3(c);}";
 for data in [[Vector3(-6,0,-12),Vector2(7,12)],[Vector3(30,0,-70),Vector2(38,68)]]:
  var mesh:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=data[1];mesh.mesh=quad;mesh.position=data[0]
  var material:=ShaderMaterial.new();material.shader=shader;mesh.material_override=material;stage.add_child(mesh)
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var marker:=ColorRect.new();marker.position=Vector2(8,8);marker.size=Vector2(40,24);marker.color=Color(1,.1,.4);marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(marker)
 lens=load("res://scripts/soft_lens.gd").new();stage.add_child(lens);lens.configure(camera)
 lens.apply({"dof":false,"bloom":false,"chromatic":false,"motion":false})
 lens.surface.visible=true
 var clean:=await picture()
 lens.apply({"dof":true,"bloom":false,"chromatic":false,"motion":false});lens.material.set_shader_parameter("focus_distance",12.)
 var depth:=await picture()
 var far_difference:=difference(clean,depth,Rect2i(430,100,140,160));var near_difference:=difference(clean,depth,Rect2i(140,100,70,160))
 print("Depth differences near/far: ",near_difference," / ",far_difference)
 assert(far_difference>.002 and near_difference<.0005,"Depth-aware blur softens distant stripes while leaving near geometry clear")
 assert(difference(clean,depth,Rect2i(8,8,40,24))==0,"HUD is unchanged by lens processing")
 lens.apply({"dof":false,"bloom":true,"chromatic":false,"motion":false})
 var bloom:=await picture();assert(difference(clean,bloom,Rect2i(430,100,140,160))>.001,"Bloom changes bright world highlights")
 lens.apply({"dof":false,"bloom":false,"chromatic":true,"motion":false})
 var chromatic:=await picture();assert(difference(clean,chromatic,Rect2i(430,100,140,160))>.0001,"Edge chromatic separation is rendered")
 lens.apply({"dof":false,"bloom":false,"chromatic":false,"motion":true});lens.material.set_shader_parameter("motion_pixels",Vector2(2.2,0))
 var moving:=await picture();assert(difference(clean,moving,Rect2i(430,100,140,160))>.001,"Camera motion blur is rendered")
 lens.material.set_shader_parameter("motion_pixels",Vector2.ZERO)
 var still:=await picture();assert(difference(clean,still,Rect2i(430,100,140,160))<.0005,"No persistent motion ghosting")
 print("PASS: actual Compatibility GPU depth separation, bright-pass bloom, chromatic edges, motion blur/reset and untouched HUD")
 stage.queue_free();ui.queue_free();await process_frame;quit()
