extends CharacterBody2D
class_name DestroyableObjective

@onready var destroy_shape = $Area2D
@onready var destroy_bar = $ProgressBar
@onready var destroy_timer = $Timer

var active = true

func _ready():
	destroy_bar.hide()
	destroy_bar.max_value = destroy_timer.wait_time

func _process(_delta):
	destroy_bar.value = destroy_timer.time_left

func _exit_tree():
	for child in OverworldGlobals.getCurrentMap().get_children():
		if child is DestroyableObjective and child != self: return
	
	if active:
		OverworldGlobals.getCurrentMap().escapePatrollers(false, true, false)
		OverworldGlobals.getCurrentMap().giveRewards()

func _on_area_2d_body_entered(body):
	if body is PlayerScene:
		destroy_bar.show()
		destroy_timer.start()

func _on_area_2d_body_exited(body):
	if body is PlayerScene:
		destroy_bar.hide()
		destroy_timer.stop()

func _on_timer_timeout():
	queue_free()
