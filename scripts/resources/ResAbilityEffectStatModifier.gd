extends ResAbilityEffect
class_name ResStatModifierEffect

enum DurationType {
	TURNS,
	BATTLE
}

@export var stat_modifications: = {
	'health': 0,
	'damage': 0,
	'defense': 0.0,
	'handling': 0,
	'speed': 0,
	'accuracy': 0.0,
	'crit': 0.0,
	'crit_dmg': 0.0,
	'heal_mult': 0.0,
	'resist': 0.0,
	'dmg_variance': 0.0,
	'dmg_modifier': 0.0,
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
	return CombatGlobals.getStatListString(stat_modifications)
