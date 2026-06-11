extends CustomDragDropButton
class_name ItemButton

@export var item:ResItem
@export var empty_icon:Texture = preload("res://images/sprites/icon_charm_trans.png")
@export var allow_drag:bool=true
@onready var durability_bar = $Durability
signal item_dragging(item)

func _ready():
	$HoldProgress.modulate=hold_color
	setItem(item)
	setTooltip()

func _get_drag_data(at_position):
	if item == null or !allow_drag:
		return
	set_drag_preview(getPreview())
	item_dragging.emit(item)
	return item

func setItem(data: ResItem):
	durability_bar.hide()
	item = data
	if data != null:
		icon = data.icon
		description_text = data.getInformation()
	else:
		icon = empty_icon
		description_text = ''
	if data != null and item.isRepairable():
		durability_bar.setItem(item)
		durability_bar.show()

func _force_drag():
	if !allow_drag:
		return
	force_drag(item, getPreview())
	item_dragging.emit(item)
