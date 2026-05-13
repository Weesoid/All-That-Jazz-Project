extends ResAbilityEffect
class_name ResStatModifierEffect

enum DurationType {
	TURNS,
	BATTLE
}

@export var stat_modifications: = {
	'health': 0,
	'damage': 0,
	'handling': 0,
	'speed': 0,
	'crit': 0.0,
	'resist': 0.0,
	'dmg_variance': 0.0,
	'resolve': 0
}
@export var duration_type: DurationType= DurationType.TURNS
@export var duration:int=1
@export var stacks: bool=false

func getModifications()-> Dictionary:
	var out={}
	for stat in stat_modifications:
		if stat_modifications[stat] == 0.0:
			continue
		
		out[stat] = stat_modifications[stat]
	
	return out

func _to_string():
	var out = stringifyCondition()
	if out != '':
		out += '\n'
	out += CombatGlobals.getStatListString(stat_modifications)
	out += str(duration)
	
	if duration_type == DurationType.TURNS: 
		out += ' Turns'
	elif duration_type == DurationType.BATTLE: 
		out += ' Battles'
	
	if stacks:
		out += ' (Stacks)'
	
	
	return out
