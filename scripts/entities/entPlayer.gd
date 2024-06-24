extends CharacterBody2D
class_name PlayerScene

@onready var player_camera = $PlayerCamera
@onready var sprite = $Sprite2D
@onready var interaction_detector = $PlayerDirection/InteractionDetector
@onready var player_animator = $WalkingAnimations
@onready var interaction_prompt = $PlayerInteractionBubble
@onready var interaction_prompt_animator = $PlayerInteractionBubble/BubbleAnimator
@onready var animation_tree = $AnimationTree
@onready var cast_animator = $PowerAnimator
@onready var player_direction = $PlayerDirection
@onready var bow_line = $PlayerDirection/BowShotLine
@onready var squad = $CombatantSquadComponent
@onready var ammo_count = $PlayerCamera/Ammo
@onready var prompt = $PlayerCamera/PlayerPrompt
@onready var audio_player = $ScriptAudioPlayer
@onready var cinematic_bars = $PlayerCamera/CinematicBars

var can_move = true
var direction = Vector2()
var channeling_power = false
var bow_mode = false
var bow_draw_strength = 0
var SPEED = 100.0
var stamina_regen = true
var play_once = true
var ANIMATION_SPEED = 0.0

func _ready():
	player_camera.global_position = global_position
	SPEED = PlayerGlobals.walk_speed
	animation_tree.active = true
	PlayerGlobals.loadSquad()
	add_child(load("res://scenes/components/DebugComponent.tscn").instantiate())

func _process(_delta):
	updateAnimationParameters()
	animateInteract()

func _physics_process(delta):
	animation_tree.advance(ANIMATION_SPEED * delta)
	if bow_mode and !OverworldGlobals.inDialogue() and !OverworldGlobals.inMenu():
		drawBow()
		ammo_count.show()
		ammo_count.text = str(PlayerGlobals.EQUIPPED_ARROW.STACK)
	else:
		ammo_count.hide()
	
	if can_move and !OverworldGlobals.inMenu():
		direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), 
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		direction = direction.normalized()
		velocity = direction * SPEED
		move_and_slide()
	
	if PlayerGlobals.stamina <= 0.0 and animation_tree["parameters/conditions/draw_bow"]:
		Input.action_press("ui_bow")
	
	if Input.is_action_pressed("ui_sprint") and PlayerGlobals.stamina > 0.0 and bow_draw_strength == 0:
		SPEED = PlayerGlobals.sprint_speed
		ANIMATION_SPEED = 1.0
		if velocity != Vector2.ZERO: PlayerGlobals.stamina -= PlayerGlobals.sprint_drain
	elif bow_draw_strength >= PlayerGlobals.bow_max_draw:
		if PlayerGlobals.stamina > 0.0:
			PlayerGlobals.stamina -= 0.1
	elif Input.is_action_pressed("ui_sprint") and PlayerGlobals.stamina < 0.0:
		SPEED = PlayerGlobals.walk_speed
		ANIMATION_SPEED = 0.0
	elif !Input.is_action_pressed("ui_sprint") and PlayerGlobals.stamina < 100 and stamina_regen:
		PlayerGlobals.stamina += PlayerGlobals.stamina_gain
	
	if PlayerGlobals.stamina > 100.0:
		PlayerGlobals.stamina = 100.0
	
	if Input.is_action_just_released("ui_sprint"):
		SPEED = PlayerGlobals.walk_speed
		ANIMATION_SPEED = 0.0
	
	OverworldGlobals.follow_array.push_front(self.global_position)
	OverworldGlobals.follow_array.pop_back()

func resetStates():
	undrawBowAnimation()
	SPEED = PlayerGlobals.walk_speed
	ANIMATION_SPEED = 0.0

func _unhandled_input(_event: InputEvent):
	if Input.is_action_just_pressed("ui_cancel"):
		OverworldGlobals.showMenu("res://scenes/user_interface/PauseMenu.tscn")
	
	if Input.is_action_just_pressed("ui_select") and !channeling_power and !OverworldGlobals.inMenu():
		var interactables = interaction_detector.get_overlapping_areas()
		if interactables.size() > 0:
			velocity = Vector2.ZERO
			undrawBowAnimation()
			interactables[0].interact()
			return
	
	if Input.is_action_just_pressed("ui_bow") and canDrawBow():
		if bow_draw_strength == 0: 
			bow_mode = !bow_mode
	
	if Input.is_action_just_pressed("ui_gambit") and canUsePower():
		if PlayerGlobals.POWER != null:
			PlayerGlobals.POWER.executePower(self)
		else:
			prompt.showPrompt("No [color=gray]Gambit[/color] binded.")
	
	if Input.is_action_pressed("ui_cheat_mode"):
		if !has_node('DebugComponent'):
			add_child(load("res://scenes/components/DebugComponent.tscn").instantiate())
		else:
			get_node('DebugComponent').queue_free()

