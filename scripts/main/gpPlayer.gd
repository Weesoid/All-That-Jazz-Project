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
@onready var squad = $CombatantSquadComponent
@onready var ammo_count = $PlayerCamera/Ammo
@onready var prompt = $PlayerCamera/PlayerPrompt
@onready var audio_player = $ScriptAudioPlayer

var stamina = 100.0
var direction = Vector2()

var channeling_power = false

var bow_mode = false
var bow_draw_strength = 0
var bow_max_draw = 5.0
var SPEED = 100.0

var walk_speed = 100.0
var sprint_speed = 200.0
var sprint_drain = 0.10
var stamina_gain = 0.10
var stamina_regen = true

var ANIMATION_SPEED = 0.0

var play_once = true

func _ready():
	player_camera.global_position = global_position
	PlayerGlobals.POWER = load("res://resources/powers/Stealth.tres")
	SPEED = walk_speed
	animation_tree.active = true

func _process(_delta):
	updateAnimationParameters()
	animateInteract()
	if bow_mode:
		drawBow()
		ammo_count.show()
		ammo_count.text = str(PlayerGlobals.EQUIPPED_ARROW.STACK)
	else:
		ammo_count.hide()

func _physics_process(delta):
	animation_tree.advance(ANIMATION_SPEED * delta)
	if OverworldGlobals.player_can_move:
		direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), 
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		direction = direction.normalized()
		velocity = direction * SPEED
		move_and_slide()
	
	if stamina <= 0.0 and animation_tree["parameters/conditions/draw_bow"]:
		Input.action_release("ui_click")
	
	if Input.is_action_pressed("ui_sprint") and stamina > 0.0 and bow_draw_strength == 0:
		SPEED = sprint_speed
		ANIMATION_SPEED = 1.0
		if velocity != Vector2.ZERO: stamina -= sprint_drain
	elif bow_draw_strength >= bow_max_draw:
		if stamina > 0.0:
			stamina -= 0.1
	elif Input.is_action_pressed("ui_sprint") and stamina < 0.0:
		SPEED = walk_speed
		ANIMATION_SPEED = 0.0
	elif !Input.is_action_pressed("ui_sprint") and stamina < 100 and stamina_regen:
		stamina += stamina_gain
	
	if Input.is_action_just_released("ui_sprint"):
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
			prompt.showPrompt("No [color=gray]Gambit[/color] binded.")

func canDrawBow()-> bool:
	if velocity != Vector2.ZERO:
		return false
	elif PlayerGlobals.EQUIPPED_ARROW.STACK <= 0:
		prompt.showPrompt("No more [color=yellow]%ss[/color]." % PlayerGlobals.EQUIPPED_ARROW.NAME)
		return false
	
	return true

func animateInteract():
	interaction_prompt.visible = OverworldGlobals.show_player_interaction
	if interaction_detector.get_overlapping_areas().size() > 0 and OverworldGlobals.player_can_move:
		interaction_prompt_animator.play('Interact')
	elif !OverworldGlobals.player_can_move:
		interaction_prompt_animator.play('RESET')
	else:
		interaction_prompt_animator.play('RESET')

func drawBow():
	if PlayerGlobals.EQUIPPED_ARROW.STACK <= 0:
		bow_mode = false
		toggleBowAnimation()
	
	if Input.is_action_pressed("ui_click") and OverworldGlobals.show_player_interaction and !animation_tree["parameters/conditions/void_call"]:
		#OverworldGlobals.player_can_move = false
		SPEED = 15.0
		if play_once:
			playAudio('bow-loading-38752.ogg',0.0,true)
			play_once = false
		bow_line.show()
		bow_line.global_position = global_position + Vector2(0, -10)
		bow_draw_strength += 0.1
		bow_line.points[1].y += 1
		if velocity != Vector2.ZERO:
			bow_line.default_color.a = 0.10
		else:
			bow_line.default_color.a = 0.5
		if bow_draw_strength >= bow_max_draw:
			#player_camera.zoom = lerp(player_camera.zoom, Vector2(1.75, 1.75), 0.25)
			bow_line.points[1].y = 275
			bow_draw_strength = bow_max_draw
	
	if Input.is_action_just_released("ui_click") and velocity == Vector2.ZERO:
		if bow_draw_strength >= bow_max_draw: shootProjectile()
		undrawBow()

func undrawBow():
	bow_line.hide()
	bow_line.points[1].y = 0
	bow_draw_strength = 0
	SPEED = walk_speed
	play_once = true
	#player_camera.zoom =  Vector2(2.0, 2.0)
	#OverworldGlobals.player_can_move = true

func shootProjectile():
	playAudio("178872__hanbaal__bow.ogg", -15.0, true)
	InventoryGlobals.removeItemResource(PlayerGlobals.EQUIPPED_ARROW)
	var projectile = load("res://scenes/entities/Arrow.tscn").instantiate()
	projectile.global_position = global_position + Vector2(0, -10)
	projectile.SHOOTER = self
	get_tree().current_scene.add_child(projectile)
	projectile.rotation = player_direction.rotation + 1.57079994678497

func playAudio(filename: String, db=0.0, random_pitch=false):
	audio_player.pitch_scale = 1
	audio_player.stream = load("res://assets/sounds/%s" % filename)
	audio_player.volume_db = db
	if random_pitch:
		randomize()
		audio_player.pitch_scale += randf_range(0.0, 0.25)
	
	audio_player.play()

func updateAnimationParameters():
	if velocity == Vector2.ZERO:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true
	
	if direction != Vector2.ZERO and bow_draw_strength == 0:
		animation_tree["parameters/Idle/blend_position"] = direction
		animation_tree["parameters/Walk/blend_position"] = direction
		animation_tree["parameters/Idle Bow/blend_position"] = direction
		animation_tree["parameters/Walk Bow/blend_position"] = direction
		animation_tree["parameters/Shoot Bow/blend_position"] = direction
		animation_tree["parameters/Draw Bow/blend_position"] = direction
		animation_tree["parameters/Draw Bow Walk/blend_position"] = direction
	
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
		
		if Input.is_action_just_released("ui_click"):
			animation_tree["parameters/conditions/draw_bow"] = false
			if bow_draw_strength >= bow_max_draw and velocity == Vector2.ZERO:
				OverworldGlobals.player_can_move = false
				animation_tree["parameters/conditions/shoot_bow"] = true
				await animation_tree.animation_finished
				OverworldGlobals.player_can_move = true
			else:
				undrawBow()
				animation_tree["parameters/conditions/cancel"] = true
	
	if Input.is_action_just_pressed('ui_gambit') and PlayerGlobals.POWER != null and bow_draw_strength == 0:
		toggleVoidAnimation()

func toggleVoidAnimation():
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

