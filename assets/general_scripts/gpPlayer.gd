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

var direction = Vector2()
var bow_mode = false
const SPEED = 100.0
const ANIMATION_SPEED = 1.5

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	player_animator.speed_scale = ANIMATION_SPEED
	print(animation_tree.tree_root)
	animation_tree.active = true

func _process(_delta):
	updateAnimationParameters()
	animateInteract()

func _physics_process(_delta):
	if (OverworldGlobals.player_can_move):
		direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), 
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		direction = direction.normalized()
		velocity = direction * SPEED
		move_and_slide()


func _unhandled_input(_event: InputEvent):
	if (OverworldGlobals.player_can_move):
		if Input.is_action_just_pressed("ui_select"):
			var interactables = interaction_detector.get_overlapping_areas()
			if interactables.size() > 0:
				velocity = Vector2.ZERO
				OverworldGlobals.show_player_interaction = false
				interactables[0].interact()
				return
				
		if Input.is_action_just_pressed("ui_cancel"):
			OverworldGlobals.showMenu()

func animateInteract():
	interaction_prompt.visible = OverworldGlobals.show_player_interaction
	if (interaction_detector.get_overlapping_areas().size() > 0) and OverworldGlobals.player_can_move:
		interaction_prompt_animator.play('Interact')
	elif !OverworldGlobals.player_can_move:
		interaction_prompt_animator.play('RESET')
	else:
		interaction_prompt_animator.play('RESET')
	
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
		
	if Input.is_action_just_pressed('ui_bow') and velocity == Vector2.ZERO and OverworldGlobals.player_can_move:
		bow_mode = !bow_mode
		animation_tree["parameters/conditions/equip_bow"] = bow_mode
		animation_tree["parameters/conditions/unequip_bow"] = !bow_mode
		if animation_tree["parameters/conditions/draw_bow"]:
			OverworldGlobals.player_can_move = true
			animation_tree["parameters/conditions/draw_bow"] = false
	
	if bow_mode:
		if Input.is_action_pressed('ui_click') and velocity == Vector2.ZERO and OverworldGlobals.player_can_move and !animation_tree["parameters/conditions/void_call"]:
			OverworldGlobals.player_can_move = false
			animation_tree["parameters/conditions/draw_bow"] = true
			animation_tree["parameters/conditions/shoot_bow"] = false
		if Input.is_action_just_released("ui_click"):
			animation_tree["parameters/conditions/draw_bow"] = false
			animation_tree["parameters/conditions/shoot_bow"] = true
			await get_tree().create_timer(0.6).timeout
			OverworldGlobals.player_can_move = true
			
	if Input.is_action_just_pressed('ui_gambit') and OverworldGlobals.player_can_move:
		animation_tree["parameters/conditions/void_call"] = !animation_tree["parameters/conditions/void_call"]
		# Code for invis ability!!!
		set_collision_layer_value(5, !get_collision_mask_value(5))
		set_collision_mask_value(5, !get_collision_mask_value(5))
		if !get_collision_mask_value(5):
			sprite.modulate.a = 0.5
		else:
			sprite.modulate.a = 1
		# end
		animation_tree["parameters/conditions/void_release"] = !animation_tree["parameters/conditions/void_call"]
	
