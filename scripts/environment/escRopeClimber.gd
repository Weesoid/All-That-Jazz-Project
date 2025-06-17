extends Area2D
class_name ClimberArea

func _on_body_exited(body):
	if body is PlayerScene:
		setClimbingFalse()

func _input(event):
	if OverworldGlobals.getPlayer() == null or get_parent().must_shoot or !OverworldGlobals.getPlayer().isMovementAllowed():
		return
	
	if playerInClimbable() and inputtedMovement():
		OverworldGlobals.getPlayer().fall_damage = 0
		OverworldGlobals.getPlayer().climbing = true
	if playerInClimbable() and get_parent().isPlayerOnEnterArea() and inputtedMovement():
		OverworldGlobals.getPlayer().toggleClimbAnimation(true)
		OverworldGlobals.getPlayer().set_collision_mask_value(1, false)
	elif playerInClimbable() and !get_parent().isPlayerOnEnterArea() and inputtedMovement():
		OverworldGlobals.getPlayer().toggleClimbAnimation(true)
		OverworldGlobals.getPlayer().set_collision_mask_value(1, true)
	elif playerInClimbable() and !get_parent().isPlayerOnEnterArea() and OverworldGlobals.getPlayer().is_on_floor():
		setClimbingFalse()

func inputtedMovement():
	return Input.is_action_pressed("ui_move_down") or Input.is_action_pressed("ui_move_up")

func setClimbingFalse():
	OverworldGlobals.getPlayer().climbing = false
	OverworldGlobals.getPlayer().toggleClimbAnimation(false)
	if !OverworldGlobals.getPlayer().get_collision_mask_value(1):
		OverworldGlobals.getPlayer().set_collision_mask_value(1, true)

func playerInClimbable():
	return get_overlapping_bodies().has(OverworldGlobals.getPlayer())
