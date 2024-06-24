extends Control

@onready var slider = $Slider/VBoxContainer/HSlider
@onready var value = $Slider/VBoxContainer/Value
@onready var accept = $Slider/VBoxContainer/HBoxContainer/Accept
var max_v

signal amount_enter

func _process(_delta):
	value.text = str(slider.value)

func _ready():
	loadSlider()
	slider.grab_focus()

func loadSlider():
	slider.max_value = max_v

func _on_return_button_up():
	slider.value = 0
	amount_enter.emit()

func _on_accept_button_up():
	amount_enter.emit()

func _unhandled_input(_event):
	if Input.is_action_just_pressed('ui_tab_right'):
		slider.value = max_v
		accept.grab_focus()
	elif Input.is_action_just_pressed('ui_tab_left'):
		slider.value = 0
		accept.grab_focus()
