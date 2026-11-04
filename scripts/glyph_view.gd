extends Control
const Glyph = preload("res://scripts/ui_glyph.gd")
var icon := "soul"
var color := Color("edb45d")
func _draw() -> void:
	Glyph.paint(self,icon,Rect2(Vector2.ZERO,size),color,2)
