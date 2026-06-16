extends CharacterBody2D
class_name NPCFollower

const DEFAULT_SPEED = 1.1
@onready var animator = $WalkingAnimations
@onready var sprite = $Sprite2D
@onready var top_sprite = $JumpPhaseSprite
@onready var fade_in_delay = $FadeInDelay
var texture: Texture
var host_combatant: ResPlayerCombatant
var speed_multiplier:float = DEFAULT_SPEED
var follow_offset=48
var follow_index:int

signal landed
var do_land_flag:bool=true

func _ready():
	name = host_combatant.name.split(' ')[0]
	sprite.texture = texture
	await get_tree().process_frame # temp
	add_collision_exception_with(OverworldGlobals.player)
	OverworldGlobals.player.jumped.connect(jump)
	OverworldGlobals.player.phased.connect(phase)
	OverworldGlobals.player.dived.connect(dive)
	OverworldGlobals.player.climb_started.connect(
		func():
			#if !fade_in_delay.is_stopped(): return
			speed_multiplier = 0.0
			fade(
				Color.TRANSPARENT, 
				0.25, 
				0 if OverworldGlobals.player.velocity.y > 0 else 179)
			)
	OverworldGlobals.player.landed.connect(
		func(was_climbing):
			if !was_climbing: return
			speed_multiplier = DEFAULT_SPEED
			teleportToTarget(false, canFadeIn())
			)
	
	landed.connect(func(_p):
		toggleTopSprite(false))
	connectFadeOut()

func connectFadeOut():
	var patrollers = OverworldGlobals.getAllPatrollers()
	for patroller in patrollers:
		patroller.visible_on_screen.screen_entered.connect(fade.bind(Color.TRANSPARENT))
		patroller.visible_on_screen.screen_exited.connect(
			func(): 
				fade_in_delay.start(5)
				)

func canFadeIn()->bool:
	for patroller in OverworldGlobals.getAllPatrollers():
		if patroller.isOnScreen(): 
			return false
	
	return true

func playFootstep():
	if is_on_floor() and modulate == Color.WHITE:
		FootstepSoundManager.playFootstep(global_position,-10)

func jump(jump_velocity):
	#print(!OverworldGlobals.player.is_on_floor(), ' or ', !is_on_floor(), ' or ', speed_multiplier < 1.1, ' or ', !canFadeIn())
	if !OverworldGlobals.player.is_on_floor() or !is_on_floor() or speed_multiplier < DEFAULT_SPEED or !canFadeIn():
		return
	#do_land_flag = true
	z_index = 99
	if checkSameXPos():
		fadeInOut()
	global_position = OverworldGlobals.player.global_position+Vector2(0,-32)
	updateSprite()
	await get_tree().create_timer(0.1*follow_index).timeout
	showTopSprite(6)
	velocity.y = jump_velocity

func dive():
	if !canFadeIn():
		return
	fadeInOut()
	var direction = int(OverworldGlobals.player.player_direction.rotation_degrees)
	global_position = OverworldGlobals.player.getPosOffset()+Vector2(8,0)
	velocity.y = OverworldGlobals.player.dive_strength
	#do_land_flag = true
	
	if direction == 90:
		sprite.flip_h = false
	elif direction == -90:
		sprite.flip_h = true
	animator.play('Dive')

func phase():
	if speed_multiplier < DEFAULT_SPEED or !canFadeIn():
		return
	if z_index != 0:
		z_index = 0
	if checkSameXPos():
		fadeInOut()
	global_position.x = OverworldGlobals.player.global_position.x
	teleportToTarget()
	updateSprite()
	await get_tree().create_timer(0.1*follow_index).timeout
	showTopSprite(0)
	set_collision_mask_value(1, false)
	await get_tree().create_timer(0.1).timeout
	set_collision_mask_value(1, true)
	do_land_flag = true

func checkSameXPos():
	return ceil(global_position.x) != ceil(OverworldGlobals.player.global_position.x)

func fadeInOut():
	await fade(Color.TRANSPARENT,0.0)
	fade(Color.WHITE)

