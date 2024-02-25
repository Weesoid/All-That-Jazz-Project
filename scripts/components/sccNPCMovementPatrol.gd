extends Node2D
class_name NPCPatrolMovement

@onready var PATROL_BUBBLE = $PatrolBubble/AnimationPlayer
@onready var PATROL_BUBBLE_SPRITE = $PatrolBubble
@onready var DEBUG = $Label
@export var NAV_AGENT: NavigationAgent2D
@export var LINE_OF_SIGHT: LineOfSight
@export var COMBAT_SQUAD: CombatantSquad
@export var PATROL_AREA: Area2D
@export var BODY: CharacterBody2D
@export var ANIMATOR: AnimationPlayer
@export var BASE_MOVE_SPEED = 35

var STATE = 0
var NAME
var TARGET
var MOVE_SPEED
var PATROL_SHAPE
var IDLE_TIMER: Timer
var STUN_TIMER: Timer

var COMBAT_SWITCH = true
var PATROL = true

func _ready():
	if OverworldGlobals.getCurrentMapData().CLEARED:
		destroy(false)
	
	NAME = get_parent().name
	BODY.get_node('CombatantSquadComponent').UNIQUE_ID = NAME
	PATROL_SHAPE = PATROL_AREA.get_node('CollisionShape2D')
	MOVE_SPEED = BASE_MOVE_SPEED
	
	#STUCK_TIMER = Timer.new()
	IDLE_TIMER = Timer.new()
	STUN_TIMER = Timer.new()
	#STUCK_TIMER.autostart = true
	
	#add_child(STUCK_TIMER)
	add_child(IDLE_TIMER)
	add_child(STUN_TIMER)
	
	OverworldGlobals.alert_patrollers.connect(alertPatrolMode)
	#STUCK_TIMER.timeout.connect(updatePath)
	NAV_AGENT.navigation_finished.connect(updatePath)
	NAV_AGENT.navigation_finished.emit()
	
	CombatGlobals.combat_won.connect(
		func(id):
			if id == NAME:
				destroy()
			)
	
	#STUCK_TIMER.start(10.0)

func _physics_process(_delta):
	BODY.move_and_slide()
	if PATROL:
		patrol()
	if COMBAT_SWITCH:
		executeCollisionAction()
	
	DEBUG.text = str(int(IDLE_TIMER.time_left))

func executeCollisionAction():
	if BODY.get_slide_collision_count() == 0:
		return
	
	if BODY.get_last_slide_collision().get_collider() == OverworldGlobals.getPlayer():
		OverworldGlobals.changeToCombat(NAME)
		OverworldGlobals.alert_patrollers.emit()
		COMBAT_SWITCH = false

func patrol():
	if LINE_OF_SIGHT.process_mode != Node.PROCESS_MODE_DISABLED:
		patrolToPosition(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if LINE_OF_SIGHT.detectPlayer() and STATE != 3:
		MOVE_SPEED = BASE_MOVE_SPEED * 8.0
		STATE = 2
		updatePath()
		patrolToPosition(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if !NAV_AGENT.is_target_reachable():
		MOVE_SPEED = BASE_MOVE_SPEED
		STATE = 0
		updatePath()
		if PATROL_BUBBLE_SPRITE.visible and PATROL_BUBBLE.current_animation != "Show":
			PATROL_BUBBLE.play_backwards("Show")
	
func alertPatrolMode():
	MOVE_SPEED = BASE_MOVE_SPEED * 1.25
	STATE = 1
	if PATROL_BUBBLE.current_animation != "Loop":
		PATROL_BUBBLE.play("Show")
		await PATROL_BUBBLE.animation_finished
		PATROL_BUBBLE.play("Loop")

func stunMode():
	STATE = 3
	updatePath()
	
func destroy(fancy=true):
	PATROL = false
	BODY.get_node('CollisionShape2D').set_deferred("disabled", true)
	immobolize()
	if fancy:
		isMapCleared()
		ANIMATOR.stop()
		ANIMATOR.play("KO")
		await ANIMATOR.animation_finished
		OverworldGlobals.alert_patrollers.emit()
	BODY.queue_free()

func isMapCleared():
	for child in OverworldGlobals.getCurrentMap().get_children():
		if child.is_in_group('patroller'):
			return
	PlayerGlobals.CLEARED_MAPS.append(OverworldGlobals.getCurrentMapData().NAME)

func updatePath():
	match STATE:
		# PATROL
		0:
			randomize()
			IDLE_TIMER.start(randf_range(2.0, 5.0))
			await IDLE_TIMER.timeout
			IDLE_TIMER.stop()
			NAV_AGENT.target_position = moveRandom()
		# ALERTED PATROL
		1:
			randomize()
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

func immobolize():
	COMBAT_SWITCH = false
	BODY.velocity = Vector2.ZERO
	LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_DISABLED

func moveRandom():
	randomize()
	return Vector2(randf_range(PATROL_SHAPE.global_position.x, PATROL_SHAPE.global_position.x + PATROL_SHAPE.shape.get_rect().end.x),
					randf_range(PATROL_SHAPE.global_position.y, PATROL_SHAPE.global_position.y + PATROL_SHAPE.shape.get_rect().end.y))


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
