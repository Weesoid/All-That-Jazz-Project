extends Node
class_name CombatDialogue

@export var dialogue_resource: DialogueResource 
var ignored_flags: Array[String] = []
#var dialogue_conditions: Dictionary

#var turn_condition: int
#var ability_condition: ResAbility
#var combatant_condition: ResCombatant
#var combatant_stat_condition: String
#var combatant_stat_value

var dialogue_triggered = false
signal dialogue_finished

func initialize():
	CombatGlobals.combat_won.connect(checkTitles)
	CombatGlobals.combat_lost.connect(checkTitles)
	CombatGlobals.turn_increment.connect(checkTitles)
	CombatGlobals.ability_used.connect(checkTitles)
	CombatGlobals.combatant_stats.connect(checkTitles)

func checkTitles(flag):
	print('Ignoring: ', ignored_flags)
	for title in dialogue_resource.get_titles():
		var title_data = title.split('`')
		var title_sub_data = title_data[0].split('/')
		var base_title = title_data[0]
		
		if flag is String and flag == base_title and !ignored_flags.has(flag):
			OverworldGlobals.showDialogueBox(dialogue_resource, title)
			dialogue_triggered = true
			
			if title_data.size() > 1:
				title_sub_data = title_data[1].split('/')
				if title_sub_data.has('once'):
					ignored_flags.append(flag)
		
		elif flag is ResCombatant and base_title.split('/')[0] == 'stat':
			readCombatantData(flag, title)

func readCombatantData(combatant: ResCombatant, title):
	var base_title = title.split('`')[0].split('/')
	
	if combatant.NAME == base_title[1]:
		for stat in combatant.STAT_VALUES.keys():
			if stat == base_title[2] and combatant.STAT_VALUES[stat] <= int(base_title[3]) and !ignored_flags.has(title):
				OverworldGlobals.showDialogueBox(dialogue_resource, title)
				dialogue_triggered = true
				
				if title.split('`').size() > 1:
					var title_sub_data = title.split('`')[1].split('/')
					print(title_sub_data)
					if title_sub_data.has('once'):
						ignored_flags.append(title)
#func startTurnDialogue(turn: int):
#	if turn == turn_condition:
#		OverworldGlobals.showDialogueBox(dialogue_resource, 'on_turn')
#		dialogue_triggered = true
#		CombatGlobals.turn_increment.disconnect(startTurnDialogue)
#
#func startWinDialogue(_id):
#	OverworldGlobals.showDialogueBox(dialogue_resource, 'on_win')
#	dialogue_triggered = true
#	CombatGlobals.combat_won.disconnect(startWinDialogue)
#
#func startLoseDialogue(_id):
#	OverworldGlobals.showDialogueBox(dialogue_resource, 'on_lose')
#	dialogue_triggered = true
#	CombatGlobals.combat_lost.disconnect(startLoseDialogue)
#
#func startCombatantDataDialogue(combatant: ResCombatant):
#	if combatant == combatant_condition:
#		if combatant.STAT_VALUES[combatant_stat_condition] <= combatant_stat_value:
#			OverworldGlobals.showDialogueBox(dialogue_resource, 'on_stat')
#			dialogue_triggered = true
#			CombatGlobals.combatant_stats.disconnect(startCombatantDataDialogue)
#
#func startAbilityDialogue(ability: ResAbility):
#	if ability == ability_condition:
#		OverworldGlobals.showDialogueBox(dialogue_resource, 'on_ability')
#		dialogue_triggered = true
#		CombatGlobals.ability_used.disconnect(startAbilityDialogue)
#
#func _exit_tree():
#	CombatGlobals.ability_used.disconnect(startAbilityDialogue)
#	CombatGlobals.combatant_stats.disconnect(startCombatantDataDialogue)
#	CombatGlobals.combat_lost.disconnect(startLoseDialogue)
#	CombatGlobals.combat_won.disconnect(startWinDialogue)
#	CombatGlobals.turn_increment.disconnect(startTurnDialogue)
