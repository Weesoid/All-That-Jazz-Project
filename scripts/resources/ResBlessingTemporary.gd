extends Node2D
class_name TemporaryBlessing

@export var blessing: ResBlessing
@export var time: float
@onready var timer = $Timer

func _on_timer_timeout():
	queue_free()

func _on_tree_entered():
	blessing.setBlessing(true)
	OverworldGlobals.showPrompt('You are affected by [color=yellow]%s[/color]!' % blessing.blessing_name)
	#timer.start(time)

func _on_tree_exited():
	blessing.setBlessing(false)

func _on_tree_exiting():
	if is_inside_tree():
		OverworldGlobals.showPrompt('[color=yellow]%s[/color] has worn out!' % blessing.blessing_name)
