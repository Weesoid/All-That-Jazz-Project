extends Area2D

@onready var sprite = $Sprite2D
@onready var shape = $CollisionShape2D

func _process(_delta):
	print('Scale: ', scale)
	
	sprite.scale = scale
