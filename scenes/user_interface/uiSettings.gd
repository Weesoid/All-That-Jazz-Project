extends Control

@onready var fps = $PanelContainer/General/ScrollContainer/VBoxContainer/FPSCap/Label/FPS
@onready var tabs = $PanelContainer
@onready var fps_slider = $PanelContainer/General/ScrollContainer/VBoxContainer/FPSCap/Option
@onready var master_slider = $PanelContainer/General/ScrollContainer/VBoxContainer/Master/Option
@onready var music_slider = $PanelContainer/General/ScrollContainer/VBoxContainer/MusicSlider/Option
@onready var sounds_slider = $PanelContainer/General/ScrollContainer/VBoxContainer/SoundSlider/Option
@onready var window_options = $PanelContainer/General/ScrollContainer/VBoxContainer/Window/Option
@onready var vsync_toggle = $PanelContainer/General/ScrollContainer/VBoxContainer/Vsync/Option
@onready var keybind_container = $PanelContainer/Controls/ScrollContainer/VBoxContainer
#@onready var resolution_options = $PanelContainer/Display/VBoxContainer/Resolution/Option
#var resolutions: Dictionary = {
#	'3840x2160': Vector2i(3840,2160),
#	'2560x1440': Vector2i(2560,1440),
#	'1920x1080': Vector2i(1920,1080),
#	'1152x648': Vector2i(1152,648),
#	'1280x720': Vector2i(1280,720),
#	'854x480': Vector2i(854,480)
#}

var window_modes: Array[String] = ['Borderless Windowed', 'Windowed', 'Fullscreen']
var editable_keybinds: Dictionary = {
	'ui_move_up': 'Move Up',
	'ui_move_left': 'Move Left',
	'ui_move_down': 'Move Down',
	'ui_move_right': 'Move Right',
	'ui_sprint': 'Sprint',
	'ui_bow': 'Equip Bow',
	'ui_select_arrow': 'Quiver',
	'ui_gambit': 'Channel Void',
	'ui_show_menu': 'Show Menu'
}
var is_rebinding: bool = false
var rebinding_action: String
signal done_rebinding

func _process(_delta):
	if fps != null:
		if fps_slider.value >= 120:
			fps.text = 'UNLIMITED'
		else:
			fps.text = str(fps_slider.value)
	
func _ready():
	for mode in window_modes:
		window_options.add_item(mode)
	loadKeybinds()
	
	master_slider.value  = db_to_linear(AudioServer.get_bus_volume_db(master_slider.value))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_slider.value))
	sounds_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sounds_slider.value))
	
	window_options.item_selected.connect(changeWindowMode)
	fps_slider.value_changed.connect(changeFPS)
	vsync_toggle.toggled.connect(toggleVsync)
	master_slider.value_changed.connect(changeMasterVolume)
	music_slider.value_changed.connect(changeMusicVolume)
	sounds_slider.value_changed.connect(changeSoundsVolume)

func loadKeybinds():
	for child in keybind_container.get_children():
		child.queue_free()
	#InputMap.load_from_project_settings()
	for action in editable_keybinds.keys():
		var button: KeybindButton = load("res://scenes/user_interface/KeybindButton.tscn").instantiate()
		button.find_child('Action').text = str(editable_keybinds[action])
		button.find_child('Input').text = InputHelper.get_label_for_input(InputHelper.get_keyboard_input_for_action(action)) 
		keybind_container.add_child(button)
		button.pressed.connect(
			func():
				Input.action_release("ui_accept")
				rebinding_action = action
				await get_tree().process_frame
				is_rebinding = true
				button.find_child('Input').text = 'Awaiting input...'
				await done_rebinding
				loadKeybinds()
				)
	
	await get_tree().process_frame
	OverworldGlobals.setMenuFocus(keybind_container)

func _unhandled_input(event) -> void:
	if is_rebinding:
		#Input.action_release("ui_accept")
		if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
			var current_action = InputHelper.get_keyboard_input_for_action(rebinding_action)
			accept_event()
			InputHelper.replace_keyboard_input_for_action(rebinding_action, current_action, event)
		if event is InputEventJoypadButton and event.is_pressed():
			var current_action = InputHelper.get_keyboard_input_for_action(rebinding_action)
			accept_event()
			InputHelper.replace_joypad_input_for_action(rebinding_action, current_action, event)
		is_rebinding = false
		done_rebinding.emit()
# DISPLAY SETTINGS
#func changeResolution(index: int):
#	get_viewport().size = resolutions[resolution_options.get_item_text(index)]

func changeWindowMode(index: int):
	var mode = window_modes[index] 
	match mode:
		'Borderless Windowed':
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		'Windowed':
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		'Fullscreen':
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)

func changeFPS(value):
	if value >= 120:
		Engine.max_fps = 0
	else:
		Engine.max_fps = value

func toggleVsync(value):
	if value:
		print('poop')
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		print('pee')
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

# AUDIO SETTINGS
func changeMasterVolume(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), linear_to_db(value))

func changeMusicVolume(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear_to_db(value))

func changeSoundsVolume(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear_to_db(value))
#
#func _unhandled_input(_event):
#	if Input.is_action_just_pressed('ui_tab_right') and (tabs.current_tab + 1 < tabs.get_tab_count() and !tabs.is_tab_disabled(tabs.current_tab + 1)):
#		tabs.current_tab += 1
#	elif Input.is_action_just_pressed('ui_tab_left') and (tabs.current_tab - 1 >= 0 and !tabs.is_tab_disabled(tabs.current_tab - 1)):
#		tabs.current_tab -= 1
