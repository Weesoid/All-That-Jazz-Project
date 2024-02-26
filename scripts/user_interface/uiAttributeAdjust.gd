extends Control

@onready var combatant: ResPlayerCombatant
@onready var points_left = $Available/Points
@onready var attribute_view = $AttributeView
func _process(_delta):
	if combatant != null:
		points_left.text = str(combatant.STAT_POINTS)
		attribute_view.combatant = combatant

func _on_up_brawn_pressed():
	if combatant.STAT_POINTS >= 1:
		combatant.STAT_POINTS -= 1
		combatant.STAT_VALUES['brawn'] += 0.02
		combatant.STAT_POINT_ALLOCATIONS['brawn'] += 1

func _on_up_grit_pressed():
	if combatant.STAT_POINTS >= 1:
		combatant.STAT_POINTS -= 1
		combatant.STAT_VALUES['grit'] += 0.02
		combatant.STAT_POINT_ALLOCATIONS['grit'] += 1

func _on_up_hand_pressed():
	if combatant.STAT_POINTS >= 5:
		combatant.STAT_POINTS -= 5
		combatant.STAT_VALUES['handling'] += 1
		combatant.STAT_POINT_ALLOCATIONS['handling'] += 1

func _on_reset_brawn_pressed():
	combatant.STAT_VALUES['brawn'] -= 0.02 * combatant.STAT_POINT_ALLOCATIONS['brawn']
	combatant.STAT_POINTS += combatant.STAT_POINT_ALLOCATIONS['brawn']
	combatant.STAT_POINT_ALLOCATIONS['brawn'] = 0

func _on_reset_grit_pressed():
	combatant.STAT_VALUES['grit'] -= 0.02 * combatant.STAT_POINT_ALLOCATIONS['grit']
	combatant.STAT_POINTS += combatant.STAT_POINT_ALLOCATIONS['grit']
	combatant.STAT_POINT_ALLOCATIONS['grit'] = 0

func _on_reset_handling_pressed():
	combatant.STAT_VALUES['handling'] -= 1 * combatant.STAT_POINT_ALLOCATIONS['handling']
	combatant.STAT_POINTS += combatant.STAT_POINT_ALLOCATIONS['handling']
	combatant.STAT_POINT_ALLOCATIONS['handling'] = 0
