extends Control
class_name CustomCountBar

var EMPTY_CIRCLE: Texture = preload("res://images/sprites/circle_empty.png")
var FILLED_CIRCLE: Texture = preload("res://images/sprites/circle_filled.png")
@onready var container = $HBoxContainer
@export var value: int = 0
@export var max_value: int = 0
@export var small_sprites: bool = false

func _ready():
	if small_sprites:
		EMPTY_CIRCLE = preload("res://images/sprites/circle_empty_small.png")
		FILLED_CIRCLE = preload("res://images/sprites/circle_filled_small.png")

func _process(_delta):
	if !valuesCorrect():
		var filled = 0
		for child in container.get_children(): child.queue_free()
		for i in range(max_value):
			var rect: TextureRect = TextureRect.new()
			rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			if filled != value:
				rect.texture = FILLED_CIRCLE
				filled += 1
			else:
				rect.texture = EMPTY_CIRCLE
			container.add_child(rect)

func valuesCorrect()-> bool:
	var empty = 0
	var filled = 0
	for circle in container.get_children():
		if circle.texture == EMPTY_CIRCLE: 
			empty += 1
		elif circle.texture == FILLED_CIRCLE:
			filled += 1
	
	return empty == max_value and filled == value
