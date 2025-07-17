extends Resource
class_name ResPatrollerProperties

@export var sprite: Texture
@export var base_move_speed: float = 20.0
@export var alerted_speed_multiplier: float = 5.0
@export var chase_speed_multiplier: float = 13.0
@export var min_action_distance: float = 25
@export_enum('Left:-1','Right:1') var direction: int = -1
@export var detection_time: float
@export var action_cooldown_time: float
@export var stun_time: float
@export var hurt_script: GDScript

func setPatrollerProperties(patroller: GenericPatroller):
	patroller.base_move_speed = base_move_speed
	patroller.alerted_speed_multiplier = alerted_speed_multiplier
	patroller.chase_speed_multiplier = chase_speed_multiplier
	patroller.min_action_distance = min_action_distance
	patroller.direction = direction
	if action_cooldown_time > 0:
		patroller.action_cooldown_time = action_cooldown_time
	if detection_time > 0:
		patroller.detection_time = detection_time
	if stun_time > 0:
		patroller.stun_time = stun_time
	if hurt_script != null:
		var hurt_box = load("res://scenes/components/Hurtbox.tscn").instantiate()
		hurt_box.HIT_SCRIPT = hurt_script
		patroller.add_child(hurt_box)
	setExtendedProperties(patroller)
	patroller.get_node('Sprite2D').texture = sprite

func setExtendedProperties(patroller):
	pass

func getType():
	if self is ResPatrollerPropertiesHybrid:
		return 2
	elif self is ResPatrollerPropertiesShooter: 
		return 1
	elif self is ResPatrollerProperties: 
		return 0
