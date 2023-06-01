extends ResItem
class_name ResArmor

enum ArmorType {
	NONE, # 1
	LIGHT, # 2
	HEAVY # 3
}

enum Slot {
	ARMOR, # 1
	CHARM # 2
}

@export var ARMOR_TYPE: ArmorType
@export var STAT_MODIFICATIONS = {}

func getStatModifications():
	return STAT_MODIFICATIONS
