extends NPCMovement

@export var NAV_AGENT: NavigationAgent2D
@export var LINE_OF_SIGHT: LineOfSight
@export var COMBAT_SQUAD: CombatantSquad
@export var PATROL_AREA: Area2D

var PATROL_SHAPE
var PATH_UPDATE_TIMER: Timer
var IDLE_TIMER: Timer

func _ready():
	PATROL_SHAPE = PATROL_AREA.get_node('CollisionShape2D')
	MOVE_SPEED = BASE_MOVE_SPEED
	
	PATH_UPDATE_TIMER = Timer.new()
	PATH_UPDATE_TIMER.autostart = true
	PATH_UPDATE_TIMER.timeout.connect(updatePath)
	PATH_UPDATE_TIMER.stop()
	
	IDLE_TIMER = Timer.new()
	IDLE_TIMER.autostart = true
	
	add_child(IDLE_TIMER)
	add_child(PATH_UPDATE_TIMER)
	
	OverworldGlobals.alert_patrollers.connect(alertPatrolMode)
	
	NAV_AGENT.navigation_finished.connect(updatePath)
	NAV_AGENT.navigation_finished.emit()

func _physics_process(_delta):
	patrol()
	BODY.move_and_slide()
	executeCollisionAction()

func executeCollisionAction():
	if BODY.get_slide_collision_count() == 0:
		return
	
	if BODY.get_last_slide_collision().get_collider() == OverworldGlobals.getPlayer():
		OverworldGlobals.changeToCombat(NAME)
		OverworldGlobals.alert_patrollers.emit()
		BODY.queue_free()

func patrol():
	if STATE != 3:
		patrolToPosition(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if LINE_OF_SIGHT.detectPlayer():
		MOVE_SPEED = BASE_MOVE_SPEED * 5
		STATE = 2
		updatePath()
		patrolToPosition(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if !NAV_AGENT.is_target_reachable():
		PATH_UPDATE_TIMER.stop()
		MOVE_SPEED = BASE_MOVE_SPEED
		STATE = 0

func alertPatrolMode():
	MOVE_SPEED = BASE_MOVE_SPEED * 1.5
	STATE = 1
	
func stunMode():
	STATE = 3
	updatePath()
	
func destroy():
	stunMode()
	ANIMATOR.play('KO')
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
			print('Alert patrol move!')
			randomize()
			IDLE_TIMER.start(randf_range(1.0, 2.5))
			await IDLE_TIMER.timeout
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position
		2:
			NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position
		3: 
			print('Stunned!')
			BODY.velocity = Vector2.ZERO
			LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_DISABLED
			await get_tree().create_timer(5.0).timeout
			STATE = 1
			updatePath()
			print('Unstunned!')
			LINE_OF_SIGHT.process_mode = Node.PROCESS_MODE_ALWAYS

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
	
	if BODY.velocity == Vector2(0,0):
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
