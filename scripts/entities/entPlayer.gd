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
@onready var power_input_container = $PlayerCamera/PowerInputs

const POWER_DOWN = preload("res://images/sprites/power_down.png")
const POWER_UP = preload("res://images/sprites/power_up.png")
const POWER_LEFT = preload("res://images/sprites/power_left.png")
const POWER_RIGHT = preload("res://images/sprites/power_right.png")
var can_move = true
var direction = Vector2()
var bow_mode = false
var bow_draw_strength = 0
var SPEED = 100.0
var stamina_regen = true # MIND THIS, PREFERABLY ONLY INVI CAN DISABLE/ENABLE STAMINA REGEN
var play_once = true
var sprinting = false
var hiding = false
var channeling_power = false
var power_listening = false
var power_inputs = ''
var ANIMATION_SPEED = 0.0

func _ready():
	player_camera.global_position = global_position
	SPEED = PlayerGlobals.overworld_stats['walk_speed']
	animation_tree.active = true
	
	PlayerGlobals.loadSquad()
	PlayerGlobals.initializeBenchedTeam()
	SaveLoadGlobals.session_start = Time.get_unix_time_from_system()
	if SettingsGlobals.cheat_mode and !has_node('DebugComponent'):
		add_child(load("res://scenes/components/DebugComponent.tscn").instantiate())
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

func _process(_delta):
	updateAnimationParameters()
	animateInteract()

func _physics_process(delta):
	animation_tree.advance(ANIMATION_SPEED * delta)
	# Bow
	if bow_mode and is_processing_input() and PlayerGlobals.EQUIPPED_ARROW != null:
		drawBow()
		ammo_count.show()
		ammo_count.text = str(PlayerGlobals.EQUIPPED_ARROW.STACK)
	else:
		ammo_count.hide()
	
	# Movement inputs
	if can_move and is_processing_input():
		direction = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), 
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
		direction = direction.normalized()
		velocity = direction * SPEED
		move_and_slide()
	
	# Bow / sprint processes
	if PlayerGlobals.overworld_stats['stamina'] <= 0.0 and animation_tree["parameters/conditions/draw_bow"]:
		Input.action_press("ui_bow")
	if sprinting and PlayerGlobals.overworld_stats['stamina'] > 0.0 and bow_draw_strength == 0 and can_move:
		SPEED = PlayerGlobals.overworld_stats['sprint_speed']
		ANIMATION_SPEED = 1.0
		if velocity != Vector2.ZERO: PlayerGlobals.overworld_stats['stamina'] -= PlayerGlobals.overworld_stats['sprint_drain']
	elif bow_draw_strength >= PlayerGlobals.overworld_stats['bow_max_draw']:
		if PlayerGlobals.overworld_stats['stamina'] > 0.0:
			PlayerGlobals.overworld_stats['stamina'] -= 0.1
	elif sprinting and PlayerGlobals.overworld_stats['stamina'] < 0.0:
		SPEED = PlayerGlobals.overworld_stats['walk_speed']
		ANIMATION_SPEED = 0.0
	elif !sprinting and PlayerGlobals.overworld_stats['stamina'] < 100 and stamina_regen:
		PlayerGlobals.overworld_stats['stamina'] += PlayerGlobals.overworld_stats['stamina_gain']
	if !sprinting or PlayerGlobals.overworld_stats['stamina'] <= 0.0:
		SPEED = PlayerGlobals.overworld_stats['walk_speed']
		ANIMATION_SPEED = 0.0
	
	# Ensure that stamina doesn't over regen
	if PlayerGlobals.overworld_stats['stamina'] > 100.0:
		PlayerGlobals.overworld_stats['stamina'] = 100.0
	
	# Follower points
	OverworldGlobals.follow_array.push_front(global_position)
	OverworldGlobals.follow_array.pop_back()

