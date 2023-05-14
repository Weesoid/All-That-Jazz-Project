extends CharacterBody2D

@onready var interaction_detector = $PlayerDirection/InteractionDetector

var direction = Vector2()
const SPEED = 100.0
const ANIMATION_SPEED = 1.5

func _ready():
	$PlayerAnimator.speed_scale = ANIMATION_SPEED

func _process(delta):
	# MOVEMENT
	if (Globals.player_can_move):
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
			Globals.show_player_interaction = false
			interactables[0].interact()
			return

func animateWalk(input):
	if input == Vector2(-1,0):
		$PlayerAnimator.play('Walk_Left')
	if input == Vector2(1,0):
		$PlayerAnimator.play('Walk_Right')
	if input == Vector2(0,1):
		$PlayerAnimator.play('Walk_Down')
	if input == Vector2(0,-1):
		$PlayerAnimator.play('Walk_Up')

	if (input == Vector2(0,0) || Globals.player_can_move == false):
		$PlayerAnimator.seek(1, true)
		$PlayerAnimator.pause()

func animateInteract():
	$PlayerInteractionBubble.visible = Globals.show_player_interaction
	if (interaction_detector.get_overlapping_areas().size() > 0):
		$PlayerInteractionBubble/BubbleAnimator.play('Interact')
	else:
		$PlayerInteractionBubble/BubbleAnimator.play('RESET')
