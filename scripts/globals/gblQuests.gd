extends Node

var QUESTS: Array[ResQuest]
signal quest_completed(quest)
signal quest_objective_completed(objective)
signal quest_added

func _ready():
	quest_objective_completed.connect(checkQuestsForCompleted)

#********************************************************************************
# QUEST MANAGEMENT (NOT IF ANY OVERTIME LAG HAPPENS, CONSIDER REWORKING QUESTS TO NODES) ...ehh you know what this might be fine...
#********************************************************************************
func checkQuestsForCompleted(objective: ResQuestObjective):
	var ongoing_quests = QUESTS.filter(func getOngoing(quest): return !quest.COMPLETED)
	
	for quest in ongoing_quests:
		if quest.getObjective(objective.NAME) != null and !objective.END_OBJECTIVE:
			OverworldGlobals.getPlayer().prompt.showPrompt('Quest updated: [color=yellow]%s[/color]' % quest.NAME, 5.0, "641011__metkir__crying-sound-0.mp3")
		
		quest.isCompleted()

func addQuest(quest_name: String):
	var quest = load("res://resources/quests/%s/%s.tres" % [quest_name, quest_name])
	quest.initializeQuest()
	QUESTS.append(quest)
	quest_added.emit()

func hasQuest(quest_name: String):
	if QUESTS.is_empty() or getQuest(quest_name) == null: 
		return false
	
	var quest = QUESTS[QUESTS.find(getQuest(quest_name))]
	return quest != null

func isQuestCompleted(quest_name: String):
	if QUESTS.is_empty(): return false
	var quest = QUESTS[QUESTS.find(getQuest(quest_name))]
	return quest.COMPLETED

func setQuestObjective(quest_name: String, quest_objective_name: String, set_to: bool):
	var objective = QUESTS[QUESTS.find(getQuest(quest_name))].getObjective(quest_objective_name)
	objective.FINISHED = set_to
	if set_to:
		quest_objective_completed.emit(objective)

func isQuestObjectiveEnabled(quest_name: String, quest_objective_name: String) -> bool:
	if QUESTS.is_empty() or getQuest(quest_name) == null:
		return false
	
	var objective = QUESTS[QUESTS.find(getQuest(quest_name))].getObjective(quest_objective_name)
	
	return objective.ENABLED and !objective.FINISHED

func isQuestObjectiveCompleted(quest_name: String, quest_objective_name: String) -> bool:
	if QUESTS.is_empty() or getQuest(quest_name) == null: 
		return false
	
	var objective = QUESTS[QUESTS.find(getQuest(quest_name))].getObjective(quest_objective_name)
	
	return objective.FINISHED

func isQuestObjectiveFailed(quest_name: String, quest_objective_name: String) -> bool:
	if QUESTS.is_empty() or getQuest(quest_name) == null:
		return false
	
	var objective = QUESTS[QUESTS.find(getQuest(quest_name))].getObjective(quest_objective_name)
	
	return objective.FAILED

func getQuest(quest_name: String)-> ResQuest:
	for quest in QUESTS:
		if quest.NAME.to_lower() == quest_name.to_lower(): 
			return quest
	
	return null
