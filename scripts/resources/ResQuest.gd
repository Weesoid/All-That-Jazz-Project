extends Resource
class_name ResQuest

@export var NAME: String
@export var DESCRIPTION: String
@export var OBJECTIVES: Array[ResQuestObjective]

var COMPLETED: bool = false

func initializeQuest():
	for objective in OBJECTIVES:
		objective.attemptEnable()

func getObjective(objective_name: String)-> ResQuestObjective:
	return OBJECTIVES.filter(func getObjectiveFromName(objective): return objective.NAME == objective_name)[0]

func _to_string():
	return "%s : %s" % [NAME, COMPLETED]

func isCompleted():
	for objective in OBJECTIVES:
		objective.checkComplete()
		objective.attemptEnable()
		if !objective.FINISHED: return false
	
	COMPLETED = true
	return COMPLETED
