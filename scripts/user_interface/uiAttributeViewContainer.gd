extends Control
class_name AttributeViewer


#@onready var main_stats = $MainStats

func setCombatant(combatant, clear:bool=false):
	if combatant == null:
		return
	if clear:
		clear()
		await get_tree().process_frame
	for stat_tracker in get_children():
		stat_tracker.combatant = combatant

func clear():
	for stat_tracker in get_children():
		stat_tracker.queue_free()
