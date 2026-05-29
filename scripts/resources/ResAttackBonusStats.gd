extends ResAttackBonus
class_name ResAttackStats

@export var stats:Dictionary= CombatExtras.ALL_STATS

func getAttackEffect():
	return CombatGlobals.getStatChanges(stats)

func _to_string():
	#print()
	var out = CombatGlobals.getStatListString(stats)#.replace('\n',', ')
	#print(out)
	#out = out.replace('[/color]\n','[/color]')
	#out += '[/color]'
	return out+(getStringCondition().trim_prefix('\n'))
