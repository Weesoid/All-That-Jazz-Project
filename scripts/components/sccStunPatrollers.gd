extends Area2D

@onready var animator = $Sprite2D/AnimationPlayer

func _process(_delta):
	if has_overlapping_bodies():
		stunPatrollers()

func stunPatrollers():
	for body in get_overlapping_bodies():
		if body.has_node('NPCPatrolComponent') and body.get_node('NPCPatrolComponent').STATE != 3: 
			body.get_node('NPCPatrolComponent').stunMode()
	animator.play("Show")
	await animator.animation_finished
	queue_free()
