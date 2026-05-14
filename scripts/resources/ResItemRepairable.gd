extends Resource
class_name RepairableItem

static func useDurability(item:ResItem):
	item.durability -= 1
	if item.durability <= 0:
		item.durability = 0
	print('emittance')
	InventoryGlobals.item_used.emit(item)

static func repair(item:ResItem, repair_amount: int):
	if !canRepair(item, repair_amount):
		return
	
	item.durability = min(item.durability+repair_amount,item.max_durability)
	InventoryGlobals.removeItemResource(item.repair_item,item.repair_cost*repair_amount)
	InventoryGlobals.item_repaired.emit(item, item.durability)

static func canRepair(item:ResItem,repair_amount:int):
	return InventoryGlobals.hasItem(item.repair_item, item.repair_cost*repair_amount) and item.durability != item.max_durability

static func isBroken(item:ResItem):
	return item.durability < 1
