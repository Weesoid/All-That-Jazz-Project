extends ResQuestObjective
class_name ResQuestObjectiveQuest

@export var REQUIRED_QUEST: ResQuest
var quest_completed

func initializeObjective():
	QuestGlobals.quest_completed.connect(setID)
	checkCompletedQuests()

func setID(quest):
	quest_completed = quest
	checkComplete()

func checkComplete():
	if quest_completed == REQUIRED_QUEST:
		FINISHED = true
		QuestGlobals.quest_objective_completed.emit(self)
		QuestGlobals.quest_completed.disconnect(setID)

func checkCompletedQuests():
	for quest in QuestGlobals.QUESTS:
		if quest == REQUIRED_QUEST and quest.COMPLETED:
			FINISHED = true
			QuestGlobals.quest_objective_completed.emit(self)
			QuestGlobals.quest_completed.disconnect(setID)
			return

func disconnectSignals():
	QuestGlobals.quest_completed.disconnect(setID)
