extends "res://scripts/arena_hud.gd"
const Stick=preload("res://scripts/touch_stick.gd")
var damage_edges: Control
var wheel: Control
var wheel_button: Control
var stick: Control
var lock_button: Control
var lock_brackets: Control
func _ready() -> void:
	super._ready()
	stick=Stick.new();combat.add_child(stick);stick.moved.connect(func(value):action.emit("move",value))
	lock_button=preload("res://scripts/lock_button.gd").new();combat.add_child(lock_button);lock_button.held.connect(func(value):action.emit("lock",value))
	lock_brackets=preload("res://scripts/lock_brackets.gd").new();combat.add_child(lock_brackets);lock_brackets.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wheel=preload("res://scripts/weapon_wheel.gd").new();combat.add_child(wheel);wheel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wheel_button=preload("res://scripts/weapon_wheel_button.gd").new();combat.add_child(wheel_button);wheel_button.held.connect(func(value):action.emit("wheel",value))
	damage_edges=preload("res://scripts/damage_edges.gd").new();combat.add_child(damage_edges);damage_edges.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	schedule_layout()
func _layout_combat() -> void:
	super._layout_combat()
	for button in routes.values():button.hide()
	down.hide();reverse.hide();essence.hide();labels["round"].hide()
	if not is_instance_valid(stick):return
	_place(stick,Vector2(0,1),Vector2(22+safe_margins.x,-325),Vector2(160,160))
	_place(jump,Vector2(1,1),Vector2(-95-safe_margins.z,-255),Vector2(72,72))
	_place(lock_button,Vector2(0,1),Vector2(67+safe_margins.x,-410),Vector2(70,70))
	lock_button.visible=not controller_mode
	stick.visible=not controller_mode
	if is_instance_valid(wheel_button):
		_place(wheel_button,Vector2(1,1),Vector2(-177-safe_margins.z,-255),Vector2(68,68))
		wheel_button.visible=not controller_mode
	_place(labels["route"],Vector2(.5,0),Vector2(-250,94),Vector2(500,26))
	labels["route"].horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func set_controller_mode(value: bool,help_text := "") -> void:
	super.set_controller_mode(value,help_text)
	for button in routes.values():button.hide()
	down.hide();reverse.hide();essence.hide();labels["round"].hide()
	if is_instance_valid(stick):stick.visible=not value
	if is_instance_valid(wheel_button):wheel_button.visible=not value
	if is_instance_valid(lock_button):
		lock_button.visible=not value
		if value:lock_button.release()
func show_screen(value: String,context: Dictionary) -> void:
	if value in ["heroes","hero_detail"]:_hero_screen(value,context);return
	if value=="conditions":
		super.show_screen("play",{})
		screen=value;data=context;combat.hide();stats.hide();overlay.show()
		var w:=overlay.size.x;var h:=overlay.size.y
		_wide_text("ARENA CONDITIONS",.5,h*.15,minf(700,w-30),65,42 if landscape else 36)
		labels["condition_time"]=_wide_text("",.25 if landscape else .5,h*.40,minf(440,w-40),85,32)
		labels["condition_weather"]=_wide_text("",.75 if landscape else .5,h*(.40 if landscape else .56),minf(440,w-40),85,30)
		_wide_text("SHARED ROLL / SAME CONDITIONS FOR EVERY PLAYER",.5,h*.80,minf(750,w-30),55,17)
		return
	super.show_screen(value,context)
	if is_instance_valid(stick) and value!="play":stick.release()
	if is_instance_valid(lock_button) and value!="play":lock_button.release()
