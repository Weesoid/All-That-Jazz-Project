extends ResEquippable
class_name ResCharm

@export var STATUS_EFFECT: ResStatusEffect

func equip(combatant: ResCombatant):
	if isEquipped():
		unequip()
	
	EQUIPPED_COMBATANT = combatant
	if combatant is ResPlayerCombatant:
		if STATUS_EFFECT != null:
			STATUS_EFFECT = STATUS_EFFECT.duplicate()
		if EQUIPPED_COMBATANT.CHARMS.size() >= 3:
			OverworldGlobals.getPlayer().prompt.showPrompt('Max [color=yelloe]Charm[/color] capacity reached. Unequip a [color=yellow]Charm[/color].')
			EQUIPPED_COMBATANT = null
			return
	
	EQUIPPED_COMBATANT = combatant
	EQUIPPED_COMBATANT.CHARMS.append(self)
	applyStatModifications()

func unequip():
	removeStatModifications()
	EQUIPPED_COMBATANT.CHARMS.erase(self)
	EQUIPPED_COMBATANT = null
