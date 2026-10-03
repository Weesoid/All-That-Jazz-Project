extends ResAttackBonus
class_name ResAttackDot

@export var dot_effect: ResDamageOvertimeEffect

func getAttackEffect(target:ResCombatant=null):
	return {'dot_effect': dot_effect.getDotEffect(target)}

func _to_string():
	var effect = dot_effect.getDotStatusEffect()
	var out = effect.getIconColor(true)
	if effect.name != 'Bleed':
		out += '%s%s (%s turns) ' % [
		dot_effect.damage, 
		effect.getMessageIcon(), 
		dot_effect.duration
		] + '[/color]'
	else:
		out += '%s%s[/color]' % [dot_effect.duration, effect.getMessageIcon()]
	
	return out + str(dot_effect.getBonusConditionString())
