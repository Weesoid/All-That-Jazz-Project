extends Node2D

@onready var coordinates = $VBoxContainer/Coordinates
@onready var playtime_info = $VBoxContainer/PlaytimeInfo
@onready var equipped_charm = $VBoxContainer/EquippedCharm
var clipboard = DisplayServer.clipboard_get()

func _process(_delta):
	coordinates.text = str(get_parent().global_position)+','+str(int(get_parent().player_direction.rotation_degrees))
	playtime_info.text = Time.get_time_string_from_unix_time(SaveLoadGlobals.current_playtime)
	if PlayerGlobals.hasUtilityCharm():
		equipped_charm.text = PlayerGlobals.EQUIPPED_CHARM.NAME
	else:
		equipped_charm.text = 'No charm.'
	
func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_quick_save"):
		SaveLoadGlobals.saveGame()
	elif Input.is_action_just_pressed("ui_quick_load"):
		SaveLoadGlobals.loadGame(load("res://saves/Save 0.tres"))
	elif Input.is_action_just_pressed("ui_debug_copy_coords"):
		var copied = coordinates.text.replace('(','').replace(')','')
		OverworldGlobals.showPlayerPrompt('Copied coordinates to clipboard! [color=yellow]%s[/color]' % copied)
		DisplayServer.clipboard_set(copied)
