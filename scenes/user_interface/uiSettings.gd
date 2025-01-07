extends Control

@onready var fps = $PanelContainer/Display/VBoxContainer/FPSCap/Label/FPS
@onready var tabs = $PanelContainer
@onready var keybind_container = $PanelContainer/Controls/ScrollContainer/VBoxContainer
@onready var fps_slider = $PanelContainer/Display/VBoxContainer/FPSCap/Option
@onready var master_slider = $PanelContainer/Sounds/VBoxContainer2/Master/Option
@onready var music_slider = $PanelContainer/Sounds/VBoxContainer2/MusicSlider/Option
@onready var sounds_slider = $PanelContainer/Sounds/VBoxContainer2/SoundSlider/Option
@onready var window_options = $PanelContainer/Display/VBoxContainer/Window/Option
@onready var vsync_toggle = $PanelContainer/Display/VBoxContainer/Vsync/Option
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
	'ui_up': 'Move Up',
	'ui_down': 'Move Down',
	'ui_left': 'Move Left',
	'ui_right': 'Move Right',
	'ui_bow': 'Equip Bow'
}

func _process(_delta):
	if fps != null:
		if fps_slider.value >= 120:
			fps.text = 'UNLIMITED'
		else:
			fps.text = str(fps_slider.value)
	
func _ready():
#	for resolution in resolutions:
#		resolution_options.add_item(resolution)
	for mode in window_modes:
		window_options.add_item(mode)
	loadKeybinds()
	
	master_slider.value  = db_to_linear(AudioServer.get_bus_volume_db(master_slider.value))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_slider.value))
	sounds_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sounds_slider.value))
	
#	resolution_options.item_selected.connect(changeResolution)
	
	window_options.item_selected.connect(changeWindowMode)
	fps_slider.value_changed.connect(changeFPS)
	vsync_toggle.toggled.connect(toggleVsync)
	master_slider.value_changed.connect(changeMasterVolume)
	music_slider.value_changed.connect(changeMusicVolume)
	sounds_slider.value_changed.connect(changeSoundsVolume)

func loadKeybinds():
	InputMap.load_from_project_settings()
	
	for action in InputMap.get_actions():
		if !editable_keybinds.keys().has(action): continue
		
		var button: KeybindButton = load("res://scenes/user_interface/KeybindButton.tscn").instantiate()
		button.text = str(editable_keybinds[action]) + '\n' + eventToText(InputMap.action_get_events(action))
#		button.action_label.text = str(action)
#		button.input_label.text = InputMap.action_get_events(action)[0].as_text()
		keybind_container.add_child(button)

func eventToText(events: Array[InputEvent]):
	var out = ''
	var regex = RegEx.new()
	regex.compile("\\((.*?)\\)")
	
	for event in events:
		var text_event = event.as_text()
		if text_event.contains('(') and !text_event.contains('(Physical)'):
			text_event = regex.search(text_event).get_string().strip_edges().split(',')[0].replace('(', '').replace(')', '')
		out += '%s /' % text_event
	return out

# DISPLAY SETTINGS
#func changeResolution(index: int):
#	get_viewport().size = resolutions[resolution_options.get_item_text(index)]

func changeWindowMode(index: int):
	var mode = window_modes[index] 
	print(mode)
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

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_tab_right') and (tabs.current_tab + 1 < tabs.get_tab_count() and !tabs.is_tab_disabled(tabs.current_tab + 1)):
		tabs.current_tab += 1
	elif Input.is_action_just_pressed('ui_tab_left') and (tabs.current_tab - 1 >= 0 and !tabs.is_tab_disabled(tabs.current_tab - 1)):
		tabs.current_tab -= 1
