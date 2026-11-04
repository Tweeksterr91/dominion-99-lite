extends Control
var target := Rect2()
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 if not target.has_area():return
 var r:=target;var length:=clampf(r.size.x*.27,9,24)
 for corner in [r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]:
  var dx: float=1 if corner.x==r.position.x else -1
  var dy: float=1 if corner.y==r.position.y else -1
  for end in [corner+Vector2(dx*length,0),corner+Vector2(0,dy*length)]:
   draw_line(corner,end,Color(0,0,0,.65),4,true);draw_line(corner,end,Color("edb45d"),2,true)
