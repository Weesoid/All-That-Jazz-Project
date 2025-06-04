extends Node2D
class_name NPCPatrolMovement

#@onready var PATROL_BUBBLE = $PatrolBubble/AnimationPlayer
@onready var PATROLLER_BUBBLE: PatrollerBubble = $PatrolBubble
@onready var DEBUG = $Label
@export var PATROL_AREA: Area2D
@export var MOVE_SPEED = 6
@export var ALERTED_SPEED_MULTIPLIER = 1.5
@export var CHASE_SPEED_MULTIPLIER = 5.0
@export var DETECTION_TIME = 0.5
@export var IDLE_TIME: Dictionary = {'patrol':5.0, 'alerted_patrol':2.0}
@export var STUN_TIME: Dictionary = {'min':3.0, 'max':4.0}
@export var IS_STALKER = false

var NAV_AGENT: NavigationAgent2D
var LINE_OF_SIGHT: LineOfSight
var COMBAT_SQUAD: CombatantSquad
var BODY: CharacterBody2D
var ANIMATOR: AnimationPlayer
var STATE = 0
var NAME: String
var TARGET: Vector2
var PATROL_SHAPE: CollisionShape2D
var IDLE_TIMER: Timer
var STUN_TIMER: Timer
var DETECT_TIMER: Timer
var COMBAT_SWITCH = true
var PATROL = true
var last_target_position: Vector2
var flicker_tween: Tween

func initialize():
	BODY = get_parent()
	NAV_AGENT = get_parent().get_node('NavigationAgent2D')
	LINE_OF_SIGHT = get_parent().get_node('LineOfSightComponent')
	ANIMATOR = get_parent().get_node('Animator')
	BODY.velocity = Vector2.ZERO
	
	NAME = get_parent().name
	COMBAT_SQUAD.UNIQUE_ID = NAME
	if PATROL_AREA != null:
		PATROL_SHAPE = PATROL_AREA.get_node('CollisionShape2D')
		print(PATROL_SHAPE)
	
	IDLE_TIMER = Timer.new()
	STUN_TIMER = Timer.new()
	DETECT_TIMER = Timer.new()
	add_child(IDLE_TIMER)
	add_child(STUN_TIMER)
	add_child(DETECT_TIMER)
	OverworldGlobals.update_patroller_modes.connect(updateMode)
	NAV_AGENT.navigation_finished.connect(updatePath)
	NAV_AGENT.velocity_computed.connect(velocityComputed)
	NAV_AGENT.navigation_finished.emit()
	
	CombatGlobals.combat_won.connect(
		func(id): 
			if id == NAME: 
				destroy()
			if IS_STALKER:
				OverworldGlobals.getCurrentMap().give_on_exit = false
				)
	CombatGlobals.combat_lost.connect(
		func(_id): 
			if !OverworldGlobals.isPlayerAlive(): 
				destroy(false)
				if IS_STALKER:
					OverworldGlobals.getCurrentMap().give_on_exit = false
					BODY.queue_free()
				#BODY.hide()
			)
	for child in OverworldGlobals.getCurrentMap().get_children():
		# and !child.has_node('NPCPatrolComponent')
		if child is CharacterBody2D and !child is PlayerScene and !child.has_node('NPCPatrolComponent'):
			child.add_collision_exception_with(BODY)
	#DETECT_BAR.max_value = DETECTION_TIME
	flicker_tween = create_tween().set_loops()
	flicker_tween.tween_property(get_parent().get_node('Sprite2D'),'self_modulate', Color(Color.WHITE, 0.5), 0.5).from(Color.WHITE)
	flickerTween(false)

func _physics_process(_delta):
	if PATROL:
		patrol()
	if canEnterCombat():
		executeCollisionAction()
	if collidedWithTilemap():
		updatePath(true, last_target_position)
	BODY.move_and_slide()

func canEnterCombat()-> bool:
	return COMBAT_SWITCH and STATE != 3 and (OverworldGlobals.getCurrentMap().has_node('Player') and OverworldGlobals.isPlayerAlive())

func collidedWithTilemap()-> bool:
	return BODY.velocity != Vector2.ZERO and BODY.get_slide_collision_count() > 0 and BODY.get_slide_collision(0).get_collider() is TileMap

func executeCollisionAction():
	if BODY.get_slide_collision_count() == 0 or !OverworldGlobals.getCurrentMap().done_loading_map:
		return
	
	if BODY.get_last_slide_collision().get_collider() is PlayerScene:
		#print(NAME, ': You touched me! I am fighting you! ', Time.get_time_dict_from_system())
		immobolize()
		OverworldGlobals.addPatrollerPulse(BODY, 200.0, 1)
		OverworldGlobals.changeToCombat(NAME)
		COMBAT_SWITCH = false
	if BODY.get_last_slide_collision().get_collider().has_node('NPCPatrolComponent') and STATE == 2:
		BODY.get_last_slide_collision().get_collider().get_node('NPCPatrolComponent').updateMode(2)

