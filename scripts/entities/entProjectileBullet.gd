extends Projectile
class_name ProjectileBullet

func _on_body_entered(body):
	if body is PlayerScene:
		OverworldGlobals.showGameOver('You were shot!')
	elif body.has_node('NPCPatrolComponent') and body != SHOOTER:
		body.get_node('NPCPatrolComponent').destroy()
	
	if body != SHOOTER:
		queue_free()
