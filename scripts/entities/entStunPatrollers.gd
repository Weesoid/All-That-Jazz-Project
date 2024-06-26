extends Area2D

@onready var animator = $Sprite2D/AnimationPlayer
@onready var shape: CollisionShape2D = $CollisionShape2D
var mode: int
var radius: float

func _ready():
	shape.shape.radius = radius

func _process(_delta):
	if has_overlapping_bodies():
		stunPatrollers()

func stunPatrollers():
	for body in get_overlapping_bodies():
		if body.has_node('NPCPatrolComponent'): 
			var current_state = body.get_node('NPCPatrolComponent').STATE
			if mode == current_state:
				continue
			elif mode == 0 and current_state == 3:
				continue
			elif mode == 1 and (current_state == 2 or current_state == 3):
				continue
			
			body.get_node('NPCPatrolComponent').updateMode(mode)
	
	animator.play("Show")
	await animator.animation_finished
	queue_free()
