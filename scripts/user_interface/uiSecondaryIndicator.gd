extends Node2D
class_name Indicator

@onready var label = $Label
@onready var animator = $AnimationPlayer
@onready var tween: Tween
@onready var pos_tween: Tween

#func _ready():
#	label.add_theme_constant_override("outline_size",99)

func playAnimation(pos: Vector2, text: String, animation: String,time:float=1.5):
	randomize()
	tween = create_tween()
	pos_tween = create_tween()
	pos_tween.tween_property(self, 'global_position',pos,time).set_ease(Tween.EASE_IN_OUT)
	label.text = '[center]'+str(text)
	animator.play(animation)
	tween.tween_property(self, 'modulate', Color.TRANSPARENT,time).set_trans(Tween.TRANS_EXPO)
	await tween.finished
	queue_free()

func _on_tree_exited():
	if is_instance_valid(tween):
		tween.kill()
		pos_tween.kill()
