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
@export var SLOT: Slot
@export var STAT_MODIFICATIONS = {}
var EQUIPPED_COMBATANT: ResCombatant

func equip(combatant: ResCombatant):
	EQUIPPED_COMBATANT = combatant
	match SLOT:
		Slot.ARMOR: combatant.EQUIPMENT['armor'] = self
		Slot.CHARM: combatant.EQUIPMENT['charm'] = self

func getStatModifications():
	return STAT_MODIFICATIONS
