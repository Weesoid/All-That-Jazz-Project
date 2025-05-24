extends Resource
class_name ResObjective

@export var NAME: String
@export_multiline var DESCRIPTION: String
@export var DEPENDENT: ResObjective
@export var DEPENDENT_OUTCOME: int
@export var FINAL_OBJECTIVE: bool
@export var AUTO_COMPLETE: bool

var ACTIVE: bool = false
var COMPLETED: bool = false
var OUTCOME: int

func complete(outcome:int=0):
	COMPLETED = true
	OUTCOME = outcome

func _to_string():
	return "%s > Dependent:%s/%s, Active:%s, Completed:%s, Final:%s" % [NAME, DEPENDENT.NAME, DEPENDENT_OUTCOME, ACTIVE, COMPLETED, FINAL_OBJECTIVE]
