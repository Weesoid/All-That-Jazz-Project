extends Camera2D
class_name DynamicCamera

var shake_strength: float = 0.0
var shake_speed: float = 0.0

func _process(delta):
	if shake_strength != 0:
		shake_strength = lerpf(shake_strength, 0, shake_speed * delta)
		offset = Vector2(randf_range(-shake_strength,shake_strength), randf_range(-shake_strength,shake_strength))

func shake(strength: float, speed: float):
	shake_speed = speed
	shake_strength = strength
