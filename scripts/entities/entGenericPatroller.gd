extends CharacterBody2D
class_name GenericPatroller

@export var patrol_area: Area2D
@export var alerted_speed_multiplier: float
@export var chase_speed_multiplier: float

@onready var patrol_component: NPCPatrolMovement = $NPCPatrolComponent

func _ready():
	#add_child(combatant_squad)
	patrol_component.COMBAT_SQUAD = get_node('CombatantSquadComponent')
	patrol_component.PATROL_AREA = patrol_area
	
	if alerted_speed_multiplier != 0:
		patrol_component.ALERTED_SPEED_MULTIPLIER = alerted_speed_multiplier
	if chase_speed_multiplier != 0:
		patrol_component.CHASE_SPEED_MULTIPLIER = chase_speed_multiplier
	
	patrol_component.initialize()
