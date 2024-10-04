extends Node2D
class_name AbilityAnimation

@onready var animator = $AnimationPlayer

func playAnimation(pos: Vector2):
	position = pos
	animator.play('Execute')
	await animator.animation_finished
	queue_free()
