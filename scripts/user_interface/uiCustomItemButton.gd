extends CustomDragDropButton
class_name ItemButton

@export var item:ResItem
@export var empty_icon:Texture = preload("res://images/sprites/icon_charm_trans.png")
@export var allow_drag:bool=true
@export var hide_stack:bool=false
@onready var durability_bar = $Durability
@onready var stack_count = $Count
signal item_dragging(item)

func _ready():
	$HoldProgress.modulate=hold_color
	setItem(item)
	setTooltip()

func _get_drag_data(_at_position):
	if item == null or !allow_drag:
		return
	set_drag_preview(getPreview())
	item_dragging.emit(item)
	return item

func setItem(data: ResItem):
	durability_bar.hide()
	stack_count.hide()
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
	if data != null and data is ResStackItem and !stack_count.visible and !hide_stack:
		InventoryGlobals.stack_item_changed.connect(updateCount.unbind(1))
		updateCount(item)
		stack_count.show()
	elif data != null and !data is ResStackItem and stack_count.visible and !hide_stack:
		InventoryGlobals.stack_item_changed.disconnect(updateCount)
		stack_count.hide()

func updateCount(changed_item):
	await get_tree().process_frame
	if changed_item != item:
		return
	stack_count.text = str(changed_item.stack)
	if item.max_stack > 0 and changed_item.stack >= changed_item.max_stack:
		stack_count.modulate = Color.YELLOW
	else:
		stack_count.modulate = Color.WHITE
	
	if changed_item.stack <= 0:
		hide()

func _force_drag():
	if !allow_drag:
		return
	force_drag(item, getPreview())
	item_dragging.emit(item)
