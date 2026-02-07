extends CharacterBody2D
class_name NPCFollower

@onready var animator = $WalkingAnimations
@onready var sprite = $Sprite2D
@onready var top_sprite = $JumpPhaseSprite

var texture: Texture
var host_combatant: ResPlayerCombatant
var speed_multiplier:float = 1.1
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
	landed.connect(func(): toggleTopSprite(false))

func playFootstep():
	if is_on_floor() and modulate == Color.WHITE:
		FootstepSoundManager.playFootstep(global_position,-10)

func jump(jump_velocity):
	if !OverworldGlobals.player.is_on_floor() or !is_on_floor() or speed_multiplier < 1.1:
		return
	z_index = 99
	if checkSameXPos():
		fadeInOut()
	global_position = OverworldGlobals.player.global_position+Vector2(0,-32)
	updateSprite()
	await get_tree().create_timer(0.1*follow_index).timeout
	showTopSprite(6)
	velocity.y = jump_velocity
	do_land_flag = true

func dive():
	fadeInOut()
	var direction = int(OverworldGlobals.player.player_direction.rotation_degrees)
	global_position = OverworldGlobals.player.getPosOffset()+Vector2(8,0)
	velocity.y = OverworldGlobals.player.dive_strength
	
	if direction == 90:
		sprite.flip_h = false
	elif direction == -90:
		sprite.flip_h = true
	animator.play('Dive')
	do_land_flag = true

func phase():
	if speed_multiplier < 1.1:
		return
	if z_index != 0:
		z_index = 0
	if checkSameXPos():
		fadeInOut()
	global_position.x = OverworldGlobals.player.global_position.x
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

func fade(color: Color,duration:float=0.25):
	if color == modulate:
		return
	updateSprite()
	var tween = create_tween().tween_property(self, 'modulate', color, duration)
	await tween.finished

func _physics_process(delta):
#	if !OverworldGlobals.getCombatantSquad('Player').has(host_combatant):
#		queue_free()
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
	elif do_land_flag:
		landed.emit()
		do_land_flag = false
	
	if speed_multiplier < 1.0:
		return
	if OverworldGlobals.player.sprinting:
		animator.speed_scale = 2.0
	else:
		animator.speed_scale = 1.0
	
	if OverworldGlobals.player.diving and not is_on_floor():
		velocity.x = OverworldGlobals.player.direction.x * 500.0
	elif OverworldGlobals.player.diving and is_on_floor():
		velocity.x = move_toward(OverworldGlobals.player.velocity.x, 0, 500.0)
	
	if OverworldGlobals.player.climbing:
		fade(Color.TRANSPARENT)
	elif modulate == Color.TRANSPARENT and (OverworldGlobals.player.velocity.y == 0 and OverworldGlobals.player.is_on_floor()):
		teleportToTarget()
	
	if global_position.distance_to(OverworldGlobals.player.global_position) > follow_offset*follow_index:
		if z_index != 0: z_index = 0
		var direction = (OverworldGlobals.player.position-position).normalized()
		velocity.x = snappedf(direction.x*(OverworldGlobals.player.speed),100.0)
		updateSprite()
	else:
		velocity.x = move_toward(velocity.x, 0, (OverworldGlobals.player.speed*speed_multiplier))
		stopWalkAnimation()
	if global_position.distance_to(OverworldGlobals.player.global_position) > 300 and !OverworldGlobals.player.climbing:
		fadeInOut()
		teleportToTarget()
	
	
	move_and_slide()

func teleportToTarget(follow_point:bool=false):
	if !follow_point:
		global_position = OverworldGlobals.player.global_position+Vector2(0,-32)
	else:
		global_position =OverworldGlobals.player.global_position+Vector2((follow_index*follow_offset),-32)
	fade(Color.WHITE)

func getFollowPoint(offset:Vector2=Vector2(1,0)):
	return OverworldGlobals.player.global_position+(Vector2((follow_index*follow_offset),0)*offset)

func updateSprite():
	if OverworldGlobals.player.diving:
		return
	
	var player_direction: int = OverworldGlobals.player.player_direction.rotation_degrees
	
	if player_direction == 90:
		animator.play('Walk_Left')
	elif player_direction == -90:
		animator.play('Walk_Right')
	elif player_direction == 0:
		print('fuh')
		animator.play('Walk_Down')
	elif player_direction == 179:
		print('juh')
		animator.play('Walk_Up')

## 0 = phase, 6 = jump
func showTopSprite(set_frame:int):
	toggleTopSprite(true)
	top_sprite.frame=set_frame

func toggleTopSprite(toggle_to:bool):
	sprite.visible = !toggle_to
	top_sprite.visible = toggle_to

func stopWalkAnimation():
	if !animator.current_animation.contains('Walk') or !animator.is_playing():
		return
	
	animator.seek(1, true)
	animator.pause()
