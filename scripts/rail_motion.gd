extends RefCounted
## The same movement step is used for prediction and host-authoritative humans.
var origin := 22
var target := 17
var queued := -1
var jumps := 0
var coyote := 0.15
var blocked := 0.0
var distance := 0.0
var junctions := 0
var aim_yaw := 0.0
var pitch := 0.0
var last_input := 0

func options(course: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	var forward: Vector3 = course.direction(origin, target)
	var right := Vector3(-forward.z, 0, forward.x)
	for id in course.links[target]:
		if id == origin:
			continue
		var d: Vector3 = course.direction(target, id)
		var side := d.dot(right)
		result["right" if side > 0.5 else ("left" if side < -0.5 else "ahead")] = id
	if result.is_empty():
		result["ahead"] = origin
	return result

func choose(course: RefCounted, key: String) -> void:
	var routes := options(course)
	if key == "down":
		for id in routes.values():
			if course.climb(target, id) < 0:
				queued = id
				return
	elif routes.has(key):
		queued = routes[key]

func jump(body: CharacterBody3D) -> void:
	if jumps >= 2 or (jumps == 0 and not body.is_on_floor() and coyote <= 0):
		return
	body.velocity.y = 7.8
	jumps += 1
	coyote = 0

func reset(body: CharacterBody3D, course: RefCounted, node := 22) -> void:
	origin = node
	target = 17 if node == 22 else course.links[node][0]
	queued = -1
	jumps = 0
	coyote = 0.15
	blocked = 0
	aim_yaw = 0
	pitch = 0
	body.position = course.nodes[node] + Vector3.UP * 0.06
	body.velocity = Vector3.ZERO
	var d: Vector3 = course.direction(origin, target)
	body.rotation.y = atan2(-d.x, -d.z)

func step(body: CharacterBody3D, course: RefCounted, delta: float, speed := 5.6) -> String:
	var destination: Vector3 = course.nodes[target]
	var offset := destination - body.position
	offset.y = 0
	var remaining := offset.length()
	var d := offset.normalized()
	var heading: Vector3 = course.direction(origin, target)
	body.rotation.y = lerp_angle(body.rotation.y, atan2(-heading.x, -heading.z), minf(1, delta * 9))
	if body.is_on_floor() and body.velocity.y <= 0:
		jumps = 0
		coyote = 0.12
	else:
		coyote = maxf(0, coyote - delta)
	body.velocity.x = d.x * speed if remaining > 0.25 else 0.0
	body.velocity.z = d.z * speed if remaining > 0.25 else 0.0
	body.velocity.y -= 18 * delta
	var before := body.position
	body.move_and_slide()
	var travel := Vector2(body.position.x - before.x, body.position.z - before.z).length()
	distance += travel
	blocked = blocked + delta if travel < 0.005 and remaining > 0.5 and body.is_on_floor() else 0.0
	if body.position.y < minf(course.nodes[origin].y, destination.y) - 4 or blocked > 1.5:
		var old_target := target
		reset(body, course, origin)
		target = old_target
		return "missed"
	if remaining < 0.4 and body.is_on_floor() and absf(body.position.y - destination.y) < 0.3:
		var routes := options(course)
		var next: int = queued if queued in routes.values() else routes.get("ahead", routes.values()[0])
		origin = target
		target = next
		queued = -1
		junctions += 1
		aim_yaw = 0
		blocked = 0
		return "corner"
	return ""

func pack() -> Array:
	return [origin, target, queued, jumps, coyote, aim_yaw, pitch, last_input]

func unpack(data: Array) -> void:
	if data.size() != 8:
		return
	origin = int(data[0])
	target = int(data[1])
	queued = int(data[2])
	jumps = int(data[3])
	coyote = float(data[4])
	aim_yaw = float(data[5])
	pitch = float(data[6])
	last_input = int(data[7])
