extends Node2D
class_name PowerAttachment

@onready var player = OverworldGlobals.getPlayer()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_gambit"):
		if player.stamina >= 25.0:
			player.stamina -= 25
			player.global_position = global_position
			queue_free()
		else:
			player.prompt.showPrompt('Not enough [color=yellow]stamina[/color].')
	
