extends Resource
class_name ResQuestObjective

@export var NAME: String
@export var DESCRIPTION: String
@export var DEPENDENT: ResQuestObjective
 
var ENABLED: bool
var FINISHED: bool = false

func checkComplete():
	return FINISHED

func attemptEnable():
	if DEPENDENT == null or DEPENDENT.FINISHED == true:
		ENABLED = true
	else:
		ENABLED = false
