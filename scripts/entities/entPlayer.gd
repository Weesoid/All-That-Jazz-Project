extends CharacterBody2D
class_name PlayerScene

@export var dialogue_name: String

@onready var sprite = $Sprite2D
@onready var interaction_detector = $PlayerDirection/InteractionDetector
@onready var player_animator = $WalkingAnimations
@onready var animation_player = $AnimationPlayer
@onready var animation_tree = $AnimationTree
@onready var cast_animator = $PowerAnimator
@onready var player_direction = $PlayerDirection
@onready var bow_line = $PlayerDirection/BowShotLine
@onready var squad = $CombatantSquadComponent
@onready var player_camera: PlayerCamera = $PlayerCamera
@onready var audio_player = $AudioStreamPlayer2D
@onready var drop_detector: Area2D = $PlayerDirection/Area2D
@onready var animation_sprite = $AnimationSprite
@onready var collision_shape: CollisionShape2D = $PlayerCollision
@onready var climb_cooldown: Timer = $ClimbCooldown
@onready var melee_hitbox = $PlayerDirection/MeleeHitbox

const POWER_DOWN = preload("res://images/sprites/power_down.png")
const POWER_UP = preload("res://images/sprites/power_up.png")
const POWER_LEFT = preload("res://images/sprites/power_left.png")
const POWER_RIGHT = preload("res://images/sprites/power_right.png")

var can_move = true
var direction = Vector2()
var bow_mode = false
var bow_draw_strength = 0
var speed = 100.0
var stamina_regen = true # MIND THIS, PREFERABLY ONLY INVI CAN DISABLE/ENABLE STAMINA REGEN
var sprinting = false
var climbing = false
var channeling_power = false
var power_listening = false
var power_inputs = ''
var fall_damage: int = 0
var ANIMATION_SPEED = 0.0
var default_camera_pos: Vector2
var diving = false
var dive_strength:float=-125
var invincible = false
var camping = false
var do_gravity:bool = true
var do_land_flag

signal jumped(jump_velocity)
signal dived
signal phased
signal landed

func _ready():
	setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
	animation_tree.active = true
	
	PlayerGlobals.loadSquad()
	SaveLoadGlobals.session_start = Time.get_unix_time_from_system()
	if SettingsGlobals.cheat_mode and !has_node('DebugComponent'):
		add_child(load("res://scenes/components/DebugComponent.tscn").instantiate())
	
	default_camera_pos = player_camera.position
	OverworldGlobals.setMouseController(false)
	OverworldGlobals.player = self
	landed.connect(playFootstep)

func _process(_delta):
	updateAnimationParameters()
	#animateInteract()

func getPosOffset()-> Vector2:
	return global_position+sprite.offset

func jump(jump_velocity:float=-200.0):
	if climbing:
		toggleClimbAnimation(false)
	velocity.y = jump_velocity
	if direction.x > 0:
		animation_sprite.flip_h = true
	else:
		animation_sprite.flip_h = false
	if !diving:
		jumped.emit(jump_velocity)

func phase():
	phased.emit()
	set_collision_mask_value(1, false)
	await get_tree().create_timer(0.1).timeout
	set_collision_mask_value(1, true)

func dodge(time:float=0.2):
	if invincible:
		return
	
	invincible=true
	setPatrollerCollisionExceptions(true)
	await get_tree().create_timer(time).timeout
	invincible=false
	setPatrollerCollisionExceptions(false)

func setPatrollerCollisionExceptions(set_to:bool):
	var patrollers = OverworldGlobals.getAllPatrollers()
	if set_to:
		for patroller in patrollers:
			patroller.add_collision_exception_with(self)
	else:
		for patroller in patrollers:
			patroller.remove_collision_exception_with(self)

