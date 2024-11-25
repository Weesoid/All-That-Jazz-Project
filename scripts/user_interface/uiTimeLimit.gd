extends Node2D

@onready var label = $Label
@onready var bar = $ProgressBar
var timer: Timer

func _ready():
	bar.max_value = OverworldGlobals.getCurrentMap().EVENTS['time_limit']
	timer = OverworldGlobals.getCurrentMap().clear_timer
	timer.timeout.connect(queue_free)
	OverworldGlobals.getCurrentMap().map_cleared.connect(queue_free)

func _process(_delta):
	bar.value = OverworldGlobals.getCurrentMap().clear_timer.time_left
	label.text = time_to_minutes_secs_mili(timer.time_left)

func time_to_minutes_secs_mili(time : float):
	var mins: int = int(time / 60)
	time -= mins * 60
	var secs = int(time) 
	return str(mins) + ":" + str("%0*d" % [2, secs])
