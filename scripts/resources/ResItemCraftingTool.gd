extends ResItem
class_name ResCraftingTool

@export var max_durability:int=1
@export var repair_item: ResItem
@export var repair_cost = 1
var durability:int

func useDurability():
	RepairableItem.useDurability(self)
	#combatant.file_references['equipped_weapon'][1] = durability

func repair(repair_amount: int):
	RepairableItem.repair(self, repair_amount)

func canRepair(repair_amount:int):
	return RepairableItem.canRepair(self, repair_amount)

func isBroken():
	return RepairableItem.isBroken(self)
