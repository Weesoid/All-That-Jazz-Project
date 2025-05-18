extends Node
class_name SpriteShaker

@onready var sprite: Sprite2D = get_parent()
var shake_strength: float = 0.0
var shake_speed: float = 0.0

func _process(delta):
	if shake_strength != 0 and sprite != null:
		shake_strength = lerpf(shake_strength, 0, shake_speed * delta)
		sprite.offset = Vector2(randf_range(-shake_strength,shake_strength), sprite.offset.y)
	else:
		#if sprite.get_parent() is CombatantScene: sprite.offset = sprite.get_parent().offset
		queue_free()
