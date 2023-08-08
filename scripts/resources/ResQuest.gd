extends Resource
class_name ResQuest

@export var NAME: String
@export var DESCRIPTION: String
@export var OBJECTIVES: Array[ResQuestObjective]

var COMPLETED: bool = false

func initializeQuest():
	for objective in OBJECTIVES:
		objective.initializeObjective()
		objective.attemptEnable()

func getObjective(objective_name: String)-> ResQuestObjective:
	if !PlayerGlobals.hasQuest(NAME):
		return null
	
	return OBJECTIVES.filter(func getObjectiveFromName(objective): return objective.NAME == objective_name)[0]

func getCurrentObjective()-> ResQuestObjective:
	for objective in OBJECTIVES:
		if !objective.FINISHED and objective.ENABLED:
			return objective
	
	return null

func isCompleted():
	for objective in OBJECTIVES:
		objective.attemptEnable()
		if objective.END_OBJECTIVE and objective.FINISHED:
			COMPLETED = true
			failRemainingObjectives()
			PlayerGlobals.quest_completed.emit(self)
			return COMPLETED

func failRemainingObjectives():
	for objective in OBJECTIVES:
		if !objective.FINISHED and objective.ENABLED: 
			objective.FAILED = true
			objective.ENABLED = false

func _to_string():
	return "%s : %s" % [NAME, COMPLETED]
