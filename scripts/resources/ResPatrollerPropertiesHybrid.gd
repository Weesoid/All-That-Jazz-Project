extends ResPatrollerPropertiesShooter
class_name ResPatrollerPropertiesHybrid

@export var min_melee_action_distance: float = 25.0

func setExtendedProperties(patroller):
	patroller.projectile = projectile
	patroller.min_melee_action_distance = min_melee_action_distance
