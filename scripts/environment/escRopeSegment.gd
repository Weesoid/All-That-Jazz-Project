extends RigidBody2D
class_name RopeSegment


func _on_area_2d_body_entered(body):
	if body is PlayerScene:
		linear_velocity.x = 20

func _on_area_2d_body_exited(body):
	if body is PlayerScene:
		linear_velocity.x = 0
