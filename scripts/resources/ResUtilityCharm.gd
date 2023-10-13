extends ResEquippable
class_name ResUtilityCharm

@export var CHARM_SCRIPT: GDScript
var equipped = false

func equip(_combatant: ResCombatant):
	if PlayerGlobals.UTILITY_CHARM_COUNT >= 3:
		OverworldGlobals.getPlayer().prompt.showPrompt('Max [color=yelloe]Charm[/color] capacity reached. Unequip a [color=yellow]Charm[/color].')
		return
	
	equipped = true
	CHARM_SCRIPT.equip()
	PlayerGlobals.UTILITY_CHARM_COUNT += 1

func unequip():
	equipped = false
	CHARM_SCRIPT.unequip()
	PlayerGlobals.UTILITY_CHARM_COUNT -= 1

func isEquipped():
	return equipped
