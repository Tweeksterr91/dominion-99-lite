extends Node
var agent: NavigationAgent3D
var repath := 0.0
var jump_target := Vector3.ZERO
var jumping_left := 0.0
var second_jump := false
func _ready() -> void:
	agent=NavigationAgent3D.new();agent.path_desired_distance=.65;agent.target_desired_distance=1.0;agent.path_metadata_flags=NavigationPathQueryParameters3D.PATH_METADATA_INCLUDE_ALL
	get_parent().add_child.call_deferred(agent)
	agent.link_reached.connect(_link)
func _link(details: Dictionary) -> void:
	jump_target=details.get("link_exit_position",Vector3.ZERO);jumping_left=1.4;second_jump=false
func steer(body: CharacterBody3D,motion: RefCounted,goal: Vector3,delta: float) -> Vector3:
	if not agent.is_inside_tree() or NavigationServer3D.map_get_iteration_id(agent.get_navigation_map())==0:return Vector3.ZERO
	repath-=delta
	if repath<=0:agent.target_position=goal;repath=.55
	var next: Vector3=agent.get_next_path_position()
	if jumping_left>0:
		if body.is_on_floor() and jumping_left>1.2:motion.jump(body)
		jumping_left-=delta
		if not second_jump and jumping_left<1.16:motion.jump(body);second_jump=true
		next=jump_target
		if body.position.distance_to(jump_target)<.8:jumping_left=0
	var offset:=next-body.position;offset.y=0
	return offset.normalized() if offset.length()>.25 else Vector3.ZERO
