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
@onready var animation_tree = $AnimationTree
@onready var player_direction = $PlayerDirection
@onready var bow_line = $PlayerDirection/BowShotLine

var direction = Vector2()
var bow_mode = false
var bow_draw_strength = 0
var bow_max_draw = 5.0
var SPEED = 100.0
const ANIMATION_SPEED = 1.5

func _ready():
	PlayerGlobals.POWER = load("res://resources/powers/Stealth.tres")
	player_animator.speed_scale = ANIMATION_SPEED
	print(animation_tree.tree_root)
	animation_tree.active = true

func _process(_delta):
	updateAnimationParameters()
	animateInteract()
	if bow_mode:
		drawBow()

func _physics_process(_delta):
	if OverworldGlobals.player_can_move:
		direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), 
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		direction = direction.normalized()
		velocity = direction * SPEED
		move_and_slide()
	
		OverworldGlobals.follow_array.push_front(self.global_position)
		OverworldGlobals.follow_array.pop_back()


func _unhandled_input(_event: InputEvent):
	if Input.is_action_just_pressed("ui_cancel"):
		OverworldGlobals.showMenu("res://scenes/user_interface/PauseMenu.tscn")
	
	if Input.is_action_just_pressed("ui_select") and !OverworldGlobals.showing_menu and interaction_prompt.visible:
		var interactables = interaction_detector.get_overlapping_areas()
		if interactables.size() > 0:
			velocity = Vector2.ZERO
			undrawBowAnimation()
			OverworldGlobals.show_player_interaction = false
			interactables[0].interact()
			return
	
	if Input.is_action_just_pressed("ui_bow") and canDrawBow():
		if bow_draw_strength == 0: 
			bow_mode = !bow_mode
	
	if Input.is_action_just_pressed("ui_gambit") and bow_draw_strength == 0:
		if PlayerGlobals.POWER != null:
			PlayerGlobals.POWER.executePower(self)
		else:
			print('No power!')

func canDrawBow()-> bool:
	return direction == Vector2.ZERO and PlayerGlobals.EQUIPPED_ARROW.STACK > 0 and OverworldGlobals.show_player_interaction

func animateInteract():
	interaction_prompt.visible = OverworldGlobals.show_player_interaction
	if interaction_detector.get_overlapping_areas().size() > 0 and OverworldGlobals.player_can_move:
		interaction_prompt_animator.play('Interact')
	elif !OverworldGlobals.player_can_move:
		interaction_prompt_animator.play('RESET')
	else:
		interaction_prompt_animator.play('RESET')

func drawBow():
	print('STACKS: ', PlayerGlobals.EQUIPPED_ARROW.STACK)
	if Input.is_action_pressed("ui_click") and velocity == Vector2.ZERO and OverworldGlobals.show_player_interaction:
		OverworldGlobals.player_can_move = false
		bow_line.show()
		bow_line.global_position = global_position + Vector2(0, -10)
		bow_draw_strength += 0.1
		bow_line.points[1].y += 1
		if bow_draw_strength >= bow_max_draw:
			bow_line.points[1].y = 275
			bow_draw_strength = bow_max_draw
	
	if Input.is_action_just_released("ui_click"):
		if bow_draw_strength >= bow_max_draw: shootProjectile()
		undrawBow(bow_draw_strength >= bow_max_draw)

func undrawBow(wait=false):
	bow_line.hide()
	bow_line.points[1].y = 0
	bow_draw_strength = 0
	if wait: await get_tree().create_timer(0.6).timeout
	OverworldGlobals.player_can_move = true

func shootProjectile():
	PlayerGlobals.EQUIPPED_ARROW.use()
	var projectile = load("res://scenes/entities/Arrow.tscn").instantiate()
	projectile.global_position = global_position + Vector2(0, -10)
	projectile.SHOOTER = self
	get_tree().current_scene.add_child(projectile)
	projectile.rotation = player_direction.rotation + 1.57079994678497
	
	if PlayerGlobals.EQUIPPED_ARROW.STACK <= 0:
		bow_mode = false
		toggleBowAnimation()

func updateAnimationParameters():
	if velocity == Vector2.ZERO:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true
	
	if direction != Vector2.ZERO:
		animation_tree["parameters/Idle/blend_position"] = direction
		animation_tree["parameters/Walk/blend_position"] = direction
		animation_tree["parameters/Idle Bow/blend_position"] = direction
		animation_tree["parameters/Walk Bow/blend_position"] = direction
		animation_tree["parameters/Shoot Bow/blend_position"] = direction
		animation_tree["parameters/Draw Bow/blend_position"] = direction
	
	if Input.is_action_just_pressed('ui_bow') and !animation_tree["parameters/conditions/void_call"]:
		toggleBowAnimation()
		if animation_tree["parameters/conditions/draw_bow"]:
			bow_draw_strength = 0
			Input.action_release("ui_click")
			animation_tree["parameters/conditions/draw_bow"] = false
			animation_tree["parameters/conditions/cancel"] = true
	
	if bow_mode:
		if Input.is_action_pressed('ui_click') and OverworldGlobals.show_player_interaction and !animation_tree["parameters/conditions/void_call"]:
			animation_tree["parameters/conditions/draw_bow"] = true
			animation_tree["parameters/conditions/shoot_bow"] = false
			animation_tree["parameters/conditions/cancel"] = false
		
		if velocity != Vector2.ZERO:
			undrawBow()
			animation_tree["parameters/conditions/draw_bow"] = false
			animation_tree["parameters/conditions/cancel"] = true
		
		if Input.is_action_just_released("ui_click"):
			animation_tree["parameters/conditions/draw_bow"] = false
			if bow_draw_strength >= bow_max_draw:
				animation_tree["parameters/conditions/shoot_bow"] = true
			else:
				animation_tree["parameters/conditions/cancel"] = true
	
	if Input.is_action_just_pressed('ui_gambit') and PlayerGlobals.POWER != null:
		animation_tree["parameters/conditions/void_call"] = !animation_tree["parameters/conditions/void_call"]
		animation_tree["parameters/conditions/void_release"] = !animation_tree["parameters/conditions/void_call"]

func toggleBowAnimation():
	animation_tree["parameters/conditions/equip_bow"] = bow_mode
	animation_tree["parameters/conditions/unequip_bow"] = !bow_mode

func playShootAnimation():
	animation_tree["parameters/conditions/draw_bow"] = false
	animation_tree["parameters/conditions/shoot_bow"] = true

func undrawBowAnimation():
	undrawBow()
	animation_tree["parameters/conditions/draw_bow"] = false
	animation_tree["parameters/conditions/cancel"] = true

