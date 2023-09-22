extends ResQuestObjective
class_name ResQuestObjectiveQuest

@export var REQUIRED_QUEST: ResQuest
var quest_completed

func initializeObjective():
	PlayerGlobals.quest_completed.connect(
		func setID(quest): 
			quest_completed = quest
			checkComplete()
			)
	
	checkCompletedQuests()

func checkComplete():
	if quest_completed == REQUIRED_QUEST:
		FINISHED = true
		PlayerGlobals.quest_objective_completed.emit(self)

func checkCompletedQuests():
	for quest in PlayerGlobals.QUESTS:
		if quest == REQUIRED_QUEST and quest.COMPLETED:
			FINISHED = true
			PlayerGlobals.quest_objective_completed.emit(self)
			return
