extends CharacterBody2D
class_name NPCFollower

@onready var ANIMATOR = $WalkingAnimations
@onready var player = OverworldGlobals.getPlayer()

var host_combatant: ResPlayerCombatant
var speed_multiplier:float = 1.1
var follow_index:int

func _ready():
	#follow_index = OverworldGlobals.player_follower_count
	add_collision_exception_with(OverworldGlobals.getPlayer())
	player.jumped.connect(jump)
	player.phased.connect(phase)

func jump(jump_velocity):
	if !player.is_on_floor():
		return
	z_index = 99
	updateSprite()
	if checkSameXPos():
		fadeInOut()
	global_position = player.global_position+Vector2(0,-32)
	await get_tree().create_timer(0.1).timeout
	velocity.y = jump_velocity

func phase():
	if z_index != 0:
		z_index = 0
	updateSprite()
	if checkSameXPos():
		fadeInOut()
	global_position.x = player.global_position.x
	await get_tree().create_timer(0.05).timeout
	set_collision_mask_value(1, false)
	await get_tree().create_timer(0.1).timeout
	set_collision_mask_value(1, true)

func checkSameXPos():
	return ceil(global_position.x) != ceil(player.global_position.x)

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
	
	if player.climbing:
		fade(Color.TRANSPARENT)
	elif modulate == Color.TRANSPARENT and (player.velocity.y == 0 and player.is_on_floor()):
		teleportToTarget()
	
	if global_position.distance_to(player.global_position) > 50*follow_index:
		if z_index != 0: z_index = 0
		var direction = (player.position-position).normalized()
		velocity.x = snappedf(direction.x*(player.SPEED),100.0)
		print(velocity.x)
		#print('my velo: ', velocity, ' vs player velo', player.velocity)
		updateSprite()
	else:
		velocity.x = move_toward(velocity.x, 0, (player.SPEED*speed_multiplier)) # Stop walking
		stopWalkAnimation()
	if global_position.distance_to(player.global_position) > 300 and !player.climbing:
		fadeInOut()
		teleportToTarget()
		
	
	
	move_and_slide()

func teleportToTarget():
	global_position = player.global_position+Vector2(0,-32)
	fade(Color.WHITE)

func updateSprite():
	var player_direction: int = OverworldGlobals.getPlayer().player_direction.rotation_degrees
	
	if player_direction == 90:
		ANIMATOR.play('Walk_Left')
	elif player_direction == -90:
		ANIMATOR.play('Walk_Right')
	elif player_direction == 0:
		ANIMATOR.play('Walk_Down')
	elif player_direction == 179:
		ANIMATOR.play('Walk_Up')

func stopWalkAnimation():
	ANIMATOR.seek(1, true)
	ANIMATOR.pause()
