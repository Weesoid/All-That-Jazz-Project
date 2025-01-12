extends Node
class_name MouseController

@onready var fade_out_timer = $FadeOutTimer
var sensitivity: float = 200.0
var x_axis: float = 0.0
var y_axis: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event is InputEventJoypadMotion:
		if event.axis == 2:
			x_axis = event.axis_value
		if event.axis == 3:
			y_axis = event.axis_value
		fade_out_timer.stop()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseMotion:
		fade_out_timer.stop()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventJoypadButton and event.device == 0 and event.button_index == JOY_BUTTON_RIGHT_STICK and event.pressed:
		click()

func click():
	var a = InputEventMouseButton.new()
	a.position = get_viewport().get_screen_transform() * get_viewport().get_mouse_position()
	a.button_index = MOUSE_BUTTON_LEFT
	a.pressed = true
	Input.parse_input_event(a)
	await get_tree().process_frame
	a.pressed = false
	Input.parse_input_event(a)

func _process(delta):
	if InputEventJoypadMotion and (x_axis != 0.0 or y_axis != 0.0):
		var new_mouse_pos = get_viewport().get_mouse_position() + (Vector2(x_axis, y_axis) * sensitivity * delta)
		get_viewport().warp_mouse(new_mouse_pos)
	if fade_out_timer.is_stopped():
		fade_out_timer.start()

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_fade_out_timer_timeout():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