func fade(color: Color,duration:float=0.25,override_direction:int=-1):
#	print('Received color: ', color, ' / ', 'Curr color ', modulate)
	if color == modulate:
		return
	#print('Fading to ', color)
	updateSprite(override_direction)
	var tween = create_tween().tween_property(self, 'modulate', color, duration)
	await tween.finished

# TODO Change to signals
# Climb start > fade trans
# 
func _physics_process(delta):
#	if !OverworldGlobals.getCombatantSquad('Player').has(host_combatant):
#		queue_free()
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
		do_land_flag = true
	elif do_land_flag:
		print('emittarium')
		landed.emit(false)
		do_land_flag = false
	
	if speed_multiplier < 1.0 or OverworldGlobals.player.bow_draw_strength > 0:
		stopWalkAnimation()
		return
	if OverworldGlobals.player.sprinting:
		animator.speed_scale = 2.0
	else:
		animator.speed_scale = 1.0
	
	if OverworldGlobals.player.diving and not is_on_floor():
		velocity.x = OverworldGlobals.player.direction.x * 500.0
	elif OverworldGlobals.player.diving and is_on_floor():
		velocity.x = move_toward(OverworldGlobals.player.velocity.x, 0, 500.0)
	
	#if OverworldGlobals.player.climbing:
	#	fade(Color.TRANSPARENT)
	#elif modulate == Color.TRANSPARENT and (OverworldGlobals.player.velocity.y == 0 and OverworldGlobals.player.is_on_floor()):
	#	teleportToTarget()
	
	if global_position.distance_to(OverworldGlobals.player.global_position) > follow_offset*follow_index:
		if z_index != 0: z_index = 0
		var direction = (OverworldGlobals.player.position-position).normalized()
		velocity.x = snappedf(direction.x*(OverworldGlobals.player.speed),100.0)
		updateSprite()
		print('AGH!')
	else:
		velocity.x = move_toward(velocity.x, 0, (OverworldGlobals.player.speed*speed_multiplier))
		stopWalkAnimation()
	if global_position.distance_to(OverworldGlobals.player.global_position) > 300 and !OverworldGlobals.player.climbing:
		fadeInOut()
		teleportToTarget()
	
	
	move_and_slide()

func teleportToTarget(follow_point:bool=false, do_fade_in:bool=true):
	var teleport_pos = OverworldGlobals.player.global_position+Vector2((follow_index*follow_offset),-32) if follow_point else OverworldGlobals.player.global_position+Vector2(0,-32)
	#if global_position.is_equal_approx(teleport_pos):
	#	return
	
	global_position = teleport_pos
	if do_fade_in:
		fade(Color.WHITE)
	
#	if !follow_point:
#		global_position = OverworldGlobals.player.global_position+Vector2(0,-32)
#	else:
#		global_position =OverworldGlobals.player.global_position+Vector2((follow_index*follow_offset),-32)

func getFollowPoint(offset:Vector2=Vector2(1,0)):
	return OverworldGlobals.player.global_position+(Vector2((follow_index*follow_offset),0)*offset)

func updateSprite(override_direction:int=-1):
	if OverworldGlobals.player.diving:
		return
	
	var player_direction: int = OverworldGlobals.player.player_direction.rotation_degrees if override_direction < 0 else override_direction
	#print('received dir ', player_direction)
	if player_direction == 90:
		animator.play('Walk_Left')
	elif player_direction == -90:
		animator.play('Walk_Right')
	elif player_direction == 0:
		animator.play('Walk_Down')
	elif player_direction == 179:
		animator.play('Walk_Up')

## 0 = phase, 6 = jump
func showTopSprite(set_frame:int):
	toggleTopSprite(true)
	top_sprite.frame=set_frame

func toggleTopSprite(toggle_to:bool):
	#print('toggling')
	sprite.visible = !toggle_to
	top_sprite.visible = toggle_to
	updateSprite()
	#await get_tree().process_frame
	#updateSprite()

func stopWalkAnimation():
	if !animator.current_animation.contains('Walk') or !animator.is_playing():
		return
	
	animator.seek(1, true)
	animator.pause()


func _on_fade_in_delay_timeout():
	if canFadeIn(): fade(Color.WHITE)
