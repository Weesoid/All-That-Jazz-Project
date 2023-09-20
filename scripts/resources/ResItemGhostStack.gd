extends ResStackItem
class_name ResGhostStackItem

var REFERENCE_ITEM: ResStackItem

func _init(ref_item: ResStackItem):
	REFERENCE_ITEM = ref_item
	NAME = REFERENCE_ITEM.NAME
	DESCRIPTION = REFERENCE_ITEM.DESCRIPTION + ' THIS IS A GHOST ITEM'
	MAX_STACK = 999
	STACK = 1
	PER_WEIGHT = 0
	print('Initialized ghost!')
