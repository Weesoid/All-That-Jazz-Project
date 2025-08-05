extends GenericPatroller
class_name GenericPatrollerShooter

@export var projectile: ResProjectile

func doAction():
	if direction == 1:
		line_of_sight.rotation_degrees = -90
		sprite.flip_h = false
	elif direction == -1:
		line_of_sight.rotation_degrees = 90
		sprite.flip_h = true
	if !isSameYLevel():
		line_of_sight.look_at(OverworldGlobals.player.global_position+OverworldGlobals.player.sprite.offset+Vector2(0,-16))
		line_of_sight.rotation -= PI/2
	velocity.x = move_toward(velocity.x, 0, speed)
	action_cooldown.start()
	var shot = projectile.getProjectile()
	shot.global_position = global_position + Vector2(0, -10)
	shot.shooter = self
	get_tree().current_scene.add_child(shot)
	shot.rotation = line_of_sight.rotation + 1.57079994678497
	animator.play('Action')

func chase():
	# check y
#	var y_pos = snappedf(shape.global_position.y,100.0)
#	var y_pos_player = snappedf(OverworldGlobals.player.get_node('PlayerCollision').global_position.y, 100.0)
#	if y_pos != y_pos_player:
#		updateState(State.IDLE)
	
	var flat_pos:Vector2 = OverworldGlobals.flattenY(shape.global_position)
	var flat_palyer_pos:Vector2 = OverworldGlobals.flattenY(OverworldGlobals.player.get_node('PlayerCollision').global_position)
	# action
	direction = int((flat_pos.direction_to(flat_palyer_pos)).x)
	if flat_pos.distance_to(flat_palyer_pos) <= min_action_distance and canDoAction():
		doAction()
	elif flat_pos.distance_to(flat_palyer_pos) > min_action_distance and combat_switch and !animator.current_animation.contains('Action'):
		velocity.x = (direction * speed) * chase_speed_multiplier # chase!
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
