extends ResEquippable
class_name ResUtilityCharm

@export var CHARM_SCRIPT: GDScript
var equipped = false

func equip(combatant: ResCombatant):
	equipped = true
	CHARM_SCRIPT.equip()

func unequip():
	equipped = false
	CHARM_SCRIPT.unequip()

func isEquipped():
	return equipped
