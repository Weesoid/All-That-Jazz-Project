extends ResStackItem
class_name ResGhostStackItem

var reference_item: ResStackItem

func _init(ref_item: ResStackItem):
	reference_item = ref_item
	NAME = reference_item.NAME
	value = reference_item.value
	description = reference_item.description
	icon = reference_item.icon
	stack = 1
