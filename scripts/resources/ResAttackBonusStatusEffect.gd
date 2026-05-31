extends ResAttackBonus
class_name ResAttackStatusEffect

@export var status_effects: Array[ResStatusEffect]

func getAttackEffect():
	return {'status_effects': status_effects}

func _to_string():
	var effect_icons =  ''
	for effect in status_effects:
		effect_icons += effect.getMessageIcon() +', '
	effect_icons = effect_icons.trim_suffix(', ')
	return target_text+effect_icons+getStringCondition()
