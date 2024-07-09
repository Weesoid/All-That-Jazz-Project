extends Projectile
class_name ProjectileBullet

func _on_body_entered(body):
	if body is PlayerScene:
		OverworldGlobals.damageParty(20)
	
	if body != SHOOTER or body is PlayerScene:
		queue_free()

func _exit_tree():
	if has_overlapping_bodies() and get_overlapping_bodies()[0] is PlayerScene:
		randomize()
		OverworldGlobals.playSound2D(global_position, "460509__florianreichelt__hitting-in-a-face_%s.ogg" % randi_range(1,2), 0.0)
		OverworldGlobals.playSound2D(global_position, "522091__magnuswaker__pound-of-flesh-%s.ogg" % randi_range(1,2), 0.0)
	else:
		OverworldGlobals.playSound2D(global_position, "66777__kevinkace__crate-break-1.ogg")
