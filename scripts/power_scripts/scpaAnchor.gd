extends Node2D
class_name PowerAttachment

var PLAYER: PlayerScene

func _ready():
	PLAYER = OverworldGlobals.getPlayer()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_gambit"):
		PLAYER.global_position = global_position
		queue_free()
	
