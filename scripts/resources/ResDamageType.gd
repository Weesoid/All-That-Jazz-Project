extends Resource
class_name ResDamageType

@export var NAME: String
@export var EFFECT: ResStatusEffect
@export var EFFECT_CHANCE: float

func rollEffect(target: ResCombatant):
	if EFFECT == null: return
	randomize()
	var random_number = randf_range(0, 100)
	print('Rolled: ', random_number)
	if EFFECT_CHANCE > random_number:
		CombatGlobals.addStatusEffect(target, EFFECT.duplicate())
	else:
		print('Fail!')
		return

func _to_string():
	return NAME