func update_view(view: Dictionary,delta: float) -> void:
	super.update_view(view,delta)
	labels["round"].hide()
	damage_edges.strength=view.get("damage_edges",Vector4.ZERO);damage_edges.queue_redraw()
	if view.get("infinite_ammo",false):labels["reserve"].text="∞"
	if view.get("melee",false):labels["ammo"].text="∞";labels["reserve"].text=""
	reticle.lock_active=view.get("lock_active",false);reticle.lock_progress=view.get("lock_progress",0.0)
	lock_brackets.target=view.get("lock_rect",Rect2());lock_brackets.queue_redraw()
	if screen=="conditions":
		var rolling: bool=float(view.get("prelude",0))>3.8
		if is_instance_valid(labels.get("condition_time")):
			labels["condition_time"].text="TIME OF DAY\n"+(["DARK SUNSET","STORM FRONT","OVERCAST DUSK","NIGHT"][int(time*10)%4] if rolling else str(view.get("conditions",{}).get("time","")))
			labels["condition_weather"].text="WEATHER\n"+(["OVERCAST","RAIN","FOG","CALM BEFORE STORM"][int(time*12)%4] if rolling else str(view.get("conditions",{}).get("weather","")))

func _hero_screen(value: String,context: Dictionary) -> void:
	super.show_screen("play",{})
	screen=value;data=context;combat.hide();stats.hide();overlay.show()
	var w:=overlay.size.x;var h:=overlay.size.y
	_wide_text("THE TWENTY-FOUR" if value=="heroes" else str(context["hero"]["name"]).to_upper(),.5,25,w-30,58,36)
	if value=="heroes":
		var page: int=context.get("page",0);var heroes: Array=context["heroes"]
		_wide_text("8 MEN / 8 WOMEN / 4 ANTHRO / 4 ROBOTIC",.5,86,w-30,30,16)
		var columns:=4 if landscape else 2
		var card_h:=90.0 if landscape else minf(200,(h-330)/4)
		for i in range(8):
			var index: int=page*8+i
			if index>=heroes.size():break
			var hero: Dictionary=heroes[index];var career: Dictionary=context["careers"][hero["id"]]
			var x: float=(float(i%columns)+.5)/columns;var y: float=145+(i/columns)*card_h
			var button:=_wide_button("%s\n%s / %d OF 5" % [hero["name"].to_upper(),str(hero["kind"]).to_upper(),career["cleared"].size()],x,y,w/columns-30,"hero_select",hero["id"],card_h-12,18)
			var emblem:=preload("res://scripts/hero_emblem.gd").new();emblem.kind=hero["kind"];emblem.species=hero["species"];emblem.variant=index
			button.add_child(emblem);emblem.position=Vector2(3,9);emblem.size=Vector2(42,42)
		_wide_button("CURRENT CAREER",.5,h-155,300,"hero_current",null,40,18)
		_wide_button("PREV",.22,h-105,150,"hero_page",posmod(page-1,3),40,18)
		_wide_text("ROSTER %d / 3"%(page+1),.5,h-100,180,35,18)
		_wide_button("NEXT",.78,h-105,150,"hero_page",posmod(page+1,3),40,18)
		_wide_button("BACK",.5,h-52,260,"hero_back",null,40,18)
	else:
		var hero: Dictionary=context["hero"];var career: Dictionary=context["career"]
		_wide_text("%s / %s / %s" % [str(hero["kind"]).to_upper(),str(hero["species"]).to_upper(),str(hero["role"]).to_upper()],.5,87,w-30,30,17)
		_wide_text(hero["bio"],.5,122,w-40,65 if not landscape else 42,18)
		for i in range(5):
			var mission: Dictionary=context["missions"][i]
			var done: bool=i in career["cleared"];var locked: bool=i>=int(career["unlocked"])
			var text: String=("✓ " if done else "")+mission["title"]+"\n"+("LOCKED" if locked else mission["description"])
			var button:=_wide_button(text,.5,(180 if landscape else 205)+i*(46 if landscape else 78),w-50,"hero_start",i,44 if landscape else 65,17)
			button.disabled=locked
		_wide_text("CAREER / %d WINS / %d FRAGS / %d SOULS" % [career["wins"],career["frags"],career["souls"]],.5,h-105,w-30,35,17)
		_wide_button("HERO ROSTER",.5,h-52,300,"hero_roster",null,40,18)
