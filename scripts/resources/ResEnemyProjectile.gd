extends Resource
class_name ResEnemyProjectile

@export var hit_script: GDScript
@export var texture: Texture
@export var speed = 800.0
@export var impact_sound: AudioStream = preload("res://audio/sounds/13_Ice_explosion_01.ogg")
@export var free_distance: float = 2500.0

func getProjectile():
	var projectile: ProjectileEnemy = preload("res://scenes/entities_disposable/ProjectileEnemy.tscn").instantiate()
	projectile.hit_script = hit_script
	projectile.PROJECTILE_TEXTURE = texture
	projectile.SPEED = speed
	projectile.IMPACT_SOUND = impact_sound
	projectile.FREE_DISTANCE = free_distance
	return projectile