func _input(_event):
	# Power handling
	if !channeling_power and power_listening and !can_move and power_input_container.get_child_count() < 3:
		if Input.is_action_just_pressed('ui_left'):
			power_inputs += 'a'
			showPowerInput(POWER_LEFT)
		elif Input.is_action_just_pressed('ui_right'):
			power_inputs += 'd'
			showPowerInput(POWER_RIGHT)
		elif Input.is_action_just_pressed('ui_up'):
			power_inputs += 'w'
			showPowerInput(POWER_UP)
		elif Input.is_action_just_pressed('ui_down'):
			power_inputs += 's'
			showPowerInput(POWER_DOWN)
	if Input.is_action_pressed("ui_gambit") and canUsePower() and !power_listening and can_move:
		toggleVoidAnimation(true)
		sprinting = false
		can_move = false
		power_listening = true
	elif (Input.is_action_just_released("ui_gambit") and canUsePower() and power_listening and !can_move) or (power_inputs.length() >= 3):
		executePower()
		cancelPower()
	
	# Sprint/bow handling
	if SettingsGlobals.doSprint():
		sprinting = true
	elif SettingsGlobals.stopSprint():
		sprinting = false
	if Input.is_action_just_pressed("ui_bow") and canDrawBow():
		if bow_draw_strength == 0: 
			bow_mode = !bow_mode
	
	# Debug
	if Input.is_action_pressed("ui_cheat_mode"):
		if !has_node('DebugComponent'):
			add_child(load("res://scenes/components/DebugComponent.tscn").instantiate())
		else:
			get_node('DebugComponent').queue_free()

func _unhandled_input(_event: InputEvent):
	# UI Handling
	if Input.is_action_just_pressed("ui_show_menu") and !hiding:
		OverworldGlobals.showMenu("res://scenes/user_interface/PauseMenu.tscn")
	if Input.is_action_just_pressed("ui_cancel") and OverworldGlobals.inMenu() and !hiding:
		OverworldGlobals.showMenu("res://scenes/user_interface/PauseMenu.tscn")
	# Interaction handling
	if Input.is_action_just_pressed("ui_select") and !channeling_power and can_move and !OverworldGlobals.inMenu() and !OverworldGlobals.inDialogue():
		var interactables = interaction_detector.get_overlapping_areas()
		if interactables.size() > 0:
			velocity = Vector2.ZERO
			undrawBowAnimation()
			interactables[0].interact()
			return

func showPowerInput(texture:CompressedTexture2D):
	OverworldGlobals.playSound("res://audio/sounds/52_Dive_02.ogg")
	var icon = TextureRect.new()
	icon.grow_horizontal = Control.GROW_DIRECTION_BOTH
	icon.grow_vertical = Control.GROW_DIRECTION_BOTH
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.texture = texture
	power_input_container.add_child(icon)
	var tween = create_tween().bind_node(icon).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(icon, 'scale', Vector2(1.25,1.25), 0.1)
	tween.tween_property(icon, 'scale', Vector2(1.0,1.0), 0.25)
	tween.tween_callback(tween.kill)
	tween.tween_callback(icon.queue_free)

func executePower():
	for power in PlayerGlobals.KNOWN_POWERS:
		if power.INPUT_MAP == power_inputs and power.INPUT_MAP != null:
			power.POWER_SCRIPT.executePower(self)
			return

func cancelPower():
	Input.action_release("ui_gambit")
	toggleVoidAnimation(false)
	power_listening = false
	power_inputs = ''
	for child in power_input_container.get_children():
		var tween = create_tween().bind_node(child).set_trans(Tween.TRANS_BOUNCE).set_parallel(true)
		tween.tween_property(child, 'modulate', Color.TRANSPARENT, 0.15)
		tween.tween_property(child, 'scale', Vector2(1.5,1.5), 0.25)
		tween.tween_callback(child.queue_free)
	await get_tree().create_timer(0.15).timeout
	if OverworldGlobals.isPlayerAlive():
		can_move = true
		#await tween.finished
		#child.queue_free()

func resetStates():
	undrawBowAnimation()
	sprinting = false
	SPEED = PlayerGlobals.overworld_stats['walk_speed']
	ANIMATION_SPEED = 0.0
	power_inputs = ''
	cancelPower()
	Input.action_release("ui_bow_draw")

func canDrawBow()-> bool:
	if OverworldGlobals.inMenu():
		return false
	
	if OverworldGlobals.getCurrentMap().SAFE:
		prompt.showPrompt("Can't use [color=yellow]Bow[/color] right now.")
		return false
	
	if velocity != Vector2.ZERO:
		return false
	elif !PlayerGlobals.equipNewArrowType() and (PlayerGlobals.EQUIPPED_ARROW != null and PlayerGlobals.EQUIPPED_ARROW.STACK <= 0):
		prompt.showPrompt("No more [color=yellow]%ss[/color]." % PlayerGlobals.EQUIPPED_ARROW.NAME)
		return false
	
	return true

