extends Control
signal moved(value: Vector2)
var finger := -1
var value := Vector2.ZERO
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var center:=size*.5;var radius:=size.x*.44
	draw_circle(center,radius,Color(0.05,.06,.07,.12))
	draw_arc(center,radius,0,TAU,64,Color("d6b476"),1.7,true)
	draw_circle(center+value*radius*.65,radius*.28,Color(.88,.72,.44,.55),true,-1,true)
func handle(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if event.pressed and finger<0 and get_global_rect().has_point(event.position):finger=event.index;_update(event.position);return true
		if event.index==finger and not event.pressed:finger=-1;value=Vector2.ZERO;moved.emit(value);queue_redraw();return true
	elif event is InputEventScreenDrag and event.index==finger:_update(event.position);return true
	return false
func _update(point: Vector2) -> void:
	value=((point-get_global_rect().get_center())/(size.x*.35)).limit_length(1)
	moved.emit(value);queue_redraw()
func release() -> void:
	finger=-1;value=Vector2.ZERO;moved.emit(value);queue_redraw()
