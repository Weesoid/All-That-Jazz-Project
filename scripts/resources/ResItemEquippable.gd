extends ResItem
class_name ResEquippable

@export var stat_modifications = {
	'health': 0,
	'damage': 0,
	'handling': 0,
	'speed': 0,
	'crit_mult': 0.0,
	'crit': 0.0,
	'resist': 0.0
}

func equip(_combatant: ResCombatant):
	pass

func unequip(_combatant: ResCombatant):
	pass

#func applyStatModifications():
#	removeEmptyModifications()
#	if stat_modifications.is_empty() or !isEquipped(): return
#	CombatGlobals.modifyStat(equipped_combatant, stat_modifications, name)
#
#func removeStatModifications():
#	removeEmptyModifications()
#	if stat_modifications.is_empty() or !isEquipped(): return
#	CombatGlobals.resetStat(equipped_combatant, name)

#func removeEmptyModifications():
#	var remove = []
#	for stat in stat_modifications.keys():
#		if stat_modifications[stat] == 0.0: remove.append(stat)
#	for stat in remove:
#		stat_modifications.erase(stat)

func getStringStats():
	return CombatGlobals.getStatListString(stat_modifications)

#func isEquipped():
#	return equipped_combatant != null

func getStatModifications():
	return stat_modifications

func getInformation():
	var out = '[center]'+OverworldGlobals.insertTextureCode(icon)+' '+name.to_upper()+'[/center]\n'
	out += getStringStats()+"\n"
	out += description
	return out
