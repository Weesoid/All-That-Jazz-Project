extends Node
class_name ItemDropDetector

signal drag_started(item)
signal item_not_dropped(item)
signal item_dropped(item)
#signal item_exit_hover(item)
var dragged_item:ResItem=null

func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN:
		dragged_item = get_viewport().gui_get_drag_data()
		drag_started.emit(dragged_item)
	
	if what == NOTIFICATION_DRAG_END and !get_viewport().gui_is_drag_successful():
		item_not_dropped.emit(dragged_item)
		dragged_item = null
	
	if what == NOTIFICATION_DRAG_END and get_viewport().gui_is_drag_successful():
		item_dropped.emit(dragged_item)
		dragged_item = null

#	if what == NOTIF and get_viewport().gui_is_dragging():
#		print('zaza')
#		item_exit_hover.emit(dragged_item)
