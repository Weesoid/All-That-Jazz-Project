extends ProgressBar

@export var timer: Timer
@export var color: Color

func _ready():
	# check for queue conditions
	modulate=color

func _process(_delta):
	if !timer.is_stopped():
		show()
		max_value = timer.wait_time
		value = (timer.wait_time-timer.time_left)
	else:
		hide()
