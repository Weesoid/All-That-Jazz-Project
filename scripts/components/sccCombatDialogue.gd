extends Node
class_name CombatDialogue

# Tems is a slut n whore and I hate her sm!!
@export var dialogue_resource: DialogueResource
@export var end_sentence = ''
@export var enabled: bool = true
var ignored_titles: Array[String] = []
var dialogue_triggered = false

signal dialogue_finished

func initialize():
	if !enabled:
		return
	
	ignored_titles.clear()
	if !CombatGlobals.dialogue_signal.is_connected(checkTitles):
		CombatGlobals.dialogue_signal.connect(checkTitles)

func checkTitles(flag):
	for title in dialogue_resource.get_titles():
		var title_data = title.split('`')
		var base_title = title_data[0]
		var base_title_data = title_data[0].split('/')
		
		# NOTE: Prioritize flags that only pop up once (e.g. Turn flag)
		if flag is String and flag == base_title:
			showDialogueBox(title)
		elif flag is ResCombatant and base_title_data[0] == 'combatant':
			readCombatantData(flag, title)

func readCombatantData(combatant: ResCombatant, title):
	var base_title = title.split('`')[0].split('/')
	if combatant.NAME != base_title[2]:
		return
	
	match base_title[1]:
		'stats':
			if combatant.STAT_VALUES[base_title[3]] <= int(base_title[4]):
				showDialogueBox(title)
		'effect':
			if combatant.hasStatusEffect(base_title[3]):
				showDialogueBox(title)

func showDialogueBox(title: String):
	if ignored_titles.has(title) or dialogue_triggered:
		return
	
	CombatGlobals.getCombatScene().toggleUI(false)
	OverworldGlobals.showDialogueBox(dialogue_resource, title)
	dialogue_triggered = true
	await DialogueManager.dialogue_ended
	CombatGlobals.getCombatScene().toggleUI(true)
	dialogue_triggered = false
	
	if title.split('`').size() > 1:
		var title_sub_data = title.split('`')[1].split('/')
		if title_sub_data.has('once') or (title=='win' or title=='lose'):
			ignored_titles.append(title)

func disconnectSignal():
	if CombatGlobals.dialogue_signal.is_connected(checkTitles):
		CombatGlobals.dialogue_signal.disconnect(checkTitles)
