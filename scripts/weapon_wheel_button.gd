extends "res://scripts/lock_button.gd"
func _draw() -> void:
 var center:=size*.5;var color:=Color("edb45d")
 draw_circle(center,size.x*.46,Color(.05,.06,.07,.12))
 draw_arc(center,size.x*.46,0,TAU,64,color,2.2 if finger>=0 else 1.5,true)
 for i in range(6):
  var angle: float=-PI/2+i*TAU/6
  draw_arc(center,size.x*.27,angle-.35,angle+.35,12,color,3,true)
 draw_circle(center,3,color,true,-1,true)
