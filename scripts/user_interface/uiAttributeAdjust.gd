extends Control

@onready var combatant: ResPlayerCombatant
@onready var points_left = $Available/Points
@onready var brawn_bonus = $HBoxContainer/VBoxContainer/Brawn/HBoxContainer/Value
@onready var grit_bonus = $HBoxContainer/VBoxContainer/Grit/HBoxContainer/Value
@onready var handling_bonus = $HBoxContainer/VBoxContainer/Handling/HBoxContainer/Value
@onready var reset_brawn = $HBoxContainer/VBoxContainer/Brawn/Reset
@onready var reset_grit = $HBoxContainer/VBoxContainer/Grit/Reset
@onready var reset_handling = $HBoxContainer/VBoxContainer/Handling/Reset
func _process(_delta):
	if combatant != null:
		points_left.text = str(combatant.STAT_POINTS)
		brawn_bonus.text = '+%s' % str((0.02 * combatant.STAT_POINT_ALLOCATIONS['brawn']) * 100)+"%"
		grit_bonus.text = '+%s' % str((0.02 * combatant.STAT_POINT_ALLOCATIONS['grit']) * 100)+"%"
		handling_bonus.text = '+%s' % str(1 * combatant.STAT_POINT_ALLOCATIONS['handling'])
		if combatant.STAT_POINT_ALLOCATIONS['brawn'] != 0:
			reset_brawn.show()
		else:
			reset_brawn.hide()
		if combatant.STAT_POINT_ALLOCATIONS['grit'] != 0:
			reset_grit.show()
		else:
			reset_grit.hide()
		if combatant.STAT_POINT_ALLOCATIONS['handling'] != 0:
			reset_handling.show()
		else:
			reset_handling.hide()

func _on_up_brawn_pressed():
	adjustStat(1, 0.02, 'brawn')

func _on_up_grit_pressed():
	adjustStat(1, 0.02, 'grit')

func _on_up_hand_pressed():
	adjustStat(5, 1, 'handling')

func _on_reset_brawn_pressed():
	resetStat('brawn', 0.02, 1)

func _on_reset_grit_pressed():
	resetStat('grit', 0.02, 1)

func _on_reset_handling_pressed():
	resetStat('handling', 1, 5)

func adjustStat(cost: int, value, stat: String):
	if combatant.STAT_POINTS >= cost:
		combatant.STAT_POINTS -= cost
		combatant.STAT_POINT_ALLOCATIONS[stat] += 1
		combatant.STAT_VALUES[stat] += value

func resetStat(stat: String, value, cost):
	if combatant.STAT_POINT_ALLOCATIONS[stat] > 0:
		combatant.STAT_VALUES[stat] -= value * combatant.STAT_POINT_ALLOCATIONS[stat]
		combatant.STAT_POINTS += combatant.STAT_POINT_ALLOCATIONS[stat] * cost
		combatant.STAT_POINT_ALLOCATIONS[stat] = 0
