extends Control

const KEYBIND_BUTTON = preload("res://scenes/user_interface/KeybindButton.tscn")
const DEFAULT_SETTINGS = preload("res://default_settings.tres")
const SAVED_SETTINGS = preload("res://saved_settings.tres")

@onready var fps = $PanelContainer/General/ScrollContainer/VBoxContainer/FPSCap/Label/FPS
@onready var vol_master = $PanelContainer/General/ScrollContainer/VBoxContainer/Master/Label/Volume
@onready var vol_music = $PanelContainer/General/ScrollContainer/VBoxContainer/MusicSlider/Label/Volume
@onready var vol_sounds = $PanelContainer/General/ScrollContainer/VBoxContainer/SoundSlider/Label/Volume
@onready var tabs = $PanelContainer
@onready var fps_slider = $PanelContainer/General/ScrollContainer/VBoxContainer/FPSCap/Option
@onready var master_slider = $PanelContainer/General/ScrollContainer/VBoxContainer/Master/Option
@onready var music_slider = $PanelContainer/General/ScrollContainer/VBoxContainer/MusicSlider/Option
@onready var sounds_slider = $PanelContainer/General/ScrollContainer/VBoxContainer/SoundSlider/Option
@onready var window_options = $PanelContainer/General/ScrollContainer/VBoxContainer/Window/Option
@onready var vsync_toggle = $PanelContainer/General/ScrollContainer/VBoxContainer/Vsync/Option
@onready var sprint_toggle = $PanelContainer/General/ScrollContainer/VBoxContainer/ToggleSprint/Option
@onready var cheat_toggle = $PanelContainer/General/ScrollContainer/VBoxContainer/ToggleCheats/Option
@onready var general_container = $PanelContainer/General/ScrollContainer/VBoxContainer
@onready var keybind_container = $PanelContainer/Controls/ScrollContainer/VBoxContainer
@onready var resolution_options = $PanelContainer/General/ScrollContainer/VBoxContainer/Resolution/Option
@onready var ui_hover_sounds = $HoverPlayer
@onready var ui_click_sounds = $ClickPlayer
@onready var ui_slide_sounds = $SlidePlayer
@onready var apply_button = $ApplySettings

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
var settings = {
	'window_mode': 0,
	'resolution': 0,
	'fps_cap': 60,
	'vsync': true,
	'master_vol': 1.0,
	'music_vol': 1.0,
	'sound_vol': 1.0,
	'toggle_sprint': true,
	'toggle_cheats': false,
	'binds': InputHelper.serialize_inputs_for_actions()
}
#var option_button_settings = {
#	'window_mode': 0,
#	'resolution': 0
#}

signal done_rebinding

func _process(_delta):
	if fps != null:
		if fps_slider.value >= 120:
			fps.text = 'UNLIMITED'
		else:
			fps.text = str(fps_slider.value)
	if vol_master != null:
		vol_master.text = str(int(master_slider.value * 100))+'%'
	if vol_music != null:
		vol_music.text = str(int(music_slider.value * 100))+'%'
	if vol_sounds != null:
		vol_sounds.text = str(int(sounds_slider.value * 100))+'%'

func _ready():
	for mode in SettingsGlobals.window_modes:
		window_options.add_item(mode)
	for resolution in SettingsGlobals.resolutions:
		resolution_options.add_item(resolution)
	loadKeybinds(InputHelper.device)
	if FileAccess.file_exists('saved_settings.tres'):
		await loadSettings(SAVED_SETTINGS, false)
	else:
		await loadSettings(DEFAULT_SETTINGS, false)
	#InputHelper.device_changed.connect(loadKeybinds)
	window_options.item_selected.connect(changeWindowMode)
	resolution_options.item_selected.connect(changeResolution)
	fps_slider.value_changed.connect(changeFPS)
	vsync_toggle.toggled.connect(toggleVsync)
	master_slider.value_changed.connect(changeMasterVolume)
	music_slider.value_changed.connect(changeMusicVolume)
	sounds_slider.value_changed.connect(changeSoundsVolume)
	sprint_toggle.toggled.connect(toggleSprint)
	cheat_toggle.toggled.connect(toggleCheats)
	
	addSound(master_slider)
	addSound(music_slider)
	addSound(sounds_slider)
	addSound(window_options)
	addSound(resolution_options)
	addSound(fps_slider)
	addSound(vsync_toggle)
	addSound(sprint_toggle)
	addSound(cheat_toggle)
	
	await get_tree().process_frame
	resolution_options.disabled = SettingsGlobals.window_modes[settings['window_mode']] == 'Fullscreen'
	window_options.grab_focus()