func patrol():
	# Detection
	if LINE_OF_SIGHT.detectPlayer() and STATE != 3:
		startDetectTimer()
		if !DETECT_TIMER.is_stopped():
			await DETECT_TIMER.timeout
			DETECT_TIMER.stop()
		chaseMode()
	else:
		DETECT_TIMER.stop()
	
	# Navigation and pathfinding
	if targetReached() or STATE == 3:
		setLastTargetPosition()
		BODY.velocity = Vector2.ZERO
		doTargetReachedAction()
		return
	
	var current_pos = BODY.global_position
	var next_path_pos = NAV_AGENT.get_next_path_position()
	var new_velocity = current_pos.direction_to(next_path_pos) * MOVE_SPEED
	updateLineOfSight()
	
	if NAV_AGENT.avoidance_enabled:
		NAV_AGENT.set_velocity(new_velocity* MOVE_SPEED)
	else:
		velocityComputed(new_velocity)
	
	# Target unreachable fallback
	if ((!NAV_AGENT.is_target_reachable() and !NAV_AGENT.distance_to_target() > 10.0) and !LINE_OF_SIGHT.detectPlayer()) or (STATE == 2 and isPlayerTooFar()):
		if self is NPCPatrolShooterMovement and ['Shoot_Up', 'Shoot_Down', 'Shoot_Right', 'Shoot_Left', 'Load'].has(ANIMATOR.current_animation):
			ANIMATOR.animation_finished.emit()
			ANIMATOR.play('RESET')
		updateMode(1)

func doTargetReachedAction():
	ANIMATOR.seek(1, true)
	ANIMATOR.pause()

func startDetectTimer():
	if (!LINE_OF_SIGHT.detectPlayer() and STATE == 3) or !DETECT_TIMER.is_stopped():
		return
	
	if DETECT_TIMER.is_stopped() and STATE != 2:
		if STATE == 1:
			DETECT_TIMER.start(DETECTION_TIME/1.5)
		else:
			DETECT_TIMER.start(DETECTION_TIME)

func alertPatrolMode():
	if IS_STALKER:
		chaseMode()
		return
	PATROLLER_BUBBLE.playBubbleAnimation('Loop_Seek', "387533__soundwarf__alert-short.ogg")
	#ANIMATOR.speed_scale = 1.0
	STATE = 1

func soothePatrolMode():
	NAV_AGENT.get_current_navigation_path().clear()
	#ANIMATOR.speed_scale = 1.0
	STATE = 0
	updatePath(true)
	PATROLLER_BUBBLE.animator.play_backwards("Soothe")

func chaseMode():
	PATROLLER_BUBBLE.show()
	PATROLLER_BUBBLE.playBubbleAnimation('Loop', "413641__djlprojects__metal-gear-solid-inspired-alert-surprise-sfx.ogg")
	#ANIMATOR.speed_scale = 2.5
	STATE = 2
	updatePath()

func stunMode(alert_others:bool=false):
	var last_state = STATE
	#ANIMATOR.speed_scale = 1.0
	STATE = 3
	updatePath()
	if alert_others:
		if last_state == 2 or last_state == 1:
			OverworldGlobals.addPatrollerPulse(BODY.global_position, 150.0, 2)
		else:
			OverworldGlobals.addPatrollerPulse(BODY.global_position, 150.0, 4)

func updateMode(state: int, alert_others:bool=false):
	if STATE == state:
		return
	
	match state:
		0: soothePatrolMode()
		1: alertPatrolMode()
		2: chaseMode()
		3: stunMode(alert_others)

func destroy(fancy=true):
	if ANIMATOR.current_animation == 'KO': return
	if BODY.has_node('CombatDialogue'):
		ANIMATOR.play('RESET')
		queue_free()
		return
	
	PATROL = false
	BODY.get_node('CollisionShape2D').set_deferred("disabled", true)
	immobolize()
	if fancy:
		if STATE == 2 or STATE == 1:
			OverworldGlobals.addPatrollerPulse(BODY.global_position, 150.0, 2)
		else:
			OverworldGlobals.addPatrollerPulse(BODY.global_position, 150.0, 1)
		await get_tree().process_frame
		if OverworldGlobals.getCurrentMap().arePatrollersHalved() and !OverworldGlobals.getCurrentMap().full_alert and OverworldGlobals.getCurrentMap().getPatrollers().size() > 1:
			OverworldGlobals.addPatrollerPulse(BODY.global_position, 999.0, 4)
			OverworldGlobals.getCurrentMap().full_alert = true
			OverworldGlobals.showPlayerPrompt('Enemies have noticed your presence and are [color=red]fully alert[/color]!')
	
	BODY.queue_free()
	await tree_exited
	OverworldGlobals.patroller_destroyed.emit()

