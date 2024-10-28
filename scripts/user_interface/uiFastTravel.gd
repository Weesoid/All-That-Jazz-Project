extends Control

@onready var travel_panel = $FastTravelAreas/MarginContainer/ScrollContainer/VBoxContainer
@onready var image = $PanelContainer/TextureRect
@onready var description = $PanelContainer2/RichTextLabel
var map_component_data = {}

func _ready():
	for location in PlayerGlobals.FAST_TRAVEL_LOCATIONS:
		var button = OverworldGlobals.createCustomButton()
		var map = load(location).instantiate()
		button.text = map.NAME
		map_component_data[location] = [map.NAME, map.DESCRIPTION, map.IMAGE]
		button.pressed.connect(func(): travel(location))
		button.focus_entered.connect(
			func():
				description.text = map_component_data[location][1]
				if map_component_data[location][2] != null:
					image.texture = map_component_data[location][2]
		)
		if location == OverworldGlobals.getCurrentMap().scene_file_path:
			button.disabled = true
		travel_panel.add_child(button)
		map.queue_free()
	
	OverworldGlobals.setMenuFocus(travel_panel)

func travel(location):
	OverworldGlobals.closeMenu(self)
	OverworldGlobals.changeMap(location, '0,0,0', 'FastTravel')
