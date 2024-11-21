extends Area2D
class_name DynamicStatusEffect

enum TriggerType {
	OVERWATCH,
	OVERGUARD,
	FOLLOW_UP
}
@export var trigger_type: TriggerType
var status_effect: ResStatusEffect

func _ready():
	if trigger_type == TriggerType.FOLLOW_UP:
		CombatGlobals.ability_casted.connect(followUpCast)

func _on_body_entered(body):
	var afflicted = status_effect.afflicted_combatant
	if checkTriggers(afflicted, body) and body is CombatantScene:
		status_effect.STATUS_SCRIPT.animate(afflicted, body)

func followUpCast(ability: ResAbility):
	await get_tree().create_timer(0.05).timeout
	var afflicted = status_effect.afflicted_combatant
	if ability.TARGET_TYPE == ability.TargetType.SINGLE and ability.TARGET_GROUP == ability.TargetGroup.ENEMIES and CombatGlobals.getCombatScene().active_combatant != afflicted and !CombatGlobals.isSameCombatantType(afflicted, CombatGlobals.getCombatScene().target_combatant):
		status_effect.STATUS_SCRIPT.animate(afflicted, CombatGlobals.getCombatScene().target_combatant)

func checkTriggers(afflicted: ResCombatant, body)-> bool:
	if afflicted.SCENE == self:
		return false
	
	if trigger_type == TriggerType.OVERWATCH:
		return !CombatGlobals.isSameCombatantType(afflicted, body) and CombatGlobals.getCombatScene().target_combatant != status_effect.afflicted_combatant and CombatGlobals.getCombatScene().active_combatant != afflicted
	else:
		return false
