extends CanvasLayer
signal action(kind: String, value: Variant)
const AmberButton = preload("res://scripts/amber_button.gd")
const GlyphView = preload("res://scripts/glyph_view.gd")
const Reticle = preload("res://scripts/match_reticle.gd")
const FONT = preload("res://assets/fonts/Rajdhani-Medium.ttf")
const BOLD = preload("res://assets/fonts/Rajdhani-Bold.ttf")
const AMBER := Color("edb45d")
var root: Control
var stats: Control
var combat: Control
var overlay: Control
var bottom: Control
var labels: Dictionary = {}
var routes: Dictionary = {}
var buttons: Array[Button] = []
var jump: Button
var down: Button
var essence: Button
var reticle: Control
var health_bar: ProgressBar
var shield_bar: ProgressBar
var screen := "title"
var data: Dictionary = {}
var ip: LineEdit
var time := 0.0

func _ready() -> void:
	layer = 10
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats = _group(root)
	combat = _group(root)
	overlay = _group(root)
	_icon(stats,"life",Vector2(0,0),Vector2(18,25),Vector2(28,28))
	labels["lives"] = _label(stats,"5",Vector2(50,18),Vector2(60,44),32)
	labels["life_caption"] = _label(stats,"LIVES",Vector2(20,59),Vector2(80,20),12)
	labels["timer"] = _label(stats,"02:45",Vector2.ZERO,Vector2(146,44),34)
	_place(labels["timer"],Vector2(0.5,0),Vector2(-73,22),Vector2(146,44))
	labels["timer"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	labels["phase"] = _label(stats,"COLLECTION A",Vector2.ZERO,Vector2(210,24),15)
	_place(labels["phase"],Vector2(0.5,0),Vector2(-105,64),Vector2(210,24))
	labels["phase"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	labels["phase"].modulate = AMBER
	labels["round"] = _label(stats,"ROUND 1 / 5",Vector2.ZERO,Vector2(140,20),12)
	_place(labels["round"],Vector2(0.5,0),Vector2(-70,5),Vector2(140,20))
	labels["round"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon(stats,"soul",Vector2(1,0),Vector2(-113,25),Vector2(25,25))
	labels["souls"] = _label(stats,"0",Vector2.ZERO,Vector2(82,32),27)
	_place(labels["souls"],Vector2(1,0),Vector2(-100,18),Vector2(82,38))
	labels["souls"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_icon(stats,"frag",Vector2(1,0),Vector2(-111,62),Vector2(22,22))
	labels["frags"] = _label(stats,"0",Vector2.ZERO,Vector2(82,28),22)
	_place(labels["frags"],Vector2(1,0),Vector2(-100,57),Vector2(82,30))
	labels["frags"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom = _group(stats)
	_icon(bottom,"health",Vector2(0,1),Vector2(18,-110),Vector2(22,22),Color("9ed1b2"))
	labels["health"] = _label(bottom,"100",Vector2.ZERO,Vector2(120,35),28)
	_place(labels["health"],Vector2(0,1),Vector2(48,-120),Vector2(120,35))
	health_bar = _meter(bottom,Vector2(0,1),Vector2(20,-81),Color("9ed1b2"))
	_icon(bottom,"shield",Vector2(0,1),Vector2(18,-65),Vector2(22,22),Color("9bc8df"))
	labels["shield"] = _label(bottom,"100",Vector2.ZERO,Vector2(120,35),28)
	_place(labels["shield"],Vector2(0,1),Vector2(48,-75),Vector2(120,35))
	shield_bar = _meter(bottom,Vector2(0,1),Vector2(20,-35),Color("9bc8df"))
	_icon(bottom,"ammo",Vector2(1,1),Vector2(-49,-107),Vector2(28,28))
	labels["ammo"] = _label(bottom,"12",Vector2.ZERO,Vector2(100,54),44)
	_place(labels["ammo"],Vector2(1,1),Vector2(-162,-126),Vector2(100,54))
	labels["ammo"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	labels["reserve"] = _label(bottom,"/ 72",Vector2.ZERO,Vector2(140,28),20)
	_place(labels["reserve"],Vector2(1,1),Vector2(-160,-68),Vector2(140,28))
	labels["reserve"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	labels["weapon"] = _label(bottom,"D-9 PULSE",Vector2.ZERO,Vector2(180,22),13)
	_place(labels["weapon"],Vector2(1,1),Vector2(-200,-35),Vector2(180,22))
	labels["weapon"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reticle = Reticle.new()
	combat.add_child(reticle)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(reticle,Vector2(0.5,0.5),Vector2(-50,-50),Vector2(100,100))
	labels["reload"] = _label(combat,"",Vector2.ZERO,Vector2(230,25),14)
	_place(labels["reload"],Vector2(0.5,0.5),Vector2(-115,48),Vector2(230,25))
	labels["reload"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	labels["notice"] = _label(combat,"",Vector2.ZERO,Vector2(480,54),19)
	_place(labels["notice"],Vector2(0.5,0),Vector2(-240,112),Vector2(480,54))
	labels["notice"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	labels["notice"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for key in ["left","ahead","right"]:
		var button := _button(combat,"",Vector2.ZERO,Vector2(72,72),"route",key,key)
		var x: float = {"left":-178.0,"ahead":-36.0,"right":106.0}[key]
		_place(button,Vector2(0.5,1),Vector2(x,-305),Vector2(72,72))
		routes[key] = button
	jump = _button(combat,"",Vector2.ZERO,Vector2(74,74),"jump",null,"jump")
	_place(jump,Vector2(0.5,1),Vector2(-37,-219),Vector2(74,74))
	down = _button(combat,"",Vector2.ZERO,Vector2(52,52),"route","down","down")
	_place(down,Vector2(1,1),Vector2(-70,-215),Vector2(52,52))
	essence = _button(combat,"",Vector2.ZERO,Vector2(64,64),"essence",null,"essence")
	essence.accent = Color("68c8fb")
	_place(essence,Vector2(0,0.62),Vector2(12,-32),Vector2(64,64))
	labels["route"] = _label(combat,"",Vector2.ZERO,Vector2(420,30),14)
	_place(labels["route"],Vector2(0.5,1),Vector2(-210,-342),Vector2(420,30))
	labels["route"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pause := _button(combat,"",Vector2.ZERO,Vector2(40,40),"pause",null,"pause")
	_place(pause,Vector2(1,0),Vector2(-55,104),Vector2(40,40))
	_apply_safe_area()
	root.resized.connect(_apply_safe_area)
	show_screen("title",{})


func _apply_safe_area() -> void:
	if not OS.has_feature("android"):return
	var safe := DisplayServer.get_display_safe_area()
	var pixels := DisplayServer.window_get_size()
	if pixels.y>0 and safe.size.y>0:
		stats.offset_top = maxf(0,float(safe.position.y)*root.size.y/pixels.y)

func _group(parent: Control) -> Control:
	var control := Control.new()
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control

func _place(c: Control, anchor: Vector2, offset: Vector2, dimensions: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x+dimensions.x
	c.offset_bottom = offset.y+dimensions.y

func _label(parent: Control,text: String,pos: Vector2,dimensions: Vector2,size := 22) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",BOLD if size>=28 else FONT)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("eee9dd"))
	label.add_theme_color_override("font_outline_color",Color(0,0,0,0.65))
	label.add_theme_constant_override("outline_size",2)
	parent.add_child(label)
	return label

func _icon(parent: Control,kind: String,anchor: Vector2,offset: Vector2,dimensions: Vector2,color := AMBER) -> Control:
	var icon := GlyphView.new()
	icon.icon = kind
	icon.color = color
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	_place(icon,anchor,offset,dimensions)
	return icon

func _button(parent: Control,text: String,pos: Vector2,dimensions: Vector2,kind: String,value: Variant=null,icon := "") -> Button:
	var button := AmberButton.new()
	button.text = text
	button.glyph = icon
	button.position = pos
	button.size = dimensions
	button.add_theme_font_override("font",BOLD)
	button.add_theme_font_size_override("font_size",24)
	button.pressed.connect(func(): action.emit(kind,value))
	parent.add_child(button)
	buttons.append(button)
	return button

func _meter(parent: Control,anchor: Vector2,offset: Vector2,color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1,1,1,0.1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background",bg)
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	_place(bar,anchor,offset,Vector2(140,3))
	return bar

func press_at(point: Vector2) -> bool:
	if is_instance_valid(ip) and ip.is_visible_in_tree() and ip.get_global_rect().has_point(point):
		ip.grab_focus()
		DisplayServer.virtual_keyboard_show(ip.text,ip.get_global_rect())
		return true
	for i in range(buttons.size()-1,-1,-1):
		var button = buttons[i]
		if is_instance_valid(button) and button.is_visible_in_tree() and button.get_global_rect().has_point(point):
			if not button.disabled:button.pressed.emit()
			return true
	return false

func show_screen(value: String,context: Dictionary) -> void:
	screen = value
	data = context
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	buttons = buttons.filter(func(b): return is_instance_valid(b))
	ip = null
	combat.visible = value == "play"
	stats.visible = value in ["play","shop","reveal","results","paused"]
	bottom.visible = value in ["play","paused"]
	overlay.visible = value != "play"
	if value == "play":return
	var texture := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.015,0.02,0.03,0.25),Color(0.015,0.02,0.03,0.78)])
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2(0,1)
	var scrim := TextureRect.new()
	scrim.texture = texture
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if value == "title":
		_logo(0.30,true)
		var tap := _label(overlay,"TAP TO ENTER",Vector2.ZERO,Vector2(400,44),25)
		_place(tap,Vector2(0.5,0.79),Vector2(-200,0),Vector2(400,44))
		tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		labels["tap"] = tap
		return
	if value == "main":
		_logo(0.12,false)
		_menu_line("SINGLE PLAYER CAMPAIGN",0.47,"campaign")
		_menu_line("MULTIPLAYER",0.56,"multiplayer")
		_menu_line("OPTIONS",0.65,"options")
		_menu_line("QUIT GAME",0.74,"quit")
		_footer("ART CREDITS","credits")
		return
	var title: String = {"campaign":"CAMPAIGN","multiplayer":"MULTIPLAYER","format":"LAN / DIRECT IP","join":"JOIN ROOM","lobby":"LAN ROOM","options":"OPTIONS","paused":"PAUSED","shop":"THE ARMORY","reveal":"FATE ENGINE","results":"MATCH COMPLETE","credits":"ART CREDITS"}.get(value,"DOMINION '99")
	var heading := _label(overlay,title,Vector2.ZERO,Vector2(480,65),46)
	_place(heading,Vector2(0.5,0.14),Vector2(-240,0),Vector2(480,65))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match value:
		"campaign":
			var names: Array = context.get("maps",[])
			for i in range(names.size()):
				var button := _menu_line("%02d / %s" % [i+1,names[i]],0.31+i*0.09,"campaign_start",i)
				button.disabled = i >= int(context.get("unlocked",1))
			_footer("BACK","main")
		"multiplayer":
			for i in range(1,5):_menu_line("%d v %d" % [i,i],0.32+(i-1)*0.11,"mp_format",i)
			_footer("BACK","main")
		"format":
			_info("%dv%d / SAME WI-FI OR HOTSPOT\nOpen slots are filled by bots." % [context.get("size",1),context.get("size",1)],0.27)
			_menu_line("HOST ROOM",0.45,"lan_host")
			_menu_line("JOIN ROOM",0.55,"join_screen")
			_menu_line("PRACTICE WITH BOTS",0.65,"practice")
			_footer("BACK","multiplayer")
		"join":
			_info("Enter the host phone's Wi-Fi IP address.\nBoth phones must run this game version.",0.29)
			ip = LineEdit.new()
			ip.text = context.get("ip","")
			ip.placeholder_text = "192.168.1.25"
			ip.max_length = 80
			ip.add_theme_font_override("font",FONT)
			ip.add_theme_font_size_override("font_size",28)
			ip.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
			ip.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
			overlay.add_child(ip)
			_place(ip,Vector2(0.5,0.45),Vector2(-190,0),Vector2(380,60))
			_menu_line("CONNECT",0.60,"lan_join")
			_info(context.get("message",""),0.72)
			_footer("BACK","format")
		"lobby":
			_info(context.get("status",""),0.27)
			_info(context.get("address",""),0.35)
			var roster := _info(context.get("roster",""),0.44)
			roster.size.y = 280
			labels["lobby_roster"] = roster
			var start := _menu_line("START MATCH" if context.get("host",false) else "READY",0.77,"lobby_start" if context.get("host",false) else "lobby_ready")
			start.disabled = context.get("host",false) and not context.get("can_start",false)
			_footer("LEAVE ROOM","leave_room")
		"options":
			_menu_line("AIM / %s" % context.get("sensitivity_name","NORMAL"),0.32,"option_sensitivity")
			_menu_line("SOUND / %d%%" % int(float(context.get("volume",0.8))*100),0.43,"option_volume")
			_menu_line("INVERT AIM / %s" % ("ON" if context.get("invert",false) else "OFF"),0.54,"option_invert")
			_menu_line("CAMERA MOTION / %s" % ("ON" if context.get("motion",true) else "MINIMAL"),0.65,"option_motion")
			_footer("BACK","options_back")
		"paused":
			_menu_line("RESUME",0.35,"resume")
			_menu_line("OPTIONS",0.47,"options")
			_menu_line("RETURN TO MAIN MENU",0.59,"abandon")
			_info("LAN matches keep running while this menu is open." if context.get("lan",false) else "Your match is paused.",0.72)
		"shop":
			_info("Spend souls. Ready up when finished.\nShopping closes after one minute.",0.22)
			var items: Array = context.get("items",[])
			for i in range(items.size()):
				var item: Dictionary = items[i]
				var button := _button(overlay,item["text"],Vector2.ZERO,Vector2(476,45),"buy",item["id"])
				_place(button,Vector2(0.5,0),Vector2(-238,root.size.y*0.34+i*46),Vector2(476,45))
				button.add_theme_font_size_override("font_size",18)
				button.disabled = item.get("disabled",false)
			_menu_line("READY / CONTINUE",0.88,"shop_ready")
		"reveal":
			_info("ONE ROLL EACH / SHARED REVEAL",0.23)
			var rewards: Array = context.get("rewards",[])
			var count: int = context.get("count",2)
			for i in range(count):
				var col := 0 if i < count/2 else 1
				var row: int = i if col == 0 else i-count/2
				var left := 20+col*260
				var y: float = root.size.y*0.34+row*100
				_icon(overlay,"dice",Vector2.ZERO,Vector2(left,y),Vector2(30,30))
				var label := _label(overlay,"",Vector2(left+38,y),Vector2(206,82),17)
				labels["gift_%d" % i] = label
			_update_rewards(rewards,context.get("names",[]),false)
		"results":
			var summary := _info(context.get("summary",""),0.29)
			summary.size.y = 300
			_menu_line("CONTINUE",0.74,"results_continue")
			_footer("MAIN MENU","abandon")
		"credits":
			var credit := _info("Sinbad creature: © Zi Ye / CC BY-SA 3.0\ncreativecommons.org/licenses/by-sa/3.0/\nTextures: ambientCG / CC0\nSky: Poly Haven / CC0\nRajdhani font: Indian Type Foundry / SIL OFL\nOther art and code: Dominion '99\nFull notices: repository ASSET_CREDITS.md",0.31)
			credit.size.y = 340
			_footer("BACK","main")

func _logo(y: float,large: bool) -> void:
	var title := _label(overlay,"DOMINION",Vector2.ZERO,Vector2(500,100),76 if large else 65)
	_place(title,Vector2(0.5,y),Vector2(-250,0),Vector2(500,100))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var number := _label(overlay,"'99",Vector2.ZERO,Vector2(360,145),128 if large else 97)
	_place(number,Vector2(0.5,y),Vector2(-180,75),Vector2(360,145))
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.modulate = AMBER
	var sub := _label(overlay,"LITE  /  SOULS & ASH",Vector2.ZERO,Vector2(420,30),17)
	_place(sub,Vector2(0.5,y),Vector2(-210,205 if large else 177),Vector2(420,30))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _menu_line(text: String,y: float,kind: String,value: Variant=null) -> Button:
	var button := _button(overlay,text,Vector2.ZERO,Vector2(424,58),kind,value)
	_place(button,Vector2(0.5,y),Vector2(-212,0),Vector2(424,58))
	return button

func _info(text: String,y: float) -> Label:
	var label := _label(overlay,text,Vector2.ZERO,Vector2(480,76),19)
	_place(label,Vector2(0.5,y),Vector2(-240,0),Vector2(480,76))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _footer(text: String,kind: String) -> void:
	var button := _button(overlay,text,Vector2.ZERO,Vector2(240,38),kind)
	_place(button,Vector2(0.5,1),Vector2(-120,-58),Vector2(240,38))
	button.add_theme_font_size_override("font_size",17)

func _update_rewards(rewards: Array,names: Array,revealed: bool) -> void:
	for i in range(rewards.size()):
		if not labels.has("gift_%d" % i) or not is_instance_valid(labels["gift_%d" % i]):continue
		var gift: Dictionary = rewards[i]
		labels["gift_%d" % i].text = "%s\n%s\n%s" % [names[i] if i<names.size() else "PLAYER",gift["name"] if revealed else ["QUIET EDGE","THIN AEGIS","LONG REACH"][int(time*12+i)%3],gift["detail"] if revealed else "ROLLING..."]

func update_view(view: Dictionary,delta: float) -> void:
	time += delta
	if screen == "title" and is_instance_valid(labels.get("tap")):
		labels["tap"].modulate.a = 0.65+0.25*sin(time*2)
	if view.is_empty():return
	labels["lives"].text = str(view.get("lives",5))
	labels["souls"].text = str(view.get("souls",0))
	labels["frags"].text = str(view.get("frags",0))
	var seconds := ceili(float(view.get("remaining",165)))
	labels["timer"].text = "%02d:%02d" % [seconds/60,seconds%60]
	labels["phase"].text = view.get("phase_name","COLLECTION A")
	labels["round"].text = "ROUND %d / 5" % view.get("round",1)
	labels["health"].text = str(ceili(view.get("health",100)))
	labels["shield"].text = str(ceili(view.get("shield",100)))
	health_bar.max_value = view.get("max_health",100)
	shield_bar.max_value = view.get("max_shield",100)
	health_bar.value = view.get("health",100)
	shield_bar.value = view.get("shield",100)
	labels["ammo"].text = str(view.get("ammo",12))
	labels["reserve"].text = "/ %d" % view.get("reserve",72)
	labels["weapon"].text = view.get("weapon","D-9 PULSE")
	labels["notice"].text = view.get("notice","")
	labels["route"].text = view.get("route_hint","")
	labels["reload"].text = view.get("reload_hint","")
	reticle.locked = view.get("locked",false)
	reticle.essence = view.get("essence_target",false)
	reticle.progress = view.get("reload_progress",-1.0)
	reticle.empty = view.get("ammo",1)==0
	reticle.attempt_used = view.get("reload_used",false)
	reticle.success = view.get("reload_success",0.0)
	reticle.queue_redraw()
	var choices: Dictionary = view.get("routes",{})
	for key in routes:
		var button: Button = routes[key]
		button.disabled = not choices.has(key) or not view.get("alive",true)
		button.selected = key == view.get("queued","")
		button.hint = choices.get(key,"")
		button.queue_redraw()
	jump.disabled = view.get("jumps",0)>=2 or not view.get("alive",true)
	jump.hint = "2x" if view.get("jumps",0)==1 else ""
	jump.queue_redraw()
	down.disabled = not view.get("can_drop",false) or not view.get("alive",true)
	essence.disabled = not view.get("can_collect",true) or not view.get("alive",true)
	if screen == "reveal":
		_update_rewards(view.get("rewards",[]),view.get("names",[]),float(view.get("remaining",6))<3.2)
