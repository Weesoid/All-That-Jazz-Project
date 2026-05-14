extends ResEquippable
class_name ResCharm

@export var status_effect: ResStatusEffect
@export var unique: bool = false

#func updateItem():
#	if !FileAccess.file_exists(resource_path):
#		InventoryGlobals.inventory.erase(self)
#	var updated_item = load(parent_item)
#	name = updated_item.name
#	icon = updated_item.icon
#	description = updated_item.description
#	value = updated_item.value
#	mandatory = updated_item.mandatory
#	stat_modifications = updated_item.stat_modifications
#	status_effect = updated_item.status_effect

func equip(combatant: ResCombatant):
	CombatGlobals.modifyStat(combatant, stat_modifications, name)

func unequip(combatant: ResCombatant):
	CombatGlobals.resetStat(combatant,name)

func canEquip(combatant: ResPlayerCombatant)-> bool:
	return !combatant.hasCharm(self)
