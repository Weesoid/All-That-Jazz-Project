extends VBoxContainer
class_name AttributeViewer


@export var tooltip_position: CustomTooltip.AnchorPreset = CustomTooltip.AnchorPreset.LEFT

func _ready():
	UIGlobals.setVerticalNeighbors(self)

func setCombatant(combatant, clear:bool=false):
	if combatant == null:
		return
	if clear:
		clear()
		await get_tree().process_frame
	for stat_tracker in get_children():
		stat_tracker.setCombatant(combatant)
		if stat_tracker.has_node('CustomTooltip'):
			stat_tracker.get_node('CustomTooltip').tooltip_position = tooltip_position
	UIGlobals.setVerticalNeighbors(self)

func clear():
	for stat_tracker in get_children():
		stat_tracker.queue_free()
