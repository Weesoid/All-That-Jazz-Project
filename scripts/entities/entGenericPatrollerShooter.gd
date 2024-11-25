extends GenericPatroller
class_name GenericPatrollerShooter

@export var projectile: ResEnemyProjectile

func _ready():
	print(projectile)
	patrol_component.COMBAT_SQUAD = get_node('CombatantSquadComponent')
	patrol_component.PATROL_AREA = patrol_area
	patrol_component.PROJECTILE = projectile
	
	if base_move_speed != 0:
		patrol_component.BASE_MOVE_SPEED = base_move_speed
	if alerted_speed_multiplier != 0:
		patrol_component.ALERTED_SPEED_MULTIPLIER = alerted_speed_multiplier
	if chase_speed_multiplier != 0:
		patrol_component.CHASE_SPEED_MULTIPLIER = chase_speed_multiplier
	if detection_time != 0:
		patrol_component.DETECTION_TIME = detection_time
	if alerted_speed_multiplier != 0:
		patrol_component.ALERTED_SPEED_MULTIPLIER = alerted_speed_multiplier
	if chase_speed_multiplier != 0:
		patrol_component.CHASE_SPEED_MULTIPLIER = chase_speed_multiplier
	
	patrol_component.initialize()
