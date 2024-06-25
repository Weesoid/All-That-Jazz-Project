extends Projectile
class_name ProjectileArrow

func _on_body_entered(body):
	if body.has_node('NPCPatrolComponent'):
		PlayerGlobals.EQUIPPED_ARROW.applyOverworldEffect(body)
	elif body.has_node('HurtBoxComponent'):
		body.get_node('HurtBoxComponent').applyEffect()
	
	if body != SHOOTER:
		queue_free()
