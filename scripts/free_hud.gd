extends "res://scripts/arena_hud.gd"
const Stick=preload("res://scripts/touch_stick.gd")
var stick: Control
var lock_button: Control
var lock_brackets: Control
func _ready() -> void:
	super._ready()
	stick=Stick.new();combat.add_child(stick);stick.moved.connect(func(value):action.emit("move",value))
	lock_button=preload("res://scripts/lock_button.gd").new();combat.add_child(lock_button);lock_button.held.connect(func(value):action.emit("lock",value))
	lock_brackets=preload("res://scripts/lock_brackets.gd").new();combat.add_child(lock_brackets);lock_brackets.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	schedule_layout()
func _layout_combat() -> void:
	super._layout_combat()
	for button in routes.values():button.hide()
	down.hide();reverse.hide();essence.hide()
	if not is_instance_valid(stick):return
	_place(stick,Vector2(0,1),Vector2(22+safe_margins.x,-325),Vector2(160,160))
	_place(jump,Vector2(1,1),Vector2(-95-safe_margins.z,-255),Vector2(72,72))
	_place(lock_button,Vector2(0,1),Vector2(67+safe_margins.x,-410),Vector2(70,70))
	lock_button.visible=not controller_mode
	stick.visible=not controller_mode
	_place(labels["route"],Vector2(.5,0),Vector2(-250,94),Vector2(500,26))
	labels["route"].horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func set_controller_mode(value: bool,help_text := "") -> void:
	super.set_controller_mode(value,help_text)
	for button in routes.values():button.hide()
	down.hide();reverse.hide();essence.hide()
	if is_instance_valid(stick):stick.visible=not value
	if is_instance_valid(lock_button):
		lock_button.visible=not value
		if value:lock_button.release()
func show_screen(value: String,context: Dictionary) -> void:
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
	reticle.lock_active=view.get("lock_active",false);reticle.lock_progress=view.get("lock_progress",0.0)
	lock_brackets.target=view.get("lock_rect",Rect2());lock_brackets.queue_redraw()
	if screen=="conditions":
		var rolling: bool=float(view.get("prelude",0))>3.8
		if is_instance_valid(labels.get("condition_time")):
			labels["condition_time"].text="TIME OF DAY\n"+(["DARK SUNSET","STORM FRONT","OVERCAST DUSK","NIGHT"][int(time*10)%4] if rolling else str(view.get("conditions",{}).get("time","")))
			labels["condition_weather"].text="WEATHER\n"+(["OVERCAST","RAIN","FOG","CALM BEFORE STORM"][int(time*12)%4] if rolling else str(view.get("conditions",{}).get("weather","")))
