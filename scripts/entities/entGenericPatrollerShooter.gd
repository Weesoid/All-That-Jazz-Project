extends GenericPatroller
class_name GenericPatrollerShooter

@export var projectile: PackedScene

func _ready():
	patrol_component.COMBAT_SQUAD = get_node('CombatantSquadComponent')
	patrol_component.PATROL_AREA = patrol_area
	patrol_component.PROJECTILE = projectile
	
	if alerted_speed_multiplier != 0:
		patrol_component.ALERTED_SPEED_MULTIPLIER = alerted_speed_multiplier
	if chase_speed_multiplier != 0:
		patrol_component.CHASE_SPEED_MULTIPLIER = chase_speed_multiplier
	
	patrol_component.initialize()
