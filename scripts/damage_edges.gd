extends Control
var strength := Vector4.ZERO
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 var width:=minf(86,size.x*.16);var height:=minf(86,size.y*.14)
 for i in range(24):
  var alpha:=pow(1.0-float(i)/24,2)*.65
  if strength.x>0:draw_rect(Rect2(i*width/24,0,width/24+1,size.y),Color(.67,.015,.025,alpha*strength.x))
  if strength.y>0:draw_rect(Rect2(size.x-(i+1)*width/24,0,width/24+1,size.y),Color(.67,.015,.025,alpha*strength.y))
  if strength.z>0:draw_rect(Rect2(0,i*height/24,size.x,height/24+1),Color(.67,.015,.025,alpha*strength.z))
  if strength.w>0:draw_rect(Rect2(0,size.y-(i+1)*height/24,size.x,height/24+1),Color(.67,.015,.025,alpha*strength.w))
