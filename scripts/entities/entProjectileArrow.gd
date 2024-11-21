extends Projectile
class_name ProjectileArrow

func _on_body_entered(body):
	if body.has_node('NPCPatrolComponent'):
		PlayerGlobals.EQUIPPED_ARROW.applyOverworldEffect(body)
	elif body.has_node('HurtBoxComponent'):
		body.get_node('HurtBoxComponent').applyEffect()
	
	if body != SHOOTER:
		queue_free()

func _exit_tree():
	if has_overlapping_bodies() and get_overlapping_bodies()[0] is CharacterBody2D:
		randomize()
		OverworldGlobals.playSound2D(global_position, "460509__florianreichelt__hitting-in-a-face_%s.ogg" % randi_range(1,2), 0.0)
	else:
		OverworldGlobals.addPatrollerPulse(global_position, 100.0, 1)
		OverworldGlobals.playSound2D(global_position, "66777__kevinkace__crate-break-1.ogg")
