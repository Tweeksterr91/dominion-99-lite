extends CanvasLayer
signal action(kind: String, value: Variant)
const AmberButton = preload("res://scripts/amber_button.gd")
const GlyphView = preload("res://scripts/glyph_view.gd")
const Reticle = preload("res://scripts/match_reticle.gd")
const FONT = preload("res://assets/fonts/Rajdhani-Medium.ttf")
const BOLD = preload("res://assets/fonts/Rajdhani-Bold.ttf")
const MATCH_RULES=preload("res://scripts/match_rules.gd")
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
var reverse: Button
var down: Button
var essence: Button
var pause_control: Button
var reticle: Control
var health_bar: ProgressBar
var shield_bar: ProgressBar
var screen := "title"
var data: Dictionary = {}
var ip: LineEdit
var time := 0.0
var landscape := false
var controller_mode := false
var focused: Control
var prompt := ""
var layout_pending := false
var safe_margins := Vector4.ZERO

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
	labels["timer"] = _label(stats,"01:23",Vector2.ZERO,Vector2(146,44),34)
	_place(labels["timer"],Vector2(0.5,0),Vector2(-73,22),Vector2(146,44))
	labels["timer"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	labels["phase"] = _label(stats,"COLLECTION A",Vector2.ZERO,Vector2(210,24),15)
	_place(labels["phase"],Vector2(0.5,0),Vector2(-105,64),Vector2(210,24))
	labels["phase"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	labels["phase"].modulate = AMBER
	labels["round"] = _label(stats,"ROUND 1 / 3",Vector2.ZERO,Vector2(140,20),12)
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
	jump.circled = true
	_place(jump,Vector2(0.5,1),Vector2(-37,-219),Vector2(74,74))
	reverse = _button(combat,"",Vector2.ZERO,Vector2(58,58),"reverse",null,"reverse")
	reverse.circled = true
	_place(reverse,Vector2(0.5,1),Vector2(-29,-137),Vector2(58,58))
	down = _button(combat,"",Vector2.ZERO,Vector2(52,52),"route","down","down")
	_place(down,Vector2(1,1),Vector2(-70,-215),Vector2(52,52))
	essence = _button(combat,"",Vector2.ZERO,Vector2(64,64),"essence",null,"essence")
	essence.accent = Color("68c8fb")
	essence.circled = true
	_place(essence,Vector2(0,0.62),Vector2(12,-32),Vector2(64,64))
	labels["route"] = _label(combat,"",Vector2.ZERO,Vector2(420,30),14)
	_place(labels["route"],Vector2(0.5,1),Vector2(-210,-342),Vector2(420,30))
	labels["route"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_control = _button(combat,"",Vector2.ZERO,Vector2(40,40),"pause",null,"pause")
	_place(pause_control,Vector2(1,0),Vector2(-55,104),Vector2(40,40))
	labels["pad_prompt"] = _label(combat,"",Vector2.ZERO,Vector2(620,30),15)
	_apply_safe_area()
	root.resized.connect(schedule_layout)
	show_screen("title",{})
	schedule_layout()


func schedule_layout() -> void:
	if layout_pending:return
	layout_pending=true
	call_deferred("_relayout")

func _relayout() -> void:
	layout_pending=false
	landscape=root.size.x>root.size.y
	_apply_safe_area()
	var context: Dictionary=data.duplicate(true)
	if is_instance_valid(ip):context["ip"]=ip.text
	show_screen(screen,context)
	_layout_combat()

func _apply_safe_area() -> void:
	var inset := Vector4.ZERO
	if OS.has_feature("android"):
		var safe := DisplayServer.get_display_safe_area()
		var pixels := DisplayServer.window_get_size()
		if pixels.x>0 and pixels.y>0 and safe.size.x>0:
			inset=Vector4(maxf(0,safe.position.x),maxf(0,safe.position.y),maxf(0,pixels.x-safe.end.x),maxf(0,pixels.y-safe.end.y))
			inset*=Vector4(root.size.x/pixels.x,root.size.y/pixels.y,root.size.x/pixels.x,root.size.y/pixels.y)
	safe_margins=inset
	for group in [stats,overlay]:
		group.offset_left=inset.x
		group.offset_top=inset.y
		group.offset_right= -inset.z
		group.offset_bottom= -inset.w

func _layout_combat() -> void:
	var margin: float=maxf(safe_margins.x,safe_margins.z)
	_place(pause_control,Vector2(1,0),Vector2(-55-safe_margins.z,104+safe_margins.y),Vector2(40,40))
	if landscape:
		for key in routes:
			_place(routes[key],Vector2(.5,1),Vector2({"left":-140.0,"ahead":-29.0,"right":82.0}[key],-210),Vector2(58,58))
		_place(jump,Vector2(.5,1),Vector2(-27,-144),Vector2(54,54))
		_place(reverse,Vector2(.5,1),Vector2(-24,-82),Vector2(48,48))
		_place(down,Vector2(1,1),Vector2(-70-margin,-200),Vector2(52,52))
		_place(labels["route"],Vector2(0,1),Vector2(20+margin,-165),Vector2(250,30))
		labels["route"].horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		_place(labels["reload"],Vector2(.5,.5),Vector2(66,-12),Vector2(260,25))
		_place(essence,Vector2(0,.55),Vector2(12+margin,-32),Vector2(64,64))
	else:
		for key in routes:
			_place(routes[key],Vector2(.5,1),Vector2({"left":-178.0,"ahead":-36.0,"right":106.0}[key],-305),Vector2(72,72))
		_place(jump,Vector2(.5,1),Vector2(-37,-219),Vector2(74,74))
		_place(reverse,Vector2(.5,1),Vector2(-29,-137),Vector2(58,58))
		_place(down,Vector2(1,1),Vector2(-70-margin,-215),Vector2(52,52))
		_place(labels["route"],Vector2(.5,1),Vector2(-210,-342),Vector2(420,30))
		labels["route"].horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		_place(labels["reload"],Vector2(.5,.5),Vector2(-115,48),Vector2(230,25))
		_place(essence,Vector2(0,.62),Vector2(12+margin,-32),Vector2(64,64))
	_place(labels["pad_prompt"],Vector2(.5,1),Vector2(-310,-56),Vector2(620,30))
	if not landscape:_place(labels["pad_prompt"],Vector2(.5,1),Vector2(-240,-180),Vector2(480,60))
	labels["pad_prompt"].horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	labels["pad_prompt"].autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	set_controller_mode(controller_mode,prompt)

func set_controller_mode(value: bool,help_text := "") -> void:
	controller_mode=value
	prompt=help_text
	for control in routes.values()+[jump,reverse,down,essence]:control.visible=not value
	labels["pad_prompt"].visible=value
	labels["pad_prompt"].text=help_text
	if not value:_focus(null)
	elif screen!="play":ensure_focus()

func _focus(control: Control) -> void:
	if is_instance_valid(focused) and focused is Button:
		focused.controller_focused=false
		focused.queue_redraw()
	if is_instance_valid(focused) and focused is LineEdit:
		focused.remove_theme_color_override("font_placeholder_color")
	focused=control
	if is_instance_valid(focused) and focused is LineEdit:
		focused.add_theme_color_override("font_placeholder_color",AMBER)
	if is_instance_valid(focused) and focused is Button:
		focused.controller_focused=true
		focused.queue_redraw()

func focusables() -> Array[Control]:
	var result: Array[Control]=[]
	if is_instance_valid(ip) and ip.is_visible_in_tree():result.append(ip)
	for button in buttons:
		if is_instance_valid(button) and button.is_visible_in_tree() and button.get_parent()==overlay and not button.disabled:result.append(button)
	return result

func ensure_focus() -> void:
	var choices := focusables()
	if focused not in choices:_focus(choices[0] if not choices.is_empty() else null)

func navigate(direction: Vector2) -> void:
	ensure_focus()
	if not is_instance_valid(focused):return
	var center := focused.get_global_rect().get_center()
	var best: Control
	var score := INF
	for candidate in focusables():
		if candidate==focused:continue
		var offset := candidate.get_global_rect().get_center()-center
		var ahead := offset.dot(direction)
		if ahead<1:continue
		var side := absf(offset.cross(direction))
		var cost := ahead+side*3.0
		if cost<score:score=cost;best=candidate
	if is_instance_valid(best):_focus(best)

func activate_focus() -> void:
	ensure_focus()
	if not is_instance_valid(focused):return
	if focused is Button:focused.pressed.emit()
	elif focused is LineEdit:
		focused.grab_focus()
		DisplayServer.virtual_keyboard_show(focused.text,focused.get_global_rect())

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
	button.set_meta("action_key",kind+":"+str(value))
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
	var saved_focus := str(focused.get_meta("action_key","")) if is_instance_valid(focused) and screen==value else ""
	screen = value
	data = context
	_focus(null)
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	buttons = buttons.filter(func(b): return is_instance_valid(b))
	ip = null
	combat.visible = value == "play"
	stats.visible = value in ["play","shop","reveal","results","paused"]
	bottom.visible = value in ["play","paused"]
	overlay.visible = value != "play"
	if controller_mode:call_deferred("_restore_focus",saved_focus)
	if value == "play":return
	if value not in ["title","main"]:
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
	if landscape:
		_landscape_screen(value,context)
		return
	if value in ["controller_options","bind_controller","controller_help"]:
		_controller_screen(value,context)
		return
	if value == "title":
		_logo(0.30,true)
		var tap := _label(overlay,"TAP TO ENTER",Vector2.ZERO,Vector2(400,44),25)
		_place(tap,Vector2(0.5,0.79),Vector2(-200,0),Vector2(400,44))
		tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		labels["tap"] = tap
		return
	if value == "main":
		_logo(0.12,false)
		_menu_line("HEROES / CAMPAIGNS",0.47,"campaign")
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
			_info("AIM SENSITIVITY / %d%%" % context.get("sensitivity_pct",180),0.265)
			var minus := _button(overlay,"−",Vector2.ZERO,Vector2(82,48),"sensitivity_adjust",-0.1)
			_place(minus,Vector2(.5,.335),Vector2(-170,0),Vector2(82,48))
			var reset := _button(overlay,"RESET",Vector2.ZERO,Vector2(140,48),"sensitivity_reset")
			_place(reset,Vector2(.5,.335),Vector2(-70,0),Vector2(140,48))
			var plus := _button(overlay,"+",Vector2.ZERO,Vector2(82,48),"sensitivity_adjust",0.1)
			_place(plus,Vector2(.5,.335),Vector2(88,0),Vector2(82,48))
			_wide_button("CONTROLLER SETTINGS",.5,overlay.size.y*.84,424,"controller_options",null,52)
			_wide_button("EFFECTS / %d%%" % roundi(float(context.get("volume",0.8))*100),.5,overlay.size.y*.42,424,"option_volume",null,52)
			_wide_button("MUSIC / %d%%" % roundi(float(context.get("music",0.35))*100),.5,overlay.size.y*.49,424,"option_music",null,52)
			_wide_button("AMBIENCE / %d%%" % roundi(float(context.get("ambience",0.5))*100),.5,overlay.size.y*.56,424,"option_ambience",null,52)
			_wide_button("INVERT AIM / %s" % ("ON" if context.get("invert",false) else "OFF"),.5,overlay.size.y*.63,424,"option_invert",null,52)
			_wide_button("CAMERA MOTION / %s" % ("ON" if context.get("motion",true) else "MINIMAL"),.5,overlay.size.y*.70,424,"option_motion",null,52)
			_wide_button("SCREEN / %s" % context.get("orientation","AUTO"),.5,overlay.size.y*.77,424,"option_orientation",null,52)
			_footer("BACK","options_back")
		"paused":
			_menu_line("RESUME",0.35,"resume")
			_menu_line("OPTIONS",0.47,"options")
			_menu_line("RETURN TO MAIN MENU",0.59,"abandon")
			_info("LAN matches keep running while this menu is open." if context.get("lan",false) else "Your match is paused.",0.72)
		"shop":
			_info("Spend souls. Ready up when finished.\nShopping closes after 30 seconds.",0.22)
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
			var credit := _info("Sinbad creature: © Zi Ye / CC BY-SA 3.0\ncreativecommons.org/licenses/by-sa/3.0/\nTextures: ambientCG / CC0\nSky: Poly Haven / CC0\nRajdhani font: Indian Type Foundry / SIL OFL\nSentinel player, music, hand and icons: original MIT\nOther art and code: Dominion '99\nFull notices: repository ASSET_CREDITS.md",0.31)
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
	_place(button,Vector2(0.5,1),Vector2(-120,-48),Vector2(240,38))
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
	labels["life_caption"].text = "BLUE / LIVES" if view.get("team",0)==0 else "RED / LIVES"
	labels["life_caption"].modulate = Color("48a9ff") if view.get("team",0)==0 else Color("ff4f62")
	labels["souls"].text = str(view.get("souls",0))
	labels["frags"].text = str(view.get("frags",0))
	var seconds := ceili(float(view.get("remaining",165)))
	labels["timer"].text = "%02d:%02d" % [seconds/60,seconds%60]
	labels["phase"].text = view.get("phase_name","COLLECTION A")
	labels["round"].text = "ROUND %d / %d" % [view.get("round",1),MATCH_RULES.ROUND_COUNT]
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
	reticle.gold = view.get("essence_gold",false)
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
	reverse.disabled = not view.get("alive",true)
	jump.disabled = view.get("jumps",0)>=2 or not view.get("alive",true)
	jump.hint = "2x" if view.get("jumps",0)==1 else ""
	jump.queue_redraw()
	down.disabled = not view.get("can_drop",false) or not view.get("alive",true)
	essence.disabled = not view.get("can_collect",true) or not view.get("alive",true)
	if screen == "reveal":
		_update_rewards(view.get("rewards",[]),view.get("names",[]),float(view.get("remaining",MATCH_RULES.REVEAL_TIME))<MATCH_RULES.REVEAL_TIME*.53)

func _restore_focus(key: String) -> void:
	if not controller_mode:return
	for control in focusables():
		if not key.is_empty() and str(control.get_meta("action_key",""))==key:_focus(control);return
	ensure_focus()

func _wide_text(text: String,x: float,y: float,width: float,height := 50.0,font_size := 20) -> Label:
	var label := _label(overlay,text,Vector2.ZERO,Vector2(width,height),font_size)
	_place(label,Vector2(x,0),Vector2(-width/2,y),Vector2(width,height))
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

func _wide_button(text: String,x: float,y: float,width: float,kind: String,value: Variant=null,height := 44.0,font_size := 22) -> Button:
	var button := _button(overlay,text,Vector2.ZERO,Vector2(width,height),kind,value)
	_place(button,Vector2(x,0),Vector2(-width/2,y),Vector2(width,height))
	button.add_theme_font_size_override("font_size",font_size)
	return button

func _landscape_screen(value: String,context: Dictionary) -> void:
	var w := overlay.size.x
	var h := overlay.size.y
	var column := minf(410,(w-80)/2)
	if value in ["controller_options","bind_controller","controller_help"]:
		_controller_screen(value,context)
		return
	if value=="title":
		_logo(.16,true)
		labels["tap"]=_wide_text("TAP / PRESS A TO ENTER",.5,h*.82,500,44,25)
		return
	if value=="main":
		_logo(.20,false)
		for child in overlay.get_children():
			if child is Label:
				child.anchor_left=.26;child.anchor_right=.26
				if child.text=="DOMINION":child.offset_left=-230;child.offset_right=230
		for i in range(4):_wide_button(["HEROES / CAMPAIGNS","MULTIPLAYER","OPTIONS","QUIT GAME"][i],.74,135+i*60,column,["campaign","multiplayer","options","quit"][i])
		_footer("ART CREDITS","credits")
		return
	var title: String={"campaign":"CAMPAIGN","multiplayer":"MULTIPLAYER","format":"LAN / DIRECT IP","join":"JOIN ROOM","lobby":"LAN ROOM","options":"OPTIONS","paused":"PAUSED","shop":"THE ARMORY","reveal":"FATE ENGINE","results":"MATCH COMPLETE","credits":"ART CREDITS"}.get(value,"DOMINION '99")
	_wide_text(title,.5,100 if stats.visible else 28,640,48,36)
	match value:
		"campaign":
			var names: Array=context.get("maps",[])
			for i in range(names.size()):
				var button := _wide_button("%02d / %s" % [i+1,names[i]],.25 if i%2==0 else .75,145+(i/2)*66,column,"campaign_start",i)
				button.disabled=i>=int(context.get("unlocked",1))
			_footer("BACK","main")
		"multiplayer":
			for i in range(4):_wide_button("%d v %d" % [i+1,i+1],.25 if i%2==0 else .75,160+(i/2)*80,column,"mp_format",i+1)
			_footer("BACK","main")
		"format":
			_wide_text("%dv%d / SAME WI-FI OR HOTSPOT\nOpen slots are filled by bots." % [context.get("size",1),context.get("size",1)],.5,98,700,66)
			_wide_button("HOST ROOM",.25,200,column,"lan_host")
			_wide_button("JOIN ROOM",.75,200,column,"join_screen")
			_wide_button("PRACTICE WITH BOTS",.5,280,column,"practice")
			_footer("BACK","multiplayer")
		"join":
			_wide_text("Enter the host phone's Wi-Fi IP address. Both phones must run this version.",.5,105,760,50)
			ip=LineEdit.new()
			ip.text=context.get("ip","")
			ip.placeholder_text="192.168.1.25"
			ip.max_length=80
			ip.add_theme_font_override("font",FONT)
			ip.add_theme_font_size_override("font_size",28)
			ip.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
			ip.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
			overlay.add_child(ip)
			_place(ip,Vector2(.5,0),Vector2(-250,180),Vector2(500,52))
			_wide_button("CONNECT",.5,270,400,"lan_join")
			_wide_text(context.get("message",""),.5,350,760,66)
			_footer("BACK","format")
		"lobby":
			_wide_text(context.get("status",""),.25,108,column,60)
			_wide_text(context.get("address",""),.25,180,column,65)
			labels["lobby_roster"]=_wide_text(context.get("roster",""),.75,100,column,310,17)
			var button := _wide_button("START MATCH" if context.get("host",false) else "READY",.25,280,column,"lobby_start" if context.get("host",false) else "lobby_ready")
			button.disabled=context.get("host",false) and not context.get("can_start",false)
			_footer("LEAVE ROOM","leave_room")
		"options":
			_wide_text("TOUCH AIM / %d%%" % context.get("sensitivity_pct",180),.25,100,column,38)
			_wide_button("−",.25,145,64,"sensitivity_adjust",-.1)
			var minus: Button=buttons.back()
			minus.position.x-=110
			_wide_button("RESET",.25,145,120,"sensitivity_reset")
			_wide_button("+",.25,145,64,"sensitivity_adjust",.1)
			var plus: Button=buttons.back()
			plus.position.x+=110
			_wide_button("CONTROLLER SETTINGS",.75,145,column,"controller_options")
			_wide_button("EFFECTS / %d%%" % roundi(float(context.get("volume",.8))*100),.25,220,column,"option_volume")
			_wide_button("MUSIC / %d%%" % roundi(float(context.get("music",.35))*100),.75,220,column,"option_music")
			_wide_button("AMBIENCE / %d%%" % roundi(float(context.get("ambience",.5))*100),.25,280,column,"option_ambience")
			_wide_button("INVERT AIM / %s" % ("ON" if context.get("invert",false) else "OFF"),.75,280,column,"option_invert")
			_wide_button("CAMERA MOTION / %s" % ("ON" if context.get("motion",true) else "MINIMAL"),.25,340,column,"option_motion")
			_wide_button("SCREEN / %s" % context.get("orientation","AUTO"),.75,340,column,"option_orientation")
			_footer("BACK","options_back")
		"paused":
			_wide_button("RESUME",.5,170,450,"resume")
			_wide_button("OPTIONS",.5,240,450,"options")
			_wide_button("RETURN TO MAIN MENU",.5,310,450,"abandon")
			_wide_text("LAN keeps running behind this menu." if context.get("lan",false) else "Your match is paused.",.5,365,700,60)
		"shop":
			_wide_text("Spend souls. Ready up when finished. Shopping closes after 30 seconds.",.5,155,w-60,32,17)
			var items: Array=context.get("items",[])
			for i in range(items.size()):
				var item: Dictionary=items[i]
				var button := _wide_button(item["text"],.25 if i%2==0 else .75,200+(i/2)*46,column,"buy",item["id"],42,17)
				button.disabled=item.get("disabled",false)
			_wide_button("READY / CONTINUE",.5,h-50,400,"shop_ready",null,40)
		"reveal":
			_wide_text("ONE ROLL EACH / SHARED REVEAL",.5,155,w-60,35,17)
			var count: int=context.get("count",2)
			var columns := maxi(1,count/2)
			for i in range(count):
				var x: float=(float(i%columns)+.5)/columns
				var y: float=220+(i/columns)*115
				labels["gift_%d" % i]=_wide_text("",x,y,w/columns-35,100,17)
			_update_rewards(context.get("rewards",[]),context.get("names",[]),false)
		"results":
			_wide_text(context.get("summary",""),.5,170,760,235,23)
			_wide_button("CONTINUE",.5,h-110,350,"results_continue")
			_footer("MAIN MENU","abandon")
		"credits":
			_wide_text("Sinbad minions: © Zi Ye / CC BY-SA 3.0\nTextures / ambientCG CC0  ·  Sky / Poly Haven CC0\nRajdhani / Indian Type Foundry SIL OFL\nSentinel, music, hand, icons, code / original MIT\nFull notices: repository ASSET_CREDITS.md\ncreativecommons.org/licenses/by-sa/3.0/",.5,125,800,270,21)
			_footer("BACK","main")

func _controller_screen(value: String,context: Dictionary) -> void:
	var h := overlay.size.y
	var w := overlay.size.x
	_wide_text({"controller_options":"CONTROLLER SETTINGS","bind_controller":"BIND BUTTON","controller_help":"CONTROLLER GUIDE"}[value],.5,28 if landscape else h*.14,minf(w-30,700),60,34 if landscape else 36)
	if value=="bind_controller":
		_wide_text("%s\nPress a face, shoulder, stick-click, or Start button.\nView / Select cancels. D-pad stays reserved for movement." % str(context.get("action","")).to_upper(),.5,h*.35,minf(w-40,700),190,24)
		_footer("CANCEL","controller_cancel_bind")
	elif value=="controller_help":
		_wide_text(context.get("guide",""),.5,125 if landscape else h*.30,minf(w-40,760),300 if landscape else 510,20)
		_footer("BACK","controller_help_back")
	else:
		_wide_text(context.get("device","NO CONTROLLER CONNECTED"),.5,92 if landscape else h*.24,minf(w-40,700),50,17)
		var entries: Array=context.get("entries",[])
		for i in range(entries.size()):
			var item: Dictionary=entries[i]
			if landscape:_wide_button(item["text"],.25 if i%2==0 else .75,155+(i/2)*54,minf(410,(w-80)/2),item["kind"],item.get("value"),44,19)
			else:_wide_button(item["text"],.5,h*.32+i*49,minf(w-40,470),item["kind"],item.get("value"),44,21)
		_footer("BACK","controller_back")
