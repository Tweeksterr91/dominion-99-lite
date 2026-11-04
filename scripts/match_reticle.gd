extends Control
var lock_active := false
var lock_progress := 0.0
var locked := false
var essence := false
var gold := false
var hit := false
var progress := -1.0
var empty := false
var attempt_used := false
var success := 0.0
func _draw() -> void:
	var center := size*0.5
	var color := Color("ffd06a") if gold else Color("64cfff") if essence else (Color("edb45d") if locked or hit else Color("f2eee6"))
	var gap := 6.0 if locked else 10.0
	for d in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		draw_line(center+d*gap,center+d*(gap+7),Color(0,0,0,0.65),4,true)
		draw_line(center+d*gap,center+d*(gap+7),color,1.7,true)
	draw_circle(center,1.2,color)
	if progress >= 0 or empty or success > 0:
		var radius := 34.0
		draw_arc(center,radius,0,TAU,80,Color(0,0,0,0.45),5,true)
		draw_arc(center,radius,0,TAU,80,Color(1,1,1,0.25),1.5,true)
		if progress >= 0:
			draw_arc(center,radius,-PI/2+TAU*0.60,-PI/2+TAU*0.78,24,Color("edb45d"),5,true)
			draw_arc(center,radius,-PI/2,-PI/2+maxf(0.001,progress)*TAU,80,Color("b6c3cc") if attempt_used else Color("fff1d1"),2.5,true)
			var point := center+Vector2.from_angle(-PI/2+progress*TAU)*radius
			draw_circle(point,3.5,Color("fff3d8"))
		if success > 0:
			draw_arc(center,radius,0,TAU,80,Color(0.9,0.75,0.35,success),3,true)

	# Acquisition ring hugs the active-reload ring without obscuring its timing window.
	if lock_active:
		var radius:=41.0
		var tint:=Color("79e7a2") if lock_progress>=1.0 else Color("edb45d")
		draw_arc(center,radius,0,TAU,96,Color(0,0,0,.6),5,true)
		draw_arc(center,radius,0,TAU,96,Color(tint,.25),1.5,true)
		if lock_progress>0:draw_arc(center,radius,-PI/2,-PI/2+lock_progress*TAU,96,tint,3,true)
