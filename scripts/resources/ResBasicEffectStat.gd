extends ResBasicEffect
class_name ResStatChangeEffect

@export var status_change = {
	'health': 0,
	'damage': 0,
	'handling': 0,
	'speed': 0,
	'crit': 0.0,
	'resist': 0.0
}
#@export var rank_scaling = true

func getStatChanges(multiplier: int=1):
	var out = {}
	for key in status_change.keys():
		if status_change[key] != 0: 
			out[key] = status_change[key]
			if multiplier != 0:
				out[key] *= multiplier
	return out

func _to_string():
	return CombatGlobals.getStatListString(getStatChanges())
