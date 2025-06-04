extends NPCPatrolMovement
class_name NPCPatrolShooterMovement

@export var PROJECTILE: ResProjectile
@export var SHOOT_DISTANCE: float = 125.0
var shoot_ready: bool = true

func doTargetReachedAction():
	if shoot_ready and STATE == 2:
		updateLineOfSight()
		shootProjectile()
		OverworldGlobals.addPatrollerPulse(BODY, 100.0, 2)

func targetReached():
	if !shoot_ready:
		return true
	if STATE == 2:
		randomize()
		var half_shoot_distance = ceil(SHOOT_DISTANCE / 2)
		return NAV_AGENT.distance_to_target() < (SHOOT_DISTANCE - randf_range(-half_shoot_distance, half_shoot_distance)) and LINE_OF_SIGHT.detectPlayer()
	else:
		return NAV_AGENT.distance_to_target() < 1.0

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

func animateShot():
	var look_direction = LINE_OF_SIGHT.global_rotation_degrees
	if look_direction < 135 and look_direction > 45:
		ANIMATOR.play('Shoot_Left')
	elif look_direction < -45 and look_direction > -135:
		ANIMATOR.play('Shoot_Right')
	elif look_direction < 45 and look_direction > -45:
		ANIMATOR.play('Shoot_Down')
	else:
		ANIMATOR.play('Shoot_Up')

func isPlayerTooFar():
	return OverworldGlobals.getCurrentMap().has_node('Player') and BODY.global_position.distance_to(OverworldGlobals.getPlayer().global_position) > 600.0
