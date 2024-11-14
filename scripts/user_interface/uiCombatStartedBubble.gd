extends Node2D

@export var animation = 'Show'
@onready var animator = $PatrolBubble/AnimationPlayer

func _ready():
	if get_parent().has_node('NPCPatrolComponent'):
		get_parent().get_node('NPCPatrolComponent').hide()
	animator.play(animation)
	await animator.animation_finished
	#queue_free()

func _exit_tree():
	if get_parent().has_node('NPCPatrolComponent'):
		get_parent().get_node('NPCPatrolComponent').show()
