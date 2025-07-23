extends Control

@onready var combatant: ResPlayerCombatant
@onready var brawn_bonus = $StatAdjustPanel/BrawnVal
@onready var grit_bonus = $StatAdjustPanel/GritVal
@onready var handling_bonus = $StatAdjustPanel/HandVal
@onready var brawn_up = $StatAdjustPanel/PanelContainer/MarginContainer/VFlowContainer/Brawn/Up
@onready var grit_up = $StatAdjustPanel/PanelContainer/MarginContainer/VFlowContainer/Grit/Up
@onready var handling_up = $StatAdjustPanel/PanelContainer/MarginContainer/VFlowContainer/Handling/Up
@onready var reset_brawn = $StatAdjustPanel/PanelContainer/MarginContainer/VFlowContainer/Brawn/Reset
@onready var reset_grit = $StatAdjustPanel/PanelContainer/MarginContainer/VFlowContainer/Grit/Reset
@onready var reset_handling = $StatAdjustPanel/PanelContainer/MarginContainer/VFlowContainer/Handling/Reset
@onready var animator = $AnimationPlayer

func _ready():
	if !OverworldGlobals.getCombatantSquad('Player').is_empty():
		combatant = OverworldGlobals.getCombatantSquad('Player')[0]

func _process(_delta):
	if combatant != null:
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

func showPanel():
	show()
	animator.play("Show")

func hidePanel():
	animator.play_backwards("Show")
	await animator.animation_finished
	hide()

func focus():
	brawn_up.grab_focus()

func _on_up_brawn_pressed():
	adjustStat(1, 'brawn', brawn_up)
	if combatant.STAT_POINTS <= 0:
		hidePanel()

func _on_up_grit_pressed():
	adjustStat(1, 'grit', grit_up)
	if combatant.STAT_POINTS <= 0:
		hidePanel()

func _on_up_hand_pressed():
	adjustStat(5, 'handling', handling_up)
	if combatant.STAT_POINTS <= 0:
		hidePanel()

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
		OverworldGlobals.showPrompt('[color=yellow]%s[/color] point(s) is required to increase [color=yellow]%s[/color].' % [str(cost), stat])
	
	if button.visible == false:
		focus()

func resetStat(stat: String, cost):
	if combatant.STAT_POINT_ALLOCATIONS[stat] > 0:
		combatant.STAT_POINTS += combatant.STAT_POINT_ALLOCATIONS[stat] * cost
		combatant.STAT_POINT_ALLOCATIONS[stat] = 0
		CombatGlobals.modifyStat(combatant, combatant.getAllocationModifier(), 'allocations')
	
	if combatant.hasEquippedWeapon() and !combatant.EQUIPPED_WEAPON.canUse(combatant):
		combatant.unequipWeapon()
