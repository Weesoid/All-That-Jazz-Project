extends Resource
class_name ResArmorType

@export var NAME: String
@export var DEFAULT_MULTIPLIER = 1.0
@export var MULTIPLIERS: Dictionary

func getMultiplier(damage_type: ResDamageType)-> float:
	if !MULTIPLIERS.has(damage_type): 
		print('Neutral!')
		return DEFAULT_MULTIPLIER
	if MULTIPLIERS[damage_type] > 1.0:
		print('Effective!')
	else:
		print('Resisted!')
	return MULTIPLIERS[damage_type]
