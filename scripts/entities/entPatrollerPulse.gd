extends Area2D

@onready var shape: CollisionShape2D = $CollisionShape2D
var mode: int
var radius: float
var trigger_others=false

func _ready():
	shape.shape.radius = radius

func _process(_delta):
	if has_overlapping_bodies():
		updatePatrollers()

func updatePatrollers():
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
	
#	PULSE VISUALS!
	var pulse_anim = preload("res://scenes/entities_disposable/Pulse.tscn").instantiate()
	pulse_anim.global_position = global_position
	OverworldGlobals.getCurrentMap().add_child(pulse_anim)
	pulse_anim.showAnimation(radius)
	queue_free()
