extends CustomDragDropButton
class_name ItemButton

@export var item:ResItem
@export var empty_icon:Texture = preload("res://images/sprites/icon_charm_trans.png")
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
	setItem(item)

func setItem(data: ResItem):
	item = data
	if data != null:
		icon = data.icon
		description_text = data.getInformation()
	else:
		icon = empty_icon
		description_text = ''
