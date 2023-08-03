extends ResQuestObjective
class_name ResQuestObjectiveItem

@export var REQUIRED_ITEM: ResItem
@export var AMOUNT: int = 1

func initializeObjective():
	PlayerGlobals.added_item_to_inventory.connect(checkComplete)
	checkComplete()

func checkComplete():
	if REQUIRED_ITEM is ResStackItem:
		if PlayerGlobals.INVENTORY.has(REQUIRED_ITEM) and PlayerGlobals.getItemFromInventory(REQUIRED_ITEM).STACK >= AMOUNT:
			FINISHED = true
			PlayerGlobals.quest_objective_completed.emit()
	elif REQUIRED_ITEM is ResEquippable:
		if PlayerGlobals.getItemWithName(REQUIRED_ITEM.NAME) != null:
			FINISHED = true
			PlayerGlobals.quest_objective_completed.emit()