func _physics_process(delta):
	#print(velocity.x)
	# Gravity
	if not is_on_floor() and !climbing and do_gravity:
		if bow_draw_strength > 0.0:
			setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
		velocity.x = 0
		velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
		fall_damage += 1
		do_land_flag=true
	
	# Fall damage
	if fall_damage != 0 and get_node('CombatantSquadComponent').combatant_squad.size() > 0 and is_on_floor():
		var damage = floor(float(fall_damage)/6.0)
		if damage < 6:
			fall_damage = 0
			return
		OverworldGlobals.damageParty(damage, ['Faceplant!', "That's gotta hurt.", 'Watch your step!'])
		fall_damage = 0
		suddenStop()
		resetStates()
		animation_player.play('Faceplant')
		await animation_player.animation_finished
		can_move = true
		resetAnimation()
	elif is_on_floor():
		if do_land_flag: 
			landed.emit()
			do_land_flag=false
		fall_damage = 0
	
	# Movement inputs
	if isMovementAllowed() and (is_on_floor() or climbing):
		direction = Vector2(
			Input.get_action_strength("ui_move_right") - Input.get_action_strength("ui_move_left"), 
			Input.get_action_strength("ui_move_down") - Input.get_action_strength("ui_move_up")
		)
		direction = direction.normalized()
		
		if Input.is_action_just_pressed("ui_accept") and canDive() and canDoStaminaAction(5.0):
			dived.emit()
			diving=true
			jump(dive_strength)
			dodge()
			animation_player.play('Dive_2')
			await animation_player.animation_finished
			collision_shape.set_deferred('disabled', false)
			animation_player.play('RESET')
			diving=false
			can_move=true
		
		# Jump detector
		if Input.is_action_just_pressed("ui_accept") and Input.is_action_pressed("ui_move_up") and is_on_floor() and velocity == Vector2.ZERO and isFacingUp()  and canDoStaminaAction(5) :
			jump(-255.0)
		elif Input.is_action_just_pressed("ui_accept") and Input.is_action_pressed("ui_move_down") and get_collision_mask_value(1) and drop_detector.has_overlapping_bodies() and is_on_floor():
			phase()
	
	# Dive
	if diving and not is_on_floor():
		velocity.x = direction.x * 500.0
	elif diving and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 500.0)
	
	# Physical movement
	if isMovementAllowed() and direction and !diving:
		if climbing and (isFacingUp() or isFacingDown()): # Climbing
			sprinting = false
			velocity.y = direction.y * 100.0
		velocity.x = direction.x * speed # Walking
	else:
		if climbing:
			velocity.y = 0.0 # Stop climbing
		velocity.x = move_toward(velocity.x, 0, speed) # Stop walking
	move_and_slide()
	
	animation_tree.advance(ANIMATION_SPEED * delta)
	# Bow
	if bow_mode and is_processing_input() and PlayerGlobals.equipped_arrow != null:
		drawBow()

	
	# Bow / sprint processes
	if PlayerGlobals.overworld_stats['stamina'] <= 0.0 and animation_tree["parameters/conditions/draw_bow"]:
		Input.action_press("ui_bow")
	if sprinting and PlayerGlobals.overworld_stats['stamina'] > 0.0 and bow_draw_strength == 0 and can_move:
		setSpeed(PlayerGlobals.overworld_stats['sprint_speed'])
		ANIMATION_SPEED = 1.0
		if velocity != Vector2.ZERO and is_on_floor(): 
			PlayerGlobals.overworld_stats['stamina'] -= PlayerGlobals.overworld_stats['sprint_drain']
	elif bow_draw_strength >= PlayerGlobals.overworld_stats['bow_max_draw']:
		if PlayerGlobals.overworld_stats['stamina'] > 0.0:
			PlayerGlobals.overworld_stats['stamina'] -= 0.1
	elif sprinting and PlayerGlobals.overworld_stats['stamina'] < 0.0:
		setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
		ANIMATION_SPEED = 0.0
	elif !sprinting and PlayerGlobals.overworld_stats['stamina'] < 100 and stamina_regen and is_on_floor():
		PlayerGlobals.overworld_stats['stamina'] += PlayerGlobals.overworld_stats['stamina_gain']
	if (!sprinting or PlayerGlobals.overworld_stats['stamina'] <= 0.0) and bow_draw_strength == 0.0:
		setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
		ANIMATION_SPEED = 0.0
	
	# Ensure that stamina doesn't over regen
	if PlayerGlobals.overworld_stats['stamina'] > 100.0:
		PlayerGlobals.overworld_stats['stamina'] = 100.0
	
	# Follower points
	#OverworldGlobals.follow_array.push_front(global_position)
	#OverworldGlobals.follow_array.pop_back()

## NOTE: Must be called last.
func canDoStaminaAction(cost:float):
	if PlayerGlobals.overworld_stats['stamina'] >= cost:
		PlayerGlobals.overworld_stats['stamina'] -= cost
		return true
	else:
		player_camera.flashStamina(Color.RED)
		return false


func isMovementAllowed():
	return can_move and is_processing_input() and isMobile() and !animation_player.is_playing()

