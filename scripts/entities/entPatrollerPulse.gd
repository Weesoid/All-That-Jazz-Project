extends Area2D

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var sprite = $Sprite2D
var mode: int
var radius: float
var trigger_others=false

func _ready():
	shape.shape.radius = radius

func _process(_delta):
	if has_overlapping_bodies():
		updatePatrollers()

func updatePatrollers():
#	var color: Color
#	match mode:
#		0: color=Color.DARK_GRAY
#		1: color=Color.ORANGE
#		2: color=Color.RED
#		3: color=Color.WHITE
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
	
	var calculated_scale = (0.00450612244898*radius)+0.000938775510204
	var scale_tween = get_tree().create_tween()
	var opacity_tween = get_tree().create_tween()
	scale_tween.tween_property(sprite, 'scale', Vector2(calculated_scale, calculated_scale), 0.25)
	opacity_tween.tween_property(sprite, 'modulate', Color(Color.RED,0.0), 0.25)
	await get_tree().create_timer(0.5).timeout
	queue_free()
