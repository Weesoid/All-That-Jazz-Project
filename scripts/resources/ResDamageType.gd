extends Resource
class_name ResDamageType

@export var NAME: String
@export var EFFECT: ResStatusEffect
@export var EFFECT_CHANCE: float

func rollEffect(target: ResCombatant):
	if EFFECT == null: return
	
	var percent_chance = EFFECT_CHANCE + target.STAT_VALUES['exposure']
	if percent_chance > 1.0: 
		percent_chance = 1.0
	elif percent_chance < 0:
		percent_chance = 0
	
	if CombatGlobals.randomRoll(percent_chance):
		CombatGlobals.addStatusEffect(target, EFFECT.NAME)
	else:
		return

func _to_string():
	return NAME