func canDive():
	return sprinting and !interaction_detector.has_overlapping_areas() and velocity.x != 0 and ((Input.is_action_pressed('ui_move_left') or Input.is_action_pressed('ui_move_right')) and !Input.is_action_pressed('ui_move_up'))

func _input(_event):
	if !channeling_power and power_listening and !can_move and isMobile() and player_camera.power_input_container.get_child_count() < 3:
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
	if Input.is_action_pressed("ui_gambit") and canUsePower():
		OverworldGlobals.playSound("res://audio/sounds/MAGSpel_Anime Ability Ready 2.ogg")
		OverworldGlobals.zoomCamera(Vector2(1.01,1.01))
		toggleVoidAnimation(true)
		sprinting = false
		can_move = false
		power_listening = true

	elif (Input.is_action_just_released("ui_gambit") and canUsePower() and power_listening and !can_move) or (power_inputs.length() >= 3) and isMobile():
		OverworldGlobals.zoomCamera(Vector2(1.0,1.0))
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
		elif bow_draw_strength > 0:
			undrawBow()

	
	# Debug
#	if Input.is_action_pressed("ui_cheat_mode"):
#		if !has_node('DebugComponent'):
#			add_child(load("res://scenes/components/DebugComponent.tscn").instantiate())
#		else:
#			get_node('DebugComponent').queue_free()

func isFacingSide():
	return floor(player_direction.rotation_degrees) == 90 or ceil(player_direction.rotation_degrees) == -90

func isFacingUp():
	return ceil(player_direction.rotation_degrees) == 180

func isFacingDown():
	return ceil(player_direction.rotation_degrees) == 0

func _unhandled_input(_event: InputEvent):
	# UI Handling
	if Input.is_action_just_pressed("ui_show_menu") and !camping:
		OverworldGlobals.showMenu("res://scenes/user_interface/GameMenu.tscn")
	if Input.is_action_just_pressed("ui_cancel") and OverworldGlobals.inMenu() and !camping:
		OverworldGlobals.showMenu("res://scenes/user_interface/GameMenu.tscn")
	# Interaction handling
	if Input.is_action_just_pressed("ui_select"):
		var interactables = interaction_detector.get_overlapping_areas()
		if interactables.size() > 0:
			#velocity = Vector2.ZERO CHANGE LATER
			velocity.move_toward(Vector2.ZERO,get_physics_process_delta_time())
			undrawBowAnimation()
			interactables[0].interact()
			return
	if Input.is_action_just_pressed("ui_text_backspace"):
		#get_tree().change_scene_to_file("res://EmptyScene.tscn")
		OverworldGlobals.changeToCombat('Entity')
#	if Input.is_action_just_pressed('ui_accept'):
#		PlayerGlobals.addCombatantTemperment(OverworldGlobals.getCombatantSquad('Player').pick_random())

func canInteract():
	return !channeling_power and can_move and !OverworldGlobals.inMenu() and !OverworldGlobals.inDialogue() and !climbing and !animation_player.is_playing()

func isMobile():
	return PlayerGlobals.overworld_stats['walk_speed'] > 0 and PlayerGlobals.overworld_stats['sprint_speed'] > 0

func showPowerInput(texture:CompressedTexture2D):
	OverworldGlobals.playSound("res://audio/sounds/52_Dive_02.ogg")
	var icon = TextureRect.new()
	icon.grow_horizontal = Control.GROW_DIRECTION_BOTH
	icon.grow_vertical = Control.GROW_DIRECTION_BOTH
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.texture = texture
	player_camera.addPowerInput(icon)

func executePower():
	for power in PlayerGlobals.known_powers:
		if power.input_map == power_inputs and power.input_map != null: 
			if canCastPower(power): 
				InventoryGlobals.removeItemWithName('VoidCrystal', power.crystal_cost)
				power.power_script.executePower(self)
			elif !canCastPower(power) and power_inputs.length() >= 3:
				OverworldGlobals.showPrompt("Not enough [color=yellow]Void Crystals[/color].")
			return

func canCastPower(power: ResPower):
	return (power.crystal_cost != 0 and InventoryGlobals.hasItem('VoidCrystal',power.crystal_cost)) or power.crystal_cost == 0

