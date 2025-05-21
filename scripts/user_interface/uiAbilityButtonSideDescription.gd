extends Control

@onready var text = $PanelContainer/RichTextLabel
@onready var animator:AnimationPlayer = $AnimationPlayer

func _enter_tree():
	get_parent().focus_exited.connect(remove)
	get_parent().mouse_exited.connect(remove)

func showDescription(show_text: String, cust_offset:Vector2=Vector2.ZERO):
	global_position = get_parent().global_position+cust_offset
	text.text = '[center]'+show_text
	animator.play('Show')

func remove():
	animator.play_backwards('Show')
	await animator.animation_finished
	queue_free()

func _unhandled_input(_event):
	if Input.is_action_just_released("ui_select_arrow"):
		remove()
