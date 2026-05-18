extends Label
class_name StackCountLabel

var item: ResStackItem

func _init(p_item):
	item = p_item
	InventoryGlobals.stack_item_changed.connect(updateCount.unbind(1))

func _enter_tree():
	updateCount(item)
	theme = load("res://design/OutlinedLabel.tres")

func updateCount(changed_item):
	if changed_item != item:
		return
	text = str(changed_item.stack)
	if item.max_stack > 0 and changed_item.stack >= changed_item.max_stack:
		modulate = Color.YELLOW
	else:
		modulate = Color.WHITE
	
	if changed_item.stack <= 0:
		get_parent().queue_free()
