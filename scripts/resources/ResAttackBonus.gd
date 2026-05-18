extends Resource
class_name ResAttackBonus

@export var condition: ResEffectCondition #= preload()

func getAttackEffect():
	return {'attack_key':null}

func conditionsPassed(target:ResCombatant):
	return condition == null or condition.isPassed(target)
