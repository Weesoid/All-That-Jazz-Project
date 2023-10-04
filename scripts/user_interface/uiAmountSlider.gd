extends Control

@onready var slider = $Slider/VBoxContainer/HSlider
@onready var value = $Slider/VBoxContainer/Value
var max_v

signal amount_enter

func _process(_delta):
	value.text = str(slider.value)

func _ready():
	loadSlider()

func loadSlider():
	slider.max_value = max_v

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_accept"):
		amount_enter.emit()
	elif Input.is_action_just_pressed("ui_alt_cancel"):
		slider.value = 0
		amount_enter.emit()
