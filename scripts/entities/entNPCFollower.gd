extends CharacterBody2D
class_name NPCFollower

@onready var animator = $WalkingAnimations
@onready var sprite = $Sprite2D

var texture: Texture
var host_combatant: ResPlayerCombatant
var speed_multiplier:float = 1.1
var follow_offset=48
var follow_index:int

func _ready():
	name = host_combatant.name.split(' ')[0]
	sprite.texture = texture
	add_collision_exception_with(OverworldGlobals.player)
	OverworldGlobals.player.jumped.connect(jump)
	OverworldGlobals.player.phased.connect(phase)
	OverworldGlobals.player.dived.connect(dive)

func playFootstep():
	FootstepSoundManager.playFootstep(self, global_position,-8)

func jump(jump_velocity):
	if !OverworldGlobals.player.is_on_floor() or speed_multiplier < 1.1:
		return
	z_index = 99
	updateSprite()
	if checkSameXPos():
		fadeInOut()
	global_position = OverworldGlobals.player.global_position+Vector2(0,-32)
	await get_tree().create_timer(0.1*follow_index).timeout
	velocity.y = jump_velocity

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

func phase():
	if speed_multiplier < 1.1:
		return
	if z_index != 0:
		z_index = 0
	updateSprite()
	if checkSameXPos():
		fadeInOut()
	global_position.x = OverworldGlobals.player.global_position.x
	await get_tree().create_timer(0.1*follow_index).timeout
	set_collision_mask_value(1, false)
	await get_tree().create_timer(0.1).timeout
	set_collision_mask_value(1, true)

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
		velocity.x = snappedf(direction.x*(OverworldGlobals.player.SPEED),100.0)
		updateSprite()
	else:
		velocity.x = move_toward(velocity.x, 0, (OverworldGlobals.player.SPEED*speed_multiplier)) # Stop walking
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
		animator.play('Walk_Down')
	elif player_direction == 179:
		animator.play('Walk_Up')

func stopWalkAnimation():
	if !animator.current_animation.contains('Walk'):
		return
	
	animator.seek(1, true)
	animator.pause()
