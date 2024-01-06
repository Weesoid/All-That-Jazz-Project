extends ResEquippable
class_name ResArmor

@export var STATUS_EFFECT: ResStatusEffect # Remove this? Keep it charm specific?
@export var ARMOR_TYPE: ResArmorType

func equip(combatant: ResCombatant):
	if combatant is ResPlayerCombatant:
		if STATUS_EFFECT != null:
			STATUS_EFFECT = STATUS_EFFECT.duplicate()
		if EQUIPPED_COMBATANT != null:
			unequip()
	
	EQUIPPED_COMBATANT = combatant
	combatant.EQUIPMENT['armor'] = self
	applyStatModifications()

func unequip():
	removeStatModifications()
	EQUIPPED_COMBATANT.EQUIPMENT['armor'] = null
	EQUIPPED_COMBATANT = null
