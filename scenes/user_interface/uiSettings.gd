extends Control

@onready var fps = $PanelContainer/Display/VBoxContainer/FPSCap/Label/FPS
@onready var tabs = $PanelContainer
@onready var fps_slider = $PanelContainer/Display/VBoxContainer/FPSCap/Option
@onready var master_slider = $PanelContainer/Sounds/VBoxContainer2/Master/Option
@onready var music_slider = $PanelContainer/Sounds/VBoxContainer2/MusicSlider/Option
@onready var sounds_slider = $PanelContainer/Sounds/VBoxContainer2/SoundSlider/Option

@onready var resolution_options = $PanelContainer/Display/VBoxContainer/Resolution/Option
#var resolutions: Dictionary = {
#	'3840x2160': Vector2i(3840,2160),
#	'2560x1440': Vector2i(2560,1440),
#	'1920x1080': Vector2i(1920,1080),
#	'1152x648': Vector2i(1152,648),
#	'1280x720': Vector2i(1280,720),
#	'854x480': Vector2i(854,480)
#}

func _process(_delta):
	if fps != null:
		if fps_slider.value >= 120:
			fps.text = 'UNLIMITED'
		else:
			fps.text = str(fps_slider.value)
	
func _ready():
#	for resolution in resolutions:
#		resolution_options.add_item(resolution)
	
	master_slider.value  = db_to_linear(AudioServer.get_bus_volume_db(master_slider.value))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_slider.value))
	sounds_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sounds_slider.value))
	
#	resolution_options.item_selected.connect(changeResolution)
	master_slider.value_changed.connect(changeMasterVolume)
	music_slider.value_changed.connect(changeMusicVolume)
	sounds_slider.value_changed.connect(changeSoundsVolume)

# DISPLAY SETTINGS
#func changeResolution(index: int):
#	get_viewport().size = resolutions[resolution_options.get_item_text(index)]

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
