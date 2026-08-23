@tool
extends CharacterBody2D
class_name GenericNPC

@export var texture: Texture:
	set(tex):
		if tex != null and Engine.is_editor_hint() :
			texture = tex
			setSprite()
		elif Engine.is_editor_hint():
			texture = null
			setSprite(true)
@export var gravity = false
@export var stop_frame:int=0
@onready var sprite = $Sprite2D

func _ready():
	set_meta('stop_frame',stop_frame)
	if texture != null:
		setSprite()

func _physics_process(delta):
	if gravity and not is_on_floor():
		velocity.y += ProjectSettings.get_setting('physics/2d/default_gravity') * delta
		move_and_slide()

func setSprite(remove_sprite:bool=false):
	if Engine.is_editor_hint():
		sprite.texture = texture
		return
	
	if remove_sprite and !Engine.is_editor_hint():
		sprite.texture = null
	elif !Engine.is_editor_hint():
		sprite.texture = texture
		sprite.position.y = -(sprite.texture.get_height()/2)

func playFootstep():
	if is_on_floor():
		FootstepSoundManager.playFootstep(global_position)
		print('FS on ', name)
