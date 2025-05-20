extends Control

@onready var combatant: ResPlayerCombatant
@onready var points_left_text = $Available
@onready var points_left = $Available/Points
@onready var brawn_bonus = $HBoxContainer/VBoxContainer/Brawn/HBoxContainer/Value
@onready var grit_bonus = $HBoxContainer/VBoxContainer/Grit/HBoxContainer/Value
@onready var handling_bonus = $HBoxContainer/VBoxContainer/Handling/HBoxContainer/Value
@onready var reset_brawn = $HBoxContainer/VBoxContainer/Brawn/Reset
@onready var reset_grit = $HBoxContainer/VBoxContainer/Grit/Reset
@onready var reset_handling = $HBoxContainer/VBoxContainer/Handling/Reset
@onready var brawn_up = $HBoxContainer/VBoxContainer/Brawn/HBoxContainer/Up
@onready var grit_up = $HBoxContainer/VBoxContainer/Grit/HBoxContainer/Up
@onready var handling_up = $HBoxContainer/VBoxContainer/Handling/HBoxContainer/Up

func _ready():
	if !OverworldGlobals.getCombatantSquad('Player').is_empty():
		combatant = OverworldGlobals.getCombatantSquad('Player')[0]

func _process(_delta):
	if combatant != null:
		points_left.text = str(combatant.STAT_POINTS)
		if combatant.STAT_POINTS > 0:
			points_left_text.show()
			points_left.add_theme_color_override("font_color", Color.YELLOW)
		else:
			points_left_text.hide()
			points_left.add_theme_color_override("font_color", Color.WHITE)
			
		brawn_bonus.text = '+%s' % str((combatant.STAT_MULTIPLIER * combatant.STAT_POINT_ALLOCATIONS['brawn']) * 100)+"%"
		grit_bonus.text = '+%s' % str((combatant.STAT_MULTIPLIER * combatant.STAT_POINT_ALLOCATIONS['grit']) * 100)+"%"
		handling_bonus.text = '+%s' % str(1 * combatant.STAT_POINT_ALLOCATIONS['handling'])
		if combatant.STAT_POINT_ALLOCATIONS['brawn'] != 0:
			reset_brawn.show()
		else:
			reset_brawn.hide()
		if combatant.STAT_POINT_ALLOCATIONS['grit'] != 0:
			reset_grit.show()
		else:
			reset_grit.hide()
		if combatant.STAT_POINTS >= 5:
			handling_up.show()
			handling_bonus.show()
		elif PlayerGlobals.PARTY_LEVEL < 5:
			handling_up.hide()
			handling_bonus.hide()
		if combatant.STAT_POINT_ALLOCATIONS['handling'] != 0:
			reset_handling.show()
		else:
			reset_handling.hide()

func focus():
	brawn_up.grab_focus()

func _on_up_brawn_pressed():
	adjustStat(1, 'brawn', brawn_up)

func _on_up_grit_pressed():
	adjustStat(1, 'grit', grit_up)

func _on_up_hand_pressed():
	adjustStat(5, 'handling', handling_up)

func _on_reset_brawn_pressed():
	resetStat('brawn', 1)
	focus()

func _on_reset_grit_pressed():
	resetStat('grit', 1)
	focus()

func _on_reset_handling_pressed():
	resetStat('handling', 5)
	focus()

func adjustStat(cost: int, stat: String, button: Button):
	if combatant.STAT_POINTS >= cost:
		combatant.STAT_POINTS -= cost
		combatant.STAT_POINT_ALLOCATIONS[stat] += 1
		CombatGlobals.modifyStat(combatant, combatant.getAllocationModifier(), 'allocations')
	else:
		OverworldGlobals.showPlayerPrompt('[color=yellow]%s[/color] point(s) is required to increase [color=yellow]%s[/color].' % [str(cost), stat])
	
	if button.visible == false:
		focus()

func resetStat(stat: String, cost):
	if combatant.STAT_POINT_ALLOCATIONS[stat] > 0:
		combatant.STAT_POINTS += combatant.STAT_POINT_ALLOCATIONS[stat] * cost
		combatant.STAT_POINT_ALLOCATIONS[stat] = 0
		CombatGlobals.modifyStat(combatant, combatant.getAllocationModifier(), 'allocations')
	
	if combatant.hasEquippedWeapon() and !combatant.EQUIPPED_WEAPON.canUse(combatant):
		combatant.unequipWeapon()
