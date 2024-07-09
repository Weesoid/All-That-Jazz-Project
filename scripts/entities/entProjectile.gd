extends Area2D
class_name Projectile

@export var SPEED = 1500.0
@export var IMPACT_SOUND: AudioStream = preload("res://audio/sounds/13_Ice_explosion_01.ogg")
@onready var AUDIO = $AudioStreamPlayer2D
var SHOOTER: CharacterBody2D
var SPAWN_LOCATION: Vector2

func _ready():
	SPAWN_LOCATION = global_position

func _physics_process(delta):
	global_position += Vector2(cos(rotation), sin(rotation)) * SPEED * delta
	if global_position.distance_to(SPAWN_LOCATION)>2500.0: queue_free()

func _on_body_entered(body):
	var _b = body
	queue_free()

func _exit_tree():
	if has_overlapping_bodies() and get_overlapping_bodies()[0] is CharacterBody2D:
		randomize()
		OverworldGlobals.playSound2D(global_position, "460509__florianreichelt__hitting-in-a-face_%s.ogg" % randi_range(1,2), 0.0)
