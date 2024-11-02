extends Node2D
class_name PowerAttachment

@onready var player = OverworldGlobals.getPlayer()
@onready var animator = $AnimationPlayer

func _ready():
	animator.play("Spawn")

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_gambit"):
		if PlayerGlobals.overworld_stats['stamina']>= 25.0 and !OverworldGlobals.inMenu() and !player.hiding:
			player.playCastAnimation()
			PlayerGlobals.overworld_stats['stamina']-= 25
			player.global_position = global_position
			OverworldGlobals.addPatrollerPulse(player, 80.0, 3)
			queue_free()
		else:
			player.prompt.showPrompt('Not enough [color=yellow]stamina[/color].')
