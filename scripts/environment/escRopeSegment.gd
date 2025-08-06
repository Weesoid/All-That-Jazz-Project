extends RigidBody2D
class_name RopeSegment

var player_on_segment = false

func _on_area_2d_body_entered(body):
	if body is PlayerScene:
		player_on_segment = true
		linear_velocity.x = 20

func _on_area_2d_body_exited(body):
	if body is PlayerScene:
		player_on_segment = false
		linear_velocity.x = 0
	
# MIGHT BE A PROBLEM!
func _physics_process(_delta):
	if player_on_segment and OverworldGlobals.player.climbing and !OverworldGlobals.player.is_on_floor():
		OverworldGlobals.player.global_position.x = global_position.x

func _input(_event):
	if Input.is_action_just_pressed('ui_accept') and player_on_segment and OverworldGlobals.player.isMovementAllowed() and OverworldGlobals.player.climbing:
		if !OverworldGlobals.player.get_collision_mask_value(1):
			OverworldGlobals.player.set_collision_mask_value(1, true)
		OverworldGlobals.player.climbing = false
		OverworldGlobals.player.toggleClimbAnimation(false)
		OverworldGlobals.player.jump()
		apply_force(Vector2(50.0*OverworldGlobals.player.velocity.x,0))
		
