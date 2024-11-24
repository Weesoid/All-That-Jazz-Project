extends Control
class_name CustomConfirmationDialogue

@onready var text = $PanelContainer/RichTextLabel
@onready var container = $HBoxContainer
@onready var yes_button = $HBoxContainer/Yes
@onready var no_button = $HBoxContainer/No

func _ready():
	OverworldGlobals.setMenuFocus(container)
