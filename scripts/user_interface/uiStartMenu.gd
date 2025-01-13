extends Node2D

@onready var camera = $Camera2D
@onready var new_game = $VBoxContainer/NewGame
@onready var load_game = $VBoxContainer/LoadGame
@onready var animator = $AnimationPlayer
@onready var transition_animator = $TransitionMatte/AnimationPlayer
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
	await get_tree().create_timer(0.15).timeout # Placeholder
	if FileAccess.file_exists('saved_settings.tres'):
		SettingsGlobals.applySettings(load('saved_settings.tres'))
	else:
		SettingsGlobals.applySettings(load('default_settings.tres'))

func _on_new_game_pressed():
	var menu = load("res://scenes/user_interface/Saves.tscn").instantiate()
	menu.mode = menu.Modes.NEW_GAME
	addMenu(menu)

func _on_load_game_pressed():
	var menu = load("res://scenes/user_interface/Saves.tscn").instantiate()
	menu.mode = menu.Modes.LOAD
	addMenu(menu)

func _on_settings_pressed():
	var menu = load("res://scenes/user_interface/Settings.tscn").instantiate()
	addMenu(menu)

func _on_quit_pressed():
	get_tree().quit()

func addMenu(menu: Control):
	menu.name = 'uiMenu'
	transition_animator.play("Slide_In")
	await transition_animator.animation_finished
	camera.add_child(menu)
	transition_animator.play("Slide_Out")

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
		transition_animator.play("Slide_In")
		await transition_animator.animation_finished
		camera.get_node('uiMenu').queue_free()
		new_game.grab_focus()
		load_game.disabled = !hasSaves()
		transition_animator.play("Slide_Out")
	if Input.is_action_just_pressed("ui_cancel") and camera.has_node('uiMenu'):
		transition_animator.play("Slide_In")
		await transition_animator.animation_finished
		camera.get_node('uiMenu').queue_free()
		new_game.grab_focus()
		transition_animator.play("Slide_Out")

func _on_audio_stream_player_finished():
	animator.play("RESET")
