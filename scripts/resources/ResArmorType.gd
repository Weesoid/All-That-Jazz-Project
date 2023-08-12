extends Resource
class_name ResArmorType

@export var NAME: String
@export var DEFAULT_MULTIPLIER = 1.0
@export var MULTIPLIERS: Dictionary

func getMultiplier(damage_type: ResDamageType)-> float:
	if !MULTIPLIERS.has(damage_type):
		return DEFAULT_MULTIPLIER
		#print('Resisted!')
	return MULTIPLIERS[damage_type]