func changeWindowMode(index: int):
	apply_button.show()
	settings['window_mode'] = index
	resolution_options.disabled = SettingsGlobals.window_modes[settings['window_mode']] == 'Fullscreen'

func changeResolution(index: int):
	apply_button.show()
	settings['resolution'] = index

func changeFPS(value):
	apply_button.show()
	settings['fps_cap'] = value

func toggleVsync(value):
	apply_button.show()
	settings['vsync'] = value

func toggleSprint(value):
	apply_button.show()
	settings['toggle_sprint'] = value

func toggleCheats(value):
	apply_button.show()
	settings['toggle_cheats'] = value

func changeMasterVolume(value):
	apply_button.show()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), linear_to_db(value))
	settings['master_vol'] = value

func changeMusicVolume(value):
	apply_button.show()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear_to_db(value))
	settings['music_vol'] = value

func changeSoundsVolume(value):
	apply_button.show()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear_to_db(value))
	settings['sound_vol'] = value

func loadKeybinds(device: String, _device_index:int=0):
	for child in keybind_container.get_children():
		child.queue_free()
	await get_tree().process_frame
	for action in editable_keybinds.keys():
		var button: KeybindButton = KEYBIND_BUTTON.instantiate()
		button.find_child('Action').text = str(editable_keybinds[action])
		if device == 'keyboard':
			button.find_child('Input').text = InputHelper.get_label_for_input(InputHelper.get_keyboard_input_for_action(action)) 
		elif ["xbox", "switch", "switch_left_joycon", "switch_right_joycon", "playstation", "steamdeck"].has(device):
			button.find_child('Input').text = InputHelper.get_label_for_input(InputHelper.get_joypad_input_for_action(action)) 
			if action.contains('move'): button.disabled = true
		keybind_container.add_child(button)
		button.pressed.connect(
			func():
				Input.action_release("ui_accept")
				button.release_focus()
				rebinding_action = action
				await get_tree().process_frame
				is_rebinding = true
				button.find_child('Input').text = 'Awaiting input...'
				await done_rebinding
				await loadKeybinds(InputHelper.device)
				OverworldGlobals.setMenuFocus(keybind_container)
				apply_button.show()
				)
	
	await get_tree().process_frame
	settings['binds'] = InputHelper.serialize_inputs_for_actions()

func _unhandled_input(event) -> void:
	if is_rebinding:
		if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
			var current_action = InputHelper.get_keyboard_input_for_action(rebinding_action)
			accept_event()
			InputHelper.replace_keyboard_input_for_action(rebinding_action, current_action, event)
		if event is InputEventJoypadButton and event.is_pressed():
			var current_action = InputHelper.get_joypad_input_for_action(rebinding_action)
			accept_event()
			InputHelper.replace_joypad_input_for_action(rebinding_action, current_action, event)
		is_rebinding = false
		done_rebinding.emit()
	else:
		if Input.is_action_just_pressed('ui_tab_right') and tabs.current_tab + 1 < tabs.get_tab_count():
			tabs.current_tab += 1
		elif Input.is_action_just_pressed('ui_tab_left') and tabs.current_tab - 1 >= 0:
			tabs.current_tab -= 1

func saveSettings():
	var saved_settings = SavedSettings.new()
	saved_settings.window_mode = settings['window_mode']
	saved_settings.resolution = settings['resolution']
	saved_settings.fps_cap = settings['fps_cap']
	saved_settings.vsync = settings['vsync']
	saved_settings.master_vol = settings['master_vol']
	saved_settings.music_vol = settings['music_vol']
	saved_settings.sound_vol = settings['sound_vol']
	saved_settings.toggle_sprint = settings['toggle_sprint']
	saved_settings.toggle_cheats = settings['toggle_cheats']
	saved_settings.binds = settings['binds']
	ResourceSaver.save(saved_settings, "saved_settings.tres")

