extends HSplitContainer

const POWER_DOWN = preload("res://images/sprites/power_down.png")
const POWER_UP = preload("res://images/sprites/power_up.png")
const POWER_LEFT = preload("res://images/sprites/power_left.png")
const POWER_RIGHT = preload("res://images/sprites/power_right.png")

@onready var power_name = $Label
@onready var power_combo = $HBoxContainer

@export var power: ResPower

func _ready():
	power_name.text = power.NAME
	for character in power.INPUT_MAP:
		var icon = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.modulate = Color.TRANSPARENT
		match character:
			'w': icon.texture = POWER_UP
			'a': icon.texture = POWER_LEFT
			's': icon.texture = POWER_DOWN
			'd': icon.texture = POWER_RIGHT
		power_combo.add_child(icon)
	
	for child in power_combo.get_children():
		var icon_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		#icon_tween.tween_property(child, 'modulate', Color.TRANSPARENT, 0.2)
		icon_tween.tween_property(child, 'modulate', Color.WHITE, 0.25)
		await get_tree().create_timer(0.025).timeout

