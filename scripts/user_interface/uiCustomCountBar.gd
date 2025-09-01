extends Control
class_name CustomCountBar

const EMPTY_CIRCLE: Texture = preload("res://images/sprites/circle_empty.png")
const FILLED_CIRCLE: Texture = preload("res://images/sprites/circle_filled.png")
const EMPTY_CIRCLE_SMALL = preload("res://images/sprites/circle_empty_small.png")
const FILLED_CIRCLE_SMALL = preload("res://images/sprites/circle_filled_small.png")

@onready var container = $HBoxContainer
@export var value: int = 0
@export var max_value: int = 0
@export var show_max: bool = true
@export var small_sprites: bool = false
@export var process:bool=true
var empty_circle = EMPTY_CIRCLE
var filled_circle = FILLED_CIRCLE

func _ready():
	if small_sprites:
		empty_circle = EMPTY_CIRCLE_SMALL
		filled_circle = FILLED_CIRCLE_SMALL
	if !process:
		process_mode = Node.PROCESS_MODE_DISABLED

func _process(_delta):
	if !valuesCorrect():
		updateValue()

func valuesCorrect()-> bool:
	var empty = 0
	var filled = 0
	for circle in container.get_children():
		if circle.texture == empty_circle: 
			empty += 1
		elif circle.texture == filled_circle:
			filled += 1
	
	return empty == max_value and filled == value

func setValue(p_value):
	value = p_value
	updateValue()

func updateValue():
	var filled = 0
	for child in container.get_children(): 
		child.queue_free()
	for i in range(max_value):
		var rect: TextureRect = TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		if filled != value:
			rect.texture = filled_circle
			filled += 1
		elif filled == value and show_max:
			rect.texture = empty_circle
			rect.scale = Vector2(1.25,1.25)
		rect.pivot_offset = rect.texture.get_size()/2
		container.add_child(rect)

func getCircles(type:String='all'):
	match type:
		'all':
			return container.get_children()
		'filled':
			return container.get_children().filter(func(circle): return circle.texture == filled_circle)
		'empty':
			return container.get_children().filter(func(circle): return circle.texture == empty_circle)
