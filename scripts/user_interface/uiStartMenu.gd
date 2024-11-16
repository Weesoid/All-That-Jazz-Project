extends Node2D

@onready var camera = $Camera2D
@onready var new_game = $VBoxContainer/NewGame
@onready var load_game = $VBoxContainer/LoadGame
@onready var animator = $AnimationPlayer
@onready var music = $AudioStreamPlayer

func _ready():
	InventoryGlobals.resetVariables()
	OverworldGlobals.resetVariables()
	PlayerGlobals.resetVariables()
	QuestGlobals.resetVariables()
	SaveLoadGlobals.resetVariables()
	
	new_game.grab_focus()
	music.play()
	animator.play("Show")
	load_game.disabled = !hasSaves()

func _on_new_game_pressed():
	var menu = load("res://scenes/user_interface/Saves.tscn").instantiate()
	menu.mode = menu.Modes.NEW_GAME
	addMenu(menu)

func _on_load_game_pressed():
	var menu = load("res://scenes/user_interface/Saves.tscn").instantiate()
	menu.mode = menu.Modes.LOAD
	addMenu(menu)

func _on_settings_pressed():
	pass # Replace with function body.

func _on_quit_pressed():
	get_tree().quit()

func addMenu(menu: Control):
	menu.name = 'uiMenu'
	camera.add_child(menu)

func hasSaves()-> bool:
	var path = "res://saves/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			return true
	
	return false

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_show_menu") and camera.has_node('uiMenu'):
		camera.get_node('uiMenu').queue_free()
		new_game.grab_focus()
		load_game.disabled = !hasSaves()

func _on_audio_stream_player_finished():
	animator.play("RESET")
