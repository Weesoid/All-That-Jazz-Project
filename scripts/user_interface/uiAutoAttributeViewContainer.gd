extends AttributeViewer
class_name AutoAttribueViewer

@onready var stat_container = $ScrollContainer/VBoxContainer
var skip_stats = CombatExtras.BASE_STATS


func setCombatant(combatant):
	if combatant == null:
		return
	
	for stat in combatant.stat_values.keys():
		if skip_stats.has(stat): continue
		stat_container.add_child(createStatTracker(combatant, stat))

func createStatTracker(combatant, stat):
	var tracker = load("res://scenes/user_interface/StatLabel.tscn").instantiate()
	tracker.track_stat = stat
	tracker.visual = StatLabel.StatVisuals.LABEL
	if fmod(combatant.stat_values[stat], 1.0) != 0:
		tracker.label_style = StatLabel.LabelStyle.PERCENTAGE
	else:
		tracker.label_style = StatLabel.LabelStyle.FLAT
	tracker.combatant = combatant
	return tracker
