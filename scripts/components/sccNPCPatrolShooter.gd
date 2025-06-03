extends NPCPatrolMovement
class_name NPCPatrolShooterMovement

@export var PROJECTILE: ResProjectile
@export var SHOOT_DISTANCE: float = 125.0
var shoot_ready: bool = true

func updatePath(immediate:bool=false):
	match STATE:
		# PATROL
		0:
			randomize()
			if !immediate:
				IDLE_TIMER.start(randf_range(2.0, IDLE_TIME['patrol']))
				await IDLE_TIMER.timeout
				IDLE_TIMER.stop()
			NAV_AGENT.target_position = moveRandom()
		# ALERTED PATROL
		1:
			randomize()
			if !immediate:
				IDLE_TIMER.start(randf_range(1.0, IDLE_TIME['alerted_patrol']))
				await IDLE_TIMER.timeout
				IDLE_TIMER.stop()
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position
		# CHASE
		2:
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position
		# STUNNED
		3:
			if ['Shoot_Up', 'Shoot_Down', 'Shoot_Right', 'Shoot_Left'].has(ANIMATOR.current_animation):
				ANIMATOR.animation_finished.emit()
			
			BODY.set_collision_layer_value(1, false)
			immobolize()
			randomize()
			STUN_TIMER.start(randf_range(STUN_TIME['min'],STUN_TIME['max']))
			IDLE_TIMER.stop()
			await STUN_TIMER.timeout
			STUN_TIMER.stop()
			alertPatrolMode()
			updatePath()
			LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_INHERIT
			COMBAT_SWITCH = true
			shoot_ready = true
			BODY.set_collision_layer_value(1, true)
			ANIMATOR.play("RESET")

func targetReached():
	if STATE == 2:
		randomize()
		var half_shoot_distance = ceil(SHOOT_DISTANCE / 2)
		return NAV_AGENT.distance_to_target() < (SHOOT_DISTANCE - randf_range(-half_shoot_distance, half_shoot_distance)) and LINE_OF_SIGHT.detectPlayer()
	else:
		return NAV_AGENT.distance_to_target() < 1.0

func patrolToPosition(target_position: Vector2):
	if targetReached():
		BODY.velocity = Vector2.ZERO
		if shoot_ready and STATE == 2:
			updateLineOfSight()
			shootProjectile()
			OverworldGlobals.addPatrollerPulse(BODY, 100.0, 2)
	elif !NAV_AGENT.get_current_navigation_path().is_empty() and shoot_ready:
		updateLineOfSight()
		BODY.velocity = target_position * MOVE_SPEED
	
	if BODY.velocity == Vector2.ZERO and STATE != 2:
		ANIMATOR.seek(1, true)
		ANIMATOR.pause()

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
