extends NPCPatrolMovement
class_name NPCPatrolShooterMovement

@export var PROJECTILE = preload("res://scenes/entities_disposable/ProjectileBullet.tscn")
@onready var reload_timer = $ReloadTimer
var shoot_ready: bool = true

func updatePath(immediate:bool=false):
	match STATE:
		# PATROL
		0:
			randomize()
			if !immediate:
				IDLE_TIMER.start(randf_range(2.0, 5.0))
				await IDLE_TIMER.timeout
				IDLE_TIMER.stop()
			NAV_AGENT.target_position = moveRandom()
		# ALERTED PATROL
		1:
			randomize()
			if !immediate:
				IDLE_TIMER.start(randf_range(2.0, 3.0))
				await IDLE_TIMER.timeout
				IDLE_TIMER.stop()
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position
		# CHASE
		2:
			if !PATROL_BUBBLE_SPRITE.visible:
				PATROL_BUBBLE.play("Show")
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position
		# STUNNED
		3:
			immobolize()
			ANIMATOR.play("Stun")
			randomize()
			STUN_TIMER.start(randf_range(3.0,4.0))
			IDLE_TIMER.stop()
			await STUN_TIMER.timeout
			STUN_TIMER.stop()
			alertPatrolMode()
			updatePath()
			LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_ALWAYS
			COMBAT_SWITCH = true

func targetReached():
	if STATE == 2:
		return NAV_AGENT.distance_to_target() < 125.0 and LINE_OF_SIGHT.detectPlayer()
	else:
		return NAV_AGENT.distance_to_target() < 1.0

func patrolToPosition(target_position: Vector2):
	if targetReached():
		BODY.velocity = Vector2.ZERO
		if shoot_ready:
			updateLineOfSight()
			shootProjectile()
	elif !NAV_AGENT.get_current_navigation_path().is_empty() and shoot_ready:
		updateLineOfSight()
		BODY.velocity = target_position * MOVE_SPEED
	
	if BODY.velocity == Vector2.ZERO and STATE != 2:
		ANIMATOR.seek(1, true)
		ANIMATOR.pause()

func _on_reload_timer_timeout():
	shoot_ready = true

func shootProjectile():
	shoot_ready = false
	ANIMATOR.play('Shoot')
	var projectile = PROJECTILE.instantiate()
	projectile.global_position = global_position + Vector2(0, -10)
	projectile.SHOOTER = BODY
	get_tree().current_scene.add_child(projectile)
	projectile.rotation = LINE_OF_SIGHT.rotation + 1.57079994678497
	reload_timer.start()
	await ANIMATOR.animation_finished
	ANIMATOR.play('Load')
