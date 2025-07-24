extends Projectile
class_name ProjectileArrow

func _on_body_entered(body):
	if body.has_node('HurtBoxComponent'):
		body.get_node('HurtBoxComponent').applyEffect()
	elif body is GenericPatroller:
		OverworldGlobals.playSound2D(global_position, "460509__florianreichelt__hitting-in-a-face_%s.ogg" % randi_range(1,2), 0.0)
		PlayerGlobals.EQUIPPED_ARROW.applyOverworldEffect(body)
	
	if body != SHOOTER:
		OverworldGlobals.shakeSprite(body, 5.0, 10.0)
		queue_free()

func _exit_tree():
	#OverworldGlobals.addPatrollerPulse(global_position, 150.0, 4)
	pass
	#OverworldGlobals.playSound2D(global_position, "66777__kevinkace__crate-break-1.ogg")