func canUsePower():
	if OverworldGlobals.inMenu():
		return false
	
	if OverworldGlobals.getCurrentMap().SAFE:
		prompt.showPrompt("Can't use [color=gray]Gambit[/color] right now.")
		return false
	
	if bow_draw_strength != 0.0:
		return false
	
	return true

func animateInteract():
	if interaction_detector.get_overlapping_areas().size() > 0 and is_processing_input() and !channeling_power and can_move:
		interaction_prompt.visible = true
		interaction_prompt_animator.play('Interact')
	else:
		interaction_prompt_animator.play('RESET')

func drawBow():
	if (PlayerGlobals.EQUIPPED_ARROW != null and PlayerGlobals.EQUIPPED_ARROW.STACK <= 0) and !PlayerGlobals.equipNewArrowType():
		bow_mode = false
		toggleBowAnimation()
	
	if Input.is_action_pressed("ui_bow_draw") and !animation_tree["parameters/conditions/void_call"] and !OverworldGlobals.inDialogue() and !OverworldGlobals.inMenu() and can_move:
		sprinting = false
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
		if bow_draw_strength >= PlayerGlobals.overworld_stats['bow_max_draw']:
			bow_line.points[1].y = 275
			bow_draw_strength = PlayerGlobals.overworld_stats['bow_max_draw']
	
	
	if Input.is_action_just_released("ui_bow_draw") and velocity == Vector2.ZERO:
		if bow_draw_strength >= PlayerGlobals.overworld_stats['bow_max_draw']: 
			shootProjectile()
		await get_tree().create_timer(0.05).timeout
		undrawBow()

func undrawBow():
	bow_line.hide()
	bow_line.points[1].y = 0
	bow_draw_strength = 0
	SPEED = PlayerGlobals.overworld_stats['walk_speed']
	play_once = true

func shootProjectile():
	OverworldGlobals.playSound("178872__hanbaal__bow.ogg", -15.0, true)
	InventoryGlobals.removeItemResource(PlayerGlobals.EQUIPPED_ARROW)
	var projectile = load("res://scenes/entities_disposable/ProjectileArrow.tscn").instantiate()
	projectile.global_position = global_position + Vector2(0, -10)
	projectile.SHOOTER = self
	projectile.name = 'PlayerArrow'
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

func shakeCamera(strength:float, speed:float):
	player_camera.shake(strength,speed)

# Based on https://www.youtube.com/watch?v=WrMORzl3g1U
func updateAnimationParameters():
	if velocity == Vector2.ZERO:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/is_moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/is_moving"] = true
	
	if direction != Vector2.ZERO and bow_draw_strength < 1.0:
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
			Input.action_release("ui_bow_draw")
			animation_tree["parameters/conditions/draw_bow"] = false
			animation_tree["parameters/conditions/cancel"] = true
	
	if bow_mode:
		if Input.is_action_pressed('ui_bow_draw') and !animation_tree["parameters/conditions/void_call"] and !OverworldGlobals.inDialogue() and is_processing_input():
			animation_tree["parameters/conditions/draw_bow"] = true
			animation_tree["parameters/conditions/shoot_bow"] = false
			animation_tree["parameters/conditions/cancel"] = false
		
		if Input.is_action_just_released("ui_bow_draw"):
			animation_tree["parameters/conditions/draw_bow"] = false
			if bow_draw_strength >= PlayerGlobals.overworld_stats['bow_max_draw'] and velocity == Vector2.ZERO:
				animation_tree["parameters/conditions/shoot_bow"] = true
				can_move = false
				await animation_tree.animation_finished
				can_move = true
			else:
				undrawBow()
				animation_tree["parameters/conditions/cancel"] = true

func setUIVisibility(set_visibility:bool):
	for child in player_camera.get_children():
		if child is Control: 
			match set_visibility:
				true: child.self_modulate.a = 1.0
				false: child.self_modulate.a = 0.0

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
	data.scene_path = scene_file_path
	data.position = global_position
	data.direction = int(player_direction.rotation_degrees)
	save_data.append(data)

func loadData():
	get_parent().remove_child(self)
	queue_free()
