extends Resource
class_name RezObjective

@export var NAME: String
@export var DESCRIPTION: String
@export var DEPENDENT: RezObjective
@export var DEPENDENT_OUTCOME: int
@export var FINAL_OBJECTIVE: bool
var ACTIVE: bool = false
var COMPLETED: bool = false
var OUTCOME: int

func complete(outcome:int=0):
	COMPLETED = true
	OUTCOME = outcome
