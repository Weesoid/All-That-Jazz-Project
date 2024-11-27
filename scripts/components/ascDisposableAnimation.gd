extends Node2D
class_name QuickAnimation

@export var animation_name = 'Show'
@export var invisible_frame_zero: bool = false
@export var free_after:bool = true
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	if invisible_frame_zero:
		modulate = Color.TRANSPARENT
	if animation_name == '':
		var random_anim = Array(animation_player.get_animation_list())
		random_anim.erase('RESET')
		animation_name = random_anim.pick_random()
	
	animation_player.play(animation_name)
	if invisible_frame_zero:
		create_tween().tween_property(self, 'modulate', Color.WHITE, 0.15)
	if free_after:
		await animation_player.animation_finished
		queue_free()
