extends Node

var QUESTS: Array[RezQuest]

#********************************************************************************
# QUEST MANAGEMENT (NOT IF ANY OVERTIME LAG HAPPENS, CONSIDER REWORKING QUESTS TO NODES) ...ehh you know what this might be fine...
#********************************************************************************
func promptQuestCompleted(quest: RezQuest):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	
	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(quest.NAME)
	prompt.playAnimation('quest_complete')

func addQuest(quest_name: String):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	var quest = load("res://resources/quests/%s.tres" % quest_name)
	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(quest.NAME)
	prompt.playAnimation('show_quest')
	
	quest.initializeQuest()
	QUESTS.append(quest)

func hasQuest(quest_name: String):
	if QUESTS.is_empty() or getQuest(quest_name) == null: 
		return false
	
	var quest = QUESTS[QUESTS.find(getQuest(quest_name))]
	return quest != null

func isQuestCompleted(quest_name: String):
	if QUESTS.is_empty(): return false
	var quest = QUESTS[QUESTS.find(getQuest(quest_name))]
	return quest.COMPLETED

func completeQuestObjective(quest_name: String, quest_objective_name: String):
	getQuest(quest_name).completeObjective(quest_objective_name)

func isQuestObjectiveCompleted(quest_name: String, quest_objective_name: String) -> bool:
	if QUESTS.is_empty() or getQuest(quest_name) == null: 
		return false
	
	return getQuest(quest_name).getObjective(quest_objective_name).FINISHED

func getQuest(quest_name: String)-> RezQuest:
	for quest in QUESTS:
		if quest.NAME.to_lower() == quest_name.to_lower(): return quest
	
	return null


# REMEMBER TO DO THIS
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
		for objective in quest.OBJECTIVES:
			if !save_data.QUEST_OBJECTIVES_DATA.keys().has(objective): continue
			objective.ENABLED = save_data.QUEST_OBJECTIVES_DATA[objective][0]
			objective.FINISHED = save_data.QUEST_OBJECTIVES_DATA[objective][1]
			objective.FAILED = save_data.QUEST_OBJECTIVES_DATA[objective][2]
		
		quest.isCompleted()
		if quest.COMPLETED:
			for objective in quest.OBJECTIVES: objective.disconnectSignals()
