extends Control
class_name CustomCountBar

enum FillTween {
	NONE,
	TP_GAIN
}

@export var value: int = 0
@export var max_value: int = 0
@export var show_max: bool = true
@export var empty_circle: Texture = preload("res://images/sprites/circle_empty.png")
@export var filled_circle: Texture = preload("res://images/sprites/circle_filled.png")
@export var fill_tween := FillTween.NONE

var filled_modulate:Color = Color.WHITE
var empty_modulate:Color = Color.WHITE
var tween_running:bool=false
signal value_changed(value)

func _ready():
	for i in range(value):
		add_child(createCircle(filled_circle))
	for i in range(max_value-value):
		add_child(createCircle(empty_circle))
	setValue(value)

func setValue(p_value):
	value = p_value
	updateValue()
	value_changed.emit(value)

func updateValue():
	var filled = 0
	#var do_tween:bool=true
	for circle in get_children():
		if filled < value: 
			circle.show()
			circle.texture = filled_circle
			filled += 1
			if filled == value: 
				await get_tree().process_frame
				doFillTween(circle)
		elif show_max:
			circle.texture = empty_circle
		else:
			circle.hide()

func doFillTween(circle: TextureRect):
	if fill_tween == FillTween.NONE or tween_running: 
		return
	
	tween_running=true
	var original_pos = circle.position
	if fill_tween == FillTween.TP_GAIN:
		var pos_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		var modulate_tween = create_tween()
		circle.modulate = SettingsGlobals.ui_colors['up']
		circle.position = original_pos+Vector2(0,5)
		modulate_tween.tween_property(circle, 'modulate', Color.WHITE, 2)
		pos_tween.tween_property(circle, 'position', original_pos,1)
		await modulate_tween.finished
	tween_running = false


func createCircle(texture: Texture):
	var rect: TextureRect = TextureRect.new()
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	rect.texture = texture
	rect.modulate = filled_modulate if texture == filled_circle else empty_modulate
	rect.pivot_offset = rect.texture.get_size()/2
	return rect

func getCircles(type:String='all'):
	match type:
		'all':
			return get_children()
		'filled':
			return get_children().filter(func(circle): return circle.texture == filled_circle)
		'empty':
			return get_children().filter(func(circle): return circle.texture == empty_circle)