func canDrawBow()-> bool:
	if OverworldGlobals.inMenu():
		return false
	
	if OverworldGlobals.getCurrentMapData().SAFE:
		prompt.showPrompt("Can't use [color=yellow]Bow[/color] right now.")
		return false
	
	if velocity != Vector2.ZERO:
		return false
	elif PlayerGlobals.EQUIPPED_ARROW.STACK <= 0:
		prompt.showPrompt("No more [color=yellow]%ss[/color]." % PlayerGlobals.EQUIPPED_ARROW.NAME)
		return false
	
	return true

func canUsePower():
	if OverworldGlobals.inMenu():
		return false
	
	if OverworldGlobals.getCurrentMapData().SAFE:
		prompt.showPrompt("Can't use [color=gray]Gambit[/color] right now.")
		return false
	
	if bow_draw_strength != 0.0:
		return false
	
	return true

func animateInteract():
	if interaction_detector.get_overlapping_areas().size() > 0 and !OverworldGlobals.inDialogue() and !OverworldGlobals.inMenu() and !channeling_power and can_move:
		interaction_prompt.visible = true
		interaction_prompt_animator.play('Interact')
	else:
		interaction_prompt_animator.play('RESET')

func drawBow():
	if PlayerGlobals.EQUIPPED_ARROW.STACK <= 0:
		bow_mode = false
		toggleBowAnimation()
	
	if Input.is_action_pressed("ui_click") and !animation_tree["parameters/conditions/void_call"] and !OverworldGlobals.inDialogue() and !OverworldGlobals.inMenu():
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
		if bow_draw_strength >= PlayerGlobals.bow_max_draw:
			bow_line.points[1].y = 275
			bow_draw_strength = PlayerGlobals.bow_max_draw
	
	if Input.is_action_just_released("ui_click") and velocity == Vector2.ZERO:
		if bow_draw_strength >= PlayerGlobals.bow_max_draw: 
			shootProjectile()
		await get_tree().create_timer(0.05).timeout
		undrawBow()

func undrawBow():
	bow_line.hide()
	bow_line.points[1].y = 0
	bow_draw_strength = 0
	SPEED = PlayerGlobals.walk_speed
	play_once = true

func shootProjectile():
	OverworldGlobals.playSound("178872__hanbaal__bow.ogg", -15.0, true)
	InventoryGlobals.removeItemResource(PlayerGlobals.EQUIPPED_ARROW)
	var projectile = load("res://scenes/entities_disposable/Arrow.tscn").instantiate()
	projectile.global_position = global_position + Vector2(0, -10)
	projectile.SHOOTER = self
	get_tree().current_scene.add_child(projectile)
	projectile.rotation = player_direction.rotation + 1.57079994678497

func playAudio(filename: String, db=0.0, random_pitch=false):
	audio_player.pitch_scale = 1
	audio_player.stream = load("res://audio/sounds/%s" % filename)
	audio_player.volume_db = db
	if random_pitch:
		randomize()
		audio_player.pitch_scale += randf_range(0.0, 0.25)
	audio_player.play()

# Based on https://www.youtube.com/watch?v=WrMORzl3g1U
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
		if Input.is_action_pressed('ui_click') and !animation_tree["parameters/conditions/void_call"] and !OverworldGlobals.inDialogue() and !OverworldGlobals.inMenu():
			animation_tree["parameters/conditions/draw_bow"] = true
			animation_tree["parameters/conditions/shoot_bow"] = false
			animation_tree["parameters/conditions/cancel"] = false
		
		if Input.is_action_just_released("ui_click"):
			animation_tree["parameters/conditions/draw_bow"] = false
			if bow_draw_strength >= PlayerGlobals.bow_max_draw and velocity == Vector2.ZERO:
				animation_tree["parameters/conditions/shoot_bow"] = true
				can_move = false
				await animation_tree.animation_finished
				can_move = true
			else:
				undrawBow()
				animation_tree["parameters/conditions/cancel"] = true

func toggleVoidAnimation(enabled: bool):
	if enabled:
		animation_tree["parameters/conditions/void_call"] = true
		animation_tree["parameters/conditions/void_release"] = false
	else:
		animation_tree["parameters/conditions/void_call"] = false
		animation_tree["parameters/conditions/void_release"] = true

func toggleBowAnimation():
	animation_tree["parameters/conditions/equip_bow"] = bow_mode
	animation_tree["parameters/conditions/unequip_bow"] = !bow_mode

func playShootAnimation():
	animation_tree["parameters/conditions/draw_bow"] = false
	animation_tree["parameters/conditions/shoot_bow"] = true

func playCastAnimation():
	cast_animator.play("Show")

func undrawBowAnimation():
	undrawBow()
	animation_tree["parameters/conditions/draw_bow"] = false
	animation_tree["parameters/conditions/cancel"] = true

func saveData(save_data: Array):
	var data = EntitySaveData.new()
	data.position = global_position
	data.scene_path = scene_file_path
	data.direction = int(player_direction.rotation_degrees)
	save_data.append(data)

func loadData():
	get_parent().remove_child(self)
	queue_free()
