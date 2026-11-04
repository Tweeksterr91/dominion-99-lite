extends Control
const RULES=preload("res://scripts/match_rules.gd")
const FONT=preload("res://assets/fonts/Rajdhani-Bold.ttf")
var opened := false
var selected := "pump"
var profile: Dictionary={}
var keys: Array=[]
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE;hide();keys=RULES.WEAPONS.keys()
func present(p: Dictionary) -> void:
 profile=p.duplicate(true);selected=p["weapon"];opened=true;show();queue_redraw()
func close() -> void:opened=false;hide()
func point(direction: Vector2) -> void:
 if direction.length()<.3:return
 var angle:=fposmod(direction.angle()+PI/2+PI/keys.size(),TAU)
 var key: String=keys[int(angle/(TAU/keys.size()))%keys.size()]
 if key in profile.get("owned",[]):selected=key;queue_redraw()
func select_point(position: Vector2) -> void:
 var direction:=position-size*.5
 if direction.length()>30:point(direction.normalized())
func cycle(step: int) -> void:
 var owned: Array=profile.get("owned",[])
 if owned.is_empty():return
 selected=owned[posmod(owned.find(selected)+step,owned.size())];queue_redraw()
func text_center(text: String,position: Vector2,font_size: int,color: Color) -> void:
 draw_string(FONT,position-Vector2(FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _draw() -> void:
 if not opened:return
 var center:=size*.5;var radius:=minf(195,minf(size.x,size.y)*.37);var step:=TAU/keys.size()
 draw_circle(center,radius+8,Color(.015,.02,.025,.70),true,-1,true)
 for i in range(keys.size()):
  var key: String=keys[i];var angle: float=-PI/2+i*step;var owned: bool=key in profile.get("owned",[])
  var color:=Color("edb45d") if selected==key else Color("c5d0da") if owned else Color("667078")
  draw_arc(center,radius-3,angle-step*.47,angle+step*.47,32,color,5 if selected==key else 1.5,true)
  var edge:=Vector2.from_angle(angle-step*.5)
  draw_line(center+edge*48,center+edge*(radius-9),Color(color,.4),1,true)
  var label:=center+Vector2.from_angle(angle)*(radius*.68)
  var name: String={"pump":"PUMP","scythe":"SCYTHE","double":"DOUBLE","pulse":"PULSE","needle":"CARBON","scatter":"SCATTER","sniper":"SNIPER"}[key]
  text_center(name,label,18,color)
  var ammo: Dictionary=profile.get("inventory",{}).get(key,{})
  var info: String="∞" if RULES.WEAPONS[key].get("infinite",false) else "%d / %d" % [ammo.get("ammo",0),ammo.get("reserve",0)]
  text_center(info if owned else "LOCKED",label+Vector2(0,21),16,color)
 draw_circle(center,43,Color(.04,.05,.06,.85),true,-1,true)
 text_center("EQUIP",center+Vector2(0,6),18,Color("edb45d"))
 text_center("WEAPON WHEEL",center-Vector2(0,radius+25),24,Color("f2eee6"))
 text_center("RELEASE TO EQUIP",center+Vector2(0,radius+37),18,Color("edb45d"))
