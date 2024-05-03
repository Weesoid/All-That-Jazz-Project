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

func _on_return_button_up():
	slider.value = 0
	amount_enter.emit()

func _on_accept_button_up():
	amount_enter.emit()
