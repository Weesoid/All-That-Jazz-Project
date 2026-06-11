extends CustomButton
class_name CustomDragDropButton

@onready var drag_delay = $DragDelay

func getPreview():
	var preview = load("res://scenes/user_interface/DragPreview.tscn").instantiate()
	preview.texture = icon
	return preview
