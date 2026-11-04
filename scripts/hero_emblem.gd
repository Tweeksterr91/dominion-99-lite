extends Control
var kind := "male"
var species := "Human"
var variant := 0
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 var c:=size*.5;var s:=minf(size.x,size.y);var tint:=Color.from_hsv(fposmod(variant*.071+.08,1),.30,.88)
 draw_arc(c,s*.45,0,TAU,48,Color(tint,.55),1.5,true)
 if kind=="robot":
  draw_style_box(_box(tint),Rect2(c-Vector2(s*.20,s*.24),Vector2(s*.4,s*.4)))
  draw_line(c+Vector2(-s*.14,-s*.07),c+Vector2(s*.14,-s*.07),Color("72bdd3"),3,true)
 elif kind=="anthro":
  draw_circle(c-Vector2(0,s*.08),s*.17,Color(tint,.5),true,-1,true)
  var points:=PackedVector2Array()
  if species=="Stag":
   for side in [-1,1]:draw_polyline(PackedVector2Array([c+Vector2(side*s*.12,-s*.18),c+Vector2(side*s*.28,-s*.36),c+Vector2(side*s*.30,-s*.12)]),tint,2,true)
  elif species=="Raven":draw_colored_polygon(PackedVector2Array([c+Vector2(-s*.12,0),c+Vector2(s*.27,0),c+Vector2(s*.06,-s*.14)]),tint)
  else:
   for side in [-1,1]:draw_colored_polygon(PackedVector2Array([c+Vector2(side*s*.07,-s*.18),c+Vector2(side*s*.22,-s*.37),c+Vector2(side*s*.22,-s*.08)]),tint)
 else:
  draw_circle(c-Vector2(0,s*.09),s*.14,tint,true,-1,true)
  draw_line(c+Vector2(-s*.27,-s*.22),c+Vector2(s*.27,-s*.22),tint,3,true)
  draw_style_box(_box(tint),Rect2(c+Vector2(-s*.16,-s*.37),Vector2(s*.32,s*.14)))
 draw_polyline(PackedVector2Array([c+Vector2(-s*.30,s*.28),c+Vector2(-s*.20,s*.12),c+Vector2(s*.20,s*.12),c+Vector2(s*.30,s*.28)]),tint,2.5,true)
func _box(color: Color) -> StyleBoxFlat:
 var box:=StyleBoxFlat.new();box.bg_color=color;box.corner_radius_top_left=3;box.corner_radius_top_right=3
 return box
