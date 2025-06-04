extends ProgressBar
class_name PatrollerDetectBar

@onready var patrol_component: NPCPatrolMovement
var detect_timer: Timer

func initialize():
	patrol_component = get_parent()
	max_value = patrol_component.DETECTION_TIME
	detect_timer = patrol_component.DETECT_TIMER

func _process(_delta):
	if detect_timer == null:
		return
	
	if !detect_timer.is_stopped():
		show()
	else:
		hide()
	if patrol_component.STATE == 0 or patrol_component.STATE == 1:
		value = detect_timer.time_left
	
