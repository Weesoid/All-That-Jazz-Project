extends Control
class_name AttributeViewer


#@onready var main_stats = $MainStats

#func _ready():
#	var william = load("res://resources/combat/combatants_player/Willis.tres")
#	william.initializeCombatant()
#	await get_tree().process_frame
#	setCombatant(william)

func setCombatant(combatant, clear:bool=false):
	if combatant == null:
		return
	if clear:
		clear()
		await get_tree().process_frame
	for stat_tracker in get_children():
		stat_tracker.setCombatant(combatant)

func clear():
	for stat_tracker in get_children():
		stat_tracker.queue_free()
