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
@export var return_button:Control

func _ready():
	if !OverworldGlobals.getCombatantSquad('Player').is_empty():
		combatant = OverworldGlobals.getCombatantSquad('Player')[0]

func _process(_delta):
	if combatant != null:
		brawn_bonus.text = '+%s' % combatant.stat_point_allocations['damage']
		grit_bonus.text = '+%s' % str((combatant.stat_multiplier * combatant.stat_point_allocations['defense']) * 100)+"%"
		handling_bonus.text = '+%s' % str(1 * combatant.stat_point_allocations['handling'])
		if combatant.stat_point_allocations['damage'] != 0:
			reset_brawn.show()
		else:
			reset_brawn.hide()
		if combatant.stat_point_allocations['defense'] != 0:
			reset_grit.show()
		else:
			reset_grit.hide()
		if combatant.stat_points >= 5:
			handling_up.show()
			handling_bonus.show()
		elif PlayerGlobals.team_level < 5:
			handling_up.hide()
			handling_bonus.hide()
		if combatant.stat_point_allocations['handling'] != 0:
			reset_handling.show()
		else:
			reset_handling.hide()

func showPanel():
	show()
	animator.play("Show")

func hidePanel():
	if return_button != null:
		return_button.grab_focus()
	animator.play_backwards("Show")
	await animator.animation_finished
	hide()

func focus():
	brawn_up.grab_focus()

func _on_up_brawn_pressed():
	adjustStat(1, 'damage', brawn_up)
	if combatant.stat_points <= 0:
		hidePanel()

func _on_up_grit_pressed():
	adjustStat(1, 'defense', grit_up)
	if combatant.stat_points <= 0:
		hidePanel()

func _on_up_hand_pressed():
	adjustStat(5, 'handling', handling_up)
	if combatant.stat_points <= 0:
		hidePanel()

func _on_reset_brawn_pressed():
	resetStat('damage', 1)
	focus()

func _on_reset_grit_pressed():
	resetStat('defense', 1)
	focus()

func _on_reset_handling_pressed():
	resetStat('handling', 5)
	focus()

func adjustStat(cost: int, stat: String, button: Button):
	if combatant.stat_points >= cost:
		combatant.stat_points -= cost
		combatant.stat_point_allocations[stat] += 1
		CombatGlobals.modifyStat(combatant, combatant.getAllocationModifier(), 'allocations')
	else:
		OverworldGlobals.showPrompt('[color=yellow]%s[/color] point(s) is required to increase [color=yellow]%s[/color].' % [str(cost), stat])
	
	if button.visible == false:
		focus()

func resetStat(stat: String, cost):
	if combatant.stat_point_allocations[stat] > 0:
		combatant.stat_points += combatant.stat_point_allocations[stat] * cost
		combatant.stat_point_allocations[stat] = 0
		CombatGlobals.modifyStat(combatant, combatant.getAllocationModifier(), 'allocations')
	
	if combatant.hasEquippedWeapon() and !combatant.equipped_weapon.canUse(combatant):
		combatant.unequipWeapon()


func _on_return_pressed():
	hidePanel()
