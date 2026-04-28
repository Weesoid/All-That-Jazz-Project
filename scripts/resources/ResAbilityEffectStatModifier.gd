extends ResAbilityEffect
class_name ResStatModifierEffect

enum DurationType {
	TEMPORARY,
	PERMANENT
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
@export var duration_type: DurationType= DurationType.TEMPORARY
@export var duration:int
