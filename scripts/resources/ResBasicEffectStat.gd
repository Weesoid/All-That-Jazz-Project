extends ResBasicEffect
class_name ResStatChangeEffect

@export var status_change = {
	'health': 0,
	'damage': 0,
	'defense': 0.0,
	'handling': 0,
	'speed': 0,
	'accuracy': 0.0,
	'crit_dmg': 0.0,
	'crit': 0.0,
	'heal_mult': 0.0,
	'resist': 0.0
}
@export var rank_scaling = true

func getStatChanges(current_rank: int=0):
	var out = {}
	for key in status_change.keys():
		if status_change[key] != 0: 
			out[key] = status_change[key]
			if current_rank != 0:
				out[key] *= current_rank
	return out
