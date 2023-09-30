extends ResEquippable
class_name ResWeapon

@export var EFFECT: ResAbility
@export var max_durability = 100
@export var durability: int = max_durability

func equip(combatant: ResCombatant):
	if combatant is ResPlayerCombatant:
		print(durability)
		print(EQUIPPED_COMBATANT)
		if EQUIPPED_COMBATANT != null or max_durability <= 0:
			unequip()
		if combatant.EQUIPMENT['weapon'] != null:
			combatant.EQUIPMENT['weapon'].unequip()
	
	EQUIPPED_COMBATANT = combatant
	combatant.EQUIPMENT['weapon'] = self
	combatant.ABILITY_SET[0] = EFFECT
	applyStatModifications()

func unequip():
	removeStatModifications()
	EQUIPPED_COMBATANT.ABILITY_SET[0] = load("res://resources/abilities/Punch.tres")
	EQUIPPED_COMBATANT.EQUIPMENT['weapon'] = null
	EQUIPPED_COMBATANT = null

func useDurability():
	durability -= 1
	if durability <= 0:
		durability = 0
		unequip()

func restoreDurability(amount: int):
	if (durability + amount) > max_durability:
		durability = max_durability
	else:
		durability += amount
	
	if durability == max_durability:
		OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] fully repaired.' % NAME)

func getInformation():
	var out = ""
	out += "W: %s V: %s\n\n" % [WEIGHT, VALUE]
	out += 'D: %s / %s\n\n' % [durability, max_durability]
	out += getStringStats()+"\n\n"
	out += DESCRIPTION
	return out
