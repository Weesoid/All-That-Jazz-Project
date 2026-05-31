extends ResAttackBonus
class_name ResAttackBonusStatModifiers

@export var stat_modifiers: Dictionary = CombatExtras.ALL_STATS
@export var duration:int=1
@export var per_battle:bool=false
@export var stacks:bool=false
@export var resistable:bool=true

func getAttackEffect():
	return {'stat_modifiers': self}

func _to_string():
	var out = CombatGlobals.getStatListString(stat_modifiers,true).replace('\n',', ')
	out = out.trim_suffix(', [/color]')
	out += '[/color]'
	out +=  ' (%s %s)' % [str(duration), 'Turns' if !per_battle else 'Battles']
	out += ' (Stacks)' if stacks else ''
	return  target_text+out+getStringCondition()
