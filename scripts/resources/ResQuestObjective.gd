extends Resource
class_name ResQuestObjective

@export var NAME: String
@export var DESCRIPTION: String
@export var DEPENDENTS: Array[ResQuestObjective]
@export var FAIL_OBJECTIVES: Array[ResQuestObjective]
@export var OR_DEPENDENTS: bool
@export var END_OBJECTIVE: bool

var ENABLED: bool
var FINISHED: bool = false
var FAILED: bool

# UGLY AND BAD, DESPERATE NEED FOR FIXING!!!
func initializeObjective():
	pass

func checkComplete():
	if FINISHED:
		PlayerGlobals.quest_objective_completed.emit(self)
	elif FAILED:
		PlayerGlobals.quest_objective_completed.emit(self)
	return FINISHED

func attemptEnable():
	if DEPENDENTS.is_empty() and !FAILED:
		ENABLED = true
	elif FAILED:
		ENABLED = false
	else:
		var objectives_finished = false
		if !OR_DEPENDENTS:
			var done = 0
			for objective in DEPENDENTS:
				if objective.FINISHED:
					done += 1
			objectives_finished = (done == DEPENDENTS.size())
		else:
			for objective in DEPENDENTS:
				if objective.FINISHED and objective.ENABLED:
					objectives_finished = true
					break
		ENABLED = objectives_finished
		
	failObjectives()

func failObjectives():
	if FAIL_OBJECTIVES.is_empty():
		return
	
	if ENABLED:
		for objective in FAIL_OBJECTIVES:
			objective.FAILED = true
			objective.ENABLED = false
