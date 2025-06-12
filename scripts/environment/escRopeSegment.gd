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
	if player_on_segment and OverworldGlobals.getPlayer().climbing and !OverworldGlobals.getPlayer().is_on_floor():
		OverworldGlobals.getPlayer().global_position.x = global_position.x

func _input(event):
	if Input.is_action_pressed('ui_accept') and player_on_segment:
		OverworldGlobals.getPlayer().climbing = false
		OverworldGlobals.getPlayer().jump()
		apply_force(Vector2(50.0*OverworldGlobals.getPlayer().velocity.x,0))
