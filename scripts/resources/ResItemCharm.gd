extends ResEquippable
class_name ResCharm

@export var STATUS_EFFECT: ResStatusEffect

func updateItem():
	print(resource_path)
	print(PARENT_ITEM)
	NAME = PARENT_ITEM.NAME
	ICON = PARENT_ITEM.ICON
	DESCRIPTION = PARENT_ITEM.DESCRIPTION
	VALUE = PARENT_ITEM.VALUE
	MANDATORY = PARENT_ITEM.MANDATORY
	STAT_MODIFICATIONS = PARENT_ITEM.STAT_MODIFICATIONS
	STATUS_EFFECT = PARENT_ITEM.STATUS_EFFECT

func equip(combatant: ResCombatant):
	if isEquipped():
		unequip()
	
	EQUIPPED_COMBATANT = combatant
	if combatant is ResPlayerCombatant:
		if STATUS_EFFECT != null:
			STATUS_EFFECT = STATUS_EFFECT.duplicate()
	
	EQUIPPED_COMBATANT = combatant
	applyStatModifications()

func unequip():
	removeStatModifications()
	EQUIPPED_COMBATANT = null
