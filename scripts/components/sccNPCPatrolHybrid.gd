extends NPCPatrolShooterMovement
class_name NPCPatrolHybridMovement

var PATROL_MODE: int = 1 # 0 = Chaser, 1 = Shooter

func executeHitAction():
	PATROL_MODE = 0
	updatePath(true)

func doTargetReachedAction():
	if shoot_ready and STATE == 2 and PATROL_MODE == 1:
		updateLineOfSight()
		shootProjectile()

func targetReached():
	if (!shoot_ready and PATROL_MODE == 1):
		return true
	if (STATE == 2 and PATROL_MODE  == 1):
		randomize()
		var half_shoot_distance = ceil(SHOOT_DISTANCE / 2)
		return NAV_AGENT.distance_to_target() < (SHOOT_DISTANCE - randf_range(-half_shoot_distance, half_shoot_distance)) and LINE_OF_SIGHT.detectPlayer()
	else:
		return NAV_AGENT.distance_to_target() < 1.0

func doStunRecoveryAction():
	PATROL_MODE = 1
	chaseMode()
	updatePath()

func shootProjectile():
	shoot_ready = false
	var projectile = PROJECTILE.getProjectile()
	projectile.global_position = global_position + Vector2(0, -10)
	projectile.SHOOTER = BODY
	get_tree().current_scene.add_child(projectile)
	animateShot()
	projectile.rotation = LINE_OF_SIGHT.rotation + 1.57079994678497
	await ANIMATOR.animation_finished
	ANIMATOR.play('Load')
	await ANIMATOR.animation_finished
	shoot_ready = true
	PATROL_MODE = 1
