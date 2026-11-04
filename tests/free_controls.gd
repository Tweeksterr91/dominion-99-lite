extends SceneTree
var g
func _initialize() -> void:call_deferred("run")
func axis(id: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.device=99;e.axis=id;e.axis_value=value;g._input(e)
func touch(index: int,point: Vector2,pressed: bool) -> void:
 var e:=InputEventScreenTouch.new();e.index=index;e.position=point;e.pressed=pressed;g._input(e)
func run() -> void:
 root.size=Vector2i(540,1206)
 g=load("res://main.tscn").instantiate();root.add_child(g);current_scene=g
 g._start_match(1,0,135,[0]);g.set_physics_process(false);g.pad_input.set_physics_process(false)
 while not g.course.nav_ready:await physics_frame
 g.prelude_left=0;g._show("play")
 for i in range(4):await process_frame
 var start: Vector3=g.player.position
 var point: Vector2=g.hud_ui.stick.get_global_rect().get_center()+Vector2(45,0)
 touch(0,point,true)
 for i in range(50):
  await physics_frame
  g._physics_process(1.0/60)
 assert(g.player.position.distance_to(start)>1,"Holding a stationary touch stick keeps moving beyond input timeout")
 assert(g.hud_ui.stick.finger==0 and not g.pad_input.active)
 var yaw: float=g.rails[0].aim_yaw
 touch(1,Vector2(280,250),true)
 var drag:=InputEventScreenDrag.new();drag.index=1;drag.position=Vector2(310,250);drag.relative=Vector2(30,0);g._input(drag)
 assert(g.rails[0].aim_yaw!=yaw and g.hud_ui.stick.finger==0,"Independent second-finger aiming")
 touch(1,Vector2(310,250),false);touch(0,point,false)
 for i in range(15):await physics_frame;g._physics_process(1.0/60)
 assert(g.rails[0].move_input==Vector2.ZERO and Vector2(g.player.velocity.x,g.player.velocity.z).length()<.01)
 axis(JOY_AXIS_LEFT_X,.8);g.pad_input.step(.04)
 assert(g.pad_input.active and g.rails[0].move_input.x>.4 and not g.hud_ui.stick.visible)
 axis(JOY_AXIS_LEFT_X,0);g.pad_input.step(.04)
 assert(g.rails[0].move_input==Vector2.ZERO)
 yaw=g.rails[0].aim_yaw;axis(JOY_AXIS_RIGHT_X,.7);g.pad_input.step(.04);assert(g.rails[0].aim_yaw!=yaw)
 axis(JOY_AXIS_RIGHT_X,0)
 touch(0,point,true)
 assert(g.hud_ui.stick.finger==0)
 root.size=Vector2i(1206,540)
 for i in range(5):await process_frame
 assert(g.hud_ui.stick.finger==-1 and g.touch_move==Vector2.ZERO,"Rotation releases stale touch movement")
 g._show_controller_help()
 assert("MOVE / STRAFE" in g.hud_ui.data["guide"])
 print("PASS: held touch-stick movement, independent multi-touch aim, release/stop, controller move/aim/release, hot switching, rotation cleanup and free-movement guide")
 g._quit_game()
