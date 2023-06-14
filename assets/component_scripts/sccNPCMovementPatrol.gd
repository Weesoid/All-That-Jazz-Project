extends Node
## REFACTOR THIS, EXTEND IT TO NPCMovement

@export var BODY: CharacterBody2D
@export var NAV_AGENT: NavigationAgent2D
@export var LINE_OF_SIGHT: LineOfSight
@export var ANIMATOR: AnimationPlayer
@export var COMBAT_SQUAD: CombatantSquad
@export var BASE_MOVE_SPEED = 35
@export var PATROL_AREA: Area2D

var MOVE_SPEED
var PATROL_SHAPE
var STATE = 0
var PATH_UPDATE_TIMER: Timer
var IDLE_TIMER: Timer
var rng = RandomNumberGenerator.new()

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
		OverworldGlobals.changeToCombat(COMBAT_SQUAD.COMBATANT_SQUAD)
		BODY.queue_free()

func patrol():
	moveBody(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if LINE_OF_SIGHT.detectPlayer():
		MOVE_SPEED = BASE_MOVE_SPEED * 5
		STATE = 1
		updatePath()
		moveBody(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if !NAV_AGENT.is_target_reachable():
		PATH_UPDATE_TIMER.stop()
		MOVE_SPEED = BASE_MOVE_SPEED
		STATE = 0

func updatePath():
	if STATE == 0:
		IDLE_TIMER.start(randf_range(1.0, 5.0))
		await IDLE_TIMER.timeout
		NAV_AGENT.target_position = moveRandom()
		
	elif STATE == 1:
		NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position

func moveRandom():
	return Vector2(rng.randf_range(PATROL_SHAPE.global_position.x, PATROL_SHAPE.global_position.x + PATROL_SHAPE.shape.get_rect().end.x),
					rng.randf_range(PATROL_SHAPE.global_position.y, PATROL_SHAPE.global_position.y + PATROL_SHAPE.shape.get_rect().end.y))


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
	return NAV_AGENT.distance_to_target() < 1.0

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
