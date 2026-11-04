extends Button
const Glyph = preload("res://scripts/ui_glyph.gd")
var glyph := ""
var selected := false
var circled := false
var controller_focused := false
var accent := Color("edb45d")
var hint := ""

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	for state in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	add_theme_color_override("font_color",accent)
	add_theme_color_override("font_hover_color",Color("fff0c9"))
	add_theme_color_override("font_disabled_color",Color(accent,0.22))
	add_theme_color_override("font_outline_color",Color(0,0,0,0.8))
	add_theme_constant_override("outline_size",2)

func _draw() -> void:
	if controller_focused:
		draw_line(Vector2(1,4),Vector2(1,size.y-4),accent,2,true)
		draw_line(Vector2(size.x-1,4),Vector2(size.x-1,size.y-4),accent,2,true)
	if glyph.is_empty():
		draw_line(Vector2(0,size.y-2),Vector2(size.x,size.y-2),Color(accent,1.0 if controller_focused else 0.24),2.5 if controller_focused else 1.0,true)
		return
	var color := Color(accent,0.22 if disabled else 1.0)
	if circled:
		var radius := minf(size.x,size.y)*0.46
		draw_arc(size*0.5,radius,0,TAU,72,Color(0,0,0,color.a*0.7),4.5,true)
		draw_arc(size*0.5,radius,0,TAU,72,Color(accent,color.a*0.85),1.8,true)
	var icon_size := minf(size.x,size.y)*(0.62 if circled else 0.78)
	var box := Rect2((size-Vector2.ONE*icon_size)*0.5,Vector2.ONE*icon_size)
	Glyph.paint(self,glyph,box,color,3.3 if glyph in ["left","ahead","right","down"] else 2.6)
	if selected:
		draw_arc(size*0.5,icon_size*0.58,0.2,PI-0.2,32,Color(accent,0.8),1.5,true)
	if not hint.is_empty():
		var font := get_theme_font("font")
		draw_string(font,Vector2(0,size.y-1),hint,HORIZONTAL_ALIGNMENT_CENTER,size.x,12,color)