func updatePath(immediate:bool=false, target:Vector2=Vector2.ZERO):
	match STATE:
		# PATROL
		0:
			randomize()
			if !immediate:
				IDLE_TIMER.start(randf_range(2.0, IDLE_TIME['patrol']))
				await IDLE_TIMER.timeout
				IDLE_TIMER.stop()
			if target != Vector2.ZERO:
				NAV_AGENT.target_position = target
			else:
				NAV_AGENT.target_position = moveRandom()
		# ALERTED PATROL
		1:
			randomize()
			if !immediate:
				IDLE_TIMER.start(randf_range(1.0, IDLE_TIME['alerted_patrol']))
				await IDLE_TIMER.timeout
				IDLE_TIMER.stop()
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position+OverworldGlobals.getPlayer().get_node('Sprite2D').offset
		# CHASE
		2:
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position+OverworldGlobals.getPlayer().get_node('Sprite2D').offset
		# STUNNED
		3:
			if ['Shoot_Up', 'Shoot_Down', 'Shoot_Right', 'Shoot_Left'].has(ANIMATOR.current_animation):
				ANIMATOR.animation_finished.emit()
			
			BODY.get_node("CollisionShape2D").set_deferred('disabled', true)
			immobolize()
			flickerTween(true)
			randomize()
			STUN_TIMER.start(randf_range(STUN_TIME['min'],STUN_TIME['max']))
			IDLE_TIMER.stop()
			await STUN_TIMER.timeout
			flickerTween(false)
			STUN_TIMER.stop()
			doStunRecoveryAction()
			LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_INHERIT
			COMBAT_SWITCH = true
			BODY.get_node("CollisionShape2D").set_deferred('disabled', false)
			ANIMATOR.play("RESET")

func doStunRecoveryAction():
	alertPatrolMode()
	updatePath()

func flickerTween(play:bool):
	var sprite = get_parent().get_node('Sprite2D')
	if play:
		sprite.modulate = Color.DARK_GRAY
		flicker_tween.play()
	else:
		flicker_tween.stop()
		#flicker_tween.kill()
		sprite.modulate = Color.WHITE
		sprite.self_modulate = Color.WHITE

func immobolize(disabled_los:bool=true):
	COMBAT_SWITCH = false
	BODY.velocity = Vector2.ZERO
	if disabled_los:
		LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_DISABLED

func moveRandom()-> Vector2:
	if PATROL_SHAPE != null:
#		var theta : float = randf() * 2 * PI
#		return (PATROL_SHAPE.global_position+Vector2(cos(theta), sin(theta)) * sqrt(randf())) * PATROL_SHAPE.shape.radius
		randomize()
		var pos = PATROL_SHAPE.global_position + PATROL_SHAPE.shape.get_rect().position
		var end = PATROL_SHAPE.global_position + PATROL_SHAPE.shape.get_rect().end
		return Vector2(randf_range(pos.x, end.x), randf_range(pos.y, end.y))
	else:
		return OverworldGlobals.getPlayer().global_position

func targetReached():
	return NAV_AGENT.distance_to_target() < 2.0

func isPlayerTooFar():
	return OverworldGlobals.getCurrentMap().has_node('Player') and BODY.global_position.distance_to(OverworldGlobals.getPlayer().global_position) > 300.0

func updateLineOfSight():
	LINE_OF_SIGHT.look_at(NAV_AGENT.target_position)
	LINE_OF_SIGHT.rotation -= PI/2
	var look_direction = LINE_OF_SIGHT.global_rotation_degrees
	
	if look_direction < 135 and look_direction > 45:
		updateSprite('L')
	elif look_direction < -45 and look_direction > -135:
		updateSprite('R')
	elif look_direction < 45 and look_direction > -45:
		updateSprite('D')
	else:
		updateSprite('U')

func updateSprite(direction: String):
	if direction == 'L':
		ANIMATOR.play('Walk_Left')
	elif direction == 'R':
		ANIMATOR.play('Walk_Right')
	elif direction == 'D':
		ANIMATOR.play('Walk_Down')
	else:
		ANIMATOR.play('Walk_Up')

func velocityComputed(safe_velocity):
	if STATE == 2:
		BODY.velocity = safe_velocity*CHASE_SPEED_MULTIPLIER
	elif STATE == 1:
		BODY.velocity = safe_velocity*ALERTED_SPEED_MULTIPLIER
	else:
		BODY.velocity = safe_velocity

func setLastTargetPosition():
	if NAV_AGENT.is_target_reachable() and STATE == 0:
		last_target_position = NAV_AGENT.target_position
