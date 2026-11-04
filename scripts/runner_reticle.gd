extends Control
var locked := false
var hit := false
func _draw() -> void:
	var color := Color("ffb968") if locked or hit else Color("def3ed")
	var gap := 7.0 if locked else 11.0
	var center := size * 0.5
	for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + d * gap, center + d * (gap + 9), Color(0, 0, 0, 0.7), 5)
		draw_line(center + d * gap, center + d * (gap + 9), color, 2)
	draw_circle(center, 1.8, color)
