extends Area2D
class_name ClimberArea

func _on_body_entered(body):
	if body is PlayerScene:
		body.climbing = true

func _on_body_exited(body):
	if body is PlayerScene:
		body.climbing = false
		if !body.get_collision_mask_value(1):
			OverworldGlobals.getPlayer().set_collision_mask_value(1, true)

func _input(event):
	if playerInClimbable() and get_parent().isPlayerOnPin() and Input.is_action_just_pressed("ui_move_down"):
		OverworldGlobals.getPlayer().set_collision_mask_value(1, false)
	elif playerInClimbable() and !get_parent().isPlayerOnPin():
		OverworldGlobals.getPlayer().set_collision_mask_value(1, true)

func playerInClimbable():
	return get_overlapping_bodies().has(OverworldGlobals.getPlayer())
