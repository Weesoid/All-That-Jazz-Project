extends Node
class_name ItemDropDetector

signal item_dropped(item)
var dragged_item:ResItem=null

func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN:
		dragged_item = get_viewport().gui_get_drag_data()
	
	if what == NOTIFICATION_DRAG_END and !get_viewport().gui_is_drag_successful():
		item_dropped.emit(dragged_item)
		dragged_item = null
	
	if what == NOTIFICATION_DRAG_END and get_viewport().gui_is_drag_successful():
		dragged_item = null
