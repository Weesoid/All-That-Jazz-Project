extends Node

var QUESTS: Array[ResQuest]
signal quest_completed(quest)
signal quest_objective_completed(objective)
signal quest_added

func _ready():
	quest_objective_completed.connect(checkQuestsForCompleted)
	quest_completed.connect(promptQuestCompleted)

#********************************************************************************
# QUEST MANAGEMENT (NOT IF ANY OVERTIME LAG HAPPENS, CONSIDER REWORKING QUESTS TO NODES) ...ehh you know what this might be fine...
#********************************************************************************
func promptQuestCompleted(quest: ResQuest):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()

	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(quest.NAME)
	prompt.playAnimation('quest_complete')

func checkQuestsForCompleted(objective: ResQuestObjective):
	var ongoing_quests = QUESTS.filter(func getOngoing(quest): return !quest.COMPLETED)
	
	for quest in ongoing_quests:
		if quest.getObjective(objective.NAME) != null and !objective.END_OBJECTIVE:
			OverworldGlobals.getPlayer().prompt.showPrompt('Quest updated: [color=yellow]%s[/color]' % quest.NAME, 5.0, "641011__metkir__crying-sound-0.mp3")
		
		quest.isCompleted()

func addQuest(quest_name: String):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	var quest = load("res://resources/quests/%s/%s.tres" % [quest_name, quest_name])
	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(quest.NAME)
	prompt.playAnimation('show_quest')
	
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
	var objective = getQuest(quest_name).getObjective(quest_objective_name)
	objective.FINISHED = set_to
	if set_to:
		quest_objective_completed.emit(objective)

func isQuestObjectiveEnabled(quest_name: String, quest_objective_name: String) -> bool:
	if QUESTS.is_empty() or getQuest(quest_name) == null:
		return false
	
	#print('List objs')
	#for obj in getQuest('Choice Choices').OBJECTIVES:
	#	print(obj.NAME)
	
	var objective = getQuest(quest_name).getObjective(quest_objective_name)
	
	return objective.ENABLED and !objective.FINISHED

func isQuestObjectiveCompleted(quest_name: String, quest_objective_name: String) -> bool:
	if QUESTS.is_empty() or getQuest(quest_name) == null: 
		return false
	
	var objective = getQuest(quest_name).getObjective(quest_objective_name)
	
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

func saveData(save_data: Array):
	var data: QuestSaveData = QuestSaveData.new()
	data.QUESTS = QUESTS
	for quest in QUESTS:
		for objective in quest.OBJECTIVES:
			data.QUEST_OBJECTIVES_DATA[objective] = [objective.ENABLED, objective.FINISHED, objective.FAILED]
	save_data.append(data)

func loadData(save_data: QuestSaveData):
	QUESTS = save_data.QUESTS
	
	for quest in QUESTS:
		quest.initializeQuest()
	
	for quest in QUESTS:
		for objective in quest.OBJECTIVES:
			objective.ENABLED = save_data.QUEST_OBJECTIVES_DATA[objective][0]
			objective.FINISHED = save_data.QUEST_OBJECTIVES_DATA[objective][1]
			objective.FAILED = save_data.QUEST_OBJECTIVES_DATA[objective][2]
		
		quest.isCompleted(true)
		if quest.COMPLETED:
			for objective in quest.OBJECTIVES: objective.disconnectSignals()
