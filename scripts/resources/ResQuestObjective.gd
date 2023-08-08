extends Resource
class_name ResQuestObjective

@export var NAME: String
@export var DESCRIPTION: String
@export var DEPENDENT: Array[ResQuestObjective]
@export var FAIL_CONDITIONS: Array[ResQuestObjective]
@export var OR_DEPENDENTS: bool 
@export var OR_FAIL_CONDITIONS: bool 
@export var END_OBJECTIVE: bool

var ENABLED: bool
var FINISHED: bool = false
var FAILED: bool

# UGLY AND BAD, DESPERATE NEED FOR FIXING!!!
func initializeObjective():
	pass

func checkComplete():
	failObjectives()
	
	if FINISHED:
		PlayerGlobals.quest_objective_completed.emit()
	elif FAILED:
		PlayerGlobals.quest_objective_completed.emit()
	return FINISHED

func attemptEnable():
	#print('-----------------------------------------------------------')
	#print('Attempting to enable on: ', NAME)
	
	if DEPENDENT.is_empty():
		ENABLED = true
	else:
		var objectives_finished = true
		for objective in DEPENDENT:
	#		print('Checking ', objective.NAME)
			if !objective.FINISHED:
	#			print('This is objective not yet done!')
				objectives_finished = false
				break
		ENABLED = objectives_finished
	
	failObjectives()

func failObjectives():
	if FAIL_CONDITIONS.is_empty():
		return
	
	if ENABLED:
		print(NAME, ' is ENABLED! Failing objectives')
		for objective in FAIL_CONDITIONS:
			print('Failing: ', objective.NAME)
			objective.FAILED = true
			objective.ENABLED = false

