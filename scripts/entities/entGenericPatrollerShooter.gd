extends GenericPatroller
class_name GenericPatrollerShooter

@export var projectile: ResProjectile
@export var shoot_distance: float = 0.0

func _ready():
	patrol_component.COMBAT_SQUAD = get_node('CombatantSquadComponent')
	print(name)
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
	if shoot_distance != 0:
		patrol_component.SHOOT_DISTANCE = shoot_distance
	if idle_time['patrol'] > 0.0 and idle_time['alerted_patrol'] > 0.0:
		patrol_component.IDLE_TIME = idle_time
	if stun_time['min'] > 0.0 and stun_time['max'] > 0.0:
		patrol_component.STUN_TIME = stun_time
	
	patrol_component.initialize()
