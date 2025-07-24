extends Resource
class_name ResObjective

@export var name: String
@export_multiline var description: String
@export var dependent: ResObjective
@export var dependent_outcome: int
@export var final_objective: bool
@export var auto_complete: bool

var active: bool = false
var completed: bool = false
var outcome: int

func complete(outcome:int=0):
	completed = true
	outcome = outcome

func _to_string():
	return "%s > Dependent:%s/%s, Active:%s, Completed:%s, Final:%s" % [name, dependent.name, dependent_outcome, active, completed, final_objective]
