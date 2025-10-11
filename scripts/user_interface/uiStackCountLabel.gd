extends Label
class_name StackCountLabel

var item: ResStackItem

func _init(p_item):
	item = p_item
	InventoryGlobals.stack_item_changed.connect(updateCount)

func _enter_tree():
	updateCount(item, item.stack, -1)
	theme = load("res://design/OutlinedLabelThin.tres")

func updateCount(changed_item, new_stack, _old_stack):
	if changed_item != item:
		return
	text = str(new_stack)
	if item.max_stack > 0 and new_stack >= changed_item.max_stack:
		modulate = Color.YELLOW
	else:
		modulate = Color.WHITE
	
	if new_stack <= 0:
		get_parent().queue_free()
