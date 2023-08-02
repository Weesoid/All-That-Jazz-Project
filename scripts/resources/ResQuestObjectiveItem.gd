extends ResQuestObjective
class_name ResQuestObjectiveItem

@export var REQUIRED_ITEM: ResItem
@export var AMOUNT: int = 1

func checkComplete():
	if REQUIRED_ITEM is ResStackItem:
		if PlayerGlobals.INVENTORY.has(REQUIRED_ITEM) and PlayerGlobals.getItemFromInventory(REQUIRED_ITEM).STACK >= AMOUNT:
			FINISHED = true
	elif REQUIRED_ITEM is ResEquippable:
		if PlayerGlobals.getItemWithName(REQUIRED_ITEM.NAME) != null:
			FINISHED = true
