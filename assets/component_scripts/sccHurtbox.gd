extends Node

@export var BODY: CharacterBody2D
@export var BODY_ANIMATOR: AnimationPlayer

func destroy():
	# Find a better way to disable nodes that are using the body
	BODY.remove_child(BODY.get_node('NPCPatrolComponent'))
	BODY_ANIMATOR.play('KO')
	await BODY_ANIMATOR.animation_finished
	BODY.queue_free()

