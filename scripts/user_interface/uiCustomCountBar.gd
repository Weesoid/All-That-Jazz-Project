extends Control
class_name CustomCountBar

@onready var container = $HBoxContainer
@export var value: int = 0
@export var max_value: int = 0
@export var show_max: bool = true
@export var process:bool=true
@export var empty_circle: Texture = preload("res://images/sprites/circle_empty.png")
@export var filled_circle: Texture = preload("res://images/sprites/circle_filled.png")
var filled_modulate:Color = Color.WHITE
var empty_modulate:Color = Color.WHITE

func _ready():
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
			rect.modulate = filled_modulate
			filled += 1
		elif filled == value and show_max:
			rect.texture = empty_circle
			rect.modulate = empty_modulate
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
