extends Resource
class_name ResProjectile

enum Projectile_Type {
	Enemy,
	Pulse
}

@export var projectile_data: Dictionary = {}
@export var projectile_type: Projectile_Type
@export var hit_script: GDScript
@export var texture: Texture
@export var speed = 800.0
@export var impact_sound: AudioStream = preload("res://audio/sounds/13_Ice_explosion_01.ogg")
@export var free_distance: float = 500.0
@export var no_clip_time: float = 0.0

func getProjectile()-> Projectile:
	var projectile: Projectile 
	match projectile_type:
		Projectile_Type.Enemy: 
			projectile = preload("res://scenes/entities_disposable/ProjectileEnemy.tscn").instantiate()
		Projectile_Type.Pulse:
			projectile = preload("res://scenes/entities_disposable/ProjectilePulse.tscn").instantiate()
			projectile.radius = projectile_data['radius']
			projectile.animation = projectile_data['animation']
			if projectile_data.has('animation_data'):
				projectile.animation_data = projectile_data['animation_data']
			
	projectile.hit_script = hit_script
	projectile.projectile_texture = texture
	projectile.SPEED = speed
	projectile.impact_sound = impact_sound
	projectile.free_distance = free_distance
	projectile.no_clip_time = no_clip_time
	return projectile
