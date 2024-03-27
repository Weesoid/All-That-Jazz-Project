extends ResItem
class_name ResWeapon

@export var EFFECT: ResAbility
@export var USE_REQUIREMENT: Dictionary = {
	'handling': 1
}
@export var max_durability = 100
var durability: int = max_durability

func useDurability():
	durability -= 1
	if durability <= 0:
		durability = 0

func restoreDurability(amount: int):
	if (durability + amount) > max_durability:
		durability = max_durability
	else:
		durability += amount
	
	if durability == max_durability:
		OverworldGlobals.getPlayer().prompt.showPrompt('[color=yellow]%s[/color] fully repaired.' % NAME)

func canUse(combatant: ResCombatant):
	for stat in USE_REQUIREMENT.keys():
		if USE_REQUIREMENT[stat] > combatant.BASE_STAT_VALUES[stat]:
			return false
	
	return true

func getInformation():
	var out = ""
	out += "W: %s V: %s\n" % [WEIGHT, VALUE]
	out += 'D: %s / %s\n\n' % [durability, max_durability]
	out += DESCRIPTION
	return out
