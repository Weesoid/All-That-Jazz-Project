extends ResAbilityEffect
class_name ResDotEffect

@export var dot_effect:ResDamageOvertimeEffect

func getDot():
	return dot_effect.getDotEffect()
