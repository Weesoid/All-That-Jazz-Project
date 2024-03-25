extends Node

var dialogue_resource: DialogueResource 
var dialogue_conditions: Dictionary

var turn_condition: int
var ability_condition: ResAbility

var combatant_condition: ResCombatant
var combatant_stat_condition: String
var combatant_stat_value

var dialogue_triggered = false

signal dialogue_finished

func _ready():
	CombatGlobals.combat_won.connect(startWinDialogue)
	CombatGlobals.combat_lost.connect(startLoseDialogue)
	CombatGlobals.turn_increment.connect(startTurnDialogue)
	CombatGlobals.ability_used.connect(startAbilityDialogue)
	CombatGlobals.combatant_stats.connect(startCombatantDataDialogue)

func startTurnDialogue(turn: int):
	if turn == turn_condition:
		OverworldGlobals.showDialogueBox(dialogue_resource, 'on_turn')
		dialogue_triggered = true
		CombatGlobals.turn_increment.disconnect(startTurnDialogue)

func startWinDialogue(_id):
	OverworldGlobals.showDialogueBox(dialogue_resource, 'on_win')
	dialogue_triggered = true
	CombatGlobals.combat_won.disconnect(startWinDialogue)

func startLoseDialogue(_id):
	OverworldGlobals.showDialogueBox(dialogue_resource, 'on_lose')
	dialogue_triggered = true
	CombatGlobals.combat_lost.disconnect(startLoseDialogue)

func startCombatantDataDialogue(combatant: ResCombatant):
	if combatant == combatant_condition:
		if combatant.STAT_VALUES[combatant_stat_condition] <= combatant_stat_value:
			OverworldGlobals.showDialogueBox(dialogue_resource, 'on_stat')
			dialogue_triggered = true
			CombatGlobals.combatant_stats.disconnect(startCombatantDataDialogue)

func startAbilityDialogue(ability: ResAbility):
	if ability == ability_condition:
		OverworldGlobals.showDialogueBox(dialogue_resource, 'on_ability')
		dialogue_triggered = true
		CombatGlobals.ability_used.disconnect(startAbilityDialogue)

func _exit_tree():
	CombatGlobals.ability_used.disconnect(startAbilityDialogue)
	CombatGlobals.combatant_stats.disconnect(startCombatantDataDialogue)
	CombatGlobals.combat_lost.disconnect(startLoseDialogue)
	CombatGlobals.combat_won.disconnect(startWinDialogue)
	CombatGlobals.turn_increment.disconnect(startTurnDialogue)
