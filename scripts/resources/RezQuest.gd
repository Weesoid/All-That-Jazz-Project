extends Resource
class_name RezQuest

@export var NAME: String
@export var DESCRIPTION: String
@export var OBJECTIVES: Array[RezObjective]
@export var COMPLETED: bool = false

func getObjective(objective_name: String)-> RezObjective:
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
	
	isCompleted()

func isCompleted():
	for objective in OBJECTIVES:
		if objective.FINAL_OBJECTIVE and objective.COMPLETED:
			COMPLETED = true
			QuestGlobals.promptQuestCompleted(self)
			return COMPLETED

func _to_string():
	return "%s : %s" % [NAME, COMPLETED]
