extends ResEffectCondition
class_name ResStatusCondition

@export var status_effect:ResStatusEffect
@export var rank:int=0

func isPassed(combatant:ResCombatant):
	return combatant.hasStatusEffect(status_effect.name) and combatant.getStatusEffect(status_effect.name).current_rank >= rank

func getDescription():
	return 'If %s ' % status_effect.getMessageIcon()
