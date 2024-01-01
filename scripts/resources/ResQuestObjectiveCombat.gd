extends ResQuestObjective
class_name ResQuestObjectiveCombat

@export var UNIQUE_COMBAT_ID: String
@export var REQUIRE_WIN: bool = true
@export var COUNT: int = 1

var id
var objective_count = 0
var combat_result

func initializeObjective():
	CombatGlobals.combat_won.connect(setIDWin)
	CombatGlobals.combat_lost.connect(setIDLose)

func setIDLose(input_id):
	id = input_id
	combat_result = 0
	checkComplete()

func setIDWin(input_id):
	id = input_id
	combat_result = 1
	checkComplete()

func checkComplete():
	if UNIQUE_COMBAT_ID == id:
		if REQUIRE_WIN and combat_result == 1:
			objective_count += 1
		elif !REQUIRE_WIN:
			objective_count += 1
	
	if objective_count == COUNT:
		FINISHED = true
		QuestGlobals.quest_objective_completed.emit(self)
		CombatGlobals.combat_won.disconnect(setIDWin)
		CombatGlobals.combat_lost.disconnect(setIDLose)
