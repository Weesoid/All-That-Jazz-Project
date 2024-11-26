extends Node2D
class_name ScriptedMovement

var BODY: CharacterBody2D
# * = Animation (ex. *Spin)
# w = Wait (ex. w10.5)
# ^ = Direction (ex. ^U) (Only applicable to non-player scenes)
var TARGET_POSITIONS = []
var MOVE_SPEED = 35
var ANIMATE_DIRECTION: bool

signal movement_finished
signal animation_done

func _ready():
	BODY = get_parent()
	BODY.set_physics_process(false)
	BODY.set_collision_layer_value(1, false)
	BODY.set_collision_mask_value(1, false)

func _physics_process(_delta):
	BODY.move_and_slide()
	
	if !TARGET_POSITIONS.is_empty():
		if TARGET_POSITIONS[0] is Vector2:
			BODY.velocity = BODY.global_position.direction_to(TARGET_POSITIONS[0]) * MOVE_SPEED
			if BODY.global_position.distance_to(TARGET_POSITIONS[0]) < 1.0:
				TARGET_POSITIONS.remove_at(0)
		elif TARGET_POSITIONS[0] is String and TARGET_POSITIONS[0].substr(0,1) == '*':
			var animation = TARGET_POSITIONS[0]
			playAnimation(animation.replace('*', ''))
			await animation_done
			TARGET_POSITIONS.erase(animation)
		elif TARGET_POSITIONS[0] is String and TARGET_POSITIONS[0].substr(0,1) == '^':
			var animation = TARGET_POSITIONS[0]
			updateSprite(TARGET_POSITIONS[0].replace('^', ''))
			TARGET_POSITIONS.erase(animation)
		elif TARGET_POSITIONS[0] is String and TARGET_POSITIONS[0].substr(0,1) == 'w':
			var animation = TARGET_POSITIONS[0]
			BODY.velocity = Vector2.ZERO
			await get_tree().create_timer(float(animation.replace('w',''))).timeout
			TARGET_POSITIONS.erase(animation)
		
		if !TARGET_POSITIONS.is_empty() and TARGET_POSITIONS[0] is Vector2 and ANIMATE_DIRECTION:
			if BODY is PlayerScene:
				OverworldGlobals.getPlayer().direction = BODY.velocity.normalized()
			elif BODY.has_node('WalkingAnimations'):
				animateWalk()
	
	elif TARGET_POSITIONS.is_empty():
		BODY.velocity = Vector2.ZERO
		BODY.set_collision_layer_value(1, true)
		BODY.set_collision_mask_value(1, true)
		movement_finished.emit()
		BODY.set_physics_process(true)
		queue_free()

func moveBody(move_sequence: String):
	if move_sequence.contains('v>'):
		move_sequence = move_sequence.replace('v>', '')
		setVectorMoveSequence(move_sequence.split(','))
	elif move_sequence.contains('>'):
		move_sequence = move_sequence.replace('>', '')
		setMoveSequence(move_sequence.split(','))

func setMoveSequence(movements: Array[String]):
	var previous_position
	for i in range(movements.size()):
		if setAnimation(movements[i]):
			continue
		
		var direction
		match movements[i].substr(0,1):
			"L": direction = Vector2(-1, 0) * Vector2(int(movements[i].substr(1,2)), 0)
			"R": direction = Vector2(1, 0) * Vector2(int(movements[i].substr(1,2)), 0)
			"U": direction = Vector2(0, -1) * Vector2(0, int(movements[i].substr(1,2)))
			"D": direction = Vector2(0, 1) * Vector2(0, int(movements[i].substr(1,2)))
		
		if i == 0:
			TARGET_POSITIONS.append(BODY.global_position + direction)
			previous_position = BODY.global_position + direction
		else:
			TARGET_POSITIONS.append(previous_position + direction)
			previous_position = previous_position + direction

func setVectorMoveSequence(movements: Array[String]):
	for pos in movements:
		if setAnimation(pos):
			continue
		var coords = pos.split(' ')
		TARGET_POSITIONS.append(Vector2(int(coords[0]), int(coords[1])))

func setAnimation(movement):
	if movement.substr(0,1) == '*' or movement.substr(0,1) == '^' or movement.substr(0,1) == 'w':
		TARGET_POSITIONS.append(movement)
		return true
	else:
		return false

func animateWalk():
	look_at(TARGET_POSITIONS[0])
	rotation -= PI/2
	var look_direction = global_rotation_degrees
	
	if look_direction < 135 and look_direction > 45:
		updateSprite('L')
	elif look_direction < -45 and look_direction > -135:
		updateSprite('R')
	elif look_direction < 45 and look_direction > -45:
		updateSprite('D')
	else:
		updateSprite('U')

func updateSprite(direction: String):
	var animator 
	if BODY is PlayerScene:
		animator = BODY.get_node('WalkingAnimations')
	else:
		animator = OverworldGlobals.getEntityAnimator(BODY.name)
		
	
	if direction == 'L':
		animator.play('Walk_Left')
	elif direction == 'R':
		animator.play('Walk_Right')
	elif direction == 'D':
		animator.play('Walk_Down')
	else:
		animator.play('Walk_Up')

func playAnimation(animation_name: String, animation_player_name: String = 'AnimationPlayer'):
	BODY.velocity = Vector2.ZERO
	var animator = BODY.get_node(animation_player_name)
	animator.play(animation_name)
	await animator.animation_finished
	animation_done.emit()
