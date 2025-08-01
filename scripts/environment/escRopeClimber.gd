extends Area2D
class_name ClimberArea

func _on_body_exited(body):
	if body is PlayerScene:
		setClimbingFalse()

func _input(event):
	if OverworldGlobals.player == null or get_parent().must_shoot or !OverworldGlobals.player.isMovementAllowed() or !OverworldGlobals.player.climb_cooldown.is_stopped():
		return
	
	if playerInClimbable() and inputtedMovement():
		OverworldGlobals.player.fall_damage = 0
		OverworldGlobals.player.climbing = true
	if playerInClimbable() and get_parent().isPlayerOnEnterArea() and inputtedMovement():
		OverworldGlobals.player.toggleClimbAnimation(true)
		OverworldGlobals.player.set_collision_mask_value(1, false)
	elif playerInClimbable() and !get_parent().isPlayerOnEnterArea() and inputtedMovement():
		OverworldGlobals.player.toggleClimbAnimation(true)
		OverworldGlobals.player.set_collision_mask_value(1, true)
	elif playerInClimbable() and !get_parent().isPlayerOnEnterArea() and OverworldGlobals.player.is_on_floor():
		setClimbingFalse()

func inputtedMovement():
	return Input.is_action_pressed("ui_move_down") or Input.is_action_pressed("ui_move_up")

func setClimbingFalse():
	OverworldGlobals.player.climbing = false
	OverworldGlobals.player.toggleClimbAnimation(false)
	if !OverworldGlobals.player.get_collision_mask_value(1):
		OverworldGlobals.player.set_collision_mask_value(1, true)

func playerInClimbable():
	return get_overlapping_bodies().has(OverworldGlobals.player)
