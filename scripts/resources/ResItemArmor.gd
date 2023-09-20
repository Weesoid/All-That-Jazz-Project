extends ResEquippable
class_name ResArmor

# REFACTOR THIS
enum Slot {
	ARMOR, # 1
	CHARM # 2
}

@export var STATUS_EFFECT: ResStatusEffect # Remove this? Keep it charm specific?
@export var ARMOR_TYPE: ResArmorType
@export var SLOT: Slot

func equip(combatant: ResCombatant):
	print('Equipping on: ', combatant.NAME)
	if combatant is ResPlayerCombatant:
		if STATUS_EFFECT != null:
			STATUS_EFFECT = STATUS_EFFECT.duplicate()
		if EQUIPPED_COMBATANT != null:
			unequip()
		if combatant.EQUIPMENT[slotToString()]:
			combatant.EQUIPMENT[slotToString()].unequip()
	
	EQUIPPED_COMBATANT = combatant
	EQUIPPED_COMBATANT.EQUIPMENT[slotToString()] = self
	applyStatModifications()

func unequip():
	removeStatModifications()
	EQUIPPED_COMBATANT.EQUIPMENT[slotToString()] = null
	EQUIPPED_COMBATANT = null

func slotToString():
	if SLOT == Slot.ARMOR:
		return "armor"
	elif SLOT == Slot.CHARM:
		return "charm"
