extends Node2D

@onready var label = $Label
@onready var animator = $AnimationPlayer

func playAnimation(pos: Vector2, text: String, animation: String):
	global_position = pos
	label.text = str(text)
	if animation == "Crit": label.text += " CRITICAL!"
	animator.play(animation)
	await animator.animation_finished
	queue_free()