func cancelPower():
	Input.action_release("ui_gambit")
	toggleVoidAnimation(false)
	power_listening = false
	power_inputs = ''
	player_camera.crystal_count.hide()
	for child in player_camera.power_input_container.get_children():
		var tween = create_tween().bind_node(child).set_trans(Tween.TRANS_BOUNCE).set_parallel(true)
		tween.tween_property(child, 'modulate', Color.TRANSPARENT, 0.15)
		tween.tween_property(child, 'scale', Vector2(1.5,1.5), 0.25)
		tween.tween_callback(child.queue_free)
	await get_tree().create_timer(0.15).timeout
	if OverworldGlobals.isPlayerAlive():
		can_move = true

func resetStates():
	undrawBowAnimation()
	toggleVoidAnimation(false)
	sprinting = false
	setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
	ANIMATION_SPEED = 0.0
	power_inputs = ''
	cancelPower()
	#player_camera.quiver.select_name.text = ''
	#player_camera.quiver.visible = false
	Input.action_release("ui_bow_draw")

func resetAnimation():
	animation_player.play("RESET")

func canDrawBow()-> bool: 
	if OverworldGlobals.inMenu():
		return false
	if !PlayerGlobals.equipNewArrowType() and (PlayerGlobals.equipped_arrow != null and PlayerGlobals.equipped_arrow.stack <= 0):
		OverworldGlobals.showPrompt("No more [color=yellow]%ss[/color]." % PlayerGlobals.equipped_arrow.name)
		return false
	if PlayerGlobals.equipped_arrow == null:
		return false
	if !isMobile():
		return false
	if diving:
		return false
	
	return true

func canUsePower():
	if OverworldGlobals.inMenu():
		return false
	if bow_draw_strength != 0.0:
		return false
	if OverworldGlobals.getCombatantSquad('Player').is_empty():
		return false
	
	return !power_listening and can_move and isMobile()

#func animateInteract():
#	if interaction_detector.get_overlapping_areas().size() > 0 and is_processing_input() and interaction_detector.get_overlapping_areas()[0].visible and !channeling_power and can_move:
#		interaction_prompt.visible = true
#		interaction_prompt_animator.play('Interact')
#	else:
#		interaction_prompt_animator.play('RESET')

func drawBow():
	if (PlayerGlobals.equipped_arrow != null and PlayerGlobals.equipped_arrow.stack <= 0) and !PlayerGlobals.equipNewArrowType():
		bow_mode = false
		toggleBowAnimation()
	
	if Input.is_action_pressed("ui_bow_draw") and canPullBow():
		if bow_draw_strength < 1.5: suddenStop(false)
		setSpeed(15.0)
		bow_line.show()
		bow_line.global_position = global_position + Vector2(0, -10) + sprite.offset
		bow_draw_strength += 0.1
		bow_line.points[1].y += 1
		if velocity != Vector2.ZERO:
			bow_line.default_color.a = 0.10
		else:
			bow_line.default_color.a = 0.5
		if !isMobile():
			bow_draw_strength = 0
		if bow_draw_strength >= PlayerGlobals.overworld_stats['bow_max_draw'] and bow_line.points[1].y < 275:
			var tween = create_tween()
			tween.tween_property(sprite, 'self_modulate', Color.INDIAN_RED,0.1)
			tween.tween_property(sprite, 'self_modulate', Color.WHITE, 0.25)
			OverworldGlobals.playSound("res://audio/sounds/MAGSpel_Anime Ability Ready 2.ogg", -8.0)
			OverworldGlobals.showQuickAnimation("res://scenes/animations_quick/BowReady.tscn",player_direction)
		if bow_draw_strength >= PlayerGlobals.overworld_stats['bow_max_draw']:
			bow_line.points[1].y = 275
			bow_draw_strength = PlayerGlobals.overworld_stats['bow_max_draw']
	if Input.is_action_just_released("ui_bow_draw") and canShootBow(): 
		suddenStop()
		shootProjectile()
		playShootAnimation()
		await animation_tree.animation_finished
		undrawBow()
		

func canPullBow():
	return !animation_tree["parameters/conditions/void_call"] and !OverworldGlobals.inDialogue() and !OverworldGlobals.inMenu() and can_move and isMobile() and !diving and (isFacingSide() or isFacingUp())

func canShootBow()-> bool:
	return can_move and bow_draw_strength >= PlayerGlobals.overworld_stats['bow_max_draw'] and isMobile() and velocity.x == 0

func undrawBow():
	bow_line.hide()
	bow_line.points[1].y = 0
	bow_draw_strength = 0
	setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
	if !can_move:
		can_move = true

