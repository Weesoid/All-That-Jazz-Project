extends Node

@export var BODY: CharacterBody2D
@export var NAV_AGENT: NavigationAgent2D
@export var LINE_OF_SIGHT: LineOfSight
@export var ANIMATOR: AnimationPlayer
@export var MOVE_SPEED = 35

var STATE = 0
var PATH_UPDATE_TIMER: Timer
var IDLE_TIMER: Timer
var rng = RandomNumberGenerator.new()

func _ready():
	PATH_UPDATE_TIMER = Timer.new()
	PATH_UPDATE_TIMER.autostart = true
	PATH_UPDATE_TIMER.stop()
	PATH_UPDATE_TIMER.timeout.connect(updatePath)
	IDLE_TIMER = Timer.new()
	IDLE_TIMER.autostart = true
	add_child(IDLE_TIMER)
	add_child(PATH_UPDATE_TIMER)
	
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
		OverworldGlobals.changeToCombat(OverworldGlobals.getCombatantSquad('NPCPrototype'))
		BODY.queue_free()

func patrol():
	moveBody(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if LINE_OF_SIGHT.detectPlayer():
		PATH_UPDATE_TIMER.start(0.5)
		MOVE_SPEED = 135
		STATE = 1
		updatePath()
		moveBody(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if !NAV_AGENT.is_target_reachable():
		PATH_UPDATE_TIMER.stop()
		MOVE_SPEED = 35
		STATE = 0

func updatePath():
	if STATE == 0:
		IDLE_TIMER.start(rng.randf_range(1.0, 5.0))
		await IDLE_TIMER.timeout
		NAV_AGENT.target_position = moveRandom()
		
	elif STATE == 1:
		NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position

func moveRandom():
	rng.randomize()
	return BODY.global_position + Vector2(rng.randf_range(-100.0, 100.0), rng.randf_range(-100.0, 100.0))

func moveBody(target_position: Vector2):
	if targetReached():
		BODY.velocity = Vector2(0,0)
	elif !NAV_AGENT.get_current_navigation_path().is_empty():
		BODY.velocity = target_position * MOVE_SPEED
		updateLineOfSight()
	
	if BODY.velocity == Vector2(0,0):
		ANIMATOR.seek(1, true)
		ANIMATOR.pause()

func targetReached():
	return NAV_AGENT.distance_to_target() < 1

func updateLineOfSight():
	LINE_OF_SIGHT.look_at(NAV_AGENT.get_next_path_position())
	LINE_OF_SIGHT.rotation -= PI/2
	var look_direction = LINE_OF_SIGHT.global_rotation_degrees
	
	if look_direction < 135 and look_direction > 45:
		ANIMATOR.play('Walk_Left')
	elif look_direction < -45 and look_direction > -135:
		ANIMATOR.play('Walk_Right')
	elif look_direction < 45 and look_direction > -45:
		ANIMATOR.play('Walk_Down')
	else:
		ANIMATOR.play('Walk_Up')
	
func isBodyMoving():
	return BODY.velocity.length() > 0
