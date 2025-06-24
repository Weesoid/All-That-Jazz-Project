extends ProgressBar
class_name PatrollerDetectBar

@onready var patroller: GenericPatroller
var detect_timer: Timer

func _ready():
	detect_timer = get_parent().get_node('DetectTimer')
	max_value = detect_timer.wait_time
	patroller = get_parent()
	#detect_timer = patrol_component.DETECT_TIMER

func _process(_delta):
	if detect_timer == null:
		return
	
	if !detect_timer.is_stopped():
		show()
	else:
		hide()
	if patroller.state == 0:
		value = detect_timer.time_left