func shootProjectile():
	bow_line.hide()
	OverworldGlobals.playSound("178872__hanbaal__bow.ogg", -15.0, true)
	InventoryGlobals.removeItemResource(PlayerGlobals.equipped_arrow)
	var projectile = load("res://scenes/entities_disposable/ProjectileArrow.tscn").instantiate()
	projectile.global_position = bow_line.global_position
	projectile.shooter = self
	projectile.name = 'PlayerArrow'
	get_tree().current_scene.add_child(projectile)
	projectile.rotation = player_direction.rotation + 1.57079994678497

func shakeCamera(strength:float, shake_speed:float):
	player_camera.shake(strength,shake_speed)

func setSpeed(p_speed:float, only_on_floor:bool=true):
	if only_on_floor and !is_on_floor():
		return
	speed = p_speed

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
		animation_tree["parameters/Melee/blend_position"] = direction
		animation_tree["parameters/Climb/blend_position"] = direction
	if Input.is_action_just_pressed('ui_bow') and !animation_tree["parameters/conditions/void_call"]:
		suddenStop()
		toggleBowAnimation()
		if animation_tree["parameters/conditions/draw_bow"]:
			bow_draw_strength = 0
			Input.action_release("ui_bow_draw")
			animation_tree["parameters/conditions/draw_bow"] = false
			animation_tree["parameters/conditions/cancel"] = true
			undrawBow()
		await get_tree().process_frame
		can_move = true
	
	if bow_mode:
		if Input.is_action_pressed('ui_bow_draw') and  canPullBow(): # !animation_tree["parameters/conditions/void_call"] and !animation_tree["parameters/conditions/melee"] and !OverworldGlobals.inDialogue() and is_processing_input() and
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
				animation_tree["parameters/conditions/shoot_bow"] = false
			else:
				undrawBow()
				animation_tree["parameters/conditions/cancel"] = true
	if Input.is_action_just_pressed("ui_melee") and canMelee() and canDoStaminaAction(5.0): 
		undrawBowAnimation()
		suddenStop()
		animation_tree["parameters/conditions/melee"] = true
		melee_hitbox.showSmear()
		await animation_tree.animation_finished
		animation_tree["parameters/conditions/melee"] = false
		can_move = true 

func playDrawSound():
	if bow_draw_strength < 1:
		OverworldGlobals.playSound("res://audio/sounds/bow-loading-38752.ogg")

func canMelee():
	return can_move and !animation_tree["parameters/conditions/shoot_bow"] and isFacingSide() and bow_mode and !diving and is_on_floor() and !OverworldGlobals.inMenu()

func suddenStop(stop_move:bool=true, stop_sprint:bool=true):
	if stop_sprint:
		sprinting = false
		ANIMATION_SPEED=0.0
	if stop_move:
		Input.action_release('ui_move_down')
		Input.action_release('ui_move_up')
		Input.action_release('ui_move_left')
		Input.action_release('ui_move_right')
		can_move = false

func setUIVisibility(set_visibility:bool):
	var exceptions = ['ColorOverlay', 'PlayerPrompt','SaveIndicator']
	for child in player_camera.get_node('UI').get_children():
		if child is Control and !exceptions.has(child.name): 
			match set_visibility:
				true: child.modulate.a = 1.0
				false: child.modulate.a = 0.0

func toggleVoidAnimation(enabled: bool):
	if enabled:
		animation_tree["parameters/conditions/void_call"] = true
		animation_tree["parameters/conditions/void_release"] = false
	else:
		animation_tree["parameters/conditions/void_call"] = false
		animation_tree["parameters/conditions/void_release"] = true

func toggleClimbAnimation(enabled: bool):
	if (enabled and animation_tree["parameters/conditions/climb"]) or (!enabled and animation_tree["parameters/conditions/unclimb"]):
		return
	
	if enabled:
		animation_tree["parameters/conditions/climb"] = true
		animation_tree["parameters/conditions/unclimb"] = false
	else:
		animation_tree["parameters/conditions/climb"] = false
		animation_tree["parameters/conditions/unclimb"] = true
	animation_tree["parameters/conditions/is_moving"] = false
	animation_tree["parameters/conditions/idle"] = true

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

func playFootstep():
	if is_on_floor():
		FootstepSoundManager.playFootstep(getPosOffset())

func saveData(save_data: Array):
	var data = EntitySaveData.new()
	data.scene_path = scene_file_path
	data.position = global_position
	data.direction = int(player_direction.rotation_degrees)
	save_data.append(data)

func loadData():
	get_parent().remove_child(self)
	queue_free()

#func _on_tree_exiting():
#	animation_player.play('RESET')
