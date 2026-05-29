extends ResAttackBonus
class_name ResAttackDot

@export var dot_effect: ResDamageOvertimeEffect

func getAttackEffect():
	return {'dot_effect': dot_effect.getDotEffect()}

func _to_string():
	var effect = dot_effect.getDotStatusEffect()
	return effect.getIconColor(true) + '%s%s (%s turns) ' % [
		dot_effect.duration, 
		effect.getMessageIcon(), 
		dot_effect.damage
		] + '[/color]' + getStringCondition()
