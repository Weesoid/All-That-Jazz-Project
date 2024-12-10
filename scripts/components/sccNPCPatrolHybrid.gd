extends NPCPatrolShooterMovement
class_name NPCPatrolHybridMovement

var PATROL_MODE: int = 1 # 0 = Chaser, 1 = Shooter

func executeHitAction():
	PATROL_MODE = 0
	updatePath(true)

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
			if !PATROL_BUBBLE_SPRITE.visible:
				PATROL_BUBBLE_SPRITE.visible = true
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position
		# STUNNED
		3:
			if ['Shoot_Up', 'Shoot_Down', 'Shoot_Right', 'Shoot_Left'].has(ANIMATOR.current_animation):
				ANIMATOR.animation_finished.emit()
			
			BODY.get_node("CollisionShape2D").set_deferred('disabled', true)
			immobolize()
			ANIMATOR.play("Stun")
			randomize()
			STUN_TIMER.start(randf_range(STUN_TIME['min'],STUN_TIME['max']))
			IDLE_TIMER.stop()
			print(STUN_TIMER.time_left)
			await STUN_TIMER.timeout
			print('guh')
			STUN_TIMER.stop()
			alertPatrolMode()
			updatePath()
			LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_INHERIT
			PATROL_MODE = 1
			COMBAT_SWITCH = true
			shoot_ready = true
			BODY.get_node("CollisionShape2D").set_deferred('disabled', false)
			ANIMATOR.play("RESET")

func targetReached():
	if (STATE == 2 and PATROL_MODE == 1):
		randomize()
		var half_shoot_distance = ceil(SHOOT_DISTANCE / 2)
		return NAV_AGENT.distance_to_target() < (SHOOT_DISTANCE - randf_range(-half_shoot_distance, half_shoot_distance)) and LINE_OF_SIGHT.detectPlayer()
	else:
		return NAV_AGENT.distance_to_target() < 1.0

func patrolToPosition(target_position: Vector2):
	if targetReached():
		BODY.velocity = Vector2.ZERO
		if (shoot_ready and STATE == 2 and PATROL_MODE == 1):
			updateLineOfSight()
			shootProjectile()
	elif !NAV_AGENT.get_current_navigation_path().is_empty() and shoot_ready:
		updateLineOfSight()
		BODY.velocity = target_position * MOVE_SPEED
	
	if BODY.velocity == Vector2.ZERO and STATE != 2:
		ANIMATOR.seek(1, true)
		ANIMATOR.pause()