func loadSettings(saved_settings: SavedSettings, apply:bool=true):
	await get_tree().process_frame
	settings['window_mode'] = saved_settings.window_mode
	settings['resolution'] = saved_settings.resolution
	settings['fps_cap'] = saved_settings.fps_cap
	settings['vsync'] = saved_settings.vsync
	settings['master_vol'] = saved_settings.master_vol
	settings['music_vol'] = saved_settings.music_vol
	settings['sound_vol'] = saved_settings.sound_vol
	settings['toggle_sprint'] = saved_settings.toggle_sprint
	settings['toggle_cheats'] = saved_settings.toggle_cheats
	settings['binds'] = saved_settings.binds
	window_options.selected = saved_settings.window_mode
	resolution_options.selected = saved_settings.resolution
	fps_slider.value = saved_settings.fps_cap
	vsync_toggle.button_pressed = saved_settings.vsync
	master_slider.value = saved_settings.master_vol
	music_slider.value = saved_settings.music_vol
	sounds_slider.value = saved_settings.sound_vol
	sprint_toggle.button_pressed = saved_settings.toggle_sprint
	cheat_toggle.button_pressed = saved_settings.toggle_cheats
	InputHelper.deserialize_inputs_for_actions(settings['binds'])
	loadKeybinds(InputHelper.device)
	if apply:
		_on_apply_settings_pressed()

func _on_apply_settings_pressed():
	match SettingsGlobals.window_modes[settings['window_mode']]:
		'Borderless Windowed':
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		'Windowed':
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		'Fullscreen':
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	if SettingsGlobals.window_modes[settings['window_mode']] != 'Fullscreen':
		get_viewport().size = SettingsGlobals.resolutions.values()[settings['resolution']]
	if settings['fps_cap'] >= 120:
		Engine.max_fps = 0
	else:
		Engine.max_fps = settings['fps_cap']
	if settings['vsync']:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), linear_to_db(settings['master_vol']))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear_to_db(settings['music_vol']))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear_to_db(settings['sound_vol']))
	SettingsGlobals.toggle_sprint = settings['toggle_sprint']
	SettingsGlobals.cheat_mode = settings['toggle_cheats']
	saveSettings()
	apply_button.hide()

func _on_default_settings_pressed():
	loadSettings(DEFAULT_SETTINGS)

func _on_panel_container_tab_changed(tab):
	await get_tree().process_frame
	match tab:
		0:
			window_options.grab_focus()
		1: 
			OverworldGlobals.setMenuFocus(keybind_container)

func addSound(ui_element: Control):
	ui_element.focus_entered.connect(playFocusSound)
	ui_element.mouse_entered.connect(playFocusSound)
	if ui_element is CheckBox:
		ui_element.toggled.connect(playClickSound)
	elif ui_element is OptionButton:
		ui_element.item_focused.connect(playFocusSoundWithVal)
		ui_element.item_selected.connect(playClickSound)
	elif ui_element is Slider:
		ui_element.value_changed.connect(playSlideSound)

func playFocusSound():
	ui_hover_sounds.pitch_scale = 1.0 + randf_range(-0.1, 0.1)
	ui_hover_sounds.stop()
	ui_hover_sounds.play()

func playFocusSoundWithVal(_val):
	ui_hover_sounds.pitch_scale = 1.0 + randf_range(-0.1, 0.1)
	ui_hover_sounds.stop()
	ui_hover_sounds.play()

func playClickSound(_val):
	ui_click_sounds.pitch_scale = 1.0 + randf_range(-0.1, 0.1)
	ui_click_sounds.stop()
	ui_click_sounds.play()

func playSlideSound(_val):
	ui_slide_sounds.stop()
	ui_slide_sounds.play()

func _on_swap_device_pressed():
	loadKeybinds(InputHelper.device)
