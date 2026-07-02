extends Control
class_name CornerCloseButton

enum Mode {
	QUEUE_FREE,
	HIDE,
	CUSTOM
}
@export var menu:Control
@export var mode: Mode = Mode.HIDE
@export var set_parent_menu:bool=false
@onready var button = $CustomButton
signal custom_close

func _ready():
	if set_parent_menu:
		menu = get_parent()

func close():
	var close_menu = menu if menu != null else get_parent()
	match mode:
		Mode.QUEUE_FREE: close_menu.queue_free()
		Mode.HIDE: close_menu.hide()
		Mode.CUSTOM: custom_close.emit()

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_cancel") and visible and modulate != Color.TRANSPARENT:
		close()
