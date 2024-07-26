extends Resource
class_name ResQuest

@export var NAME: String
@export var DESCRIPTION: String
@export var OBJECTIVES: Array[ResQuestObjective] = []
var COMPLETED: bool = false

func initializeQuest():
	print(OBJECTIVES)
	if !OBJECTIVES.is_empty():
		return
	
	var path = get_path().get_base_dir()+'/objectives'
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			OBJECTIVES.append(load(path+'/'+file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
		print(path)
	
	for objective in OBJECTIVES:
		objective.initializeObjective()
		objective.attemptEnable()

func getObjective(objective_name: String)-> ResQuestObjective:
	if !QuestGlobals.hasQuest(NAME):
		return null
		
	for objective in OBJECTIVES:
		if objective.NAME.to_lower() == objective_name.to_lower():
			return objective
	
	return null

func isCompleted(load_mode:bool=false):
	for objective in OBJECTIVES:
		objective.attemptEnable()
		if objective.END_OBJECTIVE and objective.FINISHED:
			COMPLETED = true
			if !load_mode:
				failRemainingObjectives()
				QuestGlobals.quest_completed.emit(self)
			return COMPLETED

func failRemainingObjectives():
	for objective in OBJECTIVES:
		if !objective.FINISHED and objective.ENABLED: 
			objective.FAILED = true
			objective.ENABLED = false

func _to_string():
	return "%s : %s" % [NAME, COMPLETED]
