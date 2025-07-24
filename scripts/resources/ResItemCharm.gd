extends ResEquippable
class_name ResCharm

@export var STATUS_EFFECT: ResStatusEffect
@export var UNIQUE: bool = false

func updateItem():
	if !FileAccess.file_exists(PARENT_ITEM):
		InventoryGlobals.removeItemResource(self)
		return
	
	var parent_item = load(PARENT_ITEM)
	NAME = parent_item.NAME
	icon = parent_item.icon
	DESCRIPTION = parent_item.DESCRIPTION
	VALUE = parent_item.VALUE
	MANDATORY = parent_item.MANDATORY
	STAT_MODIFICATIONS = parent_item.STAT_MODIFICATIONS
	STATUS_EFFECT = parent_item.STATUS_EFFECT

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

func canEquip(combatant: ResPlayerCombatant)-> bool:
	return !combatant.hasCharm(self)
