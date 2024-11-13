extends Node2D

@onready var animator = $PatrolBubble/AnimationPlayer

func _ready():
	print('Playing!')
	animator.play("Show")
	await animator.animation_finished
	queue_free()
