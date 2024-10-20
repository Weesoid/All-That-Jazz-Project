extends Area2D
class_name DynamicStatusEffect

enum TriggerType {
	OVERWATCH
}
@export var trigger_type: TriggerType
var status_effect: ResStatusEffect

func _on_body_entered(body):
	var afflicted = status_effect.afflicted_combatant
	if checkTriggers(afflicted, body):
		status_effect.STATUS_SCRIPT.animate(afflicted, body)

func checkTriggers(afflicted: ResCombatant, body: CombatantScene)-> bool:
	if trigger_type == TriggerType.OVERWATCH:
		return afflicted.SCENE != self and CombatGlobals.getCombatantType(afflicted) != CombatGlobals.getCombatantType(body) and CombatGlobals.getCombatScene().target_combatant != status_effect.afflicted_combatant and CombatGlobals.getCombatScene().active_combatant != afflicted
	else:
		return false
