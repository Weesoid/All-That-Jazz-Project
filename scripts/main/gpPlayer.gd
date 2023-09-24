# Draw bow, set anchor, use anchor when drawn, get locked into void channel.
# SOLUTION: Channel / Instant cast animation depending on power type

extends CharacterBody2D
class_name PlayerScene

@onready var player_camera = $PlayerCamera
@onready var sprite = $PlayerSprite
@onready var interaction_detector = $PlayerDirection/InteractionDetector
@onready var player_animator = $PlayerAnimator
@onready var interaction_prompt = $PlayerInteractionBubble
@onready var interaction_prompt_animator = $PlayerInteractionBubble/BubbleAnimator
@onready var player_direction = $PlayerDirection
@onready var bow_line = $PlayerDirection/BowShotLine
@onready var squad = $CombatantSquadComponent
@onready var ammo_count = $PlayerCamera/Ammo
@onready var prompt = $PlayerCamera/PlayerPrompt
@onready var animation_tree = $AnimationTree

var stamina = 100.0
var direction = Vector2()
var bow_mode = false
var bow_draw_strength = 0
var bow_max_draw = 4.0
var SPEED = 100.0

var walk_speed = 100.0
var sprint_speed = 200.0
var sprint_drain = 0.10
var stamina_gain = 0.10

var ANIMATION_SPEED = 0.0

signal stance_changed
signal bow_shot

func _ready():
	animation_tree.active = true
	PlayerGlobals.POWER = load("res://resources/powers/Stealth.tres")
	SPEED = walk_speed

func _process(_delta):
	updateAnimationParameters()
	animateInteract()
	if bow_mode:
		drawBow()
		ammo_count.show()
		ammo_count.text = str(PlayerGlobals.EQUIPPED_ARROW.STACK)
	else:
		ammo_count.hide()

func _physics_process(_delta):
	if OverworldGlobals.player_can_move:
		direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), 
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		direction = direction.normalized()
		velocity = direction * SPEED
		move_and_slide()
	
	if Input.is_action_pressed("ui_sprint") and stamina > 0.0:
		SPEED = sprint_speed
		ANIMATION_SPEED = 1.0
		if velocity != Vector2.ZERO: stamina -= sprint_drain
	else:
		if stamina != 100 and !Input.is_action_pressed("ui_sprint"): stamina += stamina_gain
		SPEED = walk_speed
		ANIMATION_SPEED = 0.0
	
	OverworldGlobals.follow_array.push_front(self.global_position)
	OverworldGlobals.follow_array.pop_back()


func _unhandled_input(_event: InputEvent):
	if Input.is_action_just_pressed("ui_cancel"):
		OverworldGlobals.showMenu("res://scenes/user_interface/PauseMenu.tscn")
	
	if Input.is_action_just_pressed("ui_select") and !OverworldGlobals.showing_menu and interaction_prompt.visible:
		var interactables = interaction_detector.get_overlapping_areas()
		if interactables.size() > 0:
			velocity = Vector2.ZERO
			OverworldGlobals.show_player_interaction = false
			interactables[0].interact()
			return
	
	if Input.is_action_just_pressed("ui_bow") and canDrawBow():
		if bow_draw_strength == 0: 
			bow_mode = !bow_mode
			if bow_mode:
				changeStance('bow')
			else:
				changeStance('regular')
	
	if Input.is_action_just_pressed("ui_gambit") and bow_draw_strength == 0:
		if PlayerGlobals.POWER != null:
			PlayerGlobals.POWER.executePower(self)
		else:
			print('No power!')

func canDrawBow()-> bool:
	return direction == Vector2.ZERO and OverworldGlobals.show_player_interaction #and PlayerGlobals.EQUIPPED_ARROW.STACK > 0 

