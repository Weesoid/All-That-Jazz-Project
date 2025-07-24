extends Node2D
class_name ScriptedMovement

var body: CharacterBody2D
# * = Animation (ex. *Spin)
# w = Wait (ex. w10.5)
# ^ = Direction (ex. ^U) (Only applicable to non-player scenes)
@export var target_positions = []
@export var move_speed = 100.0
@export var animate_direction: bool
var jumping:bool=false
var body_shape_disabled:bool

signal landed
signal movement_finished
signal animation_done

func _ready():
	body = get_parent()
	body.set_physics_process(false)
	#setCollisionExceptions()

func setCollisionExceptions():
	for child in OverworldGlobals.getCurrentMap().get_children().filter(func(chimp): return chimp is CharacterBody2D):
		body.add_collision_exception_with(child)

func _physics_process(delta):
	if not body.is_on_floor():
		body.velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
	elif body.is_on_floor() and jumping:
		jumping=false
		if target_positions[0] is float: target_positions.remove_at(0)
	
	if !target_positions.is_empty():
		if target_positions[0] is Vector2:
			body.velocity.x = (flattenY(body.global_position).direction_to(flattenY(target_positions[0]))).x * move_speed 
			if distanceX(body.global_position, target_positions[0]) < 1.0:
				target_positions.remove_at(0)
		elif target_positions[0] is float:
			jumpBody(target_positions[0])
		elif target_positions[0] is String and target_positions[0].substr(0,1) == '*':
			var animation = target_positions[0]
			playAnimation(animation.replace('*', ''))
			await animation_done
			target_positions.erase(animation)
		elif target_positions[0] is String and target_positions[0].substr(0,1) == '^':
			var animation = target_positions[0]
			updateSprite(target_positions[0].replace('^', ''))
			target_positions.erase(animation)
		elif target_positions[0] is String and target_positions[0].substr(0,1) == 'w':
			var animation = target_positions[0]
			body.velocity = Vector2.ZERO
			await get_tree().create_timer(float(animation.replace('w',''))).timeout
			target_positions.erase(animation)
		
		if !target_positions.is_empty() and target_positions[0] is Vector2 and animate_direction:
			if body is PlayerScene:
				OverworldGlobals.getPlayer().direction = body.velocity.normalized()
			elif body.has_node('WalkingAnimations'):
				animateWalk()
	elif target_positions.is_empty():
		body.velocity = Vector2.ZERO
		#body.set_collision_layer_value(1, true)
		#body.set_collision_mask_value(1, true)
		movement_finished.emit()
		body.set_physics_process(true)
		queue_free()
	
	body.move_and_slide()

func flattenY(vector):
	return Vector2(vector.x,0)

func distanceX(position_a, position_b):
	return flattenY(position_a).distance_to(flattenY(position_b))

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
			"J": 
				if movements[i].replace('J','') != '':
					direction = float(movements[i].replace('J',''))
				else:
					direction = 200.0
		if direction is Vector2:
			if i == 0:
				target_positions.append(body.global_position + direction)
				previous_position = body.global_position + direction
			else:
				target_positions.append(previous_position + direction)
				previous_position = previous_position + direction
		else:
			target_positions.append(-direction)

func jumpBody(jump_velocity:float):
	if body.is_on_floor():
		body.velocity.x = 0.0
		body.velocity.y = jump_velocity
		jumping=true

func setVectorMoveSequence(movements: Array[String]):
	for pos in movements:
		if setAnimation(pos):
			continue
		var coords = pos.split(' ')
		target_positions.append(Vector2(int(coords[0]), int(coords[1])))

func setAnimation(movement):
	if movement.substr(0,1) == '*' or movement.substr(0,1) == '^' or movement.substr(0,1) == 'w':
		target_positions.append(movement)
		return true
	else:
		return false

func animateWalk():
	look_at(target_positions[0])
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
	if body is PlayerScene:
		animator = body.get_node('WalkingAnimations')
	else:
		animator = OverworldGlobals.getEntityAnimator(body.name)
		
	
	if direction == 'L':
		animator.play('Walk_Left')
	elif direction == 'R':
		animator.play('Walk_Right')
	elif direction == 'D':
		animator.play('Walk_Down')
	else:
		animator.play('Walk_Up')

func playAnimation(animation_name: String, animation_player_name: String = 'AnimationPlayer'):
	body.velocity = Vector2.ZERO
	var animator = body.get_node(animation_player_name)
	animator.play(animation_name)
	await animator.animation_finished
	animation_done.emit()


func _on_tree_exited():
	body.velocity = Vector2.ZERO
