extends ResEquippable
class_name ResCharm

@export var STATUS_EFFECT: ResStatusEffect

func equip(combatant: ResCombatant):
	if combatant is ResPlayerCombatant:
		if STATUS_EFFECT != null:
			STATUS_EFFECT = STATUS_EFFECT.duplicate()
		if EQUIPPED_COMBATANT != null:
			unequip()
	
	EQUIPPED_COMBATANT = combatant
	applyStatModifications()

func unequip():
	removeStatModifications()
	EQUIPPED_COMBATANT = null
