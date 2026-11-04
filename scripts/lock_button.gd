extends Control
signal held(value: bool)
var finger := -1
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 var center:=size*.5;var color:=Color("edb45d")
 draw_circle(center,size.x*.46,Color(.05,.06,.07,.12))
 draw_arc(center,size.x*.46,0,TAU,64,color,2.2 if finger>=0 else 1.5,true)
 draw_arc(center,size.x*.19,0,TAU,48,color,1.6,true)
 for d in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:draw_line(center+d*size.x*.14,center+d*size.x*.30,color,2,true)
func handle(event: InputEvent) -> bool:
 if event is InputEventScreenTouch:
  if event.pressed and finger<0 and get_global_rect().has_point(event.position):finger=event.index;held.emit(true);queue_redraw();return true
  if not event.pressed and event.index==finger:release();return true
 if event is InputEventScreenDrag and event.index==finger:return true
 return false
func release() -> void:
 if finger>=0:finger=-1;held.emit(false);queue_redraw()
