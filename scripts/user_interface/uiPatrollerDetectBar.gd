extends ProgressBar
class_name PatrollerDetectBar

@onready var patroller: GenericPatroller
@onready var detect_audio = $AudioStreamPlayer2D
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
		if !detect_audio.playing: 
			detect_audio.play()
		if detect_audio.playing and detect_audio.volume_db < 30.0: 
			detect_audio.volume_db += 1.0
		show()
	else:
		if detect_audio.playing: 
			detect_audio.stop()
			detect_audio.volume_db = 0.0
		hide()
	if patroller.state == GenericPatroller.State.IDLE:
		value = detect_timer.time_left
