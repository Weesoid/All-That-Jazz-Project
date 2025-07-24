extends GenericPatrollerShooter
class_name HybridPatroller

@onready var melee_action_cooldown = $MeleeActionCooldown
@export var min_melee_action_distance: float = 25

func chase():
	# check y
	var y_pos = snappedf(shape.global_position.y,100.0)
	var y_pos_player = snappedf(OverworldGlobals.getPlayer().get_node('PlayerCollision').global_position.y, 100.0)
	if y_pos != y_pos_player:
		updateState(State.IDLE)
	
	var flat_pos:Vector2 = OverworldGlobals.flattenY(shape.global_position)
	var flat_palyer_pos:Vector2 = OverworldGlobals.flattenY(OverworldGlobals.getPlayer().get_node('PlayerCollision').global_position)
	# action
	direction = (flat_pos.direction_to(flat_palyer_pos)).x
	if flat_pos.distance_to(flat_palyer_pos) <= min_action_distance and canDoAction():
		doAction()
		velocity.x = 0
		return
	elif combat_switch and !animator.current_animation.contains('Action'):
		if flat_pos.distance_to(flat_palyer_pos) <= min_melee_action_distance and canDoMeleeAction():
			doMeleeAction()
			return
		velocity.x = (direction * speed) * chase_speed_multiplier

func canDoMeleeAction():
	return !action_cooldown.is_stopped() and melee_action_cooldown.is_stopped() and !animator.current_animation.contains('Action') and state != State.STUNNED

func doMeleeAction():
	combat_switch = false
	velocity.x = 0
	melee_action_cooldown.start()
	if sprite.flip_h:
		melee_hitbox.position = Vector2(-22,-23)
	else:
		melee_hitbox.position = Vector2(22,-23)
	animator.stop()
	animator.play('Action_Melee')
	await animator.animation_finished
	combat_switch = true
