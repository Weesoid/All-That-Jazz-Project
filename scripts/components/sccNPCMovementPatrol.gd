extends Node2D
class_name NPCPatrolMovement

@onready var PATROL_BUBBLE = $PatrolBubble/AnimationPlayer
@onready var PATROL_BUBBLE_SPRITE = $PatrolBubble
@onready var DEBUG = $Label
@export var PATROL_AREA: Area2D
@export var ALERTED_SPEED_MULTIPLIER = 1.25
@export var CHASE_SPEED_MULTIPLIER = 6.0

var NAV_AGENT: NavigationAgent2D
var LINE_OF_SIGHT: LineOfSight
var COMBAT_SQUAD: CombatantSquad
var BODY: CharacterBody2D
var ANIMATOR: AnimationPlayer
var BASE_MOVE_SPEED = 35
var STATE = 0
var NAME: String
var TARGET: Vector2
var MOVE_SPEED: float
var PATROL_SHAPE: CollisionShape2D
var IDLE_TIMER: Timer
var STUN_TIMER: Timer
var DETECT_TIMER: Timer

var COMBAT_SWITCH = true
var PATROL = true

func _ready():
	BODY = get_parent()
	NAV_AGENT = get_parent().get_node('NavigationAgent2D')
	LINE_OF_SIGHT = get_parent().get_node('LineOfSightComponent')
	COMBAT_SQUAD = get_parent().get_node('CombatantSquadComponent')
	ANIMATOR = get_parent().get_node('Animator')
#
#	if OverworldGlobals.getCurrentMap().CLEARED:
#		destroy(false)
	
	NAME = get_parent().name
	BODY.get_node('CombatantSquadComponent').UNIQUE_ID = NAME
	PATROL_SHAPE = PATROL_AREA.get_node('CollisionShape2D')
	MOVE_SPEED = BASE_MOVE_SPEED
	
	IDLE_TIMER = Timer.new()
	STUN_TIMER = Timer.new()
	DETECT_TIMER = Timer.new()
	add_child(IDLE_TIMER)
	add_child(STUN_TIMER)
	add_child(DETECT_TIMER)
	
	OverworldGlobals.update_patroller_modes.connect(updateMode)
	NAV_AGENT.navigation_finished.connect(updatePath)
	NAV_AGENT.navigation_finished.emit()
	
	CombatGlobals.combat_won.connect(
		func(id):
			if id == NAME:
				destroy()
			)
	
	for child in OverworldGlobals.getCurrentMap().get_children():
		# and !child.has_node('NPCPatrolComponent')
		if child is CharacterBody2D and !child is PlayerScene and !child.has_node('NPCPatrolComponent'):
			child.add_collision_exception_with(BODY)

func _physics_process(_delta):
	BODY.move_and_slide()
	if PATROL:
		patrol()
	if COMBAT_SWITCH:
		executeCollisionAction()
	
#	if OverworldGlobals.isPlayerCheating():
	DEBUG.show()
	DEBUG.text = str(DETECT_TIMER.time_left)
#	else:
#		DEBUG.hide()

func executeCollisionAction():
	if BODY.get_slide_collision_count() == 0:
		return
	
	if BODY.get_last_slide_collision().get_collider() is PlayerScene:
		OverworldGlobals.changeToCombat(NAME)
		OverworldGlobals.addPatrollerPulse(BODY, 200.0, 1)
		COMBAT_SWITCH = false

func patrol():
	if LINE_OF_SIGHT.process_mode != Node.PROCESS_MODE_DISABLED:
		patrolToPosition(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if LINE_OF_SIGHT.detectPlayer() and STATE != 3:
		if DETECT_TIMER.is_stopped() and STATE != 2: 
			DETECT_TIMER.start(0.25)
		if !DETECT_TIMER.is_stopped():
			await DETECT_TIMER.timeout
			DETECT_TIMER.stop()
		if LINE_OF_SIGHT.detectPlayer():
			chaseMode()
			patrolToPosition(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if !NAV_AGENT.is_target_reachable():
		soothePatrolMode()

func alertPatrolMode():
	MOVE_SPEED = BASE_MOVE_SPEED * ALERTED_SPEED_MULTIPLIER
	STATE = 1
	if PATROL_BUBBLE.current_animation != "Loop":
		PATROL_BUBBLE.play("Show")
		await PATROL_BUBBLE.animation_finished
		PATROL_BUBBLE.play("Loop")

func soothePatrolMode():
	NAV_AGENT.get_current_navigation_path().clear()
	MOVE_SPEED = BASE_MOVE_SPEED
	STATE = 0
	updatePath(true)
	PATROL_BUBBLE.play_backwards("Show")

func chaseMode():
	MOVE_SPEED = BASE_MOVE_SPEED * CHASE_SPEED_MULTIPLIER
	STATE = 2
	updatePath()

func stunMode(alert_others:bool=false):
	var last_state = STATE
	STATE = 3
	updatePath()
	if alert_others:
		if last_state == 2 or last_state == 1:
			OverworldGlobals.addPatrollerPulse(BODY.global_position, 150.0, 2)
		else:
			OverworldGlobals.addPatrollerPulse(BODY.global_position, 150.0, 1)

func updateMode(state: int, alert_others:bool=false):
	match state:
		0: soothePatrolMode()
		1: alertPatrolMode()
		2: chaseMode()
		3: stunMode(alert_others)

func destroy(fancy=true):
	PATROL = false
	BODY.get_node('CollisionShape2D').set_deferred("disabled", true)
	immobolize()
	if fancy:
		ANIMATOR.stop()
		ANIMATOR.play("KO")
		if STATE == 2 or STATE == 1:
			OverworldGlobals.addPatrollerPulse(BODY.global_position, 150.0, 2)
		else:
			OverworldGlobals.addPatrollerPulse(BODY.global_position, 150.0, 1)
		await ANIMATOR.animation_finished
		isMapCleared()
	BODY.queue_free()

func isMapCleared():
	for child in OverworldGlobals.getCurrentMap().get_children():
		if child.has_node('NPCPatrolComponent') and child != BODY:
			return
	OverworldGlobals.showPlayerPrompt('Map cleared!')
	PlayerGlobals.CLEARED_MAPS.append(OverworldGlobals.getCurrentMap().NAME)
	OverworldGlobals.getCurrentMap().giveRewards()

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

func immobolize(disabled_los:bool=true):
	COMBAT_SWITCH = false
	BODY.velocity = Vector2.ZERO
	if disabled_los:
		LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_DISABLED

func moveRandom()-> Vector2:
	randomize()
	var pos = PATROL_SHAPE.global_position + PATROL_SHAPE.shape.get_rect().position
	var end = PATROL_SHAPE.global_position + PATROL_SHAPE.shape.get_rect().end
	return Vector2(randf_range(pos.x, end.x), randf_range(pos.y, end.y))

func patrolToPosition(target_position: Vector2):
	if targetReached():
		BODY.velocity = Vector2(0,0)
	elif !NAV_AGENT.get_current_navigation_path().is_empty():
		BODY.velocity = target_position * MOVE_SPEED
		updateLineOfSight()
	
	if BODY.velocity == Vector2.ZERO:
		ANIMATOR.seek(1, true)
		ANIMATOR.pause()

func targetReached():
	return NAV_AGENT.distance_to_target() < 1.0

func updateLineOfSight():
	LINE_OF_SIGHT.look_at(NAV_AGENT.get_next_path_position())
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
