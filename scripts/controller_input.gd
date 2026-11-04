extends Node
## Godot's standardized Android/SDL gamepad events: USB and Bluetooth, hot-pluggable.
signal command(kind: String,value: Variant)
signal look(radians: Vector2)
signal mode_changed(active: bool)
signal disconnected
signal bindings_changed
const LEGACY_DEFAULTS := {"jump":JOY_BUTTON_A,"reverse":JOY_BUTTON_B,"reload":JOY_BUTTON_X,"suction":JOY_BUTTON_Y,"pause":JOY_BUTTON_START}
const DEFAULTS := {"jump":JOY_BUTTON_A,"reverse":JOY_BUTTON_Y,"reload":JOY_BUTTON_RIGHT_SHOULDER,"suction":JOY_BUTTON_B,"pause":JOY_BUTTON_START}
var bindings: Dictionary = DEFAULTS.duplicate()
var device := -1
var active := false
var playing := false
var sensitivity := 1.0
var deadzone := 0.18
var swap_sticks := false
var capture := ""
var axes: Dictionary = {}
var held: Dictionary = {}
var route_latch := ""
var nav_direction := Vector2.ZERO
var repeat_left := 0.0
var trigger_latches: Dictionary = {}
var wheel_open := false
var locking := false
var lock_heartbeat := 0.0
const FREE_DEFAULTS := {"jump":JOY_BUTTON_A,"lock":JOY_BUTTON_Y,"reload":JOY_BUTTON_RIGHT_SHOULDER,"wheel":JOY_BUTTON_LEFT_SHOULDER,"pause":JOY_BUTTON_START}
var firing := false
var fire_heartbeat := 0.0
var free_movement := true
var move_heartbeat := 0.0
var last_move := Vector2.ZERO

func _ready() -> void:
	Input.joy_connection_changed.connect(_connection)
	var devices := Input.get_connected_joypads()
	if not devices.is_empty():device = devices[0]

func _connection(id: int,connected: bool) -> void:
	if connected:
		if device<0:device=id
	elif id==device:
		clear_axes()
		device = -1
		set_active(false)
		capture = ""
		disconnected.emit()

func clear_axes() -> void:
	stop_wheel()
	stop_firing()
	stop_locking()
	stop_moving()
	axes.clear()
	held.clear()
	trigger_latches.clear()
	route_latch = ""
	nav_direction = Vector2.ZERO
	repeat_left = 0

func set_active(value: bool) -> void:
	if value==active:return
	active=value
	if not active:stop_wheel();stop_firing();stop_locking();stop_moving()
	mode_changed.emit(active)

func device_name() -> String:
	return Input.get_joy_name(device) if device in Input.get_connected_joypads() else "STANDARD GAMEPAD" if device>=0 else "NO CONTROLLER CONNECTED"

func button_name(button: int) -> String:
	var name_lower := device_name().to_lower()
	var face := ["A","B","X","Y"]
	if "playstation" in name_lower or "dual" in name_lower or "sony" in name_lower:face=["CROSS","CIRCLE","SQUARE","TRIANGLE"]
	elif "nintendo" in name_lower or "switch" in name_lower:face=["B","A","Y","X"]
	if button>=0 and button<4:return face[button]
	return {JOY_BUTTON_BACK:"VIEW",JOY_BUTTON_GUIDE:"HOME",JOY_BUTTON_START:"START",JOY_BUTTON_LEFT_STICK:"L3",JOY_BUTTON_RIGHT_STICK:"R3",JOY_BUTTON_LEFT_SHOULDER:"LB",JOY_BUTTON_RIGHT_SHOULDER:"RB"}.get(button,"BUTTON %d" % button)

func prompt() -> String:
	if free_movement:return "LB WHEEL   LT LOCK   RT FIRE   %s JUMP   %s RELOAD" % [button_name(bindings["jump"]),button_name(bindings["reload"]) ]
	return "RT FIRE   %s JUMP   %s 180°   %s RELOAD   %s HARVEST" % [button_name(bindings["jump"]),button_name(bindings["reverse"]),button_name(bindings["reload"]),button_name(bindings["suction"])]

