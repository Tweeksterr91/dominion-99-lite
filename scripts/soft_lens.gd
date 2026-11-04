extends Node
## One bounded world-only lens pass. No history buffer or HUD filtering.
const DEFAULTS={"bloom":true,"dof":true,"chromatic":true,"motion":true}
var effects: Dictionary=DEFAULTS.duplicate()
var source: Camera3D
var surface: MeshInstance3D
var material: ShaderMaterial
var previous_basis:=Basis.IDENTITY
var previous_position:=Vector3.ZERO
var previous_size:=Vector2.ZERO
var initialized:=false
var focus_distance:=18.0
func configure(camera: Camera3D) -> void:
 source=camera
 surface=MeshInstance3D.new();surface.name="SoftLensWorldPass"
 var quad:=QuadMesh.new();quad.size=Vector2(2,2);surface.mesh=quad
 material=ShaderMaterial.new();material.shader=preload("res://assets/soft_lens.gdshader");material.render_priority=126
 surface.material_override=material;surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 surface.extra_cull_margin=16384;surface.ignore_occlusion_culling=true;surface.layers=4
 source.add_child(surface);surface.position=Vector3(0,0,-1);source.set_cull_mask_value(3,true)
 apply(effects)
func apply(value: Dictionary) -> void:
 for key in DEFAULTS:effects[key]=bool(value.get(key,true))
 if not is_instance_valid(surface):return
 surface.visible=effects.values().has(true)
 for pair in [["dof","dof_enabled"],["bloom","bloom_enabled"],["chromatic","chromatic_enabled"]]:material.set_shader_parameter(pair[1],effects[pair[0]])
func step(delta: float,active: bool) -> void:
 if not is_instance_valid(source):return
 var size:=source.get_viewport().get_visible_rect().size
 var basis:=source.global_basis;var position:=source.global_position
 var motion:=Vector2.ZERO
 var changed: bool=not initialized or size!=previous_size or position.distance_to(previous_position)>3
 if initialized and not changed and active and effects["motion"] and delta>0 and delta<.1:
  var turn:=basis.inverse()*(-previous_basis.z)
  motion=Vector2(turn.x,-turn.y)*180.*minf(1.,.0167/delta)
  motion=motion.limit_length(2.2)
 material.set_shader_parameter("motion_pixels",motion)
 previous_basis=basis;previous_position=position;previous_size=size;initialized=true
 if not surface.visible or not effects["dof"]:return
 var world:=source.get_world_3d()
 if world==null:return
 var origin:=source.global_position;var query:=PhysicsRayQueryParameters3D.create(origin,origin-basis.z*180.,1023)
 # Own character is behind the camera's near plane; exclude it explicitly as well.
 if source.get_parent() is CollisionObject3D:query.exclude=[source.get_parent().get_rid()]
 var hit:=world.direct_space_state.intersect_ray(query)
 var desired: float=origin.distance_to(hit["position"]) if not hit.is_empty() else 120.
 focus_distance=lerpf(focus_distance,clampf(desired,5.,120.),1.-exp(-delta*6.))
 material.set_shader_parameter("focus_distance",focus_distance)
