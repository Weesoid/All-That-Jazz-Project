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
			
			if mode == 4:
				if current_state == 0:
					body.get_node('NPCPatrolComponent').updateMode(1)
				elif current_state == 1:
					body.get_node('NPCPatrolComponent').updateMode(2)
			else:
				body.get_node('NPCPatrolComponent').updateMode(mode)
	
#	PULSE VISUALS!
	var pulse_anim = preload("res://scenes/entities_disposable/Pulse.tscn").instantiate()
	var color: Color
	match mode:
		1: color = Color.WHITE
		2: color = Color.DARK_ORANGE
		3: color = Color.SANDY_BROWN
		4: color = Color.RED
	pulse_anim.global_position = global_position
	OverworldGlobals.getCurrentMap().add_child(pulse_anim)
	pulse_anim.showAnimation(radius, 0.4,color)
	queue_free()
