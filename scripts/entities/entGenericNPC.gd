@tool
extends CharacterBody2D
class_name GenericNPC

@export var texture: Texture:
	set(tex):
		if tex != null and Engine.is_editor_hint() :
			texture = tex
			setSprite()
		elif Engine.is_editor_hint() :
			texture = null
			setSprite(true)
@export var gravity = false
@onready var sprite = $Sprite2D

func _ready():
	if texture != null:
		setSprite()

func _physics_process(delta):
	if gravity and not is_on_floor():
		velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
		move_and_slide()

func setSprite(remove_sprite:bool=false):
	if remove_sprite:
		sprite.texture = null
	else:
		sprite.texture = texture
		sprite.position.y = -(sprite.texture.get_height()/2)


