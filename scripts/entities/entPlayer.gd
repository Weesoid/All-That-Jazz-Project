extends CharacterBody2D
class_name PlayerScene

@export var dialogue_name: String

@onready var sprite = $Sprite2D
@onready var interaction_detector = $PlayerDirection/InteractionDetector
@onready var animation_tree = $AnimationTree
@onready var player_direction = $PlayerDirection
@onready var bow_line = $PlayerDirection/BowShotLine
@onready var squad = $CombatantSquadComponent
@onready var player_camera: PlayerCamera = $PlayerCamera
@onready var drop_detector: Area2D = $PlayerDirection/Area2D
@onready var collision_shape: CollisionShape2D = $PlayerCollision
@onready var climb_cooldown: Timer = $ClimbCooldown
@onready var melee_cooldown: Timer = $MeleeCooldown
@onready var bow_draw_time = $BowDrawTime
@onready var melee_bar = $MeleeCooldownBar
@onready var melee_hitbox: MeleeHitbox = $PlayerDirection/MeleeHitbox
@onready var current_arrow_icon = $CurrentArrowView
@onready var walking_animations = $WalkingAnimations
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var battler = $Battler
@onready var battler_animator = $Battler/AnimationPlayer

var can_move = true
var direction = Vector2()
var speed = 100.0
var stamina_regen = true 
var sprinting = false
var climbing = false
var fall_damage: int = 0
var ANIMATION_SPEED = 0.0
var default_camera_pos: Vector2
var diving = false
var dive_strength:float=-140
var invincible = false
var camping = false
var current_camp_spot:SavePoint
var do_gravity:bool = true
var do_land_flag:bool
var landed_from_climb:bool=false
var hud: Array = [] # CHECK
var fast_travelling:bool=false
var shoot_ready := false
var pulling_bow := false
var shooting_bow := false

signal jumped(jump_velocity)
signal dived
signal phased
signal landed(from_ladder:bool)
signal bow_shot
signal bow_equipped
signal bow_unequipped
signal bow_drawn
signal bow_undrawn
signal climb_started

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
	animation_tree.active = true
	
	PlayerGlobals.loadSquad()
	SaveLoadGlobals.session_start = Time.get_unix_time_from_system()
	if SettingsGlobals.cheat_mode and !has_node('DebugComponent'):
		add_child(load("res://scenes/components/DebugComponent.tscn").instantiate())
	
	OverworldGlobals.player = self
	
	default_camera_pos = player_camera.position
	landed.connect(playFootstep.unbind(1))
	hud = [
		melee_bar,
		current_arrow_icon
	]
	resetStates()
	await get_tree().process_frame
	OverworldGlobals.loadFollowers()
	OverworldGlobals.player_ready.emit()
	print(sprite.offset)
	print(sprite.position)

func _process(_delta):
	updateAnimationParameters()

func getPosOffset()-> Vector2:
	return global_position+sprite.offset

func jump(jump_velocity:float=-200.0):
	if climbing:
		toggleClimbAnimation(false)
	velocity.y = jump_velocity
	if !diving:
		jumped.emit(jump_velocity)

func phase():
	phased.emit()
	set_collision_mask_value(1, false)
	await get_tree().create_timer(0.15).timeout
	set_collision_mask_value(1, true)

func dodge(time:float=0.2):
	if invincible:
		return
	
	invincible=true
	setPatrollerCollisionExceptions(true)
	await get_tree().create_timer(time).timeout
	invincible=false
	setPatrollerCollisionExceptions(false)

func setClimbing(to:bool):
	
	OverworldGlobals.player.climbing = to
	OverworldGlobals.player.toggleClimbAnimation(to)
	if !to:
		climb_cooldown.start()
	else:
		#print('Setting fall to 0!')
		fall_damage = 0

func setPatrollerCollisionExceptions(set_to:bool):
	var patrollers = OverworldGlobals.getAllPatrollers()
	if set_to:
		for patroller in patrollers:
			patroller.add_collision_exception_with(self)
	else:
		for patroller in patrollers:
			patroller.remove_collision_exception_with(self)

