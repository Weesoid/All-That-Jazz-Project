extends NPCMovement
class_name NPCPatrolMovement

@onready var PATROL_BUBBLE = $PatrolBubble/AnimationPlayer
@onready var PATROL_BUBBLE_SPRITE = $PatrolBubble
@export var NAV_AGENT: NavigationAgent2D
@export var LINE_OF_SIGHT: LineOfSight
@export var COMBAT_SQUAD: CombatantSquad
@export var PATROL_AREA: Area2D

var PATROL_SHAPE
#var PATH_UPDATE_TIMER: Timer
var IDLE_TIMER: Timer

var COMBAT_SWITCH = true

func _ready():
	NAME = get_parent().name
	BODY.get_node('CombatantSquadComponent').UNIQUE_ID = NAME
	PATROL_SHAPE = PATROL_AREA.get_node('CollisionShape2D')
	MOVE_SPEED = BASE_MOVE_SPEED
	
	#PATH_UPDATE_TIMER = Timer.new()
	#PATH_UPDATE_TIMER.autostart = true
	#PATH_UPDATE_TIMER.timeout.connect(updatePath)
#	PATH_UPDATE_TIMER.timeout.connect(func(): print('to'))
	
	IDLE_TIMER = Timer.new()
	IDLE_TIMER.autostart = true
	
	add_child(IDLE_TIMER)
	#add_child(PATH_UPDATE_TIMER)
	
	OverworldGlobals.alert_patrollers.connect(alertPatrolMode)
	
	NAV_AGENT.navigation_finished.connect(updatePath)
	NAV_AGENT.navigation_finished.emit()
	
	CombatGlobals.combat_won.connect(
		func(id):
			if id == NAME:
				destroy()
			)
	CombatGlobals.combat_lost.connect(
		func(_id):
			if ANIMATOR.current_animation == 'KO':
				BODY.queue_free()
			else:
				stunMode()
			)
	
#	PATH_UPDATE_TIMER.timeout.emit()
#	PATH_UPDATE_TIMER.start(15.0)

func _physics_process(_delta):
	patrol()
	BODY.move_and_slide()
	executeCollisionAction()

func executeCollisionAction():
	if BODY.get_slide_collision_count() == 0:
		return
	
	if BODY.get_last_slide_collision().get_collider() == OverworldGlobals.getPlayer() and COMBAT_SWITCH:
		OverworldGlobals.changeToCombat(NAME)
		OverworldGlobals.alert_patrollers.emit()
		COMBAT_SWITCH = false
		#await CombatGlobals.getCombatScene().combat_done
		#if COMBAT_RESULT == 1:
		#	print('Res1')
		#	destroy()
		#else:
		#	print('Res2')
		#	stunMode()
		#	COMBAT_RESULT = -1

func patrol():
	if LINE_OF_SIGHT.process_mode != Node.PROCESS_MODE_DISABLED:
		patrolToPosition(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if LINE_OF_SIGHT.detectPlayer():
		MOVE_SPEED = BASE_MOVE_SPEED * 8.0
		STATE = 2
		updatePath()
		patrolToPosition(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if !NAV_AGENT.is_target_reachable():
		#PATH_UPDATE_TIMER.timeout.emit()
		MOVE_SPEED = BASE_MOVE_SPEED
		STATE = 0
		if PATROL_BUBBLE_SPRITE.visible and PATROL_BUBBLE.current_animation != "Show":
			PATROL_BUBBLE.play_backwards("Show")

func alertPatrolMode():
	MOVE_SPEED = BASE_MOVE_SPEED * 1.5
	STATE = 1
	if PATROL_BUBBLE.current_animation != "Loop":
		PATROL_BUBBLE.play("Show")
		await PATROL_BUBBLE.animation_finished
		PATROL_BUBBLE.play("Loop")

func stunMode():
	STATE = 3
	updatePath()
	
func destroy():
	IDLE_TIMER.stop()
	if PATROL_BUBBLE_SPRITE.visible:
		PATROL_BUBBLE.play_backwards("Show")
	immobolize()
	ANIMATOR.stop()
	ANIMATOR.play("KO")
	await ANIMATOR.animation_finished
	BODY.queue_free()

func updatePath():
	match STATE:
		0:
			randomize()
			IDLE_TIMER.start(randf_range(1.0, 5.0))
			await IDLE_TIMER.timeout
			NAV_AGENT.target_position = moveRandom()
		1:
			randomize()
			IDLE_TIMER.start(randf_range(1.0, 2.5))
			await IDLE_TIMER.timeout
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position
		2:
			if !PATROL_BUBBLE_SPRITE.visible:
				PATROL_BUBBLE.play("Show")
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position
		3: 
			immobolize()
			ANIMATOR.play("Stun")
			randomize()
			await get_tree().create_timer(randf_range(3.0, 4.0)).timeout
			alertPatrolMode()
			updatePath()
			COMBAT_SWITCH = true
			LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_ALWAYS
		# 4:
		#	COMBAT_SWITCH = true
		#	interact_comp.combat_interact()
		#	OverworldGlobals.alert_patrollers.emit()
		#	COMBAT_SWITCH = false

func immobolize():
	BODY.velocity = Vector2.ZERO
	LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_DISABLED
	COMBAT_SWITCH = false

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
