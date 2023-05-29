extends CharacterBody2D
class_name PlayerScene

@onready var player_camera = $PlayerCamera
@onready var interaction_detector = $PlayerDirection/InteractionDetector
@onready var player_animator = $PlayerAnimator
@onready var interaction_prompt = $PlayerInteractionBubble
@onready var interaction_prompt_animator = $PlayerInteractionBubble/BubbleAnimator

var direction = Vector2()
const SPEED = 100.0
const ANIMATION_SPEED = 1.5

func _ready():
	player_animator.speed_scale = ANIMATION_SPEED
	
func _process(_delta):
	if (OverworldGlobals.player_can_move):
		direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), 
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		direction = direction.normalized()
		velocity = direction * SPEED
		move_and_slide()
	
	animateInteract()
	animateWalk(direction)
	
func _unhandled_input(_event: InputEvent):
	if Input.is_action_just_pressed("ui_select"):
		var interactables = interaction_detector.get_overlapping_areas()
		if interactables.size() > 0:
			OverworldGlobals.show_player_interaction = false
			interactables[0].interact()
			return
	
func animateWalk(input):
	if input == Vector2(-1,0):
		player_animator.play('Walk_Left')
	if input == Vector2(1,0):
		player_animator.play('Walk_Right')
	if input == Vector2(0,1):
		player_animator.play('Walk_Down')
	if input == Vector2(0,-1):
		player_animator.play('Walk_Up')
	
	if (input == Vector2(0,0) || OverworldGlobals.player_can_move == false):
		player_animator.seek(1, true)
		player_animator.pause()
	
func animateInteract():
	interaction_prompt.visible = OverworldGlobals.show_player_interaction
	if (interaction_detector.get_overlapping_areas().size() > 0):
		interaction_prompt_animator.play('Interact')
	else:
		interaction_prompt_animator.play('RESET')
	