func _physics_process(delta):
	# Gravity
	if not is_on_floor() and !climbing and do_gravity:
		if pulling_bow:
			setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
		velocity.x = 0
		velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
		fall_damage += 1
		do_land_flag=true
	
	#print(fall_damage)
	# Fall damage
	if fall_damage != 0 and get_node('CombatantSquadComponent').combatant_squad.size() > 0 and is_on_floor():
		var damage = floor(float(fall_damage)/5)
		if damage < 6:
			fall_damage = 0
			return
		OverworldGlobals.damageParty(damage,false)
		fall_damage = 0
		suddenStop()
		resetStates()
		# GUT REWORK
		#animation_player.play('Faceplant')
		#await animation_player.animation_finished
		can_move = true
		# GUT REWORK
		#resetAnimation()
	elif is_on_floor():
		if do_land_flag: 
			landed.emit(landed_from_climb)
			do_land_flag=false
			landed_from_climb=false
		fall_damage = 0
	
	# Movement inputs
	if isMovementAllowed() and (is_on_floor() or climbing):
		direction = Vector2(
			Input.get_action_strength("ui_move_right") - Input.get_action_strength("ui_move_left"), 
			Input.get_action_strength("ui_move_down") - Input.get_action_strength("ui_move_up")
		)
		direction = direction.normalized()
		
		if Input.is_action_just_pressed("ui_accept") and canDive() and canDoStaminaAction(5.0):
			#OverworldGlobals.showAfterImages(sprite)
			dived.emit()
			diving=true
			jump(dive_strength)
			dodge()
			# GUT REWORK
			#animation_player.play('Dive_2')
			#await animation_player.animation_finished
			collision_shape.set_deferred('disabled', false)
			# GUT REWORK
			#animation_player.play('RESET')
			diving=false
			can_move=true
		
		# Jump detector
		if Input.is_action_just_pressed("ui_accept") and Input.is_action_pressed("ui_move_up") and is_on_floor() and velocity == Vector2.ZERO and isFacingUp()  and canDoStaminaAction(5) :
			jump(-255.0)
		elif Input.is_action_just_pressed("ui_accept") and Input.is_action_pressed("ui_move_down") and get_collision_mask_value(1) and drop_detector.has_overlapping_bodies() and is_on_floor():
			phase()
	# TEMP
	battler.get_node('Sprite2D').flip_h = sprite.flip_h
	anim_sprite.flip_h = sprite.flip_h
	
	# Dive
	if diving and not is_on_floor():
		velocity.x = direction.x * 500.0
	elif diving and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 500.0)
	
	# Physical movement
	if isMovementAllowed() and direction and !diving:
		if climbing and (isFacingUp() or isFacingDown()): # Climbing
			do_land_flag=true
			landed_from_climb=true
			sprinting = false
			velocity.y = direction.y * 100.0
			climb_started.emit()
		velocity.x = direction.x * speed # Walking
	else:
		if climbing:
			velocity.y = 0.0 # Stop climbing
		velocity.x = move_toward(velocity.x, 0, speed) # Stop walking
	move_and_slide()
	
	animation_tree.advance(ANIMATION_SPEED * delta)
	
	# Bow
	if Input.is_action_just_pressed('ui_bow_draw') and canPullBow():
		startBowPull()
	elif (Input.is_action_just_released('ui_bow_draw') and !canShootBow()) or Input.is_action_just_pressed("ui_alternate_cancel"):
		cancelBowPull()
	if Input.is_action_just_released('ui_bow_draw') and canShootBow():
		shootBow()
	
	# Sprint
	if sprinting and PlayerGlobals.overworld_stats['stamina'] > 0.0 and !pulling_bow and can_move:
		setSpeed(PlayerGlobals.overworld_stats['sprint_speed'])
		ANIMATION_SPEED = 1.0
		if velocity != Vector2.ZERO and is_on_floor(): 
			PlayerGlobals.overworld_stats['stamina'] -= PlayerGlobals.overworld_stats['sprint_drain']
	elif sprinting and PlayerGlobals.overworld_stats['stamina'] < 0.0:
		setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
		ANIMATION_SPEED = 0.0
	elif !sprinting and PlayerGlobals.overworld_stats['stamina'] < 100 and stamina_regen and is_on_floor():
		PlayerGlobals.overworld_stats['stamina'] += PlayerGlobals.overworld_stats['stamina_gain']
	if (!sprinting or PlayerGlobals.overworld_stats['stamina'] <= 0.0) and !pulling_bow:
		setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
		ANIMATION_SPEED = 0.0
	
	# Ensure that stamina doesn't over regen
	if PlayerGlobals.overworld_stats['stamina'] > 100.0:
		PlayerGlobals.overworld_stats['stamina'] = 100.0

