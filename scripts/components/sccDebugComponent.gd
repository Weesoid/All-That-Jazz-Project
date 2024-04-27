extends Node2D

@onready var coordinates = $Coordinates

func _process(_delta):
	coordinates.text = str(get_parent().global_position)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_quick_save"):
		SaveLoadGlobals.saveGame()
	elif Input.is_action_just_pressed("ui_quick_load"):
		SaveLoadGlobals.loadGame()
