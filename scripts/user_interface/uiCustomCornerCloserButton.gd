extends Control
class_name CornerCloseButton

enum Mode {
	QUEUE_FREE,
	HIDE,
	CUSTOM
}
@export var menu:Control
@export var mode: Mode = Mode.HIDE
@onready var button = $CustomButton
signal custom_close



func close():
	var close_menu = menu if menu != null else get_parent()
	match mode:
		Mode.QUEUE_FREE: close_menu.queue_free()
		Mode.HIDE: close_menu.hide()
		Mode.CUSTOM: custom_close.emit()

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_cancel") and visible and modulate != Color.TRANSPARENT:
		close()
