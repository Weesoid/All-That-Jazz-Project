extends ResQuestObjective
class_name ResQuestObjectiveItem

@export var REQUIRED_ITEM: ResItem
@export var AMOUNT: int = 1

func initializeObjective():
	InventoryGlobals.added_item_to_inventory.connect(checkComplete)
	checkComplete()

func checkComplete():
	if REQUIRED_ITEM is ResStackItem:
		if InventoryGlobals.INVENTORY.has(REQUIRED_ITEM) and InventoryGlobals.getItem(REQUIRED_ITEM).STACK >= AMOUNT:
			FINISHED = true
			QuestGlobals.quest_objective_completed.emit(self)
			InventoryGlobals.added_item_to_inventory.disconnect(checkComplete)
	elif REQUIRED_ITEM is ResEquippable:
		if InventoryGlobals.getItemWithName(REQUIRED_ITEM.NAME) != null:
			FINISHED = true
			QuestGlobals.quest_objective_completed.emit(self)
			InventoryGlobals.added_item_to_inventory.disconnect(checkComplete)

func disconnectSignals():
	if InventoryGlobals.added_item_to_inventory.is_connected(checkComplete):
		InventoryGlobals.added_item_to_inventory.disconnect(checkComplete)
