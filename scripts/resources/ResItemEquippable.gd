extends ResItem
class_name ResEquippable

@export var STAT_MODIFICATIONS = {
	'health': 0,
	'brawn': 0.0,
	'grit': 0.0,
	'handling': 0,
	'hustle': 0,
	'accuracy': 0.0,
	'crit_mult': 0.0,
	'crit': 0.0,
	'heal_mult': 0.0,
	'resist': 0.0
}
var EQUIPPED_COMBATANT: ResCombatant

func equip(_combatant: ResCombatant):
	pass

func unequip():
	pass

func applyStatModifications():
	removeEmptyModifications()
	if STAT_MODIFICATIONS.is_empty() or !isEquipped(): return
	CombatGlobals.modifyStat(EQUIPPED_COMBATANT, STAT_MODIFICATIONS, NAME)

func removeStatModifications():
	removeEmptyModifications()
	if STAT_MODIFICATIONS.is_empty() or !isEquipped(): return
	CombatGlobals.resetStat(EQUIPPED_COMBATANT, NAME)

func removeEmptyModifications():
	var remove = []
	for stat in STAT_MODIFICATIONS.keys():
		if STAT_MODIFICATIONS[stat] == 0.0: remove.append(stat)
	for stat in remove:
		STAT_MODIFICATIONS.erase(stat)

func getStringStats():
	removeEmptyModifications()
	var result = ""
	for key in STAT_MODIFICATIONS.keys():
		var value = STAT_MODIFICATIONS[key]
		if value is float: 
			value *= 100.0
		if STAT_MODIFICATIONS[key] > 0 and STAT_MODIFICATIONS[key]:
			result += '[color=GREEN_YELLOW]'
			if value is float: 
				result += "+" + str(value) + "% " +key.to_upper().replace('_', ' ') + "\n"
			else:
				result += "+" + str(value) + " " +key.to_upper().replace('_', ' ') +  "\n"
		else:
			result += '[color=ORANGE_RED]'
			if value is float: 
				result += str(value) + "% " +key.to_upper().replace('_', ' ') +  "\n"
			else:
				result += str(value) + " " +key.to_upper().replace('_', ' ') + "\n"
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
