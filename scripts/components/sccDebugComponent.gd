extends Node2D

@onready var player = OverworldGlobals.getPlayer()

@onready var container = $VBoxContainer
@onready var fps = $VBoxContainer/FPS
@onready var coordinates = $VBoxContainer/Coordinates
@onready var playtime_info = $VBoxContainer/PlaytimeInfo
@onready var equipped_charm = $VBoxContainer/EquippedCharm
@onready var reward_bank = $VBoxContainer/RewardBank
@onready var save_name = $VBoxContainer/SaveName
@onready var speed = $VBoxContainer/Speed
var clipboard = DisplayServer.clipboard_get()

func _ready():
	container.hide()

func _process(_delta):
	fps.text = str(Engine.get_frames_per_second())
	coordinates.text = str(get_parent().global_position)+','+str(int(get_parent().player_direction.rotation_degrees))
	playtime_info.text = Time.get_time_string_from_unix_time(int(SaveLoadGlobals.current_playtime))
	if PlayerGlobals.equipped_blessing != null:
		equipped_charm.text = PlayerGlobals.equipped_blessing.blessing_name
	else:
		equipped_charm.text = 'No active blessing.'
	#reward_bank.text = str(OverworldGlobals.getCurrentMap().REWARD_BANK)
	save_name.text = 'Save Name: ' + str(PlayerGlobals.save_name)
	speed.text = 'Speed: ' + str(player.SPEED)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_toggle_debug"):
		container.visible = !container.visible
	#	print_orphan_nodes()
	
	if Input.is_action_just_pressed("ui_quick_save"):
		SaveLoadGlobals.saveGame(PlayerGlobals.save_name)
	elif Input.is_action_just_pressed("ui_quick_load"):
		SaveLoadGlobals.loadGame(load("res://saves/%s.tres") % PlayerGlobals.save_name)
	elif Input.is_action_just_pressed("ui_debug_copy_coords"):
		var copied = coordinates.text.replace('(','').replace(')','').replace(' ','')
		OverworldGlobals.showPrompt('Copied coordinates to clipboard! [color=yellow]%s[/color]' % copied)
		DisplayServer.clipboard_set(copied)
