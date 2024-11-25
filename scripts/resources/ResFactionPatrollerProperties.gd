extends Resource
class_name ResFactionPatrollerProperties

@export var faction: CombatGlobals.Enemy_Factions
@export var chaser: Dictionary = {
	'type': 0,
	'sprite_sheet': '', 
	'base_speed': 0.0, 
	'alerted_speed': 0.0, 
	'chase_speed': 0.0,
	'detection_time': 0.0
	}
@export var shooter: Dictionary = {
	'type': 1,
	'sprite_sheet': '', 
	'base_speed': 0.0, 
	'alerted_speed': 0.0, 
	'chase_speed': 0.0, 
	'detection_time': 0.0,
	'projectile': ''
	}
@export var hybrid: Dictionary = {
	'type': 2,
	'sprite_sheet': '', 
	'base_speed': 0.0, 
	'alerted_speed': 0.0, 
	'chase_speed': 0.0, 
	'detection_time': 0.0,
	'projectile': ''
	}

func getValidTypes(specials_only:bool=false)-> Array[int]:
	var specials: Array[int] = []
	if chaser['sprite_sheet'] != '' and !specials_only: specials.append(chaser['type'])
	if shooter['sprite_sheet'] != '': specials.append(shooter['type'])
	if hybrid['sprite_sheet'] != '': specials.append(hybrid['type'])
	return specials

func getType(type:int):
	match type:
		0: return chaser
		1: return shooter
		2: return hybrid
