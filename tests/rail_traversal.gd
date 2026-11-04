extends SceneTree
var failed := false
func _initialize() -> void:call_deferred("verify")
func verify() -> void:
 var g = load("res://main.tscn").instantiate()
 root.add_child(g)
 current_scene = g
 g._start_match(1,0,99,[0])
 g.set_physics_process(false)
 var r = g.rails[0]
 r.reset(g.player,g.course,22)
 r.choose(g.course,"left")
 for i in range(205):
  await physics_frame
  r.step(g.player,g.course,1.0/60)
 test(r.junctions>0 and g.player.position.x< -5,"Shared human physics commits queued left turn")
 for specification in [[12,7,1],[7,2,2],[2,7,0]]:
  var a: int = specification[0]
  var b: int = specification[1]
  var jumps: int = specification[2]
  r.reset(g.player,g.course,a)
  r.target = b
  var first := false
  var second := false
  var elapsed := 0.0
  for i in range(220):
   await physics_frame
   var travel := Vector2(g.player.position.x-g.course.nodes[a].x,g.player.position.z-g.course.nodes[a].z).length()
   if jumps>0 and not first and travel>4.25:
    r.jump(g.player)
    first = true
   if first:elapsed+=1.0/60
   if jumps==2 and not second and elapsed>0.16:
    r.jump(g.player)
    second = true
   var result: String = r.step(g.player,g.course,1.0/60)
   test(result!="missed","No failed landing")
   if r.origin==b:break
  test(r.origin==b,"Traverses "+str(specification))
 print("FAIL" if failed else "PASS: host/client shared movement, left turn, single/double jump, drop with real collision")
 quit(1 if failed else 0)
func test(ok: bool,detail: String) -> void:
 if not ok:
  failed = true
  push_error(detail)