func shoulder_prompt() -> String:
	var aliases: Array[String]=[]
	for button in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
		var action := ("wheel" if free_movement else "jump") if button==JOY_BUTTON_LEFT_SHOULDER else "reload"
		for primary in bindings:
			if bindings[primary]==button:action=primary
		aliases.append(button_name(button)+": "+("HARVEST" if action=="suction" else action.to_upper()))
	return "   ".join(aliases)

func handle(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		if event.device!=device and absf(event.axis_value)<0.4:return
		if event.device!=device:clear_axes();device=event.device
		axes[event.axis]=event.axis_value
		if absf(event.axis_value)>(deadzone+.02 if event.axis<4 else .65):set_active(true)
	elif event is InputEventJoypadButton:
		if not event.pressed:
			held.erase(event.button_index)
			if free_movement and event.button_index in [bindings.get("wheel",JOY_BUTTON_LEFT_SHOULDER),JOY_BUTTON_LEFT_SHOULDER]:stop_wheel()
			return
		if event.device!=device:clear_axes();device=event.device
		set_active(true)
		var button := int(event.button_index)
		if held.has(button):return
		held[button]=true
		if not capture.is_empty():
			if button==JOY_BUTTON_BACK:
				capture=""
				bindings_changed.emit()
			elif button in [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_X,JOY_BUTTON_Y,JOY_BUTTON_START,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_LEFT_STICK,JOY_BUTTON_RIGHT_STICK]:
				bind(capture,button)
				capture=""
				bindings_changed.emit()
			return
		var direction: Vector2 = {JOY_BUTTON_DPAD_LEFT:Vector2.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2.RIGHT,JOY_BUTTON_DPAD_UP:Vector2.UP,JOY_BUTTON_DPAD_DOWN:Vector2.DOWN}.get(button,Vector2.ZERO)
		if direction!=Vector2.ZERO:
			if playing:
				if wheel_open:command.emit("wheel_cycle",-1 if direction.x<0 or direction.y<0 else 1)
				elif not free_movement:command.emit("turn",_route(direction))
			else:
				nav_direction=direction;repeat_left=.4
				command.emit("nav",direction)
			return
		if not playing:
			if button==JOY_BUTTON_A:command.emit("confirm",null)
			elif button==JOY_BUTTON_B:command.emit("cancel",null)
			elif button==JOY_BUTTON_START:command.emit("pause",null)
			elif button==JOY_BUTTON_BACK:command.emit("controls",null)
			return
		if wheel_open and button not in [bindings.get("wheel",JOY_BUTTON_LEFT_SHOULDER),JOY_BUTTON_LEFT_SHOULDER,bindings["pause"],JOY_BUTTON_BACK]:
			if button==JOY_BUTTON_B:wheel_open=false;command.emit("wheel_cancel",null)
			return
		for action in bindings:
			if bindings[action]==button:
				if action=="wheel":wheel_open=true;command.emit("wheel",true)
				elif action!="lock":command.emit(action,null)
				return
		if button==JOY_BUTTON_RIGHT_SHOULDER or button==JOY_BUTTON_X:command.emit("reload",null)
		elif button==JOY_BUTTON_LEFT_SHOULDER:
			if free_movement:wheel_open=true;command.emit("wheel",true)
			else:command.emit("jump",null)
		elif button==JOY_BUTTON_BACK:command.emit("controls",null)

func stop_moving() -> void:
	if last_move!=Vector2.ZERO:command.emit("move",Vector2.ZERO)
	last_move=Vector2.ZERO;move_heartbeat=0

func stop_firing() -> void:
	if firing:
		firing=false
		command.emit("fire",false)
	fire_heartbeat=0

func bind(action: String,button: int) -> void:
	if not bindings.has(action):return
	var previous: int=bindings[action]
	for other in bindings:
		if other!=action and bindings[other]==button:bindings[other]=previous
	bindings[action]=button

func filtered(stick: Vector2) -> Vector2:
	var magnitude := minf(1,stick.length())
	if magnitude<=deadzone:return Vector2.ZERO
	return stick.normalized()*pow((magnitude-deadzone)/(1.0-deadzone),1.5)

func _route(direction: Vector2) -> String:
	if absf(direction.x)>absf(direction.y):return "left" if direction.x<0 else "right"
	return "ahead" if direction.y<0 else "down"

func _physics_process(delta: float) -> void:
	step(delta)

func step(delta: float) -> void:
	if device in Input.get_connected_joypads():
		for axis in range(6):axes[axis]=Input.get_joy_axis(device,axis)
	if not active or not capture.is_empty():return
	var left := Vector2(float(axes.get(JOY_AXIS_LEFT_X,0)),float(axes.get(JOY_AXIS_LEFT_Y,0)))
	var right := Vector2(float(axes.get(JOY_AXIS_RIGHT_X,0)),float(axes.get(JOY_AXIS_RIGHT_Y,0)))
	var aiming := left if swap_sticks else right
	var routing := right if swap_sticks else left
	if playing:
		if wheel_open:
			stop_moving();stop_firing();stop_locking();command.emit("wheel_aim",aiming);return
		var aim := filtered(aiming)
		if aim!=Vector2.ZERO:look.emit(aim*2.6*sensitivity*minf(delta,0.05))
		if free_movement:
			var movement:=filtered(routing)
			for button in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:
				if held.has(button):movement+={JOY_BUTTON_DPAD_LEFT:Vector2.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2.RIGHT,JOY_BUTTON_DPAD_UP:Vector2.UP,JOY_BUTTON_DPAD_DOWN:Vector2.DOWN}[button]
			movement=movement.limit_length(1)
			move_heartbeat-=delta
			if move_heartbeat<=0 or (movement==Vector2.ZERO and last_move!=Vector2.ZERO):
				command.emit("move",movement);last_move=movement;move_heartbeat=1.0/30
		elif routing.length()<0.35:route_latch=""
		elif routing.length()>0.65:
			var route := _route(routing)
			if route!=route_latch:route_latch=route;command.emit("turn",route)
		var right_trigger := float(axes.get(JOY_AXIS_TRIGGER_RIGHT,0))
		if right_trigger<.3:stop_firing()
		elif right_trigger>.65 and not firing:
			firing=true;fire_heartbeat=0
		if firing:
			fire_heartbeat-=delta
			if fire_heartbeat<=0:
				command.emit("fire",true)
				fire_heartbeat=.18
		if free_movement:
			var lt:=float(axes.get(JOY_AXIS_TRIGGER_LEFT,0))
			var requested: bool=lt>(.3 if locking else .65) or held.has(bindings.get("lock",JOY_BUTTON_Y))
			if not requested:stop_locking()
			else:
				locking=true;lock_heartbeat-=delta
				if lock_heartbeat<=0:command.emit("lock",true);lock_heartbeat=.18
		else:
			var lt:=float(axes.get(JOY_AXIS_TRIGGER_LEFT,0))
			if lt<.3:trigger_latches[JOY_AXIS_TRIGGER_LEFT]=false
			elif lt>.65 and not trigger_latches.get(JOY_AXIS_TRIGGER_LEFT,false):
				trigger_latches[JOY_AXIS_TRIGGER_LEFT]=true;command.emit("reverse",null)
	else:
		var direction := Vector2.ZERO
		for button in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:
			if held.has(button):direction={JOY_BUTTON_DPAD_LEFT:Vector2.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2.RIGHT,JOY_BUTTON_DPAD_UP:Vector2.UP,JOY_BUTTON_DPAD_DOWN:Vector2.DOWN}[button]
		if left.length()>0.65:direction=Vector2.LEFT if absf(left.x)>absf(left.y) and left.x<0 else Vector2.RIGHT if absf(left.x)>absf(left.y) else Vector2.UP if left.y<0 else Vector2.DOWN
		if direction==Vector2.ZERO:nav_direction=direction;repeat_left=0
		elif direction!=nav_direction:
			nav_direction=direction;repeat_left=0.4;command.emit("nav",direction)
		else:
			repeat_left-=delta
			if repeat_left<=0:repeat_left=0.15;command.emit("nav",direction)

func stop_locking() -> void:
	if locking:locking=false;command.emit("lock",false)
	lock_heartbeat=0
func default_bindings() -> Dictionary:return FREE_DEFAULTS.duplicate() if free_movement else DEFAULTS.duplicate()

func stop_wheel() -> void:
	if wheel_open:wheel_open=false;command.emit("wheel",false)
