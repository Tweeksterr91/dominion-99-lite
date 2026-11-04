extends RefCounted
## Free movement shared by the host, local prediction and physically moving AI.
var move_input := Vector2.ZERO
var input_age := 0.0
var jumps := 0
var coyote := .12
var aim_yaw := 0.0
var pitch := 0.0
var last_input := 0
var distance := 0.0
func set_move(value: Vector2) -> void:
	move_input=value.limit_length(1)
	input_age=0
func reset(body: CharacterBody3D,world: RefCounted,node := 10) -> void:
	move_input=Vector2.ZERO;input_age=0;jumps=0;coyote=.12
	body.position=world.nodes[node]+Vector3.UP*.08
	body.velocity=Vector3.ZERO
	aim_yaw=atan2(body.position.x,body.position.z)
	pitch=0
	body.rotation.y=aim_yaw
	body.floor_snap_length=.4
	body.floor_max_angle=deg_to_rad(44)
func jump(body: CharacterBody3D) -> void:
	if jumps>=2 or (jumps==0 and not body.is_on_floor() and coyote<=0):return
	body.velocity.y=7.8;jumps+=1;coyote=0
func reverse(body: CharacterBody3D) -> void:
	aim_yaw=wrapf(aim_yaw+PI,-PI,PI)
	body.rotation.y=aim_yaw
func step(body: CharacterBody3D,_world: RefCounted,delta: float,speed := 5.8) -> String:
	input_age+=delta
	if input_age>.4:move_input=Vector2.ZERO
	if body.is_on_floor() and body.velocity.y<=0:jumps=0;coyote=.12
	else:coyote=maxf(0,coyote-delta)
	body.rotation.y=aim_yaw
	var direction := Basis(Vector3.UP,aim_yaw)*Vector3(move_input.x,0,move_input.y)
	body.velocity.x=move_toward(body.velocity.x,direction.x*speed,delta*32)
	body.velocity.z=move_toward(body.velocity.z,direction.z*speed,delta*32)
	body.velocity.y-=18*delta
	var before:=body.position
	body.move_and_slide()
	distance+=Vector2(body.position.x-before.x,body.position.z-before.z).length()
	return "fallen" if body.position.y< -11 else ""
func pack() -> Array:
	return [move_input.x,move_input.y,jumps,coyote,0,aim_yaw,pitch,last_input]
func unpack(data: Array) -> void:
	if data.size()!=8:return
	move_input=Vector2(data[0],data[1]);jumps=int(data[2]);coyote=float(data[3]);aim_yaw=float(data[5]);pitch=float(data[6]);last_input=int(data[7])
