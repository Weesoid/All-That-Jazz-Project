extends CustomButton
class_name KeybindButton

@onready var action_label = $MarginContainer/HBoxContainer/Action
@onready var input_label = $MarginContainer/HBoxContainer/Input
var is_rebinding:bool=false
var action:String

func _on_bind_pressed():
	Input.action_release("ui_accept")
	release_focus()
	await get_tree().process_frame
	is_rebinding = true
	input_label.text = 'Awaiting input...'
	SettingsGlobals.keybind_pressed.emit(action)

func _input(event):
	if !is_rebinding or event is InputEventMouseMotion:
		return
	print(event)
	if (event is InputEventKey and event.is_pressed()) or event is InputEventMouseButton:
		accept_event()
		InputHelper._update_keyboard_input_for_action(action, event, true)
	elif (event is InputEventJoypadButton and event.is_pressed()) or event is InputEventJoypadMotion:
		accept_event()
		InputHelper._update_joypad_input_for_action(action, event)
	update()
	SettingsGlobals.keybind_updated.emit(action, event)
	is_rebinding = false
	grab_focus()

func pulse():
#	rotation = 1
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	input_label.modulate = Color.YELLOW
	tween.tween_property(input_label,'modulate', Color.WHITE,1)
#	tween.tween_property(self, 'rotation', 0,1)

func reset():
	var old_action = InputHelper.get_joypad_input_for_action(action) if UIGlobals.isUsingController() else InputHelper.get_keyboard_input_for_action(action)
	if UIGlobals.isUsingController():
		InputHelper._update_joypad_input_for_action(action, old_action)
	else:
		InputHelper._update_keyboard_input_for_action(action, old_action, true)
	update()

func resetButton(p_action):
	if is_rebinding and action != p_action:
		reset()
		SettingsGlobals.keybind_updated.emit(action, InputHelper.get_joypad_input_for_action(action) if UIGlobals.isUsingController() else InputHelper.get_keyboard_input_for_action(action))
		is_rebinding=false

func update():
	await get_tree().process_frame
	var previous_input_label = input_label.text
	action_label.text = action.trim_prefix('ui_').replace('_', ' ').capitalize()
	input_label.text = InputHelper.get_label_for_input(InputHelper.get_keyboard_input_for_action(action)) if !UIGlobals.isUsingController() else InputHelper.get_label_for_input(InputHelper.get_joypad_input_for_action(action)) 
	if input_label.text != previous_input_label:
		pulse()

func connectSignals():
	SettingsGlobals.keybind_updated.connect(update.unbind(2))
	SettingsGlobals.keybind_pressed.connect(resetButton)
	UIGlobals.getControllerAdapter().device_switched.connect(update.unbind(1))
