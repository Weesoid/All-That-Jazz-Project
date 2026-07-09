extends Node

const CONTROLLER_DEVICES = ["xbox", "switch", "switch_left_joycon", "switch_right_joycon", "playstation", "steamdeck", "generic"]

var window_modes: Array[String] = ['Fullscreen', 'Borderless Windowed', 'Windowed']
var resolutions: Dictionary = {
	'1280x720': Vector2i(1280,720),
	'1920x1080': Vector2i(1920,1080),
	'2560x1440': Vector2i(2560,1440),
	'3840x2160': Vector2i(3840,2160)
}
var toggle_sprint = true
var cheat_mode = true
var ui_colors: Dictionary = {
	'up': Color.GOLD,
	'down': Color.STEEL_BLUE,
	'special':Color.TURQUOISE,
	'unique':Color.ORANGE,
	'up-bb': '[color=GOLD]',
	'down-bb': '[color=STEEL_BLUE]',
	'special-bb':'[color=TURQUOISE]',
	'unique-bb':'[color=ORANGE]',
	'up-bb-nobracket': 'color=GOLD',
	'down-bb-nobracket': 'color=STEEL_BLUE',
	'special-bb-nobracket':'color=TURQUOISE',
	'unique-bb-nobracket':'color=ORANGE'
}
var bb_line:String = '\n[color=transparent]a[/color][img]res://images/user_interface/bb_line.png[/img][color=transparent]a[/color]\n'
signal keybind_updated(action, new_bind)
signal keybind_pressed(action)

func colorImgBB(ui_color:String):
	return '[img '+ui_colors[ui_color].replace('[','').replace(']','')+']'

func colorValueBB(value, control_value)-> String:
	if value > control_value:
		return ui_colors['up-bb']+str(value)
	elif value < control_value:
		return ui_colors['down-bb']+str(value)
	else:
		return '[color=white]'+str(value)

func applySettings(settings_data: SavedSettings):
	#InputHelper.deserialize_inputs_for_actions(settings_data.binds)
	match window_modes[settings_data.window_mode]:
		'Borderless Windowed':
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		'Windowed':
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		'Fullscreen':
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	if window_modes[settings_data.window_mode] != 'Fullscreen':
		get_viewport().size = resolutions.values()[settings_data.resolution]
	Engine.max_fps = settings_data.fps_cap
	if settings_data.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Master'), linear_to_db(settings_data.master_vol))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'), linear_to_db(settings_data.music_vol))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Sounds'), linear_to_db(settings_data.sound_vol))
	SettingsGlobals.toggle_sprint = settings_data.toggle_sprint
	SettingsGlobals.cheat_mode = settings_data.toggle_cheats

func doSprint()-> bool:
	return (Input.is_action_pressed("ui_sprint") and !SettingsGlobals.toggle_sprint) or (Input.is_action_just_pressed("ui_sprint") and SettingsGlobals.toggle_sprint) and !OverworldGlobals.player.sprinting

func stopSprint()-> bool:
	return (Input.is_action_just_released("ui_sprint") and !SettingsGlobals.toggle_sprint) or (Input.is_action_just_pressed("ui_sprint") and SettingsGlobals.toggle_sprint) and OverworldGlobals.player.sprinting

func longhandWord(word:String):
	word = word.replace('_', ' ')
	word = word.to_lower()
	var word_split = word.split(' ')
	for i in range(word_split.size()):
		match word_split[i]:
			'dmg': word_split.set(i, 'damage')
			'amp': word_split.set(i, 'amp.')
	
	return " ".join(word_split)

func click():
	var a = InputEventMouseButton.new()
	a.position = get_viewport().get_screen_transform() * get_viewport().get_mouse_position()
	a.button_index = MOUSE_BUTTON_LEFT
	a.pressed = true
	Input.parse_input_event(a)
	await get_tree().process_frame
	a.pressed = false
	Input.parse_input_event(a)
