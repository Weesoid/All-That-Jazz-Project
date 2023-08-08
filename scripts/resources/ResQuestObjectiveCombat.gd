extends ResQuestObjective
class_name ResQuestObjectiveCombat

@export var UNIQUE_COMBAT_ID: String
@export var REQUIRE_WIN: bool = true

var id
var combat_result

func initializeObjective():
	PlayerGlobals.combat_won.connect(
		func setID(input_id): 
			id = input_id
			combat_result = 1
			checkComplete()
			)
	PlayerGlobals.combat_lost.connect(
		func setID(input_id): 
			id = input_id
			combat_result = 0
			checkComplete()
			)

func checkComplete():
	if UNIQUE_COMBAT_ID == id:
		if REQUIRE_WIN and combat_result == 1:
			FINISHED = true
			PlayerGlobals.quest_objective_completed.emit()
		elif !REQUIRE_WIN:
			FINISHED = true
			PlayerGlobals.quest_objective_completed.emit()
