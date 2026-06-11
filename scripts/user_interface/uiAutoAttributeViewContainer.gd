extends AttributeViewer
class_name AutoAttribueViewer

@onready var stat_container = $"."
var tracked_stats:Array[String] = []
var skip_stats = CombatExtras.BASE_STATS

func setCombatant(combatant:ResCombatant, clear:bool=false):
	if combatant == null:
		return
	if clear:
		clear()
		await get_tree().process_frame
	
	for stat in combatant.stat_values.keys():
		if skip_stats.has(stat): continue
		addStat(combatant,stat)
	if !combatant.extra_stat_added.is_connected(addStat):
		combatant.extra_stat_added.connect(addStat)

func addStat(combatant, stat):
	if tracked_stats.has(stat): return
	stat_container.add_child(createStatTracker(combatant, stat, tooltip_position))
	UIGlobals.setVerticalNeighbors(self)

func clear():
	for stat_tracker in stat_container.get_children():
		stat_tracker.queue_free()
	tracked_stats.clear()

func createStatTracker(combatant, stat,tooltip_position:CustomTooltip.AnchorPreset=CustomTooltip.AnchorPreset.LEFT):
	var tracker = load("res://scenes/user_interface/StatLabel.tscn").instantiate()
	tracker.track_stat = stat
	tracker.visual = StatLabel.StatVisuals.LABEL
	tracker.tooltip_pos = tooltip_position
	if combatant.stat_values[stat] is float:
		tracker.label_style = StatLabel.LabelStyle.PERCENTAGE
	else:
		tracker.label_style = StatLabel.LabelStyle.FLAT
	tracker.combatant = combatant
	tracked_stats.append(stat)
	return tracker
