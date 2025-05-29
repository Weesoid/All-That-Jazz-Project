extends ProgressBar

@onready var block_timer = $BlockTimer

func _ready():
	max_value = block_timer.wait_time

func _physics_process(_delta):
	if block_timer.time_left > 0 and !block_timer.is_stopped():
		value = block_timer.time_left
		show()
	else:
		hide()
