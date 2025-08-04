extends Resource
class_name ResQuest

@export var name: String
@export_multiline var description: String
@export var objectives: Array[ResObjective]
@export var completed: bool = false
@export var experience_reward: float = 0.25

func getObjective(objective_name: String)-> ResObjective:
	if !QuestGlobals.hasQuest(name):
		return null
		
	for objective in objectives:
		if objective.name.to_lower() == objective_name.to_lower():
			return objective
	
	return null

func completeObjective(objective_name: String, outcome:int=0):
	for objective in objectives:
		if objective.name == objective_name: objective.complete(outcome)
	
	for objective in objectives:
		if objective.dependent != null and objective.dependent.completed and objective.dependent_outcome == objective.dependent.outcome and !objective.active:
			objective.active = true
			if objective.auto_complete: objective.completed = true
	
	isCompleted()

func isCompleted(show_prompt:bool=true):
	for objective in objectives:
		if objective.final_objective and objective.completed:
			completed = true
			if show_prompt:
				SaveLoadGlobals.saveGame(PlayerGlobals.save_name)
				QuestGlobals.promptQuestCompleted(self)
			PlayerGlobals.addExperience(int(PlayerGlobals.getRequiredExp()*experience_reward), show_prompt, true)
			return completed

func _to_string():
	return "%s : %s" % [name, completed]
