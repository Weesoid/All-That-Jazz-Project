extends Node2D
class_name AbilityAnimation

@onready var animator = $AnimationPlayer

func playNow():
	animator.play('Execute')
	await animator.animation_finished
	queue_free()

func playAnimation(pos: Vector2):
	position = pos
	if get_parent() is CharacterBody2D:
		rotation_degrees = get_parent().rotation_degrees
	animator.play('Execute')
	await animator.animation_finished
	queue_free()
