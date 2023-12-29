extends ResQuestObjective
class_name ResQuestObjectiveOtherObjectives

@export var QUEST: ResQuest
@export var REQUIRED_OBJECTIVE: ResQuestObjective

func initializeObjective():
	#assert(QUEST.getObjective(REQUIRED_OBJECTIVE.NAME) != null, "Objective %s does not exist in Quest %s" % [REQUIRED_OBJECTIVE.NAME, QUEST.NAME])
	ENABLED = false
	QuestGlobals.quest_added.connect(attemptEnable)
	QuestGlobals.quest_objective_completed.connect(checkObjective)
	checkComplete()

func attemptEnable():
	if QuestGlobals.isQuestObjectiveEnabled(QUEST.NAME, REQUIRED_OBJECTIVE.NAME):
		ENABLED = true
	elif QuestGlobals.isQuestObjectiveCompleted(QUEST.NAME, REQUIRED_OBJECTIVE.NAME):
		ENABLED = true
	
	failObjectives()

func checkObjective(_objective: ResQuestObjective):
	checkComplete()

func checkComplete():
	attemptEnable()
	
	if QuestGlobals.isQuestObjectiveCompleted(QUEST.NAME, REQUIRED_OBJECTIVE.NAME):
		FINISHED = true
		if QuestGlobals.quest_objective_completed.is_connected(checkComplete):
			QuestGlobals.quest_objective_completed.disconnect(checkComplete)
		if QuestGlobals.quest_objective_completed.is_connected(checkObjective):
			QuestGlobals.quest_objective_completed.disconnect(checkObjective)
		QuestGlobals.quest_objective_completed.emit(self)
		QuestGlobals.quest_added.disconnect(attemptEnable)
	elif QuestGlobals.isQuestObjectiveFailed(QUEST.NAME, REQUIRED_OBJECTIVE.NAME):
		FAILED = true
		ENABLED = false
		if QuestGlobals.quest_objective_completed.is_connected(checkComplete):
			QuestGlobals.quest_objective_completed.disconnect(checkComplete)
		if QuestGlobals.quest_objective_completed.is_connected(checkObjective):
			QuestGlobals.quest_objective_completed.disconnect(checkObjective)
		QuestGlobals.quest_objective_completed.emit(self)
		QuestGlobals.quest_added.disconnect(attemptEnable)