func animateInteract():
	interaction_prompt.visible = OverworldGlobals.show_player_interaction
	if interaction_detector.get_overlapping_areas().size() > 0 and OverworldGlobals.player_can_move:
		interaction_prompt_animator.play('Interact')
	elif !OverworldGlobals.player_can_move:
		interaction_prompt_animator.play('RESET')
	else:
		interaction_prompt_animator.play('RESET')

func drawBow():
	if Input.is_action_pressed("ui_click") and OverworldGlobals.show_player_interaction and OverworldGlobals.player_can_move:
		changeStance('draw')
		SPEED = 15.0
		bow_line.show()
		bow_line.global_position = global_position + Vector2(0, -10)
		bow_draw_strength += 0.1
		bow_line.points[1].y += 1
		
		print(velocity)
		if velocity == Vector2.ZERO:
			bow_line.default_color.a = 1.0
		else:
			bow_line.default_color.a = 0.25
		
		if bow_draw_strength >= bow_max_draw:
			stamina -= 0.25
			bow_line.points[1].y = 275
			bow_draw_strength = bow_max_draw
			if Input.is_action_just_pressed("ui_bow"):
				await stance_changed
				undrawBow(true)
				bow_mode = false
		if stamina <= 0:
			Input.action_release("ui_click")
	
	
	if Input.is_action_just_released("ui_click"):
		if bow_draw_strength >= bow_max_draw and velocity == Vector2.ZERO: 
			shootProjectile()
		
		await stance_changed
		undrawBow()

func undrawBow(change_to_regular=false):
	if !change_to_regular:
		changeStance('bow')
	else:
		changeStance('regular')
	bow_line.hide()
	bow_line.points[1].y = 0
	bow_draw_strength = 0
	SPEED = walk_speed
	
	#OverworldGlobals.player_can_move = true

func shootProjectile():
	
	PlayerGlobals.removeItemResource(PlayerGlobals.EQUIPPED_ARROW)
	var projectile = load("res://scenes/entities/Arrow.tscn").instantiate()
	projectile.global_position = global_position + Vector2(0, -10)
	projectile.SHOOTER = self
	get_tree().current_scene.add_child(projectile)
	projectile.rotation = player_direction.rotation + 1.57079994678497
	animateShootBow()

	
func updateAnimationParameters():
	if velocity == Vector2.ZERO:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true
	
	if direction != Vector2.ZERO and bow_draw_strength == 0 and OverworldGlobals.player_can_move:
		animation_tree["parameters/Idle/blend_position"] = direction
		animation_tree["parameters/ShootBow/blend_position"] = direction
		animation_tree["parameters/Walk/blend_position"] = direction

func changeStance(stance: String):
	match stance:
		'regular': 
			animation_tree["parameters/conditions/stance_regular"] = true
			animation_tree["parameters/conditions/stance_bow"] = false
			animation_tree["parameters/conditions/stance_draw"] = false
		'bow':
			animation_tree["parameters/conditions/stance_bow"] = true
			animation_tree["parameters/conditions/stance_regular"] = false
			animation_tree["parameters/conditions/stance_draw"] = false
		'draw':
			animation_tree["parameters/conditions/stance_draw"] = true
			animation_tree["parameters/conditions/stance_regular"] = false
			animation_tree["parameters/conditions/stance_bow"] = false
	
	await get_tree().create_timer(0.05).timeout
	animation_tree["parameters/conditions/stance_draw"] = false
	animation_tree["parameters/conditions/stance_regular"] = false
	animation_tree["parameters/conditions/stance_bow"] = false
	stance_changed.emit()

func animateShootBow():
	OverworldGlobals.player_can_move = false
	animation_tree["parameters/conditions/shoot_bow"] = true
	await animation_tree.animation_finished
	animation_tree["parameters/conditions/shoot_bow"] = false
	OverworldGlobals.player_can_move = true
	if PlayerGlobals.EQUIPPED_ARROW.STACK <= 0:
		bow_mode = false
		changeStance('regular')
	else:
		changeStance('bow')
