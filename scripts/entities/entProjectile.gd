extends Area2D
class_name Projectile

@export var SPEED = 1500.0
var SHOOTER: CharacterBody2D
var SPAWN_LOCATION: Vector2

func _ready():
	SPAWN_LOCATION = global_position

func _physics_process(delta):
	global_position += Vector2(cos(rotation), sin(rotation)) * SPEED * delta
	if global_position.distance_to(SPAWN_LOCATION)>2500.0:
		queue_free()

func _on_body_entered(body):
	pass
