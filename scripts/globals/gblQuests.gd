extends Node

var quests: Array[ResQuest]

func promptQuestCompleted(quest: ResQuest):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	
	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(quest.NAME)
	prompt.playAnimation('quest_complete')

func addQuest(quest_name: String):
	var prompt = preload("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	var out_quest = load("res://resources/quests/%s.tres" % quest_name)
	OverworldGlobals.getPlayer().player_camera.add_child(prompt)
	prompt.setTitle(out_quest.NAME)
	prompt.playAnimation('show_quest')
	
	out_quest.OBJECTIVES[0].ACTIVE = true
	quests.append(out_quest)

func hasQuest(quest_name: String):
	if quests.is_empty() or getQuest(quest_name) == null: 
		return false
	
	var out_quest = quests[quests.find(getQuest(quest_name))]
	return out_quest != null

func isQuestCompleted(quest_name: String):
	if quests.is_empty(): return false
	var out_quest = quests[quests.find(getQuest(quest_name))]
	return out_quest.COMPLETED

func isObjectiveActive(quest_name: String, quest_objective_name: String)-> bool:
	return hasQuest(quest_name) and getQuest(quest_name).getObjective(quest_objective_name).ACTIVE and !getQuest(quest_name).getObjective(quest_objective_name).COMPLETED

func completeQuestObjective(quest_name: String, quest_objective_name: String, outcome:int=0):
	getQuest(quest_name).completeObjective(quest_objective_name, outcome)
	OverworldGlobals.showPrompt('Quest updated: [color=yellow]%s[/color]' % quest_name, 5.0, "430892__gsb1039__magic-1-grainsmooth.ogg")


func isQuestObjectiveCompleted(quest_name: String, quest_objective_name: String) -> bool:
	if quests.is_empty() or getQuest(quest_name) == null: 
		return false
	
	return getQuest(quest_name).getObjective(quest_objective_name).COMPLETED

func getQuest(quest_name: String)-> ResQuest:
	for quest in quests:
		if quest.NAME.to_lower() == quest_name.to_lower(): return quest
	
	return null

func saveData(save_data: Array):
	var data: QuestSaveData = QuestSaveData.new()
	data.quests = quests
	for quest in quests:
		var objectives_data = {}
		for objective in quest.OBJECTIVES:
			objectives_data[objective.NAME] = [objective.ACTIVE, objective.COMPLETED, objective.OUTCOME]
		data.QUEST_OBJECTIVES_DATA[quest] = objectives_data
	save_data.append(data)

func loadData(save_data: QuestSaveData):
	quests = save_data.quests
	for quest in quests:
		for objective in quest.OBJECTIVES:
			objective.ACTIVE = save_data.QUEST_OBJECTIVES_DATA[quest][objective.NAME][0]
			objective.COMPLETED = save_data.QUEST_OBJECTIVES_DATA[quest][objective.NAME][1]
			objective.OUTCOME = save_data.QUEST_OBJECTIVES_DATA[quest][objective.NAME][2]
		quest.isCompleted(false)

func resetVariables():
	quests = []