func startBowPull():
	bow_drawn.emit()
	if is_on_floor():
		velocity = Vector2.ZERO
	pulling_bow = true
	setSpeed(25.0)
	toggleBowDrawAnimation(true)
	can_move=false
	bow_draw_time.start()
	await OverworldGlobals.animateBattler('Player', 'Slow_Draw',true)
	can_move=true

func cancelBowPull():
	bow_undrawn.emit()
	if is_on_floor():
		velocity = Vector2.ZERO
	shoot_ready = false
	pulling_bow = false
	if battler_animator.current_animation == 'Slow_Draw':
		bow_draw_time.stop()
		battler_animator.stop()
		OverworldGlobals.removeAnimationOverlap(self,OverworldGlobals.SpriteType.MAIN, true)
		if can_move == false: can_move = true
	bow_draw_time.stop()
	toggleBowDrawAnimation(false)

func shootBow():
	bow_undrawn.emit()
	if is_on_floor():
		velocity = Vector2.ZERO
	shooting_bow=true
	can_move=false
	pulling_bow = false
	shoot_ready=false
	shootProjectile()
	await OverworldGlobals.animateBattler('Player', 'Ranged_Nowindup',true)
	shooting_bow=false
	toggleBowDrawAnimation(false)
	can_move=true

func setClimbDirection():
	if velocity.y < 0:
		#print('uppity')
		player_direction.rotation_degrees = 179
	elif velocity.y > 0:
		#print('suckity')
		player_direction.rotation_degrees = 0

## NOTE: Must be called last in if statement.
func canDoStaminaAction(cost:float):
	if PlayerGlobals.overworld_stats['stamina'] >= cost:
		PlayerGlobals.overworld_stats['stamina'] -= cost
		return true
	else:
		return false

func isMovementAllowed():
	# GUT REWORK
	return can_move and is_processing_input() and isMobile() #and !animation_player.is_playing()

func canDive():
	return sprinting and !interaction_detector.has_overlapping_areas() and velocity.x != 0 and ((Input.is_action_pressed('ui_move_left') or Input.is_action_pressed('ui_move_right')) and !Input.is_action_pressed('ui_move_up'))

func _input(_event):
	if SettingsGlobals.doSprint():
		sprinting = true
	elif SettingsGlobals.stopSprint():
		sprinting = false

func isFacingSide():
	return floor(player_direction.rotation_degrees) == 90 or ceil(player_direction.rotation_degrees) == -90

func isFacingUp():
	return ceil(player_direction.rotation_degrees) == 180

func isFacingDown():
	return ceil(player_direction.rotation_degrees) == 0

func _unhandled_input(_event: InputEvent):
	# UI Handling
	if Input.is_action_just_pressed("ui_show_menu") and !camping:
		UIGlobals.showMenu("res://scenes/user_interface/GameMenu.tscn")
	
	# Interaction handling
	if Input.is_action_just_pressed("ui_interact") and canInteract() and !pulling_bow and !shooting_bow:
		var interactables = interaction_detector.get_overlapping_areas()
		if interactables.size() > 0:
			velocity.move_toward(Vector2.ZERO,get_physics_process_delta_time())
			cancelBowPull()
			interactables[0].interact()
			return
	
	if Input.is_action_just_pressed("ui_melee") and canMelee():
		suddenStop()
		melee_hitbox.activate()
		await OverworldGlobals.animateBattler('Player', 'Melee_Nowindup',true)
		melee_cooldown.start()
		melee_bar.start()
		can_move = true
	
	# DEBUG
	if Input.is_action_just_pressed("ui_text_backspace") and OverworldGlobals.isPlayerCheating():
		if OverworldGlobals.getCurrentMap().scene_file_path != 'res://scenes/maps/Sidescroller.tscn':
			OverworldGlobals.changeMap("res://scenes/maps/Sidescroller.tscn")
		else:
			OverworldGlobals.changeMap("res://scenes/maps/SidescrollerB.tscn")

#func getHUD():
#

