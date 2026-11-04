extends RefCounted
## Original vector glyphs; all coordinates scale with the requested rectangle.
static func line(c: CanvasItem, points: Array, rect: Rect2, color: Color, width: float) -> void:
	var p := PackedVector2Array()
	for v in points:
		p.append(rect.position + Vector2(v[0], v[1]) * rect.size)
	c.draw_polyline(p, Color(0, 0, 0, color.a * 0.55), width + 2, true)
	c.draw_polyline(p, color, width, true)

static func paint(c: CanvasItem, kind: String, rect: Rect2, color: Color, width := 2.5) -> void:
	var center := rect.get_center()
	var radius := rect.size.x
	match kind:
		"left":
			line(c, [[0.76,0.50],[0.18,0.50]], rect,color,width)
			line(c, [[0.45,0.20],[0.16,0.50],[0.45,0.80]],rect,color,width)
		"right":
			line(c, [[0.24,0.50],[0.82,0.50]],rect,color,width)
			line(c, [[0.55,0.20],[0.84,0.50],[0.55,0.80]],rect,color,width)
		"ahead":
			line(c, [[0.50,0.82],[0.50,0.18]],rect,color,width)
			line(c, [[0.20,0.46],[0.50,0.16],[0.80,0.46]],rect,color,width)
		"down":
			line(c, [[0.50,0.18],[0.50,0.82]],rect,color,width)
			line(c, [[0.20,0.54],[0.50,0.84],[0.80,0.54]],rect,color,width)
		"jump":
			c.draw_circle(rect.position+rect.size*Vector2(0.53,0.21),radius*0.078,color,true,-1,true)
			line(c,[[0.50,0.35],[0.42,0.57]],rect,color,width)
			line(c,[[0.49,0.37],[0.68,0.27],[0.76,0.10]],rect,color,width)
			line(c,[[0.49,0.39],[0.31,0.33],[0.19,0.20]],rect,color,width)
			line(c,[[0.42,0.57],[0.65,0.65],[0.81,0.52]],rect,color,width)
			line(c,[[0.42,0.57],[0.25,0.77],[0.10,0.80]],rect,color,width)
			line(c,[[0.28,0.90],[0.64,0.90]],rect,Color(color,0.35),1)
		"soul", "essence":
			# Swept flame, split tail and a spectral mask, all original vector art.
			line(c,[[.60,.03],[.49,.23],[.64,.34],[.72,.22],[.81,.47],[.79,.65],[.66,.80],[.57,.96],[.48,.80],[.29,.85],[.34,.68],[.20,.55],[.22,.38],[.36,.17],[.35,.37],[.46,.33],[.60,.03]],rect,color,width)
			line(c,[[.37,.48],[.46,.51],[.43,.58]],rect,color,width*.8)
			line(c,[[.65,.48],[.56,.51],[.59,.58]],rect,color,width*.8)
			line(c,[[.48,.66],[.53,.62],[.57,.67]],rect,color,width*.7)
		"reverse":
			c.draw_arc(rect.position+rect.size*Vector2(.50,.47),radius*.28,PI,TAU,32,color,width,true)
			line(c,[[.78,.46],[.78,.77]],rect,color,width)
			line(c,[[.22,.46],[.22,.70]],rect,color,width)
			line(c,[[.08,.55],[.22,.72],[.37,.55]],rect,color,width)
		"life":
			c.draw_arc(center-Vector2(0,radius*0.12),radius*0.24,PI,TAU,20,color,width,true)
			line(c,[[0.26,0.38],[0.26,0.55],[0.39,0.64],[0.61,0.64],[0.74,0.55],[0.74,0.38]],rect,color,width)
			line(c,[[0.33,0.42],[0.67,0.42]],rect,color,width)
			line(c,[[0.12,0.90],[0.29,0.74],[0.71,0.74],[0.88,0.90]],rect,color,width)
		"frag":
			c.draw_arc(center-Vector2(0,radius*0.10),radius*0.29,PI*0.15,PI*2.85,28,color,width,true)
			line(c,[[0.28,0.57],[0.30,0.80],[0.70,0.80],[0.72,0.57]],rect,color,width)
			for x in [0.39,0.61]:c.draw_circle(rect.position+rect.size*Vector2(x,0.43),radius*0.055,color)
			line(c,[[0.42,0.70],[0.42,0.81]],rect,color,width)
			line(c,[[0.58,0.70],[0.58,0.81]],rect,color,width)
		"health":
			line(c,[[0.5,0.12],[0.5,0.88]],rect,color,width+1)
			line(c,[[0.12,0.5],[0.88,0.5]],rect,color,width+1)
		"shield":
			line(c,[[0.50,0.08],[0.82,0.23],[0.76,0.61],[0.50,0.91],[0.24,0.61],[0.18,0.23],[0.50,0.08]],rect,color,width)
		"ammo":
			for x in [0.25,0.5,0.75]:
				line(c,[[x-0.075,0.85],[x-0.075,0.30],[x,0.13],[x+0.075,0.30],[x+0.075,0.85],[x-0.075,0.85]],rect,color,width*0.75)
		"pause":
			line(c,[[0.35,0.2],[0.35,0.8]],rect,color,width+1)
			line(c,[[0.65,0.2],[0.65,0.8]],rect,color,width+1)
		"dice":
			line(c,[[0.2,0.2],[0.8,0.2],[0.8,0.8],[0.2,0.8],[0.2,0.2]],rect,color,width)
			for p in [Vector2(0.35,0.35),Vector2(0.5,0.5),Vector2(0.65,0.65)]:c.draw_circle(rect.position+p*rect.size,radius*0.045,color)
		"weapon":
			line(c,[[0.08,0.35],[0.85,0.35],[0.85,0.52],[0.48,0.52],[0.42,0.85],[0.24,0.85],[0.29,0.52],[0.08,0.52],[0.08,0.35]],rect,color,width)
		_:
			c.draw_arc(center,radius*0.3,0,TAU,32,color,width,true)
