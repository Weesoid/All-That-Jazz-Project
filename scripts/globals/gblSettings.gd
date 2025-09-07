extends Node

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
	'unique-bb':'[color=ORANGE]'
}
var bb_line:String = '\n[color=transparent]a[/color][img]res://images/sprites/bb_line.png[/img][color=transparent]a[/color]\n'

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
	InputHelper.deserialize_inputs_for_actions(settings_data.binds)
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
