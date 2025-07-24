extends Area2D
class_name Projectile

@export var speed = 1500.0
@export var impact_sound: AudioStream = preload("res://audio/sounds/13_Ice_explosion_01.ogg")
@export var free_distance: float = 325.0
@export var projectile_texture: Texture
@export var no_clip_time: float = 0.0

@onready var sprite = $Sprite2D
@onready var audio = $AudioStreamPlayer2D
var shooter: CharacterBody2D
var spawn_location: Vector2

func _ready():
	spawn_location = global_position
	if projectile_texture != null: 
		sprite.texture = projectile_texture
	if no_clip_time > 0.0:
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		await get_tree().create_timer(no_clip_time).timeout
		set_collision_layer_value(1, true)
		set_collision_mask_value(1, true)

func _physics_process(delta):
	global_position += Vector2(cos(rotation), sin(rotation)) * speed * delta
	if global_position.distance_to(spawn_location)>free_distance: queue_free()

func _on_body_entered(body):
	var _b = body
	queue_free()

func _exit_tree():
	if has_overlapping_bodies() and get_overlapping_bodies()[0] is CharacterBody2D:
		randomize()
		OverworldGlobals.playSound2D(global_position, "460509__florianreichelt__hitting-in-a-face_%s.ogg" % randi_range(1,2), 0.0)
	else:
		OverworldGlobals.playSound2D(global_position, "66777__kevinkace__crate-break-1.ogg")
