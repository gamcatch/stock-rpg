extends Control

# Floating Virtual Joystick for Mobile One-Thumb Controls (1080x2400 Flagship Spec)

signal joystick_vector_changed(vector: Vector2)

@export var max_radius: float = 120.0
@export var deadzone: float = 0.15

var touch_id: int = -1
var is_active: bool = false
var base_pos: Vector2 = Vector2.ZERO
var knob_pos: Vector2 = Vector2.ZERO
var output: Vector2 = Vector2.ZERO

func _ready():
	mouse_filter = MOUSE_FILTER_PASS
	queue_redraw()

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			# Activate when touched in playable screen area (below top HUD)
			if event.position.y > 350.0:
				touch_id = event.index
				is_active = true
				base_pos = event.position
				knob_pos = event.position
				_update_output(Vector2.ZERO)
		elif not event.pressed and event.index == touch_id:
			_reset_joystick()

	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			_handle_drag(event.position)

	# Mouse emulation for testing in PC editor
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_id == -1:
				if event.position.y > 350.0:
					touch_id = 999
					is_active = true
					base_pos = event.position
					knob_pos = event.position
					_update_output(Vector2.ZERO)
			elif not event.pressed and touch_id == 999:
				_reset_joystick()

	elif event is InputEventMouseMotion:
		if touch_id == 999 and is_active:
			_handle_drag(event.position)

func _handle_drag(target_pos: Vector2):
	var diff = target_pos - base_pos
	var dist = diff.length()
	if dist > max_radius:
		diff = diff.normalized() * max_radius
	knob_pos = base_pos + diff
	
	if dist / max_radius > deadzone:
		_update_output((knob_pos - base_pos) / max_radius)
	else:
		_update_output(Vector2.ZERO)

func _update_output(new_out: Vector2):
	output = new_out
	Global.joystick_vector = new_out
	emit_signal("joystick_vector_changed", output)
	queue_redraw()

func _reset_joystick():
	touch_id = -1
	is_active = false
	_update_output(Vector2.ZERO)

func _draw():
	if not is_active:
		return
		
	# Outer glowing ring
	draw_circle(base_pos, max_radius, Color(0.1, 0.3, 0.5, 0.25))
	draw_arc(base_pos, max_radius, 0.0, TAU, 48, Color(0.2, 0.8, 1.0, 0.65), 4.0)
	
	# Center crosshairs
	draw_line(base_pos - Vector2(20, 0), base_pos + Vector2(20, 0), Color(0.3, 0.9, 1.0, 0.45), 2.0)
	draw_line(base_pos - Vector2(0, 20), base_pos + Vector2(0, 20), Color(0.3, 0.9, 1.0, 0.45), 2.0)
	
	# Direction line
	if output.length() > 0.05:
		draw_line(base_pos, knob_pos, Color(0.0, 1.0, 0.5, 0.7), 3.5)
		
	# Inner Knob (Stick Handle)
	var knob_color = Color(0.0, 0.9, 0.4, 0.9) if output.length() > deadzone else Color(0.2, 0.7, 0.9, 0.75)
	draw_circle(knob_pos, 42.0, knob_color)
	draw_circle(knob_pos, 20.0, Color(1.0, 1.0, 1.0, 0.95))
