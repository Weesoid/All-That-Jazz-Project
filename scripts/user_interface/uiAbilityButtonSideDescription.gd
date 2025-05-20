extends Control

@onready var text = $PanelContainer/RichTextLabel
@onready var animator:AnimationPlayer = $AnimationPlayer

func _enter_tree():
	get_parent().focus_exited.connect(remove)
	get_parent().mouse_exited.connect(remove)

func showDescription(ability: ResAbility):
	global_position = get_parent().global_position+Vector2(-72,-96)
	text.text = ability.getRichDescription(true)
	animator.play('Show')

func remove():
	animator.play_backwards('Show')
	await animator.animation_finished
	queue_free()

func _unhandled_input(_event):
	if Input.is_action_just_released("ui_select_arrow"):
		remove()
