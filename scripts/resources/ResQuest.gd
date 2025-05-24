extends Resource
class_name ResQuest

@export var NAME: String
@export_multiline var DESCRIPTION: String
@export var OBJECTIVES: Array[ResObjective]
@export var COMPLETED: bool = false
@export var EXPERIENCE_REWARD: float = 0.25

func getObjective(objective_name: String)-> ResObjective:
	if !QuestGlobals.hasQuest(NAME):
		return null
		
	for objective in OBJECTIVES:
		if objective.NAME.to_lower() == objective_name.to_lower():
			return objective
	
	return null

func completeObjective(objective_name: String, outcome:int=0):
	for objective in OBJECTIVES:
		if objective.NAME == objective_name: objective.complete(outcome)
	
	for objective in OBJECTIVES:
		if objective.DEPENDENT != null and objective.DEPENDENT.COMPLETED and objective.DEPENDENT_OUTCOME == objective.DEPENDENT.OUTCOME and !objective.ACTIVE:
			objective.ACTIVE = true
			if objective.AUTO_COMPLETE: objective.COMPLETED = true
	
	isCompleted()

func isCompleted(show_prompt:bool=true):
	for objective in OBJECTIVES:
		if objective.FINAL_OBJECTIVE and objective.COMPLETED:
			COMPLETED = true
			if show_prompt:
				SaveLoadGlobals.saveGame(PlayerGlobals.SAVE_NAME)
				QuestGlobals.promptQuestCompleted(self)
			PlayerGlobals.addExperience(int(PlayerGlobals.getRequiredExp()*EXPERIENCE_REWARD), show_prompt, true)
			return COMPLETED

func _to_string():
	return "%s : %s" % [NAME, COMPLETED]
