extends Control
class_name AttributeViewer


#@onready var main_stats = $MainStats

func setCombatant(combatant):
	if combatant == null:
		return
	
	for stat_tracker in get_children():
		stat_tracker.combatant = combatant
