extends CustomDragDropButton
class_name ItemButton

@export var item:ResItem
@export var empty_icon:Texture = load("res://images/sprites/icon_charm_trans.png")
signal item_dragging(item)

func _get_drag_data(at_position):
	if item == null:
		return
	set_drag_preview(getPreview())
	item_dragging.emit(item)
	return item

#func _drop_data(_at_position, data):
#	print(data)

func ready():
	if item == null:
		icon = empty_icon
		return
	
	icon = item.icon
