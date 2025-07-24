extends ResStackItem
class_name ResGhostStackItem

var REFERENCE_ITEM: ResStackItem

func _init(ref_item: ResStackItem):
	REFERENCE_ITEM = ref_item
	NAME = REFERENCE_ITEM.NAME
	VALUE = REFERENCE_ITEM.VALUE
	DESCRIPTION = REFERENCE_ITEM.DESCRIPTION
	icon = REFERENCE_ITEM.icon
	STACK = 1
