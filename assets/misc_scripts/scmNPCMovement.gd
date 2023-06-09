extends Node

# State variable
@export var BODY: CharacterBody2D
@export var LINE_OF_SIGHT: RayCast2D
@export var NAV_AGENT: NavigationAgent2D
@export var PATH_UPDATE_TIMER: Timer
@export var MOVE_SPEED = 35
@export var ANIMATOR: AnimationPlayer

var STATE = 0
var rng = RandomNumberGenerator.new()

func _ready():
	PATH_UPDATE_TIMER.start(5.0)
	PATH_UPDATE_TIMER.timeout.connect(updatePath)
	NAV_AGENT.navigation_finished.connect(updatePath)
	NAV_AGENT.navigation_finished.emit()

func _physics_process(_delta):
	patrol()
	BODY.move_and_slide()

func patrol():
	moveBody(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	updateLineOfSight(NAV_AGENT.get_next_path_position())
	LINE_OF_SIGHT.force_raycast_update()
	
	if detectPlayer():
		PATH_UPDATE_TIMER.start(0.5)
		MOVE_SPEED = 135
		STATE = 1
		updatePath()
		moveBody(BODY.to_local(NAV_AGENT.get_next_path_position()).normalized())
	
	if !NAV_AGENT.is_target_reachable():
		PATH_UPDATE_TIMER.start(10.0)
		MOVE_SPEED = 35
		STATE = 0

func detectPlayer()-> bool:
	# TO-DO SWEEPING RAYCAST TO DETECT PLAYER
	# Other possible solution: Use Area2D as directional, if player enters Area2D zone,
	# Attempt to make raycast look at player, if it hits the player, process
	# If player leaves area2d, reset raycast pos
	if LINE_OF_SIGHT.get_collider() == OverworldGlobals.getPlayer():
		print('FOund!')
		return true
	return false

func updatePath():
	if STATE == 0:
		rng.randomize()
		# TO-DO: Make random direction relative to body
		NAV_AGENT.target_position = Vector2(rng.randf_range(-100.0, 100.0), rng.randf_range(-100.0, 100.0))
	elif STATE == 1:
		NAV_AGENT.target_position = OverworldGlobals.getPlayer().global_position

func moveBody(target_position: Vector2):
	BODY.velocity = target_position * MOVE_SPEED

func updateLineOfSight(look_at_coordinates: Vector2):
	LINE_OF_SIGHT.look_at(NAV_AGENT.get_next_path_position())
	LINE_OF_SIGHT.rotation -= PI/2
	if LINE_OF_SIGHT.global_rotation_degrees < 135 and LINE_OF_SIGHT.global_rotation_degrees > 	45:
		ANIMATOR.play('Walk_Left')
	elif LINE_OF_SIGHT.global_rotation_degrees < -45 and LINE_OF_SIGHT.global_rotation_degrees > -135:
		ANIMATOR.play('Walk_Right')
	elif LINE_OF_SIGHT.global_rotation_degrees < 45 and LINE_OF_SIGHT.global_rotation_degrees > -45:
		ANIMATOR.play('Walk_Down')
	else:
		ANIMATOR.play('Walk_Up')
