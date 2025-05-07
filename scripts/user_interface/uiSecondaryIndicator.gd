extends Node2D

@onready var label = $Label
@onready var animator = $AnimationPlayer

func playAnimation(pos: Vector2, text: String, animation: String):
	#modulate = color
	global_position = pos
	label.text = '[center]'+str(text)
	animator.play(animation)
	await animator.animation_finished
	create_tween().tween_property(self, 'scale', Vector2.ZERO, 0.2)
	await create_tween().tween_property(self, 'global_position', get_parent().global_position, 0.1).finished
	queue_free()
