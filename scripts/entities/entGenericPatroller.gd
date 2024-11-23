extends CharacterBody2D
class_name GenericPatroller

@export var patrol_area: Area2D
@export var base_move_speed: float
@export var alerted_speed_multiplier: float
@export var chase_speed_multiplier: float
@export var detection_time: float

@onready var patrol_component: NPCPatrolMovement = $NPCPatrolComponent

func _ready():
	#add_child(combatant_squad)
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
	
	patrol_component.initialize()
