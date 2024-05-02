extends ResEquippable
class_name ResUtilityCharm

@export var CHARM_SCRIPT: GDScript
var equipped = false

func equip(_combatant: ResCombatant):
	if PlayerGlobals.hasUtilityCharm() and PlayerGlobals.CURRENCY < 25:
		OverworldGlobals.getPlayer().prompt.showPrompt('A tribute of [color=yellow]25[/color] gold is required to change your charm.')
		return
	
	if PlayerGlobals.hasUtilityCharm() and PlayerGlobals.CURRENCY < 25:
		PlayerGlobals.CURRENCY -= 25
		PlayerGlobals.EQUIPPED_CHARM.CHARM_SCRIPT.unequip()
		PlayerGlobals.EQUIPPED_CHARM.equipped = false
		PlayerGlobals.EQUIPPED_CHARM = null
	
	equipped = true
	CHARM_SCRIPT.equip()
	PlayerGlobals.EQUIPPED_CHARM = self
	OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]25[/color] gold deducted. [color=yellow]%s[/color] equipped!' % NAME)

func unequip():
	if PlayerGlobals.EQUIPPED_CHARM != self and PlayerGlobals.CURRENCY < 25:
		OverworldGlobals.getPlayer().prompt.showPrompt('A tribute of 25 gold is required to change your charm.')
		return
	
	PlayerGlobals.CURRENCY -= 25
	equipped = false
	CHARM_SCRIPT.unequip()
	PlayerGlobals.EQUIPPED_CHARM = null
	OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]25[/color] gold deducted. [color=yellow]%s[/color] unequipped!' % NAME)

func isEquipped():
	return equipped
