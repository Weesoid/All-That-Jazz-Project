extends ResEffectCondition
class_name ResHealthCondition

enum Inequality {
	GREATER_THAN,
	LESS_THAN
}

@export var inequality: Inequality = Inequality.LESS_THAN
@export_range(0.0,1.0) var health_threshold:float = 0.0

func isPassed(combatant:ResCombatant):
	if inequality == Inequality.GREATER_THAN:
		return combatant.stat_values['health'] >= combatant.getMaxHealth()*health_threshold
	else:
		return combatant.stat_values['health'] <= combatant.getMaxHealth()*health_threshold

func _to_string():
	return 'when target HP %s %s%%' % ['<' if inequality == Inequality.LESS_THAN else '>', str(int(health_threshold*100))]
