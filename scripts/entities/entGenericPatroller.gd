extends CharacterBody2D
class_name GenericPatroller

@export var patrol_area: Area2D
@export var base_move_speed: float
@export var alerted_speed_multiplier: float
@export var chase_speed_multiplier: float
@export var detection_time: float
@export var idle_time: Dictionary = {'patrol':0.0, 'alerted_patrol':0.0}
@export var stun_time: Dictionary = {'min':0.0, 'max':0.0}


@onready var patrol_component: NPCPatrolMovement = $NPCPatrolComponent

func _ready():
	patrol_component.COMBAT_SQUAD = get_node('CombatantSquadComponent')
	patrol_component.PATROL_AREA = patrol_area
	
	if base_move_speed != 0:
		patrol_component.BASE_MOVE_SPEED = base_move_speed
	if alerted_speed_multiplier != 0:
		patrol_component.ALERTED_SPEED_MULTIPLIER = alerted_speed_multiplier
	if chase_speed_multiplier != 0:
		patrol_component.CHASE_SPEED_MULTIPLIER = chase_speed_multiplier
	if detection_time != 0:
		patrol_component.DETECTION_TIME = detection_time
	if idle_time['patrol'] > 0.0 and idle_time['alerted_patrol'] > 0.0:
		patrol_component.IDLE_TIME = idle_time
	if stun_time['min'] > 0.0 and stun_time['max'] > 0.0:
		patrol_component.STUN_TIME = stun_time
	
	patrol_component.initialize()
