extends CharacterBody2D
class_name GenericPatroller

enum State {
	IDLE,
	CHASING,
	STUNNED
}

@onready var shape = $CollisionShape2D
@onready var line_of_sight: RayCast2D = $LineOfSight
@onready var stun_timer = $StunTimer
@onready var detect_timer = $DetectTimer
@onready var detect_bar = $DetectBar
@onready var action_cooldown = $ActionCooldown
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var chase_indicator_animator = $ChaseIndicator/AnimationPlayer
@onready var edge_check_right = $EdgeCheckRight
@onready var edge_check_left = $EdgeCheckLeft
@onready var melee_hitbox = $MeleeHitbox
@onready var sprite = $Sprite2D

@export var base_move_speed: float = 20.0
@export var alerted_speed_multiplier: float = 5.0
@export var chase_speed_multiplier: float = 13.0
@export var min_action_distance: float = 25
@export var direction: int = -1
@export var detection_time: float
@export var action_cooldown_time: float
@export var stun_time: float

var state: State
var speed: float = 15.0
var combat_switch: bool = true
var patroller_group: PatrollerGroup
var flicker_tween: Tween

func _ready():
	if !has_node('CombatantSquadComponent'):
		CombatGlobals.generateCombatantSquad(self, CombatGlobals.Enemy_Factions.Scavs)
	if get_parent() is PatrollerGroup:
		patroller_group = get_parent()
	
	if detection_time > 0:
		detect_timer.wait_time = detection_time
	if action_cooldown_time > 0:
		action_cooldown.wait_time = action_cooldown_time
	if stun_time > 0:
		stun_timer.wait_time = stun_time

func updateState(new_state:State):
	if new_state == State.IDLE:
		chase_indicator_animator.play("RESET")
		state = new_state
	elif new_state == State.CHASING:
		chase_indicator_animator.play("Show")
		OverworldGlobals.playSound2D(global_position, "res://audio/sounds/413641__djlprojects__metal-gear-solid-inspired-alert-surprise-sfx.ogg")
		state = new_state
	elif new_state == State.STUNNED:
		chase_indicator_animator.play("RESET")
		animator.play("RESET")
		shape.set_deferred('disabled', true)
		state = new_state
		stun_timer.start()
		flickerTween(true)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
	
	doCollisionAction()
	match state:
		State.IDLE: patrol()
		State.CHASING: chase()
		State.STUNNED: stun()
	
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
	if state != 2:
		updateState(State.CHASING)

func patrol():
	# Direction changing
	checkEdges()
	checkPatrollerCollision()
	
	# Player in line of sight
	checkPlayer()
	velocity.x = direction*speed

func chase():
	# check y
	var y_pos = snappedf(shape.global_position.y,100.0)
	var y_pos_player = snappedf(OverworldGlobals.getPlayer().get_node('PlayerCollision').global_position.y, 100.0)
	if y_pos != y_pos_player:
		updateState(State.IDLE)
	
	var flat_pos:Vector2 = OverworldGlobals.flattenY(shape.global_position)
	var flat_palyer_pos:Vector2 = OverworldGlobals.flattenY(OverworldGlobals.getPlayer().get_node('PlayerCollision').global_position)
	# action
	if flat_pos.distance_to(flat_palyer_pos) <= min_action_distance and canDoAction():
		doAction()
	elif combat_switch and !animator.current_animation.contains('Action'):
		# chase!
		direction = (flat_pos.direction_to(flat_palyer_pos)).x
		velocity.x = (direction * speed) * chase_speed_multiplier

func stun():
	velocity = Vector2.ZERO

func _on_stun_timer_timeout():
	if shape.disabled: 
		shape.set_deferred('disabled', false)
	combat_switch = true
	updateState(State.CHASING)
	flickerTween(false)

func animateWalk():
	if animator.current_animation.contains('Action'):
		return
	if state == State.CHASING:
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
	
	if get_last_slide_collision().get_collider() is PlayerScene:
		combat_switch = false
		chase_indicator_animator.play("RESET")
		OverworldGlobals.changeToCombat(str(name),{},self)

func doAction():
	combat_switch = false
	velocity.x = 0
	action_cooldown.start()
	if sprite.flip_h:
		melee_hitbox.position = Vector2(-22,-23)
	else:
		melee_hitbox.position = Vector2(22,-23)
	animator.stop()
	animator.play('Action')
	await animator.animation_finished
	combat_switch = true

func canDoAction():
	return action_cooldown.is_stopped() and !animator.current_animation.contains('Action') and state != 2

func canEnterCombat(check_switch:bool=true)-> bool:
	return (combat_switch  or !check_switch) and is_instance_valid(self) and state != 2 and (OverworldGlobals.getCurrentMap().has_node('Player') and OverworldGlobals.isPlayerAlive())

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

func _on_melee_hitbox_body_entered(body):
	if body is PlayerScene and canEnterCombat(false): 
		OverworldGlobals.damageParty(5)
		OverworldGlobals.changeToCombat(str(name),{},self)

func destroy(give_drops=false):
	if give_drops:
		var combatant_squad: EnemyCombatantSquad = get_node("CombatantSquadComponent")
		patroller_group.reward_bank['experience'] += combatant_squad.getExperience()
		combatant_squad.addDrops()
		OverworldGlobals.getPlayer().player_camera.addRewardBank(patroller_group)
	
	updateState(GenericPatroller.State.STUNNED)
	queue_free()
	await tree_exited
	patroller_group.checkGiveRewards()
