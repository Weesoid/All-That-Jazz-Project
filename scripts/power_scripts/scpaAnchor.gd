extends Node2D
class_name PowerAttachment

@onready var player = OverworldGlobals.getPlayer()
@onready var animator = $AnimationPlayer

func _ready():
	animator.play("Spawn")

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_gambit"):
		if PlayerGlobals.stamina >= 25.0:
			player.playCastAnimation()
			var stun = preload("res://scenes/components/StunPatrollers.tscn").instantiate()
			PlayerGlobals.stamina -= 25
			stun.global_position = global_position
			player.global_position = global_position
			get_parent().add_child(stun)
			queue_free()
		else:
			player.prompt.showPrompt('Not enough [color=yellow]stamina[/color].')
