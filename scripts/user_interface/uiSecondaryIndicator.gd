extends Node2D

@onready var label = $Label
@onready var animator = $AnimationPlayer
@onready var tween: Tween

func playAnimation(pos: Vector2, text: String, animation: String,time:float=1.0):
	randomize()
	var random_vector = Vector2(randf_range(-24,24),randf_range(-24,24))
	global_position = pos
	label.text = '[center]'+str(text)
	animator.play(animation)
	await get_tree().create_timer(0.5).timeout
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, 'modulate', Color.TRANSPARENT, time-0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, 'global_position', global_position+random_vector, 1.0).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.25).timeout
	queue_free()

func _on_tree_exited():
	if is_instance_valid(tween):
		tween.kill()
