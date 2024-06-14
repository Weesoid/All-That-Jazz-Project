extends Node2D

@onready var coordinates = $VBoxContainer/Coordinates
@onready var equipped_charm = $VBoxContainer/EquippedCharm

func _process(_delta):
	coordinates.text = str(get_parent().global_position)
	if PlayerGlobals.hasUtilityCharm():
		equipped_charm.text = PlayerGlobals.EQUIPPED_CHARM.NAME
	else:
		equipped_charm.text = 'No charm.'

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_quick_save"):
		SaveLoadGlobals.saveGame()
	elif Input.is_action_just_pressed("ui_quick_load"):
		SaveLoadGlobals.loadGame(load("res://saves/Save 0.tres"))
