extends Control

@onready var icon = $PowerIcon
@onready var info_name = $PowerInfo/Name
@onready var info_description = $PowerInfo/Description

var current_index = 0

func _ready():
	updatePowerSelect()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("ui_right"):
		current_index += 1
		updatePowerSelect()

	if Input.is_action_just_pressed("ui_left"):
		current_index -= 1
		updatePowerSelect()
	
	if Input.is_action_just_pressed("ui_accept"):
		PlayerGlobals.KNOWN_POWERS[current_index].setPower()
		OverworldGlobals.closeMenu(self)
	
func updatePowerSelect():
	if current_index > PlayerGlobals.KNOWN_POWERS.size() - 1 or current_index < 0:
		current_index = 0
	
	icon.texture = PlayerGlobals.KNOWN_POWERS[current_index].ICON
	info_name.text = PlayerGlobals.KNOWN_POWERS[current_index].NAME
	info_description.text = PlayerGlobals.KNOWN_POWERS[current_index].DESCRIPTION
