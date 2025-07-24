extends Projectile
class_name ProjectilePulse

@export var radius: float
@export var hit_script: GDScript
@export var animation: String
@export var animation_data: Dictionary = {}

func _on_body_entered(body):
	if shooter != null and body != shooter:
		queue_free()

func _exit_tree():
	OverworldGlobals.showAbilityAnimation(animation, global_position, animation_data)
	OverworldGlobals.addEffectPulse(global_position, radius, hit_script)
