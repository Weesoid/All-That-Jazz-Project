extends ResEffectCondition
class_name ResStatusCondition

@export var status_effect:ResStatusEffect
@export var rank:int=0
@export var remove_effect:bool=false

func isPassed(combatant:ResCombatant):
	var is_passed = combatant.hasStatusEffect(status_effect.name) and combatant.getStatusEffect(status_effect.name).current_rank >= rank
	if remove_effect: 
		CombatGlobals.removeStatusEffect(combatant, status_effect.name)
	return is_passed

func _to_string():
	return '\nwhen target has '+status_effect.getMessageIcon()
