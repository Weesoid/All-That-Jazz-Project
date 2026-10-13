extends ResAbilityAction
class_name ResDotAction

@export var dot_effect:ResDamageOvertimeEffect

func getDot(target:ResCombatant):
	return dot_effect.getDotEffect(target)
