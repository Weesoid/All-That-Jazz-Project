extends ResItem
class_name ResEquippable

@export var STAT_MODIFICATIONS = {}
var EQUIPPED_COMBATANT: ResCombatant

func equip(_combatant: ResCombatant):
	pass

func unequip():
	pass

func applyStatModifications():
	if STAT_MODIFICATIONS.is_empty() or !isEquipped(): return
	CombatGlobals.modifyStat(EQUIPPED_COMBATANT, STAT_MODIFICATIONS, NAME)

func removeStatModifications():
	if STAT_MODIFICATIONS.is_empty() or !isEquipped(): return
	CombatGlobals.resetStat(EQUIPPED_COMBATANT, NAME)

func getStringStats():
	var result = ""
	for key in STAT_MODIFICATIONS.keys():
		var value = STAT_MODIFICATIONS[key]
		if value is float: 
			value *= 100.0
		if STAT_MODIFICATIONS[key] > 0 and STAT_MODIFICATIONS[key]:
			result += '[color=GREEN_YELLOW]'
			if value is float: 
				result += "+" + str(value) + "% " +key.to_upper() + "\n"
			else:
				result += "+" + str(value) + " " +key.to_upper() +  "\n"
		else:
			result += '[color=ORANGE_RED]'
			if value is float: 
				result += str(value) + "% " +key.to_upper() +  "\n"
			else:
				result += str(value) + " " +key.to_upper() + "\n"
		result += '[/color]'
	return result

func isEquipped():
	return EQUIPPED_COMBATANT != null

func getStatModifications():
	return STAT_MODIFICATIONS

func getInformation():
	var out = OverworldGlobals.insertTextureCode(ICON)+' '+NAME.to_upper()+'\n'
	out += getStringStats()+"\n"
	out += DESCRIPTION
	return out
