extends Projectile
class_name ProjectileBullet

func _on_body_entered(body):
	if body is PlayerScene:
		pass
		#OverworldGlobals.getPlayer().player_camera.shake(15.0,10.0)
		#OverworldGlobals.showGameOver('You were shot!')
	
	if body != SHOOTER:
		queue_free()
