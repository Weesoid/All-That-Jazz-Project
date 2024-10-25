extends Node2D

@onready var coordinates = $VBoxContainer/Coordinates
@onready var playtime_info = $VBoxContainer/PlaytimeInfo
@onready var equipped_charm = $VBoxContainer/EquippedCharm
@onready var dogpile = $VBoxContainer/Dogpile
@onready var reward_bank = $VBoxContainer/RewardBank

var clipboard = DisplayServer.clipboard_get()

func _process(_delta):
	coordinates.text = str(get_parent().global_position)+','+str(int(get_parent().player_direction.rotation_degrees))
	playtime_info.text = Time.get_time_string_from_unix_time(int(SaveLoadGlobals.current_playtime))
	dogpile.text = 'x%s (%s)' % [OverworldGlobals.dogpile, snappedf(OverworldGlobals.dogpile_timer.time_left, 0.1)]
	if PlayerGlobals.EQUIPPED_BLESSING != null:
		equipped_charm.text = PlayerGlobals.EQUIPPED_BLESSING.blessing_name
	else:
		equipped_charm.text = 'No active blessing.'
	reward_bank.text = str(OverworldGlobals.getCurrentMap().REWARD_BANK)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_quick_save"):
		SaveLoadGlobals.saveGame('Save Debug')
	elif Input.is_action_just_pressed("ui_quick_load"):
		SaveLoadGlobals.loadGame(load("res://saves/Save Debug.tres"))
	elif Input.is_action_just_pressed("ui_debug_copy_coords"):
		var copied = coordinates.text.replace('(','').replace(')','')
		OverworldGlobals.showPlayerPrompt('Copied coordinates to clipboard! [color=yellow]%s[/color]' % copied)
		DisplayServer.clipboard_set(copied)
