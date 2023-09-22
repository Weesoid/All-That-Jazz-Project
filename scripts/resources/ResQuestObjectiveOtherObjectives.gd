extends ResQuestObjective
class_name ResQuestObjectiveOtherObjectives

@export var QUEST: ResQuest
@export var REQUIRED_OBJECTIVE: ResQuestObjective

func initializeObjective():
	#assert(QUEST.getObjective(REQUIRED_OBJECTIVE.NAME) != null, "Objective %s does not exist in Quest %s" % [REQUIRED_OBJECTIVE.NAME, QUEST.NAME])
	ENABLED = false
	PlayerGlobals.quest_added.connect(attemptEnable)
	PlayerGlobals.quest_objective_completed.connect(checkObjective)
	checkComplete()

func attemptEnable():
	if PlayerGlobals.isQuestObjectiveEnabled(QUEST.NAME, REQUIRED_OBJECTIVE.NAME):
		ENABLED = true
	elif PlayerGlobals.isQuestObjectiveCompleted(QUEST.NAME, REQUIRED_OBJECTIVE.NAME):
		ENABLED = true
	
	failObjectives()

func checkObjective(_objective: ResQuestObjective):
	checkComplete()

func checkComplete():
	attemptEnable()
	
	if PlayerGlobals.isQuestObjectiveCompleted(QUEST.NAME, REQUIRED_OBJECTIVE.NAME):
		FINISHED = true
		if PlayerGlobals.quest_objective_completed.is_connected(checkComplete):
			PlayerGlobals.quest_objective_completed.disconnect(checkComplete)
		if PlayerGlobals.quest_objective_completed.is_connected(checkObjective):
			PlayerGlobals.quest_objective_completed.disconnect(checkObjective)
		PlayerGlobals.quest_objective_completed.emit(self)
		PlayerGlobals.quest_added.disconnect(attemptEnable)
	elif PlayerGlobals.isQuestObjectiveFailed(QUEST.NAME, REQUIRED_OBJECTIVE.NAME):
		FAILED = true
		ENABLED = false
		if PlayerGlobals.quest_objective_completed.is_connected(checkComplete):
			PlayerGlobals.quest_objective_completed.disconnect(checkComplete)
		if PlayerGlobals.quest_objective_completed.is_connected(checkObjective):
			PlayerGlobals.quest_objective_completed.disconnect(checkObjective)
		PlayerGlobals.quest_objective_completed.emit(self)
		PlayerGlobals.quest_added.disconnect(attemptEnable)
