extends Node
class_name MouseControllerAdapter

@onready var fade_out_timer = $FadeOutTimer
var using_controller:bool=false
var show_cursor:bool=true
var clicking:bool=false
var send_signal:bool=true

signal device_switched(type:String)

func _ready():
	if show_cursor:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		return
	if show_cursor and Input.mouse_mode != Input.MOUSE_MODE_CONFINED: 
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
	var last_device = 'controller' if using_controller else 'keyboard'
	var focused = get_viewport().gui_get_focus_owner()
	var is_dragging = get_viewport().gui_is_dragging()
	using_controller = event is InputEventJoypadButton or event is InputEventJoypadMotion
	if using_controller and last_device != 'controller':
		device_switched.emit('controller')
	elif !using_controller and last_device != 'keyboard':
		device_switched.emit('keyboard')
	
	if using_controller and Input.is_action_just_pressed("ui_accept") and (canDrag(focused) or canDrop(focused)):
		fastClick()
	elif !is_dragging and using_controller and Input.is_action_pressed("ui_accept") and !canDrag(focused) and !canDrop(focused):
		click()
	elif !is_dragging and using_controller and Input.is_action_just_released("ui_accept") and !canDrag(focused) and !canDrop(focused):
		releaseClick()
	
	elif focused == null and using_controller and UIGlobals.getMenu() != null and OverworldGlobals.player != null:
		UIGlobals.focusFirstControl()

func canDrag(control:Control)-> bool:
	return control != null and control.has_method('_force_drag') and !get_viewport().gui_is_dragging() and (control is ItemButton and control.allow_drag)

func canDrop(control:Control):
	if control == null: return false
	
	var drag_data = get_viewport().gui_get_drag_data()
	return get_viewport().gui_is_dragging() and control.has_method('_can_drop_data') and control._can_drop_data(Vector2.ZERO, drag_data)

func fastClick():
	if clicking:
		return
	
	clicking=true
	var click_input = InputEventMouseButton.new()
	click_input.position = get_viewport().get_screen_transform() * get_viewport().get_mouse_position()
	click_input.button_index = MOUSE_BUTTON_LEFT
	click_input.pressed = true
	Input.parse_input_event(click_input)
	await get_tree().process_frame
	click_input.pressed = false
	Input.parse_input_event(click_input)
	clicking=false

func click():
	Input.action_press("ui_click")

func releaseClick():
	Input.action_release("ui_click")

func _on_tree_exited():
	if show_cursor:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
