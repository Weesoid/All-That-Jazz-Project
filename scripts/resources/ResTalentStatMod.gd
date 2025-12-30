extends ResTalent
class_name ResStatTalent

@export var stat_modifiers: ResStatChangeEffect

func getStatModifiers(rank:int):
	return stat_modifiers.getStatChanges(rank)

func getRichDescription()-> String:
	var d = ''
	if !description.is_empty():
		#d = SettingsGlobals.bb_line
		d += '[color=dim_gray]" %s "' % description
	return '%s\n%s%s' % [name.to_upper(), CombatGlobals.getBasicEffectsDescription([stat_modifiers]),d]
