extends Control

@onready var travel_panel = $FastTravelAreas/ScrollContainer/VBoxContainer
@onready var texture = $PanelContainer/TextureRect
@onready var description = $PanelContainer2/RichTextLabel
@onready var travel_button = $Button

var selected_map = ''

func _process(_delta):
	if selected_map == '':
		travel_button.disabled = true
	else:
		travel_button.disabled = false

func _ready():
	for location in PlayerGlobals.FAST_TRAVEL_LOCATIONS:
		var button = Button.new()
		button.text = location
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.x = 96
		button.pressed.connect(
			func():
				selected_map = location
		)
		travel_panel.add_child(button)

func _on_button_pressed():
	if OverworldGlobals.getCurrentMap().name == selected_map:
		OverworldGlobals.closeMenu(self)
		OverworldGlobals.showPlayerPrompt("You're already here!")
	else:
		OverworldGlobals.closeMenu(self)
		OverworldGlobals.changeMap(selected_map)
