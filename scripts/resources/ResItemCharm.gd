extends ResEquippable
class_name ResCharm

@export var status_effect: ResStatusEffect
@export var unique: bool = false

func updateItem():
	if !FileAccess.file_exists(parent_item):
		InventoryGlobals.inventory.erase(self)
	var updated_item = load(parent_item)
	name = updated_item.name
	icon = updated_item.icon
	description = updated_item.description
	value = updated_item.value
	mandatory = updated_item.mandatory
	stat_modifications = updated_item.stat_modifications
	status_effect = updated_item.status_effect

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
