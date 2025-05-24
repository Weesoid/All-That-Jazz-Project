extends Resource
class_name ResBlessing

@export var blessing_name: String
@export_multiline var description: String
@export var ow_stat_modifications: Dictionary = {
	'stamina': 0.0,
	'bow_max_draw': 0.0,
	'walk_speed': 0.0,
	'sprint_speed': 0.0,
	'sprint_drain': 0.0,
	'stamina_gain': 0.0
}

func setBlessing(apply:bool):
	for key in ow_stat_modifications.keys():
		if ow_stat_modifications[key] != 0 and apply: 
			PlayerGlobals.overworld_stats[key] += ow_stat_modifications[key]
		elif ow_stat_modifications[key] != 0 and !apply: 
			PlayerGlobals.overworld_stats[key] -= ow_stat_modifications[key]
