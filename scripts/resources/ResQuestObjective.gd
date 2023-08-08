extends Resource
class_name ResQuestObjective

@export var NAME: String
@export var DESCRIPTION: String
@export var DEPENDENT: Array[ResQuestObjective]
@export var FAIL_CONDITIONS: Array[ResQuestObjective]
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
		PlayerGlobals.quest_objective_completed.emit()
	elif FAILED:
		PlayerGlobals.quest_objective_completed.emit()
	return FINISHED

func attemptEnable():
	if DEPENDENT.is_empty():
		ENABLED = true
	else:
		var objectives_finished = false
		if !OR_DEPENDENTS:
			var done = 0
			for objective in DEPENDENT:
				if objective.FINISHED:
					done += 1
			print(NAME, ' passed all reqs!')
			objectives_finished = (done == DEPENDENT.size())
		else:
			for objective in DEPENDENT:
				if objective.FINISHED and objective.ENABLED:
					objectives_finished = true
					break
		ENABLED = objectives_finished
	
	failObjectives()

func failObjectives():
	if FAIL_CONDITIONS.is_empty():
		return
	
	if ENABLED:
		for objective in FAIL_CONDITIONS:
			objective.FAILED = true
			objective.ENABLED = false
