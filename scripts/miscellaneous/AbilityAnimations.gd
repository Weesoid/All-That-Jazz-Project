extends Node2D
class_name AbilityAnimation

@onready var animator = $AnimationPlayer

func playAnimation(pos: Vector2):
	position = pos
	$AnimationPlayer.play('Execute')
	await $AnimationPlayer.animation_finished
	queue_free()
