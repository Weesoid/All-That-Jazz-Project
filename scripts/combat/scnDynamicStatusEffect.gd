extends Area2D
class_name DynamicStatusEffect

var status_effect: ResStatusEffect

func _on_body_entered(body):
	status_effect.STATUS_SCRIPT.applyEffects(status_effect.afflicted_combatant, body)
