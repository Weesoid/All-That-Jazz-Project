extends Control
class_name PositionalCountBar

const EMPTY_CIRCLE: Texture = preload("res://images/sprites/circle_empty.png")
const FILLED_CIRCLE: Texture = preload("res://images/sprites/circle_filled.png")
const EMPTY_CIRCLE_SMALL = preload("res://images/sprites/circle_empty_small.png")
const FILLED_CIRCLE_SMALL  = preload("res://images/sprites/circle_filled_small.png")

@onready var container = $HBoxContainer
@export var value: int = 0
@export var max_value: int = 0
@export var small_sprites: bool = false
var empty_circle
var filled_circle

func _ready():
	if small_sprites:
		empty_circle = EMPTY_CIRCLE_SMALL
		filled_circle = FILLED_CIRCLE_SMALL

func _process(_delta):
	if !valuesCorrect():
		var filled = 0
		for child in container.get_children(): child.queue_free()
		for i in range(max_value):
			var rect: TextureRect = TextureRect.new()
			rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
			if filled != value:
				rect.texture = filled_circle
				filled += 1
			else:
				rect.texture = empty_circle
			container.add_child(rect)

func valuesCorrect()-> bool:
	var empty = 0
	var filled = 0
	for circle in container.get_children():
		if circle.texture == empty_circle: 
			empty += 1
		elif circle.texture == filled_circle:
			filled += 1
	
	return empty == max_value and filled == value
