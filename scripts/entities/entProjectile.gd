extends Area2D
class_name Projectile

@export var SPEED = 1500.0
@export var IMPACT_SOUND: AudioStream = preload("res://audio/sounds/13_Ice_explosion_01.ogg")
@export var FREE_DISTANCE: float = 325.0
@export var PROJECTILE_TEXTURE: Texture
@export var NO_CLIP_TIME: float = 0.0

@onready var sprite = $Sprite2D
@onready var AUDIO = $AudioStreamPlayer2D
var SHOOTER: CharacterBody2D
var SPAWN_LOCATION: Vector2

func _ready():
	SPAWN_LOCATION = global_position
	if PROJECTILE_TEXTURE != null: 
		sprite.texture = PROJECTILE_TEXTURE
	if NO_CLIP_TIME > 0.0:
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		await get_tree().create_timer(NO_CLIP_TIME).timeout
		set_collision_layer_value(1, true)
		set_collision_mask_value(1, true)

func _physics_process(delta):
	global_position += Vector2(cos(rotation), sin(rotation)) * SPEED * delta
	if global_position.distance_to(SPAWN_LOCATION)>FREE_DISTANCE: queue_free()

func _on_body_entered(body):
	var _b = body
	queue_free()

func _exit_tree():
	if has_overlapping_bodies() and get_overlapping_bodies()[0] is CharacterBody2D:
		randomize()
		OverworldGlobals.playSound2D(global_position, "460509__florianreichelt__hitting-in-a-face_%s.ogg" % randi_range(1,2), 0.0)
	else:
		OverworldGlobals.playSound2D(global_position, "66777__kevinkace__crate-break-1.ogg")
