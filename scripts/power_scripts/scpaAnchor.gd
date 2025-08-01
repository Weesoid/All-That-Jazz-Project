extends Node2D
class_name PowerAttachment

@onready var animator = $AnimationPlayer

func _ready():
	animator.play("Spawn")

#func _unhandled_input(_event):
#	if Input.is_action_just_released("ui_gambit") and OverworldGlobals.player.POWER_INPUT == 'sss':
#		if PlayerGlobals.overworld_stats['stamina']>= 25.0 and !OverworldGlobals.inMenu() and !OverworldGlobals.player.hiding:
#			OverworldGlobals.player.playCastAnimation()
#			PlayerGlobals.overworld_stats['stamina']-= 25
#			OverworldGlobals.player.global_position = global_position
#			OverworldGlobals.addPatrollerPulse(OverworldGlobals.player, 80.0, 3)
#			queue_free()
#		else:
#			OverworldGlobals.player.prompt.('Not enough [color=yellow]stamina[/color].')
