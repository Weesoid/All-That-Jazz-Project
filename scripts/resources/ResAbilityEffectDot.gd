extends ResAbilityEffect
class_name ResDotEffect

@export var dot_effect:ResDamageOvertimeEffect

func getDot(target:ResCombatant):
	return dot_effect.getDotEffect(target)