func canInteract():
	# GUT REWORK
	return can_move and !UIGlobals.inMenu() and !OverworldGlobals.inDialogue() and !climbing #and !pulling_bow and !shooting_bow# and !animation_player.is_playing()# and velocity == Vector2.ZERO

func isMobile():
	return PlayerGlobals.overworld_stats['walk_speed'] > 0 and PlayerGlobals.overworld_stats['sprint_speed'] > 0

func resetStates(reset_animation:bool=true):
	#undrawBowAnimation()
	#toggleVoidAnimation(false)
	sprinting = false
	setSpeed(PlayerGlobals.overworld_stats['walk_speed'],false)
	ANIMATION_SPEED = 0.0
	cancelBowPull()
	if reset_animation:
			OverworldGlobals.removeAnimationOverlap(self, OverworldGlobals.SpriteType.MAIN)


func canDrawBow()-> bool: 
	if UIGlobals.inMenu():
		return false
	if OverworldGlobals.inDialogue():
		return false
	# Redo empty later
	if !PlayerGlobals.equipNewArrowType() and (PlayerGlobals.equipped_arrow != null and PlayerGlobals.equipped_arrow.stack <= 0):
		return false
	if PlayerGlobals.equipped_arrow == null:
		return false
	if !isMobile():
		return false
	if diving:
		return false
	if battler.visible:
		return false
	
	return true

func toggleBowDrawAnimation(toggle:bool):
	animation_tree["parameters/conditions/draw_bow"] = toggle
	animation_tree["parameters/conditions/undraw_bow"] = !toggle

func canPullBow():
	var has_equipped_arrow = InventoryGlobals.hasItem(PlayerGlobals.equipped_arrow)
	if !has_equipped_arrow and InventoryGlobals.hasArrows():
		PlayerGlobals.equipNewArrowType()
	
	return !OverworldGlobals.inDialogue() and !UIGlobals.inMenu() and can_move and isMobile() and !diving and (isFacingSide() or isFacingUp()) and is_on_floor() and has_equipped_arrow#and has_arrow#and bow_cooldown.is_stopped()

func canShootBow()-> bool:
	return can_move and shoot_ready and isMobile() #and velocity.x == 0

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
	bow_shot.emit()

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
	
	if direction != Vector2.ZERO and !pulling_bow and !shooting_bow: #and bow_cooldown.is_stopped():
		animation_tree["parameters/Idle/blend_position"] = direction
		animation_tree["parameters/Walk/blend_position"] = direction
		animation_tree["parameters/Draw Bow/blend_position"] = direction
		animation_tree["parameters/Draw Bow Walk/blend_position"] = direction
		animation_tree["parameters/Climb/blend_position"] = direction
	
#	if Input.is_action_just_pressed("ui_melee") and canMelee(): 
#		player_camera.flash(Color.WHITE,0.1,0.05,1.5)
#		#undrawBowAnimation()
#		suddenStop()
#		# REDO WITH BATTLER
#		#animation_tree["parameters/conditions/melee"] = true
#		#await animation_tree.animation_finished
#		#animation_tree["parameters/conditions/melee"] = false
#		can_move = true 
#		melee_cooldown.start()
#		melee_bar.start()

func canMelee():
	return can_move and \
		melee_cooldown.is_stopped() and \
		!shooting_bow and \
		isFacingSide() and \
		#bow_mode and \
		!diving and \
		is_on_floor() and \
		!UIGlobals.inMenu()

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

#func toggleBowAnimation():
#	animation_tree["parameters/conditions/equip_bow"] = bow_mode
#	animation_tree["parameters/conditions/unequip_bow"] = !bow_mode

func toggleShootAnimation(toggle:bool):
	animation_tree["parameters/conditions/shoot_bow"] = toggle
	animation_tree["parameters/conditions/draw_bow"] = !toggle

func playFootstep():
	if is_on_floor():
		FootstepSoundManager.playFootstep(global_position)

func saveData(save_data: Array):
	var data = EntitySaveData.new()
	data.scene_path = scene_file_path
	data.position = global_position
	data.direction = int(player_direction.rotation_degrees)
	save_data.append(data)

func loadData():
	get_parent().remove_child(self)
	queue_free()


func _on_bow_draw_time_timeout():
	shoot_ready=true
	OverworldGlobals.playSound("res://audio/sounds/MAGSpel_Anime Ability Ready 2.ogg", -8.0)
