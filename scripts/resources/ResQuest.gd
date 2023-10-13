extends Resource
class_name ResQuest

@export var NAME: String
@export var DESCRIPTION: String
var OBJECTIVES: Array[ResQuestObjective] = []

var COMPLETED: bool = false

func initializeQuest():
	var path = get_path().get_base_dir()+'/objectives'
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			print("Found file: " + file_name)
			OBJECTIVES.append(load(path+'/'+file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		print(path)
	
	for objective in OBJECTIVES:
		objective.initializeObjective()
		objective.attemptEnable()

func getObjective(objective_name: String)-> ResQuestObjective:
	if !PlayerGlobals.hasQuest(NAME):
		return null
	
	for objective in OBJECTIVES:
		if objective.NAME == objective_name:
			return objective
	
	return null

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
