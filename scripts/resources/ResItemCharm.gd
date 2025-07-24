extends ResEquippable
class_name ResCharm

@export var status_effect: ResStatusEffect
@export var unique: bool = false

func updateItem():
	if !FileAccess.file_exists(parent_item):
		InventoryGlobals.removeItemResource(self)
		return
	
	var parent_item = load(parent_item)
	name = parent_item.name
	icon = parent_item.icon
	description = parent_item.description
	value = parent_item.value
	mandatory = parent_item.mandatory
	stat_modifications = parent_item.stat_modifications
	status_effect = parent_item.status_effect

func equip(combatant: ResCombatant):
	if isEquipped():
		unequip()
	
	equipped_combatant = combatant
	if combatant is ResPlayerCombatant:
		if status_effect != null:
			status_effect = status_effect.duplicate()
	
	equipped_combatant = combatant
	applyStatModifications()

func unequip():
	removeStatModifications()
	equipped_combatant = null

func canEquip(combatant: ResPlayerCombatant)-> bool:
	return !combatant.hasCharm(self)
