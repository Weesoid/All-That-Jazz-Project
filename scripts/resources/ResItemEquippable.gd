extends ResItem
class_name ResEquippable

@export var stat_modifications = {
	'health': 0,
	'damage': 0,
	'defense': 0.0,
	'handling': 0,
	'speed': 0,
	'accuracy': 0.0,
	'crit_mult': 0.0,
	'crit': 0.0,
	'heal_mult': 0.0,
	'resist': 0.0
}
var equipped_combatant: ResCombatant

func equip(_combatant: ResCombatant):
	pass

func unequip():
	pass

func applyStatModifications():
	removeEmptyModifications()
	if stat_modifications.is_empty() or !isEquipped(): return
	CombatGlobals.modifyStat(equipped_combatant, stat_modifications, name)

func removeStatModifications():
	removeEmptyModifications()
	if stat_modifications.is_empty() or !isEquipped(): return
	CombatGlobals.resetStat(equipped_combatant, name)

func removeEmptyModifications():
	var remove = []
	for stat in stat_modifications.keys():
		if stat_modifications[stat] == 0.0: remove.append(stat)
	for stat in remove:
		stat_modifications.erase(stat)

func getStringStats():
	removeEmptyModifications()
	var result = ""
	for key in stat_modifications.keys():
		var val = stat_modifications[key]
		if val is float: 
			val *= 100.0
		if stat_modifications[key] > 0 and stat_modifications[key]:
			result += '[color=GREEN_YELLOW]'
			if val is float: 
				result += "+" + str(val) + "% " +key.to_upper().replace('_', ' ') + "\n"
			else:
				result += "+" + str(val) + " " +key.to_upper().replace('_', ' ') +  "\n"
		else:
			result += '[color=ORANGE_RED]'
			if val is float: 
				result += str(val) + "% " +key.to_upper().replace('_', ' ') +  "\n"
			else:
				result += str(val) + " " +key.to_upper().replace('_', ' ') + "\n"
		result += '[/color]'
	return result

func isEquipped():
	return equipped_combatant != null

func getStatModifications():
	return stat_modifications

func getInformation():
	var out = OverworldGlobals.insertTextureCode(icon)+' '+name.to_upper()+'\n'
	out += getStringStats()+"\n"
	out += description
	return out
