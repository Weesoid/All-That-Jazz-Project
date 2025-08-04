extends Node

var quests: Array[ResQuest] # Marked for indirect reference.

func promptQuestCompleted(quest: ResQuest):
	var prompt = load("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	
	OverworldGlobals.player.player_camera.add_child(prompt)
	prompt.setTitle(quest.name)
	prompt.playAnimation('quest_complete')

func addQuest(quest_name: String):
	var prompt = load("res://scenes/user_interface/PromptQuest.tscn").instantiate()
	var out_quest = load("res://resources/quests/%s.tres" % quest_name)
	OverworldGlobals.player.player_camera.add_child(prompt)
	prompt.setTitle(out_quest.name)
	prompt.playAnimation('show_quest')
	
	out_quest.objectives[0].active = true
	quests.append(out_quest)

func hasQuest(quest_name: String):
	if quests.is_empty() or getQuest(quest_name) == null: 
		return false
	
	var out_quest = quests[quests.find(getQuest(quest_name))]
	return out_quest != null

func isQuestCompleted(quest_name: String):
	if quests.is_empty(): return false
	var out_quest = quests[quests.find(getQuest(quest_name))]
	return out_quest.completed

func isObjectiveActive(quest_name: String, quest_objective_name: String)-> bool:
	return hasQuest(quest_name) and getQuest(quest_name).getObjective(quest_objective_name).active and !getQuest(quest_name).getObjective(quest_objective_name).completed

func completeQuestObjective(quest_name: String, quest_objective_name: String, outcome:int=0):
	getQuest(quest_name).completeObjective(quest_objective_name, outcome)
	if !getQuest(quest_name).isCompleted():
		OverworldGlobals.showPrompt('Quest updated: [color=yellow]%s[/color]' % quest_name, 5.0, "430892__gsb1039__magic-1-grainsmooth.ogg")


func isQuestObjectiveCompleted(quest_name: String, quest_objective_name: String) -> bool:
	if quests.is_empty() or getQuest(quest_name) == null: 
		return false
	
	return getQuest(quest_name).getObjective(quest_objective_name).completed

func getQuest(quest_name: String)-> ResQuest:
	for quest in quests:
		if quest.name.to_lower() == quest_name.to_lower(): return quest
	
	return null

func saveData(save_data: Array):
	var data: QuestSaveData = QuestSaveData.new()
	data.quests.assign(ResourceGlobals.getResourcePathArray(quests))
	for quest in quests:
		var objectives_data = {}
		for objective in quest.objectives:
			objectives_data[objective.name] = [objective.active, objective.completed, objective.outcome]
		data.quest_objectives_data[quest.resource_path] = objectives_data
	save_data.append(data)

func loadData(save_data: QuestSaveData):
	quests.assign(ResourceGlobals.loadResourcePathArray(save_data.quests))
	for quest in quests:
		for objective in quest.objectives:
			objective.active = save_data.quest_objectives_data[quest.resource_path][objective.name][0]
			objective.completed = save_data.quest_objectives_data[quest.resource_path][objective.name][1]
			objective.outcome = save_data.quest_objectives_data[quest.resource_path][objective.name][2]
		quest.isCompleted(false)

func resetVariables():
	quests = []
