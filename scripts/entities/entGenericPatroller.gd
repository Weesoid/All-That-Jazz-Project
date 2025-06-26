extends CharacterBody2D
class_name GenericPatroller

@onready var shape = $CollisionShape2D
@onready var line_of_sight = $LineOfSight
@onready var stun_timer = $StunTimer
@onready var detect_timer = $DetectTimer
@onready var detect_bar = $DetectBar
@onready var action_cooldown = $ActionCooldown
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var chase_indicator_animator = $ChaseIndicator/AnimationPlayer
@onready var edge_check_right = $EdgeCheckRight
@onready var edge_check_left = $EdgeCheckLeft
@onready var melee_hitbox = $MeleeHitbox
#@export var patrol_area: Area2D
@export var base_move_speed: float = 20.0
@export var alerted_speed_multiplier: float = 5.0
@export var chase_speed_multiplier: float = 13.0
@export var detection_time: float
@export var idle_time: Dictionary = {'patrol':0.0, 'alerted_patrol':0.0}
@export var stun_time: Dictionary = {'min':0.0, 'max':0.0}
@export var direction: int = -1

var state: int
var speed: float = 15.0
var combat_switch: bool = true
var flicker_tween: Tween

#func _ready():
#	patrol_component.COMBAT_SQUAD = get_node('CombatantSquadComponent')
#	spawnPatrolArea()
#
#	if base_move_speed != 0:
#		patrol_component.BASE_MOVE_SPEED = base_move_speed
#	if alerted_speed_multiplier != 0:
#		patrol_component.ALERTED_SPEED_MULTIPLIER = alerted_speed_multiplier
#	if chase_speed_multiplier != 0:
#		patrol_component.CHASE_SPEED_MULTIPLIER = chase_speed_multiplier
#	if detection_time != 0:
#		patrol_component.DETECTION_TIME = detection_time
#	if idle_time['patrol'] > 0.0 and idle_time['alerted_patrol'] > 0.0:
#		patrol_component.IDLE_TIME = idle_time
#	if stun_time['min'] > 0.0 and stun_time['max'] > 0.0:
#		patrol_component.STUN_TIME = stun_time
#
#	patrol_component.initialize()
#	patrol_component.get_node('DetectBar').initialize()


func updateState(new_state:int):
	if new_state == 0:
		chase_indicator_animator.play("RESET")
		state = new_state
	elif new_state == 1:
		chase_indicator_animator.play("Show")
		OverworldGlobals.playSound2D(global_position, "res://audio/sounds/413641__djlprojects__metal-gear-solid-inspired-alert-surprise-sfx.ogg")
		state = new_state
	elif new_state == 2:
		chase_indicator_animator.play("RESET")
		shape.set_deferred('disabled', true)
		state = new_state
		stun_timer.start()
		flickerTween(true)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
	
	doCollisionAction()
	match state:
		0: patrol()
		1: chase()
		2: stun()
	
	animateWalk()
	move_and_slide()

func checkEdges():
	if not is_on_floor():
		return
	
	if edge_check_left.get_collider() == null:
		direction = 1
	elif edge_check_right.get_collider() == null:
		direction = -1

func checkPatrollerCollision():
	if get_last_slide_collision() != null and get_last_slide_collision().get_collider() is GenericPatroller:
		direction *= -1

func checkPlayer():
	if line_of_sight.get_collider() is PlayerScene:
		if detect_timer.is_stopped(): 
			detect_timer.start()
	elif !detect_timer.is_stopped():
		detect_timer.stop()

func _on_detect_timer_timeout():
	updateState(1)

func patrol():
	# Direction changing
	checkEdges()
	checkPatrollerCollision()
	# Player in line of sight
	checkPlayer()
	velocity.x = direction*speed

func chase():
	var y_pos = snappedf(shape.global_position.y,100.0)
	var y_pos_player = snappedf(OverworldGlobals.getPlayer().get_node('PlayerCollision').global_position.y, 100.0)
	if y_pos != y_pos_player:
		updateState(0)
	
	var flat_pos:Vector2 = OverworldGlobals.flattenY(shape.global_position)
	var flat_palyer_pos:Vector2 = OverworldGlobals.flattenY(OverworldGlobals.getPlayer().get_node('PlayerCollision').global_position)
	
	direction = (flat_pos.direction_to(flat_palyer_pos)).x
	velocity.x = (direction * speed) * chase_speed_multiplier

func stun():
	velocity = Vector2.ZERO

func _on_stun_timer_timeout():
	if shape.disabled: 
		shape.set_deferred('disabled', false)
	combat_switch = true
	updateState(1)
	flickerTween(false)

func animateWalk():
	if animator.current_animation == 'Action':
		return
	if state == 1:
		animator.advance(get_physics_process_delta_time()*1.5)
	
	if direction == -1 and velocity.x != 0:
		animator.play('Walk_Right')
	elif direction == 1 and velocity.x != 0:
		animator.play('Walk_Left')
	elif velocity == Vector2.ZERO:
		animator.seek(1, true)
		animator.pause()

func doCollisionAction():
	if get_slide_collision_count() == 0 or !OverworldGlobals.getCurrentMap().done_loading_map or !canEnterCombat():
		return
	
	# REFINE LATER, GET IN RANGE THEN SWING TYPE SHI
	if get_last_slide_collision().get_collider() is PlayerScene:

		chase_indicator_animator.play("RESET")
		combat_switch = false
		OverworldGlobals.changeToCombat(str(name))

func doAction():
	if canDoAction():
		action_cooldown.start()
		animator.stop()
		animator.play('Action')
		for body in melee_hitbox.get_overlapping_bodies():
			if body is PlayerScene: OverworldGlobals.damageParty(5)
			

func canDoAction():
	return action_cooldown.is_stopped() and animator.current_animation != 'Action'

func canEnterCombat()-> bool:
	return combat_switch and state != 2 and (OverworldGlobals.getCurrentMap().has_node('Player') and OverworldGlobals.isPlayerAlive())

func flickerTween(play:bool):
	if flicker_tween == null:
		flicker_tween = create_tween().set_loops()
		flicker_tween.tween_property(get_node('Sprite2D'),'self_modulate', Color(Color.WHITE, 0.5), 0.5).from(Color.WHITE)
	
	var sprite = get_node('Sprite2D')
	if play:
		sprite.modulate = Color.DARK_GRAY
		flicker_tween.play()
	else:
		flicker_tween.stop()
		sprite.modulate = Color.WHITE
		sprite.self_modulate = Color.WHITE
