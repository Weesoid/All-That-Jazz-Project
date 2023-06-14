extends CharacterBody2D

@onready var SPRITE2D = $Sprite2D
@onready var COLLISION = $CollisionShape2D

@export var SPRITE: Sprite2D
@export var COLLISION_SHAPE: CollisionShape2D 

func _ready():
	SPRITE2D = SPRITE
	COLLISION = COLLISION_SHAPE
	print('Character initialized!')
